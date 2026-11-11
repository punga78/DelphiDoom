# Libs\PascalScript

> Note per Claude e paragrafi di dettaglio (issue #178): [CLAUDE.md](CLAUDE.md).

Nucleo di **Pascal Script** (compilatore, interprete, preprocessore, disassemblatore): codice di terzi, modificato per DelphiDoom (issue #172, spostato qui da `SCRIPT\`; la storia dei file resta in git).

Origine: Pascal Script di RemObjects (Carlo Kok), nella versione adattata dal progetto (nomi `ps_*` al posto di `uPS*` per le unit principali). Non è una libreria da convertire a classi: **è già una libreria a classi** (`TPSPascalCompiler`, `TPSExec`, `TPSPreProcessor`...) e si tiene com'è.

| File | Ruolo |
|---|---|
| `ps_defs`, `ps_keywords` | tipi, opcode e parole chiave (iniziano con `{$I Doom32.inc}`) |
| `ps_utils` | utilità (liste, stringhe, `FreeAndNil`) |
| `ps_compiler` | compilatore Pascal -> bytecode |
| `ps_runtime` | interprete del bytecode (chiamate native con `x86.inc`/`x64.inc`) |
| `uPSPreProcessor` | preprocessore (`{$I}`, `{$IFDEF}`...) |
| `uPSDisassembly` | disassemblatore del bytecode |
| `uPSC_dateutils`, `uPSR_dateutils` | funzioni di data per compilatore e runtime |
| `uPSC_dll`, `uPSR_dll` | chiamate a DLL esterne |
| `PascalScript.inc`, `eDefines.inc`, `x86.inc`, `x64.inc`, `arm.inc`, `powerpc.inc` | opzioni di compilazione e assembler per le chiamate native |

## Modifiche locali

- le unit `ps_defs` e `ps_keywords` includono `Doom32.inc` (opzioni di codice del progetto);
- in `ps_compiler` i 13 `asm int 3` (solo `DEBUG`) sono `PS_DebugBreak` (chiama `DebugBreak` di kernel32);
- `ps_runtime` usa `x86.inc`/`x64.inc` (`asm`) per le chiamate native, con un ramo per `CPUX64` (il motore le usa solo da `Libs\OpenGl\Legacy\mdl_script_proclist.pas`, `RegisterDelphiFunction`; vedi `docs\PENDING_ISSUES.md`);
- `ps_utils.PSCharPos(TbtChar, TbtString)` (issue #181) cerca un carattere sui byte di un `TbtString`: sostituisce nelle unit del nucleo le chiamate a `d_delphi.CharPos(Char, string)`, che convertivano ogni argomento in `UnicodeString` (un W1057 per chiamata); con una code page a un byte le posizioni sono le stesse. `uses d_delphi` resta nelle unit (ordine di inizializzazione invariato);
- zero hint e warning del compilatore nei progetti che la compilano (giochi, `ddc`, `ddc_*`, DD_IDE, DDScript, test): le conversioni tra `TbtString` e `string` sono cast espliciti;
- `arm.inc` e `powerpc.inc` non sono usati (nessun target).

## Come si usa

I progetti la raggiungono con `in '..\Libs\PascalScript\x.pas'` nei `.dpr`; i `.dproj` dei giochi hanno `..\Libs\PascalScript` nel `DCC_UnitSearchPath` perché i file `.inc` si includono a catena (`PascalScript.inc` -> `eDefines.inc`) e il compilatore li cerca lì. Il collegamento al motore sta in `Libs\ScriptHost`; la DLL `DDScript` (`Libs\Script`) ne usa il compilatore e l'interprete.
