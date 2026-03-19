---
name: adobe-api-mesh
description: Use when creating, configuring, or troubleshooting Adobe API Mesh for App Builder. Covers mesh.json configuration, handlers (GraphQL, OpenAPI, JsonSchema), transforms (prefix, rename, filterSchema, namingConvention, encapsulate, typeMerging), hooks (beforeAll, afterAll, beforeSource, afterSource), secrets, caching, local development, and all aio api-mesh CLI commands. Also use when combining multiple API sources into a single GraphQL endpoint or integrating Commerce with third-party APIs.
---

# Adobe API Mesh for App Builder

## Overview

API Mesh allows developers to combine multiple APIs (GraphQL, REST, JSON Schema) into a single GraphQL gateway endpoint. It provides a reverse proxy with WAF/DDoS protection, caching, and transforms — without modifying the source APIs.

References:
- https://developer.adobe.com/graphql-mesh-gateway/mesh/
- https://experienceleague.adobe.com/en/docs/commerce-learn/tutorials/extensibility/api-mesh/getting-started-api-mesh

## Prerequisites

- Node.js 18.x (via nvm)
- Adobe IO account
- `aio` CLI installed

```bash
npm install -g @adobe/aio-cli
aio plugins:install @adobe/aio-cli-plugin-api-mesh
```

## Quick Start

### 1. Create a project in Adobe Developer Console

