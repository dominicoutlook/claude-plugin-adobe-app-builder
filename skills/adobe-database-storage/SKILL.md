---
name: adobe-database-storage
description: Use when creating, configuring, or working with Adobe App Builder database collections, including provisioning, writing runtime actions that use aio-lib-db, setting up app.config.yaml for database access, creating indexes, or querying documents. Also use when migrating from MongoDB to App Builder database or troubleshooting database connectivity in App Builder actions.
---

# Adobe App Builder Database Storage

## Overview

Adobe App Builder provides a managed document database (built on AWS DocumentDB, MongoDB 8.0 compatible) for storing structured data in collections. Each workspace has its own isolated database. The `@adobe/aio-lib-db` library is a near drop-in replacement for the MongoDB Node.js driver.

## When to Use

- Creating a new database collection in an App Builder project
- Writing runtime actions that read/write to the database
- Setting up database provisioning and configuration
- Creating indexes for query performance
- Migrating existing MongoDB code to App Builder

Do NOT use for simple key-value storage (use `@adobe/aio-lib-state` instead) or binary file storage (use `@adobe/aio-lib-files` instead).

## Steps to Create a Collection

### Step 1: Add App Builder Data Services API

In the Adobe Developer Console, add the **App Builder Data Services API** to your project.

### Step 2: Install the library

```bash
npm install @adobe/aio-lib-db
```

### Step 3: Provision the database

Add to `app.config.yaml`:

```yaml
application:
  runtimeManifest:
    database:
      auto-provision: true
      region: amer  # Options: amer, apac, emea, aus
```

Run provisioning:

```bash
aio app db provision --region <region>
```

After provisioning, set `auto-provision: false` to avoid re-provisioning on every deploy:

```yaml
application:
  runtimeManifest:
    database:
      auto-provision: false
      region: amer
```

### Step 4: Configure the action in `app.config.yaml`

Every action that accesses the database needs the `include-ims-credentials` annotation:

```yaml
actions:
  my-action:
    function: actions/my-action/index.js
    annotations:
      include-ims-credentials: true
```

### Step 5: Create the collection

**Via CLI:**

```bash
aio app db collection create <COLLECTION_NAME>
```

With schema validation:

```bash
aio app db collection create <COLLECTION_NAME> --validator '{
  "$jsonSchema": {
    "required": ["userId", "action", "timestamp"],
    "properties": {
      "userId": { "type": "string" },
      "action": { "type": "string" },
      "timestamp": { "type": "date" }
    }
  }
}'
```

**Via runtime action code:**

```javascript
const newCollection = await client.createCollection('my_collection', {
  validator: {
    $jsonSchema: {
      required: ['userId', 'action', 'timestamp'],
      properties: {
        userId: { type: 'string' },
        action: { type: 'string' },
        timestamp: { type: 'date' }
      }
    }
  }
});
```

### Step 6: Create indexes (recommended)

```bash
aio app db index create <COLLECTION> -k <FIELD1> -k <FIELD2>
```

Or in code:

```javascript
await collection.createIndex({ email: 1 }, { unique: true });
await collection.createIndex({ status: 1, createdAt: -1 });
```

### Step 7: Deploy

```bash
aio app deploy
```

## Files That Need Updating When Adding a Collection

| File | Change |
|------|--------|
| `app.config.yaml` | Add `database` block under `runtimeManifest` with `auto-provision` and `region`. Add `include-ims-credentials: true` annotation to each action that uses the DB. |
| `package.json` | Add `@adobe/aio-lib-db` dependency. |
| `actions/<action>/index.js` | Import `aio-lib-db`, initialize connection, use collection. |

## Runtime Action Template

