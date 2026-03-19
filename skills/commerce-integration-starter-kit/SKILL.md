---
name: commerce-integration-starter-kit
description: Use when building back-office integrations with Adobe Commerce using the integration starter kit. Covers event-driven sync for products, customers, customer groups, orders, shipments, and stock between Commerce and external systems. Also use when setting up onboarding scripts, event registrations, consumer routing, action file structure (validator/transformer/sender/pre/post), infinite loop breaker, environment variables, app.config.yaml packages, or deploying the starter kit.
---

# Commerce Integration Starter Kit

## Overview

The integration starter kit provides a pre-built App Builder project for bidirectional, event-driven data sync between Adobe Commerce and external systems (ERP, PIM, OMS, etc.). It handles products, customers, customer groups, orders, shipments, and stock.

Repository: https://github.com/adobe/commerce-integration-starter-kit

## Prerequisites

- Adobe Developer Console project (App Builder template)
- API services: I/O Events, I/O Management, Adobe I/O Events for Adobe Commerce, Adobe Commerce as a Cloud Service
- Adobe Commerce 2.4.4 – 2.4.9
- Node.js >= 22
- Commerce Eventing module (for PaaS 2.4.4/2.4.5)

## Setup Steps

```bash
# 1. Clone and install
git clone git@github.com:adobe/commerce-integration-starter-kit.git
cd commerce-integration-starter-kit
cp env.dist .env
# Fill .env values
npm install

# 2. Connect to workspace
aio login
aio console org select
aio console project select
aio console workspace select
aio app use  # Choose merge

# 3. Edit app.config.yaml — comment out unneeded entity packages

# 4. Deploy
aio app deploy

# 5. Run onboarding (creates providers, metadata, registrations, configures eventing)
npm run onboard

# 6. Subscribe to Commerce events
npm run commerce-event-subscribe
```

## Project Structure

```
actions/
├── auth.js                          # OAuth1 (PaaS) vs IMS (SaaS) detection
├── constants.js                     # HTTP codes, provider keys
├── infinite-loop-breaker.js         # SHA-256 fingerprint dedup (60s TTL)
├── oauth1a.js                       # HTTP client (got + HTTP/2)
├── openwhisk.js                     # Action invocation wrapper
├── responses.js                     # Standard response helpers
├── telemetry.js                     # OpenTelemetry config
├── utils.js                         # Parameter validation, secret masking
├── ingestion/                       # Webhook ingestion for external events
│   └── webhook/index.js
├── webhook/                         # Synchronous webhooks
│   └── check-stock/index.js
├── starter-kit-info/index.js        # Info action
├── product/
│   ├── commerce/                    # Commerce → External
│   │   ├── actions.config.yaml
│   │   ├── consumer/index.js        # Event router
│   │   ├── created/                 # index.js, validator.js, transformer.js, sender.js, pre.js, post.js
│   │   ├── updated/
│   │   ├── deleted/
│   │   └── full-sync/
│   └── external/                    # External → Commerce
│       ├── actions.config.yaml
│       ├── consumer/index.js
│       ├── created/
│       ├── updated/
│       └── deleted/
├── customer/                        # Same structure: commerce/ + external/
│   ├── commerce/                    # + group-updated/, group-deleted/
│   └── external/                    # + group-created/, group-updated/, group-deleted/
├── order/
│   ├── commerce/                    # created/, updated/
│   └── external/                    # updated/, shipment-created/, shipment-updated/
└── stock/
    ├── commerce/                    # updated/
    └── external/                    # updated/
scripts/
├── onboarding/
│   ├── index.js                     # Main onboarding script
│   └── config/
│       ├── workspace.json           # Download from Developer Console
│       ├── providers.json           # Provider definitions
│       ├── events.json              # Event metadata + sample templates
│       └── starter-kit-registrations.json  # Entity/provider mapping
├── commerce-event-subscribe/
│   ├── index.js
│   └── config/commerce-event-subscribe.json  # Event subscriptions + fields
└── lib/                             # Shared: providers, metadata, registrations, eventing API
hooks/
└── post-app-deploy.js               # Auto-onboard after deploy (commented out by default)
```

## Action File Pattern

Every event handler action follows the same 6-file pattern:

| File | Purpose |
|------|---------|
| `index.js` | Entry point — orchestrates the pipeline |
| `validator.js` | Validates incoming event data |
| `transformer.js` | Transforms data between Commerce and external format |
| `sender.js` | Sends data to the target system (Commerce API or external API) |
| `pre.js` | Pre-processing hook (runs before sender) |
| `post.js` | Post-processing hook (runs after sender) |

**To customize an integration:** Edit `transformer.js` (data mapping), `sender.js` (API calls to your system), and optionally `pre.js`/`post.js`.

## Consumer Routing

Each entity has a `consumer/index.js` that routes events to the correct handler action:

**Commerce consumers** route by observer event name:
- `catalog_product_save_commit_after` → created (if `created_at === updated_at`) or updated
- `catalog_product_delete_commit_after` → deleted
- `customer_save_commit_after` → created or updated
- `customer_delete_commit_after` → deleted
- `customer_group_save_commit_after` → group-updated
- `customer_group_delete_commit_after` → group-deleted
- `sales_order_save_commit_after` → created or updated
- `cataloginventory_stock_item_save_commit_after` → updated