1. Go to [Adobe Developer Console](https://developer.adobe.com/console)
2. Create a project and add a workspace
3. In workspace: **Add Service** > **API** > Filter by **Adobe Experience Platform** > Select **API Mesh for Adobe Developer App Builder**
4. Optionally add: **I/O Management API** and **Adobe Commerce as a Cloud Service**

### 2. Create `mesh.json`

```json
{
  "meshConfig": {
    "sources": [
      {
        "name": "Commerce",
        "handler": {
          "graphql": {
            "endpoint": "https://venia.magento.com/graphql/"
          }
        }
      }
    ]
  }
}
```

### 3. Deploy

```bash
aio auth:login
aio api-mesh:create mesh.json
```

### 4. Get your endpoint

```bash
aio api-mesh:describe
```

Returns: `https://edge-graph.adobe.io/api/<id>/graphql`

**Tip:** Add `Connection: keep-alive` header to requests to avoid cold starts.

## mesh.json Schema

```json
{
  "meshConfig": {
    "sources": [],                    // Required — API source definitions
    "transforms": [],                 // Optional — mesh-level transforms
    "plugins": [],                    // Optional — hooks, onFetch plugins
    "responseConfig": {               // Optional
      "includeHTTPDetails": false,    // Include HTTP request/response details
      "cache": false                  // Enable native caching (disabled by default)
    },
    "disableIntrospection": false     // Disable GraphQL introspection
  }
}
```

**Note:** Each workspace can only have one mesh at a time.

## Handlers

### GraphQL Handler

```json
{
  "name": "MyGraphQLApi",
  "handler": {
    "graphql": {
      "endpoint": "https://my-service/graphql",
      "operationHeaders": {
        "Authorization": "Bearer {context.headers['x-my-api-token']}"
      },
      "schemaHeaders": {
        "x-api-key": "my-key"
      },
      "useGETForQueries": false,
      "method": "POST",
      "source": "./introspection.json"
    }
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `endpoint` | string | Yes | GraphQL endpoint URL |
| `operationHeaders` | object | No | Headers sent with every operation. Supports `{context.headers['header-name']}` templating |
| `schemaHeaders` | object | No | Headers for schema introspection calls |
| `useGETForQueries` | boolean | No | Use HTTP GET for queries |
| `method` | string | No | HTTP method (`GET` or `POST`) |
| `source` | string | No | Path to local introspection file (when remote introspection disabled) |

**Note:** Header names are automatically converted to lowercase.

### OpenAPI Handler

```json
{
  "name": "CommerceREST",
  "handler": {
    "openapi": {
      "source": "https://venia.magento.com/rest/",
      "sourceFormat": "json",
      "operationHeaders": {
        "Authorization": "Bearer {context.headers['x-commerce-token']}"
      },
      "schemaHeaders": {},
      "baseUrl": "https://override-base-url.com",
      "includeHttpDetails": false
    }
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `source` | string | Yes | URL or file path to OpenAPI spec (`.json` or `.yaml`) |
| `sourceFormat` | string | No | `json` or `yaml` |
| `operationHeaders` | object | No | Headers for operations |
| `schemaHeaders` | object | No | Headers for schema introspection |
| `baseUrl` | string | No | Overrides server URL in OpenAPI spec |
| `includeHttpDetails` | boolean | No | Include HTTP details (dev only) |

**Note:** Only processes `application/json` content. Rejects wildcard `*/*` content types. The handler modifies `operationId` values (replaces special chars with underscores).

### JsonSchema Handler

**Important:** Use `JsonSchema` (capital J, capital S), NOT `jsonSchema`.

```json
{
  "name": "carts",
  "handler": {
    "JsonSchema": {
      "baseUrl": "https://my-commerce.com",
      "operationHeaders": {},
      "schemaHeaders": {},
      "operations": [
        {
          "type": "Query",
          "field": "getCart",
          "path": "/cart?id={args.id}",
          "method": "GET",
          "responseSchema": "./schemas/cart-response.json"
        },
        {
          "type": "Mutation",
          "field": "createCart",
          "path": "/cart",
          "method": "POST",
          "requestSchema": "./schemas/cart-request.json",
          "responseSchema": "./schemas/cart-response.json"
        }
      ],
      "ignoreErrorResponses": false
    }
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `baseUrl` | string | Yes | Base URL for requests |
| `operations` | array | Yes | Operation definitions |
| `operations[].type` | string | Yes | `Query`, `Mutation`, or `Subscription` |
| `operations[].field` | string | Yes | GraphQL field name (no hyphens allowed) |
| `operations[].path` | string | Yes | URL path. Supports `{args.argName}` for query params |
| `operations[].method` | string | Yes | HTTP method |
| `operations[].requestSchema` | string | No | Path to request JSON schema (local only) |
| `operations[].requestSample` | string | No | Path to request sample |
| `operations[].responseSchema` | string | No | Path to response JSON schema (local only) |
| `operations[].responseSample` | string | No | Path to response sample |
| `operations[].requestTypeName` | string | No | Custom request type name |
| `operations[].responseTypeName` | string | No | Custom response type name |
| `operations[].argTypeMap` | object | No | Custom argument type definitions |

**Note:** `responseSchema`/`responseSample` must be local files, not remote URLs. JsonSchema handlers do not support `responseConfig`.

#### Query Parameters with argTypeMap

```json
{
  "type": "Query",
  "field": "users",
  "path": "/getUsers",
  "method": "GET",
  "responseSample": "./jsons/users.json",
  "argTypeMap": {
    "page": {
      "type": "object",
      "properties": {
        "limit": { "type": "number" },
        "offset": { "type": "number" }
      }
    }
  },
  "queryParamArgMap": {
    "page": "page"
  }
}
```

## Transforms

Apply at **handler-level** (single source) or **mesh-level** (all sources). Transforms are processed in order.

### prefix

```json
{
  "prefix": {
    "value": "catalog_",
    "includeRootOperations": true,
    "includeTypes": false,
    "ignore": ["IgnoredType"],
    "mode": "bare"
  }
}
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `value` | string | API name | Prefix string |
| `includeRootOperations` | boolean | `false` | Prefix root types/fields |
| `includeTypes` | boolean | `true` | Prefix types |
| `ignore` | string[] | required | Types to exclude |
| `mode` | string | — | `bare` or `wrap` |

### rename

```json
{
  "rename": {
    "mode": "bare",
    "renames": [
      {
        "from": { "type": "Mutation", "field": "integrationCustomerTokenServiceV1CreateCustomerAccessTokenPost" },
        "to": { "type": "Mutation", "field": "CreateCustomerToken" }
      }
    ]
  }
}
```

Supports regex:

```json
{
  "rename": {
    "renames": [
      {
        "from": { "type": "API(.*)" },
        "to": { "type": "$1" },
        "useRegExpForTypes": true
      }
    ]
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| `renames[].from` | object | `{ type, field, argument }` |
| `renames[].to` | object | `{ type, field, argument }` |
| `useRegExpForTypes` | boolean | Enable regex for type matching |
| `useRegExpForFields` | boolean | Enable regex for field matching |
| `useRegExpForArguments` | boolean | Enable regex for argument matching |
| `regExpFlags` | string | Regex flags |

### filterSchema

```json
{
  "filterSchema": {
    "mode": "bare",
    "filters": [
      "Query.!category",
      "Query.!{customerOrders, createCustomer}",
      "Customer.{firstname, lastname, email}",
      "Query.products.{search, sort}",
      "Query.*.!{id, uid}",
      "Type.!Customer"
    ]
  }
}
```

**Filter syntax:**
- `Query.!fieldName` — remove field
- `Type.!TypeName` — remove type
- `Type.{field1, field2}` — keep only these fields
- `Query.field.argName` — keep only this argument
- `Query.*.!argName` — remove argument from all fields

### namingConvention

```json
{
  "namingConvention": {
    "typeNames": "pascalCase",
    "fieldNames": "camelCase",
    "enumValues": "upperCase",
    "fieldArgumentNames": "camelCase"
  }
}
```

Valid values: `camelCase`, `constantCase`, `pascalCase`, `snakeCase`, `upperCase`, `lowerCase`

Do NOT use: `capitalCase`, `dotCase`, `headerCase`, `noCase`, `paramCase`, `pathCase`, `sentenceCase` (violate GraphQL spec).

### encapsulate

Wraps a source schema under a single field:

```json
{
  "encapsulate": {
    "name": "commerce2",
    "applyTo": {
      "query": true,
      "mutation": true,
      "subscription": false
    }
  }
}
```

### typeMerging

Combines types across multiple sources. Supports batching to solve N+1 query problems. Configure via `types` (selection sets, canonical definitions) and `queryFields` (key field identification, key argument mapping).

## Hooks (Plugins)

Hooks execute custom logic at specific points in the request lifecycle. They **cannot modify** request/response data (use custom resolvers for that). Hooks increase processing time — use sparingly.

```json
{
  "meshConfig": {
    "sources": [...],
    "plugins": [
      {
        "hooks": {
          "beforeAll": {
            "composer": "./hooks.js#isAuth",
            "blocking": true
          },
          "afterAll": {
            "composer": "./hooks.js#logResponse",
            "blocking": false
          },
          "beforeSource": {
            "Commerce": [
              { "composer": "./hooks.js#addToken", "blocking": true }
            ]
          },
          "afterSource": {
            "Commerce": [
              { "composer": "./hooks.js#processResponse", "blocking": false }
            ]
          }
        }
      }
    ]
  }
}
```

### Hook Types

| Hook | When | Can Block | Can Modify |
|------|------|-----------|------------|
| `beforeAll` | Before query execution | Yes | Can add headers via `data.headers` |
| `afterAll` | After all sources resolve | No | Can modify `data.result` |
| `beforeSource` | Before querying a specific source | Yes | Can modify `data.request` (url, headers, method, body) |
| `afterSource` | After querying a specific source | No | Can modify `data.response` (body, headers, status) |

### Hook Composer (local example)

```javascript
module.exports = {
  isAuth: ({ context }) => {
    if (!context.headers.authorization) {
      return { status: "ERROR", message: "Unauthorized" };
    }
    return { status: "SUCCESS", message: "Authorized" };
  },
};
```

### Hook Payload Context

```typescript
interface HookPayloadContext {
  request: Request;
  params: GraphQLParams;
  body?: unknown;
  headers?: Record<string, string>;
  secrets?: Record<string, string>;   // Local hooks only
  state?: StateApi;                    // Local hooks only
  logger?: Logger;                     // Local hooks only
}
```

### Local vs Remote Composers

| | Local | Remote |
|---|---|---|
| Timeout | 30 seconds | No limit |
| Network calls | Supported via `fetch()` | Native |
| Access to secrets/state/logger | Yes | No |
| Restricted constructs | `eval`, `new Function()`, `process`, `setTimeout`, `setInterval`, `WebAssembly`, `window`, `alert`, `debugger` | None |

### onFetch Plugin

Intercepts HTTP requests before they're sent to sources:

```json
{
  "plugins": [
    {
      "onFetch": [
        {
          "source": "commerceAPI",
          "handler": "./handleOnFetch.js"
        }
      ]
    }
  ]
}
```

```javascript
async function handleOnFetch(data) {
  data.options.headers["x-custom-header"] = "value";
}
module.exports = { default: handleOnFetch, __esModule: true };
```

## Secrets

Secrets are encrypted using AES-256. Values cannot be retrieved after creation.

### secrets.yaml

```yaml
TOKEN: $TOKEN
USERNAME: user-name
API_KEY: ${COMMERCE_API_KEY}
```

Supports Bash variables (`$VAR` or `${VAR}`). Not supported on Windows. Escape literal `$` with `\$`.

### Use in mesh.json

```json
"operationHeaders": {
  "Authorization": "Bearer {context.secrets.TOKEN}"
}
```

### Use in hooks/resolvers

```javascript
const apiKey = context.secrets.API_KEY;
```

### Deploy with secrets

```bash
aio api-mesh:create mesh.json --secrets secrets.yaml
aio api-mesh:update mesh.json --secrets secrets.yaml
```

**Important:** Always include `--secrets` when updating a mesh that has secrets, or values are overwritten with literal references.

## Caching

Disabled by default. Two options: native caching or third-party CDN.

### Enable native caching

```json
{
  "meshConfig": {
    "responseConfig": {
      "cache": true,
      "includeHTTPDetails": true
    }
  }
}
```

### Caching requirements

**Cached only when:**
- Request is `GET` or `POST` query (not mutation)
- Not an introspection query
- Response status 200-299
- No GraphQL errors
- `cache-control` header has public cache-eligible directives

### Source-level default cache-control

```json
{
  "name": "Commerce",
  "handler": { "graphql": { "endpoint": "..." } },
  "responseConfig": {
    "cache": {
      "cacheControl": "public, max-age=100"
    }
  }
}
```

### Cache conflict resolution (multiple sources)

- `no-store` overrides all
- `private` overrides `public`
- For time-based directives (`max-age`, `s-maxage`, etc.) — lowest value wins
- Boolean directives (`no-cache`, `must-revalidate`, etc.) — additive

### Purge cache

```bash
aio api-mesh:cache:purge -a
aio api-mesh:cache:purge -a -c    # auto-confirm
```

### Cache variance

Use `x-api-mesh-vary` header:

```
x-api-mesh-vary: customer-group
customer-group: premium
```

### Verify caching (response headers)

| Header | Description |
|--------|-------------|
| `Cache-Status` | `HIT` or `MISS` |
| `Age` | Cached response age (seconds) |
| `Etag` | Unique response identifier |
| `Expires` | UTC expiry date |
| `Last-Modified` | UTC date cached |

## Local Development

```bash
# Create local environment
aio api-mesh:init my-project

# Run locally
aio api-mesh:run mesh.json --port 9000
# Default: http://localhost:5000/graphql

# Debug mode (attach IDE on port 9229)
aio api-mesh:run mesh.json --debug
```

### Environment variables in mesh.json

`.env`:
```
APIName='Adobe Commerce API'
commerceURL='https://my-commerce.com/graphql'
PORT=9000
```

Use with `{{env.VARIABLE_NAME}}`:

```json
{
  "meshConfig": {
    "sources": [
      {
        "name": "{{env.APIName}}",
        "handler": {
          "graphql": { "endpoint": "{{env.commerceURL}}" }
        }
      }
    ]
  }
}
```

```bash
aio api-mesh:create mesh.json --env .env
aio api-mesh:run mesh.json --env .env_local
```

### Referenced files

- Only `.js`, `.json`, `.ts`, `.graphql` formats
- Path must be < 25 characters
- Must be in same directory as mesh file
- Cannot be in `~` or home directory
- Declare in `files` array of mesh config

## CLI Command Reference

| Command | Description |
|---------|-------------|
| `aio api-mesh:create [FILE]` | Create a mesh (`-c` auto-confirm, `--secrets FILE`, `--env FILE`) |
| `aio api-mesh:update [FILE]` | Update a mesh (`-c`, `--secrets FILE`, `--env FILE`) |
| `aio api-mesh:delete` | Delete current workspace mesh |
| `aio api-mesh:get [FILE]` | Download mesh config (`--json`, `--active`) |
| `aio api-mesh:describe` | Get mesh endpoint, API key, IDs |
| `aio api-mesh:status` | Check deployment status (Success/Pending/Building/Error) |
| `aio api-mesh:init PROJECTNAME` | Create local dev environment |
| `aio api-mesh:run [FILE]` | Run mesh locally (`--port`, `--debug`, `--select`, `--env`) |
| `aio api-mesh:source:discover` | List available prebuilt sources |
| `aio api-mesh:source:install "NAME"` | Install a prebuilt source (`-v` variables, `-f` variable file) |
| `aio api-mesh:source:get` | Get source details |
| `aio api-mesh:cache:purge` | Purge cache (`-a` all, `-c` auto-confirm) |
| `aio api-mesh:log-list` | List 15 most recent requests by rayID |
| `aio api-mesh:log-get RAYID` | Get logs for a specific request |
| `aio api-mesh:log-get-bulk` | Bulk download logs (`--startTime`, `--endTime`, `--past`, max 30 min range) |
| `aio api-mesh:config:set:log-forwarding` | Configure log forwarding |
| `aio api-mesh:config:get:log-forwarding` | Get log forwarding config |
| `aio api-mesh:config:delete:log-forwarding` | Delete log forwarding config |

### Workspace management

| Command | Description |
|---------|-------------|
| `aio console:project:list` | List projects |
| `aio console:workspace:list` | List workspaces |
| `aio console:project:select` | Switch project |
| `aio console:workspace:select` | Switch workspace |
| `aio config:get console` | View cached project/workspace |

## Multi-Source Example (Commerce + AEM + Catalog Service)

```json
{
  "meshConfig": {
    "sources": [
      {
        "name": "Commerce",
        "handler": {
          "graphql": {
            "endpoint": "https://my-commerce.com/graphql/"
          }
        }
      },
      {
        "name": "AEM",
        "handler": {
          "graphql": {
            "endpoint": "https://my-aem.com/endpoint.json"
          }
        }
      },
      {
        "name": "CatalogService",
        "handler": {
          "graphql": {
            "endpoint": "https://catalog-service.adobe.io/graphql/",
            "operationHeaders": {
              "x-api-key": "{context.secrets.CATALOG_API_KEY}",
              "Magento-Environment-Id": "<env_id>",
              "Magento-Website-Code": "base",
              "Magento-Store-Code": "main_website_store",
              "Magento-Store-View-Code": "default"
            },
            "schemaHeaders": {
              "x-api-key": "{context.secrets.CATALOG_API_KEY}"
            }
          }
        },
        "transforms": [
          {
            "prefix": {
              "includeRootOperations": true,
              "includeTypes": false,
              "value": "catalog_"
            }
          }
        ]
      }
    ]
  }
}
```

## Handler Versions

| Handler | Version |
|---------|---------|
| graphql | 0.34.13 |
| openapi | 0.33.39 |
| JsonSchema | 0.35.38 |

## Transform Versions

| Transform | Version | Status |
|-----------|---------|--------|
| rename | 0.14.22 | Fully supported |
| prefix | 0.12.22 | Fully supported |
| filterSchema | 0.15.23 | Fully supported |
| namingConvention | 0.13.22 | Fully supported |
| typeMerging | 0.5.20 | Fully supported |
| encapsulate | 0.4.21 | Accepted, not fully tested |
| federation | 0.11.14 | Accepted, not fully tested |

## Limitations

- One mesh per workspace
- Only `application/json` content for OpenAPI handler
- Only single-encoded URL parameters (double-encoded rejected)
- JsonSchema `responseSchema`/`responseSample` must be local files
- Referenced files must be < 25 char path, same directory as mesh file
- Local hook composers timeout at 30 seconds
- `cacheControl` headers from sources cannot be overridden by mesh config
- Log bulk download: max 30 min range, last 30 days only
- GET requests limited to 2,048 characters when caching enabled
