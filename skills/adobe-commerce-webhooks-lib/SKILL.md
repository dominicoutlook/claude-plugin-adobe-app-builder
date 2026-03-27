---
name: adobe-commerce-webhooks-lib
description: Use when building Adobe Commerce webhook handlers using @adobe/aio-commerce-lib-webhooks. Covers the webhooks API client (list/subscribe/unsubscribe), webhook operation responses (success, exception, add, replace, remove), HTTP action response helpers, TypeScript generics, and multiple operation arrays. NOTE: This package is still under development and not yet ready for production use.
---

# Adobe Commerce Webhooks Library (`@adobe/aio-commerce-lib-webhooks`)

> **WARNING:** This package is still under development and is not yet ready for use. You might be able to install it, but you may encounter breaking changes.

Docs: https://github.com/adobe/aio-commerce-sdk/blob/main/packages/aio-commerce-lib-webhooks/docs/usage.md
Official Commerce Webhooks Docs: https://developer.adobe.com/commerce/extensibility/webhooks/

## Installation

```bash
npm install @adobe/aio-commerce-lib-webhooks
```

## Package Subentries

The package uses dedicated subpackage entries for tree-shaking:

| Subpackage | Purpose |
|---|---|
| `@adobe/aio-commerce-lib-webhooks/api` | Webhooks API client — manage webhook subscriptions |
| `@adobe/aio-commerce-lib-webhooks/responses` | Webhook operations and HTTP response helpers |

---

## Webhooks API Client (`/api`)

### Creating a Client

```typescript
import { createCommerceWebhooksApiClient } from "@adobe/aio-commerce-lib-webhooks/api";

const client = createCommerceWebhooksApiClient({
  config: {
    baseUrl: "https://my-commerce-instance.com",
    flavor: "paas", // or "saas"
  },
  auth: {
    /* IMS or Integration auth params */
  },
});
```

### Client Methods

```typescript
// List subscribed webhooks
const webhooks = await client.getWebhookList();
// Returns: array of { webhook_id, webhook_method, webhook_type, batch_name, hook_name, url, ... }

// Subscribe to a webhook
await client.subscribeWebhook({
  webhook_method: "observer.catalog_product_save_after",
  webhook_type: "after",
  batch_name: "my_batch",
  hook_name: "my_hook",
  url: "https://my-app.com/webhook",
  headers: [{ name: "Authorization", value: "Bearer token123" }],
  fields: [{ name: "product_id", value: "entity_id" }],
});

// Unsubscribe by webhook_id
await client.unsubscribeWebhook({ webhook_id: "123" });

// List all available webhook methods
const supportedWebhooks = await client.getSupportedWebhookList();
// Returns: array of { method name, description }
```

### Standalone Functions (without client instance)

```typescript
import { AdobeCommerceHttpClient } from "@adobe/aio-commerce-lib-api";
import {
  getWebhookList,
  subscribeWebhook,
  unsubscribeWebhook,
  getSupportedWebhookList,
} from "@adobe/aio-commerce-lib-webhooks/api";

const httpClient = new AdobeCommerceHttpClient({
  config: { baseUrl: "https://my-commerce-instance.com", flavor: "paas" },
  auth: { /* auth params */ },
});

const webhooks = await getWebhookList(httpClient);
const supported = await getSupportedWebhookList(httpClient);

await subscribeWebhook(httpClient, {
  webhook_method: "observer.catalog_product_save_after",
  webhook_type: "after",
  batch_name: "my_batch",
  hook_name: "my_hook",
  url: "https://my-app.com/webhook",
});

await unsubscribeWebhook(httpClient, {
  webhook_method: "observer.catalog_product_save_after",
  webhook_type: "after",
  batch_name: "my_batch",
  hook_name: "my_hook",
});
```

---

## Webhook Operations and Responses (`/responses`)

### Response Model

- **HTTP 200** with operations = webhook succeeded; operations tell Commerce what to do with the event data
- **HTTP 4xx/5xx** = system/validation failures (not business logic blocks)

The `ok()` helper wraps any operation in an HTTP 200 response.

### Operation Functions

| Function | Purpose |
|---|---|
| `successOperation()` | Allow the process to continue unchanged |
| `exceptionOperation(message, class?)` | Block the process with an error message |
| `addOperation(path, value, type?)` | Add new data to the event |
| `replaceOperation(path, value)` | Modify existing data in the event |
| `removeOperation(path)` | Remove data from the event |

