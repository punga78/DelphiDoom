{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the movement of the actors and their clipping     }
{  to the tiles and to each other                                               }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  MoveObjVert ... ClipToSprite of kd_play.c                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ActorMover;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   Moves an actor by what its state proposes (xmove, ymove) and pushes it out of the walls of the tiles
  ///   of the foreground plane. A tile says in the tile info, for each of its four sides, what kind of wall it is:
  ///   1 solid, 2 to 7 the slopes (wallclip says how high the wall is at each pixel of the tile). The "int" and the
  ///   "unsigned" of the C are 16 bit: the positions and the sizes of the hit rectangles are Word and a
  ///   difference of two of them is read as a signed 16 bit number. Where the C reads a tile outside the
  ///   map, here the tile is 0
  /// </summary>
  TKeenActorMover = class
  strict private
    FMap: IKeenWorkingMap;
    FTileInfo: IKeenTileInfo;
    FSprites: IKeenSpriteCache;
    FStates: IKeenStateTable;
    FObjects: IKeenObjectList;
    FEvents: IKeenGameEvents;
    FOldTileLeft: Integer;
    FOldTileTop: Integer;
    FOldTileRight: Integer;
    FOldTileBottom: Integer;
    FOldTileMidX: Integer;
    FOldLeft: Integer;
    FOldTop: Integer;
    FOldRight: Integer;
    FOldBottom: Integer;
    FOldMidX: Integer;
    FLeftMoved: Integer;
    FRightMoved: Integer;
    FTopMoved: Integer;
    FBottomMoved: Integer;
    FMidXMoved: Integer;
    function ForegroundTile(ATileX, ATileY: Integer): Integer;
    function PushesToFloor(AObject: PKeenObject): Boolean;
    procedure ClipToEnds(AObject: PKeenObject);
    procedure ClipToEastWalls(AObject: PKeenObject);
    procedure ClipToWestWalls(AObject: PKeenObject);
  public
    constructor Create(const AMap: IKeenWorkingMap; const ATileInfo: IKeenTileInfo; const ASprites: IKeenSpriteCache;
      const AStates: IKeenStateTable; const AObjects: IKeenObjectList; const AEvents: IKeenGameEvents);
    /// <summary>The map that the walls are read from: a new level</summary>
    procedure SetMap(const AMap: IKeenWorkingMap);
    /// <summary>MoveObjVert</summary>
    procedure MoveVertical(AObject: PKeenObject; AMove: Integer);
    /// <summary>MoveObjHoriz</summary>
    procedure MoveHorizontal(AObject: PKeenObject; AMove: Integer);
    /// <summary>ClipToWalls: moves the actor by xmove and ymove (to one tile at most) and clips it to the walls</summary>
    procedure ClipToWalls(AObject: PKeenObject);
    /// <summary>ClipToSpriteSide: the push actor is pushed out of the side of the solid one</summary>
    procedure ClipToSpriteSide(APush, ASolid: PKeenObject);
    /// <summary>ClipToSprite: the push actor is pushed out of the solid one, a moving platform; with ASquish Keen dies between it and a wall</summary>
    procedure ClipToSprite(APush, ASolid: PKeenObject; ASquish: Boolean);
    /// <summary>wallclip[wall and 7][x]: how high the wall of a tile is at the pixel x (0..15), in 1/16 of a pixel</summary>
    class function WallClip(AWall, AX: Integer): Integer; static;
  end;

implementation

uses
  DelphiDoom.Keen.Arithmetic;

