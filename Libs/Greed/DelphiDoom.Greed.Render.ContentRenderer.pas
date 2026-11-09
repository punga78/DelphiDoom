{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the doors and the sprites of the renderer        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): r_conten.pas                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Render.ContentRenderer;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.Render.State;

type
  /// <summary>
  ///   Puts the doors of the tile that the state holds and all the sprites of the level in the list of spans, as
  ///   RenderDoor and RenderSprites do. The animation of a sprite advances here, as in the original (a picture that
  ///   was drawn is the one that moves on), and a sprite that only exists to animate and die is removed from the pool
  /// </summary>
  TGreedContentRenderer = class
  strict private
    FState: TGreedRenderState;
    FWorld: IGreedWorld;
    FSprites: TGreedLinkedPool<TGreedSprite>;
    FClock: IGreedRenderClock;
    /// <summary>rtimecount: the time of the game when the frame started</summary>
    FRenderTime: Integer;
    function TransformPoint(AX, AY: Integer): PGreedRenderVertex;
    function ClipDoor: Boolean;
    function SetupDoorFace(const ADoor: TGreedDoor; AOffset: Integer; out ATextureAdjust, ABaseAngle,
      ADistance: Integer): Boolean;
    procedure SetupDoorEdge(const ADoor: TGreedDoor; out ATextureAdjust, ABaseAngle, ADistance: Integer);
    function PostDoorColumns(const AWall: PGreedRenderWall; ABaseAngle, ADistance, ATextureAdjust, ACeiling,
      AFloor: Integer; AKind: TGreedSpanKind; AStopWhenFar: Boolean): Boolean;
    function SwapAndClip: Boolean;
    function HasColumns: Boolean;
    function RenderSprite(AIndex: Integer): Integer;
  public
    constructor Create(AState: TGreedRenderState; ASprites: TGreedLinkedPool<TGreedSprite>;
      const AClock: IGreedRenderClock);
    /// <summary>RenderDoor: the doors of the current tile (the three parts of each door)</summary>
    procedure RenderDoor;
    /// <summary>RenderSprites</summary>
    procedure RenderSprites;
    property RenderTime: Integer read FRenderTime write FRenderTime;
    /// <summary>The level whose doors are drawn: set before each frame</summary>
    property World: IGreedWorld read FWorld write FWorld;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.FixedMath;

type
  FM = TGreedFixedMath;

const
  TILE_SIZE_UNITS = 64 * GREED_FRACUNIT;

{ TGreedContentRenderer }

constructor TGreedContentRenderer.Create(AState: TGreedRenderState; ASprites: TGreedLinkedPool<TGreedSprite>;
  const AClock: IGreedRenderClock);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(ASprites) then
    raise EArgumentNilException.Create('ASprites');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FState := AState;
  FSprites := ASprites;
  FClock := AClock;
end;

// returns the vertex of a transformed point
function TGreedContentRenderer.TransformPoint(AX, AY: Integer): PGreedRenderVertex;
var
  S: TGreedRenderState;
  LTTRX, LTTRY, LScale: Integer;
  LValue: Int64;
begin
  S := FState;
  if S.VertexCount >= GREED_MAX_VIS_VERTEXES then
    S.VertexCount := GREED_MAX_VIS_VERTEXES - 1; // the original writes past the list
  Result := @S.VertexList[S.VertexCount];
  Inc(S.VertexCount);
  // the pixels of a corner behind the view are not set (the record keeps what the last frame left in it, as in the original)
  LTTRX := AX - S.ViewX;
  LTTRY := AY - S.ViewY;
  Result^.TX := FM.Mul(LTTRY, S.ViewCos) + FM.Mul(LTTRX, S.ViewSin);
  Result^.TZ := FM.Mul(LTTRX, S.ViewCos) - FM.Mul(LTTRY, S.ViewSin);
  if Result^.TZ >= GREED_MIN_Z then
  begin
    LScale := FM.Divide(S.FScale, Result^.TZ);
    LValue := FM.Mul64(Result^.TX, LScale);
    LValue := LValue div GREED_FRACUNIT;
    Result^.PX := S.CenterX + LValue;
  end;
