{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - what the groups of actions share                  }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  DoGravity, AccelerateX, FrictionX, ProjectileThink, ChangeState (kd_act1.c)  }
{  and the bounce of PowerReact (kd_keen.c) and ProjectileReact (kd_act2.c)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ActionContext;

// the int and the unsigned of the C are 16 bit and wrap: the arithmetic here does the same
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.StateTypes, DelphiDoom.Keen.Intf;

type
  /// <summary>The parts of the game that the actions need and the helpers that more than one group uses</summary>
  TKeenActionContext = class(TInterfacedObject, IKeenActionContext)
  strict private
    FObjects: IKeenObjectList;
    FStates: IKeenStateTable;
    FRandom: IKeenRandom;
    FEvents: IKeenGameEvents;
    FView: IKeenActionView;
    FPhysics: IKeenActorPhysics;
    FPlay: IKeenPlayState;
    FMap: IKeenWorkingMap;
    FTileInfo: IKeenTileInfo;
  public
    constructor Create(const AObjects: IKeenObjectList; const AStates: IKeenStateTable; const ARandom: IKeenRandom;
      const AEvents: IKeenGameEvents; const AView: IKeenActionView; const APhysics: IKeenActorPhysics;
      const APlay: IKeenPlayState; const AMap: IKeenWorkingMap; const ATileInfo: IKeenTileInfo);
    function GetObjects: IKeenObjectList;
    function GetStates: IKeenStateTable;
    function GetRandom: IKeenRandom;
    function GetEvents: IKeenGameEvents;
    function GetView: IKeenActionView;
    function GetPhysics: IKeenActorPhysics;
    function GetPlay: IKeenPlayState;
    function GetMap: IKeenWorkingMap;
    procedure SetMap(const AMap: IKeenWorkingMap);
    function Tile(APlane, ATileX, ATileY: Integer): Integer;
    function NorthWall(ATile: Integer): Integer;
    function EastWall(ATile: Integer): Integer;
    function SouthWall(ATile: Integer): Integer;
    function WestWall(ATile: Integer): Integer;
    function InTile(ATile: Integer): Integer;
    procedure ChangeState(AObject: PKeenObject; AState: Integer);
    procedure DoGravity(AObject: PKeenObject);
    procedure AccelerateX(AObject: PKeenObject; ADirection, AMax: Integer);
    procedure FrictionX(AObject: PKeenObject);
    procedure ProjectileThink(AObject: PKeenObject);
    procedure PlaceSprite(AObject: PKeenObject; APriority: Integer);
    function BounceOffFloor(AObject: PKeenObject): Cardinal;
  end;

implementation

uses
  DelphiDoom.Keen.Arithmetic;

const
  /// <summary>bounceangle[8][8] of kd_keen.c</summary>
  BOUNCE_ANGLE: array[0..63] of Byte = (
    0, 0, 0, 0, 0, 0, 0, 0,
    7, 6, 5, 4, 3, 2, 1, 0,
    5, 4, 3, 2, 1, 0, 15, 14,
    5, 4, 3, 2, 1, 0, 15, 14,
    3, 2, 1, 0, 15, 14, 13, 12,
    9, 8, 7, 6, 5, 4, 3, 2,
    9, 8, 7, 6, 5, 4, 3, 2,
    11, 10, 9, 8, 7, 6, 5, 4);

{ TKeenActionContext }

constructor TKeenActionContext.Create(const AObjects: IKeenObjectList; const AStates: IKeenStateTable;
  const ARandom: IKeenRandom; const AEvents: IKeenGameEvents; const AView: IKeenActionView;
  const APhysics: IKeenActorPhysics; const APlay: IKeenPlayState; const AMap: IKeenWorkingMap;
  const ATileInfo: IKeenTileInfo);
begin
  inherited Create;
  if not Assigned(AObjects) then
    raise EArgumentNilException.Create('AObjects');
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  if not Assigned(AEvents) then
    raise EArgumentNilException.Create('AEvents');
  if not Assigned(AView) then
    raise EArgumentNilException.Create('AView');
  if not Assigned(APhysics) then
    raise EArgumentNilException.Create('APhysics');
  if not Assigned(APlay) then
    raise EArgumentNilException.Create('APlay');
  if not Assigned(AMap) then
    raise EArgumentNilException.Create('AMap');
  if not Assigned(ATileInfo) then
    raise EArgumentNilException.Create('ATileInfo');
  FObjects := AObjects;
  FStates := AStates;
  FRandom := ARandom;
  FEvents := AEvents;
  FView := AView;
  FPhysics := APhysics;
  FPlay := APlay;
  FMap := AMap;
  FTileInfo := ATileInfo;
end;

function TKeenActionContext.GetObjects: IKeenObjectList;
begin
  Result := FObjects;
end;

function TKeenActionContext.GetStates: IKeenStateTable;
begin
  Result := FStates;
end;

function TKeenActionContext.GetRandom: IKeenRandom;
begin
  Result := FRandom;
end;

function TKeenActionContext.GetEvents: IKeenGameEvents;
begin
  Result := FEvents;
end;

function TKeenActionContext.GetView: IKeenActionView;
begin
  Result := FView;
end;

function TKeenActionContext.GetPhysics: IKeenActorPhysics;
begin
  Result := FPhysics;
end;

function TKeenActionContext.GetPlay: IKeenPlayState;
begin
  Result := FPlay;
end;

function TKeenActionContext.GetMap: IKeenWorkingMap;
begin
  Result := FMap;
end;

procedure TKeenActionContext.SetMap(const AMap: IKeenWorkingMap);
begin
  if not Assigned(AMap) then
    raise EArgumentNilException.Create('AMap');
  FMap := AMap;
end;

function TKeenActionContext.Tile(APlane, ATileX, ATileY: Integer): Integer;
begin
  if (ATileX < 0) or (ATileY < 0) or (ATileX >= FMap.Width) or (ATileY >= FMap.Height) then
    Exit(0);
  Result := FMap.Planes[APlane][ATileY * FMap.Width + ATileX];
end;

function TKeenActionContext.NorthWall(ATile: Integer): Integer;
begin
  if (ATile < 0) or (ATile >= KEEN_NUMTILE16M) then
    Exit(0);
  Result := FTileInfo.NorthWall(ATile);
end;

function TKeenActionContext.EastWall(ATile: Integer): Integer;
begin
  if (ATile < 0) or (ATile >= KEEN_NUMTILE16M) then
    Exit(0);
  Result := FTileInfo.EastWall(ATile);
end;

function TKeenActionContext.SouthWall(ATile: Integer): Integer;
begin
  if (ATile < 0) or (ATile >= KEEN_NUMTILE16M) then
    Exit(0);
  Result := FTileInfo.SouthWall(ATile);
end;

function TKeenActionContext.WestWall(ATile: Integer): Integer;
begin
  if (ATile < 0) or (ATile >= KEEN_NUMTILE16M) then
    Exit(0);
  Result := FTileInfo.WestWall(ATile);
end;

function TKeenActionContext.InTile(ATile: Integer): Integer;
begin
  if (ATile < 0) or (ATile >= KEEN_NUMTILE16M) then
    Exit(0);
  Result := FTileInfo.InTile(ATile);
end;

procedure TKeenActionContext.ChangeState(AObject: PKeenObject; AState: Integer);
var
  LState: TKeenStateDef;
begin
  LState := FStates[AState];
  AObject^.State := AState;
  AObject^.TicCount := 0;
  if LState.RightShape <> 0 then
  begin
    if AObject^.XDir > 0 then
      AObject^.ShapeNum := Word(LState.RightShape)
    else
      AObject^.ShapeNum := Word(LState.LeftShape);
  end;
  AObject^.XMove := 0;
  AObject^.YMove := 0;
  AObject^.NeedToReact := True; // it will need to be redrawn this frame
  FPhysics.ClipToWalls(AObject);
end;

procedure TKeenActionContext.DoGravity(AObject: PKeenObject);
var
  LTime: Integer;
  LLast: Integer;
begin
  // only accelerate on odd tics, because of limited precision
  LLast := FView.LastTimeCount;
  LTime := LLast - FView.Tics;
  while LTime < LLast do
  begin
    if (LTime and 1) <> 0 then
    begin
      if (AObject^.YSpeed < 0) and (AObject^.YSpeed >= -KEEN_ACCGRAVITY) then
      begin
        // stop at apex of jump
        AObject^.YMove := TKeenArithmetic.ToInt16(AObject^.YMove + AObject^.YSpeed);
        AObject^.YSpeed := 0;
        Exit;
      end;
      AObject^.YSpeed := TKeenArithmetic.ToInt16(AObject^.YSpeed + KEEN_ACCGRAVITY);
      if AObject^.YSpeed > KEEN_SPDMAXY then
        AObject^.YSpeed := KEEN_SPDMAXY;
    end;
    AObject^.YMove := TKeenArithmetic.ToInt16(AObject^.YMove + AObject^.YSpeed);
    Inc(LTime);
  end;
end;

procedure TKeenActionContext.AccelerateX(AObject: PKeenObject; ADirection, AMax: Integer);
var
  LTime: Integer;
  LLast: Integer;
  LOldDir: Word;
begin
  LOldDir := Word(AObject^.XSpeed) and $8000;
  LLast := FView.LastTimeCount;
  LTime := LLast - FView.Tics;
  while LTime < LLast do
  begin
    if (LTime and 1) <> 0 then
    begin
      AObject^.XSpeed := TKeenArithmetic.ToInt16(AObject^.XSpeed + ADirection);
      if (Word(AObject^.XSpeed) and $8000) <> LOldDir then
      begin
        LOldDir := Word(AObject^.XSpeed) and $8000;
        if LOldDir <> 0 then
          AObject^.XDir := -1
        else
          AObject^.XDir := 1;
      end;
      if AObject^.XSpeed > AMax then
        AObject^.XSpeed := TKeenArithmetic.ToInt16(AMax)
      else if AObject^.XSpeed < -AMax then
        AObject^.XSpeed := TKeenArithmetic.ToInt16(-AMax);
    end;
    AObject^.XMove := TKeenArithmetic.ToInt16(AObject^.XMove + AObject^.XSpeed);
    Inc(LTime);
  end;
end;

procedure TKeenActionContext.FrictionX(AObject: PKeenObject);
var
  LTime: Integer;
  LLast: Integer;
  LOldDir: Word;
  LDirection: Integer;
begin
  LOldDir := Word(AObject^.XSpeed) and $8000;
  if AObject^.XSpeed > 0 then
    LDirection := -1
  else if AObject^.XSpeed < 0 then
    LDirection := 1
  else
    LDirection := 0;
  LLast := FView.LastTimeCount;
  LTime := LLast - FView.Tics;
  while LTime < LLast do
  begin
    if (LTime and 1) <> 0 then
    begin
      AObject^.XSpeed := TKeenArithmetic.ToInt16(AObject^.XSpeed + LDirection);
      if (Word(AObject^.XSpeed) and $8000) <> LOldDir then
        AObject^.XSpeed := 0;
    end;
    AObject^.XMove := TKeenArithmetic.ToInt16(AObject^.XMove + AObject^.XSpeed);
    Inc(LTime);
  end;
end;

procedure TKeenActionContext.ProjectileThink(AObject: PKeenObject);
begin
  DoGravity(AObject);
  AObject^.XMove := TKeenArithmetic.ToInt16(FView.Tics * AObject^.XSpeed);
end;

procedure TKeenActionContext.PlaceSprite(AObject: PKeenObject; APriority: Integer);
begin
  FView.PlaceSprite(AObject^.Sprite, AObject^.X, AObject^.Y, AObject^.ShapeNum, APriority);
end;

function TKeenActionContext.BounceOffFloor(AObject: PKeenObject): Cardinal;
var
  LAbsX: Word;
  LAbsY: Word;
  LAngle: Integer;
  LSpeed: Cardinal;
  LNewAngle: Integer;
  LWall: Integer;
begin
  if AObject^.YSpeed < 0 then
    AObject^.YSpeed := 0;
  LAbsX := Word(Abs(Integer(AObject^.XSpeed)));
  LAbsY := Word(AObject^.YSpeed);
  // the products are unsigned 16 bit in the C, before they are widened
  if LAbsX > LAbsY then
  begin
    if LAbsX > TKeenArithmetic.ToWord(LAbsY * 2) then
    begin
      LAngle := 0; // 22 degrees
      LSpeed := TKeenArithmetic.ToWord(LAbsX * 286);
    end
    else
    begin
      LAngle := 1; // 45 degrees
      LSpeed := TKeenArithmetic.ToWord(LAbsX * 362);
    end;
  end
  else
  begin
    if LAbsY > TKeenArithmetic.ToWord(LAbsX * 2) then
    begin
      LAngle := 3; // 90 degrees
      LSpeed := TKeenArithmetic.ToWord(LAbsY * 256);
    end
    else
    begin
      LAngle := 2; // 67 degrees
      LSpeed := TKeenArithmetic.ToWord(LAbsY * 286);
    end;
  end;
  if AObject^.XSpeed > 0 then
    LAngle := 7 - LAngle;
  LSpeed := LSpeed shr 1;
  // bounceangle has 8 rows: the C reads past the table for a wall number of 8 or more, here the slope bits
  LWall := Word(AObject^.HitNorth) and 7;
  LNewAngle := BOUNCE_ANGLE[LWall * 8 + LAngle];
  case LNewAngle of
    0:
      begin
        AObject^.XSpeed := TKeenArithmetic.ToInt16(LSpeed div 286);
        AObject^.YSpeed := TKeenArithmetic.ToInt16(-Integer(AObject^.XSpeed) div 2);
      end;
    1:
      begin
        AObject^.XSpeed := TKeenArithmetic.ToInt16(LSpeed div 362);
        AObject^.YSpeed := TKeenArithmetic.ToInt16(-Integer(AObject^.XSpeed));
      end;
    2:
      begin
        AObject^.YSpeed := TKeenArithmetic.ToInt16(-Integer(LSpeed div 286));
        AObject^.XSpeed := TKeenArithmetic.ToInt16(-Integer(AObject^.YSpeed) div 2);
      end;
    3, 4:
      begin
        AObject^.XSpeed := 0;
        AObject^.YSpeed := TKeenArithmetic.ToInt16(-Integer(LSpeed div 256));
      end;
    5:
      begin
        AObject^.YSpeed := TKeenArithmetic.ToInt16(-Integer(LSpeed div 286));
        AObject^.XSpeed := TKeenArithmetic.ToInt16(Integer(AObject^.YSpeed) div 2);
      end;
    6:
      begin
        AObject^.YSpeed := TKeenArithmetic.ToInt16(-Integer(LSpeed div 362));
        AObject^.XSpeed := AObject^.YSpeed;
      end;
    7:
      begin
        AObject^.XSpeed := TKeenArithmetic.ToInt16(-Integer(LSpeed div 286));
        AObject^.YSpeed := TKeenArithmetic.ToInt16(Integer(AObject^.XSpeed) div 2);
      end;
    8:
      begin
        AObject^.XSpeed := TKeenArithmetic.ToInt16(-Integer(LSpeed div 286));
        AObject^.YSpeed := TKeenArithmetic.ToInt16(-Integer(AObject^.XSpeed) div 2);
      end;
    9:
      begin
        AObject^.XSpeed := TKeenArithmetic.ToInt16(-Integer(LSpeed div 362));
        AObject^.YSpeed := TKeenArithmetic.ToInt16(-Integer(AObject^.XSpeed));
      end;
    10:
      begin
        AObject^.YSpeed := TKeenArithmetic.ToInt16(LSpeed div 286);
        AObject^.XSpeed := TKeenArithmetic.ToInt16(-Integer(AObject^.YSpeed) div 2);
      end;
    11, 12:
      begin
        AObject^.XSpeed := 0;
        AObject^.YSpeed := TKeenArithmetic.ToInt16(-Integer(LSpeed div 256));
      end;
    13:
      begin
        AObject^.YSpeed := TKeenArithmetic.ToInt16(LSpeed div 286);
        AObject^.XSpeed := TKeenArithmetic.ToInt16(Integer(AObject^.YSpeed) div 2);
      end;
    14:
      begin
        AObject^.XSpeed := TKeenArithmetic.ToInt16(LSpeed div 362);
        AObject^.YSpeed := TKeenArithmetic.ToInt16(LSpeed div 362);
      end;
    15:
      begin
        AObject^.XSpeed := TKeenArithmetic.ToInt16(LSpeed div 286);
        AObject^.YSpeed := TKeenArithmetic.ToInt16(Integer(AObject^.XSpeed) div 2);
      end;
  end;
  Result := LSpeed;
end;

end.
