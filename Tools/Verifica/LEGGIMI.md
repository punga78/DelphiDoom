# Tools\Verifica

Programmi, harness e patch temporanei con cui sono state verificate le singole issue (una cartella per issue).
Non fanno parte della build.

## Patch storiche

I file `*.patch` (per esempio `149\hook-doom32.patch`, `harness\hook-*-all.patch`, `harness151\hook151.patch`)
modificano `Doom32.dpr`, `Heretic32.dpr`, `Hexen32.dpr`, `Strife32.dpr`, `GLDoom32.dpr` e `Base\...` **nelle posizioni
che avevano prima della riorganizzazione della radice** (issue #170: i progetti `.dpr`/`.dproj` stanno ora in `Doom\`,
`Heretic\`, `Hexen\`, `Strife\`, ...). Sono quindi storiche: valgono solo per i commit fino a `bf1c87fb`
(l'ultimo prima della riorganizzazione) e non vanno riscritte. Per riusarle su un albero attuale si applicano su un
checkout di `bf1c87fb`, oppure si rifa l'aggancio a mano nel `.dpr` nuovo (clausole `uses` con percorsi `..\Base\...`).

Per lo stesso motivo gli script che generano le patch (`harness\Genera-Patch*.ps1`, `harness\Prepara-Patch.ps1`,
`harness151\apply-hook.pl`) lavorano sul vecchio layout; gli script che compilano (`Compila-*.ps1`) chiamano
`Tools\build.bat` e funzionano con il layout nuovo una volta applicata una patch compatibile.

## Documenti

I documenti `RUN*.md` citati nei commenti dei programmi sono in `docs\`.
