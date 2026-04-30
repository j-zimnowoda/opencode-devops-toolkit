---
name: wiki-ingest
description: Ingest one or more new sources from raw/ into the wiki with summary, propagation, index updates, and log entries.
---

# Ingest Command

## Purpose

Add source documents from raw/ into the knowledge base while keeping raw immutable.

## Syntax

    /wiki-ingest <raw-path-or-glob> [--mode guided|batch] [--max-pages N] [--focus "theme1,theme2"]

## Defaults

- mode: guided
- max-pages: 15
- focus: none

## Required Behavior

1. Never modify files under raw/.
2. Read each source and extract key claims, entities, concepts, and uncertainties.
3. In guided mode, discuss takeaways with the user before writing broad updates.
4. Create or update wiki/sources/[source-name].md with required frontmatter.
5. Update or create related pages in wiki/concepts/ and wiki/entities/.
6. Update wiki/index.md on every ingest.
7. Append one chronological entry per source to wiki/log.md.
8. Use confidence levels when evidence is mixed or incomplete.

## Outputs

- Updated source summaries in wiki/sources/
- Updated concept and entity pages
- Updated wiki/index.md
- Appended wiki/log.md entries

## Examples

    /wiki-ingest raw/papers/attention-is-all-you-need.pdf
    /wiki-ingest raw/articles/*.md --mode batch --focus "evaluation,latency"