end;

// sets p1.px and p2.px correctly for Z values below MINZ; false if the entire door is too close or too far
function TGreedContentRenderer.ClipDoor: Boolean;
var
  S: TGreedRenderState;
  LFrac, LClip: Integer;
begin
  S := FState;
  if ((S.P1^.TZ > GREED_MAX_Z) and (S.P2^.TZ > GREED_MAX_Z)) or ((S.P1^.TZ <= 0) and (S.P2^.TZ <= 0)) then
    Exit(False);
  if S.P1^.TZ < GREED_MIN_Z then
  begin
    if S.P1^.TZ = 0 then
      LClip := S.P1^.TX
    else
    begin
      if S.P2^.TZ = S.P1^.TZ then
        Exit(False);
      LFrac := FM.Divide(S.P2^.TZ, S.P2^.TZ - S.P1^.TZ);
      LClip := S.P2^.TX + FM.Mul(S.P1^.TX - S.P2^.TX, LFrac);
    end;
    if LClip < 0 then
      S.P1^.PX := 0
    else
      S.P1^.PX := S.WindowWidth;
  end
  else if S.P2^.TZ < GREED_MIN_Z then
  begin
    if S.P2^.TZ = 0 then
      LClip := S.P2^.TX
    else
    begin
      if S.P2^.TZ = S.P1^.TZ then
        Exit(False);
      LFrac := FM.Divide(S.P1^.TZ, S.P1^.TZ - S.P2^.TZ);
      LClip := S.P1^.TX + FM.Mul(S.P2^.TX - S.P1^.TX, LFrac);
    end;
    if LClip < 0 then
      S.P2^.PX := 0
    else
      S.P2^.PX := S.WindowWidth;
  end;
  Result := True;
end;

// the faces of a door at AOffset units from the start of the tile (27 and 37): the points, the angle and the distance
function TGreedContentRenderer.SetupDoorFace(const ADoor: TGreedDoor; AOffset: Integer; out ATextureAdjust,
  ABaseAngle, ADistance: Integer): Boolean;
var
  S: TGreedRenderState;
  LTX, LTY, LPosition: Integer;
begin
  S := FState;
  Result := True;
  LTX := S.TileX * TILE_SIZE_UNITS;
  LTY := S.TileY * TILE_SIZE_UNITS;
  LPosition := ADoor.Position;
  case ADoor.Orientation of
    gdoHorizontal:
      begin
        LTY := LTY + GREED_FRACUNIT * AOffset;
        S.P1 := TransformPoint(LTX + LPosition, LTY);
        S.P2 := TransformPoint(LTX, LTY);
        ATextureAdjust := S.ViewX + GREED_TILE_GLOBAL - (LTX + LPosition);
        ABaseAngle := GREED_TAN_ANGLES * 2;
        ADistance := S.ViewY - LTY;
        if S.NorthMap[S.MapSpot] = 0 then
          S.NorthMap[S.MapSpot] := GREED_DOOR_COLOR;
      end;
    gdoVertical:
      begin
        LTX := LTX + GREED_FRACUNIT * AOffset;
        S.P1 := TransformPoint(LTX, LTY + LPosition);
        S.P2 := TransformPoint(LTX, LTY);
        ATextureAdjust := S.ViewY + GREED_TILE_GLOBAL - (LTY + LPosition);
        ABaseAngle := GREED_TAN_ANGLES;
        ADistance := LTX - S.ViewX;
        if S.WestMap[S.MapSpot] = 0 then
          S.WestMap[S.MapSpot] := GREED_DOOR_COLOR;
      end;
    gdoHorizontal2:
      begin
        LTX := LTX + GREED_TILE_GLOBAL;
        LTY := LTY + GREED_FRACUNIT * AOffset;
        S.P1 := TransformPoint(LTX - LPosition, LTY);
        S.P2 := TransformPoint(LTX, LTY);
        ATextureAdjust := S.ViewX + GREED_TILE_GLOBAL - (LTX - LPosition);
        ABaseAngle := GREED_TAN_ANGLES * 2;
        ADistance := S.ViewY - LTY;
        if S.NorthMap[S.MapSpot] = 0 then
          S.NorthMap[S.MapSpot] := GREED_DOOR_COLOR;
      end;
    gdoVertical2:
      begin
        LTX := LTX + GREED_FRACUNIT * AOffset;
        LTY := LTY + GREED_TILE_GLOBAL;
        S.P1 := TransformPoint(LTX, LTY - LPosition);
        S.P2 := TransformPoint(LTX, LTY);
        ATextureAdjust := S.ViewY + GREED_TILE_GLOBAL - (LTY - LPosition);
        ABaseAngle := GREED_TAN_ANGLES;
        ADistance := LTX - S.ViewX;
        if S.WestMap[S.MapSpot] = 0 then
          S.WestMap[S.MapSpot] := GREED_DOOR_COLOR;
      end;
  else
    Result := False;
  end;
