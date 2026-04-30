---
name: wiki-fetch
description: Ingest one or more new sources from raw/ into the wiki with summary, propagation, index updates, and log entries.
---

# Ingest Command

## Purpose

Add source documents to raw/ directory

## Syntax

    /wiki-fetch <raw-path-or-glob>


## Required Behavior

1. Fetch and convert using markitdown binary 
2. Usage: markitdown <url| file-path> -o raw/<name>.md
   

## Outputs

- A .md file in the raw/articles/ directory

## Examples

    /wiki-fetch example.com/blog/example
    /wiki-fetch path/to/document.pdf
