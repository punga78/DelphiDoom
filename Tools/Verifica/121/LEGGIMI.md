# Verifica #121: rete di Quake III

Produce `Tests\Data\Net\q3net-golden.txt` con il codice **vero** di Quake III (`huffman.c`, `msg.c`, `net_chan.c`), non riscritto: `build.sh` ritaglia per intervalli di righe i tre file di `Reference\quake3\code\qcommon`, le struct di `qcommon.h` e di `game\q_shared.h`; `stubs.h` e l'inizio di `netgen.c` sostituiscono il resto del motore (cvar, errori con `longjmp`, `NET_SendPacket` che registra i datagrammi); `netgen.c` ha gli scenari.

```
sh Tools/Verifica/121/build.sh <cartella di uscita>
<cartella>/netgen.exe > Tests/Data/Net/q3net-golden.txt
```

- Compilatore: gcc a 64 bit di `Reference\_dati\_strumenti\w64devkit`, `-O0 -fwrapv` (shift e somme come i compilatori x86 a 32 bit dell'epoca).
- Gli scenari sono ripetuti da `Tests\Source\DelphiDoom.Tests.Net.Q3Parity.pas` (stessi generatori xorshift32, stessi semi, stessi formati di riga): se si cambia uno scenario vanno rifatti entrambi.
- `printf` con piu' letture nella stessa chiamata non si usa: l'ordine di valutazione degli argomenti non e' definito (le letture passano da `pBits`, `pByte`...).
- `scrubStack` azzera la pila prima di `Huff_Compress` e `Huff_Decompress`: il C lascia non inizializzato il byte in piu' che copia e i byte di un flusso troncato.
- Il caso `MSG_ReadDeltaKey` con 32 bit non c'e': `kbitmask[32]` e' fuori dalla tabella (comportamento indefinito).