const
  // wallclip[8][16]: the height of a given point of a tile, by type of wall
  WALL_CLIP: array[0..7, 0..15] of SmallInt = (
    (256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256, 256),
    (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    (0, $08, $10, $18, $20, $28, $30, $38, $40, $48, $50, $58, $60, $68, $70, $78),
    ($80, $88, $90, $98, $A0, $A8, $B0, $B8, $C0, $C8, $D0, $D8, $E0, $E8, $F0, $F8),
    (0, $10, $20, $30, $40, $50, $60, $70, $80, $90, $A0, $B0, $C0, $D0, $E0, $F0),
    ($78, $70, $68, $60, $58, $50, $48, $40, $38, $30, $28, $20, $18, $10, $08, 0),
    ($F8, $F0, $E8, $E0, $D8, $D0, $C8, $C0, $B8, $B0, $A8, $A0, $98, $90, $88, $80),
    ($F0, $E0, $D0, $C0, $B0, $A0, $90, $80, $70, $60, $50, $40, $30, $20, $10, 0)
  );

{ TKeenActorMover }

constructor TKeenActorMover.Create(const AMap: IKeenWorkingMap; const ATileInfo: IKeenTileInfo;
  const ASprites: IKeenSpriteCache; const AStates: IKeenStateTable; const AObjects: IKeenObjectList;
  const AEvents: IKeenGameEvents);
begin
  inherited Create;
  if not Assigned(ATileInfo) then
    raise EArgumentNilException.Create('ATileInfo');
  if not Assigned(ASprites) then
    raise EArgumentNilException.Create('ASprites');
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  if not Assigned(AObjects) then
    raise EArgumentNilException.Create('AObjects');
  if not Assigned(AEvents) then
    raise EArgumentNilException.Create('AEvents');
  FMap := AMap;
  FTileInfo := ATileInfo;
  FSprites := ASprites;
  FStates := AStates;
  FObjects := AObjects;
  FEvents := AEvents;
end;

procedure TKeenActorMover.SetMap(const AMap: IKeenWorkingMap);
begin
  FMap := AMap;
end;

class function TKeenActorMover.WallClip(AWall, AX: Integer): Integer;
begin
  Result := WALL_CLIP[AWall and 7, AX and 15];
end;

function TKeenActorMover.ForegroundTile(ATileX, ATileY: Integer): Integer;
begin
  // the C reads outside of the plane for a tile that is not on the map; here there is no wall there
  if (not Assigned(FMap)) or (ATileX < 0) or (ATileX >= FMap.Width) or (ATileY < 0) or (ATileY >= FMap.Height) then
    Exit(0);
  Result := FMap.Planes[1][ATileY * FMap.Width + ATileX];
  // a number that is not a tile of the table is no wall (the C would read the next table)
  if Result >= KEEN_NUMTILE16M then
    Result := 0;
end;

function TKeenActorMover.PushesToFloor(AObject: PKeenObject): Boolean;
begin
  Result := (AObject^.State >= 0) and FStates[AObject^.State].PushToFloor;
end;

procedure TKeenActorMover.MoveVertical(AObject: PKeenObject; AMove: Integer);
begin
  AObject^.Y := TKeenArithmetic.ToWord(AObject^.Y + AMove);
  AObject^.Top := TKeenArithmetic.ToWord(AObject^.Top + AMove);
  AObject^.Bottom := TKeenArithmetic.ToWord(AObject^.Bottom + AMove);
  AObject^.TileTop := AObject^.Top shr 8;
  AObject^.TileBottom := AObject^.Bottom shr 8;
end;

procedure TKeenActorMover.MoveHorizontal(AObject: PKeenObject; AMove: Integer);
begin
  AObject^.X := TKeenArithmetic.ToWord(AObject^.X + AMove);
  AObject^.Left := TKeenArithmetic.ToWord(AObject^.Left + AMove);
  AObject^.Right := TKeenArithmetic.ToWord(AObject^.Right + AMove);
  AObject^.TileLeft := AObject^.Left shr 8;
  AObject^.TileRight := AObject^.Right shr 8;
end;

procedure TKeenActorMover.ClipToEnds(AObject: PKeenObject);
var
  LMidXPixel: Integer;
  LMaxMove: Integer;
  LY: Integer;
  LWall: Integer;
  LClip: Integer;
  LMove: Integer;
  LTotalMove: Integer;
begin
  LMidXPixel := (AObject^.MidX and $F0) shr 4;
  // the floor under the actor: from the tile before the move to the tile it is in now
  LMaxMove := -Abs(FMidXMoved) - FBottomMoved - 16;
  LY := FOldTileBottom - 1;
  // y is an int and the tile an unsigned in the C: y = -1 is 65535 and the loop does not start
  while Word(LY) <= AObject^.TileBottom do
  begin
    LWall := FTileInfo.NorthWall(ForegroundTile(AObject^.TileMidX, LY));
    if LWall <> 0 then
    begin
      LClip := WallClip(LWall, LMidXPixel);
      LMove := TKeenArithmetic.ToInt16(((LY shl 8) + LClip - 1) - AObject^.Bottom);
      if (LMove < 0) and (LMove >= LMaxMove) then
      begin
        AObject^.HitNorth := LWall;
        MoveVertical(AObject, LMove);
        Exit;
      end;
    end;
    Inc(LY);
  end;
  // the ceiling over the actor
  LMaxMove := Abs(FMidXMoved) - FTopMoved + 16;
  LY := FOldTileTop + 1;
  while (LY >= Integer(AObject^.TileTop)) and (LY >= 0) do
  begin
    LWall := FTileInfo.SouthWall(ForegroundTile(AObject^.TileMidX, LY));
    if LWall <> 0 then
    begin
      LClip := WallClip(LWall, LMidXPixel);
      LMove := TKeenArithmetic.ToInt16((((LY + 1) shl 8) - LClip) - AObject^.Top);
      if (LMove > 0) and (LMove <= LMaxMove) then
      begin
        LTotalMove := AObject^.YMove + LMove;
        if (LTotalMove < KEEN_TILEGLOBAL) and (LTotalMove > -KEEN_TILEGLOBAL) then
        begin
          AObject^.HitSouth := LWall;
          MoveVertical(AObject, LMove);
        end;
      end;
    end;
    Dec(LY);
  end;
end;

procedure TKeenActorMover.ClipToEastWalls(AObject: PKeenObject);
var
  LY: Integer;
  LTop: Integer;
  LBottom: Integer;
  LMove: Integer;
begin
  // east walls are clipped if the actor moves west
  LTop := AObject^.TileTop;
  if AObject^.HitSouth > 1 then
    Inc(LTop); // on a slope inside a tile
  LBottom := AObject^.TileBottom;
  if AObject^.HitNorth > 1 then
    Dec(LBottom);
  for LY := LTop to LBottom do
  begin
    AObject^.HitEast := FTileInfo.EastWall(ForegroundTile(AObject^.TileLeft, LY));
    if AObject^.HitEast <> 0 then
    begin
      LMove := TKeenArithmetic.ToInt16(((AObject^.TileLeft + 1) shl 8) - AObject^.Left);
      MoveHorizontal(AObject, LMove);
      Exit;
    end;
  end;
end;

procedure TKeenActorMover.ClipToWestWalls(AObject: PKeenObject);
var
  LY: Integer;
  LTop: Integer;
  LBottom: Integer;
  LMove: Integer;
begin
  // west walls are clipped if the actor moves east
  LTop := AObject^.TileTop;
  if AObject^.HitSouth > 1 then
    Inc(LTop);
  LBottom := AObject^.TileBottom;
  if AObject^.HitNorth > 1 then
    Dec(LBottom);
  for LY := LTop to LBottom do
  begin
    AObject^.HitWest := FTileInfo.WestWall(ForegroundTile(AObject^.TileRight, LY));
    if AObject^.HitWest <> 0 then
    begin
      LMove := TKeenArithmetic.ToInt16(((AObject^.TileRight shl 8) - 1) - AObject^.Right);
      MoveHorizontal(AObject, LMove);
      Exit;
    end;
  end;
end;

procedure TKeenActorMover.ClipToWalls(AObject: PKeenObject);
var
  LEntry: TKeenSpriteEntry;
begin
  // stay in contact with a slope of 45 degrees
  if PushesToFloor(AObject) then
  begin
    if AObject^.XMove > 0 then
      AObject^.YMove := AObject^.XMove + 16
    else
      AObject^.YMove := -AObject^.XMove + 16;
  end;
  // move the shape, to a tile at most
  if AObject^.XMove > KEEN_MAXMOVE then
    AObject^.XMove := KEEN_MAXMOVE
  else if AObject^.XMove < -KEEN_MAXMOVE then
    AObject^.XMove := -KEEN_MAXMOVE;
  if AObject^.YMove > KEEN_MAXMOVE + 16 then // +16 to push to the floor
    AObject^.YMove := KEEN_MAXMOVE + 16
  else if AObject^.YMove < -KEEN_MAXMOVE then
    AObject^.YMove := -KEEN_MAXMOVE;
  AObject^.X := TKeenArithmetic.ToWord(AObject^.X + AObject^.XMove);
  AObject^.Y := TKeenArithmetic.ToWord(AObject^.Y + AObject^.YMove);
  AObject^.NeedToReact := True;
  // an actor with no shape has no hit rectangle. The shape -1 (an invisible state: NewState gives it to the
  // actor before StateMachine changes it to 0) is the same: the C reads a line of the sprite table that is not there
  if (AObject^.ShapeNum = 0) or (AObject^.ShapeNum = Word(-1)) then
    Exit;
  if (AObject^.ShapeNum < KEEN_STARTSPRITES) or (AObject^.ShapeNum >= KEEN_STARTSPRITES + KEEN_NUMSPRITES) then
    raise EKeenException.CreateFmt(SKeenNoSpriteShape, [AObject^.ShapeNum]);
  LEntry := FSprites.GetEntry(AObject^.ShapeNum);
  FOldTileRight := AObject^.TileRight;
  FOldTileTop := AObject^.TileTop;
  FOldTileLeft := AObject^.TileLeft;
  FOldTileBottom := AObject^.TileBottom;
  FOldTileMidX := AObject^.TileMidX;
  FOldRight := AObject^.Right;
  FOldTop := AObject^.Top;
  FOldLeft := AObject^.Left;
  FOldBottom := AObject^.Bottom;
  FOldMidX := AObject^.MidX;
  AObject^.Left := TKeenArithmetic.ToWord(AObject^.X + LEntry.XL);
  AObject^.Right := TKeenArithmetic.ToWord(AObject^.X + LEntry.XH);
  AObject^.Top := TKeenArithmetic.ToWord(AObject^.Y + LEntry.YL);
  AObject^.Bottom := TKeenArithmetic.ToWord(AObject^.Y + LEntry.YH);
  // unsigned: (right - left) wraps if the rectangle is upside down
  AObject^.MidX := TKeenArithmetic.ToWord(AObject^.Left + TKeenArithmetic.ToWord(AObject^.Right - AObject^.Left) div 2);
  AObject^.TileLeft := AObject^.Left shr 8;
  AObject^.TileRight := AObject^.Right shr 8;
  AObject^.TileTop := AObject^.Top shr 8;
  AObject^.TileBottom := AObject^.Bottom shr 8;
  AObject^.TileMidX := AObject^.MidX shr 8;
  AObject^.HitNorth := 0;
  AObject^.HitEast := 0;
  AObject^.HitSouth := 0;
  AObject^.HitWest := 0;
  if not AObject^.NeedToClip then
    Exit;
  FLeftMoved := TKeenArithmetic.ToInt16(AObject^.Left - FOldLeft);
  FRightMoved := TKeenArithmetic.ToInt16(AObject^.Right - FOldRight);
  FTopMoved := TKeenArithmetic.ToInt16(AObject^.Top - FOldTop);
  FBottomMoved := TKeenArithmetic.ToInt16(AObject^.Bottom - FOldBottom);
  FMidXMoved := TKeenArithmetic.ToInt16(AObject^.MidX - FOldMidX);
  ClipToEnds(AObject);
  // the player is always clipped to the walls at its sides
  if (FLeftMoved < 0) or (AObject = FObjects.Player) then
    ClipToEastWalls(AObject);
  if (FRightMoved > 0) or (AObject = FObjects.Player) then
    ClipToWestWalls(AObject);
end;

procedure TKeenActorMover.ClipToSpriteSide(APush, ASolid: PKeenObject);
var
  LXMove: Integer;
  LLeftInto: Integer;
  LRightInto: Integer;
begin
  // how much the push shape can be pushed
  LXMove := ASolid^.XMove - APush^.XMove;
  // how much of it is inside
  LLeftInto := TKeenArithmetic.ToInt16(ASolid^.Right - APush^.Left);
  LRightInto := TKeenArithmetic.ToInt16(APush^.Right - ASolid^.Left);
  if (LLeftInto > 0) and (LLeftInto <= LXMove) then
  begin
    APush^.XMove := LLeftInto;
    if PushesToFloor(APush) then
      APush^.YMove := LLeftInto + 16;
    ClipToWalls(APush);
    APush^.HitEast := 1;
    Exit;
  end;
  if (LRightInto > 0) and (LRightInto <= -LXMove) then
  begin
    APush^.XMove := -LRightInto;
    if PushesToFloor(APush) then
      APush^.YMove := LRightInto + 16;
    ClipToWalls(APush);
    APush^.HitWest := 1;
  end;
end;

procedure TKeenActorMover.ClipToSprite(APush, ASolid: PKeenObject; ASquish: Boolean);
var
  LXMove: Integer;
  LWallTemp: Integer;
  LLeftInto: Integer;
  LRightInto: Integer;
  LTopInto: Integer;
  LBottomInto: Integer;
  LPushToFloor: Boolean;
begin
  LXMove := ASolid^.XMove - APush^.XMove;
  APush^.XMove := 0;
  APush^.YMove := 0;
  // left and right
  LLeftInto := TKeenArithmetic.ToInt16(ASolid^.Right - APush^.Left);
  LRightInto := TKeenArithmetic.ToInt16(APush^.Right - ASolid^.Left);
  if (LLeftInto > 0) and (LLeftInto <= LXMove) then
  begin
    APush^.XMove := LLeftInto;
    LWallTemp := APush^.HitNorth;
    ClipToWalls(APush);
    if APush^.HitNorth = 0 then
      APush^.HitNorth := LWallTemp;
    if ASquish and (APush^.HitWest <> 0) then
      FEvents.KillKeen;
    APush^.HitEast := 1;
    Exit;
  end
  else if (LRightInto > 0) and (LRightInto <= -LXMove) then
  begin
    APush^.XMove := -LRightInto;
    LWallTemp := APush^.HitNorth;
    ClipToWalls(APush);
    if APush^.HitNorth = 0 then
      APush^.HitNorth := LWallTemp;
    if ASquish and (APush^.HitEast <> 0) then
      FEvents.KillKeen;
    APush^.HitWest := 1;
    Exit;
  end;
  // top and bottom
  LTopInto := TKeenArithmetic.ToInt16(ASolid^.Bottom - APush^.Top);
  LBottomInto := TKeenArithmetic.ToInt16(APush^.Bottom - ASolid^.Top);
  if LBottomInto > 0 then
  begin
    APush^.YMove := -LBottomInto + 16;
    APush^.XMove := ASolid^.XMove;
    // the state does not push to the floor for this move
    LPushToFloor := PushesToFloor(APush);
    if APush^.State >= 0 then
      FStates.SetPushToFloor(APush^.State, False);
    LWallTemp := APush^.HitNorth;
    ClipToWalls(APush);
    if APush^.HitNorth = 0 then
      APush^.HitNorth := LWallTemp;
    if APush^.State >= 0 then
      FStates.SetPushToFloor(APush^.State, LPushToFloor);
    APush^.HitNorth := 25;
  end
  else if LTopInto > 0 then
  begin
    APush^.YMove := LTopInto;
    ClipToWalls(APush);
    APush^.HitSouth := 25;
  end;
end;

end.
