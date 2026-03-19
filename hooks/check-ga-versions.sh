#!/bin/bash
# Pre-deploy hook: Checks @adobe/aio-commerce-* packages for GA updates
# INFORMATIONAL ONLY — never blocks (always exits 0)
# Outputs NOTHING when all packages are up to date (saves tokens)

# Read tool input from stdin
TOOL_INPUT=$(cat)

# Extract the bash command — exit immediately if not a deploy command
COMMAND=$(echo "$TOOL_INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    cmd = data.get('command', '')
    # Quick exit: only print if deploy command
    if 'aio app deploy' in cmd or 'aio-app-deploy' in cmd:
        print(cmd)
except:
    pass
" 2>/dev/null)

[ -z "$COMMAND" ] && exit 0

# Find package.json
PACKAGE_JSON=""
D="$(pwd)"
while [ "$D" != "/" ]; do
    [ -f "$D/package.json" ] && PACKAGE_JSON="$D/package.json" && break
    D=$(dirname "$D")
done

[ -z "$PACKAGE_JSON" ] && exit 0

python3 << 'PYEOF' "$PACKAGE_JSON"
import json, re, sys, os, time, urllib.request, urllib.error, tempfile

pkg_path = sys.argv[1]
try:
    with open(pkg_path) as f:
        pkg = json.load(f)
except Exception:
    sys.exit(0)

all_deps = {}
for k in ("dependencies", "devDependencies"):
    all_deps.update(pkg.get(k, {}))
commerce = {k: v for k, v in all_deps.items() if k.startswith("@adobe/aio-commerce")}
if not commerce:
    sys.exit(0)

# --- Check 1: Non-GA versions ---
non_ga = []
for name, ver in commerce.items():
    cv = re.sub(r'^[\^~>=<]*', '', ver)
    if re.match(r'^0\.', cv):
        non_ga.append(f"  {name}@{ver} (pre-GA 0.x)")
    elif any(re.search(p, cv, re.IGNORECASE) for p in [r'beta', r'alpha', r'canary', r'rc', r'\d{8,}']):
        non_ga.append(f"  {name}@{ver} (pre-release)")
    elif ver in ('*', 'latest', 'next'):
        non_ga.append(f"  {name}@{ver} (may resolve to pre-release)")

# --- Check 2: Newer GA versions (cached 1 hour) ---
cache_file = os.path.join(tempfile.gettempdir(), "aio-commerce-ga-cache.json")
cache_ttl = 3600  # 1 hour

releases = None
try:
    if os.path.exists(cache_file) and (time.time() - os.path.getmtime(cache_file)) < cache_ttl:
        with open(cache_file) as f:
            releases = json.load(f)
    else:
        req = urllib.request.Request(
            "https://api.github.com/repos/adobe/aio-commerce-sdk/releases?per_page=50",
            headers={"Accept": "application/vnd.github+json", "User-Agent": "claude-plugin"}
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            releases = json.loads(resp.read().decode())
        with open(cache_file, "w") as f:
            json.dump(releases, f)
except Exception:
    pass

updates = []
if releases:
    latest_ga = {}
    for r in releases:
        if r.get("prerelease") or r.get("draft"):
            continue
        m = re.match(r'^(@adobe/aio-commerce[^@]*)@(.+)$', r.get("tag_name", ""))
        if not m:
            continue
        pn, pv = m.group(1), m.group(2)
        if any(x in pv.lower() for x in ('beta', 'alpha', 'rc', 'canary')):
            continue
        if pn not in latest_ga:
            latest_ga[pn] = pv

    for name, ver in commerce.items():
        cv = re.sub(r'^[\^~>=<]*', '', ver)
        if name in latest_ga and cv != latest_ga[name]:
            updates.append(f"  {name}: {cv} -> {latest_ga[name]}")

# --- Output only if there are issues ---
if non_ga or updates:
    lines = ["[GA Check]"]
    if non_ga:
        lines.append("Pre-release packages: " + ", ".join(non_ga))
    if updates:
        lines.append("Updates available:")
        lines.extend(updates)
    print("\n".join(lines))

PYEOF

exit 0
