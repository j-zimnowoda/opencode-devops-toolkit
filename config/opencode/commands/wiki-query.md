---
name: wiki-query
description: Query the wiki, synthesize a cited answer, and optionally save high-value outputs back into the wiki.
---

# Query Command

## Purpose

Answer research questions from wiki content and compound discoveries into reusable pages.

## Syntax

    /wiki-query "<question>" [--format markdown|table|marp|chart|canvas] [--save <wiki-path>]

## Defaults

- format: markdown
- save: none

## Required Behavior

1. Start from wiki/index.md to find candidate pages.
2. Read relevant wiki pages and source summaries before answering.
3. Provide citations to wiki pages and source paths used.
4. Match output to requested form:
   - markdown: narrative synthesis
   - table: structured comparison
   - marp: slide deck markdown
   - chart: chart-ready data and plotting guidance
   - canvas: visual-structure outline
5. If output is broadly useful, save it as a new wiki page.
6. If --save is used, update wiki/index.md and append wiki/log.md.

## Outputs

- Answer in requested format with citations
- Optional saved page in wiki/
- Index and log updates when saved

## Examples

    /wiki-query "How do retrieval and long-context strategies compare for support bots?" --format table
    /wiki-query "Summarize open risks in our current architecture" --save wiki/comparisons/architecture-risk-summary.md