end;

// the third part of a door: the narrow edge, 5 units on each side of its middle
procedure TGreedContentRenderer.SetupDoorEdge(const ADoor: TGreedDoor; out ATextureAdjust, ABaseAngle,
  ADistance: Integer);
var
  S: TGreedRenderState;
  LTX, LTY, LPosition: Integer;
begin
  S := FState;
  LTX := S.TileX * TILE_SIZE_UNITS;
  LTY := S.TileY * TILE_SIZE_UNITS;
  LPosition := ADoor.Position;
  ATextureAdjust := 0;
  ABaseAngle := 0;
  ADistance := 0;
  case ADoor.Orientation of
    gdoHorizontal:
      begin
        LTY := LTY + GREED_FRACUNIT * 32;
        LTX := LTX + LPosition;
        S.P1 := TransformPoint(LTX, LTY + (5 * GREED_FRACUNIT));
        S.P2 := TransformPoint(LTX, LTY - (5 * GREED_FRACUNIT));
        ATextureAdjust := S.ViewY + GREED_TILE_GLOBAL - LTY;
        ABaseAngle := GREED_TAN_ANGLES;
        ADistance := LTX - S.ViewX;
      end;
    gdoVertical:
      begin
        LTX := LTX + GREED_FRACUNIT * 32;
        LTY := LTY + LPosition;
        S.P1 := TransformPoint(LTX + (5 * GREED_FRACUNIT), LTY);
        S.P2 := TransformPoint(LTX - (5 * GREED_FRACUNIT), LTY);
        ATextureAdjust := S.ViewX + GREED_TILE_GLOBAL - LTX;
        ABaseAngle := GREED_TAN_ANGLES * 2;
        ADistance := S.ViewY - LTY;
      end;
    gdoHorizontal2:
      begin
        LTY := LTY + GREED_FRACUNIT * 32;
        LTX := LTX + GREED_FRACUNIT * 64 - LPosition;
        S.P1 := TransformPoint(LTX, LTY + (5 * GREED_FRACUNIT));
        S.P2 := TransformPoint(LTX, LTY - (5 * GREED_FRACUNIT));
        ATextureAdjust := S.ViewY + GREED_TILE_GLOBAL - LTY;
        ABaseAngle := GREED_TAN_ANGLES;
        ADistance := LTX - S.ViewX;
      end;
    gdoVertical2:
      begin
        LTX := LTX + GREED_FRACUNIT * 32;
        LTY := LTY + GREED_FRACUNIT * 64 - LPosition;
        S.P1 := TransformPoint(LTX + (5 * GREED_FRACUNIT), LTY);
        S.P2 := TransformPoint(LTX - (5 * GREED_FRACUNIT), LTY);
        ATextureAdjust := S.ViewX + GREED_TILE_GLOBAL - LTX;
        ABaseAngle := GREED_TAN_ANGLES * 2;
        ADistance := S.ViewY - LTY;
      end;
  else
    S.P1 := TransformPoint(0, 0);
    S.P2 := S.P1;
  end;
