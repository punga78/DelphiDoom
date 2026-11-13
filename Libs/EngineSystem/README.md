# Libs\EngineSystem

La parte fredda delle unit `i_*` di `Base\` a classi (issue #185, fase 1, fetta 1d): sequenza di uscita (`I_Destroy`), gestore degli errori fatali (`I_Error`), rapporto di crash, opzioni di rete della riga di comando, scelta del player e della periferica MIDI, player MIDI legacy (MCI), musica a moduli (tracker), buffer dello stdout, nomi dei file di log, profilo della macchina (MMX, 3DNow!, fili).

Non conosce il motore: riceve dal costruttore interfacce piccole (`DelphiDoom.EngineSystem.Intf`) e la composizione (`ComposeEngine`) le dà. Le unit `i_net`, `i_io`, `i_mikplay`, `i_midi`, `i_midi_legacy`, `i_crashlog` e `i_system` di `Base\` sono facciate sopra di lei (vedi `docs\FACCIATE.md`); i passi che toccano suono, video, rete e file sono in `Base\DelphiDoom.Engine.System.*`.

Test: `Tools\build.bat Tests\DelphiDoom.Tests.EngineSystem` (`bin\Tests`), con la copia del vecchio codice per la parità. Dettagli, differenze dal vecchio e difetti conservati: [CLAUDE.md](CLAUDE.md).
