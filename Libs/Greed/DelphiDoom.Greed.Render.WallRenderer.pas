{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the walls and the steps of the renderer          }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): DrawWall and DrawSteps of   }
{  r_walls.pas                                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Render.WallRenderer;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Greed.Render.State;

type
  /// <summary>
  ///   Draws the four walls of the tile that the state holds: DrawWall scales the wall of a side column by column
  ///   into the picture (a transparent wall waits in the list of the spans), and DrawSteps puts the steps of a floor
  ///   that is higher than the one of the next tile and the lower part of a ceiling that is lower. Nothing here
  ///   keeps a state of its own
  /// </summary>
  TGreedWallRenderer = class
  strict private
    FState: TGreedRenderState;
    procedure ScalePost;
    procedure SetFixedColormap;
  public
    constructor Create(AState: TGreedRenderState);
    /// <summary>DrawWall: the wall of the current side from the column AX1 to AX2</summary>
    procedure DrawWall(AX1, AX2: Integer);
    /// <summary>DrawSteps</summary>
    procedure DrawSteps(AX1, AX2: Integer);
    /// <summary>ScalePost: a post of AState registers into the picture</summary>
    class procedure ScalePostOf(AState: TGreedRenderState); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Types, DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.FixedMath,
  DelphiDoom.MathCore.FixedMath;

type
  FM = TGreedFixedMath;

{ TGreedWallRenderer }

constructor TGreedWallRenderer.Create(AState: TGreedRenderState);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  FState := AState;
end;

class procedure TGreedWallRenderer.ScalePostOf(AState: TGreedRenderState);
var
  LDest: PByte;
  LWidth: Integer;
begin
  with AState do
  begin
    LWidth := WindowWidth;
    SpDest := SpDest - LWidth * (SpCount - 1); // go to the top
    LDest := Buffer + SpDest;
    while SpCount > 0 do
    begin
      LDest^ := SpColormap[SpSource[SpFrac div GREED_FRACUNIT]];
      Inc(LDest, LWidth);
      SpFrac := SpFrac + SpFracStep;
      SpFrac := SpFrac and SpLoopValue;
      Dec(SpCount);
    end;
    SpDest := LDest - Buffer;
  end;
end;

procedure TGreedWallRenderer.ScalePost;
begin
  ScalePostOf(FState);
end;

// the color table of the tiles with a lighting effect of 1 to 4 (the rest is chosen for each post)
procedure TGreedWallRenderer.SetFixedColormap;
begin
  with FState do
    case WallShadow of
      1: SpColormap := @ColorMaps[WallGlow * 256];
      2: SpColormap := @ColorMaps[WallFlicker1 * 256];
      3: SpColormap := @ColorMaps[WallFlicker2 * 256];
      4: SpColormap := @ColorMaps[WallFlicker3 * 256];
    end;
end;

procedure TGreedWallRenderer.DrawWall(AX1, AX2: Integer);
var
  S: TGreedRenderState;
  LBaseAngle, LDistance, LPointZ, LAngleCos, LTextureAdjust, LCeiling, LFloor, LTop, LBottom, LScale: Integer;
  LTopY, LBottomY, LFracAdjust, LAngle, LTexture, LX, LLight: Integer;
  LWall: PGreedRenderWall;
  LTransparent, LRotateRight, LRotateLeft, LRotateUp, LRotateDown, LInvisible, LFlagsBoth: Integer;
  LKind: TGreedSpanKind;
  LHeightPost: Integer;
begin
  S := FState;
  if (S.WallType >= 0) and (S.WallType < Length(S.WallTranslation)) then
    S.WallType := S.WallTranslation[S.WallType];
  LWall := S.WallAt(S.WallType);
  if LWall = nil then
    Exit;
  LBaseAngle := S.ViewFineAngle;
  LTransparent := S.WallFlags and GREED_WALL_TRANSPARENT;
  LFloor := S.FloorHeight[S.MapSpot];
  LCeiling := S.CeilingHeight[S.MapSpot];
  LFlagsBoth := S.MapFlags[S.MapSpot] and (GREED_FL_CEILING + GREED_FL_FLOOR);
  case S.Side of
    0: // south facing wall
      begin
        LDistance := S.ViewY - (S.TileY * GREED_FRACTILEUNIT);
        LTextureAdjust := S.ViewX;
        LBaseAngle := LBaseAngle + GREED_TAN_ANGLES * 2;
        if LTransparent <> 0 then
          S.NorthMap[S.MapSpot] := GREED_TRANS_COLOR
        else
          S.NorthMap[S.MapSpot] := GREED_WALL_COLOR;
        if LFlagsBoth <> 0 then
        begin
          if S.FloorHeight[S.MapSpot + 1] < LFloor then
            LFloor := S.FloorHeight[S.MapSpot + 1];
          if S.CeilingHeight[S.MapSpot + 1] > LCeiling then
            LCeiling := S.CeilingHeight[S.MapSpot + 1];
        end;
      end;
    1: // west facing wall
      begin
        LDistance := ((S.TileX + 1) * GREED_FRACTILEUNIT) - S.ViewX;
        LTextureAdjust := S.ViewY;
        LBaseAngle := LBaseAngle + GREED_TAN_ANGLES;
        if LTransparent <> 0 then
          S.WestMap[S.MapSpot + 1] := GREED_TRANS_COLOR
        else
          S.WestMap[S.MapSpot + 1] := GREED_WALL_COLOR;
        if LFlagsBoth <> 0 then
        begin
          if S.FloorHeight[S.MapSpot + GREED_MAP_SIZE + 1] < LFloor then
            LFloor := S.FloorHeight[S.MapSpot + GREED_MAP_SIZE + 1];
          if S.CeilingHeight[S.MapSpot + GREED_MAP_SIZE + 1] > LCeiling then
            LCeiling := S.CeilingHeight[S.MapSpot + GREED_MAP_SIZE + 1];
        end;
      end;
    2: // north facing wall
      begin
        LDistance := ((S.TileY + 1) * GREED_FRACTILEUNIT) - S.ViewY;
        LTextureAdjust := -S.ViewX;
        LBaseAngle := LBaseAngle + GREED_TAN_ANGLES * 2;
        if LTransparent <> 0 then
          S.NorthMap[S.MapSpot + GREED_MAP_SIZE] := GREED_TRANS_COLOR
        else
          S.NorthMap[S.MapSpot + GREED_MAP_SIZE] := GREED_WALL_COLOR;
        if LFlagsBoth <> 0 then
        begin
          if S.FloorHeight[S.MapSpot + GREED_MAP_SIZE + 1] < LFloor then
            LFloor := S.FloorHeight[S.MapSpot + GREED_MAP_SIZE + 1];
          if S.CeilingHeight[S.MapSpot + GREED_MAP_SIZE + 1] > LCeiling then
            LCeiling := S.CeilingHeight[S.MapSpot + GREED_MAP_SIZE + 1];
        end;
      end;
    3: // east facing wall
      begin
        LDistance := S.ViewX - (S.TileX * GREED_FRACTILEUNIT);
        LTextureAdjust := -S.ViewY;
        LBaseAngle := LBaseAngle + GREED_TAN_ANGLES;
        if LTransparent <> 0 then
          S.WestMap[S.MapSpot] := GREED_TRANS_COLOR
        else
          S.WestMap[S.MapSpot] := GREED_WALL_COLOR;
        if LFlagsBoth <> 0 then
        begin
          if S.FloorHeight[S.MapSpot + GREED_MAP_SIZE] < LFloor then
            LFloor := S.FloorHeight[S.MapSpot + GREED_MAP_SIZE];
          if S.CeilingHeight[S.MapSpot + GREED_MAP_SIZE] > LCeiling then
            LCeiling := S.CeilingHeight[S.MapSpot + GREED_MAP_SIZE];
        end;
      end;
  else
    Exit;
  end;

  // the floor and ceiling height is the max of the points
  LCeiling := (LCeiling * GREED_FRACUNIT) - S.ViewZ;
  LFloor := -((LFloor * GREED_FRACUNIT) - S.ViewZ); // distance below the view
  LHeightPost := LWall^.Height;
  S.SpLoopValue := PSmallInt(LWall^.Data)^ * 4 * GREED_FRACUNIT - 1;

  // special effects
  if (S.WallShadow >= 1) and (S.WallShadow <= 4) then
    SetFixedColormap
  else if (S.WallShadow >= 5) and (S.WallShadow <= 8) then
  begin
    if S.WallCycle = S.WallShadow - 5 then
      S.SpColormap := S.ColorMaps
    else
      S.SpColormap := S.LightColormap(S.MapLight);
  end;

  LRotateLeft := S.WallFlags and GREED_WALL_LEFT;
  LRotateRight := S.WallFlags and GREED_WALL_RIGHT;
  LRotateUp := S.WallFlags and GREED_WALL_UP;
  LRotateDown := S.WallFlags and GREED_WALL_DOWN;
  LInvisible := S.WallFlags and GREED_WALL_DAMAGE;

  // step through the individual posts
  for LX := AX1 to AX2 do
  begin
    // first do the z clipping
    LAngle := LBaseAngle + S.PixelAngle^[LX];
    LAngle := LAngle and (GREED_TAN_ANGLES * 2 - 1);
    LAngleCos := S.Cosines^[(LAngle - GREED_TAN_ANGLES) and (GREED_TAN_ANGLES * 4 - 1)];
    LPointZ := FM.Divide(LDistance, LAngleCos);
    LPointZ := FM.Mul(LPointZ, S.PixelCosine^[LX]);
    if LPointZ > GREED_MAX_Z then
      Exit;
    if LPointZ < GREED_MIN_Z then
      Continue;

    // wall special effects
    if S.WallShadow = 0 then
      S.SpColormap := S.LightColormap((LPointZ div GREED_FRACUNIT) + S.MapLight)
    else if S.WallShadow = 9 then
      S.SpColormap := S.LightColormap((LPointZ div GREED_FRACUNIT) + S.MapLight + S.WallFlicker4);

    // calculate the texture post along the wall that was hit
    LTexture := (LTextureAdjust + FM.Mul(LDistance, S.Tangents^[LAngle])) div GREED_FRACUNIT;
    if LRotateRight <> 0 then
      LTexture := LTexture - S.WallRotate
    else if LRotateLeft <> 0 then
      LTexture := LTexture + S.WallRotate
    else if (LX = AX1) and (LX <> 0) then
      LTexture := 0; // fix the incorrect looping problem
    LTexture := LTexture and 63;

    S.SpSource := LWall^.Posts[LTexture];
    if LTransparent = 0 then
      S.WallZ[LX] := LPointZ;

    // calculate the size and scale of the post
    S.SpFracStep := FM.Mul(LPointZ, S.IScale);
    LScale := S.SpFracStep;
    if LScale < 1000 then
      Continue;

    LTop := FM.Divide(LCeiling, LScale) + GREED_FRACUNIT;
    LTopY := S.CenterY - (LTop div GREED_FRACUNIT);
    LFracAdjust := LTop and (GREED_FRACUNIT - 1);
    S.SpFrac := FM.Mul(LFracAdjust, S.SpFracStep);

    if LRotateDown <> 0 then
      S.SpFrac := S.SpFrac + GREED_FRACUNIT * (63 - S.WallRotate)
    else if LRotateUp <> 0 then
      S.SpFrac := S.SpFrac + GREED_FRACUNIT * S.WallRotate;

    if LTopY < S.ScrollMin then
    begin
      S.SpFrac := S.SpFrac + (S.ScrollMin - LTopY) * LScale;
      while S.SpFrac > S.SpLoopValue do
        S.SpFrac := S.SpFrac - S.SpLoopValue - 1;
      LTopY := S.ScrollMin;
    end;
    LBottom := FM.Divide(LFloor, LScale) + GREED_FRACUNIT * 2;
    if LBottom >= (S.CenterY + S.ScrollMin) * GREED_FRACUNIT then
      LBottomY := S.ScrollMax - 1
    else
      LBottomY := S.CenterY + (LBottom div GREED_FRACUNIT);
    if (LBottomY < S.ScrollMin) or (LTopY >= S.ScrollMax) or (LTopY = LBottomY) then
      Continue;

    S.SpCount := LBottomY - LTopY + 1;
    S.SpDest := (LBottomY - S.ScrollMin) * S.WindowWidth + LX;
    if LTransparent <> 0 then
    begin
      if LInvisible <> 0 then
        LKind := gskInvisibleWall
      else
        LKind := gskTransparentWall;
      S.PostWallSpan(LPointZ, LX, LKind, S.SpSource, S.SpFrac, S.SpFracStep, LHeightPost);
    end
    else
      ScalePost;
  end;
end;

procedure TGreedWallRenderer.DrawSteps(AX1, AX2: Integer);
var
  S: TGreedRenderState;
  LBaseAngle, LDistance, LPointZ, LAngleCos, LTextureAdjust, LCeiling1, LCeiling2, LFloor1, LFloor2: Integer;
  LTop, LBottom, LScale, LCClip1, LTopY, LBottomY, LFracAdjust, LAngle, LTexture, LTexture2, LX, LTileMap: Integer;
  LWall1, LWall2: PGreedRenderWall;
  LType1, LType2, LColor: Integer;
  LRotateRight1, LRotateRight2, LRotateLeft1, LRotateLeft2, LRotateUp1, LRotateUp2, LRotateDown1, LRotateDown2: Integer;
  LFloor, LCeiling: Boolean;
  LContinueCeiling: Boolean;
begin
  S := FState;
  LFloor := False;
  LCeiling := False;
  LDistance := 0;
  // the original leaves these without a value when the floor has a slope; the distance is 0 then and no post is drawn
  LBaseAngle := 0;
  LTextureAdjust := 0;
  LCClip1 := 0;
  LCeiling1 := 0;
  LFloor1 := 0;
  LCeiling2 := 0;
  LFloor2 := 0;
  LWall1 := nil;
  LWall2 := nil;
  LRotateRight1 := 0;
  LRotateLeft1 := 0;
  LRotateUp1 := 0;
  LRotateDown1 := 0;
  LRotateRight2 := 0;
  LRotateLeft2 := 0;
  LRotateUp2 := 0;
  LRotateDown2 := 0;

  if S.MapFlags[S.MapSpot] and GREED_FL_FLOOR = 0 then
  begin
    LBaseAngle := S.ViewFineAngle;
    case S.Side of
      0:
        begin
          LDistance := S.ViewY - (S.TileY * GREED_FRACTILEUNIT);
          LTextureAdjust := S.ViewX;
          LBaseAngle := LBaseAngle + GREED_TAN_ANGLES * 2;
          LTileMap := S.MapSpot - GREED_MAP_SIZE;
        end;
      1:
        begin
          LDistance := ((S.TileX + 1) * GREED_FRACTILEUNIT) - S.ViewX;
          LTextureAdjust := S.ViewY;
          LBaseAngle := LBaseAngle + GREED_TAN_ANGLES;
          LTileMap := S.MapSpot + 1;
        end;
      2:
        begin
          LDistance := ((S.TileY + 1) * GREED_FRACTILEUNIT) - S.ViewY;
          LTextureAdjust := -S.ViewX;
          LBaseAngle := LBaseAngle + GREED_TAN_ANGLES * 2;
          LTileMap := S.MapSpot + GREED_MAP_SIZE;
        end;
      3:
        begin
          LDistance := S.ViewX - (S.TileX * GREED_FRACTILEUNIT);
          LTextureAdjust := -S.ViewY;
          LBaseAngle := LBaseAngle + GREED_TAN_ANGLES;
          LTileMap := S.MapSpot - 1;
        end;
    else
      Exit;
    end;
    // the north neighbor of a tile of the first row is before the map (the original reads what is there)
    if LTileMap < 0 then
      LTileMap := 0;
    LCeiling1 := S.FloorHeight[LTileMap];
    LFloor1 := S.FloorHeight[S.MapSpot];
    if LCeiling1 > LFloor1 then
    begin
      if LCeiling1 >= S.CeilingHeight[S.MapSpot] then
        S.WallType := 1; // clip beyond this tile
      LType1 := S.FloorDef[LTileMap];
      if (LType1 >= 0) and (LType1 < Length(S.WallTranslation)) then
        LType1 := S.WallTranslation[LType1]; // global animation
      LWall1 := S.WallAt(LType1);
      if LWall1 <> nil then
      begin
        LFloor := True;
        LRotateRight1 := S.FloorDefFlags[LTileMap] and GREED_WALL_RIGHT;
        LRotateLeft1 := S.FloorDefFlags[LTileMap] and GREED_WALL_LEFT;
        LRotateUp1 := S.FloorDefFlags[LTileMap] and GREED_WALL_UP;
        LRotateDown1 := S.FloorDefFlags[LTileMap] and GREED_WALL_DOWN;
        LCClip1 := LCeiling1;
        LCeiling1 := (LCeiling1 * GREED_FRACUNIT) - S.ViewZ;
        LFloor1 := -((LFloor1 * GREED_FRACUNIT) - S.ViewZ); // distance below the view
      end;
    end;
  end;

  // the ceiling step
  LContinueCeiling := True;
  if S.MapFlags[S.MapSpot] and GREED_FL_CEILING <> 0 then
  begin
    if not LFloor then
      Exit;
    LContinueCeiling := False;
  end;
  if LContinueCeiling then
  begin
    case S.Side of
      0: LTileMap := S.MapSpot - GREED_MAP_SIZE;
      1: LTileMap := S.MapSpot + 1;
      2: LTileMap := S.MapSpot + GREED_MAP_SIZE;
      3: LTileMap := S.MapSpot - 1;
    else
      Exit;
    end;
    if LTileMap < 0 then
      LTileMap := 0;
    LFloor2 := S.CeilingHeight[LTileMap];
    LCeiling2 := S.CeilingHeight[S.MapSpot];
    if LCeiling2 <= LFloor2 then
    begin
      if not LFloor then
        Exit;
    end
    else
    begin
      if LFloor2 <= S.FloorHeight[S.MapSpot] then
        S.WallType := 1; // clip beyond this tile
      if LFloor and (LCClip1 >= LFloor2) then
        S.WallType := 1;
      LType2 := S.CeilingDef[LTileMap];
      if (LType2 >= 0) and (LType2 < Length(S.WallTranslation)) then
        LType2 := S.WallTranslation[LType2]; // global animation
      LWall2 := S.WallAt(LType2);
      if LWall2 <> nil then
      begin
        LCeiling := True;
        LCeiling2 := (LCeiling2 * GREED_FRACUNIT) - S.ViewZ;
        LFloor2 := -((LFloor2 * GREED_FRACUNIT) - S.ViewZ); // distance below the view
        LRotateLeft2 := S.CeilingDefFlags[LTileMap] and GREED_WALL_LEFT;
        LRotateRight2 := S.CeilingDefFlags[LTileMap] and GREED_WALL_RIGHT;
        LRotateUp2 := S.CeilingDefFlags[LTileMap] and GREED_WALL_UP;
        LRotateDown2 := S.CeilingDefFlags[LTileMap] and GREED_WALL_DOWN;
      end
      else if not LFloor then
        Exit;
    end;
  end;

  SetFixedColormap;

  // step through the individual posts
  for LX := AX1 to AX2 do
  begin
    // first do the z clipping
    LAngle := LBaseAngle + S.PixelAngle^[LX];
    LAngle := LAngle and (GREED_TAN_ANGLES * 2 - 1);
    LAngleCos := S.Cosines^[(LAngle - GREED_TAN_ANGLES) and (GREED_TAN_ANGLES * 4 - 1)];
    LPointZ := FM.Divide(LDistance, LAngleCos);
    LPointZ := FM.Mul(LPointZ, S.PixelCosine^[LX]);
    if (LPointZ > GREED_MAX_Z) or (LPointZ < GREED_MIN_Z) then
      Continue;

    // wall special effects
    if S.WallShadow = 0 then
      S.SpColormap := S.LightColormap((LPointZ div GREED_FRACUNIT) + S.MapLight)
    else if (S.WallShadow >= 5) and (S.WallShadow <= 8) then
    begin
      if S.WallCycle = S.WallShadow - 5 then
        S.SpColormap := S.ColorMaps
      else
        S.SpColormap := S.LightColormap((LPointZ div GREED_FRACUNIT) + S.MapLight);
    end
    else if S.WallShadow = 9 then
      S.SpColormap := S.LightColormap((LPointZ div GREED_FRACUNIT) + S.MapLight + S.WallFlicker4);

    LTexture := (LTextureAdjust + FM.Mul(LDistance, S.Tangents^[LAngle])) div GREED_FRACUNIT;

    LScale := FM.Mul(LPointZ, S.IScale);
    if LScale < 1000 then
      Continue;
    S.SpFracStep := LScale;

    if LFloor then
    begin
      LTexture2 := LTexture;
      if LRotateRight1 <> 0 then
        LTexture2 := LTexture2 - S.WallRotate
      else if LRotateLeft1 <> 0 then
        LTexture2 := LTexture2 + S.WallRotate
      else if (LX = AX1) and (LX <> 0) then
        LTexture2 := 0; // fix the incorrect looping problem
      LTexture2 := LTexture2 and 63;
      S.SpSource := LWall1^.Posts[LTexture2];
      LTop := FM.Divide(LCeiling1, LScale);
      LTopY := S.CenterY - (LTop div GREED_FRACUNIT);
      LFracAdjust := LTop and (GREED_FRACUNIT - 1);
      S.SpFrac := FM.Mul(LFracAdjust, S.SpFracStep);

      if LTopY < S.ScrollMin then
      begin
        S.SpFrac := S.SpFrac + (S.ScrollMin - LTopY) * LScale;
        S.SpLoopValue := PSmallInt(LWall1^.Data)^ * 4 * GREED_FRACUNIT - 1;
        while S.SpFrac > S.SpLoopValue do
          S.SpFrac := S.SpFrac - S.SpLoopValue - 1;
        LTopY := S.ScrollMin;
      end;
      if LRotateDown1 <> 0 then
        S.SpFrac := S.SpFrac + GREED_FRACUNIT * (63 - S.WallRotate)
      else if LRotateUp1 <> 0 then
        S.SpFrac := S.SpFrac + GREED_FRACUNIT * S.WallRotate;

      LBottom := FM.Divide(LFloor1, LScale) + GREED_FRACUNIT;
      if LBottom >= ((S.CenterY + S.ScrollMin) * GREED_FRACUNIT) then
        LBottomY := S.ScrollMax - 1
      else
        LBottomY := S.CenterY + (LBottom div GREED_FRACUNIT);
      if not ((LBottomY < S.ScrollMin) or (LTopY >= S.ScrollMax)) then
      begin
        S.SpCount := LBottomY - LTopY + 1;
        S.SpDest := (LBottomY - S.ScrollMin) * S.WindowWidth + LX;
        S.PostWallSpan(LPointZ, LX, gskStep, S.SpSource, S.SpFrac, S.SpFracStep, PSmallInt(LWall1^.Data)^ * 4);
      end;
    end;

    if LCeiling then
    begin
      LTexture2 := LTexture;
      if LRotateRight2 <> 0 then
        LTexture2 := LTexture2 - S.WallRotate
      else if LRotateLeft2 <> 0 then
        LTexture2 := LTexture2 + S.WallRotate
      else if (LX = AX1) and (LX <> 0) then
        LTexture2 := 0; // fix the incorrect looping problem
      LTexture2 := LTexture2 and 63;
      S.SpSource := LWall2^.Posts[LTexture2];
      LTop := FM.Divide(LCeiling2, LScale) + GREED_FRACUNIT;
      LTopY := S.CenterY - (LTop div GREED_FRACUNIT);
      LFracAdjust := LTop and (GREED_FRACUNIT - 1);
      S.SpFrac := FM.Mul(LFracAdjust, S.SpFracStep);

      if LTopY < S.ScrollMin then
      begin
        S.SpFrac := S.SpFrac + (S.ScrollMin - LTopY) * LScale;
        S.SpLoopValue := PSmallInt(LWall2^.Data)^ * 4 * GREED_FRACUNIT - 1;
        while S.SpFrac > S.SpLoopValue do
          S.SpFrac := S.SpFrac - S.SpLoopValue - 1;
        LTopY := S.ScrollMin;
      end;
      if LRotateDown2 <> 0 then
        S.SpFrac := S.SpFrac + GREED_FRACUNIT * (63 - S.WallRotate)
      else if LRotateUp2 <> 0 then
        S.SpFrac := S.SpFrac + GREED_FRACUNIT * S.WallRotate;

      LBottom := FM.Divide(LFloor2, LScale) + GREED_FRACUNIT;
      if LBottom >= ((S.CenterY + S.ScrollMin) * GREED_FRACUNIT) then
        LBottomY := S.ScrollMax - 1
      else
        LBottomY := S.CenterY + (LBottom div GREED_FRACUNIT);
      if (LBottomY < S.ScrollMin) or (LTopY >= S.ScrollMax) then
        Continue;
      S.SpCount := LBottomY - LTopY + 1;
      S.SpDest := (LBottomY - S.ScrollMin) * S.WindowWidth + LX;
      S.PostWallSpan(LPointZ, LX, gskStep, S.SpSource, S.SpFrac, S.SpFracStep, PSmallInt(LWall2^.Data)^ * 4);
    end;
  end;

  if LFloor then
  begin
    if S.WallType <> 0 then
      LColor := GREED_WALL_COLOR
    else
      LColor := GREED_STEP_COLOR;
    case S.Side of
      0: S.NorthMap[S.MapSpot] := LColor;
      1: S.WestMap[S.MapSpot + 1] := LColor;
      2: S.NorthMap[S.MapSpot + GREED_MAP_SIZE] := LColor;
      3: S.WestMap[S.MapSpot] := LColor;
    end;
  end;
end;

end.
