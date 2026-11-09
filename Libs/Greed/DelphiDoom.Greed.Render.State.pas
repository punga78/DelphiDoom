{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the state of a frame of the renderer             }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the variables of r_render,  }
{  r_walls, r_plane, r_spans and r_public, which here belong to one object      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Render.State;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.Render.Tables,
  DelphiDoom.Greed.Render.Assets.Intf;

const
  /// <summary>One more than the planes of the map: the walls read the tile after the last one</summary>
  GREED_RENDER_MAP_BYTES = GREED_MAP_TILES + 128;
  GREED_RENDER_Z_COLORMAPS = GREED_MAX_Z div GREED_FRACUNIT + 1;

type
  TGreedMapBytes = array[0..GREED_RENDER_MAP_BYTES - 1] of Byte;
  PGreedPixelRow = PByte;

  /// <summary>A wall texture: its lump, the height of the columns and where each of the 64 columns starts</summary>
  PGreedRenderWall = ^TGreedRenderWall;
  TGreedRenderWall = record
    Loaded: Boolean;
    /// <summary>False if the lump is not there</summary>
    Present: Boolean;
    Data: PByte;
    /// <summary>The first word of the lump times 4 (wall^ * 4): the loop of the post</summary>
    Height: Integer;
    Posts: array[0..63] of PByte;
  end;

  /// <summary>
  ///   All the variables that the original keeps in the globals of its renderer units, for one picture: the view, the
  ///   tile that is drawn, the lists of vertices, tiles and spans, and the registers of the routines that scale a
  ///   post. The classes of the renderer share one object of this kind and nothing else. The fields are public: they
  ///   are read in the loops of the columns and of the rows, where a call to a method for each would cost too much
  /// </summary>
  TGreedRenderState = class
  strict private
    FAssets: IGreedRenderAssets;
    FWallCache: TArray<TGreedRenderWall>;
    FFlatCache: TArray<PByte>;
    FFlatLoaded: TArray<Boolean>;
    FColorMapBytes: TBytes;
    FTransparencyBytes: TBytes;
    FBackdropBytes: TBytes;
    FViewTables: TGreedViewTables;
  public
    // ---- the size of the picture (SetViewSize) ----
    Tables: TGreedViewTables;
    WindowWidth: Integer;
    WindowHeight: Integer;
    CenterX: Integer;
    CenterY: Integer;
    FScale: Integer;
    IScale: Integer;
    ScrollMin: Integer;
    ScrollMax: Integer;
    MaxScroll: Integer;
    HFrac: Integer;
    AFrac: Integer;
    /// <summary>The picture: WindowWidth * WindowHeight pixels, the first row on top</summary>
    Buffer: PByte;
    // ---- the tables ----
    Tangents: PGreedFixedArray;
    Cosines: PGreedFixedArray;
    Sines: PGreedFixedArray;
    PixelAngle: PGreedFixedArray;
    PixelCosine: PGreedFixedArray;
    XSlope: PGreedFixedArray;
    YSlope: PGreedFixedArray;
    BackTangents: PGreedFixedArray;
    // ---- what is drawn with ----
    ColorMaps: PByte;
    NumColorMaps: Integer;
    ZColormap: array[0..GREED_RENDER_Z_COLORMAPS - 1] of PByte;
    /// <summary>translookup: the transparency tables, 256 bytes for each source color</summary>
    Transparency: PByte;
    Backdrop: PByte;
    WallTranslation: TArray<Integer>;
    FlatTranslation: TArray<Integer>;
    // ---- the level, as the planes were when the frame started ----
    WestWall, WestFlags, NorthWall, NorthFlags, FloorPic, CeilingPic, CeilingFlags: TGreedMapBytes;
    FloorHeight, CeilingHeight, FloorDef, FloorDefFlags, CeilingDef, CeilingDefFlags: TGreedMapBytes;
    MapLights, MapEffects, MapFlags: TGreedMapBytes;
    RealLight: array[0..GREED_RENDER_MAP_BYTES - 1] of Integer;
    // ---- the effects of the walls (SetupFrame) ----
    FrameOn: Integer;
    WallGlow, WallGlowIndex, WallRotate: Integer;
    WallFlicker1, WallFlicker2, WallFlicker3, WallFlicker4, WallCycle: Integer;
    FxTimeCount: Integer;
    // ---- the view ----
    ViewX, ViewY, ViewZ: Integer;
    ViewCos, ViewSin: Integer;
    XScale, YScale: Integer;
    ViewAngle, ViewFineAngle: Integer;
    ViewTileX, ViewTileY: Integer;
    // ---- the tile that is drawn ----
    TileX, TileY, MapSpot: Integer;
    MapLight: Integer;
    WallShadow: Integer;
    WallFlags: Integer;
    WallType: Integer;
    Side: Integer;
    XClipL, XClipH: Integer;
    DoorTile: Boolean;
    Vertex: array[0..3] of PGreedRenderVertex;
    P1, P2: PGreedRenderVertex;
    // ---- the transformed corners ----
    VertexList: array[0..GREED_MAX_VIS_VERTEXES] of TGreedRenderVertex;
    VertexCount: Integer;
    CornerVertex: array[0..GREED_MAP_TILES + 64] of PGreedRenderVertex;
    FrameValid, FrameCh, FrameFl: array[0..GREED_MAP_TILES + 64] of Integer;
    // ---- the tiles to draw ----
    Entries: array[0..GREED_MAX_ENTRIES] of TGreedRenderEntry;
    EntryCount: array[0..GREED_MAP_TILES - 1] of Integer;
    EntryMap: array[0..GREED_MAP_TILES - 1] of Integer;
    EntryNext: Integer;
    EntryCounter: Integer;
    // ---- the spans ----
    Spans: TArray<TGreedSpan>;
    SpansX: TArray<Integer>;
    SpanTags: TArray<TGreedSpanTag>;
    NumSpans: Integer;
    WallZ: array[0..GREED_RENDER_MAX_WIDTH - 1] of Integer;
    PendingDest: TArray<Integer>;
    PendingColormap: TArray<PByte>;
    PendingCount: TArray<Integer>;
    TransparentPosts: Integer;
    // ---- the registers of the routines that scale a post (sp_*) ----
    SpCount, SpFrac, SpFracStep, SpLoopValue: Integer;
    /// <summary>sp_dest: the offset in Buffer of the bottom pixel of the post</summary>
    SpDest: Integer;
    SpSource: PByte;
    SpColormap: PByte;
    // ---- the maps of the player that the walls mark (northmap and westmap of the player record) ----
    NorthMap: PByte;
    WestMap: PByte;
    constructor Create(const AAssets: IGreedRenderAssets);
    destructor Destroy; override;
    /// <summary>SetViewSize: the tables and the registers of a picture of that size</summary>
    procedure Configure(AWidth, AHeight: Integer);
    /// <summary>RF_SetLights: the color table of each distance (a table every ABlackZ / NumColorMaps units)</summary>
    procedure SetLights(ABlackZ: Integer);
    /// <summary>The wall of that number (after the translation); nil if it is not there</summary>
    function WallAt(AWall: Integer): PGreedRenderWall;
    /// <summary>The 64 x 64 pixels of a flat after the translation; nil if there is none</summary>
    function FlatAt(AFlat: Integer): PByte;
    /// <summary>The lump of a sprite picture; nil if there is none</summary>
    function SpritePicture(ALump: Integer): PByte;
    /// <summary>The color table of a light value (the distance in tiles plus the light of the tile), clamped</summary>
    function LightColormap(ALight: Integer): PByte; inline;
    /// <summary>
    ///   Puts a span that draws a post of a wall later (a transparent wall or a step): the registers SpDest,
    ///   SpColormap and SpCount are kept for it. False if the lists are full (the post is lost)
    /// </summary>
    function PostWallSpan(APoint, AX: Integer; AKind: TGreedSpanKind; APicture: PByte; AFrac, AFracStep,
      ALoop: Integer): Boolean;
    /// <summary>The next span of the list with its tag set; nil if the list is full</summary>
    function NewSpan(APoint: Cardinal; AX: Integer): PGreedSpan;
  end;

implementation

uses
  DelphiDoom.Greed.FixedMath;

{ TGreedRenderState }

constructor TGreedRenderState.Create(const AAssets: IGreedRenderAssets);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(AAssets) then
    raise EArgumentNilException.Create('AAssets');
  FAssets := AAssets;
  SetLength(Spans, GREED_MAX_SPANS + 1);
  SetLength(SpansX, GREED_MAX_SPANS + 1);
  SetLength(SpanTags, GREED_MAX_SPANS + 1);
  SetLength(PendingDest, GREED_MAX_PENDING + 1);
  SetLength(PendingColormap, GREED_MAX_PENDING + 1);
  SetLength(PendingCount, GREED_MAX_PENDING + 1);
  Tangents := TGreedFineTables.Tangents;
  Cosines := TGreedFineTables.Cosines;
  Sines := TGreedFineTables.Sines;
  FColorMapBytes := AAssets.ColorMaps;
  ColorMaps := PByte(FColorMapBytes);
  NumColorMaps := (Length(FColorMapBytes) - 512) div 256;
  if NumColorMaps < 1 then
    NumColorMaps := 1;
  FTransparencyBytes := AAssets.Transparency;
  Transparency := PByte(FTransparencyBytes);
  FBackdropBytes := AAssets.Backdrop;
  Backdrop := PByte(FBackdropBytes);
  SetLength(WallTranslation, AAssets.WallCount + 1);
  SetLength(FlatTranslation, AAssets.FlatCount + 1);
  for LIndex := 0 to AAssets.WallCount do
    WallTranslation[LIndex] := LIndex;
  for LIndex := 0 to AAssets.FlatCount do
    FlatTranslation[LIndex] := LIndex;
  SetLength(FWallCache, AAssets.WallCount + 1);
  SetLength(FFlatCache, AAssets.FlatCount + 1);
  SetLength(FFlatLoaded, AAssets.FlatCount + 1);
  SpColormap := ColorMaps;
  SetLights(GREED_MAX_Z);
end;

destructor TGreedRenderState.Destroy;
begin
  FreeAndNil(FViewTables);
  inherited Destroy;
end;

procedure TGreedRenderState.Configure(AWidth, AHeight: Integer);
begin
  if Assigned(Tables) and (Tables.Width = AWidth) and (Tables.Height = AHeight) then
  begin
    WindowWidth := AWidth;
    WindowHeight := AHeight;
    ScrollMax := WindowHeight + ScrollMin;
    Exit;
  end;
  FreeAndNil(FViewTables);
  FViewTables := TGreedViewTables.Create(AWidth, AHeight);
  Tables := FViewTables;
  WindowWidth := AWidth;
  WindowHeight := AHeight;
  CenterX := Tables.CenterX;
  CenterY := Tables.CenterY;
  FScale := Tables.Scale;
  IScale := Tables.InverseScale;
  MaxScroll := Tables.MaxScroll;
  HFrac := Tables.HFrac;
  AFrac := Tables.AFrac;
  PixelAngle := PGreedFixedArray(@Tables.PixelAngle[0]);
  PixelCosine := PGreedFixedArray(@Tables.PixelCosine[0]);
  XSlope := PGreedFixedArray(@Tables.XSlope[0]);
  YSlope := PGreedFixedArray(@Tables.YSlope[0]);
  BackTangents := PGreedFixedArray(@Tables.BackTangents[0]);
  ScrollMax := WindowHeight + ScrollMin;
end;

procedure TGreedRenderState.SetLights(ABlackZ: Integer);
var
  LIndex, LTable, LBlack: Integer;
begin
  // linear diminishing, the table is logarithmic
  LBlack := ABlackZ div GREED_FRACUNIT;
  for LIndex := 0 to GREED_MAX_Z div GREED_FRACUNIT do
  begin
    LTable := (NumColorMaps * LIndex) div LBlack;
    if LTable >= NumColorMaps then
      LTable := NumColorMaps - 1;
    ZColormap[LIndex] := @ColorMaps[LTable * 256];
  end;
end;

function TGreedRenderState.WallAt(AWall: Integer): PGreedRenderWall;
var
  LBytes: TBytes;
  LColumn: Integer;
begin
  Result := nil;
  if (AWall < 1) or (AWall >= Length(FWallCache)) then
    Exit;
  Result := @FWallCache[AWall];
  if not Result^.Loaded then
  begin
    Result^.Loaded := True;
    LBytes := FAssets.WallLump(AWall);
    if Length(LBytes) > 130 + 512 then
    begin
      Result^.Present := True;
      Result^.Data := PByte(LBytes);
      Result^.Height := PSmallInt(Result^.Data)^ * 4;
      for LColumn := 0 to 63 do
        Result^.Posts[LColumn] := Result^.Data + 65 * 2 + (Result^.Data^ * 4) * LColumn;
    end;
  end;
  if not Result^.Present then
    Result := nil;
end;

function TGreedRenderState.FlatAt(AFlat: Integer): PByte;
var
  LBytes: TBytes;
begin
  Result := nil;
  if (AFlat < 0) or (AFlat >= Length(FFlatCache)) then
    Exit;
  if not FFlatLoaded[AFlat] then
  begin
    FFlatLoaded[AFlat] := True;
    LBytes := FAssets.FlatLump(AFlat);
    if Length(LBytes) >= GREED_FLAT_BYTES + 512 then
      FFlatCache[AFlat] := PByte(LBytes);
  end;
  Result := FFlatCache[AFlat];
end;

function TGreedRenderState.LightColormap(ALight: Integer): PByte;
begin
  if ALight > GREED_MAX_Z_LIGHT then
    ALight := GREED_MAX_Z_LIGHT
  else if ALight < 0 then
    ALight := 0;
  Result := ZColormap[ALight];
end;

function TGreedRenderState.NewSpan(APoint: Cardinal; AX: Integer): PGreedSpan;
begin
  if NumSpans >= GREED_MAX_SPANS then
    Exit(nil);
  SpansX[NumSpans] := AX;
  SpanTags[NumSpans].Point := APoint;
  SpanTags[NumSpans].Span := NumSpans;
  Result := @Spans[NumSpans];
  Result^ := Default(TGreedSpan);
  Inc(NumSpans);
end;

function TGreedRenderState.PostWallSpan(APoint, AX: Integer; AKind: TGreedSpanKind; APicture: PByte; AFrac,
  AFracStep, ALoop: Integer): Boolean;
var
  LSpan: PGreedSpan;
begin
  Result := False;
  if (TransparentPosts >= GREED_MAX_PENDING) or (NumSpans >= GREED_MAX_SPANS) then
    Exit;
  LSpan := NewSpan(APoint, AX);
  LSpan^.Kind := AKind;
  LSpan^.Picture := APicture;
  LSpan^.Y := AFrac;
  LSpan^.YH := AFracStep;
  LSpan^.X2 := TransparentPosts;
  LSpan^.Light := ALoop;
  PendingDest[TransparentPosts] := SpDest;
  PendingColormap[TransparentPosts] := SpColormap;
  PendingCount[TransparentPosts] := SpCount;
  Inc(TransparentPosts);
  Result := True;
end;

function TGreedRenderState.SpritePicture(ALump: Integer): PByte;
var
  LBytes: TBytes;
begin
  LBytes := FAssets.SpriteLump(ALump);
  if Length(LBytes) > 4 + 512 then
    Result := PByte(LBytes)
  else
    Result := nil;
end;

end.

