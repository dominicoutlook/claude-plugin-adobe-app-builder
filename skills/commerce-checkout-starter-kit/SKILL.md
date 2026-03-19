---
name: commerce-checkout-starter-kit
description: Use when building custom checkout experiences with Adobe Commerce using the checkout starter kit. Covers out-of-process payment methods, shipping carriers, tax integrations, webhook signature verification, Commerce event handling, 3rd-party event publishing, Admin UI SDK extensions, and deploying the checkout starter kit. Also use when configuring payment-methods.yaml, shipping-carriers.yaml, tax-integrations.yaml, or setting up Commerce webhooks for checkout flows.
---

# Commerce Checkout Starter Kit

## Overview

The checkout starter kit provides a pre-built App Builder project for building custom checkout experiences — out-of-process payment methods, shipping carriers, and tax integrations. It uses Commerce Webhooks for synchronous operations and I/O Events for asynchronous flows.

Repository: https://github.com/adobe/commerce-checkout-starter-kit
Docs: https://developer.adobe.com/commerce/extensibility/starter-kit/checkout/

## Prerequisites

- Adobe Commerce 2.4.5 – 2.4.9 (PaaS or SaaS)
- Node.js >= 22
- Adobe Developer Console with App Builder license
- `@adobe/aio-cli` installed globally

### Commerce Modules (PaaS only)

```bash
composer require magento/module-out-of-process-payment-methods --with-dependencies
composer require magento/module-out-of-process-shipping-methods --with-dependencies
composer require magento/module-out-of-process-tax-management --with-dependencies
```

