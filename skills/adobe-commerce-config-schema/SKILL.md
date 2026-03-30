---
name: adobe-commerce-config-schema
description: Use when creating or editing an app.commerce.config.ts schema file for Adobe Commerce App Builder extensions, defining configuration fields (text, password, email, url, tel, list), setting up scope trees, managing encrypted passwords, or working with the @adobe/aio-commerce-lib-config library. Also use when adding new configuration parameters, syncing Commerce scopes, or troubleshooting config validation errors.
---

# Adobe Commerce Config Schema (`app.commerce.config.ts`)

## Overview

The `@adobe/aio-commerce-lib-config` library provides hierarchical, scope-aware configuration for Adobe Commerce App Builder extensions. Configuration is defined as a typed schema in `app.commerce.config.ts` and supports inheritance across scopes (global → website → store → store_view).

Package: `@adobe/aio-commerce-lib-config`
Install: `pnpm add @adobe/aio-commerce-lib-config`

Reference: https://github.com/adobe/aio-commerce-sdk/tree/main/packages/aio-commerce-lib-config

## Schema File Template

Create `app.commerce.config.ts` in your project root:

```typescript
import type { BusinessConfigSchema } from "@adobe/aio-commerce-lib-config";

const schema: BusinessConfigSchema = [
  {
    name: "api_key",
    label: "API Key",
    description: "The API key for the external service",
    type: "text",
    default: "",
  },
  {
    name: "api_secret",
    label: "API Secret",
    description: "The API secret (encrypted at rest)",
    type: "password",
  },
  {
    name: "admin_email",
    label: "Admin Email",
    description: "Notification email address",
    type: "email",
    default: "",
  },
  {
    name: "webhook_url",
    label: "Webhook URL",
    description: "Endpoint for callbacks",
    type: "url",
    default: "",
  },
  {
    name: "support_phone",
    label: "Support Phone",
    description: "Support contact number",
    type: "tel",
    default: "",
  },
  {
    name: "environment",
    label: "Environment",
    description: "Target environment",
    type: "list",
    selectionMode: "single",
    options: [
      { label: "Production", value: "production" },
      { label: "Staging", value: "staging" },
    ],
    default: "production",
  },
  {
    name: "enabled_features",
    label: "Enabled Features",
    description: "Features to activate",
    type: "list",
    selectionMode: "multiple",
    options: [
      { label: "Sync Orders", value: "sync_orders" },
      { label: "Sync Inventory", value: "sync_inventory" },
      { label: "Sync Customers", value: "sync_customers" },
    ],
    default: [],
  },
];

export default schema;
```

## Field Types Reference

### Base Fields (all types)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `string` | Yes | Unique field identifier. Must be non-empty. |
| `label` | `string` | No | Display label for UI. |
| `description` | `string` | No | Help text describing the field. |
| `type` | `string` | Yes | One of: `"text"`, `"password"`, `"email"`, `"url"`, `"tel"`, `"list"` |

### `type: "text"`

Plain text input. No validation on the value.

```typescript
{
  name: "api_key",
  label: "API Key",
  description: "External service API key",
  type: "text",
  default: "",          // optional, defaults to ""
}
```

| Field | Type | Required | Default | Validation |
|-------|------|----------|---------|------------|
| `default` | `string` | No | `""` | None |

### `type: "password"`

Sensitive value. Automatically encrypted at rest using AES-256-GCM. Cannot have a custom default.

```typescript
{
  name: "api_secret",
  label: "API Secret",
  type: "password",
  // default is always "" — custom defaults are NOT allowed
}
```

| Field | Type | Required | Default | Validation |
|-------|------|----------|---------|------------|
| `default` | `""` only | No | `""` | Must be empty string. No custom default allowed. |

### `type: "email"`

Email address input with format validation.

```typescript
{
  name: "admin_email",
  label: "Admin Email",
  type: "email",
  default: "admin@example.com",  // optional, must be valid email or ""
}
```

| Field | Type | Required | Default | Validation |
|-------|------|----------|---------|------------|
| `default` | `string` | No | `""` | Must be valid email format or empty string |

### `type: "url"`

URL input with format validation.

```typescript
{
  name: "webhook_url",
  label: "Webhook URL",
  type: "url",
  default: "https://api.example.com/webhook",  // optional, must be valid URL or ""
}
```

