#!/bin/bash
set -ex

SRC_DIR="/home/user-ohgh/Desktop/Repo/CompCert"
DEST_DIR="/home/user-ohgh/Desktop/Csharpminor-Exporter"

rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR/bin"
mkdir -p "$DEST_DIR/src"

OBJS="extraction/Datatypes.cmx extraction/Orders.cmx extraction/OrdersTac.cmx extraction/OrderedType.cmx extraction/List0.cmx extraction/EquivDec.cmx extraction/BinNums.cmx extraction/Nat.cmx extraction/BinPosDef.cmx extraction/BinPos.cmx extraction/BinNat.cmx extraction/BinInt.cmx extraction/ZArith_dec.cmx extraction/Coqlib.cmx extraction/Maps.cmx extraction/Ordered.cmx extraction/Int0.cmx extraction/OrdersAlt.cmx extraction/OrdersFacts.cmx extraction/MSetInterface.cmx extraction/MSetAVL.cmx extraction/FSetAVL.cmx extraction/Errors.cmx extraction/Zpower.cmx extraction/Bool.cmx lib/Readconfig.cmx lib/Responsefile.cmx lib/Commandline.cmx driver/Configuration.cmx extraction/Archi.cmx extraction/Zbits.cmx extraction/Integers.cmx extraction/Zaux.cmx extraction/Zbool.cmx extraction/SpecFloat.cmx extraction/Round.cmx extraction/BinarySingleNaN.cmx extraction/Binary.cmx extraction/IEEE754_extra.cmx extraction/Bits.cmx extraction/Floats.cmx extraction/AST.cmx extraction/Ctypes.cmx extraction/Values.cmx extraction/Znumtheory.cmx extraction/Memtype.cmx extraction/PeanoNat.cmx extraction/Memdata.cmx extraction/Memory.cmx extraction/Cop.cmx extraction/BoolEqual.cmx extraction/Op.cmx extraction/Machregs.cmx extraction/Locations.cmx extraction/Conventions1.cmx driver/Clflags.cmx extraction/Compopts.cmx extraction/Clight.cmx extraction/SimplLocals.cmx extraction/Csyntax.cmx lib/Camlcoq.cmx extraction/SimplExpr.cmx common/PrintAST.cmx extraction/Cminor.cmx extraction/Csharpminor.cmx backend/PrintCsharpminorJSON.cmx driver/Version.cmx driver/Timing.cmx cparser/Diagnostics.cmx cparser/Machine.cmx cparser/Env.cmx cparser/Cprint.cmx cparser/Cutil.cmx common/Sections.cmx extraction/Initializers.cmx backend/Machregsnames.cmx x86/Machregsaux.cmx cparser/Ceval.cmx x86/CBuiltins.cmx cparser/ExtendedAsm.cmx debug/Debug.cmx extraction/Ctyping.cmx backend/AisAnnot.cmx cfrontend/C2C.cmx cfrontend/PrintCsyntax.cmx cparser/Unblock.cmx cparser/Transform.cmx cparser/SwitchNorm.cmx cparser/StructPassing.cmx cparser/Rename.cmx extraction/Specif.cmx extraction/Alphabet.cmx extraction/Grammar.cmx extraction/Automaton.cmx extraction/Interpreter_correct.cmx extraction/FMapList.cmx extraction/FMapAVL.cmx extraction/Validator_complete.cmx extraction/Interpreter_complete.cmx extraction/Validator_safe.cmx extraction/Interpreter.cmx extraction/Main.cmx extraction/Cabs.cmx extraction/Parser.cmx cparser/PackedStructs.cmx cparser/pre_parser_aux.cmx cparser/pre_parser.cmx cparser/pre_parser_messages.cmx cparser/ErrorReports.cmx cparser/Lexer.cmx cparser/Cleanup.cmx cparser/Checks.cmx cparser/Cflow.cmx cparser/Cabshelper.cmx cparser/Elab.cmx cparser/Parse.cmx driver/Driveraux.cmx lib/Tokenize.cmx cfrontend/CPragmas.cmx driver/Frontend.cmx extraction/Cshmgen.cmx driver/CommonOptions.cmx export/CsharpminorJSONDriver.cmx"

for obj in $OBJS; do
    base=$(basename "$obj" .cmx)
    dir=$(dirname "$obj")
    
    if [ "$base" = "CsharpminorJSONDriver" ]; then
        cp "$SRC_DIR/$dir/$base.ml" "$DEST_DIR/bin/main.ml"
    else
        # Copy .ml
        if [ -f "$SRC_DIR/$dir/$base.ml" ]; then
            cp "$SRC_DIR/$dir/$base.ml" "$DEST_DIR/src/"
        fi
        
        # Copy .mli
        if [ -f "$SRC_DIR/$dir/$base.mli" ]; then
            cp "$SRC_DIR/$dir/$base.mli" "$DEST_DIR/src/"
        fi
    fi
done

cat > "$DEST_DIR/dune-project" << 'EOF'
(lang dune 3.0)
EOF

cat > "$DEST_DIR/bin/dune" << 'EOF'
(executable
 (name main)
 (public_name c2json)
 (libraries compcert_frontend str unix menhirLib))
EOF

cat > "$DEST_DIR/src/dune" << 'EOF'
(library
 (name compcert_frontend)
 (flags -w -a)
 (libraries str unix menhirLib))
EOF
