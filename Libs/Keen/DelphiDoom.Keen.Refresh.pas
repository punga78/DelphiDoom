{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the tile refresh manager                          }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  id_rf.c (EGA part) and id_rf_a.asm                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Refresh;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   ID_RF for the EGA. The map is drawn on three screens that float in the video memory (the page that is
  ///   shown, the page that is drawn and the master screen with the whole view); scrolling a tile moves the
  ///   start of the three screens. Each of the two pages has an update array with a byte for every tile of the
  ///   view: 1 = copy the tile from the master screen, 2 = a sprite was erased here, 3 = a sprite is drawn
  ///   here (so a masked foreground tile goes over it). The 16 bit unsigned and int of the C are
  ///   kept where the wrap matters (the offsets in the video memory, the global coordinates). What the C keeps
  ///   as a pointer into allanims[] in the info plane of the map is here a separate array: the info plane keeps
  ///   what the actors need
  /// </summary>
  TKeenRefresh = class(TInterfacedObject, IKeenRefresh)
  strict private
    const
      SCREENSPACE = KEEN_SCREENWIDTH * 240;
      FREEEGAMEM = $10000 - 3 * SCREENSPACE;
      UPDATESCREENSIZE = KEEN_UPDATEWIDE * KEEN_PORTTILESHIGH + 2;
      UPDATESPARESIZE = KEEN_UPDATEWIDE * 2 + 4;
      UPDATESIZE = UPDATESCREENSIZE + 2 * UPDATESPARESIZE;
      SCREENTILESWIDE = 20;
      SCREENTILESHIGH = 13;
      EGAPORTSCREENWIDE = 42;
      PORTSCREENHIGH = 224;
      SX_T_SHIFT = 1;
      SY_T_SHIFT = 4;
      XPANMASK = 6;
    type
      TSpriteSlot = record
        ScreenX: Integer;
        ScreenY: Integer;
        Width: Integer;
        Height: Integer;
        SpriteChunk: Integer;
        SourceOfs: Integer;
        PlaneSize: Integer;
        Draw: TKeenDrawType;
        TileX: Integer;
        TileY: Integer;
        TileWide: Integer;
        TileHigh: Integer;
        Priority: Integer;
        UpdateCount: Integer;
        /// <summary>The sprite before this one in its priority list, -1 if it is the first</summary>
        Prev: Integer;
        /// <summary>The next sprite of the list (or of the free list), -1 if none</summary>
        Next: Integer;
      end;
      TEraseBlock = record
        ScreenX: Integer;
        ScreenY: Integer;
        Width: Integer;
        Height: Integer;
      end;
      TAnimChain = record
        /// <summary>The tile now; a foreground tile has the high bit set</summary>
        Current: Word;
        Count: Integer;
      end;
      TAnimTile = record
        X: Integer;
        Y: Integer;
        Tile: Word;
        Chain: Integer;
        /// <summary>The plane of the map (0 background, 1 foreground) and the word of it that this tile changes</summary>
        Plane: Integer;
        Offset: Integer;
        Prev: Integer;
        Next: Integer;
      end;
  strict private
    FVideo: IKeenVideo;
    FGraphics: IKeenGraphics;
    FTileInfo: IKeenTileInfo;
    FSprites: IKeenSpriteCache;
    FClock: IKeenClock;
    FCompatibility: Boolean;
    FMap: IKeenWorkingMap;
    FPlanes: array[0..2] of TArray<Word>;
    FChain: TArray<SmallInt>;
    FBackTiles: array of TBytes;
    FForeTiles: array of TBytes;
    FTics: Integer;
    FLastTimeCount: Integer;
    FOriginXGlobal: Integer;
    FOriginYGlobal: Integer;
    FOriginXTile: Integer;
    FOriginYTile: Integer;
    FOriginXScreen: Integer;
    FOriginYScreen: Integer;
    FOriginMap: Integer;
    FOriginXMin: Integer;
    FOriginXMax: Integer;
    FOriginYMin: Integer;
    FOriginYMax: Integer;
    FMasterOfs: Integer;
    FMapWidth: Integer;
    FMapHeight: Integer;
    FMapByteWide: Integer;
    FMapBWidthTable: array[0..KEEN_MAXMAPHEIGHT - 1] of Integer;
    FBlockStarts: array[0..KEEN_UPDATEWIDE * KEEN_UPDATEHIGH - 1] of Integer;
    FUpdateMapOfs: array[0..KEEN_UPDATEWIDE * KEEN_UPDATEHIGH - 1] of Integer;
    FUWidthTable: array[0..KEEN_PORTTILESHIGH - 1] of Integer;
    FUpdate: array[0..1] of TBytes;
    FUpdatePage: Integer;
    FUpdatePtr: Integer;
    FUpdateStart: array[0..1] of Integer;
    FBaseUpdateStart: array[0..1] of Integer;
    FScreenStart: array[0..2] of Integer;
    FScreenPage: Integer;
    FOtherPage: Integer;
    FTileCache: array[0..KEEN_NUMTILE16 - 1] of Word;
    FAllAnims: array[0..KEEN_MAXANIMTYPES - 1] of TAnimChain;
    FNumAnimChains: Integer;
    FAnimArray: array[0..KEEN_MAXANIMTILES - 1] of TAnimTile;
    FAnimHead: Integer;
    FAnimFree: Integer;
    FSpriteArray: array[0..KEEN_MAXSPRITES - 1] of TSpriteSlot;
    FPriorityStart: array[0..KEEN_PRIORITIES - 1] of Integer;
    FSpriteFree: Integer;
    FEraseList: array[0..1] of array[0..KEEN_MAXSPRITES - 1] of TEraseBlock;
    FEraseCount: array[0..1] of Integer;
    FRefreshHook: TProc;
    procedure RequireMap;
    function BackgroundTile(ATile: Integer): TBytes;
    function ForegroundTile(ATile: Integer): TBytes;
    function WordAt(APlane, AByteOffset: Integer): Word;
    procedure NewTile(AUpdateOffset: Integer);
    procedure DrawMasterTile16(ADest: Integer; const ATile: TBytes);
    procedure UpdateTiles;
    procedure MaskForegroundTiles;
    procedure CopyTileBlock(AFirstTile, ACount: Integer);
    procedure CalcOriginStuff(AX, AY: Int64);
    procedure InitSpriteList;
    procedure InitAnimList;
    procedure CheckForAnimTile(AX, AY: Integer);
    procedure RemoveAnimsOnX(AX: Integer);
    procedure RemoveAnimsOnY(AY: Integer);
    procedure FreeAnim(AIndex: Integer);
    procedure AnimateTiles;
    procedure NewRow(ADir: Integer);
    procedure OldRow(AUpdateSpot, ACount, AStep: Integer);
    procedure EraseBlocks;
    procedure UpdateSprites;
    procedure PostEraseBlock(ASlot: Integer);
    procedure UnlinkSprite(ASlot: Integer);
    procedure LinkSprite(ASlot, APriority: Integer);
    procedure MarkChain(APlane: Integer);
    procedure ClearUpdateArray(APage: Integer);
    procedure WriteTerminator(APage, AIndex: Integer);
  public
    /// <param name="AVideo">The video memory manager; the screens are drawn through it</param>
    /// <param name="AGraphics">The 16x16 tiles of the background and of the foreground</param>
    /// <param name="ATileInfo">The table of the tiles (animation, masked)</param>
    /// <param name="ASprites">The sprites with their shifts</param>
    /// <param name="AClock">TimeCount</param>
    /// <param name="ACompatibility">The "comp" parameter of the game: the screens never go past the end of the memory</param>
    constructor Create(const AVideo: IKeenVideo; const AGraphics: IKeenGraphics;
      const ATileInfo: IKeenTileInfo; const ASprites: IKeenSpriteCache; const AClock: IKeenClock;
      ACompatibility: Boolean = False);
    function GetTics: Integer;
    function GetOriginXGlobal: Integer;
    function GetOriginYGlobal: Integer;
    function GetOriginXTile: Integer;
    function GetOriginYTile: Integer;
    function GetOriginXScreen: Integer;
    function GetOriginYScreen: Integer;
    function GetMasterOfs: Integer;
    function GetOriginXMax: Integer;
    function GetOriginYMax: Integer;
    function GetOriginXMin: Integer;
    function GetOriginYMin: Integer;
    function GetMapWidth: Integer;
    function GetMapHeight: Integer;
    function GetLastTimeCount: Integer;
    procedure NewMap(const AMap: IKeenWorkingMap);
    procedure MarkTileGraphics;
    procedure NewPosition(AX, AY: Integer);
    procedure Scroll(AX, AY: Integer);
    procedure PlaceSprite(var AUser: TKeenSpriteHandle; AGlobalX, AGlobalY, ASpriteChunk: Integer;
      ADraw: TKeenDrawType; APriority: Integer);
    procedure RemoveSprite(var AUser: TKeenSpriteHandle);
    procedure Refresh;
    procedure ForceRefresh;
    procedure SetRefreshHook(const AHook: TProc);
    function UpdateSnapshot(APage: Integer): TBytes;
    function GetOtherPage: Integer;
    function GetScreenPage: Integer;
  end;

implementation

uses
  DelphiDoom.Keen.Arithmetic;

{ TKeenRefresh }

constructor TKeenRefresh.Create(const AVideo: IKeenVideo; const AGraphics: IKeenGraphics;
  const ATileInfo: IKeenTileInfo; const ASprites: IKeenSpriteCache; const AClock: IKeenClock;
  ACompatibility: Boolean);
var
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
begin
  inherited Create;
  if not Assigned(AVideo) then
    raise EArgumentNilException.Create('AVideo');
  if not Assigned(AGraphics) then
    raise EArgumentNilException.Create('AGraphics');
  if not Assigned(ATileInfo) then
    raise EArgumentNilException.Create('ATileInfo');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FVideo := AVideo;
  FGraphics := AGraphics;
  FTileInfo := ATileInfo;
  FSprites := ASprites;
  FClock := AClock;
  FCompatibility := ACompatibility;
  SetLength(FBackTiles, KEEN_NUMTILE16);
  SetLength(FForeTiles, KEEN_NUMTILE16M);
  // RF_Startup (EGA)
  for LIndex := 0 to KEEN_PORTTILESHIGH - 1 do
    FUWidthTable[LIndex] := KEEN_UPDATEWIDE * LIndex;
  FOriginXMin := KEEN_MAPBORDER * KEEN_TILEGLOBAL;
  FOriginYMin := FOriginXMin;
  for LIndex := 0 to 1 do
  begin
    SetLength(FUpdate[LIndex], UPDATESIZE);
    FBaseUpdateStart[LIndex] := UPDATESPARESIZE;
    FUpdateStart[LIndex] := UPDATESPARESIZE;
    FEraseCount[LIndex] := 0;
  end;
  FScreenStart[0] := 0;
  FScreenStart[1] := SCREENSPACE;
  FScreenStart[2] := SCREENSPACE * 2;
  FScreenPage := 0;
  FOtherPage := 1;
  FVideo.DisplayOfs := FScreenStart[FScreenPage];
  FVideo.BufferOfs := FScreenStart[FOtherPage];
  FMasterOfs := FScreenStart[2];
  FUpdatePage := FOtherPage;
  FUpdatePtr := FBaseUpdateStart[FOtherPage];
  for LY := 0 to KEEN_UPDATEHIGH - 1 do
    for LX := 0 to KEEN_UPDATEWIDE - 1 do
      FBlockStarts[LY * KEEN_UPDATEWIDE + LX] := KEEN_SCREENWIDTH * 16 * LY + LX * 2;
  InitSpriteList;
  InitAnimList;
end;

procedure TKeenRefresh.RequireMap;
begin
  if not Assigned(FMap) then
    raise EKeenException.Create(SKeenRefreshNoMap);
end;

function TKeenRefresh.GetTics: Integer;
begin
  Result := FTics;
end;

function TKeenRefresh.GetOriginXGlobal: Integer;
begin
  Result := FOriginXGlobal;
end;

function TKeenRefresh.GetOriginYGlobal: Integer;
begin
  Result := FOriginYGlobal;
end;

function TKeenRefresh.GetOriginXTile: Integer;
begin
  Result := FOriginXTile;
end;

function TKeenRefresh.GetOriginYTile: Integer;
begin
  Result := FOriginYTile;
end;

function TKeenRefresh.GetOriginXScreen: Integer;
begin
  Result := FOriginXScreen;
end;

function TKeenRefresh.GetOriginYScreen: Integer;
begin
  Result := FOriginYScreen;
end;

function TKeenRefresh.GetMasterOfs: Integer;
begin
  Result := FMasterOfs;
end;

function TKeenRefresh.GetOriginXMax: Integer;
begin
  Result := FOriginXMax;
end;

function TKeenRefresh.GetOriginYMax: Integer;
begin
  Result := FOriginYMax;
end;

function TKeenRefresh.GetOriginXMin: Integer;
begin
  Result := FOriginXMin;
end;

function TKeenRefresh.GetOriginYMin: Integer;
begin
  Result := FOriginYMin;
end;

function TKeenRefresh.GetMapWidth: Integer;
begin
  Result := FMapWidth;
end;

function TKeenRefresh.GetMapHeight: Integer;
begin
  Result := FMapHeight;
end;

function TKeenRefresh.GetLastTimeCount: Integer;
begin
  Result := FLastTimeCount;
end;

function TKeenRefresh.GetOtherPage: Integer;
begin
  Result := FOtherPage;
end;

function TKeenRefresh.GetScreenPage: Integer;
begin
  Result := FScreenPage;
end;

function TKeenRefresh.UpdateSnapshot(APage: Integer): TBytes;
begin
  Result := Copy(FUpdate[APage and 1], FUpdateStart[APage and 1], UPDATESCREENSIZE);
end;

procedure TKeenRefresh.SetRefreshHook(const AHook: TProc);
begin
  FRefreshHook := AHook;
end;

function TKeenRefresh.BackgroundTile(ATile: Integer): TBytes;
begin
  Result := nil;
  if (ATile < 0) or (ATile >= KEEN_NUMTILE16) then
    Exit;
  if Length(FBackTiles[ATile]) = 0 then
    FBackTiles[ATile] := FGraphics.Tile16(ATile);
  Result := FBackTiles[ATile];
end;

function TKeenRefresh.ForegroundTile(ATile: Integer): TBytes;
begin
  Result := nil;
  if (ATile < 0) or (ATile >= KEEN_NUMTILE16M) then
    Exit;
  if Length(FForeTiles[ATile]) = 0 then
    FForeTiles[ATile] := FGraphics.Tile16Masked(ATile);
  Result := FForeTiles[ATile];
end;

function TKeenRefresh.WordAt(APlane, AByteOffset: Integer): Word;
begin
  Result := FPlanes[APlane][(AByteOffset and $FFFF) div 2];
end;

// ---------------------------------------------------------------------------
// the lists of sprites and of animating tiles
// ---------------------------------------------------------------------------

procedure TKeenRefresh.InitSpriteList;
var
  LIndex: Integer;
begin
  FSpriteFree := 0;
  for LIndex := 0 to KEEN_MAXSPRITES - 1 do
    FSpriteArray[LIndex].Next := LIndex + 1;
  FSpriteArray[KEEN_MAXSPRITES - 1].Next := -1;
  for LIndex := 0 to KEEN_PRIORITIES - 1 do
    FPriorityStart[LIndex] := -1;
end;

procedure TKeenRefresh.InitAnimList;
var
  LIndex: Integer;
begin
  FAnimFree := 0;
  for LIndex := 0 to KEEN_MAXANIMTILES - 1 do
    FAnimArray[LIndex].Next := LIndex + 1;
  FAnimArray[KEEN_MAXANIMTILES - 1].Next := -1;
  FAnimHead := -1;
end;

procedure TKeenRefresh.NewMap(const AMap: IKeenWorkingMap);
var
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
  LSpot: Integer;
  LTable: Integer;
begin
  if not Assigned(AMap) then
    raise EArgumentNilException.Create('AMap');
  FMap := AMap;
  for LIndex := 0 to 2 do
    FPlanes[LIndex] := AMap.Planes[LIndex];
  SetLength(FChain, AMap.Width * AMap.Height);
  for LIndex := 0 to High(FChain) do
    FChain[LIndex] := -1;
  FMapWidth := AMap.Width;
  FMapByteWide := 2 * FMapWidth;
  FMapHeight := AMap.Height;
  // a lookup table for the left edge of the map
  LSpot := 0;
  for LIndex := 0 to FMapHeight - 1 do
  begin
    FMapBWidthTable[LIndex] := LSpot;
    Inc(LSpot, FMapByteWide);
  end;
  // updatemapofs with the new width
  LTable := 0;
  for LY := 0 to KEEN_PORTTILESHIGH - 1 do
    for LX := 0 to KEEN_UPDATEWIDE - 1 do
    begin
      FUpdateMapOfs[LTable] := FMapBWidthTable[LY] + LX * 2;
      Inc(LTable);
    end;
  // the y max clips off the bottom half of a tile, so a map of 13 + MAPBORDER * 2 tiles high does not scroll
  FOriginXMax := (FMapWidth - KEEN_MAPBORDER - SCREENTILESWIDE) * KEEN_TILEGLOBAL;
  FOriginYMax := (FMapHeight - KEEN_MAPBORDER - SCREENTILESHIGH) * KEEN_TILEGLOBAL;
  if FOriginXMax < FOriginXMin then
    FOriginXMax := FOriginXMin;
  if FOriginYMax < FOriginYMin then
    FOriginYMax := FOriginYMin;
  InitSpriteList;
  InitAnimList;
  // adaptive timing
  FLastTimeCount := FClock.TimeCount;
  FTics := 1;
end;

procedure TKeenRefresh.MarkChain(APlane: Integer);
var
  LIndex: Integer;
  LTile: Integer;
  LNext: Integer;
  LAnims: Integer;
  LKey: Integer;
  LFound: Boolean;
  LChainIndex: Integer;
  LAnimation: Integer;
  LLimit: Integer;
begin
  if APlane = 0 then
    LLimit := KEEN_NUMTILE16
  else
    LLimit := KEEN_NUMTILE16M;
  for LIndex := 0 to FMapWidth * FMapHeight - 1 do
  begin
    // a tile under 0 as an int is a tile that is never drawn
    LTile := SmallInt(FPlanes[APlane][LIndex]);
    if LTile < 0 then
      Continue;
    if LTile >= LLimit then
      Continue;
    if APlane = 0 then
      LAnimation := FTileInfo.Animation(LTile)
    else
      LAnimation := FTileInfo.MaskedAnimation(LTile);
    if LAnimation = 0 then
      Continue;
    // this tile will animate; a foreground tile has the high bit in the chain
    if APlane = 0 then
      LKey := LTile
    else
      LKey := LTile or $8000;
    LFound := False;
    LChainIndex := 0;
    while LChainIndex < FNumAnimChains do
    begin
      if FAllAnims[LChainIndex].Current = LKey then
      begin
        LFound := True;
        Break;
      end;
      Inc(LChainIndex);
    end;
    if LFound then
    begin
      FChain[LIndex] := LChainIndex;
      Continue;
    end;
    // a new chain of animating tiles
    if LChainIndex >= KEEN_MAXANIMTYPES then
      raise EKeenException.Create(SKeenRefreshTooManyAnims);
    FAllAnims[LChainIndex].Current := Word(LKey);
    if APlane = 0 then
      FAllAnims[LChainIndex].Count := FTileInfo.Speed(LTile)
    else
      FAllAnims[LChainIndex].Count := FTileInfo.MaskedSpeed(LTile);
    FChain[LIndex] := LChainIndex;
    Inc(FNumAnimChains);
    LAnims := 0;
    LNext := LTile + LAnimation;
    while LNext <> LTile do
    begin
      if (LNext < 0) or (LNext >= LLimit) then
        raise EKeenException.CreateFmt(SKeenRefreshUnendingAnim, [LTile]);
      if APlane = 0 then
        Inc(LNext, FTileInfo.Animation(LNext))
      else
        Inc(LNext, FTileInfo.MaskedAnimation(LNext));
      Inc(LAnims);
      if LAnims > 20 then
        raise EKeenException.CreateFmt(SKeenRefreshUnendingAnim, [LTile]);
    end;
  end;
end;

procedure TKeenRefresh.MarkTileGraphics;
begin
  RequireMap;
  FillChar(FAllAnims, SizeOf(FAllAnims), 0);
  FNumAnimChains := 0;
  // the background plane and then the foreground plane (the foreground chain wins where both animate)
  MarkChain(0);
  MarkChain(1);
end;

procedure TKeenRefresh.CheckForAnimTile(AX, AY: Integer);
var
  LOffset: Integer;
  LTile: Integer;
  LPlane: Integer;
  LAnimates: Boolean;
  LSlot: Integer;
  LNext: Integer;
begin
  LOffset := FMapBWidthTable[AY] div 2 + AX;
  for LPlane := 0 to 1 do
  begin
    LTile := FPlanes[LPlane][LOffset];
    if LPlane = 0 then
      LAnimates := (LTile < KEEN_NUMTILE16) and (FTileInfo.Animation(LTile) <> 0)
    else
      LAnimates := (LTile < KEEN_NUMTILE16M) and (FTileInfo.MaskedAnimation(LTile) <> 0);
    if not LAnimates then
      Continue;
    if FAnimFree < 0 then
      raise EKeenException.Create(SKeenRefreshNoAnimTiles);
    LSlot := FAnimFree;
    FAnimFree := FAnimArray[LSlot].Next;
    // stick it at the start of the list
    LNext := FAnimHead;
    FAnimHead := LSlot;
    if LNext >= 0 then
      FAnimArray[LNext].Prev := LSlot;
    FAnimArray[LSlot].Next := LNext;
    FAnimArray[LSlot].Prev := -1;
    FAnimArray[LSlot].X := AX;
    FAnimArray[LSlot].Y := AY;
    FAnimArray[LSlot].Tile := Word(LTile);
    FAnimArray[LSlot].Plane := LPlane;
    FAnimArray[LSlot].Offset := LOffset;
    FAnimArray[LSlot].Chain := FChain[LOffset];
    if FAnimArray[LSlot].Chain < 0 then
      raise EKeenException.CreateFmt(SKeenRefreshNoChain, [AX, AY]);
  end;
end;

procedure TKeenRefresh.FreeAnim(AIndex: Integer);
var
  LNext: Integer;
begin
  LNext := FAnimArray[AIndex].Next;
  if FAnimArray[AIndex].Prev < 0 then
    FAnimHead := LNext
  else
    FAnimArray[FAnimArray[AIndex].Prev].Next := LNext;
  if LNext >= 0 then
    FAnimArray[LNext].Prev := FAnimArray[AIndex].Prev;
  FAnimArray[AIndex].Next := FAnimFree;
  FAnimFree := AIndex;
end;

procedure TKeenRefresh.RemoveAnimsOnX(AX: Integer);
var
  LCurrent: Integer;
  LNext: Integer;
begin
  LCurrent := FAnimHead;
  while LCurrent >= 0 do
  begin
    LNext := FAnimArray[LCurrent].Next;
    if FAnimArray[LCurrent].X = AX then
      FreeAnim(LCurrent);
    LCurrent := LNext;
  end;
end;

procedure TKeenRefresh.RemoveAnimsOnY(AY: Integer);
var
  LCurrent: Integer;
  LNext: Integer;
begin
  LCurrent := FAnimHead;
  while LCurrent >= 0 do
  begin
    LNext := FAnimArray[LCurrent].Next;
    if FAnimArray[LCurrent].Y = AY then
      FreeAnim(LCurrent);
    LCurrent := LNext;
  end;
end;

procedure TKeenRefresh.AnimateTiles;
var
  LIndex: Integer;
  LTile: Integer;
  LCurrent: Integer;
  LX: Integer;
  LY: Integer;
  LNewTile: Word;
begin
  // animate the chains of tiles; a chain with the tile 0 ends the list (as in the C)
  LIndex := 0;
  while (LIndex < KEEN_MAXANIMTYPES) and (FAllAnims[LIndex].Current <> 0) do
  begin
    Dec(FAllAnims[LIndex].Count, FTics);
    while FAllAnims[LIndex].Count < 1 do
    begin
      if (FAllAnims[LIndex].Current and $8000) <> 0 then
      begin
        LTile := FAllAnims[LIndex].Current and $7FFF;
        LTile := (LTile + FTileInfo.MaskedAnimation(LTile)) and $FFFF;
        Inc(FAllAnims[LIndex].Count, FTileInfo.MaskedSpeed(LTile));
        LTile := LTile or $8000;
      end
      else
      begin
        LTile := FAllAnims[LIndex].Current;
        LTile := (LTile + FTileInfo.Animation(LTile)) and $FFFF;
        Inc(FAllAnims[LIndex].Count, FTileInfo.Speed(LTile));
      end;
      FAllAnims[LIndex].Current := Word(LTile);
    end;
    Inc(LIndex);
  end;
  // traverse the list of the animating tiles
  LCurrent := FAnimHead;
  while LCurrent >= 0 do
  begin
    LNewTile := FAllAnims[FAnimArray[LCurrent].Chain].Current;
    if LNewTile <> FAnimArray[LCurrent].Tile then
    begin
      // the tile has animated: it changes in the map, it leaves the cache of the master screen and a
      // region is posted to both update pages
      FAnimArray[LCurrent].Tile := LNewTile;
      FPlanes[FAnimArray[LCurrent].Plane][FAnimArray[LCurrent].Offset] := LNewTile and $7FFF;
      if LNewTile < KEEN_NUMTILE16 then
        FTileCache[LNewTile] := 0;
      LX := Word(FAnimArray[LCurrent].X - FOriginXTile);
      LY := Word(FAnimArray[LCurrent].Y - FOriginYTile);
      if (LX >= KEEN_PORTTILESWIDE) or (LY >= KEEN_PORTTILESHIGH) then
        raise EKeenException.CreateFmt(SKeenRefreshOutOfBounds, [LX, LY]);
      NewTile(FUWidthTable[LY] + LX);
    end;
    LCurrent := FAnimArray[LCurrent].Next;
  end;
end;

// ---------------------------------------------------------------------------
// tiles on the master screen and the pages
// ---------------------------------------------------------------------------

procedure TKeenRefresh.DrawMasterTile16(ADest: Integer; const ATile: TBytes);
var
  LPlane: Integer;
  LRow: Integer;
  LMemory: IKeenEgaMemory;
begin
  LMemory := FVideo.Memory;
  // a tile with no data in the file (a sparse chunk): the C draws what the unloaded chunk points to, here it is black
  if Length(ATile) < KEEN_TILE16_BYTES then
  begin
    for LPlane := 0 to KEEN_EGA_PLANES - 1 do
      for LRow := 0 to 15 do
      begin
        LMemory.WriteByte(LPlane, ADest + LRow * KEEN_SCREENWIDTH, 0);
        LMemory.WriteByte(LPlane, ADest + LRow * KEEN_SCREENWIDTH + 1, 0);
      end;
    Exit;
  end;
  for LPlane := 0 to KEEN_EGA_PLANES - 1 do
    for LRow := 0 to 15 do
    begin
      LMemory.WriteByte(LPlane, ADest + LRow * KEEN_SCREENWIDTH, ATile[LPlane * 32 + LRow * 2]);
      LMemory.WriteByte(LPlane, ADest + LRow * KEEN_SCREENWIDTH + 1, ATile[LPlane * 32 + LRow * 2 + 1]);
    end;
end;

procedure TKeenRefresh.NewTile(AUpdateOffset: Integer);
var
  LMapOffset: Integer;
  LDest: Integer;
  LForeground: Integer;
  LBackground: Integer;
  LCached: Integer;
  LRow: Integer;
  LBackBytes: TBytes;
  LForeBytes: TBytes;
  LPlane: Integer;
  LColumn: Integer;
  LMemory: IKeenEgaMemory;
begin
  // mark both update lists at this spot
  FUpdate[0][FUpdateStart[0] + AUpdateOffset] := 1;
  FUpdate[1][FUpdateStart[1] + AUpdateOffset] := 1;
  LMapOffset := FUpdateMapOfs[AUpdateOffset] + FOriginMap;
  LDest := (FBlockStarts[AUpdateOffset] + FMasterOfs) and $FFFF;
  LForeground := WordAt(1, LMapOffset);
  LBackground := WordAt(0, LMapOffset);
  LMemory := FVideo.Memory;
  LForeBytes := nil;
  if LForeground <> 0 then
    LForeBytes := ForegroundTile(LForeground);
  if Length(LForeBytes) >= KEEN_TILE16M_BYTES then
  begin
    // a masked tile combo: the background tile with the foreground over it (a foreground tile that has no
    // data in the file is not drawn)
    LBackBytes := BackgroundTile(LBackground);
    for LPlane := 0 to KEEN_EGA_PLANES - 1 do
      for LRow := 0 to 15 do
        for LColumn := 0 to 1 do
        begin
          if Length(LBackBytes) >= KEEN_TILE16_BYTES then
            LCached := LBackBytes[LPlane * 32 + LRow * 2 + LColumn]
          else
            LCached := 0;
          LMemory.WriteByte(LPlane, LDest + LRow * KEEN_SCREENWIDTH + LColumn,
            Byte((LCached and LForeBytes[LRow * 2 + LColumn]) or LForeBytes[(LPlane + 1) * 32 + LRow * 2 + LColumn]));
        end;
    Exit;
  end;
  // no foreground tile: a single background tile, from the master screen cache if it is there
  if LBackground >= KEEN_NUMTILE16 then
    Exit;
  LCached := FTileCache[LBackground];
  if LCached <> 0 then
  begin
    for LRow := 0 to 15 do
    begin
      LMemory.CopyByte(LCached + LRow * KEEN_SCREENWIDTH, LDest + LRow * KEEN_SCREENWIDTH);
      LMemory.CopyByte(LCached + LRow * KEEN_SCREENWIDTH + 1, LDest + LRow * KEEN_SCREENWIDTH + 1);
    end;
    Exit;
  end;
  // from the memory: next time it can come from here with the latches
  FTileCache[LBackground] := Word(LDest);
  DrawMasterTile16(LDest, BackgroundTile(LBackground));
end;

procedure TKeenRefresh.CopyTileBlock(AFirstTile, ACount: Integer);
var
  LStart: Integer;
  LRow: Integer;
  LColumn: Integer;
  LMemory: IKeenEgaMemory;
  LSource: Integer;
  LDest: Integer;
begin
  LMemory := FVideo.Memory;
  LStart := FBlockStarts[AFirstTile];
  LSource := (LStart + FMasterOfs) and $FFFF;
  LDest := (LStart + FVideo.BufferOfs) and $FFFF;
  for LRow := 0 to 15 do
  begin
    for LColumn := 0 to ACount * 2 - 1 do
      LMemory.CopyByte(LSource + LColumn, LDest + LColumn);
    LSource := (LSource + KEEN_SCREENWIDTH) and $FFFF;
    LDest := (LDest + KEEN_SCREENWIDTH) and $FFFF;
  end;
end;

procedure TKeenRefresh.UpdateTiles;
var
  LBase: Integer;
  LEnd: Integer;
  LPage: TBytes;
  LPosition: Integer;
  LFound: Integer;
  LNext: Integer;
  LStop: Integer;
begin
  // scans the update array for 1s: a tile that has to be copied from the master screen to the page; more
  // than one tile in a row are copied as a group. The scan ends at the 1 of the terminator
  LPage := FUpdate[FUpdatePage];
  LBase := FUpdatePtr;
  LEnd := LBase + KEEN_UPDATEWIDE * KEEN_PORTTILESHIGH + 1;
  LPosition := LBase;
  while True do
  begin
    LFound := LPosition;
    while (LFound < Length(LPage)) and (LPage[LFound] <> 1) do
      Inc(LFound);
    LNext := LFound + 1;
    if (LNext >= LEnd) or (LFound >= Length(LPage)) then
      Break;
    if LPage[LNext] <> 1 then
    begin
      // a single tile: the next one is nothing
      CopyTileBlock(LFound - LBase, 1);
      LPosition := LNext + 1;
    end
    else
    begin
      // a group: the tiles in a row that are all 1
      LStop := LNext + 1;
      while (LStop < Length(LPage)) and (LPage[LStop] = 1) do
        Inc(LStop);
      CopyTileBlock(LFound - LBase, LStop - LFound);
      LPosition := LStop + 1;
    end;
  end;
end;

procedure TKeenRefresh.MaskForegroundTiles;
var
  LBase: Integer;
  LEnd: Integer;
  LPage: TBytes;
  LPosition: Integer;
  LFound: Integer;
  LTileIndex: Integer;
  LForeground: Integer;
  LBytes: TBytes;
begin
  // looks for the 3s of the update array: a foreground tile that is masked goes over what was drawn there
  LPage := FUpdate[FUpdatePage];
  LBase := FUpdatePtr;
  LEnd := LBase + KEEN_UPDATEWIDE * KEEN_PORTTILESHIGH + 2;
  LPosition := LBase;
  while True do
  begin
    LFound := LPosition;
    while (LFound < Length(LPage)) and (LPage[LFound] <> 3) do
      Inc(LFound);
    LPosition := LFound + 1;
    if (LPosition >= LEnd) or (LFound >= Length(LPage)) then
      Break;
    LTileIndex := LFound - LBase;
    LForeground := WordAt(1, FUpdateMapOfs[LTileIndex] + FOriginMap);
    if LForeground = 0 then
      Continue;
    if (LForeground >= KEEN_NUMTILE16M) or ((FTileInfo.InTile(LForeground) and $80) = 0) then
      Continue;
    LBytes := ForegroundTile(LForeground);
    if Length(LBytes) < KEEN_TILE16M_BYTES then
      Continue;
    FVideo.MaskBlock(LBytes, 0, FBlockStarts[LTileIndex] + FVideo.BufferOfs, 2, 16, 32);
  end;
end;

// ---------------------------------------------------------------------------
// origin and scrolling
// ---------------------------------------------------------------------------

procedure TKeenRefresh.CalcOriginStuff(AX, AY: Int64);
begin
  if AX < FOriginXMin then
    AX := FOriginXMin
  else if AX > FOriginXMax then
    AX := FOriginXMax;
  if AY < FOriginYMin then
    AY := FOriginYMin
  else if AY > FOriginYMax then
    AY := FOriginYMax;
  FOriginXGlobal := Word(AX);
  FOriginYGlobal := Word(AY);
  FOriginXTile := FOriginXGlobal shr 8;
  FOriginYTile := FOriginYGlobal shr 8;
  FOriginXScreen := FOriginXTile shl SX_T_SHIFT;
  FOriginYScreen := FOriginYTile shl SY_T_SHIFT;
  FOriginMap := FMapBWidthTable[FOriginYTile] + FOriginXTile * 2;
  FVideo.PanX := (FOriginXGlobal shr 4) and 15;
  FVideo.PanSX := FVideo.PanX and 8;
  FVideo.PanY := (FOriginYGlobal shr 4) and 15;
  FVideo.PanSY := FVideo.PanY;
  FVideo.PanAdjust := FVideo.PanX div 8 + FVideo.YLookup(FVideo.PanY);
end;

procedure TKeenRefresh.WriteTerminator(APage, AIndex: Integer);
begin
  // UPDATETERMINATE: a 1 and a 3
  FUpdate[APage][AIndex] := 1;
  FUpdate[APage][AIndex + 1] := 3;
end;

procedure TKeenRefresh.NewPosition(AX, AY: Integer);
var
  LMX: Integer;
  LMY: Integer;
  LUpdateNum: Integer;
  LPage0: Integer;
  LPage1: Integer;
begin
  RequireMap;
  CalcOriginStuff(AX and $FFFF, AY and $FFFF);
  // clear out all the animating tiles
  InitAnimList;
  // the old cache is not valid
  FillChar(FTileCache, SizeOf(FTileCache), 0);
  FUpdateStart[0] := FBaseUpdateStart[0];
  FUpdateStart[1] := FBaseUpdateStart[1];
  LPage0 := FUpdateStart[0] + KEEN_PORTTILESWIDE;
  LPage1 := FUpdateStart[1] + KEEN_PORTTILESWIDE;
  LUpdateNum := 0;
  for LMY := 0 to KEEN_PORTTILESHIGH - 1 do
  begin
    for LMX := 0 to KEEN_PORTTILESWIDE - 1 do
    begin
      NewTile(LUpdateNum);
      CheckForAnimTile(LMX + FOriginXTile, LMY + FOriginYTile);
      Inc(LUpdateNum);
    end;
    Inc(LUpdateNum);
    // a 0 at the end of a line of tiles
    FUpdate[0][LPage0] := 0;
    FUpdate[1][LPage1] := 0;
    Inc(LPage0, KEEN_PORTTILESWIDE + 1);
    Inc(LPage1, KEEN_PORTTILESWIDE + 1);
  end;
  WriteTerminator(0, LPage0 - KEEN_PORTTILESWIDE);
  WriteTerminator(1, LPage1 - KEEN_PORTTILESWIDE);
end;

procedure TKeenRefresh.NewRow(ADir: Integer);
var
  LCount: Integer;
  LUpdateSpot: Integer;
  LUpdateStep: Integer;
  LX: Integer;
  LY: Integer;
  LXStep: Integer;
  LYStep: Integer;
begin
  case ADir of
    0: // top row
      begin
        LUpdateSpot := 0;
        LUpdateStep := 1;
        LX := FOriginXTile;
        LY := FOriginYTile;
        LXStep := 1;
        LYStep := 0;
        LCount := KEEN_PORTTILESWIDE;
      end;
    1: // right row
      begin
        LUpdateSpot := KEEN_PORTTILESWIDE - 1;
        LUpdateStep := KEEN_UPDATEWIDE;
        LX := FOriginXTile + KEEN_PORTTILESWIDE - 1;
        LY := FOriginYTile;
        LXStep := 0;
        LYStep := 1;
        LCount := KEEN_PORTTILESHIGH;
      end;
    2: // bottom row
      begin
        LUpdateSpot := KEEN_UPDATEWIDE * (KEEN_PORTTILESHIGH - 1);
        LUpdateStep := 1;
        LX := FOriginXTile;
        LY := FOriginYTile + KEEN_PORTTILESHIGH - 1;
        LXStep := 1;
        LYStep := 0;
        LCount := KEEN_PORTTILESWIDE;
      end;
    3: // left row
      begin
        LUpdateSpot := 0;
        LUpdateStep := KEEN_UPDATEWIDE;
        LX := FOriginXTile;
        LY := FOriginYTile;
        LXStep := 0;
        LYStep := 1;
        LCount := KEEN_PORTTILESHIGH;
      end;
  else
    raise EKeenException.Create('Keen: RFL_NewRow: bad direction');
  end;
  while LCount > 0 do
  begin
    NewTile(LUpdateSpot);
    CheckForAnimTile(LX, LY);
    Inc(LUpdateSpot, LUpdateStep);
    Inc(LX, LXStep);
    Inc(LY, LYStep);
    Dec(LCount);
  end;
end;

procedure TKeenRefresh.OldRow(AUpdateSpot, ACount, AStep: Integer);
var
  LSpot: Integer;
  LTile: Integer;
begin
  // uncache the trailing row of tiles: a foreground tile means the block was not cached
  LSpot := AUpdateSpot;
  while ACount > 0 do
  begin
    if WordAt(1, LSpot) = 0 then
    begin
      LTile := WordAt(0, LSpot);
      if LTile < KEEN_NUMTILE16 then
        FTileCache[LTile] := 0;
    end;
    LSpot := (LSpot + AStep) and $FFFF;
    Dec(ACount);
  end;
end;

procedure TKeenRefresh.Scroll(AX, AY: Integer);
var
  LOldXTile: Integer;
  LOldYTile: Integer;
  LOldOriginMap: Integer;
  LOldPanAdjust: Integer;
  LOldPanX: Integer;
  LDeltaX: Integer;
  LDeltaY: Integer;
  LScreenMove: Integer;
  LIndex: Integer;
  LScreenCopy: Integer;
  LOldScreen: Integer;
  LNewScreen: Integer;
  LMove: Integer;
  LUpdateSpot: Integer;
  LRow: Integer;
begin
  RequireMap;
  LOldXTile := FOriginXTile;
  LOldYTile := FOriginYTile;
  LOldOriginMap := FOriginMap;
  LOldPanAdjust := FVideo.PanAdjust;
  LOldPanX := FVideo.PanX;
  CalcOriginStuff(Int64(FOriginXGlobal) + AX, Int64(FOriginYGlobal) + AY);
  LDeltaX := FOriginXTile - LOldXTile;
  LDeltaY := FOriginYTile - LOldYTile;
  if (Abs(LDeltaX) > 1) or (Abs(LDeltaY) > 1) then
  begin
    // scrolled more than one tile, so start from scratch
    NewPosition(FOriginXGlobal, FOriginYGlobal);
    Exit;
  end;
  if (LDeltaX = 0) and (LDeltaY = 0) then
    Exit; // the screen has not scrolled an entire tile
  // adjust the screens and handle the crippled compatibility mode of the SVGAs
  LScreenMove := LDeltaY * 16 * KEEN_SCREENWIDTH + LDeltaX * 2;
  for LIndex := 0 to 2 do
  begin
    FScreenStart[LIndex] := (FScreenStart[LIndex] + LScreenMove) and $FFFF;
    if FCompatibility and (FScreenStart[LIndex] > ($10000 - SCREENSPACE)) then
    begin
      // move the screen to the opposite end of the buffer
      if LScreenMove > 0 then
        LScreenCopy := FREEEGAMEM
      else
        LScreenCopy := (-FREEEGAMEM) and $FFFF;
      LOldScreen := (FScreenStart[LIndex] - LScreenMove) and $FFFF;
      LNewScreen := (LOldScreen + LScreenCopy) and $FFFF;
      FScreenStart[LIndex] := (LNewScreen + LScreenMove) and $FFFF;
      FVideo.ScreenToScreen(LOldScreen, LNewScreen, KEEN_PORTTILESWIDE * 2, KEEN_PORTTILESHIGH * 16);
      if LIndex = FScreenPage then
        FVideo.SetScreen(LNewScreen + LOldPanAdjust, LOldPanX and XPANMASK);
    end;
  end;
  FVideo.BufferOfs := FScreenStart[FOtherPage];
  FVideo.DisplayOfs := FScreenStart[FScreenPage];
  FMasterOfs := FScreenStart[2];
  // float the update regions
  LMove := LDeltaX;
  if LDeltaY = 1 then
    Inc(LMove, KEEN_UPDATEWIDE)
  else if LDeltaY = -1 then
    Dec(LMove, KEEN_UPDATEWIDE);
  Inc(FUpdateStart[0], LMove);
  Inc(FUpdateStart[1], LMove);
  // the new tiles that scrolled on are drawn on the master screen and marked for both pages
  if LDeltaX <> 0 then
  begin
    if LDeltaX = 1 then
    begin
      NewRow(1); // a new right row
      OldRow(LOldOriginMap, KEEN_PORTTILESHIGH, FMapByteWide);
      RemoveAnimsOnX(FOriginXTile - 1);
    end
    else
    begin
      NewRow(3); // a new left row
      OldRow(LOldOriginMap + (KEEN_PORTTILESWIDE - 1) * 2, KEEN_PORTTILESHIGH, FMapByteWide);
      RemoveAnimsOnX(FOriginXTile + KEEN_PORTTILESWIDE);
    end;
    // a 0 at the end of each row
    for LRow := 0 to KEEN_PORTTILESHIGH - 1 do
    begin
      FUpdate[0][FUpdateStart[0] + KEEN_PORTTILESWIDE + LRow * KEEN_UPDATEWIDE] := 0;
      FUpdate[1][FUpdateStart[1] + KEEN_PORTTILESWIDE + LRow * KEEN_UPDATEWIDE] := 0;
    end;
  end;
  if LDeltaY <> 0 then
  begin
    if LDeltaY = 1 then
    begin
      NewRow(2); // a new bottom row
      OldRow(LOldOriginMap, KEEN_PORTTILESWIDE, 2);
      LUpdateSpot := KEEN_UPDATEWIDE * (KEEN_PORTTILESHIGH - 1);
      RemoveAnimsOnY(FOriginYTile - 1);
    end
    else
    begin
      NewRow(0); // a new top row
      OldRow(LOldOriginMap + FMapBWidthTable[KEEN_PORTTILESHIGH - 1], KEEN_PORTTILESWIDE, 2);
      LUpdateSpot := 0;
      RemoveAnimsOnY(FOriginYTile + KEEN_PORTTILESHIGH);
    end;
    FUpdate[0][FUpdateStart[0] + LUpdateSpot + KEEN_PORTTILESWIDE] := 0;
    FUpdate[1][FUpdateStart[1] + LUpdateSpot + KEEN_PORTTILESWIDE] := 0;
  end;
  // a new terminator
  FUpdate[0][FUpdateStart[0] + KEEN_UPDATEWIDE * KEEN_PORTTILESHIGH - 1] := 0;
  FUpdate[1][FUpdateStart[1] + KEEN_UPDATEWIDE * KEEN_PORTTILESHIGH - 1] := 0;
  WriteTerminator(0, FUpdateStart[0] + KEEN_UPDATEWIDE * KEEN_PORTTILESHIGH);
  WriteTerminator(1, FUpdateStart[1] + KEEN_UPDATEWIDE * KEEN_PORTTILESHIGH);
end;

// ---------------------------------------------------------------------------
// sprites
// ---------------------------------------------------------------------------

procedure TKeenRefresh.PostEraseBlock(ASlot: Integer);
var
  LBlock: TEraseBlock;
begin
  // an erase block (the position and the size) to both pages; both are not needed if the sprite just
  // changed last frame
  LBlock.ScreenX := FSpriteArray[ASlot].ScreenX;
  LBlock.ScreenY := FSpriteArray[ASlot].ScreenY;
  LBlock.Width := FSpriteArray[ASlot].Width;
  LBlock.Height := FSpriteArray[ASlot].Height;
  if FSpriteArray[ASlot].UpdateCount < 2 then
  begin
    if FSpriteArray[ASlot].UpdateCount = 0 then
    begin
      FEraseList[FOtherPage][FEraseCount[FOtherPage]] := LBlock;
      Inc(FEraseCount[FOtherPage]);
    end;
    FEraseList[FScreenPage][FEraseCount[FScreenPage]] := LBlock;
    Inc(FEraseCount[FScreenPage]);
  end;
end;

procedure TKeenRefresh.UnlinkSprite(ASlot: Integer);
var
  LNext: Integer;
begin
  LNext := FSpriteArray[ASlot].Next;
  if LNext >= 0 then
    FSpriteArray[LNext].Prev := FSpriteArray[ASlot].Prev;
  if FSpriteArray[ASlot].Prev < 0 then
    FPriorityStart[FSpriteArray[ASlot].Priority] := LNext
  else
    FSpriteArray[FSpriteArray[ASlot].Prev].Next := LNext;
end;

procedure TKeenRefresh.LinkSprite(ASlot, APriority: Integer);
var
  LNext: Integer;
begin
  // at the start of the list of its priority
  LNext := FPriorityStart[APriority];
  if LNext >= 0 then
    FSpriteArray[LNext].Prev := ASlot;
  FSpriteArray[ASlot].Next := LNext;
  FPriorityStart[APriority] := ASlot;
  FSpriteArray[ASlot].Prev := -1;
end;

procedure TKeenRefresh.PlaceSprite(var AUser: TKeenSpriteHandle; AGlobalX, AGlobalY,
  ASpriteChunk: Integer; ADraw: TKeenDrawType; APriority: Integer);
var
  LSlot: Integer;
  LEntry: TKeenSpriteEntry;
  LSprite: TKeenSprite;
  LShift: Integer;
  LPixelX: Integer;
begin
  if ASpriteChunk = 0 then
  begin
    RemoveSprite(AUser);
    Exit;
  end;
  if (APriority < 0) or (APriority >= KEEN_PRIORITIES) then
    raise EKeenException.CreateFmt(SKeenRefreshBadPriority, [APriority, KEEN_PRIORITIES - 1]);
  if not Assigned(FSprites) then
    raise EKeenException.Create(SKeenRefreshNoSprites);
  if AUser > 0 then
  begin
    // the sprite is already in the list, so its block can be used
    LSlot := AUser - 1;
    PostEraseBlock(LSlot);
    if APriority <> FSpriteArray[LSlot].Priority then
    begin
      // the sprite moved to another priority: it leaves the old list and goes in the new one
      UnlinkSprite(LSlot);
      LinkSprite(LSlot, APriority);
    end;
  end
  else
  begin
    // a new sprite: a block from the free list
    if FSpriteFree < 0 then
      raise EKeenException.Create(SKeenRefreshNoSprites);
    LSlot := FSpriteFree;
    FSpriteFree := FSpriteArray[LSlot].Next;
    LinkSprite(LSlot, APriority);
  end;
  // the new information of the sprite
  LEntry := FSprites.GetEntry(ASpriteChunk);
  LSprite := FSprites.GetSprite(ASpriteChunk);
  AGlobalY := (AGlobalY + LEntry.OriginY) and $FFFF;
  AGlobalX := (AGlobalX + LEntry.OriginX) and $FFFF;
  LPixelX := AGlobalX shr 4;
  LShift := (LPixelX and 7) div 2;
  with FSpriteArray[LSlot] do
  begin
    ScreenX := LPixelX shr 3;
    ScreenY := AGlobalY shr 4;
    Width := LSprite.Width[LShift];
    Height := LEntry.Height;
    SpriteChunk := ASpriteChunk;
    SourceOfs := LSprite.SourceOffset[LShift];
    PlaneSize := LSprite.PlaneSize[LShift];
    Draw := ADraw;
    Priority := APriority;
    TileX := ScreenX shr SX_T_SHIFT;
    TileY := ScreenY shr SY_T_SHIFT;
    TileWide := ((ScreenX + Width - 1) shr SX_T_SHIFT) - TileX + 1;
    TileHigh := ((ScreenY + Height - 1) shr SY_T_SHIFT) - TileY + 1;
    // draw on the next two refreshes
    UpdateCount := 2;
  end;
  // the sprite is kept in the pointer of the user, so it can be moved again later
  AUser := LSlot + 1;
end;

procedure TKeenRefresh.RemoveSprite(var AUser: TKeenSpriteHandle);
var
  LSlot: Integer;
begin
  if AUser <= 0 then
    Exit;
  LSlot := AUser - 1;
  PostEraseBlock(LSlot);
  UnlinkSprite(LSlot);
  // back to the free list
  FSpriteArray[LSlot].Next := FSpriteFree;
  FSpriteFree := LSlot;
  // so the next time that the actor is placed, it gets a new block
  AUser := 0;
end;

procedure TKeenRefresh.EraseBlocks;
var
  LIndex: Integer;
  LBlock: TEraseBlock;
  LScreenXH: Integer;
  LScreenYH: Integer;
  LPosition: Integer;
  LXTL: Integer;
  LYTL: Integer;
  LXTH: Integer;
  LYTH: Integer;
  LX: Integer;
  LY: Integer;
  LSpot: Integer;
  LSkip: Boolean;
begin
  for LIndex := 0 to FEraseCount[FOtherPage] - 1 do
  begin
    LBlock := FEraseList[FOtherPage][LIndex];
    LSkip := False;
    // clip the block to the current view
    Dec(LBlock.ScreenX, FOriginXScreen);
    Dec(LBlock.ScreenY, FOriginYScreen);
    if LBlock.ScreenX < 0 then
    begin
      Inc(LBlock.Width, LBlock.ScreenX);
      if LBlock.Width < 1 then
        LSkip := True
      else
        LBlock.ScreenX := 0;
    end;
    if (not LSkip) and (LBlock.ScreenY < 0) then
    begin
      Inc(LBlock.Height, LBlock.ScreenY);
      if LBlock.Height < 1 then
        LSkip := True
      else
        LBlock.ScreenY := 0;
    end;
    if LSkip then
      Continue;
    LScreenXH := LBlock.ScreenX + LBlock.Width;
    LScreenYH := LBlock.ScreenY + LBlock.Height;
    if LScreenXH > EGAPORTSCREENWIDE then
      LBlock.Width := EGAPORTSCREENWIDE - LBlock.ScreenX;
    if LScreenYH > PORTSCREENHIGH then
      LBlock.Height := PORTSCREENHIGH - LBlock.ScreenY;
    if (LBlock.Width < 1) or (LBlock.Height < 1) then
      Continue;
    // erase by copying from the master screen
    LPosition := FVideo.YLookup(LBlock.ScreenY) + LBlock.ScreenX;
    FVideo.ScreenToScreen(FMasterOfs + LPosition, FVideo.BufferOfs + LPosition, LBlock.Width, LBlock.Height);
    // 2s in the update array where the block was, to force the sprites to update
    LXTL := LBlock.ScreenX shr SX_T_SHIFT;
    LXTH := (LBlock.ScreenX + LBlock.Width - 1) shr SX_T_SHIFT;
    LYTL := LBlock.ScreenY shr SY_T_SHIFT;
    LYTH := (LBlock.ScreenY + LBlock.Height - 1) shr SY_T_SHIFT;
    LSpot := FUpdatePtr + FUWidthTable[LYTL] + LXTL;
    for LY := LYTL to LYTH do
    begin
      for LX := LXTL to LXTH do
      begin
        FUpdate[FUpdatePage][LSpot] := 2;
        Inc(LSpot);
      end;
      Inc(LSpot, KEEN_UPDATEWIDE - (LXTH - LXTL + 1));
    end;
  end;
  FEraseCount[FOtherPage] := 0;
end;

procedure TKeenRefresh.UpdateSprites;
var
  LPriority: Integer;
  LSlot: Integer;
  LPortX: Integer;
  LPortY: Integer;
  LXTL: Integer;
  LXTH: Integer;
  LYTL: Integer;
  LYTH: Integer;
  LBaseSpot: Integer;
  LSpot: Integer;
  LDelta: Integer;
  LX: Integer;
  LY: Integer;
  LRedraw: Boolean;
  LHeight: Integer;
  LSourceOfs: Integer;
  LDest: Integer;
  LSprite: TKeenSprite;
begin
  for LPriority := 0 to KEEN_PRIORITIES - 1 do
  begin
    if LPriority = KEEN_MASKEDTILEPRIORITY then
      MaskForegroundTiles;
    LSlot := FPriorityStart[LPriority];
    while LSlot >= 0 do
    begin
      // does the sprite have a visible area in the port?
      LPortX := FSpriteArray[LSlot].ScreenX - FOriginXScreen;
      LPortY := FSpriteArray[LSlot].ScreenY - FOriginYScreen;
      LXTL := TKeenArithmetic.ShiftRight(LPortX, SX_T_SHIFT);
      LXTH := TKeenArithmetic.ShiftRight(LPortX + FSpriteArray[LSlot].Width - 1, SX_T_SHIFT);
      LYTL := TKeenArithmetic.ShiftRight(LPortY, SY_T_SHIFT);
      LYTH := TKeenArithmetic.ShiftRight(LPortY + FSpriteArray[LSlot].Height - 1, SY_T_SHIFT);
      if LXTL < 0 then
        LXTL := 0;
      if LXTH >= KEEN_PORTTILESWIDE then
        LXTH := KEEN_PORTTILESWIDE - 1;
      if LYTL < 0 then
        LYTL := 0;
      if LYTH >= KEEN_PORTTILESHIGH then
        LYTH := KEEN_PORTTILESHIGH - 1;
      if (LXTL > LXTH) or (LYTL > LYTH) then
      begin
        LSlot := FSpriteArray[LSlot].Next;
        Continue;
      end;
      // does its visible area cover any update tile that is not 0?
      LBaseSpot := FUpdatePtr + FUWidthTable[LYTL] + LXTL;
      LDelta := KEEN_UPDATEWIDE - (LXTH - LXTL + 1);
      LRedraw := False;
      if FSpriteArray[LSlot].UpdateCount > 0 then
      begin
        // the sprite was just placed: it is drawn for sure
        Dec(FSpriteArray[LSlot].UpdateCount);
        LRedraw := True;
      end
      else
      begin
        LSpot := LBaseSpot;
        for LY := LYTL to LYTH do
        begin
          for LX := LXTL to LXTH do
          begin
            if FUpdate[FUpdatePage][LSpot] <> 0 then
              LRedraw := True;
            Inc(LSpot);
          end;
          Inc(LSpot, LDelta);
        end;
      end;
      if LRedraw then
      begin
        // the tiles that it covers are 3: they are being updated
        LSpot := LBaseSpot;
        for LY := LYTL to LYTH do
        begin
          for LX := LXTL to LXTH do
          begin
            FUpdate[FUpdatePage][LSpot] := 3;
            Inc(LSpot);
          end;
          Inc(LSpot, LDelta);
        end;
        // draw it
        LHeight := FSpriteArray[LSlot].Height;
        LSourceOfs := FSpriteArray[LSlot].SourceOfs;
        if LPortY < 0 then
        begin
          // clip the top off
          Inc(LHeight, LPortY);
          Dec(LSourceOfs, LPortY * FSpriteArray[LSlot].Width);
          LPortY := 0;
        end
        else if LPortY + LHeight > PORTSCREENHIGH then
          LHeight := PORTSCREENHIGH - LPortY;
        LDest := FVideo.BufferOfs + FVideo.YLookup(LPortY) + LPortX;
        if FSpriteArray[LSlot].Draw = kdtSpriteDraw then
        begin
          LSprite := FSprites.GetSprite(FSpriteArray[LSlot].SpriteChunk);
          FVideo.MaskBlock(LSprite.Data, LSourceOfs, LDest, FSpriteArray[LSlot].Width, LHeight,
            FSpriteArray[LSlot].PlaneSize);
        end;
      end;
      LSlot := FSpriteArray[LSlot].Next;
    end;
  end;
end;

procedure TKeenRefresh.ClearUpdateArray(APage: Integer);
begin
  FUpdateStart[APage] := FBaseUpdateStart[APage];
  FillChar(FUpdate[APage][FUpdateStart[APage]], UPDATESCREENSIZE - 2, 0);
  WriteTerminator(APage, FUpdateStart[APage] + UPDATESCREENSIZE - 2);
end;

procedure TKeenRefresh.Refresh;
var
  LNewTime: Integer;
begin
  FUpdatePage := FOtherPage;
  FUpdatePtr := FUpdateStart[FOtherPage];
  AnimateTiles;
  // newly scrolled on tiles and animated tiles are copied from the master screen
  UpdateTiles;
  EraseBlocks;
  // the sprites that cover an update tile that is not 0
  UpdateSprites;
  // the hook of the main program, before the new page is shown
  if Assigned(FRefreshHook) then
    FRefreshHook();
  // show the changed screen
  FVideo.SetScreen(FVideo.BufferOfs + FVideo.PanAdjust, FVideo.PanX and XPANMASK);
  // prepare for the next refresh: the update array in the middle position and all 0, with the terminator
  ClearUpdateArray(FOtherPage);
  FScreenPage := FScreenPage xor 1;
  FOtherPage := FOtherPage xor 1;
  FVideo.BufferOfs := FScreenStart[FOtherPage];
  FVideo.DisplayOfs := FScreenStart[FScreenPage];
  // the tics since the last refresh, for the adaptive timing
  if FLastTimeCount > FClock.TimeCount then
    FLastTimeCount := FClock.TimeCount; // the game was paused for a long time
  repeat
    LNewTime := FClock.TimeCount;
    FTics := LNewTime - FLastTimeCount;
    if FTics < KEEN_MINTICS then
      FClock.Idle;
  until FTics >= KEEN_MINTICS;
  FLastTimeCount := LNewTime;
  if FTics > KEEN_MAXTICS then
  begin
    FClock.TimeCount := FClock.TimeCount - (FTics - KEEN_MAXTICS);
    FTics := KEEN_MAXTICS;
  end;
end;

procedure TKeenRefresh.ForceRefresh;
begin
  NewPosition(FOriginXGlobal, FOriginYGlobal);
  Refresh;
  Refresh;
end;

end.
