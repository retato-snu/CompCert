#!/bin/bash
# Standalone Exporter Extractor for CompCert

set -e

DEST="./c2json-standalone"
echo "Initializing standalone folder at $DEST..."
mkdir -p "$DEST"
mkdir -p "$DEST/src"

# 1. Identify required modules using modorder
echo "Analyzing dependencies..."
MODULES=$(./tools/modorder .depend.extr export/C2JsonDriver.cmx)

# 2. Copy source files
echo "Copying source files..."
for obj in $MODULES; do
    base=$(echo "$obj" | sed 's/\.cmx//')
    
    # Search for .ml and .mli in all relevant source directories
    ml_file=$(find extraction lib common backend cfrontend cparser driver export debug aarch64 arm powerpc riscV x86 -name "$(basename "$base").ml" | head -n 1)
    mli_file=$(find extraction lib common backend cfrontend cparser driver export debug aarch64 arm powerpc riscV x86 -name "$(basename "$base").mli" | head -n 1)
    
    if [ -n "$ml_file" ]; then cp "$ml_file" "$DEST/src/"; fi
    if [ -n "$mli_file" ]; then cp "$mli_file" "$DEST/src/"; fi
done

# 3. Copy specifically generated files that might not be in the trace
cp cparser/pre_parser_messages.ml "$DEST/src/" || true
cp cparser/pre_parser.ml "$DEST/src/" || true
cp cparser/pre_parser.mli "$DEST/src/" || true
cp cparser/Lexer.ml "$DEST/src/" || true

# 4. Copy backend/PrintCsharpminorJSON.ml explicitly (just in case)
cp backend/PrintCsharpminorJSON.ml "$DEST/src/"

# 5. Copy configuration if needed (mostly headers)
cp VERSION "$DEST/"

# 6. Create Standalone Makefile
echo "Creating Standalone Makefile..."
cat << 'EOF' > "$DEST/Makefile"
# Standalone Makefile for C#minor JSON Exporter
# This Makefile assumes all required .ml and .mli files are in src/

OCAMLOPT=ocamlopt -g -safe-string -I src
LIBS=str.cmxa unix.cmxa
# Assuming menhirLib is installed in the opam environment
MENHIR_LIBS=-I $(shell ocamlfind query menhirLib 2>/dev/null || echo "+menhirLib") menhirLib.cmxa

# We use the pre-calculated order for linking
c2json:
	@echo "Linking c2json..."
	$(OCAMLOPT) -o $@ $(LIBS) $(MENHIR_LIBS) \
		$(shell cat module_list_fixed.txt) src/C2JsonDriver.ml

clean:
	rm -f c2json src/*.cmx src/*.cmi src/*.o
EOF

# Fix the module list to use src/ prefix and .ml extension for the final link
FIXED_MODULES=""
for m in $MODULES; do
    base=$(basename "$m" .cmx)
    # Check if .ml exists in our standalone src
    if [ -f "$DEST/src/$base.ml" ]; then
        FIXED_MODULES="$FIXED_MODULES src/$base.ml"
    fi
done
echo "$FIXED_MODULES" > "$DEST/module_list_fixed.txt"

echo "Extraction complete. Standalone project created in $DEST."
