---
description: "Update all Adobe App Builder plugin skills by re-fetching source documentation and applying changes"
---

# Update Adobe App Builder Plugin

You are updating the skills in the Adobe App Builder Claude Code plugin. Follow these steps carefully.

## Step 1: Read the source manifest

Read `sources.json` from the plugin root directory. This file maps each skill to its documentation URLs and GitHub repos, with `lastChecked` dates.

## Step 2: For each skill in sources.json, do the following

### 2a. Fetch all source documentation

- For each URL in `sources`, use WebFetch to retrieve the current documentation content
- For each entry in `githubRepos`, fetch the relevant source files (types, schemas, etc.) using WebFetch on the raw GitHub URLs
- For the `adobe-commerce-sdk-versions` skill, also fetch `https://github.com/adobe/aio-commerce-sdk/releases` to check for new GA releases

### 2b. Read the current skill file

Read the existing `skills/<skill-name>/SKILL.md` file.

### 2c. Compare and identify changes

Compare the fetched documentation against the current skill content. Look for:

- **New fields, types, or APIs** added to the documentation
- **Changed behavior** (validation rules, defaults, limits, etc.)
- **New CLI commands** or options
- **Removed or deprecated features**
- **Updated version numbers** or compatibility information
- **New code examples** or patterns

### 2d. Update the skill if changes are found

If there are material changes:

1. Edit the `SKILL.md` file to reflect the new documentation
2. Preserve the existing frontmatter format (`name` and `description` fields)
3. Keep the same section structure — add new sections only if the docs introduced new topics
4. Do NOT remove information unless it was explicitly removed from the source docs
5. Update code examples only if the API changed

If no material changes are found, skip to the next skill.

## Step 3: Update sources.json

After checking each skill:

1. Update the `lastChecked` date for each skill to today's date
2. Update `lastFullUpdate` to today's date
3. If any source URLs have changed (redirects, new pages), update them

## Step 4: Update the GA baseline (if applicable)

If the `adobe-commerce-sdk-versions` skill was updated with new GA releases:

1. Also update the `hooks/check-ga-versions.sh` script comments if the GA baseline changed
2. Update any version references in `README.md`

## Step 5: Report changes

Provide a summary of what was updated:

```
Plugin Update Summary
=====================
Date: <today>

Skills checked: <count>
Skills updated: <count>

Changes:
- <skill-name>: <brief description of what changed>
- <skill-name>: No changes
...

New source URLs found: <any new pages discovered>
```

## Important Rules

- Do NOT rewrite skills from scratch — only apply incremental changes
- Do NOT change the skill `name` in frontmatter (breaks skill matching)
- Do NOT expand the `description` beyond 1024 characters
- Preserve user-added customizations that aren't from source docs
- If a source URL returns an error or redirect, note it in the summary and skip
- Keep the output concise to minimize token usage
