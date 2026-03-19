# Adobe App Builder Plugin for Claude Code

A Claude Code plugin providing skills and reference documentation for Adobe App Builder development, including database storage, Commerce extensibility MCP tooling, and configuration schema management.

## Plugin Structure

```
adobe-app-builder/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   └── update-plugin.md               # /update-plugin command
├── hooks/
│   ├── hooks.json                     # Hook configuration (PreToolUse)
│   └── check-ga-versions.sh           # Pre-deploy GA compatibility check
├── sources.json                        # Skill-to-documentation mapping
├── skills/
│   ├── adobe-database-storage/
│   │   └── SKILL.md                  # Database collections, CRUD, aggregation
│   ├── adobe-commerce-coding-tools/
│   │   └── SKILL.md                  # MCP servers, slash commands, deployment
│   ├── adobe-commerce-config-schema/
│   │   └── SKILL.md                  # Config schema fields, types, encryption
│   ├── adobe-commerce-sdk-versions/
│   │   └── SKILL.md                  # GA version gate, compatibility checks
│   ├── adobe-api-mesh/
│   │   └── SKILL.md                  # API Mesh handlers, transforms, hooks, CLI
│   ├── commerce-integration-starter-kit/
│   │   └── SKILL.md                  # Back-office integration, event-driven sync
│   └── commerce-checkout-starter-kit/
│       └── SKILL.md                  # Payment, shipping, tax, webhooks
└── README.md
```

## Skills

### adobe-database-storage

Reference for working with App Builder's managed document database (`@adobe/aio-lib-db`). Covers collection creation, runtime action templates, CRUD operations, aggregation pipelines, indexing, CLI commands, and best practices.

### adobe-commerce-coding-tools

Reference for the Adobe Commerce AI coding tooling suite — MCP servers, slash commands (`/architect`, `/developer`, `/tester`, etc.), and deployment workflows.

### adobe-commerce-config-schema

Reference for creating and editing `app.commerce.config.ts` schema files using `@adobe/aio-commerce-lib-config`. Covers all 6 field types (`text`, `password`, `email`, `url`, `tel`, `list`), validation rules, password encryption (AES-256-GCM), scope trees, Commerce scope syncing, configuration inheritance, and the full TypeScript types API.

### adobe-commerce-sdk-versions

