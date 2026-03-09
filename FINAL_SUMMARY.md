# CompCert to Scala Integration: C#minor JSON Exporter

This project provides a standalone, lightweight tool to export CompCert's `C#minor` intermediate representation into JSON format, designed for consumption by a Scala analyzer.

## 🚀 Overview

The integration follows a decoupled architecture where CompCert acts as a frontend parser and exporter. This avoids the extreme complexity of native OCaml-JVM bindings while providing a high-performance, maintainable bridge.

### Key Components

1.  **JSON Exporter (`PrintCsharpminorJSON.ml`)**: A custom OCaml module integrated into CompCert that serializes the `Csharpminor` AST.
2.  **Standalone Driver (`C2JsonDriver.ml`)**: A focused entry point that only performs parsing and JSON export, bypassing the full backend and optimization passes.
3.  **Extraction Script (`extract_standalone.sh`)**: Automatically collects the minimal set of OCaml files needed to build the exporter independently.
4.  **Scala AST & Decoders (`Csharpminor.scala`)**: Ready-to-use Scala `case classes` and `io.circe` decoders matching the exported JSON schema.

## 📦 Standalone Project: `c2json-standalone`

You can create a standalone version of the exporter that doesn't depend on the full CompCert build system:

1.  Run `./extract_standalone.sh` in the CompCert root.
2.  Navigate to `./c2json-standalone`.
3.  Run `make` to produce the `c2json` binary.

## 🛠 Integration Guide

### Multi-file Projects
Integrate `c2json` into your `Makefile` or use `compile_commands.json` (from CMake or Bear). The exporter supports standard flags like `-I`, `-D`, and `-m32/-m64`.

### Scala "Linker" Logic
Since analysis is per-file, use a global symbol table in Scala to resolve cross-file references. Example:
```scala
case class GlobalState(
  functions: Map[String, InternalFunDef],
  variables: Map[String, GlobalVarDef]
)
```

## 📖 Related Documents
- [WALKTHROUGH.md](WALKTHROUGH.md): Step-by-step extraction and build guide.
- [Csharpminor.scala](Csharpminor.scala): Scala AST definitions.
