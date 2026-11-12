# Xcom32: disegno a 32 bit e interfaccia a risoluzione più alta (issue #183)

Analisi fatta **prima** di scrivere codice (fetta 1). Le fette successive aggiornano il capitolo "Stato" in fondo.

## 1. Com'è fatto oggi

- Ogni cosa che si vede è una `TXcomSurface` (`Libs\XcomSurface`): pixel a **8 bit**, una palette di 256 `TXcomColor`,
  colore 0 trasparente. Gli stati copiano le loro superfici sulla **superficie base** dello schermo
  (`TXcomState.Blit` -> `TXcomScreen.GetSurface`), poi il gioco ci copia contatore dei fotogrammi e cursore
  (`TXcomGame`, `DelphiDoom.XcomEngine.Game.pas:684-687`).
- `TXcomScreen.Flip` (`DelphiDoom.XcomEngine.Screen.pas`) ingrandisce la base alla misura della finestra col pixel più
  vicino (`Zoom`, port di `Zoom::_zoomSurfaceY`) e dà al dispositivo **indici + palette**
  (`IXcomVideoDevice.Present`). Con `useOpenGL` il dispositivo riceve la base non ingrandita (`PresentUnscaled`).
- La conversione a colori avviene **una volta sola, alla fine, nel dispositivo**: GDI con una DIB a 8 bit e la tabella
  dei colori (`TGameHostWinGdiVideoDevice.Present`), OpenGL con una tabella di 256 `Cardinal`
  (`TGameHostWinOpenGlVideoDevice.Draw`).
- **Sullo schermo c'è sempre una sola palette** (`TXcomScreen.SetPalette`, differita al flip come `SDL_SetColors`).
  Le "palette miste" del gioco sono *una* palette di 256 colori composta a pezzi: la palette della schermata
  (`PAL_GEOSCAPE`, `PAL_BASESCAPE`, `PAL_BATTLESCAPE`...) più un blocco di 16 colori di `BACKPALS.DAT` in posizione
  224 (`TXcomState.SetPalette(nome, backpals)`, `State.pas:562-576`), o i 256 colori della battaglia in corso
  (`SetInterface` col terzo argomento, `State.pas:352-354`). Le superfici portano una copia della palette, ma al
  momento del `Blit` **contano solo gli indici**: un popup con un'altra palette cambia la palette di tutto lo
  schermo (come nel vero OpenXcom: è il motivo per cui il geoscape "cambia colore" sotto certi popup).

Conseguenza: la parità sui pixel col vero OpenXcom è parità **sugli indici della superficie base** e sulla palette
dello schermo. Tutto ciò che segue non deve toccare né gli uni né l'altra.

## 2. Censimento: dove il gioco dipende dalla palette a 8 bit

Per ogni voce: dove sta, che cosa fa con gli indici, l'equivalente a 32 bit, il rischio (B basso, M medio, A alto) e
l'ordine proposto (fetta della #183 o "dopo").

