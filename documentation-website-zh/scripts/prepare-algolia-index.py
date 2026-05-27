#!/usr/bin/env python3

from __future__ import annotations

import json
import sys
from pathlib import Path


ALLOWED_FIELDS = {
    "objectID",
    "parent",
    "pageViews",
    "url",
    "mainTitle",
    "product",
    "headings",
    "content",
    "pageTitle",
    "metaDescription",
    "type",
    "breadcrumbs",
    "root",
    "depth",
    "version",
}


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: prepare-algolia-index.py <index-dir>")

    index_dir = Path(sys.argv[1])
    if not index_dir.is_dir():
        raise SystemExit(f"Index directory not found: {index_dir}")

    for record_path in index_dir.rglob("*.json"):
        record = json.loads(record_path.read_text(encoding="utf-8"))
        filtered = {key: value for key, value in record.items() if key in ALLOWED_FIELDS}
        record_path.write_text(json.dumps(filtered, ensure_ascii=False), encoding="utf-8")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
