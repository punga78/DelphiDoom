{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the renderer of a picture of the game            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): RF_RenderView of            }
{  r_public.pas and the flow through the tiles of r_render.pas (Raven 3D)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Render.FrameRenderer;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Frame.Intf, DelphiDoom.Greed.Random,
  DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.Render.State, DelphiDoom.Greed.Render.Assets.Intf,
  DelphiDoom.Greed.Render.WallRenderer, DelphiDoom.Greed.Render.PlaneRenderer,
  DelphiDoom.Greed.Render.ContentRenderer, DelphiDoom.Greed.Render.SpanDrawer,
  DelphiDoom.Greed.Render.SpriteInterpolator;

type
  /// <summary>
  ///   The first person view of the game (RF_RenderView): from the tile of the player it flows through the tiles that
  ///   can be seen, putting walls, steps, floors, ceilings, doors and sprites in a list of spans, and then draws the
  ///   list from the farthest to the nearest into the picture of the frame. It draws 8 bit pixels, the indexes of the
  ///   palette of the game. Each frame reads the level from the world and the sprites from the pool; the object keeps
  ///   what the original keeps in its globals (the cache of transformed corners, the effects of the walls)
  /// </summary>
  TGreedFrameRenderer = class(TInterfacedObject, IGreedFrameRenderer)
  strict private
    FState: TGreedRenderState;
    FWalls: TGreedWallRenderer;
    FPlanes: TGreedPlaneRenderer;
    FContent: TGreedContentRenderer;
    FDrawer: TGreedSpanDrawer;
    FInterpolator: TGreedSpriteInterpolator;
    FClock: IGreedRenderClock;
    FRandom: IGreedRandom;
    FActionHook: IGreedRenderActionHook;
    procedure CheckActionFlag;
    procedure CopyLevel(const AWorld: IGreedWorld);
    function TransformVertex(ATileX, ATileY: Integer): PGreedRenderVertex;
    function ClipEdge: Boolean;
    procedure RenderTileWalls(AEntry: PGreedRenderEntry);
    procedure SetupFrame;
    procedure FlowView;
  public
    constructor Create(const AAssets: IGreedRenderAssets; ASprites: TGreedLinkedPool<TGreedSprite>;
      const AClock: IGreedRenderClock; const ARandom: IGreedRandom);
    destructor Destroy; override;
    /// <summary>
    ///   Draws the view of the player (its position, height and angle) into the frame, which is any size up to
    ///   640 x 400. The walls mark the maps of the player (north map and west map of the record). The vertical look
    ///   of the player (ScrollMin) moves the view up and down
    /// </summary>
    procedure Render(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; var AFrame: TGreedFrame);
    /// <summary>
    ///   RF_RenderView(x, y, z, angle): the view from a place that is not the one of the record of the player (the
    ///   game adds the bobbing of the head to z). The maps of the walls seen and the scroll are the ones of APlayer
    /// </summary>
    procedure RenderView(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; AX, AY, AZ: TGreedFixed;
      AAngle: Integer; var AFrame: TGreedFrame);
    /// <summary>
    ///   Called where the original calls RF_CheckActionFlag; nil (the default) calls nothing. What it does can change
    ///   the level: the planes are read again before the view flows through the tiles
    /// </summary>
    property ActionHook: IGreedRenderActionHook read FActionHook write FActionHook;
    /// <summary>What the game changes between pictures: the lights added by the sprites, the animation tables</summary>
    property State: TGreedRenderState read FState;
    property Planes: TGreedPlaneRenderer read FPlanes;
    property Interpolator: TGreedSpriteInterpolator read FInterpolator;
  end;

implementation

uses
  DelphiDoom.Greed.FixedMath, DelphiDoom.MathCore.FixedMath, DelphiDoom.Greed.TrigTables,
  DelphiDoom.Greed.Render.Tables;

type
  FM = TGreedFixedMath;

const
  ADJACENT_X: array[0..3] of Integer = (0, 1, 0, -1);
  ADJACENT_Y: array[0..3] of Integer = (-1, 0, 1, 0);

{ TGreedFrameRenderer }

constructor TGreedFrameRenderer.Create(const AAssets: IGreedRenderAssets; ASprites: TGreedLinkedPool<TGreedSprite>;
  const AClock: IGreedRenderClock; const ARandom: IGreedRandom);
begin
  inherited Create;
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  FClock := AClock;
  FRandom := ARandom;
  FState := TGreedRenderState.Create(AAssets);
  FWalls := TGreedWallRenderer.Create(FState);
  FPlanes := TGreedPlaneRenderer.Create(FState);
  FContent := TGreedContentRenderer.Create(FState, ASprites, AClock);
  FDrawer := TGreedSpanDrawer.Create(FState);
  FInterpolator := TGreedSpriteInterpolator.Create(ASprites, AClock);
end;

destructor TGreedFrameRenderer.Destroy;
begin
  FreeAndNil(FInterpolator);
  FreeAndNil(FDrawer);
  FreeAndNil(FContent);
  FreeAndNil(FPlanes);
  FreeAndNil(FWalls);
  FreeAndNil(FState);
  inherited Destroy;
end;

procedure TGreedFrameRenderer.CopyLevel(const AWorld: IGreedWorld);
var
  S: TGreedRenderState;
begin
  S := FState;
  AWorld.CopyPlane(gpNorthWall, @S.NorthWall[0]);
  AWorld.CopyPlane(gpNorthFlags, @S.NorthFlags[0]);
  AWorld.CopyPlane(gpWestWall, @S.WestWall[0]);
  AWorld.CopyPlane(gpWestFlags, @S.WestFlags[0]);
  AWorld.CopyPlane(gpFloorPic, @S.FloorPic[0]);
  AWorld.CopyPlane(gpCeilingPic, @S.CeilingPic[0]);
  AWorld.CopyPlane(gpCeilingFlags, @S.CeilingFlags[0]);
  AWorld.CopyPlane(gpFloorHeight, @S.FloorHeight[0]);
  AWorld.CopyPlane(gpCeilingHeight, @S.CeilingHeight[0]);
  AWorld.CopyPlane(gpFloorDef, @S.FloorDef[0]);
  AWorld.CopyPlane(gpFloorDefFlags, @S.FloorDefFlags[0]);
  AWorld.CopyPlane(gpCeilingDef, @S.CeilingDef[0]);
  AWorld.CopyPlane(gpCeilingDefFlags, @S.CeilingDefFlags[0]);
  AWorld.CopyPlane(gpMapLights, @S.MapLights[0]);
  AWorld.CopyPlane(gpMapEffects, @S.MapEffects[0]);
  AWorld.CopyMapFlags(@S.MapFlags[0]);
end;

// Returns the vertex for a given coordinate: tx, tz are the transformed coordinates, and px, the heights are valid if
// tz >= MINZ. A corner is used by up to four tiles and is calculated once for the same heights
function TGreedFrameRenderer.TransformVertex(ATileX, ATileY: Integer): PGreedRenderVertex;
var
  S: TGreedRenderState;
  LTTRX, LTTRY: Integer;
  LScale: Double;
  LMapSpot2, LFloor, LCeiling: Integer;
begin
  S := FState;
  LMapSpot2 := ATileY * GREED_MAP_SIZE + ATileX;
  if S.MapSpot <> LMapSpot2 then
  begin
    if S.MapFlags[S.MapSpot] and GREED_FL_FLOOR <> 0 then
      LFloor := (S.FloorHeight[LMapSpot2] * GREED_FRACUNIT) - S.ViewZ
    else
      LFloor := (S.FloorHeight[S.MapSpot] * GREED_FRACUNIT) - S.ViewZ;
    if S.MapFlags[S.MapSpot] and GREED_FL_CEILING <> 0 then
      LCeiling := (S.CeilingHeight[LMapSpot2] * GREED_FRACUNIT) - S.ViewZ
    else
      LCeiling := (S.CeilingHeight[S.MapSpot] * GREED_FRACUNIT) - S.ViewZ;
  end
  else
  begin
    LFloor := (S.FloorHeight[LMapSpot2] * GREED_FRACUNIT) - S.ViewZ;
    LCeiling := (S.CeilingHeight[LMapSpot2] * GREED_FRACUNIT) - S.ViewZ;
  end;
  if (S.FrameValid[LMapSpot2] = S.FrameOn) and (S.FrameFl[LMapSpot2] = LFloor) and (S.FrameCh[LMapSpot2] = LCeiling) then
    Exit(S.CornerVertex[LMapSpot2]);
  if S.VertexCount >= GREED_MAX_VIS_VERTEXES then
    S.VertexCount := GREED_MAX_VIS_VERTEXES - 1; // the original writes past the list
  Result := @S.VertexList[S.VertexCount];
  Inc(S.VertexCount);
  // the pixels of a corner behind the view are not set (the record keeps what the last frame left in it, as in the original)
  Result^.FloorHeight := LFloor;
  Result^.CeilingHeight := LCeiling;
  LTTRX := (FM.ShiftLeft(ATileX, GREED_FRACBITS + 6)) - S.ViewX;
  LTTRY := (FM.ShiftLeft(ATileY, GREED_FRACBITS + 6)) - S.ViewY;
  Result^.TX := FM.Mul(LTTRX, S.ViewSin) + FM.Mul(LTTRY, S.ViewCos);
  Result^.TZ := FM.Mul(LTTRX, S.ViewCos) - FM.Mul(LTTRY, S.ViewSin);
  if Result^.TZ >= GREED_MIN_Z then
  begin
    LScale := S.FScale / Result^.TZ;
    Result^.PX := S.CenterX + GreedRint((Result^.TX / GREED_FRACUNIT) * LScale);
    Result^.FloorY := S.CenterY - GreedRint((Result^.FloorHeight / GREED_FRACUNIT) * LScale);
    Result^.CeilingY := S.CenterY - GreedRint((Result^.CeilingHeight / GREED_FRACUNIT) * LScale);
  end;
  S.FrameValid[LMapSpot2] := S.FrameOn;
  S.CornerVertex[LMapSpot2] := Result;
  S.FrameFl[LMapSpot2] := LFloor;
  S.FrameCh[LMapSpot2] := LCeiling;
end;

// Sets p1.px and p2.px correctly for Z values below MINZ; false if the entire edge is too close or too far
function TGreedFrameRenderer.ClipEdge: Boolean;
var
  S: TGreedRenderState;
  LLeftFrac, LRightFrac, LClipZ, LDX, LDZ: Integer;
begin
  S := FState;
  LLeftFrac := 0;
  if (S.P1^.TZ > GREED_MAX_Z) and (S.P2^.TZ > GREED_MAX_Z) then
    Exit(False); // entire face is too far away
  if (S.P1^.TZ <= 0) and (S.P2^.TZ <= 0) then
    Exit(False); // totally behind the projection plane
  if (S.P1^.TZ < GREED_MIN_Z) or (S.P2^.TZ < GREED_MIN_Z) then
  begin
    LDX := S.P2^.TX - S.P1^.TX;
    LDZ := S.P2^.TZ - S.P1^.TZ;
    if S.P1^.TZ < GREED_MIN_Z then
    begin
      if Abs(LDX + LDZ) < 1024 then
        Exit(False);
      LLeftFrac := FM.Divide(-S.P1^.TX - S.P1^.TZ, LDX + LDZ);
    end;
    if S.P2^.TZ < GREED_MIN_Z then
    begin
      if Abs(LDZ - LDX) < 1024 then
        Exit(False);
      LRightFrac := FM.Divide(S.P1^.TX - S.P1^.TZ, LDZ - LDX);
      if (S.P1^.TZ < GREED_MIN_Z) and (LRightFrac < LLeftFrac) then
        Exit(False); // back face
      LClipZ := S.P1^.TZ + FM.Mul(LDZ, LRightFrac);
      if LClipZ < 0 then
        Exit(False);
      S.P2^.PX := S.WindowWidth;
    end;
    if S.P1^.TZ < GREED_MIN_Z then
    begin
      LClipZ := S.P1^.TZ + FM.Mul(LDZ, LLeftFrac);
      if LClipZ < 0 then
        Exit(False);
      S.P1^.PX := 0;
    end;
  end;
  Result := S.P1^.PX <> S.P2^.PX;
end;

procedure TGreedFrameRenderer.RenderTileWalls(AEntry: PGreedRenderEntry);
var
  S: TGreedRenderState;
  LXL, LXH, LTX, LTY, LX1, LX2: Integer;
begin
  S := FState;
  S.TileX := AEntry^.TileX;
  S.TileY := AEntry^.TileY;
  S.XClipL := AEntry^.XMin;
  S.XClipH := AEntry^.XMax;
  S.MapSpot := S.TileY * GREED_MAP_SIZE + S.TileX;
  S.MapLight := (S.MapLights[S.MapSpot] * 8) + S.RealLight[S.MapSpot];
  S.WallShadow := S.MapEffects[S.MapSpot];
  // validate or transform the four corner vertexes
  S.Vertex[0] := TransformVertex(S.TileX, S.TileY);
  S.Vertex[1] := TransformVertex(S.TileX + 1, S.TileY);
  S.Vertex[2] := TransformVertex(S.TileX + 1, S.TileY + 1);
  S.Vertex[3] := TransformVertex(S.TileX, S.TileY + 1);
  // handle a door if present
  if S.MapFlags[S.MapSpot] and GREED_FL_DOOR <> 0 then
  begin
    S.DoorTile := True;
    FContent.RenderDoor;
  end
  else
    S.DoorTile := False;
  // draw or flow through the walls
  S.Side := -1;
  while S.Side < 3 do
  begin
    Inc(S.Side);
    S.P1 := S.Vertex[S.Side];
    S.P2 := S.Vertex[(S.Side + 1) and 3];
    if not ClipEdge then
      Continue;
    if S.P1^.PX >= S.P2^.PX then
      Continue;
    case S.Side of
      0: // north
        begin
          S.WallType := S.NorthWall[S.MapSpot];
          S.WallFlags := S.NorthFlags[S.MapSpot];
        end;
      1: // east
        begin
          S.WallType := S.WestWall[S.MapSpot + 1];
          S.WallFlags := S.WestFlags[S.MapSpot + 1];
        end;
      2: // south
        begin
          S.WallType := S.NorthWall[S.MapSpot + GREED_MAP_SIZE];
          S.WallFlags := S.NorthFlags[S.MapSpot + GREED_MAP_SIZE];
        end;
      3: // west
        begin
          S.WallType := S.WestWall[S.MapSpot];
          S.WallFlags := S.WestFlags[S.MapSpot];
        end;
    end;
    if S.P1^.PX < S.XClipL then
      LX1 := S.XClipL
    else
      LX1 := S.P1^.PX;
    if S.P2^.PX - 1 > S.XClipH then
      LX2 := S.XClipH
    else
      LX2 := S.P2^.PX - 1;
    if LX1 <= LX2 then
    begin // totally clipped off side
      if S.WallType <> 0 then
        FWalls.DrawWall(LX1, LX2);
      FWalls.DrawSteps(LX1, LX2);
    end;
    if (S.WallType = 0) or (S.WallFlags and GREED_WALL_TRANSPARENT <> 0) then
    begin
      // restrict outward flow by the door, if present, and by the clipping window
      LXL := S.P1^.PX;
      LXH := S.P2^.PX - 1;
      if LXL < S.XClipL then
        LXL := S.XClipL;
      if LXH > S.XClipH then
        LXH := S.XClipH;
      // flow into the adjacent tile if there is at least a one pixel
      if LXH >= LXL then
      begin
        LTX := S.TileX + ADJACENT_X[S.Side];
        LTY := S.TileY + ADJACENT_Y[S.Side];
        if (LTX < 0) or (LTX >= GREED_MAP_SIZE - 1) or (LTY < 0) or (LTY >= GREED_MAP_SIZE - 1) then
          Continue;
        if S.EntryNext >= GREED_MAX_ENTRIES then
          Continue; // the original writes past the list
        S.Entries[S.EntryNext].TileX := LTX;
        S.Entries[S.EntryNext].TileY := LTY;
        S.Entries[S.EntryNext].XMin := LXL;
        S.Entries[S.EntryNext].XMax := LXH;
        S.Entries[S.EntryNext].MapSpot := (LTY * 64) + LTX;
        Inc(S.EntryCounter);
        S.Entries[S.EntryNext].Counter := S.EntryCounter;
        S.EntryCount[S.Entries[S.EntryNext].MapSpot] := S.EntryCounter;
        Inc(S.EntryNext);
      end;
    end;
  end;
end;

procedure TGreedFrameRenderer.SetupFrame;
var
  S: TGreedRenderState;
  LIndex: Integer;
begin
  S := FState;
  // clears the wallz array, so posts that fade out into the distance won't block sprites
  for LIndex := 0 to S.WindowWidth - 1 do
    S.WallZ[LIndex] := GREED_MAX_Z + 1;

  // reset span counters
  S.NumSpans := 0;
  S.TransparentPosts := 0;
  Inc(S.FrameOn);
  S.VertexCount := 0;

  // special effects
  if FContent.RenderTime > S.FxTimeCount then
  begin
    Inc(S.WallGlowIndex);
    if S.WallGlowIndex = 32 then
      S.WallGlowIndex := 0;
    if S.WallGlowIndex < 16 then
      S.WallGlow := S.WallGlowIndex * 2
    else
      S.WallGlow := (32 - S.WallGlowIndex) * 2;
    if S.WallRotate = 63 then
      S.WallRotate := 0
    else
      Inc(S.WallRotate);
    S.WallFlicker1 := FRandom.Next and 63;
    S.WallFlicker2 := FRandom.Next and 63;
    S.WallFlicker3 := FRandom.Next and 63;
    if S.FrameOn and 1 <> 0 then
      S.WallFlicker4 := (FRandom.Next mod 63) - 32;
    Inc(S.WallCycle);
    S.WallCycle := S.WallCycle and 3;
    S.FxTimeCount := FClock.GetTimeCount + 5;
  end;

  S.ViewTileX := S.ViewX div GREED_FRACTILEUNIT;
  S.ViewTileY := S.ViewY div GREED_FRACTILEUNIT;
  S.ViewFineAngle := S.ViewAngle * GREED_FINE_UNIT;
  S.ViewCos := TGreedTrigTables.Cosine(S.ViewAngle);
  S.ViewSin := TGreedTrigTables.Sine(S.ViewAngle);
  S.XScale := FM.Divide(S.ViewSin, S.FScale);
  S.YScale := FM.Divide(S.ViewCos, S.FScale);
end;

procedure TGreedFrameRenderer.FlowView;
var
  S: TGreedRenderState;
  LProcess, LNext: Integer;
  LEntry: PGreedRenderEntry;
begin
  S := FState;
  S.Entries[0].TileX := S.ViewTileX;
  S.Entries[0].TileY := S.ViewTileY;
  S.Entries[0].MapSpot := (S.ViewTileY * 64) + S.ViewTileX;
  S.Entries[0].XMin := 0;
  S.Entries[0].XMax := S.WindowWidth - 1;
  S.EntryNext := 1;
  FillChar(S.EntryCount, SizeOf(S.EntryCount), 0);
  S.EntryCounter := 1;
  LProcess := 0;
  while LProcess < S.EntryNext do
  begin
    LEntry := @S.Entries[LProcess];
    if LEntry^.MapSpot = -1 then // entry has been merged
    begin
      Inc(LProcess);
      Continue;
    end;

    // check for mergeable entries
    if S.EntryCount[LEntry^.MapSpot] > LEntry^.Counter then // mergeable tile
    begin
      LNext := LProcess + 1;
      while LNext < S.EntryNext do // scan for mergeable entries
      begin
        if S.Entries[LNext].MapSpot = LEntry^.MapSpot then
        begin
          if S.Entries[LNext].XMin = LEntry^.XMax + 1 then
            LEntry^.XMax := S.Entries[LNext].XMax
          else if S.Entries[LNext].XMax = LEntry^.XMin - 1 then
            LEntry^.XMin := S.Entries[LNext].XMin;
          // a bad combination is an error in the original; here the entry is left alone
          S.EntryCount[S.Entries[LNext].MapSpot] := 0;
          S.Entries[LNext].MapSpot := -1;
        end;
        Inc(LNext);
      end;
    end;

    // check for a duplicate entry
    if S.EntryMap[LEntry^.MapSpot] <> S.FrameOn then
    begin
      S.EntryMap[LEntry^.MapSpot] := S.FrameOn;
      RenderTileWalls(LEntry);
      FPlanes.RenderTileEnds;
    end;
    Inc(LProcess);
  end;
end;

procedure TGreedFrameRenderer.CheckActionFlag;
begin
  if Assigned(FActionHook) then
    FActionHook.CheckActionFlag;
end;

procedure TGreedFrameRenderer.Render(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord;
  var AFrame: TGreedFrame);
begin
  RenderView(AWorld, APlayer, APlayer.X, APlayer.Y, APlayer.Z, APlayer.Angle, AFrame);
end;

procedure TGreedFrameRenderer.RenderView(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; AX, AY,
  AZ: TGreedFixed; AAngle: Integer; var AFrame: TGreedFrame);
var
  S: TGreedRenderState;
begin
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  if Length(AFrame.Pixels) < AFrame.Width * AFrame.Height then
    raise EGreedRenderException.CreateFmt(SGreedRenderSize, [AFrame.Width, AFrame.Height, GREED_RENDER_MAX_WIDTH,
      GREED_RENDER_MAX_HEIGHT]);
  S := FState;
  S.ScrollMin := APlayer.ScrollMin;
  S.Configure(AFrame.Width, AFrame.Height);
  S.Buffer := PByte(AFrame.Pixels);
  FillChar(S.Buffer^, S.WindowWidth * S.WindowHeight, 0);
  CopyLevel(AWorld);
  S.NorthMap := @APlayer.NorthMap[0];
  S.WestMap := @APlayer.WestMap[0];
  FContent.World := AWorld;
  FContent.RenderTime := FClock.GetTimeCount;
  S.ViewX := AX;
  S.ViewY := AY;
  S.ViewZ := AZ;
  S.ViewAngle := AAngle and GREED_ANGLES;
  CheckActionFlag;
  SetupFrame;
  if Assigned(FActionHook) then
  begin
    FActionHook.CheckActionFlag;
    // the original reads the planes of the map where they are: what the hooks changed is seen by the flow
    CopyLevel(AWorld);
  end;
  // the tile of the player has to be inside the map
  if S.ViewTileX < 0 then
    S.ViewTileX := 0
  else if S.ViewTileX > GREED_MAP_SIZE - 1 then
    S.ViewTileX := GREED_MAP_SIZE - 1;
  if S.ViewTileY < 0 then
    S.ViewTileY := 0
  else if S.ViewTileY > GREED_MAP_SIZE - 1 then
    S.ViewTileY := GREED_MAP_SIZE - 1;
  FlowView;
  CheckActionFlag;
  FInterpolator.Interpolate(AWorld);
  FContent.RenderSprites;
  FInterpolator.Restore;
  FDrawer.DrawSpans;
  CheckActionFlag;
end;

end.