**GA version gate** — automatically triggered before installing or recommending any `@adobe/aio-commerce-*` package. Ensures only General Availability compatible versions are used, flags beta/pre-release packages, and instructs Claude to verify against the [releases page](https://github.com/adobe/aio-commerce-sdk/releases) before proceeding.

### adobe-api-mesh

Reference for Adobe API Mesh — combining multiple APIs (GraphQL, REST, JSON Schema) into a single GraphQL gateway. Covers `mesh.json` configuration, all 3 handler types (GraphQL, OpenAPI, JsonSchema), 7 transforms (prefix, rename, filterSchema, namingConvention, encapsulate, typeMerging, federation), hooks (beforeAll/afterAll/beforeSource/afterSource), secrets, native caching, local development, environment variables, and the full `aio api-mesh:*` CLI command reference.

### commerce-integration-starter-kit

Reference for the [integration starter kit](https://github.com/adobe/commerce-integration-starter-kit) — event-driven bidirectional sync between Commerce and external systems. Covers the 6-file action pattern (validator/transformer/sender/pre/post), consumer routing for products, customers, customer groups, orders, shipments, and stock, onboarding scripts, infinite loop breaker, `app.config.yaml` packages, environment variables, and authentication (OAuth1 PaaS vs IMS SaaS).

### commerce-checkout-starter-kit

Reference for the [checkout starter kit](https://github.com/adobe/commerce-checkout-starter-kit) — out-of-process payment methods, shipping carriers, and tax integrations. Covers webhook actions (validate-payment, filter-payment, shipping-methods, collect-taxes), YAML configuration files (`payment-methods.yaml`, `shipping-carriers.yaml`, `tax-integrations.yaml`), webhook signature verification, Commerce event handling, 3rd-party event publishing, Admin UI SDK extension, and setup scripts.

## Hooks

### Pre-deploy GA Version Check

A `PreToolUse` hook automatically runs when you type `aio app deploy` or `aio-app-deploy` **in Claude Code chat**. It is **informational only** — it never blocks the deploy.

**What it does:**

1. Scans `package.json` for all `@adobe/aio-commerce-*` dependencies
2. Flags any non-GA versions (beta, alpha, rc, 0.x, date-stamped pre-releases)
3. Fetches `https://api.github.com/repos/adobe/aio-commerce-sdk/releases` to check for newer GA versions
4. Reports findings, then **proceeds with the deploy**

**Example output when updates are available:**

```
⚠ Non-GA @adobe/aio-commerce-* packages detected:

  @adobe/aio-commerce-lib-webhooks@^0.1.0-beta — version 0.x is pre-GA

These are pre-release packages. Consider updating to GA versions.

ℹ GA updates available for @adobe/aio-commerce-* packages:

  @adobe/aio-commerce-lib-config: 1.0.1 → 1.0.2

Run the appropriate install command to update (e.g., pnpm add <package>@<version>).

Release info: https://github.com/adobe/aio-commerce-sdk/releases

Proceeding with deploy...
```

**When everything is up to date:** No output at all (zero tokens consumed).

**Token optimization:**
- Exits immediately with no output for non-deploy Bash commands
- Outputs nothing when all packages are GA and up to date
- Caches GitHub API response for 1 hour in `/tmp/aio-commerce-ga-cache.json` (avoids repeated API calls across deploys)
- Compact output format when issues are found

**Two layers, different purposes:**
- **Hook** — runs at deploy time, checks for updates against live GitHub releases, informs you
- **Skill** (`adobe-commerce-sdk-versions`) — guides Claude during development when installing packages

## Setup

### 1. Install this plugin

Add the plugin path to your Claude Code settings. In `~/.claude/settings.json`:

```json
{
  "plugins": [
    "/path/to/adobe-app-builder"
  ]
}
```

Or at project level in `.claude/settings.json`:

```json
{
  "plugins": [
    "/path/to/adobe-app-builder"
  ]
}
```

### 2. Set up the Commerce Extensibility MCP Server

The plugin skills provide reference knowledge across all projects. For **live MCP tool access** (deploy, invoke, doc search) inside an App Builder project, follow these steps:

#### Prerequisites

- Node.js LTS
- npm or yarn
- Git

#### Install Adobe I/O CLI and plugins

```bash
npm install -g @adobe/aio-cli

aio plugins:install https://github.com/adobe-commerce/aio-cli-plugin-commerce \
  @adobe/aio-cli-plugin-app-dev \
  @adobe/aio-cli-plugin-runtime
```

#### Clone a starter kit

```bash
# For back-office integrations
git clone git@github.com:adobe/commerce-integration-starter-kit.git
cd commerce-integration-starter-kit

# OR for checkout customizations
git clone git@github.com:adobe/commerce-checkout-starter-kit.git
cd commerce-checkout-starter-kit
```

#### Run the tools setup

```bash
aio commerce extensibility tools-setup
```

When prompted:
1. Select **Claude Code** as your preferred coding agent
2. Confirm your package manager (npm/yarn)

This configures the MCP servers and installs agent skills into your project.

#### Authenticate

```bash
aio auth login
aio where  # Verify you're connected
```

Authentication is required for the RAG documentation search to work.

#### Restart Claude Code

After setup, restart Claude Code so it picks up the new MCP servers and skills.

## Using the MCP Tools

Once the MCP server is running inside a configured project, Claude Code gains access to these tools:

### MCP Tools (automatic)

Claude can use these directly during conversation:

| Tool | What it does |
|------|-------------|
| `aio-app-deploy` | Deploy your App Builder app (all actions or specific ones) |
| `aio-app-dev` | Start local development server |
| `aio-dev-invoke` | Invoke a runtime action with test parameters |

Example prompts:
- "Deploy my application"
- "Invoke the `process-order` action with `{\"orderId\": \"123\"}`"
- "Start local dev server"

### Slash Commands (manual)

Use these in your Claude Code conversation:

| Command | Example prompt |
|---------|---------------|
| `/architect` | "Design the architecture for a custom shipping integration" |
| `/developer` | "Implement a runtime action that processes webhook events" |
| `/devops-engineer` | "Deploy this to staging and set up CI/CD" |
| `/product-manager` | "Create requirements for an order sync integration" |
| `/technical-writer` | "Write API documentation for the actions in this project" |
| `/tester` | "Write unit tests for the event handler action" |
| `/tutor` | "Explain how App Builder events work" |
| `/search-commerce-docs "webhooks"` | Search Adobe Commerce docs inline |

### Typical Workflow

```
1. /product-manager    → Define requirements in REQUIREMENTS.md
2. /architect          → Design the extension architecture
3. /developer          → Implement runtime actions and configuration
4. /tester             → Write tests and validate
5. aio-app-deploy      → Deploy via MCP tool
6. /technical-writer   → Generate documentation
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Skills/MCP tools not showing | Restart Claude Code after `tools-setup` |
| RAG doc search not working | Run `aio auth login` — RAG requires authentication |
| Authentication errors | `aio auth logout` then `aio auth login` |
| CLI commands instead of MCP tools | Ask Claude to use MCP tools explicitly |
| `/feedback` command missing | Re-run `aio commerce extensibility tools-setup` to update |
| MCP server not connecting | Check `.claude/mcp.json` exists in your project root |

## Updating

### Update plugin skills from source documentation

Run the `/update-plugin` command in Claude Code:

```
/update-plugin
```

This will:
1. Read `sources.json` to find all source documentation URLs for each skill
2. Fetch the latest docs from each URL
3. Compare against current skill content
4. Apply incremental updates where docs have changed
5. Update `lastChecked` dates in `sources.json`
6. Report a summary of what changed

**`sources.json`** maps each skill to its documentation:

```json
{
  "skills": {
    "adobe-database-storage": {
      "lastChecked": "2026-03-18",
      "sources": ["https://developer.adobe.com/..."],
      "githubRepos": [{"repo": "adobe/aio-commerce-sdk", "path": "..."}]
    }
  }
}
```

To add a new source URL for an existing skill, add it to the `sources` array. To track a new GitHub repo, add it to `githubRepos`.

### Update MCP tools and agent skills

To update the Commerce extensibility MCP tools:

```bash
aio commerce extensibility tools-setup
```

## References

- [AI Coding Developer Tooling](https://experienceleague.adobe.com/en/docs/commerce/cloud-service/migration/migration-tools/coding-tools)
- [App Builder Database Storage](https://developer.adobe.com/app-builder/docs/guides/app_builder_guides/storage/database)
- [App Builder Storage Overview](https://developer.adobe.com/app-builder/docs/guides/app_builder_guides/storage/)
- [Commerce Config Library](https://github.com/adobe/aio-commerce-sdk/tree/main/packages/aio-commerce-lib-config)
- [Config Library Usage](https://github.com/adobe/aio-commerce-sdk/blob/main/packages/aio-commerce-lib-config/docs/usage.md)
- [Config API Reference](https://github.com/adobe/aio-commerce-sdk/blob/main/packages/aio-commerce-lib-config/docs/api-reference/README.md)
- [Password Encryption](https://github.com/adobe/aio-commerce-sdk/blob/main/packages/aio-commerce-lib-config/docs/password-encryption.md)
- [Commerce SDK Releases](https://github.com/adobe/aio-commerce-sdk/releases)
- [API Mesh Documentation](https://developer.adobe.com/graphql-mesh-gateway/mesh/)
- [API Mesh Getting Started](https://experienceleague.adobe.com/en/docs/commerce-learn/tutorials/extensibility/api-mesh/getting-started-api-mesh)
- [Integration Starter Kit](https://github.com/adobe/commerce-integration-starter-kit)
- [Checkout Starter Kit](https://github.com/adobe/commerce-checkout-starter-kit)
- [Checkout Starter Kit Docs](https://developer.adobe.com/commerce/extensibility/starter-kit/checkout/)