### Success Operation

```typescript
import { successOperation, ok } from "@adobe/aio-commerce-lib-webhooks/responses";

export async function handleWebhook(params) {
  return ok(successOperation());
  // Returns: { type: "success", statusCode: 200, body: { op: "success" } }
}
```

### Exception Operation

```typescript
import { exceptionOperation, successOperation, ok } from "@adobe/aio-commerce-lib-webhooks/responses";

export async function validateStock(params) {
  const stock = await checkInventory(params.product.sku);

  if (stock < params.product.quantity) {
    return ok(
      exceptionOperation("The product cannot be added to the cart because it is out of stock"),
    );
  }
  return ok(successOperation());
}

// With exception class:
return ok(
  exceptionOperation(
    "Insufficient inventory",
    "Magento\\Framework\\Exception\\LocalizedException",
  ),
);
```

### Add Operation

```typescript
import { addOperation, ok } from "@adobe/aio-commerce-lib-webhooks/responses";

export async function addCustomShipping(params) {
  const rate = await calculateShippingRate(params);

  return ok(
    addOperation(
      "result",
      {
        data: {
          amount: rate.toString(),
          carrier_code: "custom_express",
          carrier_title: "Express Shipping",
          method_code: "express",
          method_title: "2-Day Express Delivery",
        },
      },
      "Magento\\Quote\\Api\\Data\\ShippingMethodInterface",
    ),
  );
}

// With TypeScript generics:
type ShippingMethodData = {
  data: {
    amount: string;
    carrier_code: string;
    carrier_title: string;
    method_code: string;
    method_title: string;
  };
};

return ok(addOperation<ShippingMethodData>("result", { data: { /* ... */ } }));
```

### Replace Operation

```typescript
import { replaceOperation, successOperation, ok } from "@adobe/aio-commerce-lib-webhooks/responses";

export async function applyVipDiscount(params) {
  const isVip = await checkVipStatus(params.customer.id);

  if (isVip) {
    const discountedAmount = params.cart.shipping_amount * 0.5;
    return ok(
      replaceOperation("result/shipping_methods/flatrate/amount", discountedAmount),
    );
  }
  return ok(successOperation());
}

// With TypeScript generics:
type PriceData = { amount: number; currency: string; discount?: number };
return ok(replaceOperation<PriceData>("result/price", { amount: 99.99, currency: "USD", discount: 10 }));
```

### Remove Operation

```typescript
import { removeOperation, successOperation, ok } from "@adobe/aio-commerce-lib-webhooks/responses";

export async function restrictPaymentMethods(params) {
  if (params.shippingAddress.country !== "US") {
    return ok(removeOperation("result/payment_methods/cashondelivery"));
  }
  return ok(successOperation());
}
```

### Multiple Operations

Operations are executed in the order they appear. Pass an array to `ok()`:

```typescript
import { addOperation, replaceOperation, removeOperation, ok } from "@adobe/aio-commerce-lib-webhooks/responses";

// Multiple add operations (e.g. multiple shipping options)
return ok([
  addOperation("result", {
    data: { amount: expressRate.toString(), carrier_code: "custom_express", carrier_title: "Express Shipping", method_code: "express", method_title: "2-Day Express" },
  }, "Magento\\Quote\\Api\\Data\\ShippingMethodInterface"),
  addOperation("result", {
    data: { amount: overnightRate.toString(), carrier_code: "custom_overnight", carrier_title: "Overnight Shipping", method_code: "overnight", method_title: "Next Day Delivery" },
  }, "Magento\\Quote\\Api\\Data\\ShippingMethodInterface"),
]);

// Mixed operation types
return ok([
  addOperation("result/shipping_methods", { /* ... */ }),
  replaceOperation("result/shipping_methods/flatrate/amount", 5.99),
  removeOperation("result/payment_methods/cashondelivery"),
]);
```

---

## Relationship to Checkout Starter Kit

The `commerce-checkout-starter-kit` uses its own internal webhook helpers (`webhookSuccessResponse`, `webhookErrorResponse` from `lib/adobe-commerce.js`). The `aio-commerce-lib-webhooks` package is a standalone SDK library that provides a richer, typed alternative with:
- Full TypeScript discriminated union types
- Add/replace/remove operations (not just success/exception)
- A webhooks API client for programmatic subscription management