end;

// the swap of the two points, the clipping and the range of columns; False if nothing of the door is in view
function TGreedContentRenderer.SwapAndClip: Boolean;
var
  S: TGreedRenderState;
  LPoint: PGreedRenderVertex;
begin
  S := FState;
  if S.P1^.PX > S.P2^.PX then
  begin
    LPoint := S.P1;
    S.P1 := S.P2;
    S.P2 := LPoint;
  end;
  Result := ClipDoor;
end;

// whether the columns of the door are inside the clipping window of the tile
function TGreedContentRenderer.HasColumns: Boolean;
var
  LX1, LX2: Integer;
begin
  LX1 := FState.P1^.PX;
  LX2 := FState.P2^.PX;
  if LX1 < FState.XClipL then
    LX1 := FState.XClipL;
  if LX2 > FState.XClipH + 1 then
    LX2 := FState.XClipH + 1;
  Result := LX1 < LX2;
end;

// the posts of a face of a door: one span for each column, from the post the ray hits
function TGreedContentRenderer.PostDoorColumns(const AWall: PGreedRenderWall; ABaseAngle, ADistance, ATextureAdjust,
  ACeiling, AFloor: Integer; AKind: TGreedSpanKind; AStopWhenFar: Boolean): Boolean;
var
  S: TGreedRenderState;
  LX, LX1, LX2, LAngle, LAngleCos, LPointZ, LTexture, LAbsDistance: Integer;
  LSpan: PGreedSpan;
begin
  S := FState;
  Result := True;
  LX1 := S.P1^.PX;
  LX2 := S.P2^.PX;
  // calculate the textures to post into the span list
  if LX1 < S.XClipL then
    LX1 := S.XClipL;
  if LX2 > S.XClipH + 1 then
    LX2 := S.XClipH + 1;
  if LX1 >= LX2 then
    Exit; // totally clipped off side
  ABaseAngle := ABaseAngle + S.ViewFineAngle;
  if ADistance < 0 then
    LAbsDistance := -ADistance
  else
    LAbsDistance := ADistance;
  // step through the individual posts
  for LX := LX1 to LX2 - 1 do
  begin
    LAngle := ABaseAngle + S.PixelAngle^[LX];
    LAngle := LAngle and (GREED_TAN_ANGLES * 2 - 1);
    // the z distance of the post hit is walldistance * cos(screenangle)
    LAngleCos := S.Cosines^[(LAngle - GREED_TAN_ANGLES) and (GREED_TAN_ANGLES * 4 - 1)];
    if LAngleCos < 8000 then
      Continue;
    LPointZ := FM.Divide(LAbsDistance, LAngleCos);
    LPointZ := FM.Mul(LPointZ, S.PixelCosine^[LX]);
    if LPointZ > GREED_MAX_Z then
    begin
      if AStopWhenFar then
        Exit(False);
      Continue;
    end;
    if LPointZ < GREED_MIN_Z then
      Continue;

    // calculate the texture post along the wall that was hit
    LTexture := (ATextureAdjust + FM.Mul(ADistance, S.Tangents^[LAngle])) div GREED_FRACUNIT;
    LTexture := LTexture and 63;

    // post the span in the draw list
    LSpan := S.NewSpan(Cardinal(LPointZ), LX);
    if LSpan = nil then
      Exit;
    LSpan^.Kind := AKind;
    LSpan^.Picture := AWall^.Posts[LTexture];
    LSpan^.Y := ACeiling;
    LSpan^.YH := AFloor;
    LSpan^.Light := S.MapLight;
    LSpan^.Shadow := S.WallShadow;
  end;
end;

