---
name: adobe-commerce-sdk-versions
description: Use BEFORE installing, recommending, or updating any @adobe/aio-commerce-* package. This skill ensures only GA-compatible versions are used and beta or pre-release packages are flagged. Must be checked when adding dependencies to package.json, running npm/pnpm install for Commerce SDK libraries, or reviewing existing Commerce SDK versions in a project.
---

# Adobe Commerce SDK — GA Version Gate

## Purpose

All `@adobe/aio-commerce-*` packages must use **General Availability (GA) compatible** versions. Before installing or recommending any package version, you MUST verify it against the releases page.

## Verification Step (REQUIRED)

Before installing or recommending any `@adobe/aio-commerce-*` package:

1. **Fetch the releases page**: https://github.com/adobe/aio-commerce-sdk/releases
2. **Find the latest GA release** — look for a release whose description contains **"General Availability (GA) release of the Adobe Commerce SDK and all libraries"**
3. **Check that the package version you are about to use is GA-compatible** — it must be either:
   - Part of the GA release itself, OR
   - A stable patch release AFTER the GA baseline (e.g., `1.0.1`, `1.0.2` after a `1.0.0` GA)
4. **REJECT any version that contains**: `beta`, `alpha`, `rc`, `canary`, or date-stamped pre-release suffixes (e.g., `0.1.0-beta-20260317091123`)

## GA Baseline (as of 2026-03-27)

The latest GA release is `@adobe/aio-commerce-sdk@1.1.0` (March 24, 2025). The following packages are declared GA:

| Package | GA Version | Status |
|---------|-----------|--------|
| `@adobe/aio-commerce-sdk` | `1.1.0` | GA |
| `@adobe/aio-commerce-lib-webhooks` | `0.1.0` | GA (added in 1.1.0) |
| `@adobe/aio-commerce-lib-events` | `1.0.1` | GA |
| `@adobe/aio-commerce-lib-auth` | `1.0.1` | GA |
| `@adobe/aio-commerce-lib-app` | `1.1.0` | GA |
| `@adobe/aio-commerce-lib-api` | `1.0.1` | GA |
| `@adobe/aio-commerce-lib-config` | `1.0.3` | GA |
| `@adobe/aio-commerce-lib-core` | `1.0.0` | GA |

### NOT GA — Do Not Use in Production

| Package | Version | Why |
|---------|---------|-----|
| `@adobe/aio-commerce-lib-config` | `1.0.4-beta-*` | Beta, pre-release |
| `@adobe/aio-commerce-lib-app` | `1.2.0-beta-*` | Beta, pre-release |

## How to Check in an Existing Project

Run in the project directory:

```bash
# List all installed @adobe/aio-commerce-* packages
npm ls 2>/dev/null | grep "@adobe/aio-commerce" || pnpm ls 2>/dev/null | grep "@adobe/aio-commerce"
```

Or check `package.json` directly for any `@adobe/aio-commerce-*` entries under `dependencies` or `devDependencies`.

**Red flags to look for:**
- Any version containing `-beta`, `-alpha`, `-rc`, or date suffixes
- Any `0.x.x` version (not yet at stable `1.0.0`)
- Any version range like `*`, `latest`, or `next` (may resolve to pre-release)

## Safe Install Commands

```bash
# Install specific GA-compatible versions
pnpm add @adobe/aio-commerce-sdk@1.1.0
pnpm add @adobe/aio-commerce-lib-config@1.0.3
pnpm add @adobe/aio-commerce-lib-app@1.1.0
pnpm add @adobe/aio-commerce-lib-events@1.0.1
pnpm add @adobe/aio-commerce-lib-auth@1.0.1
pnpm add @adobe/aio-commerce-lib-webhooks@0.1.0
```

## When This Skill's Data May Be Stale

This skill contains a snapshot of GA versions as of 2026-03-27. The GA baseline may have been updated since then. **Always fetch the releases page** to confirm:

```
https://github.com/adobe/aio-commerce-sdk/releases
```

Look for the most recent release tagged with "General Availability (GA)" in its description. If a newer GA release exists, use those versions instead of the ones listed above.

## Decision Flow

```
Need to install @adobe/aio-commerce-* package?
│
├─ Fetch https://github.com/adobe/aio-commerce-sdk/releases
│
├─ Find latest GA release (description contains "General Availability")
│
├─ Is the target package version in the GA release or a stable patch after it?
│  ├─ YES → Safe to install
│  └─ NO  → Is it a beta/alpha/rc/0.x version?
│     ├─ YES → WARN the user: "This package is not GA-compatible"
│     │        Ask if they explicitly want pre-release
│     └─ NO  → Version is newer than GA but stable (e.g., 1.1.0)
│              Check if a new GA announcement exists for this version
│              If not found, WARN and confirm with user
```

## What to Tell the User

When a non-GA package is detected or requested:

> **Warning:** `<package>@<version>` is a pre-release package and is NOT part of the GA release. Using beta packages in production is not recommended. The current GA baseline is `@adobe/aio-commerce-sdk@1.1.0` (released 2025-03-24). Would you like to proceed with the beta version, or use only GA-compatible packages?
