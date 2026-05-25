#!/bin/bash
# build.sh - Build Chinese documentation site
# Builds Writerside documentation and optionally Dokka API docs

set -e

OUTPUT_DIR="output-zh"
SITE_DIR="documentation-website-zh/site"

echo "Building Chinese documentation..."

# Clean previous build
rm -rf "$OUTPUT_DIR" "$SITE_DIR"
mkdir -p "$SITE_DIR"

# Build Writerside documentation
echo "Building Writerside documentation..."
docker run --rm \
    -v "$(pwd):/opt/sources" \
    -e SOURCE_DIR=/opt/sources/documentation-website-zh \
    -e MODULE_INSTANCE=Writerside/hi_zh \
    -e OUTPUT_DIR=/opt/sources/"$OUTPUT_DIR" \
    -e RUNNER=other \
    jetbrains/writerside-builder:2026.04.8711

# Extract built documentation
echo "Extracting documentation..."
if [ -f "$OUTPUT_DIR/webHelpHI_ZH2-all.zip" ]; then
    unzip -O UTF-8 "$OUTPUT_DIR/webHelpHI_ZH2-all.zip" -d "$SITE_DIR/"
elif [ -f "$OUTPUT_DIR/webHelpHI_ZH2.zip" ]; then
    unzip -O UTF-8 "$OUTPUT_DIR/webHelpHI_ZH2.zip" -d "$SITE_DIR/"
else
    echo "Error: No output ZIP file found"
    exit 1
fi

echo "Build complete. Output: $SITE_DIR"
