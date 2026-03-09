#!/bin/bash
set -e

EXPORT_DIR="/home/user-ohgh/Desktop/Repo/c2json_standalone"
mkdir -p "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR/src"

echo "Collecting modules..." > bundle.log

# Get modules in order
MODULES=$(./tools/modorder export/C2JsonDriver.cmx)

for obj in $MODULES; do
    echo "Processing $obj" >> bundle.log
    # Convert .cmx to .ml and .mli
    # Note: some files are in subdirectories. We need to find them.
    base=$(echo "$obj" | sed 's/\.cmx//')
    
    # Try to find the .ml file
    ml_file=$(find extraction lib common backend cfrontend cparser driver export debug aarch64 arm powerpc riscV x86 -name "$(basename "$base").ml" | head -n 1)
    mli_file=$(find extraction lib common backend cfrontend cparser driver export debug aarch64 arm powerpc riscV x86 -name "$(basename "$base").mli" | head -n 1)
    
    if [ -n "$ml_file" ]; then
        cp "$ml_file" "$EXPORT_DIR/src/"
        echo "  Copied $ml_file" >> bundle.log
    fi
    if [ -n "$mli_file" ]; then
        cp "$mli_file" "$EXPORT_DIR/src/"
        echo "  Copied $mli_file" >> bundle.log
    fi
done

# Copy generated files that might not be in modorder
cp cparser/pre_parser_messages.ml "$EXPORT_DIR/src/" || true
cp cparser/pre_parser.ml "$EXPORT_DIR/src/" || true
cp cparser/pre_parser.mli "$EXPORT_DIR/src/" || true
cp cparser/Lexer.ml "$EXPORT_DIR/src/" || true

echo "Collection complete." >> bundle.log
