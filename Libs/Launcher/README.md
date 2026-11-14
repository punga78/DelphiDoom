# Libs\Launcher

Logica del Launcher senza VCL.

| Unit | Ruolo |
|---|---|
| `DelphiDoom.Launcher.Engines` | `TLauncherEngines`: i motori che il Launcher sa avviare (Doom, Heretic, Hexen, Strife, Radix, nell'ordine di `gameengine_t` e del gruppo di opzioni "Engine"), i loro programmi (software e OpenGL), dove cercarli, i loro file di dati principali |

Il Launcher (`Launcher\Launcher_main.pas`) chiede a questa classe il programma da avviare, il motore di un file di dati, il file e il motore predefiniti; la finestra resta quella di prima.

Test: `Tests\DelphiDoom.Tests.Launcher` (`Tools\build.bat Tests\DelphiDoom.Tests.Launcher`).
