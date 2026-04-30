---
name: wiki-lint
description: Run a health check on the wiki to detect consistency issues, structural gaps, and research opportunities.
---

# Lint Command

## Purpose

Assess wiki health and produce actionable maintenance guidance.

## Syntax

    /wiki-lint [--scope wiki/**] [--with-web-search yes|no] [--save outputs/wiki-lint-YYYY-MM-DD.md]

## Defaults

- scope: wiki/**
- with-web-search: no
- save: outputs/wiki-lint-YYYY-MM-DD.md

## Required Behavior

1. Detect contradictions between pages.
2. Flag stale claims superseded by newer sources.
3. Find orphan pages with no inbound wikilinks.
4. Identify concepts/entities mentioned but missing dedicated pages.
5. Detect missing cross-references among related pages.
6. Call out data gaps and propose targeted follow-up questions and source searches.
7. Save a structured report with severity, affected pages, and recommendations.

## Outputs

- Lint report in outputs/
- Follow-up suggestions for ingest/query tasks

## Examples

    /wiki-lint
    /wiki-lint --with-web-search yes --save outputs/wiki-lint-2026-04-30.md
