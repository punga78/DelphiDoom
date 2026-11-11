{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the tile refresh manager             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Refresh;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf,
  DelphiDoom.Tests.Keen.VideoFakes;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenRefresh = class(TObject)
  strict private
    FMemory: IKeenEgaMemory;
    FGraphics: IKeenGraphics;
    FSprites: IKeenSpriteCache;
    FVideo: IKeenVideo;
    FClock: TFakeKeenClock;
    FClockIntf: IKeenClock;
    FTileInfo: IKeenTileInfo;
    FMap: IKeenWorkingMap;
    FRefresh: IKeenRefresh;
    FRandom: Cardinal;
    function NextRandom(ALimit: Integer): Integer;
    procedure Build(AWidth, AHeight: Integer; ACompatibility: Boolean = False);
    procedure BuildWithTable(AWidth, AHeight: Integer; const ATable: TBytes; ACompatibility: Boolean = False; AMark: Boolean = True);
    function StandardTable: TBytes;
    procedure FillMap(AWidth, AHeight: Integer);
    function Oracle: TKeenChunkyImage;
    procedure ExpectScreen(const AExpected: TKeenChunkyImage; const AWhat: string);
    procedure OverlaySprite(var AImage: TKeenChunkyImage; ASprite, AGlobalX, AGlobalY: Integer);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDisegnareNeroUnTileSenzaDati;
    [Test]
    procedure DovrebbeSaltareUnTileDiPrimoPianoSenzaDati;
    [Test]
    procedure DovrebbeCalcolareILimitiDellOrigine;
    [Test]
    procedure DovrebbeLimitareUnaMappaPiccola;
    [Test]
    procedure DovrebbeDisegnareLaMappaConNewPosition;
    [Test]
    procedure DovrebbeLimitareLaPosizioneAllaMappa;
    [Test]
    procedure DovrebbeRifareLoSchermoConForceRefresh;
    [Test]
    procedure DovrebbeSegnareUnoInTuttiITileDopoNewPosition;
    [Test]
    procedure DovrebbeAzzerareLArrayDiAggiornamentoDopoUnRefresh;
    [Test]
    procedure DovrebbeScorrereUnPixelAlColpoInOgniDirezione;
    [Test]
    procedure DovrebbeScorrereConMovimentiCasualiEAnimazioni;
    [Test]
    procedure DovrebbeRidisegnareTuttoSeSiScorrePiuDiUnTile;
    [Test]
    procedure DovrebbeFareIlGiroDellaMemoriaVideoScorrendoInAlto;
    [Test]
    procedure DovrebbeScorrereInModoCompatibile;
    [Test]
    procedure DovrebbeAnimareITile;
    [Test]
    procedure DovrebbeAnimareIlTileMascherato;
    [Test]
    procedure DovrebbeRifiutareUnaAnimazioneCheNonFinisce;
    [Test]
    procedure DovrebbeRifiutareTroppeAnimazioniDiverse;
    [Test]
    procedure DovrebbeMettereUnoSpriteSullaMappa;
    [Test]
    procedure DovrebbeSpostareUnoSpriteSenzaLasciareTracce;
    [Test]
    procedure DovrebbeTogliereUnoSprite;
    [Test]
    procedure DovrebbeDisegnareLeCopieScorrevoliDegliSprite;
    [Test]
    procedure DovrebbeDisegnareUnoSpriteTagliatoInAlto;
    [Test]
    procedure DovrebbeDisegnareUnoSpriteTagliatoInBasso;
    [Test]
    procedure DovrebbeNonDisegnareUnoSpriteFuoriDallaVista;
    [Test]
    procedure DovrebbeRimettereIlTileMascheratoSopraLoSprite;
    [Test]
    procedure DovrebbeLasciareLoSpriteSopraAPrioritaAlta;
    [Test]
    procedure DovrebbeDisegnareGliSpriteInOrdineDiPriorita;
    [Test]
    procedure DovrebbeSpostareUnoSpriteDaUnaPrioritaAUnAltra;
    [Test]
    procedure DovrebbeTogliereUnoSpriteInMezzoALista;
    [Test]
    procedure DovrebbeRiusareIBlocchiLiberati;
    [Test]
    procedure DovrebbeRifiutareUnaPrioritaNonValida;
    [Test]
    procedure DovrebbeRifiutareMenoSpriteDiCentouno;
    [Test]
    procedure DovrebbeTogliereUnoSpriteSenzaHandleSenzaErrori;
    [Test]
    procedure DovrebbeTogliereUnoSpriteConIlNumeroZero;
    [Test]
    procedure DovrebbeNonDisegnareUnoSpriteMaskdraw;
    [Test]
    procedure DovrebbeChiamareIlHookPrimaDiMostrarePagina;
    [Test]
    procedure DovrebbeAlternareLePagine;
    [Test]
    procedure DovrebbeMostrareLaPaginaDisegnata;
    [Test]
    procedure DovrebbeAspettareIDueTicMinimi;
    [Test]
    procedure DovrebbeLimitareITicAlMassimo;
    [Test]
    procedure DovrebbeRipartireDaTicUnoConUnaMappaNuova;
    [Test]
    procedure DovrebbeRifiutareUnaMappaMancante;
    [Test]
    procedure DovrebbeRifiutareIParametriNulli;
  end;

implementation

uses
  DelphiDoom.Keen.EgaMemory, DelphiDoom.Keen.Video, DelphiDoom.Keen.SpriteCache, DelphiDoom.Keen.TileInfo,
  DelphiDoom.Keen.WorkingMap, DelphiDoom.Keen.Refresh, DelphiDoom.Keen.Map, DelphiDoom.Keen.MapRenderer,
  DelphiDoom.Keen.DisplayCapture, DelphiDoom.Keen.PlanarConverter, DelphiDoom.Keen.Arithmetic;

const
  // the tile of the fake map that goes over a sprite (INTILE high bit)
  FRONT_TILE = 25;

{ TTestKeenRefresh }

procedure TTestKeenRefresh.Setup;
begin
  FRandom := 20260509;
  Build(40, 30);
end;

function TTestKeenRefresh.NextRandom(ALimit: Integer): Integer;
begin
  FRandom := FRandom * 1664525 + 1013904223;
  Result := Integer((FRandom shr 8) mod Cardinal(ALimit));
end;

function TTestKeenRefresh.StandardTable: TBytes;
var
  LIndex: Integer;
begin
  Result := TFakeKeenTiles.EmptyTable;
  // the background tiles 10, 11 and 12 animate in a loop of 3 tiles, 3 tics each
  Result[KEEN_TINF_ANIM + 10] := 1;
  Result[KEEN_TINF_ANIM + 11] := 1;
  Result[KEEN_TINF_ANIM + 12] := Byte(-2);
  for LIndex := 10 to 12 do
    Result[KEEN_TINF_SPEED + LIndex] := 3;
  // the foreground tiles 5 and 6 animate between them, 4 tics
  Result[KEEN_TINF_MANIM + 5] := 1;
  Result[KEEN_TINF_MANIM + 6] := Byte(-1);
  Result[KEEN_TINF_MSPEED + 5] := 4;
  Result[KEEN_TINF_MSPEED + 6] := 4;
  // the foreground tiles 20 to 31 are drawn over the sprites
  for LIndex := 20 to 31 do
    Result[KEEN_TINF_INTILE + LIndex] := $80;
end;

procedure TTestKeenRefresh.FillMap(AWidth, AHeight: Integer);
var
  LBackground: TArray<Word>;
  LForeground: TArray<Word>;
  LIndex: Integer;
begin
  LBackground := FMap.Planes[0];
  LForeground := FMap.Planes[1];
  for LIndex := 0 to AWidth * AHeight - 1 do
  begin
    LBackground[LIndex] := Word(NextRandom(FAKE_TILES));
    if NextRandom(100) < 18 then
      // the tiles under 20 stay under the sprites: the ones that go over them are placed by the tests
      LForeground[LIndex] := Word(1 + NextRandom(19))
    else
      LForeground[LIndex] := 0;
  end;
end;

procedure TTestKeenRefresh.BuildWithTable(AWidth, AHeight: Integer; const ATable: TBytes;
  ACompatibility, AMark: Boolean);
begin
  FMemory := TKeenEgaMemory.Create;
  FGraphics := TFakeKeenGraphics.Create(11);
  FSprites := TKeenSpriteCache.Create(FGraphics);
  FVideo := TKeenVideo.Create(FMemory, FGraphics, FSprites);
  FClock := TFakeKeenClock.Create(1);
  FClockIntf := FClock;
  FTileInfo := TKeenTileInfo.Create(ATable);
  FMap := TKeenWorkingMap.Create(AWidth, AHeight);
  FillMap(AWidth, AHeight);
  FRefresh := TKeenRefresh.Create(FVideo, FGraphics, FTileInfo, FSprites, FClockIntf, ACompatibility);
  FRefresh.NewMap(FMap);
  if AMark then
    FRefresh.MarkTileGraphics;
end;

procedure TTestKeenRefresh.Build(AWidth, AHeight: Integer; ACompatibility: Boolean);
begin
  BuildWithTable(AWidth, AHeight, StandardTable, ACompatibility);
end;

function TTestKeenRefresh.Oracle: TKeenChunkyImage;
var
  LHeader: TKeenMapHeader;
  LFile: IKeenMap;
  LFull: TKeenChunkyImage;
  LStartX: Integer;
  LStartY: Integer;
  LX: Integer;
  LY: Integer;
begin
  // the whole map as the tiles make it, and the part of it that the screen shows
  FillChar(LHeader, SizeOf(LHeader), 0);
  LHeader.Width := FMap.Width;
  LHeader.Height := FMap.Height;
  LFile := TKeenMap.Create(0, LHeader, [Copy(FMap.Planes[0]), Copy(FMap.Planes[1]), Copy(FMap.Planes[2])]);
  LFull := TKeenMapRenderer.Create.Render(LFile, FGraphics);
  // the screen starts at the tile of the origin plus the pixels of the panning (the odd pixel is dropped)
  LStartX := FRefresh.OriginXTile * 16 + (FVideo.PanX and 14);
  LStartY := FRefresh.OriginYTile * 16 + FVideo.PanY;
  Result.Width := KEEN_DISPLAY_WIDTH;
  Result.Height := KEEN_DISPLAY_HEIGHT;
  SetLength(Result.Pixels, Result.Width * Result.Height);
  for LY := 0 to Result.Height - 1 do
    for LX := 0 to Result.Width - 1 do
      Result.Pixels[LY * Result.Width + LX] := LFull.Pixels[(LStartY + LY) * LFull.Width + LStartX + LX];
end;

procedure TTestKeenRefresh.ExpectScreen(const AExpected: TKeenChunkyImage; const AWhat: string);
var
  LActual: TKeenChunkyImage;
  LIndex: Integer;
  LFirst: Integer;
  LLast: Integer;
  LCount: Integer;
  LTileX: Integer;
  LTileY: Integer;
begin
  LActual := TKeenDisplayCapture.CaptureVideo(FVideo);
  LCount := 0;
  LLast := -1;
  LFirst := -1;
  for LIndex := 0 to High(LActual.Pixels) do
    if LActual.Pixels[LIndex] <> AExpected.Pixels[LIndex] then
    begin
      Inc(LCount);
      LLast := LIndex;
      if LFirst < 0 then
        LFirst := LIndex;
    end;
  if LCount <> 0 then
  begin
    LTileX := FRefresh.OriginXTile + ((LFirst mod KEEN_DISPLAY_WIDTH) + (FVideo.PanX and 14)) div 16;
    LTileY := FRefresh.OriginYTile + ((LFirst div KEEN_DISPLAY_WIDTH) + FVideo.PanY) div 16;
    Assert.Fail(Format('%s: %d pixels differ, the first at (%d, %d), the last at (%d, %d); tile (%d, %d) back %d front %d',
      [AWhat, LCount, LFirst mod KEEN_DISPLAY_WIDTH, LFirst div KEEN_DISPLAY_WIDTH,
       LLast mod KEEN_DISPLAY_WIDTH, LLast div KEEN_DISPLAY_WIDTH, LTileX, LTileY,
       FMap.Planes[0][LTileY * FMap.Width + LTileX], FMap.Planes[1][LTileY * FMap.Width + LTileX]]));
  end;
end;

procedure TTestKeenRefresh.OverlaySprite(var AImage: TKeenChunkyImage; ASprite, AGlobalX, AGlobalY: Integer);
var
  LEntry: TKeenSpriteEntry;
  LPlanar: TBytes;
  LColors: TKeenChunkyImage;
  LMask: TBytes;
  LPixelX: Integer;
  LPixelY: Integer;
  LX: Integer;
  LY: Integer;
  LScreenX: Integer;
  LScreenY: Integer;
  LIndex: Integer;
  LShifts: Integer;
begin
  // the sprite at the pixel of its global position, to a multiple of 2 pixels (the copies are 0, 2, 4, 6)
  LEntry := FSprites.GetEntry(ASprite);
  LPlanar := FGraphics.SpritePlanar(ASprite - KEEN_STARTSPRITES);
  LColors := TKeenPlanarConverter.ToChunkyMasked(LPlanar, 0, LEntry.Width, LEntry.Height, LMask);
  LPixelX := (AGlobalX + LEntry.OriginX) and $FFFF;
  LPixelX := LPixelX shr 4;
  LShifts := LEntry.Shifts;
  case LShifts of
    4: LPixelX := LPixelX and not 1;
    2: LPixelX := (LPixelX and not 7) or (((LPixelX and 7) div 4) * 4);
    1: LPixelX := LPixelX and not 7;
  end;
  LPixelY := ((AGlobalY + LEntry.OriginY) and $FFFF) shr 4;
  for LY := 0 to LEntry.Height - 1 do
    for LX := 0 to LEntry.Width * 8 - 1 do
    begin
      LScreenX := LPixelX - FRefresh.OriginXTile * 16 - (FVideo.PanX and 14) + LX;
      LScreenY := LPixelY - FRefresh.OriginYTile * 16 - FVideo.PanY + LY;
      if (LScreenX < 0) or (LScreenX >= KEEN_DISPLAY_WIDTH) or (LScreenY < 0) or (LScreenY >= KEEN_DISPLAY_HEIGHT) then
        Continue;
      LIndex := LScreenY * KEEN_DISPLAY_WIDTH + LScreenX;
      AImage.Pixels[LIndex] := Byte((AImage.Pixels[LIndex] and LMask[LY * LEntry.Width * 8 + LX]) or
        LColors.Pixels[LY * LEntry.Width * 8 + LX]);
    end;
end;

procedure TTestKeenRefresh.DovrebbeDisegnareNeroUnTileSenzaDati;
begin
  // the tiles from FAKE_TILES on are sparse: no data in the file. Two of them in the view, one of them twice
  FMap.Planes[0][8 * 40 + 8] := 70;
  FMap.Planes[0][9 * 40 + 9] := 70;
  FMap.Planes[0][8 * 40 + 12] := 99;
  FRefresh.NewPosition(2 * 256, 2 * 256);
  FRefresh.Refresh;
  ExpectScreen(Oracle, 'sparse tiles');
end;

procedure TTestKeenRefresh.DovrebbeSaltareUnTileDiPrimoPianoSenzaDati;
begin
  // a foreground tile with no data is not drawn: the background shows
  FMap.Planes[1][8 * 40 + 8] := FAKE_MASKED_TILES + 5;
  FRefresh.NewPosition(2 * 256, 2 * 256);
  FRefresh.Refresh;
  ExpectScreen(Oracle, 'sparse foreground tile');
end;

procedure TTestKeenRefresh.DovrebbeCalcolareILimitiDellOrigine;
begin
  Assert.AreEqual(512, FRefresh.OriginXMin);
  Assert.AreEqual(512, FRefresh.OriginYMin);
  // (width - border - screen tiles) * 256
  Assert.AreEqual((40 - 2 - 20) * 256, FRefresh.OriginXMax);
  Assert.AreEqual((30 - 2 - 13) * 256, FRefresh.OriginYMax);
  Assert.AreEqual(40, FRefresh.MapWidth);
  Assert.AreEqual(30, FRefresh.MapHeight);
end;

procedure TTestKeenRefresh.DovrebbeLimitareUnaMappaPiccola;
begin
  Build(21, 16);
  // a map that does not scroll: the maximum is not under the minimum
  Assert.AreEqual(FRefresh.OriginXMin, FRefresh.OriginXMax);
  Assert.AreEqual(FRefresh.OriginYMin, FRefresh.OriginYMax);
end;

procedure TTestKeenRefresh.DovrebbeDisegnareLaMappaConNewPosition;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  ExpectScreen(Oracle, 'NewPosition');
  Assert.AreEqual(1000 shr 8, FRefresh.OriginXTile);
  Assert.AreEqual(900 shr 8, FRefresh.OriginYTile);
  Assert.AreEqual(FRefresh.OriginXTile * 2, FRefresh.OriginXScreen);
  Assert.AreEqual(FRefresh.OriginYTile * 16, FRefresh.OriginYScreen);
end;

procedure TTestKeenRefresh.DovrebbeLimitareLaPosizioneAllaMappa;
begin
  FRefresh.NewPosition(0, 0);
  Assert.AreEqual(512, FRefresh.OriginXGlobal);
  Assert.AreEqual(512, FRefresh.OriginYGlobal);
  FRefresh.NewPosition(60000, 60000);
  Assert.AreEqual(FRefresh.OriginXMax, FRefresh.OriginXGlobal);
  Assert.AreEqual(FRefresh.OriginYMax, FRefresh.OriginYGlobal);
end;

procedure TTestKeenRefresh.DovrebbeRifareLoSchermoConForceRefresh;
begin
  FRefresh.NewPosition(2000, 1500);
  FRefresh.Refresh;
  FMemory.Fill(3);
  FRefresh.ForceRefresh;
  ExpectScreen(Oracle, 'ForceRefresh');
end;

procedure TTestKeenRefresh.DovrebbeSegnareUnoInTuttiITileDopoNewPosition;
var
  LUpdate: TBytes;
  LRow: Integer;
  LColumn: Integer;
begin
  FRefresh.NewPosition(1000, 900);
  LUpdate := FRefresh.UpdateSnapshot(FRefresh.OtherPage);
  for LRow := 0 to KEEN_PORTTILESHIGH - 1 do
  begin
    for LColumn := 0 to KEEN_PORTTILESWIDE - 1 do
      Assert.AreEqual(1, Integer(LUpdate[LRow * KEEN_UPDATEWIDE + LColumn]));
    // the 0 at the end of each row
    Assert.AreEqual(0, Integer(LUpdate[LRow * KEEN_UPDATEWIDE + KEEN_PORTTILESWIDE]));
  end;
  // the terminator: a 1 and a 3
  Assert.AreEqual(1, Integer(LUpdate[KEEN_UPDATEWIDE * KEEN_PORTTILESHIGH]));
  Assert.AreEqual(3, Integer(LUpdate[KEEN_UPDATEWIDE * KEEN_PORTTILESHIGH + 1]));
end;

procedure TTestKeenRefresh.DovrebbeAzzerareLArrayDiAggiornamentoDopoUnRefresh;
var
  LUpdate: TBytes;
  LIndex: Integer;
  LPage: Integer;
begin
  FRefresh.NewPosition(1000, 900);
  LPage := FRefresh.OtherPage;
  FRefresh.Refresh;
  LUpdate := FRefresh.UpdateSnapshot(LPage);
  for LIndex := 0 to KEEN_UPDATEWIDE * KEEN_PORTTILESHIGH - 1 do
    Assert.AreEqual(0, Integer(LUpdate[LIndex]), 'byte ' + IntToStr(LIndex));
  Assert.AreEqual(1, Integer(LUpdate[KEEN_UPDATEWIDE * KEEN_PORTTILESHIGH]));
  Assert.AreEqual(3, Integer(LUpdate[KEEN_UPDATEWIDE * KEEN_PORTTILESHIGH + 1]));
end;

procedure TTestKeenRefresh.DovrebbeScorrereUnPixelAlColpoInOgniDirezione;
var
  LStep: Integer;
  LDirection: Integer;
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  FRefresh.NewPosition(1500, 1500);
  FRefresh.Refresh;
  for LDirection := 0 to 3 do
  begin
    case LDirection of
      0: begin LDeltaX := 16; LDeltaY := 0; end;
      1: begin LDeltaX := 0; LDeltaY := 16; end;
      2: begin LDeltaX := -16; LDeltaY := 0; end;
    else
      begin LDeltaX := 0; LDeltaY := -16; end;
    end;
    for LStep := 1 to 80 do
    begin
      FRefresh.Scroll(LDeltaX, LDeltaY);
      FRefresh.Refresh;
      ExpectScreen(Oracle, Format('direction %d step %d', [LDirection, LStep]));
    end;
  end;
end;

procedure TTestKeenRefresh.DovrebbeScorrereConMovimentiCasualiEAnimazioni;
var
  LStep: Integer;
begin
  FRefresh.NewPosition(2000, 1800);
  FRefresh.Refresh;
  for LStep := 1 to 400 do
  begin
    // never more than a tile at a time: 0..31 global units are 0..2 pixels, with a sign
    FRefresh.Scroll(NextRandom(97) - 48, NextRandom(97) - 48);
    FRefresh.Refresh;
    ExpectScreen(Oracle, 'random step ' + IntToStr(LStep));
  end;
end;

procedure TTestKeenRefresh.DovrebbeRidisegnareTuttoSeSiScorrePiuDiUnTile;
begin
  FRefresh.NewPosition(1000, 1000);
  FRefresh.Refresh;
  FRefresh.Scroll(256 * 5, 256 * 3);
  FRefresh.Refresh;
  ExpectScreen(Oracle, 'jump');
  FRefresh.Scroll(-256 * 4 - 20, 0);
  FRefresh.Refresh;
  ExpectScreen(Oracle, 'jump back');
end;

procedure TTestKeenRefresh.DovrebbeFareIlGiroDellaMemoriaVideoScorrendoInAlto;
var
  LStep: Integer;
begin
  // 1024 bytes of video memory for each tile: after 64 tiles the screens go round the end of the 64 KB
  Build(22, 120);
  FRefresh.NewPosition(600, 600);
  FRefresh.Refresh;
  for LStep := 1 to 107 * 16 do
  begin
    FRefresh.Scroll(0, 16);
    FRefresh.Refresh;
    if LStep mod 7 = 0 then
      ExpectScreen(Oracle, 'step ' + IntToStr(LStep));
  end;
  ExpectScreen(Oracle, 'the end');
  // the master screen has gone round the plane (it started at 30720)
  Assert.IsTrue(FRefresh.MasterOfs < 30720);
end;

procedure TTestKeenRefresh.DovrebbeScorrereInModoCompatibile;
var
  LStep: Integer;
begin
  Build(22, 120, True);
  FRefresh.NewPosition(600, 600);
  FRefresh.Refresh;
  for LStep := 1 to 107 * 16 do
  begin
    FRefresh.Scroll(0, 16);
    FRefresh.Refresh;
    if LStep mod 11 = 0 then
      ExpectScreen(Oracle, 'step ' + IntToStr(LStep));
    // the screens never pass the end of the memory
    Assert.IsTrue(FRefresh.MasterOfs <= $10000 - KEEN_SCREENWIDTH * 240);
  end;
  ExpectScreen(Oracle, 'the end');
end;

procedure TTestKeenRefresh.DovrebbeAnimareITile;
var
  LBackground: TArray<Word>;
  LIndex: Integer;
  LAnimated: Integer;
  LBefore: Word;
  LChanges: Integer;
  LRefresh: Integer;
begin
  LBackground := FMap.Planes[0];
  // a tile 10 in the view
  FRefresh.NewPosition(1000, 900);
  LAnimated := -1;
  // a tile 10 that is in the view (the tiles 3..22 of the columns and 3..15 of the rows)
  for LIndex := 0 to High(LBackground) do
    if (LBackground[LIndex] = 10) and (LIndex mod 40 in [4..21]) and (LIndex div 40 in [4..14]) then
    begin
      LAnimated := LIndex;
      Break;
    end;
  Assert.IsTrue(LAnimated >= 0, 'the fake map has a tile 10');
  FRefresh.Refresh;
  LBefore := LBackground[LAnimated];
  // the clock moves 2 tics at every refresh and the speed is 3: the tile goes 10, 11, 12, 10... and the
  // screen always shows the map as it is
  LChanges := 0;
  for LRefresh := 1 to 12 do
  begin
    FRefresh.Refresh;
    if LBackground[LAnimated] <> LBefore then
    begin
      Inc(LChanges);
      LBefore := LBackground[LAnimated];
    end;
    Assert.IsTrue(LBackground[LAnimated] in [10, 11, 12]);
    ExpectScreen(Oracle, 'animation ' + IntToStr(LRefresh));
  end;
  Assert.IsTrue(LChanges >= 6, 'the tile changed ' + IntToStr(LChanges) + ' times');
end;

procedure TTestKeenRefresh.DovrebbeAnimareIlTileMascherato;
var
  LForeground: TArray<Word>;
  LIndex: Integer;
  LSeen: array[0..1] of Boolean;
  LRefresh: Integer;
begin
  LForeground := FMap.Planes[1];
  // put a tile 5 in the middle of the view
  FRefresh := TKeenRefresh.Create(FVideo, FGraphics, FTileInfo, FSprites, FClockIntf);
  FRefresh.NewMap(FMap);
  LForeground[8 * 40 + 12] := 5;
  FRefresh.MarkTileGraphics;
  FRefresh.NewPosition(512, 512);
  FRefresh.Refresh;
  LSeen[0] := False;
  LSeen[1] := False;
  for LRefresh := 1 to 20 do
  begin
    FRefresh.Refresh;
    if LForeground[8 * 40 + 12] = 5 then
      LSeen[0] := True
    else if LForeground[8 * 40 + 12] = 6 then
      LSeen[1] := True;
    ExpectScreen(Oracle, 'masked animation ' + IntToStr(LRefresh));
  end;
  Assert.IsTrue(LSeen[0] and LSeen[1], 'the tile goes 5, 6, 5, ...');
  LIndex := LForeground[8 * 40 + 12];
  Assert.IsTrue((LIndex = 5) or (LIndex = 6));
end;

procedure TTestKeenRefresh.DovrebbeRifiutareUnaAnimazioneCheNonFinisce;
var
  LTable: TBytes;
  LIndex: Integer;
begin
  LTable := TFakeKeenTiles.EmptyTable;
  // a chain that goes forward 40 tiles and never comes back
  for LIndex := 30 to 59 do
  begin
    LTable[KEEN_TINF_ANIM + LIndex] := 1;
    LTable[KEEN_TINF_SPEED + LIndex] := 2;
  end;
  BuildWithTable(10, 10, LTable, False, False);
  FMap.Planes[0][5] := 30;
  Assert.WillRaise(
    procedure
    begin
      FRefresh.MarkTileGraphics;
    end, EKeenException);
end;

procedure TTestKeenRefresh.DovrebbeRifiutareTroppeAnimazioniDiverse;
var
  LTable: TBytes;
  LIndex: Integer;
begin
  LTable := TFakeKeenTiles.EmptyTable;
  // pairs of tiles that go back and forth: each distinct tile of the map is a chain of its own
  for LIndex := 1 to 60 do
  begin
    if Odd(LIndex) then
      LTable[KEEN_TINF_ANIM + LIndex] := 1
    else
      LTable[KEEN_TINF_ANIM + LIndex] := Byte(-1);
    LTable[KEEN_TINF_SPEED + LIndex] := 2;
  end;
  BuildWithTable(20, 20, LTable, False, False);
  for LIndex := 0 to 59 do
    FMap.Planes[0][LIndex] := Word(LIndex + 1);
  Assert.WillRaise(
    procedure
    begin
      FRefresh.MarkTileGraphics;
    end, EKeenException);
end;

procedure TTestKeenRefresh.DovrebbeMettereUnoSpriteSullaMappa;
var
  LHandle: TKeenSpriteHandle;
  LExpected: TKeenChunkyImage;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  LHandle := 0;
  FRefresh.PlaceSprite(LHandle, 1000 + 40 * 16, 900 + 30 * 16, KEEN_STARTSPRITES, kdtSpriteDraw, 1);
  Assert.IsTrue(LHandle > 0);
  FRefresh.Refresh;
  LExpected := Oracle;
  OverlaySprite(LExpected, KEEN_STARTSPRITES, 1000 + 40 * 16, 900 + 30 * 16);
  ExpectScreen(LExpected, 'sprite on the first page');
  // the animations of the tiles go on: the expected picture is made again every time
  FRefresh.Refresh;
  LExpected := Oracle;
  OverlaySprite(LExpected, KEEN_STARTSPRITES, 1000 + 40 * 16, 900 + 30 * 16);
  ExpectScreen(LExpected, 'sprite on the second page');
  FRefresh.Refresh;
  LExpected := Oracle;
  OverlaySprite(LExpected, KEEN_STARTSPRITES, 1000 + 40 * 16, 900 + 30 * 16);
  ExpectScreen(LExpected, 'sprite on the first page again');
end;

procedure TTestKeenRefresh.DovrebbeSpostareUnoSpriteSenzaLasciareTracce;
var
  LHandle: TKeenSpriteHandle;
  LExpected: TKeenChunkyImage;
  LStep: Integer;
  LX: Integer;
  LY: Integer;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  LHandle := 0;
  LX := 1000 + 100 * 16;
  LY := 900 + 40 * 16;
  for LStep := 1 to 60 do
  begin
    Inc(LX, NextRandom(161) - 60);
    Inc(LY, NextRandom(121) - 50);
    FRefresh.PlaceSprite(LHandle, LX, LY, KEEN_STARTSPRITES, kdtSpriteDraw, 1);
    FRefresh.Refresh;
    LExpected := Oracle;
    OverlaySprite(LExpected, KEEN_STARTSPRITES, LX, LY);
    ExpectScreen(LExpected, 'sprite step ' + IntToStr(LStep));
  end;
end;

procedure TTestKeenRefresh.DovrebbeTogliereUnoSprite;
var
  LHandle: TKeenSpriteHandle;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  LHandle := 0;
  FRefresh.PlaceSprite(LHandle, 1800, 1500, KEEN_STARTSPRITES, kdtSpriteDraw, 2);
  FRefresh.Refresh;
  FRefresh.Refresh;
  FRefresh.RemoveSprite(LHandle);
  Assert.AreEqual(0, LHandle);
  FRefresh.Refresh;
  ExpectScreen(Oracle, 'after removing');
  FRefresh.Refresh;
  ExpectScreen(Oracle, 'after removing, second page');
end;

procedure TTestKeenRefresh.DovrebbeDisegnareLeCopieScorrevoliDegliSprite;
var
  LHandle: TKeenSpriteHandle;
  LExpected: TKeenChunkyImage;
  LShift: Integer;
  LSprite: Integer;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  for LSprite := 0 to 3 do
  begin
    LHandle := 0;
    for LShift := 0 to 15 do
    begin
      // 1/16 of a pixel for each unit: 16 of them are a pixel, the shift goes with the pixel
      FRefresh.PlaceSprite(LHandle, 1600 + LShift * 16 + 5, 1400 + LShift * 3, KEEN_STARTSPRITES + LSprite,
        kdtSpriteDraw, 1);
      FRefresh.Refresh;
      LExpected := Oracle;
      OverlaySprite(LExpected, KEEN_STARTSPRITES + LSprite, 1600 + LShift * 16 + 5, 1400 + LShift * 3);
      ExpectScreen(LExpected, Format('sprite %d shift %d', [LSprite, LShift]));
    end;
    FRefresh.RemoveSprite(LHandle);
    FRefresh.Refresh;
    FRefresh.Refresh;
  end;
end;

procedure TTestKeenRefresh.DovrebbeDisegnareUnoSpriteTagliatoInAlto;
var
  LHandle: TKeenSpriteHandle;
  LExpected: TKeenChunkyImage;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  LHandle := 0;
  // the sprite starts 7 pixels above the screen
  FRefresh.PlaceSprite(LHandle, 1000 + 160 * 16, 900 - 7 * 16 + (FVideo.PanY * 16), KEEN_STARTSPRITES,
    kdtSpriteDraw, 1);
  FRefresh.Refresh;
  LExpected := Oracle;
  OverlaySprite(LExpected, KEEN_STARTSPRITES, 1000 + 160 * 16, 900 - 7 * 16 + (FVideo.PanY * 16));
  ExpectScreen(LExpected, 'clipped on top');
end;

procedure TTestKeenRefresh.DovrebbeDisegnareUnoSpriteTagliatoInBasso;
var
  LHandle: TKeenSpriteHandle;
  LExpected: TKeenChunkyImage;
  LY: Integer;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  LHandle := 0;
  // the last 9 rows of the sprite are under the picture of the port (14 tiles of 16 rows): 224 rows
  LY := FRefresh.OriginYTile * 256 + (224 - 11) * 16;
  FRefresh.PlaceSprite(LHandle, 1000 + 100 * 16, LY, KEEN_STARTSPRITES, kdtSpriteDraw, 1);
  FRefresh.Refresh;
  LExpected := Oracle;
  OverlaySprite(LExpected, KEEN_STARTSPRITES, 1000 + 100 * 16, LY);
  ExpectScreen(LExpected, 'clipped on the bottom');
end;

procedure TTestKeenRefresh.DovrebbeNonDisegnareUnoSpriteFuoriDallaVista;
var
  LHandle: TKeenSpriteHandle;
  LExpected: TKeenChunkyImage;
  LStep: Integer;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  LHandle := 0;
  // the view starts at the pixel (48, 48) and has 320 x 200 of them: the sprite is just past the right side
  FRefresh.PlaceSprite(LHandle, 400 * 16, 100 * 16, KEEN_STARTSPRITES, kdtSpriteDraw, 1);
  FRefresh.Refresh;
  FRefresh.Refresh;
  ExpectScreen(Oracle, 'sprite out of the view');
  // and the sprite comes into the view when the map scrolls
  for LStep := 1 to 8 do
  begin
    FRefresh.Scroll(160, 0);
    FRefresh.Refresh;
    LExpected := Oracle;
    OverlaySprite(LExpected, KEEN_STARTSPRITES, 400 * 16, 100 * 16);
    ExpectScreen(LExpected, 'scrolled ' + IntToStr(LStep));
  end;
end;

procedure TTestKeenRefresh.DovrebbeRimettereIlTileMascheratoSopraLoSprite;
var
  LForeground: TArray<Word>;
  LHandle: TKeenSpriteHandle;
  LExpected: TKeenChunkyImage;
  LTileX: Integer;
  LTileY: Integer;
  LImage: TKeenChunkyImage;
  LMask: TBytes;
  LColors: TKeenChunkyImage;
  LX: Integer;
  LY: Integer;
  LScreenX: Integer;
  LScreenY: Integer;
begin
  // the tile 25 of the foreground is masked (INTILE): it goes over a sprite of a priority under 3
  LForeground := FMap.Planes[1];
  LTileX := 8;
  LTileY := 6;
  LForeground[LTileY * 40 + LTileX] := FRONT_TILE;
  FRefresh.NewPosition(2 * 256 + 128, 2 * 256);
  FRefresh.Refresh;
  LHandle := 0;
  // the sprite 2 is 16 x 8 pixels: at the corner of the tile (8, 6) it covers only that tile
  FRefresh.PlaceSprite(LHandle, LTileX * 256, LTileY * 256, KEEN_STARTSPRITES + 2, kdtSpriteDraw, 1);
  FRefresh.Refresh;
  LExpected := Oracle;
  OverlaySprite(LExpected, KEEN_STARTSPRITES + 2, LTileX * 256, LTileY * 256);
  // the tile goes over it again
  LColors := TKeenPlanarConverter.ToChunkyMasked(FGraphics.Tile16Masked(FRONT_TILE), 0, 2, 16, LMask);
  LImage := LExpected;
  for LY := 0 to 15 do
    for LX := 0 to 15 do
    begin
      LScreenX := LTileX * 16 - FRefresh.OriginXTile * 16 - (FVideo.PanX and 14) + LX;
      LScreenY := LTileY * 16 - FRefresh.OriginYTile * 16 - FVideo.PanY + LY;
      if (LScreenX >= 0) and (LScreenX < KEEN_DISPLAY_WIDTH) and (LScreenY >= 0) and (LScreenY < KEEN_DISPLAY_HEIGHT) then
        LImage.Pixels[LScreenY * KEEN_DISPLAY_WIDTH + LScreenX] :=
          Byte((LImage.Pixels[LScreenY * KEEN_DISPLAY_WIDTH + LScreenX] and LMask[LY * 16 + LX]) or LColors.Pixels[LY * 16 + LX]);
    end;
  ExpectScreen(LImage, 'the tile over the sprite');
end;

procedure TTestKeenRefresh.DovrebbeLasciareLoSpriteSopraAPrioritaAlta;
var
  LForeground: TArray<Word>;
  LHandle: TKeenSpriteHandle;
  LExpected: TKeenChunkyImage;
begin
  LForeground := FMap.Planes[1];
  LForeground[6 * 40 + 8] := FRONT_TILE;
  FRefresh.NewPosition(2 * 256 + 128, 2 * 256);
  FRefresh.Refresh;
  LHandle := 0;
  FRefresh.PlaceSprite(LHandle, 8 * 256, 6 * 256, KEEN_STARTSPRITES + 2, kdtSpriteDraw, 3);
  FRefresh.Refresh;
  LExpected := Oracle;
  OverlaySprite(LExpected, KEEN_STARTSPRITES + 2, 8 * 256, 6 * 256);
  ExpectScreen(LExpected, 'priority 3 over the masked tile');
end;

procedure TTestKeenRefresh.DovrebbeDisegnareGliSpriteInOrdineDiPriorita;
var
  LFirst: TKeenSpriteHandle;
  LSecond: TKeenSpriteHandle;
  LExpected: TKeenChunkyImage;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  LFirst := 0;
  LSecond := 0;
  // the one with the higher priority number is drawn last, whatever the order of the calls
  FRefresh.PlaceSprite(LSecond, 1700, 1500, KEEN_STARTSPRITES + 1, kdtSpriteDraw, 2);
  FRefresh.PlaceSprite(LFirst, 1710, 1505, KEEN_STARTSPRITES, kdtSpriteDraw, 0);
  FRefresh.Refresh;
  LExpected := Oracle;
  OverlaySprite(LExpected, KEEN_STARTSPRITES, 1710, 1505);
  OverlaySprite(LExpected, KEEN_STARTSPRITES + 1, 1700, 1500);
  ExpectScreen(LExpected, 'two sprites');
end;

procedure TTestKeenRefresh.DovrebbeSpostareUnoSpriteDaUnaPrioritaAUnAltra;
var
  LHandle: TKeenSpriteHandle;
  LOther: TKeenSpriteHandle;
  LExpected: TKeenChunkyImage;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  LHandle := 0;
  LOther := 0;
  FRefresh.PlaceSprite(LHandle, 1700, 1500, KEEN_STARTSPRITES + 1, kdtSpriteDraw, 0);
  FRefresh.PlaceSprite(LOther, 1710, 1505, KEEN_STARTSPRITES, kdtSpriteDraw, 1);
  FRefresh.Refresh;
  // the first goes to a higher priority: it is now over the second
  FRefresh.PlaceSprite(LHandle, 1700, 1500, KEEN_STARTSPRITES + 1, kdtSpriteDraw, 2);
  FRefresh.Refresh;
  LExpected := Oracle;
  OverlaySprite(LExpected, KEEN_STARTSPRITES, 1710, 1505);
  OverlaySprite(LExpected, KEEN_STARTSPRITES + 1, 1700, 1500);
  ExpectScreen(LExpected, 'priority changed');
  FRefresh.Refresh;
  LExpected := Oracle;
  OverlaySprite(LExpected, KEEN_STARTSPRITES, 1710, 1505);
  OverlaySprite(LExpected, KEEN_STARTSPRITES + 1, 1700, 1500);
  ExpectScreen(LExpected, 'priority changed, second page');
end;

procedure TTestKeenRefresh.DovrebbeTogliereUnoSpriteInMezzoALista;
var
  LHandles: array[0..4] of TKeenSpriteHandle;
  LIndex: Integer;
  LExpected: TKeenChunkyImage;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  for LIndex := 0 to 4 do
  begin
    LHandles[LIndex] := 0;
    FRefresh.PlaceSprite(LHandles[LIndex], 1600 + LIndex * 400, 1400 + LIndex * 150, KEEN_STARTSPRITES + 2,
      kdtSpriteDraw, 1);
  end;
  FRefresh.Refresh;
  FRefresh.RemoveSprite(LHandles[2]);
  FRefresh.RemoveSprite(LHandles[0]);
  FRefresh.RemoveSprite(LHandles[4]);
  FRefresh.Refresh;
  FRefresh.Refresh;
  LExpected := Oracle;
  OverlaySprite(LExpected, KEEN_STARTSPRITES + 2, 1600 + 1 * 400, 1400 + 1 * 150);
  OverlaySprite(LExpected, KEEN_STARTSPRITES + 2, 1600 + 3 * 400, 1400 + 3 * 150);
  ExpectScreen(LExpected, 'two sprites are left');
end;

procedure TTestKeenRefresh.DovrebbeRiusareIBlocchiLiberati;
var
  LHandles: array[0..99] of TKeenSpriteHandle;
  LIndex: Integer;
  LNew: TKeenSpriteHandle;
begin
  for LIndex := 0 to 99 do
  begin
    LHandles[LIndex] := 0;
    FRefresh.PlaceSprite(LHandles[LIndex], 1000, 1000, KEEN_STARTSPRITES + 2, kdtSpriteDraw, LIndex mod 4);
  end;
  FRefresh.RemoveSprite(LHandles[37]);
  LNew := 0;
  FRefresh.PlaceSprite(LNew, 1000, 1000, KEEN_STARTSPRITES + 2, kdtSpriteDraw, 0);
  Assert.IsTrue(LNew > 0);
end;

procedure TTestKeenRefresh.DovrebbeRifiutareUnaPrioritaNonValida;
var
  LHandle: TKeenSpriteHandle;
begin
  LHandle := 0;
  Assert.WillRaise(
    procedure
    begin
      FRefresh.PlaceSprite(LHandle, 0, 0, KEEN_STARTSPRITES, kdtSpriteDraw, 4);
    end, EKeenException);
end;

procedure TTestKeenRefresh.DovrebbeRifiutareMenoSpriteDiCentouno;
var
  LHandles: array[0..100] of TKeenSpriteHandle;
  LIndex: Integer;
begin
  for LIndex := 0 to 99 do
  begin
    LHandles[LIndex] := 0;
    FRefresh.PlaceSprite(LHandles[LIndex], 1000, 1000, KEEN_STARTSPRITES + 2, kdtSpriteDraw, 1);
  end;
  LHandles[100] := 0;
  Assert.WillRaise(
    procedure
    begin
      FRefresh.PlaceSprite(LHandles[100], 1000, 1000, KEEN_STARTSPRITES + 2, kdtSpriteDraw, 1);
    end, EKeenException);
end;

procedure TTestKeenRefresh.DovrebbeTogliereUnoSpriteSenzaHandleSenzaErrori;
var
  LHandle: TKeenSpriteHandle;
begin
  LHandle := 0;
  FRefresh.RemoveSprite(LHandle);
  Assert.AreEqual(0, LHandle);
end;

procedure TTestKeenRefresh.DovrebbeTogliereUnoSpriteConIlNumeroZero;
var
  LHandle: TKeenSpriteHandle;
begin
  // RF_PlaceSprite with the sprite 0 removes the sprite
  LHandle := 0;
  FRefresh.PlaceSprite(LHandle, 1000, 1000, KEEN_STARTSPRITES, kdtSpriteDraw, 1);
  Assert.IsTrue(LHandle > 0);
  FRefresh.PlaceSprite(LHandle, 1000, 1000, 0, kdtSpriteDraw, 1);
  Assert.AreEqual(0, LHandle);
end;

procedure TTestKeenRefresh.DovrebbeNonDisegnareUnoSpriteMaskdraw;
var
  LHandle: TKeenSpriteHandle;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  LHandle := 0;
  FRefresh.PlaceSprite(LHandle, 1700, 1500, KEEN_STARTSPRITES, kdtMaskDraw, 1);
  FRefresh.Refresh;
  FRefresh.Refresh;
  ExpectScreen(Oracle, 'maskdraw');
end;

procedure TTestKeenRefresh.DovrebbeChiamareIlHookPrimaDiMostrarePagina;
var
  LCalls: Integer;
  LCrtcInHook: Integer;
begin
  LCalls := 0;
  LCrtcInHook := -1;
  FRefresh.NewPosition(1000, 900);
  FRefresh.SetRefreshHook(
    procedure
    begin
      Inc(LCalls);
      LCrtcInHook := FVideo.CrtcStart;
    end);
  FRefresh.Refresh;
  Assert.AreEqual(1, LCalls);
  // the page is shown after the hook
  Assert.AreNotEqual(LCrtcInHook, FVideo.CrtcStart);
  FRefresh.SetRefreshHook(nil);
  FRefresh.Refresh;
  Assert.AreEqual(1, LCalls);
end;

procedure TTestKeenRefresh.DovrebbeAlternareLePagine;
var
  LOther: Integer;
  LScreen: Integer;
begin
  LOther := FRefresh.OtherPage;
  LScreen := FRefresh.ScreenPage;
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  Assert.AreEqual(LScreen, FRefresh.OtherPage);
  Assert.AreEqual(LOther, FRefresh.ScreenPage);
  Assert.AreEqual(FRefresh.ScreenPage * KEEN_SCREENWIDTH * 240, FVideo.DisplayOfs);
  Assert.AreEqual(FRefresh.OtherPage * KEEN_SCREENWIDTH * 240, FVideo.BufferOfs);
end;

procedure TTestKeenRefresh.DovrebbeMostrareLaPaginaDisegnata;
var
  LDrawn: Integer;
begin
  FRefresh.NewPosition(1000, 900);
  LDrawn := FVideo.BufferOfs;
  FRefresh.Refresh;
  Assert.AreEqual(LDrawn + FVideo.PanAdjust, FVideo.CrtcStart);
  Assert.AreEqual(FVideo.PanX and 6, FVideo.PelPan);
end;

procedure TTestKeenRefresh.DovrebbeAspettareIDueTicMinimi;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  Assert.AreEqual(2, FRefresh.Tics);
  Assert.AreEqual(2, FClock.IdleCalls);
end;

procedure TTestKeenRefresh.DovrebbeLimitareITicAlMassimo;
var
  LNow: Integer;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  LNow := FClock.GetTimeCount;
  // the game was stopped for 100 tics: the time goes back so that 6 tics are the ones that are used
  FClock.SetTimeCount(LNow + 100);
  FRefresh.Refresh;
  Assert.AreEqual(KEEN_MAXTICS, FRefresh.Tics);
  Assert.AreEqual(LNow + 100 - (100 - KEEN_MAXTICS), FClock.GetTimeCount);
end;

procedure TTestKeenRefresh.DovrebbeRipartireDaTicUnoConUnaMappaNuova;
begin
  FRefresh.NewPosition(1000, 900);
  FRefresh.Refresh;
  Assert.AreEqual(2, FRefresh.Tics);
  FRefresh.NewMap(FMap);
  Assert.AreEqual(1, FRefresh.Tics);
end;

procedure TTestKeenRefresh.DovrebbeRifiutareUnaMappaMancante;
var
  LRefresh: IKeenRefresh;
begin
  LRefresh := TKeenRefresh.Create(FVideo, FGraphics, FTileInfo, FSprites, FClockIntf);
  Assert.WillRaise(
    procedure
    begin
      LRefresh.NewPosition(0, 0);
    end, EKeenException);
  Assert.WillRaise(
    procedure
    begin
      LRefresh.MarkTileGraphics;
    end, EKeenException);
end;

procedure TTestKeenRefresh.DovrebbeRifiutareIParametriNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenRefresh.Create(nil, FGraphics, FTileInfo, FSprites, FClockIntf);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TKeenRefresh.Create(FVideo, nil, FTileInfo, FSprites, FClockIntf);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TKeenRefresh.Create(FVideo, FGraphics, nil, FSprites, FClockIntf);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TKeenRefresh.Create(FVideo, FGraphics, FTileInfo, FSprites, nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenRefresh);

end.