| Field | Type | Required | Default | Validation |
|-------|------|----------|---------|------------|
| `default` | `string` | No | `""` | Must be valid URL format or empty string |

### `type: "tel"`

Phone number input with pattern validation.

```typescript
{
  name: "support_phone",
  label: "Support Phone",
  type: "tel",
  default: "+1-555-123-4567",  // optional
}
```

| Field | Type | Required | Default | Validation |
|-------|------|----------|---------|------------|
| `default` | `string` | No | `""` | Must match `/^\+?[0-9\s\-()]+$/` or be empty string |

### `type: "list"` with `selectionMode: "single"`

Dropdown / single-select. Requires a non-empty default.

```typescript
{
  name: "environment",
  label: "Environment",
  type: "list",
  selectionMode: "single",
  options: [
    { label: "Production", value: "production" },
    { label: "Staging", value: "staging" },
  ],
  default: "production",   // REQUIRED, must be non-empty string
}
```

| Field | Type | Required | Default | Validation |
|-------|------|----------|---------|------------|
| `selectionMode` | `"single"` | Yes | — | Literal |
| `options` | `Array<{ label: string; value: string }>` | Yes | — | At least one option |
| `default` | `string` | **Yes** | — | Must be non-empty string |

### `type: "list"` with `selectionMode: "multiple"`

Multi-select. Default is an optional array.

```typescript
{
  name: "enabled_features",
  label: "Enabled Features",
  type: "list",
  selectionMode: "multiple",
  options: [
    { label: "Sync Orders", value: "sync_orders" },
    { label: "Sync Inventory", value: "sync_inventory" },
  ],
  default: ["sync_orders"],  // optional, defaults to []
}
```

| Field | Type | Required | Default | Validation |
|-------|------|----------|---------|------------|
| `selectionMode` | `"multiple"` | Yes | — | Literal |
| `options` | `Array<{ label: string; value: string }>` | Yes | — | At least one option |
| `default` | `string[]` | No | `[]` | Each item must be non-empty string |

## Schema Validation Rules

- Schema must contain **at least one field** (`minLength(1)`)
- `name` must be a non-empty string on every field
- `type` must be one of: `"text"`, `"password"`, `"email"`, `"url"`, `"tel"`, `"list"`
- For `list` type, `selectionMode` must be `"single"` or `"multiple"`
- Single-select lists **require** a non-empty `default`
- Password fields **cannot** have a custom default (must be `""`)
- Email defaults must pass email format validation
- URL defaults must pass URL format validation
- Tel defaults must match `/^\+?[0-9\s\-()]+$/`

## Initializing the Schema

In your runtime action or app entry point:

```typescript
import { initialize } from "@adobe/aio-commerce-lib-config";
import schema from "./app.commerce.config.json" with { type: "json" };

await initialize({ schema });
```

This registers the schema with the config service. Call once at app startup. **Schema is stored in memory only** — it is not persisted and must be provided on every startup. Configuration functions will throw `Error: Schema not initialized. Call initialize({ schema }) before using configuration functions.` if called before initialization.

## Password Encryption

Password fields are automatically encrypted/decrypted using AES-256-GCM.

### Setup encryption key

```bash
# Generate and write key to .env
npx @adobe/aio-commerce-lib-config encryption setup

# Validate existing key
npx @adobe/aio-commerce-lib-config encryption validate
```

This adds `AIO_COMMERCE_CONFIG_ENCRYPTION_KEY` to your `.env` file.

### Key requirements

- Exactly **64 hex characters** (32 bytes for AES-256)
- Stored in env var `AIO_COMMERCE_CONFIG_ENCRYPTION_KEY`

### Programmatic key management

```typescript
import {
  generateEncryptionKey,
  validateEncryptionKey,
} from "@adobe/aio-commerce-lib-config";

const key = generateEncryptionKey();   // returns 64-char hex string
validateEncryptionKey(key);            // throws if invalid
```

### Encrypted storage format

Values are stored as: `enc:INITIALIZATION_VECTOR:AUTH_TAG:ENCRYPTED_DATA`

### Using encryption in operations

**Encryption is strictly enforced** — setting or getting a password field without an `encryptionKey` will throw an error. There is no plain text fallback.