// Posts one pixel wide span events for each visible post of the doors of the tile
procedure TGreedContentRenderer.RenderDoor;
var
  S: TGreedRenderState;
  LIndex, LFound, LPart: Integer;
  LDoor: TGreedDoor;
  LTextureAdjust, LBaseAngle, LDistance, LCeiling, LFloor: Integer;
  LKind: TGreedSpanKind;
  LWall: PGreedRenderWall;
  LType: Integer;
begin
  S := FState;
  // scan the doors for the matching tile (this only happens a couple of times a frame)
  LFound := -1;
  for LIndex := 0 to FWorld.DoorCount - 1 do
  begin
    LDoor := FWorld.GetDoor(LIndex);
    if (LDoor.TileX = S.TileX) and (LDoor.TileY = S.TileY) then
    begin
      LFound := LIndex;
      Break;
    end;
  end;
  if LFound < 0 then
    Exit;
  // the heights that the original has left in the locals when the first two parts are not drawn
  LCeiling := S.Vertex[0]^.CeilingHeight;
  LFloor := -S.Vertex[0]^.FloorHeight;
  LKind := gskDoor;

  for LPart := 1 to 2 do
  begin
    if not SetupDoorFace(LDoor, 27 + (LPart - 1) * 10, LTextureAdjust, LBaseAngle, LDistance) then
      Exit;
    if (LDoor.Position = 0) or not SwapAndClip or not HasColumns then
      Continue;
    // set up for loop
    if LDoor.Transparent then
    begin
      LKind := gskMaskedDoor;
      S.DoorTile := False;
    end
    else
      LKind := gskDoor;
    LType := LDoor.Pic;
    if (LType >= 0) and (LType < Length(S.WallTranslation)) then
      LType := S.WallTranslation[LType]; // global animation
    LWall := S.WallAt(LType);
    if LWall = nil then
      Continue;
    LCeiling := S.Vertex[0]^.CeilingHeight;
    LFloor := -S.Vertex[0]^.FloorHeight;
    if not PostDoorColumns(LWall, LBaseAngle, LDistance, LTextureAdjust, LCeiling, LFloor, LKind, LPart = 2) then
      Exit;
  end;

  // the edge of the door (the third part)
  SetupDoorEdge(LDoor, LTextureAdjust, LBaseAngle, LDistance);
  if (LDoor.Position = 0) or not SwapAndClip or not HasColumns then
    Exit;
  LWall := S.WallAt(3);
  if LWall = nil then
    Exit;
  PostDoorColumns(LWall, LBaseAngle, LDistance, LTextureAdjust, LCeiling, LFloor, LKind, True);
end;

// For each sprite, if its bounding rect touches a tile with a vertex, transform and clip the projected view rect. If
// still visible a span goes in the list. Returns the index of the sprite from which the loop goes on
function TGreedContentRenderer.RenderSprite(AIndex: Integer): Integer;
var
  S: TGreedRenderState;
  LSprite: PGreedSprite;
  LDeltaX, LDeltaY, LPointX, LPointZ, LGXT, LGYT, LPicNum: Integer;
  LSpan: PGreedSpan;
  LGraphic, LMax, LDelay: Byte;
  LMapX, LMapY, LMapSpot, LNext: Integer;
  LPicture: PByte;