Optional:
- Commerce Webhooks: version per [installation docs](https://developer.adobe.com/commerce/extensibility/webhooks/installation/)
- Commerce Eventing: version `1.12.1`+
- Admin UI SDK: `magento/commerce-backend-sdk >= 3.0`

## Setup Steps

```bash
# 1. Clone and install
git clone git@github.com:adobe/commerce-checkout-starter-kit.git
cd commerce-checkout-starter-kit
npm install

# 2. Connect workspace
aio login
aio console org select
aio console project select
aio console workspace select
aio app use --merge

# 3. Add services
aio app add service
# Select: I/O Management API, (optional) I/O Events, Adobe I/O Events for Adobe Commerce, (SaaS) Adobe Commerce as a Cloud Service

# 4. Setup env
cp env.dist .env
npm run sync-oauth-credentials  # Auto-populates OAuth fields

# 5. Set COMMERCE_BASE_URL in .env
# PaaS: https://<instance>/rest/<store_view>/
# SaaS: https://na1.api.commerce.adobe.com/<tenant>/

# 6. Configure payment, shipping, tax
npm run create-payment-methods
npm run create-shipping-carriers
npm run create-tax-integrations

# 7. Update .env with payment codes
# COMMERCE_PAYMENT_METHOD_CODES=["method-1"]

# 8. Configure webhooks (see Webhook Signature section)

# 9. Deploy
aio app deploy --force-build --force-deploy
```

## Project Structure

```
actions/
├── utils.js                              # Parameter validation
├── telemetry.js                          # OpenTelemetry config
├── checkout-metrics.js                   # Checkout-specific metrics/counters
├── validate-payment/index.js             # Validate payment method (webhook)
├── filter-payment/index.js               # Filter available payment methods (webhook)
├── shipping-methods/index.js             # Calculate shipping rates (webhook)
├── collect-taxes/index.js                # Collect taxes (webhook)
├── collect-adjustment-taxes/index.js     # Collect adjustment taxes (webhook)
├── commerce-events/
│   ├── consume.js                        # Commerce event consumer
│   └── events-handler.js                 # Event routing logic
├── 3rd-party-events/
│   ├── publish.js                        # Publish events to 3rd party providers
│   └── consume.js                        # Consume 3rd party events
├── commerce-checkout-starter-kit-info/   # Info action
└── generic/index.js                      # Generic action template
lib/
├── adobe-auth.js                         # IMS token + credential resolution
├── adobe-commerce.js                     # Commerce REST client + webhook helpers
├── env.js                                # .env file manipulation
├── http.js                               # HTTP status constants
├── key-values.js                         # Key-value string encoding/decoding
└── params.js                             # Parameter validation helpers
scripts/
├── sync-oauth-credentials.js             # Auto-sync OAuth creds from workspace
├── create-payment-methods.js             # Create payment methods via Commerce API
├── create-shipping-carriers.js           # Create shipping carriers via Commerce API
├── create-tax-integrations.js            # Create tax integrations via Commerce API
├── get-shipping-carriers.js              # List existing carriers
├── configure-events.js                   # Create event providers
└── configure-commerce-events.js          # Configure Commerce eventing module
commerce-backend-ui-1/                    # Admin UI SDK extension
├── ext.config.yaml
├── actions/
│   ├── registration/index.js             # Extension registration
│   └── commerce/index.js                 # Commerce REST API proxy action
└── web-src/                              # React frontend
hooks/
└── pre-app-build.js                      # Runs sync-oauth-credentials before build
```

## Runtime Actions

| Action | Type | Auth | Purpose |
|--------|------|------|---------|
| `validate-payment` | web, raw-http | No adobe-auth | Validates payment method is supported |
| `filter-payment` | web, raw-http | No adobe-auth | Filters available payment methods per cart/customer |
| `shipping-methods` | web, raw-http | No adobe-auth | Calculates shipping rates |
| `collect-taxes` | web, raw-http | No adobe-auth | Collects taxes for cart items |
| `collect-adjustment-taxes` | web, raw-http | No adobe-auth | Collects adjustment taxes (refunds) |
| `consume` | non-web | adobe-auth | Commerce event consumer |
| `3rd-party-events/publish` | web | adobe-auth | Publish events to external providers |
| `3rd-party-events/consume` | non-web | adobe-auth | Consume external events |
| `info` | web | adobe-auth | Starter kit info |

All actions use `nodejs:22`, `final: true`, and `ENABLE_TELEMETRY: true` for webhook actions.

## Configuration Files

### payment-methods.yaml

```yaml
methods:
  - payment_method:
      code: 'my-payment'
      title: 'My Payment Method'
      active: true
      backend_integration_url: http://oope-payment-method.pay/event
      stores:
        - default
      order_status: processing
      countries:
        - US
      currencies:
        - USD
      custom_config:
        - key: can_refund
          value: true
```

Commerce API endpoint: `V1/oope_payment_method/`

### shipping-carriers.yaml

```yaml
shipping_carriers:
  - carrier:
      code: 'DPS'
      title: 'Demo Postal Service'
      stores: [default]
      countries: [US, CA]
      sort_order: 10
      active: true
      tracking_available: true
      shipping_labels_available: true
```

Commerce API endpoint: `V1/oope_shipping_carrier`

### tax-integrations.yaml

```yaml
tax_integrations:
  - tax_integration:
      code: 'my-tax-provider'
      title: 'My Tax Provider'
      active: true
      stores: [default]
```

Commerce API endpoint: `V1/oope_tax_management/tax_integration`

### events.config.yaml

```yaml
event_providers:
  - label: 3rd party events
    provider_metadata: 3rd_party_custom_events
    description: Events from 3rd party system
    events_metadata:
      - event_code: com.3rdparty.events.test.Event1
        label: Test event 1
  - label: Commerce events provider
    provider_metadata: dx_commerce_events
    description: Events from Adobe Commerce
    subscription:
      - event:
          name: checkout_starter_kit.observer.sales_order_creditmemo_save_after
          parent: observer.sales_order_creditmemo_save_after
          fields:
            - name: '*'
```

## Webhook Signature Verification

All webhook actions verify Commerce webhook signatures using SHA-256:

1. Commerce Admin → Stores → Settings → Configuration → Adobe Services → Webhooks
2. Enable Digital Signature Configuration, Regenerate Key Pair
3. Add public key to `.env`:

```env
COMMERCE_WEBHOOKS_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
-----END PUBLIC KEY-----"
```

The `webhookVerify()` function in `lib/adobe-commerce.js` checks the `x-adobe-commerce-webhook-signature` header against the request body.

### Webhook Response Format

```javascript
// Success
webhookSuccessResponse()
// Returns: { statusCode: 200, body: { op: "success" } }

// Error
webhookErrorResponse("Payment method not supported")
// Returns: { statusCode: 200, body: { op: "exception", message: "..." } }
```

## Webhook Action Patterns

### validate-payment

1. Verify webhook signature
2. Decode `params.__ow_body` (base64 → JSON)
3. Extract `payment_method`, `payment_additional_information`
4. Check against `COMMERCE_PAYMENT_METHOD_CODES` (JSON array from env)
5. Return `webhookSuccessResponse()` or `webhookErrorResponse()`

### filter-payment

Returns operations array to add/remove payment methods:

```javascript
// Remove a payment method
{ op: "replace", path: "result/checkmo/is_available", value: false }

// Conditional: remove if customer group
if (customerGroupId === "1") {
  operations.push({ op: "replace", path: "result/cashondelivery/is_available", value: false });
}
```

### shipping-methods

Returns operations array to add/remove shipping methods:

```javascript
// Add a shipping method
{
  op: "add", path: "result",
  value: {
    carrier_code: "DPS", method: "dps_shipping_one",
    carrier_title: "Demo Postal Service", method_title: "Shipping One",
    amount: 17, available: true,
    additional_data: [{ key: "delivery_date", value: "2025-01-01" }]
  }
}

// Remove a method
{ op: "add", path: "result", value: { method: "flatrate", remove: true } }
```

### collect-taxes

Registered to webhook: `plugin.magento.out_of_process_tax_management.api.oop_tax_collection.collect_taxes`

## Authentication

| Method | When | Env Vars |
|--------|------|----------|
| IMS OAuth | Default (SaaS included) | `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRETS`, `OAUTH_TECHNICAL_ACCOUNT_ID`, `OAUTH_TECHNICAL_ACCOUNT_EMAIL`, `OAUTH_SCOPES`, `OAUTH_IMS_ORG_ID` |
| Commerce Integration (PaaS) | Fallback | `COMMERCE_CONSUMER_KEY`, `COMMERCE_CONSUMER_SECRET`, `COMMERCE_ACCESS_TOKEN`, `COMMERCE_ACCESS_TOKEN_SECRET` |

`npm run sync-oauth-credentials` auto-populates IMS fields from the workspace config.

## Environment Variables

```env
# IMS OAuth (auto-synced)
OAUTH_CLIENT_ID=
OAUTH_CLIENT_SECRETS=[""]
OAUTH_TECHNICAL_ACCOUNT_ID=
OAUTH_TECHNICAL_ACCOUNT_EMAIL=
OAUTH_SCOPES=[""]
OAUTH_IMS_ORG_ID=

# Commerce Integration (PaaS, optional)
COMMERCE_CONSUMER_KEY=
COMMERCE_CONSUMER_SECRET=
COMMERCE_ACCESS_TOKEN=
COMMERCE_ACCESS_TOKEN_SECRET=

# Commerce config
COMMERCE_BASE_URL=                           # Must end with /
COMMERCE_WEBHOOKS_PUBLIC_KEY=                 # For webhook signature verification
COMMERCE_PAYMENT_METHOD_CODES=[""]           # JSON array of payment codes

# Eventing
AIO_EVENTS_PROVIDERMETADATA_TO_PROVIDER_MAPPING=
COMMERCE_ADOBE_IO_EVENTS_MERCHANT_ID=
COMMERCE_ADOBE_IO_EVENTS_ENVIRONMENT_ID=
```

## NPM Scripts

| Script | Purpose |
|--------|---------|
| `npm run sync-oauth-credentials` | Auto-sync OAuth creds from workspace |
| `npm run create-payment-methods` | Create payment methods (reads `payment-methods.yaml`) |
| `npm run create-shipping-carriers` | Create shipping carriers (reads `shipping-carriers.yaml`) |
| `npm run create-tax-integrations` | Create tax integrations (reads `tax-integrations.yaml`) |
| `npm run get-shipping-carriers` | List existing carriers |
| `npm run configure-events` | Create event providers |
| `npm run configure-commerce-events` | Configure Commerce eventing module |
| `npm test` | Run vitest tests |
| `npm run e2e` | Run E2E tests |

## Admin UI SDK Extension

The starter kit includes an Admin UI SDK extension (`commerce-backend-ui-1/`) with:
- Extension registration action
- Commerce REST API proxy action (with full auth)
- React frontend (using `@adobe/react-spectrum`)

Registered in `app.config.yaml` under `extensions.commerce/backend-ui/1`.

## Event Registrations (app.config.yaml)

```yaml
events:
  registrations:
    Event registration for 3rd party system:
      events_of_interest:
        - provider_metadata: 3rd_party_custom_events
          event_codes:
            - com.3rdparty.events.test.Event1
      runtime_action: 3rd-party-events/consume
    Commerce events consumer:
      events_of_interest:
        - provider_metadata: dx_commerce_events
          event_codes:
            - com.adobe.commerce.checkout_starter_kit.observer.sales_order_creditmemo_save_after
      runtime_action: commerce-checkout-starter-kit/consume
```
