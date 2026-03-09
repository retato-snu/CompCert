# Standalone C#minor JSON Exporter Walkthrough

## Summary
The goal was to separate the `C#minor` JSON exporting functionality from the full CompCert compiler into a lightweight, standalone OCaml project. This allows for faster builds and easier integration into other tools (like a Scala analyzer) without needing the entire CompCert codebase.

## Project Structure
The standalone project is designed to reside in `c2json-standalone/` and contains:
- `src/`: A collection of minimal `.ml` and `.mli` files required for parsing C and generating C#minor.
- `Makefile`: A simplified build file for the `c2json` binary.
- `module_list_fixed.txt`: The exact linking order required for the OCaml compiler.
- `C2JsonDriver.ml`: The dedicated entry point for the standalone exporter.

## How to Extract and Build

### 1. Preparation
Ensure you are in the root of the CompCert repository and have the OPAM environment active.
```bash
eval $(opam env)
```

### 2. Extraction
Run the extraction script I've created. This script uses CompCert's `modorder` to find only the necessary files and copies them into `./c2json-standalone`.
```bash
chmod +x extract_standalone.sh
./extract_standalone.sh
```

### 3. Build
Navigate to the new standalone directory and run `make`.
```bash
cd c2json-standalone
make
```
This will produce a `c2json` binary in the directory.

### 4. Testing
You can now test the standalone exporter on a C file:
```bash
./c2json test.c
```
This will generate `test.csm.json`, containing the `C#minor` AST.

## Scala Integration: Linker Logic

When analyzing large projects, you will have multiple `.csm.json` files. You can use the following pattern in Scala to "link" them:

```scala
case class GlobalState(
  functions: Map[String, Csharpminor.GlobDef.InternalFunDef] = Map.empty,
  variables: Map[String, Csharpminor.GlobDef.GlobalVarDef] = Map.empty
)

def link(programs: List[Csharpminor.Program]): GlobalState = {
  programs.foldLeft(GlobalState()) { (state, prog) =>
    prog.defs.foldLeft(state) { (st, definition) =>
      definition match {
        case f @ Csharpminor.GlobDef.InternalFunDef(func) =>
          st.copy(functions = st.functions + (func.id -> f))
        case v @ Csharpminor.GlobDef.GlobalVarDef(id, _) =>
          st.copy(variables = st.variables + (id -> v))
        case _ => st // Skip external/duplicate definitions
      }
    }
  }
}
```

This allows your Scala analyzer to resolve cross-file references by looking up function bodies in the global map.

## Key Features of the Standalone Project
- **Lightweight**: Only includes the frontend and the JSON printer.
- **Fast Build**: Compiles in seconds compared to minutes for the full CompCert.
- **Decoupled**: Does not require Coq or the full CompCert backend to build or run.
- **Easy Deployment**: The `c2json-standalone` directory can be moved and used independently.
