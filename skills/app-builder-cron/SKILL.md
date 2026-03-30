---
name: app-builder-cron
description: Use when implementing scheduled/recurring tasks (cron jobs) in Adobe App Builder using the OpenWhisk Alarms Package. Covers interval triggers, one-time triggers, cron-based scheduling, manifest.yml configuration, action setup, and deployment for headless App Builder applications that need to run tasks on a schedule (e.g. data imports, batch processing).
---

# Cron Jobs in Adobe App Builder

## Overview

App Builder (built on Adobe I/O Runtime / OpenWhisk) supports scheduled tasks via the **OpenWhisk Alarms Package**. Three feed types are available: `interval`, `once`, and `alarm` (cron).

Scheduled actions are triggered by alarms internally — they should **not** be web actions to prevent unprivileged access.

## Action Setup

Create a non-web action (or set `web: 'no'`). Example action at `actions/generic/index.js`:

```js
const { Core } = require('@adobe/aio-sdk')

async function main (params) {
  const logger = Core.Logger('main', { level: 'info' })

  try {
    logger.info('Calling the main action')
    const currentTime = new Date()
    logger.info(`Current time is ${currentTime.toLocaleString()}.`)

    return {
      timeInMilliseconds: currentTime.getTime(),
      timeInString: currentTime.toLocaleString()
    }
  } catch (error) {
    logger.error(error)
    return { error }
  }
}

exports.main = main
```

## manifest.yml Structure

Cron jobs require three elements in `runtimeManifest`:
1. **Action** — the function to run
2. **Trigger** — the alarm feed that fires at the schedule
3. **Rule** — connects the trigger to the action

```yaml
application:
  actions: actions
  web: web-src
  runtimeManifest:
    packages:
      my-app:
        license: Apache-2.0
        actions:
          generic:
            function: actions/generic/index.js
            web: 'yes'
            runtime: 'nodejs:14'
            inputs:
              LOG_LEVEL: debug
            annotations:
              final: true
        triggers:
          everyMin:
            feed: /whisk.system/alarms/interval
            inputs:
              minutes: 1
        rules:
          everyMinRule:
            trigger: everyMin
            action: generic
```

## Feed Types

### 1. Interval — `/whisk.system/alarms/interval`

Fires a trigger on a recurring minute-based interval.

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `minutes` | Yes | integer | Interval in minutes |
| `trigger_payload` | No | object | Payload passed to action |
| `startDate` | No | ISO-8601 string | When to start firing |
| `stopDate` | No | ISO-8601 string | When to stop firing |

```yaml
triggers:
  everyHour:
    feed: /whisk.system/alarms/interval
    inputs:
      minutes: 60
```

### 2. Once — `/whisk.system/alarms/once`

Fires a trigger exactly once at a specific date/time.

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `date` | Yes | ISO-8601 string | `YYYY-MM-DDTHH:mm:ss.sssZ` |
| `trigger_payload` | No | object | Payload passed to action |
| `deleteAfterFire` | No | boolean | Delete trigger after it fires |

```yaml
triggers:
  runMeOnce:
    feed: /whisk.system/alarms/once
    inputs:
      date: "2027-06-01T09:00:00.000Z"
      deleteAfterFire: true
```

### 3. Cron — `/whisk.system/alarms/alarm`

Fires on a UNIX crontab schedule.

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `cron` | Yes | string | UNIX crontab expression |
| `trigger_payload` | No | object | Payload passed to action |
| `startDate` | No | ISO-8601 string | When to start (must be future date) |
| `stopDate` | No | ISO-8601 string | When to stop (must be future date) |

**Important:** Cron expressions are always evaluated in **UTC**. The `timezone` parameter from upstream OpenWhisk docs is **ignored** in Adobe I/O Runtime. `startDate` and `stopDate` must be ISO-8601 (not epoch milliseconds) and must be future dates at deploy time.

```yaml
triggers:
  sunday2amUTC:
    feed: /whisk.system/alarms/alarm
    inputs:
      cron: "0 2 * * 0"
      startDate: "2027-01-01T00:00:00.000Z"
      stopDate: "2028-01-01T00:00:00.000Z"
```

## Deploy & Verify

```bash
# Deploy
aio app deploy

# List recent activations (verify trigger fired)
aio rt activation list

# Invoke manually to test
aio rt action invoke your-app-name/generic

# Check result and logs
aio rt activation get <ID>
aio rt activation logs <ID>
```

## Common Cron Expressions

| Expression | Schedule |
|------------|----------|
| `0 * * * *` | Every hour (on the hour) |
| `0 2 * * *` | Daily at 2:00 AM UTC |
| `0 2 * * 0` | Every Sunday at 2:00 AM UTC |
| `0 0 1 * *` | First day of every month at midnight UTC |
| `*/15 * * * *` | Every 15 minutes |

## Key Rules

- Actions triggered by alarms do **not** need to be web actions
- Set `web: 'no'` (or omit `web`) to prevent unprivileged access
- Each trigger must have a corresponding rule connecting it to an action
- `timezone` parameter is NOT supported in Adobe I/O Runtime (cron is always UTC)
- For `once` and `alarm` feeds, `startDate`/`stopDate` must be future ISO-8601 dates at deploy time