**External consumers** route by backoffice event type:
- `be-observer.catalog_product_create/update/delete`
- `be-observer.customer_create/update/delete`
- `be-observer.customer_group_create/update/delete`
- `be-observer.sales_order_status_update`
- `be-observer.sales_order_shipment_create/update`
- `be-observer.catalog_stock_update`

## Infinite Loop Breaker

Prevents bidirectional sync loops using SHA-256 fingerprinting via `@adobe/aio-lib-state`:

```javascript
// In consumer/index.js
const { isAPotentialInfiniteLoop, storeFingerPrint } = require('../../infinite-loop-breaker');

// Check before processing
if (await isAPotentialInfiniteLoop(state, eventData, fingerprintFields)) {
  return; // Skip — already processed
}

// Store after processing
await storeFingerPrint(state, eventData, fingerprintFields);
```

Default TTL: 60 seconds. Fingerprint fields vary by entity (e.g., `{sku, description}` for products).

## Authentication

Detected automatically from `.env` values:

| Auth Type | When Used | Required Env Vars |
|-----------|-----------|-------------------|
| OAuth1 (PaaS) | `COMMERCE_CONSUMER_KEY` is set | `COMMERCE_CONSUMER_KEY`, `COMMERCE_CONSUMER_SECRET`, `COMMERCE_ACCESS_TOKEN`, `COMMERCE_ACCESS_TOKEN_SECRET` |
| IMS OAuth (SaaS/ACCS) | `OAUTH_CLIENT_ID` is set | `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`, `OAUTH_TECHNICAL_ACCOUNT_ID`, `OAUTH_TECHNICAL_ACCOUNT_EMAIL`, `OAUTH_ORG_ID`, `OAUTH_SCOPES` |

OAuth1 is tried first. SaaS/ACCS is opt-in.

## Environment Variables

```env
# IMS OAuth
OAUTH_BASE_URL=https://ims-na1.adobelogin.com/ims/token/
IO_MANAGEMENT_BASE_URL=https://api.adobe.io/events/
OAUTH_CLIENT_ID=
OAUTH_CLIENT_SECRET=
OAUTH_TECHNICAL_ACCOUNT_ID=
OAUTH_TECHNICAL_ACCOUNT_EMAIL=
OAUTH_ORG_ID=
OAUTH_SCOPES=AdobeID, openid, read_organizations, additional_info.projectedProductContext, additional_info.roles, adobeio_api, read_client_secret, manage_client_secrets, event_receiver_api, commerce.accs

# Commerce PaaS OAuth1
COMMERCE_CONSUMER_KEY=
COMMERCE_CONSUMER_SECRET=
COMMERCE_ACCESS_TOKEN=
COMMERCE_ACCESS_TOKEN_SECRET=

# Commerce endpoints
COMMERCE_BASE_URL=
COMMERCE_GRAPHQL_ENDPOINT=

# Commerce eventing
COMMERCE_ADOBE_IO_EVENTS_MERCHANT_ID=

# Workspace
IO_CONSUMER_ID=
IO_PROJECT_ID=
IO_WORKSPACE_ID=

# Event prefix (for uniqueness)
EVENT_PREFIX=
```

## app.config.yaml Packages

| Package | Entity | Direction |
|---------|--------|-----------|
| `starter-kit` | Info action | — |
| `ingestion` | Event ingestion webhook | Inbound |
| `webhook` | Synchronous webhooks (check-stock) | Inbound |
| `product-commerce` | Product | Commerce → External |
| `product-backoffice` | Product | External → Commerce |
| `customer-commerce` | Customer + Groups | Commerce → External |
| `customer-backoffice` | Customer + Groups | External → Commerce |
| `order-commerce` | Order | Commerce → External |
| `order-backoffice` | Order + Shipments | External → Commerce |
| `stock-commerce` | Stock | Commerce → External |
| `stock-backoffice` | Stock | External → Commerce |

Comment out unneeded packages in `app.config.yaml` before deploying.

## Onboarding Config

**`scripts/onboarding/config/starter-kit-registrations.json`** — controls which entities/directions are registered:

```json
{
  "product": ["commerce", "backoffice"],
  "customer": ["commerce", "backoffice"],
  "order": ["commerce", "backoffice"],
  "stock": ["commerce", "backoffice"]
}
```

Remove entries you don't need before running `npm run onboard`.

## NPM Scripts

| Script | Purpose |
|--------|---------|
| `npm run onboard` | Create providers, metadata, registrations, configure eventing |
| `npm run commerce-event-subscribe` | Subscribe to Commerce observer events |
| `npm test` | Run Jest tests |

## OpenTelemetry

Set `ENABLE_TELEMETRY: true` in action inputs (see customer/commerce actions). Uses `@adobe/aio-lib-telemetry` with service name `commerce-integration-starter-kit`. Local telemetry stack: `docker compose up`.

## Runtime

All actions use `nodejs:22`, `require-adobe-auth: true`, `final: true` annotations. Exception: ingestion webhook uses `require-adobe-auth: false`.

## Adding a New Entity

1. Create `actions/<entity>/commerce/` and `actions/<entity>/external/` directories
2. Add `consumer/index.js` with event routing logic
3. Add handler folders (created/updated/deleted) each with the 6-file pattern
4. Create `actions.config.yaml` for each direction
5. Add packages to `app.config.yaml` with `$include` references
6. Add event definitions to `scripts/onboarding/config/events.json`
7. Update `starter-kit-registrations.json`
8. Add Commerce event subscriptions to `commerce-event-subscribe.json`
9. Run `npm run onboard` and `npm run commerce-event-subscribe`