| # | Dipendenza | File e routine | Che cosa fa con gli indici | Equivalente a 32 bit | Rischio | Ordine |
|---|---|---|---|---|---|---|
| 1 | Palette unica dello schermo, differita | `XcomEngine.Screen` `SetPalette`/`Flip`; `XcomEngine.State` `SetPalette`, `Init` (`State.pas:427-435`) | gli indici si traducono al flip con la palette corrente | la traduzione si sposta dal dispositivo al **compositore** (stessa tabella, stesso momento): pixel identici | B | fetta 2 |
| 2 | Blocchi `BACKPALS` e palette della battaglia | `State.SetPalette(nome, backpals)`, `SetInterface`, `TXcomStateHost.BattlePalette` | sostituiscono 16 o 256 voci della palette unica | nessun cambiamento: restano voci della palette che il compositore applica | B | fetta 2 |
| 3 | Sfumature per offset d'indice nei controlli | `XcomUi.Window.pas:187-227`, `Frame.pas:101-113`, `TextButton.pas:193-240` (`Invert`), `Bar.pas:146-160`, `Cursor.pas:78-87`, `ArrowButton`, `ScrollBar`, `Slider`, `ComboBox` | il bordo è `colore + n` dentro un blocco di 16; il pulsante premuto è `Invert(mezzo)` | restano a 8 bit; ad alta risoluzione le **cornici** si ridisegnano alla scala vera con gli stessi indici (rettangoli concentrici di spessore 1 pixel vero o `s` pixel) | M | fetta 3, dopo il globo |
| 4 | Colore del testo per offset | `XcomUi.Text.pas:426-454` (`SetColor`, `SetInvert`, contrasto), `XcomSurface.Font` (i glifi hanno indici 1..5, `Offset(colore)`), `TextList.pas`, `NumberText` (`TXcomSurfaceShader`) | il glifo è una rampa di 5 indici spostata sul colore | **issue #184** (font TTF): il testo ad alta risoluzione non ha più una rampa d'indici ma copertura (alpha) per un colore RGB preso dalla palette (`colore + 1..5` -> interpolazione); aggancio dichiarato al §5 | A | #184 |
| 5 | Globo: ombra della notte | `XcomGeoscape.Globe.pas` `DrawShadow` (940-979), `ShadowValue`, `FShadeGradient`, rumore 60x60 | terra: `indice + ombra/3` saturato nel blocco di 16; mare (`OceanShading`): `OceanColor + ombra` su 32 indici | fetta 3: stesso calcolo per indice ma **per pixel vero** (normale della sfera calcolata alla risoluzione alta, rumore ingrandito). Fetta 4: ombra continua (moltiplicazione RGB, niente scalini da 16) | M | fetta 3 / 4 |
| 6 | Globo: terra a texture | `Globe.DrawLand` -> `TXcomGfx.DrawTexturedPolygon` (`XcomSurface.Gfx`), texture 32x32 di `TEXTURE.DAT` | poligoni riempiti con la texture ripetuta in coordinate di schermo | poligoni rasterizzati alla risoluzione vera, texture ingrandita col pixel più vicino (stesso disegno, bordi lisci) | M | fetta 3 |
| 7 | Globo: linee | `Globe.XuLine` (1052-1118: radar e rotte, **legge** il pixel sotto e lo schiarisce di `ombra`), `DrawDetail` (`TXcomGfx.DrawLine`, confini), `DrawOcean` (`DrawCircle`) | linee di 1 pixel base; `XuLine` dipende dall'indice che trova | le stesse routine su una superficie `s` volte più grande: linee di 1 pixel vero | M | fetta 3 |
| 8 | Globo: marcatori che lampeggiano | `Globe.Blink` (799-808): `FMarkerSet.GetFrame(i).Offset(±1)` | il lampeggio è uno spostamento d'indice | immagini originali ingrandite; il lampeggio resta lo stesso `Offset` | B | fetta 3 |
| 9 | Battlescape: luce delle tegole e delle unità | `XcomBattlescape.Map.pas` `BlitShade` (426-439), `DrawUnit` (944-952), `DrawTerrain`; `XcomSurface.Shade` (`TXcomStandardShade`: `indice + ombra` saturato nel blocco di 16, 16 livelli) | l'ombra è un passo dentro la rampa di 16 indici del colore | luce continua: `RGB * f(ombra)` con la curva ricavata dalle rampe della palette (o interpolata tra due livelli durante il passo: oggi `LUnitShade` è già un'interpolazione intera, 944) | A | fetta 4 |
| 10 | Battlescape: sprite ricolorati | `XcomBattlescape.UnitSprite*.pas` (`TXcomColorReplaceShade`, tabelle di ricolorazione di capelli/pelle/divisa), `Inventory`, `MedikitView`, `ModSprites` | sostituzione del blocco di 16 (`newBaseColor`) tenendo l'ombra | restano a 8 bit (sono *contenuto*): la ricolorazione avviene prima della composizione | B | non toccare |
| 11 | Battlescape: fumo e fuoco | `Map.pas` 953-969 (fotogrammi di `SMOKE.PCK` con ombra, copertura per densità), `Map.DrawParticles` (706-727) con `TXcomTransparencyTable` (`Mod::createTransparencyLUT`: per tinta, 4 opacità, l'**indice più vicino** al colore mescolato) | la trasparenza è una tabella indice->indice (256 colori: bande e colori sbagliati) | alpha vero: `dst = dst*(1-a) + tinta*a` sullo strato RGBA; per il fumo di `SMOKE.PCK` un alpha dalla densità al posto del fotogramma pieno | A | fetta 4 |
| 12 | Battlescape: proiettili, esplosioni, cursore 3D, frecce | `Map.pas` (`CreateArrow` 289-313, `Offset` 882-928), `Projectile`, `Explosion` | sprite a indici con `Offset` | restano a 8 bit, ingranditi | B | non toccare |
| 13 | Dissolvenze | `XcomMenu.VideoState.pas:346-373` (`FadeStep`: 20 passi sulla **palette** dello schermo), `XcomMenu` diapositive; `StartState` | la dissolvenza scala i 256 colori della palette | funziona da sé (la palette è applicata alla composizione); a 32 bit si potrebbe fare per pixel, ma non serve | B | nessuno |
| 14 | Cicli e lampeggi a indici | `XcomBattleStates.WarningMessage.pas` (colore che scende di un indice per passo), `XcomGeoscape.BaseDefenseState`, `DogfightState.pas` (`Offset`, radar, 15 accessi ai pixel), `TextList` (riga selezionata: `Offset`/`Invert`), `ScrollBar` | animazioni fatte spostando indici | restano a 8 bit | B | non toccare |
| 15 | Colore più vicino in palette | `XcomSurface.Sdl.FindColor`, `XcomSurface.Gfx` (`DrawLine`/`DrawString`: `SDL_MapRGBA`, tabella 3-3-2) | un RGB chiesto diventa l'indice più vicino | a 32 bit il colore chiesto si usa direttamente; riguarda solo `DrawString` (FPS, debug) | B | dopo |
| 16 | Immagini con palette propria | `XcomEngine.ModResources` (`.SCR/.BDY/.SPK/.LBM`, PNG a palette degli `extraSprites`), `XcomMenu.VideoState` (FLI/FLC: palette per fotogramma), `XcomUfopaedia.ArticleState` | l'immagine porta indici pensati per *una* palette; lo stato la impone allo schermo | restano così; una sola palette per fotogramma basta sempre (anche FLC) | B | nessuno |
| 17 | Screenshot e `-shot` | `Screen.DisplayPixels`, `OpenXcom\ShotRunner.Shot`, `TXcomMemoryVideoDevice` | salvano indici + palette | il percorso a 8 bit resta com'è; con la composizione a 32 bit `-shot` salva il fotogramma RGB composto | B | fetta 2 |
| 18 | Filtri e shader OpenGL | `GameHost.Win.OpenGlVideoDevice` (`PresentUnscaled`: lo shader lavora sull'immagine 320x200) | lo shader riceve l'immagine base convertita | con la composizione a 32 bit lo shader riceve il fotogramma **già composto** alla misura della finestra (cambia il risultato degli shader che ingrandiscono: dichiarato) | M | fetta 2 |
| 19 | Minimappa, scanner, medikit, grafici | `XcomBattleStates.MiniMapView` (ombra per indice), `ScannerView`, `XcomGeoscape.GraphsState` (linee con `TXcomGfx.DrawLine`), `XcomBasescape.BaseView` | misto di sprite e linee | le **linee dei grafici** sono vettoriali: stesso meccanismo del globo (strato di dettaglio) | M | dopo il globo |

### I cinque punti più rischiosi

1. **Ordine di copia e strati di dettaglio (fetta 3).** Le superfici si copiano una sull'altra sulla base a 8 bit: chi
   disegna "alla risoluzione vera" non può scrivere sulla base. Serve uno strato ad alta risoluzione *per widget* e
   una regola per sapere, pixel per pixel, se quel widget è ancora visibile o è stato coperto (pulsanti, popup,
   cursore). Un errore qui si vede come dettagli del globo che bucano una finestra.
2. **Luce del Battlescape (voce 9).** L'ombra a 16 passi dentro la rampa è *il look* del gioco e le rampe della
   palette non sono lineari né uguali tra colori: una luce RGB continua cambia i colori (i blocchi con rampe corte
   saturano prima). Va ricavata dalle rampe vere, colore per colore.
3. **Fumo, fuoco e particelle (voce 11).** Oggi sono indici scelti da una tabella; l'alpha vero vuole che la mappa
   tattica si componga in RGBA (strato della mappa separato dal pannello), cioè un secondo bersaglio di disegno per
   `TXcomBattleMap` e l'ordine di disegno per tegola conservato.
4. **Testo (voce 4, #184).** Glifi a rampe d'indici contro glifi a copertura: due agenti sulla stessa classe
   (`TXcomText`). Qui non si tocca; si lascia l'aggancio (uno strato di dettaglio come quello del globo).
5. **Parità (tutte).** Ogni routine condivisa tra il percorso a 8 bit e quello nuovo (il globo che si disegna due
   volte, lo schermo che compone in due modi) può spostare un pixel del percorso vecchio. Regola: il percorso nuovo
   è **aggiunto** (oggetti in più creati solo se la strategia c'è), mai un ramo dentro un ciclo esistente; verifica
   byte per byte di `-shot`/`-script` e delle suite dopo ogni fetta.

## 3. Architettura proposta

```
stati e widget (8 bit, invariati) ──Blit──> superficie base (8 bit) ──┐
widget vettoriali (globo) ──strato di dettaglio (8 bit, s volte più grande)──┤
                                                                       v
TXcomScreen.Flip ── senza strategia ──> Zoom a indici ──> IXcomVideoDevice.Present(indici, palette)    [oggi, predefinito]
                └── IXcomFrameComposer ──> fotogramma BGRA alla misura della finestra ──> IXcomTrueColorDisplay.PresentTrueColor
```

- **Dove sta la conversione.** In una classe nuova di `Libs\XcomEngine`, `TXcomTrueColorComposer`
  (`IXcomFrameComposer`): riceve dal flip la superficie base, la palette differita, la misura dello schermo e le
  bande nere, e produce un fotogramma `TArray<Cardinal>` (`$FFRRGGBB`, righe dall'alto) alla misura della finestra,
  ingrandendo con gli stessi passi di `Zoom` (stessa tabella dei passi: a qualunque scala il pixel scelto è lo
  stesso del percorso a 8 bit). La palette è applicata **qui**.
- **Quale interfaccia cambia.** Nessuna firma esistente. Si aggiungono:
  `IXcomFrameComposer` e `IXcomDetailLayers` (`DelphiDoom.XcomEngine.TrueColor.Intf`), l'interfaccia opzionale del
  dispositivo `IXcomTrueColorDisplay` (come `IXcomWindowStyle`/`IXcomFilteredDisplay`: chi non ce l'ha non è
  usato), e in `Libs\GameHost` `IGameHostTrueColorDisplay` (unit nuova) implementata dai dispositivi GDI (DIB a 32
  bit) e OpenGL (la texture BGRA che già usa) e inoltrata dal selettore. `TXcomScreen.Create` prende un terzo
  argomento facoltativo (`AComposer = nil`).
- **Come si sceglie il percorso.** Nel composition root (`OpenXcom\DelphiDoom.Xcom.GameComposition.pas`): se le
  impostazioni chiedono la composizione a 32 bit (`-truecolor` sulla riga di comando o `trueColor: true` in
  `options.cfg`) **e** il dispositivo è un `IXcomTrueColorDisplay`, lo schermo riceve un `TXcomTrueColorComposer`;
  altrimenti `nil` e lo schermo fa esattamente ciò che fa oggi. Nessun `{$IFDEF}`, nessun `if` nei widget: un widget
  chiede `Host.Screen.DetailLayers` e, se è `nil` o la scala è 1, non fa nulla di nuovo.
- **Strati di dettaglio (fetta 3).** `IXcomDetailLayers`: `DetailScale` (intero: finestra = base × s senza bande,
  altrimenti 1), `BeginLayer(base, rettangolo)` prima che il widget si copi sulla base e `EndLayer(base, dettaglio)`
  dopo. Il compositore tiene due copie del rettangolo (prima e dopo la copia del widget). Al flip, per ogni pixel
  base del rettangolo: se l'indice finale è ancora quello lasciato dal widget, i suoi `s × s` pixel veri vengono dallo
  strato di dettaglio (dove lo strato è trasparente, da ciò che c'era *prima* del widget); se è cambiato (un
  pulsante, un popup, il cursore sopra), si usa il pixel base ingrandito. Così l'ordine di copia resta quello del
  gioco senza toccare `TXcomSurface.Blit`. Limite dichiarato: un pixel coperto da qualcosa con lo **stesso indice**
  è preso per scoperto (l'errore è un dettaglio del widget dello stesso colore: non visibile).
- **Il globo.** `TXcomGlobe` non cambia le sue routine: quando c'è una scala di dettaglio possiede un **secondo
  globo** `s` volte più grande (stessa classe, costruito con le texture e i marcatori ingranditi col pixel più
  vicino), gli copia vista e stato prima di disegnare e ne dà la composizione come strato. Le routine sono le stesse:
  poligoni, cerchi e linee vengono rasterizzati alla risoluzione vera per costruzione.
- **Aggancio per #184 (testo TTF).** Lo strato di dettaglio è il punto d'ingresso: un `TXcomText` ad alta risoluzione
  si registrerà con `BeginLayer`/`EndLayer` come il globo. Finché #184 non c'è, le etichette del globo sono il testo
  a 8 bit ingrandito (`TXcomGlobe.BlitLabel`, unico punto da sostituire). Per l'alpha dei glifi servirà uno strato
  RGBA (oggi lo strato è a indici): `IXcomDetailLayers` andrà esteso con un `EndLayer` che prende pixel BGRA; il
  compositore ha già tutto il resto.

## 4. Che cosa non conviene fare

- **Portare `TXcomSurface` a 32 bit.** Tutto il contenuto, i controlli e gli effetti (voci 3, 8, 10, 12, 14) sono
  aritmetica sugli indici; i golden di centinaia di schermate sono impronte di indici. Si perderebbe la parità per
  guadagnare nulla: l'originale *è* a 256 colori.
- **Una palette per superficie alla composizione.** Lo schermo ne ha una sola per costruzione (§1); comporre "per
  superficie con la sua palette" cambierebbe i pixel dove oggi un popup ricolora lo sfondo, cioè romperebbe la
  parità a scala 1. La composizione per strato serve solo agli strati di dettaglio, che usano la stessa palette.
- **Filtri di ingrandimento (HQx, xBRZ) sul fotogramma composto**: inventano pixel; il mandato è immagini originali
  col pixel più vicino e vettori veri.
- **Rasterizzare i vettori con l'antialiasing** in questa fase: richiede lo strato RGBA e cambia l'aspetto (linee
  grigie su terra a 256 colori). Prima la geometria vera a indici, poi (fetta 4) l'alpha.
- **Riscrivere `DrawTexturedPolygon`/`XuLine` con coordinate in virgola mobile "più precise"** nel percorso a 8 bit:
  sono port fedeli di SDL_gfx e di `Globe.cpp` e hanno i loro golden.
- **Far scalare l'immagine allo shader OpenGL quando c'è la composizione a 32 bit**: i due ingrandimenti non si
  compongono (lo strato di dettaglio esiste solo alla misura finale).

## 5. Ordine dei lavori

1. Fetta 2: compositore, interfacce, dispositivi, `-truecolor`, `-shot` RGB; verifica a scala 1 (pixel uguali) e a
   scala 2 (uguale allo zoom a indici convertito).
2. Fetta 3: strati di dettaglio e globo; poi cornici (`Window`, `Frame`, `TextButton`) e linee dei grafici.
3. Fetta 4 (solo dopo): strato RGBA, luce continua del Battlescape, fumo/fuoco/particelle con alpha.

## 6. Stato

- Fetta 1 (questo documento): fatta.
- **Fetta 2 (composizione finale in RGBA): fatta.** Come al §3. `TXcomScreen` riceve il compositore dal composition
  root (`TXcomGameComposition.CreateFrameComposer`: `-truecolor` o `trueColor: true` in `options.cfg`); senza, nulla
  cambia. Rispetto al progetto: lo zoom a indici (`DisplayPixels`) con il compositore si fa solo a richiesta; le
  bande nere hanno il colore 0 della palette come nel percorso a 8 bit. Numeri in `Libs\XcomEngine\CLAUDE.md`:
  percorso a 8 bit 7 PNG su 7 identici byte per byte; con l'opzione a scala 1 e 2 zero pixel diversi dopo la palette
  (tolto il globo fine a scala 2).
- **Fetta 3 (scala intera piu' alta): fatto il globo del Geoscape**, come al §3 (secondo globo + strato di
  dettaglio; `Libs\XcomGeoscape\CLAUDE.md`). La scala e' quella che il gioco ha gia' (misura della finestra diviso
  misura dell'immagine: 640x400, 960x600, 1280x800 su 320x200), non un'opzione nuova. **Non fatto**: le linee dei
  grafici (`GraphsState`: stesso meccanismo, uno strato per il riquadro del grafico), il radar del dogfight, la
  minimappa. **Cornici e pulsanti: deciso di non farli.** Sono rettangoli allineati agli assi: l'ingrandimento col
  pixel piu' vicino li rende gia' esatti, e ridisegnarli "alla risoluzione vera" li farebbe solo piu' sottili (un
  bordo di 5 pixel veri invece di 5 pixel del gioco), cambiando le proporzioni dell'interfaccia senza guadagno.
  Il testo e' della #184 (aggancio: `TXcomGlobe.BlitLabel` e, per i widget, `IXcomDetailLayers`).
- **Fetta 4 (trasparenze ed effetti veri): non iniziata**, per scelta (la 3 non e' completa). Che cosa serve, in
  ordine: (1) estendere lo strato di dettaglio a **BGRA con alpha** (`EndLayer` con pixel a colori; il compositore
  fa `dst = dst*(1-a) + src*a` al posto della copia) - serve anche alla #184; (2) dare a `TXcomBattleMap` un
  secondo bersaglio per fumo, fuoco e particelle: oggi `DrawParticles` scrive sulla mappa l'indice della tabella
  di `TXcomTransparencyTable` e il fumo e' un fotogramma pieno di `SMOKE.PCK`; nel percorso nuovo li registrerebbe
  (posizione, tinta, opacita' 1..4 o densita') in uno strato alla scala 1 che il compositore mescola in RGB, lasciando
  invariato cio' che scrive sulla superficie a 8 bit; l'ordine per tegola resta giusto solo se lo strato ricorda
  **dopo quale sprite** e' stato disegnato (stesso criterio "il pixel e' ancora quello che ho lasciato"); (3) la luce:
  `TXcomSurfaceShader.Blit` con ombra `n` sposta l'indice di `n` nella rampa; per una luce continua serve, per ogni
  blocco di 16 colori della palette, la curva di luminosita' della rampa (non e' lineare ne' uguale tra blocchi) e
  uno strato che porti "indice base + ombra frazionaria": si interpola tra i due colori vicini della **stessa
  rampa**, cosi' ai valori interi il risultato coincide col gioco. Il rischio e' quello detto al §2 (punti 2 e 3):
  vanno fatti uno alla volta con un confronto visivo, non c'e' un riferimento con cui fare parita'.
- **Prestazioni** (millisecondi per fotogramma, `-script`): opzione spenta invariata (menu 0,9, geoscape 1,7,
  battaglia 25); accesa a 2x menu 1,4, battaglia 25,6, geoscape 5,4; geoscape a 3x 9,2 e a 4x 15,2 (il globo fine
  si ridisegna per intero a ogni passo del tempo: e' il primo punto da ottimizzare, ridisegnando l'ombra solo
  quando il sole si e' mosso di un livello).
