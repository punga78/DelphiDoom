# IdTech4\D3Host

Le parti di `idCommon` e `idEventLoop` di Doom 3 (id Tech 4) che esistono prima della sessione, del renderer e del gioco: stampa e redirezione, file di log, avvisi e errori, riga di comando a `+`, ciclo degli eventi con il diario. Issue #255, fase 1 (`docs\DOOM3_CENSIMENTO.md`). Port di `framework\Common.cpp` e `framework\EventLoop.cpp` di `Reference\doom3`. **Licenza**: GPL v3 o successiva con gli "Additional Terms" di Doom 3 (`Reference\doom3\COPYING.txt`: avvisi di marchio e di copyright, manleva), dichiarata in ogni unit; il motore di Doom resta GPL v2 o successiva. Nessun chiamante nel motore.

```pascal
LWorld := ...;                                   // un oggetto che implementa le interfacce di DelphiDoom.D3Host.Intf
LServices.CVars := LWorld; LServices.System := LWorld; ... // TD3HostServices
LHost := TD3HostFactory.CreateCommon(LServices); // TD3CommonHost
LHost.CommandLine.ParseCommandLine(LArguments);
LHost.Printer.Printf('^2hello'#10);
LHost.Diagnostics.Warning('texture missing');
try
  LHost.Errors.Error('a drop');                   // ED3HostException con il renderer; senza, fatale
except
  on E: ED3HostException do ...
end;
LHost.EventLoop.Init; LHost.EventLoop.RunEventLoop;
```

| C++ | Pascal |
|---|---|
| `idCommonLocal::Printf`/`VPrintf`/`DPrintf`/redirect/log | `TD3Printer` |
| `Warning`, `DWarning`, `PrintWarnings`, `DumpWarnings`, `errorList` | `TD3Diagnostics` |
| `Error`, `FatalError` | `TD3ErrorHandler` |
| `ParseCommandLine`, `SafeMode`, `CheckToolMode`, `StartupVariable`, `AddStartupCommands` | `TD3CommandLine` |
| `idEventLoop` | `TD3EventLoop` |

Dettagli (decisioni, difetti del C++ conservati, parita' con il C++ vero, cosa resta): [CLAUDE.md](CLAUDE.md).