```javascript
const { generateAccessToken } = require('@adobe/aio-sdk').Core.AuthClient;
const libDb = require('@adobe/aio-lib-db');

async function main(params) {
  let client;
  try {
    const token = await generateAccessToken(params);
    const db = await libDb.init({ token: token.access_token });
    // For explicit region: libDb.init({ token: token.access_token, region: 'emea' })
    client = await db.connect();

    const collection = await client.collection('my_collection');

    // --- INSERT ---
    const insertResult = await collection.insertOne({
      name: 'Jane Smith',
      email: 'jane@example.com',
      createdAt: new Date()
    });

    // --- FIND ---
    const doc = await collection.findOne({ email: 'jane@example.com' });
    const docs = await collection.find({ status: 'active' })
      .project({ name: 1, email: 1 })
      .sort({ name: 1 })
      .limit(10)
      .toArray();

    // --- UPDATE ---
    await collection.updateOne(
      { email: 'jane@example.com' },
      { $set: { lastLogin: new Date() } }
    );

    // --- DELETE ---
    await collection.deleteOne({ email: 'jane@example.com' });

    return { statusCode: 200, body: { success: true } };
  } catch (error) {
    if (error.name === 'DbError') {
      console.error('Database error:', error.message);
    }
    return { statusCode: 500, body: { error: error.message } };
  } finally {
    if (client) {
      await client.close();
    }
  }
}

exports.main = main;
```

## ObjectId Handling

```javascript
const { ObjectId } = require('bson');
const doc = await collection.findOne({
  _id: new ObjectId('56fc40f9d735c28df206d078')
});
```

## Aggregation Pipelines

```javascript
const pipeline = [
  { $match: { status: 'active' } },
  { $group: { _id: '$category', count: { $sum: 1 } } },
  { $sort: { count: -1 } }
];
const results = await collection.aggregate(pipeline).toArray();
```

Fluent API also supported:

```javascript
const results = await collection.aggregate()
  .match({ date: { $gte: startDate } })
  .group({ _id: '$category', total: { $sum: '$amount' } })
  .sort({ total: -1 })
  .toArray();
```

## Bulk Operations

```javascript
const result = await collection.bulkWrite([
  { insertOne: { document: { name: 'Alice' } } },
  { updateOne: { filter: { name: 'Bob' }, update: { $set: { age: 30 } } } },
  { deleteOne: { filter: { name: 'Charlie' } } }
]);
```

## CLI Requirements

- `@adobe/aio-cli-plugin-app` v14.7.0+
- `@adobe/aio-cli-plugin-app-storage` v1.5.0+

## CLI Quick Reference

```bash
# Provisioning
aio app db provision [--region <region>]
aio app db status
aio app db ping
aio app db delete

# Collections
aio app db collection create <NAME>
aio app db collection list
aio app db collection rename <OLD> <NEW>
aio app db collection drop <NAME>
aio app db collection stats <NAME>

# Indexes
aio app db index create <COLLECTION> -k <FIELD>
aio app db index list <COLLECTION>
aio app db index drop <COLLECTION> <INDEX_NAME>

# Documents
aio app db document insert <COLLECTION> '<JSON>'
aio app db document find <COLLECTION> '<FILTER>'
aio app db document update <COLLECTION> '<FILTER>' '<UPDATE>'
aio app db document replace <COLLECTION> '<FILTER>' '<REPLACEMENT>'
aio app db document delete <COLLECTION> '<FILTER>'
aio app db document count <COLLECTION> '<FILTER>'

# Stats
aio app db stats
aio app db org stats
```

## Limits

| Resource | Limit |
|----------|-------|
| Storage per pack | 40 GB |
| Bandwidth per pack | 10 TB/month |
| Max collections | 1,000 |
| Request rate | 20,000 req/min per workspace |
| Burst bandwidth | 500 MB/min, 100 MB/sec |
| Document size | 16 MB |
| Default find limit | 20 docs (max 100) |

## Best Practices

- **Always close connections** in a `finally` block
- **Use projections** to reduce data transfer: `.project({ name: 1, email: 1, _id: 0 })`
- **Create indexes** on frequently queried fields
- **Use cursor iteration** for large datasets instead of `.toArray()`
- **Use aggregation** for server-side data processing
- **Region**: defaults to `amer`; set explicitly in `app.config.yaml` or `libDb.init()`

## Unsupported Features

- `$set` and `$unset` aggregation pipeline stages
- Views
- Database selection (workspace-bound, one DB per workspace)
- Direct database admin commands (use CLI or `aio-lib-db` only)