begin
  S := FState;
  Result := FSprites.Next(AIndex);
  LSprite := PGreedSprite(FSprites.Item(AIndex));
  // calculate which image to display
  LPicNum := LSprite^.BasePic;
  if LSprite^.Rotate <> grOne then
  begin // this is only approximate, but ok for 8
    if LSprite^.Rotate = grEight then
      LPicNum := LPicNum + ((S.ViewAngle - LSprite^.Angle + GREED_WEST + GREED_DEGREE45_2) div 128) and 7
    else
      LPicNum := LPicNum + ((S.ViewAngle - LSprite^.Angle + GREED_WEST + GREED_DEGREE45) div 256) and 3;
  end;

  if (LSprite^.Animation <> 0) and (FRenderTime >= LSprite^.AnimationTime) then
  begin
    LGraphic := (LSprite^.Animation and GREED_ANIM_CG_MASK) div 2;
    LMax := (LSprite^.Animation and GREED_ANIM_MG_MASK) div 32;
    LDelay := (LSprite^.Animation and GREED_ANIM_DELAY_MASK) shr 9;
    if LGraphic < LMax - 1 then
      Inc(LGraphic)
    else if LSprite^.Animation and GREED_ANIM_LOOP_MASK <> 0 then
      LGraphic := 0
    else if LSprite^.Animation and GREED_ANIM_SELF_DESTRUCT <> 0 then
    begin
      // some sprites exist only to animate and die
      LNext := FSprites.Next(AIndex);
      FSprites.Remove(AIndex);
      Exit(LNext);
    end;
    LPicNum := LPicNum + LGraphic;
    LSprite^.Animation := (LSprite^.Animation and GREED_ANIM_LOOP_MASK) + (LGraphic * 2) + (LMax * 32) +
      (LDelay shl 9) + (LSprite^.Animation and GREED_ANIM_SELF_DESTRUCT);
    LSprite^.AnimationTime := FClock.GetTimeCount + LDelay;
  end
  else if LSprite^.Animation <> 0 then
    LPicNum := LPicNum + (LSprite^.Animation and GREED_ANIM_CG_MASK) div 2;

  LDeltaX := LSprite^.X - S.ViewX;
  if (LDeltaX < -GREED_MAX_Z) or (LDeltaX > GREED_MAX_Z) then
    Exit;
  LDeltaY := LSprite^.Y - S.ViewY;
  if (LDeltaY < -GREED_MAX_Z) or (LDeltaY > GREED_MAX_Z) then
    Exit;

  // transform the point
  LGXT := FM.Mul(LDeltaX, S.ViewCos);
  LGYT := FM.Mul(LDeltaY, S.ViewSin);
  LPointZ := LGXT - LGYT;
  if (LPointZ > GREED_MAX_Z) or (LPointZ < GREED_FRACUNIT * 8) then
    Exit;
  LPointX := FM.Mul(LDeltaX, S.ViewSin) + FM.Mul(LDeltaY, S.ViewCos);

  // post the span event
  LPicture := S.SpritePicture(LPicNum);
  if LPicture = nil then
    Exit; // the original posts it and the drawing finds no picture
  LSpan := S.NewSpan(Cardinal(LPointZ), 0);
  if LSpan = nil then
    Exit;
  LSpan^.Kind := gskShape;
  LSpan^.Picture := LPicture;
  LSpan^.X2 := LPointX;
  LSpan^.Y := LSprite^.Z - S.ViewZ;
  LSpan^.Scale := LSprite^.Scale;
  LMapY := LSprite^.Y div GREED_FRACTILEUNIT;
  LMapX := LSprite^.X div GREED_FRACTILEUNIT;
  LMapSpot := LMapY * GREED_MAP_SIZE + LMapX;
  if (LMapSpot < 0) or (LMapSpot >= GREED_MAP_TILES) then
    LMapSpot := 0;
  if LSprite^.SpecialType = gstNoClip then
    LSpan^.Shadow := Ord(gstNoClip) * 256
  else
    LSpan^.Shadow := Ord(LSprite^.SpecialType) * 256 + S.MapEffects[LMapSpot];
  if LSprite^.SpecialType = gstNoClip then
    LSpan^.Light := -1000
  else
    LSpan^.Light := (S.MapLights[LMapSpot] * 4) + S.RealLight[LMapSpot];
end;

procedure TGreedContentRenderer.RenderSprites;
var
  LIndex: Integer;
begin
  LIndex := FSprites.First;
  while LIndex <> GREED_POOL_NIL do
    LIndex := RenderSprite(LIndex);
end;

end.