```typescript
import { setConfiguration, getConfiguration, byScopeId } from "@adobe/aio-commerce-lib-config";

// Set — password auto-encrypted (throws if encryptionKey missing)
await setConfiguration(
  { config: [{ name: "api_secret", value: "my-secret" }] },
  byScopeId("scope-uuid"),
  { encryptionKey: process.env.AIO_COMMERCE_CONFIG_ENCRYPTION_KEY },
);

// Get — password auto-decrypted (throws if encryptionKey missing)
const result = await getConfiguration(
  byScopeId("scope-uuid"),
  { encryptionKey: process.env.AIO_COMMERCE_CONFIG_ENCRYPTION_KEY },
);
```

### Key rotation

```typescript
import { generateEncryptionKey, getConfiguration, setConfiguration } from "@adobe/aio-commerce-lib-config";

// 1. Get all configs with old key
const oldConfig = await getConfiguration(byScopeId("scope-uuid"), {
  encryptionKey: "old-key",
});

// 2. Generate new key
const newKey = generateEncryptionKey();

// 3. Re-save with new key (re-encrypts all password fields)
await setConfiguration({ config: oldConfig.config }, byScopeId("scope-uuid"), {
  encryptionKey: newKey,
});
```

## Scope Tree & Configuration Inheritance

### Inheritance order (highest to lowest priority)

1. **Target Scope** — value set directly on requested scope
2. **Parent Scopes** — walking up the hierarchy
3. **Global Scope** — application-wide defaults
4. **Schema Defaults** — `default` values from the schema (origin: `{ code: "default", level: "system" }`)

### Commerce scope mapping

When syncing from Adobe Commerce:

| Commerce Entity | Scope Level | `is_editable` | `is_final` | `is_removable` |
|----------------|-------------|---------------|------------|-----------------|
| Website | `"website"` | `true` | `true` | `false` |
| Store Group | `"store"` | `false` | `true` | `false` |
| Store View | `"store_view"` | `true` | `true` | `false` |

All Commerce scopes live under a parent `"commerce"` node.

### Sync Commerce scopes

```typescript
import { syncCommerceScopes } from "@adobe/aio-commerce-lib-config";
import { resolveCommerceHttpClientParams } from "@adobe/aio-commerce-sdk/api";

const commerceConfig = resolveCommerceHttpClientParams(params);
const result = await syncCommerceScopes(commerceConfig);
// result: { synced: boolean }
```

Commerce REST endpoints used: `store/websites`, `store/storeGroups`, `store/storeViews`.

### Custom scope tree

```typescript
import { setCustomScopeTree } from "@adobe/aio-commerce-lib-config";

await setCustomScopeTree({
  scopes: [
    {
      code: "region_us",
      label: "United States",
      level: "region",        // optional, defaults to "base"
      is_editable: true,
      is_final: false,
      children: [
        {
          code: "warehouse_east",
          label: "East Coast Warehouse",
          is_editable: true,
          is_final: true,
        },
      ],
    },
  ],
});
```

### Custom scope validation rules

- `code`: non-empty string, **cannot** be `"commerce"` or `"global"` (reserved)
- `label`: non-empty string
- `level`: non-empty string if provided (defaults to `"base"`)
- `is_editable`: boolean (required)
- `is_final`: boolean (required)
- `id`: non-empty string if provided (auto-generated if omitted)
- `children`: array if provided (recursively validated)
- Duplicate `code:level` combinations are **forbidden** across the entire tree
- Custom scopes always get `is_removable: true`

## Getting the Scope Tree

```typescript
import { getScopeTree } from "@adobe/aio-commerce-lib-config";

// Returns cached scope tree
const result = await getScopeTree();
// result: { scopeTree: ScopeNode[], isCachedData: boolean }
console.log(result.scopeTree);
console.log("Using cached data:", result.isCachedData);

// Force refresh from Commerce API
const freshResult = await getScopeTree(
  { refreshData: true, commerceConfig },
  { cacheTimeout: 600000 },
);
```

## Getting the Config Schema

```typescript
import { getConfigSchema } from "@adobe/aio-commerce-lib-config";

const schema = await getConfigSchema();
// Returns: array of field definitions
```

## Removing Commerce Scopes

```typescript
import { unsyncCommerceScopes } from "@adobe/aio-commerce-lib-config";

// Removes all persisted Commerce scope data
const { unsynced } = await unsyncCommerceScopes();
if (unsynced) {
  console.log("Commerce scopes removed successfully");
}
```

## Scope Selectors

Three ways to select a scope for get/set operations:

```typescript
import { byScopeId, byCode, byCodeAndLevel } from "@adobe/aio-commerce-lib-config";

// By UUID
byScopeId("550e8400-e29b-41d4-a716-446655440000");

// By code (matches first scope with this code)
byCode("default_website");

// By code + level (exact match)
byCodeAndLevel("default_website", "website");
```

## Reading & Writing Configuration

```typescript
import {
  getConfiguration,
  getConfigurationByKey,
  setConfiguration,
  byScopeId,
  byCode,
} from "@adobe/aio-commerce-lib-config";

// Get all config for a scope (with inheritance)
const all = await getConfiguration(byCode("default_website"));
// Returns: { scope: { id, code, level }, config: ConfigValue[] }

// Get single key
const single = await getConfigurationByKey("api_key", byCode("default_website"));
// Returns: { scope: { id, code, level }, config: ConfigValue | null }

// Set config on a scope
await setConfiguration(
  {
    config: [
      { name: "api_key", value: "sk-12345" },
      { name: "environment", value: "staging" },
    ],
  },
  byScopeId("scope-uuid"),
);
```

### ConfigValue shape

```typescript
type ConfigValue = {
  name: string;                          // field name from schema
  value: string | string[];              // current value
  origin: {
    code: string;                        // scope code where value was set
    level: string;                       // scope level (or "system" for defaults)
  };
};
```

## Operation Options

```typescript
type OperationOptions = {
  cacheTimeout?: number;   // seconds, default 300 (5 min)
};

type ConfigOptions = OperationOptions & {
  encryptionKey?: string;  // 64-char hex for password encrypt/decrypt
};
```

## Storage Internals

| Data | Storage Path |
|------|-------------|
| Scope tree | `{namespace}/scope-tree.json` |
| Config per scope | `scope/{scopeCode}/configuration.json` |
| Schema | `config-schema.json` |
| Cache keys | `{namespace}:scope-tree`, `{namespace}:config-schema`, `configuration.{scopeCode}` |

Default namespace: `aio-commerce-config`
Default cache timeout: `300` seconds (5 minutes)

Uses `@adobe/aio-lib-state` for caching and `@adobe/aio-lib-files` for persistence.

## TypeScript Types Reference

```typescript
// Schema types
type BusinessConfigSchema = BusinessConfigSchemaField[];

type BusinessConfigSchemaField =
  | { name: string; label?: string; description?: string; type: "text"; default?: string }
  | { name: string; label?: string; description?: string; type: "password"; default?: "" }
  | { name: string; label?: string; description?: string; type: "email"; default?: string }
  | { name: string; label?: string; description?: string; type: "url"; default?: string }
  | { name: string; label?: string; description?: string; type: "tel"; default?: string }
  | { name: string; label?: string; description?: string; type: "list"; selectionMode: "single"; options: BusinessConfigSchemaListOption[]; default: string }
  | { name: string; label?: string; description?: string; type: "list"; selectionMode: "multiple"; options: BusinessConfigSchemaListOption[]; default?: string[] };

type BusinessConfigSchemaListOption = { label: string; value: string };
type BusinessConfigSchemaValue = string | string[];

// Scope types
type ScopeNode = {
  id: string; code: string; label: string; level: string;
  is_editable: boolean; is_final: boolean; is_removable: boolean;
  commerce_id?: number; children?: ScopeNode[];
};

// Config types
type ConfigValue = { name: string; value: BusinessConfigSchemaValue; origin: ConfigOrigin };
type ConfigOrigin = { code: string; level: string };

// Commerce types
type Website = { id: number; name: string; code: string; default_group_id: number; extension_attributes?: Record<string, unknown> };
type StoreGroup = { id: number; website_id: number; root_category_id: number; default_store_id: number; name: string; code: string; extension_attributes?: Record<string, unknown> };
type StoreView = { id: number; code: string; name: string; website_id: number; store_group_id: number; is_active: boolean; extension_attributes?: Record<string, unknown> };
```

## Files to Update When Adding Config

| File | Change |
|------|--------|
| `app.commerce.config.ts` | Create/update schema with field definitions |
| `package.json` | Add `@adobe/aio-commerce-lib-config` dependency |
| `.env` | Add `AIO_COMMERCE_CONFIG_ENCRYPTION_KEY` if using password fields |
| Action entry file | Import schema, call `initialize({ schema })` at startup |
