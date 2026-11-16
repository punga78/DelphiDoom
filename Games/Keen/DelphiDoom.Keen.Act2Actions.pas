{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the enemies of kd_act2.c                          }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  Tater Trooper, Cantaloupe Cart, Frenchy, Melon Lips, Squasher, Apel,         }
{  Pea Pod, Pea Brain and King Boobus Tuber                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Act2Actions;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf,
  DelphiDoom.Keen.UnmanagedObject;

type
  /// <summary>The think, react and spawn functions of the other enemies and of the shots</summary>
  TKeenAct2Actions = class(TKeenUnmanagedObject, IKeenActionGroup)
  strict private
    FContext: IKeenActionContext;
    function Difference(AFirst, ASecond: Word): Integer;
    procedure TaterThink(AObject: PKeenObject);
    procedure BackupReact(AObject: PKeenObject);
    procedure CartReact(AObject: PKeenObject);
    procedure FrenchyThink(AObject: PKeenObject);
    procedure FrenchyThrow(AObject: PKeenObject);
    procedure MelonSpitThink(AObject: PKeenObject);
    procedure ProjectileReact(AObject: PKeenObject);
    procedure SquasherThink(AObject: PKeenObject);
    procedure SquasherJumpReact(AObject: PKeenObject);
    procedure ApelThink(AObject: PKeenObject);
    procedure ApelClimbThink(AObject: PKeenObject);
    procedure ApelSlideThink(AObject: PKeenObject);
    procedure PeaPodThink(AObject: PKeenObject);
    procedure SpitPeaBrain(AObject: PKeenObject);
    procedure FragThink(AObject: PKeenObject);
    procedure FinishThink(AObject: PKeenObject);
    procedure BoobusThink(AObject: PKeenObject);
    procedure BoobusGroundReact(AObject: PKeenObject);
    procedure BoobusAirReact(AObject: PKeenObject);
  public
    constructor Create(const AContext: IKeenActionContext);
    function TryThink(AAction: Word; AObject: PKeenObject): Boolean;
    function TryContact(AAction: Word; AObject, AOther: PKeenObject): Boolean;
    function TryReact(AAction: Word; AObject: PKeenObject): Boolean;
    procedure SpawnTater(ATileX, ATileY: Integer);
    procedure SpawnCart(ATileX, ATileY: Integer);
    procedure SpawnFrenchy(ATileX, ATileY: Integer);
    procedure SpawnMelon(ATileX, ATileY, ADirection: Integer);
    procedure SpawnSquasher(ATileX, ATileY: Integer);
    procedure SpawnApel(ATileX, ATileY: Integer);
    procedure SpawnPeaPod(ATileX, ATileY: Integer);
    procedure SpawnPeaBrain(ATileX, ATileY: Integer);
    procedure SpawnBoobus(ATileX, ATileY: Integer);
  end;

implementation

uses
  DelphiDoom.Keen.ActionIds, DelphiDoom.Keen.AudioIds, DelphiDoom.Keen.StateTable, DelphiDoom.Keen.Arithmetic;

const
  FRY_X_SPEED = 40;
  FRY_Y_SPEED = -20;
  SPIT_X_SPEED = 48;
  SPIT_Y_SPEED = -20;
  SPD_SQUASH_LEAP_Y = 50;
  MAX_PEA_SPIT = 4;
  PEA_X_SPEED = 48;
  PEA_Y_SPEED = -20;
  PRE_FRAG_THINK = 60;
  POST_FRAG_THINK = 60;
  SPD_BOOBUS_JUMP = 60;
  SPD_BOOBUS_RUN_JUMP = 24;

{ TKeenAct2Actions }

constructor TKeenAct2Actions.Create(const AContext: IKeenActionContext);
begin
  inherited Create;
  if not Assigned(AContext) then
    raise EArgumentNilException.Create('AContext');
  FContext := AContext;
end;

function TKeenAct2Actions.Difference(AFirst, ASecond: Word): Integer;
begin
  // two unsigned numbers of the C, taken away and read as an int
  Result := TKeenArithmetic.ToInt16(Integer(AFirst) - Integer(ASecond));
end;

function TKeenAct2Actions.TryThink(AAction: Word; AObject: PKeenObject): Boolean;
begin
  Result := True;
  case AAction of
    KEEN_ACTION_TATERTHINK:
      TaterThink(AObject);
    KEEN_ACTION_FRENCHYTHINK:
      FrenchyThink(AObject);
    KEEN_ACTION_FRENCHYRUNTHINK:
      AObject^.State := KEEN_STATE_S_FRENCHYWALK1;
    KEEN_ACTION_FRENCHYTHROW:
      FrenchyThrow(AObject);
    KEEN_ACTION_MELONSPITTHINK:
      MelonSpitThink(AObject);
    KEEN_ACTION_SQUASHERTHINK:
      SquasherThink(AObject);
    KEEN_ACTION_APELTHINK:
      ApelThink(AObject);
    KEEN_ACTION_APELCLIMBTHINK:
      ApelClimbThink(AObject);
    KEEN_ACTION_APELSLIDETHINK:
      ApelSlideThink(AObject);
    KEEN_ACTION_PEABRAINTHINK:
      ; // PeaBrainThink does nothing
    KEEN_ACTION_PEAPODTHINK:
      PeaPodThink(AObject);
    KEEN_ACTION_SPITPEABRAIN:
      SpitPeaBrain(AObject);
    KEEN_ACTION_FRAGTHINK:
      FragThink(AObject);
    KEEN_ACTION_FINISHTHINK:
      FinishThink(AObject);
    KEEN_ACTION_BOOBUSTHINK:
      BoobusThink(AObject);
  else
    Result := False;
  end;
end;

function TKeenAct2Actions.TryContact(AAction: Word; AObject, AOther: PKeenObject): Boolean;
begin
  Result := False;
end;

function TKeenAct2Actions.TryReact(AAction: Word; AObject: PKeenObject): Boolean;
begin
  Result := True;
  case AAction of
    KEEN_ACTION_BACKUPREACT:
      BackupReact(AObject);
    KEEN_ACTION_CARTREACT:
      CartReact(AObject);
    KEEN_ACTION_PROJECTILEREACT:
      ProjectileReact(AObject);
    KEEN_ACTION_SQUASHERJUMPREACT:
      SquasherJumpReact(AObject);
    KEEN_ACTION_APELCLIMBREACT:
      begin
        if AObject^.HitSouth <> 0 then
          FContext.ChangeState(AObject, KEEN_STATE_S_APELFALL);
        FContext.PlaceSprite(AObject, 0);
      end;
    KEEN_ACTION_APELFALLREACT:
      begin
        if AObject^.HitNorth <> 0 then
          FContext.ChangeState(AObject, KEEN_STATE_S_APELWALK1);
        FContext.PlaceSprite(AObject, 0);
      end;
    KEEN_ACTION_PEAFLYREACT:
      begin
        if AObject^.HitNorth <> 0 then
          FContext.ChangeState(AObject, KEEN_STATE_S_PEABRAINWALK1);
        FContext.PlaceSprite(AObject, 0);
      end;
    KEEN_ACTION_BOOBUSGROUNDREACT:
      BoobusGroundReact(AObject);
    KEEN_ACTION_BOOBUSAIRREACT:
      BoobusAirReact(AObject);
  else
    Result := False;
  end;
end;

// ---- Tater Trooper ----

procedure TKeenAct2Actions.SpawnTater(ATileX, ATileY: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcTater;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord((ATileY shl 8) - 2 * KEEN_BLOCKSIZE + 15);
  LNew^.XDir := 1;
  LNew^.YDir := 1;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_TATERWALK1);
  LNew^.HitNorth := 1;
end;

procedure TKeenAct2Actions.TaterThink(AObject: PKeenObject);
var
  LPlayer: PKeenObject;
  LDelta: Integer;
begin
  LPlayer := FContext.Objects.Player;
  if (AObject^.Top > LPlayer^.Bottom) or (AObject^.Bottom < LPlayer^.Top) then
    Exit;
  if AObject^.XDir = -1 then
  begin
    LDelta := Difference(AObject^.Left, LPlayer^.Right);
    if LDelta > KEEN_TILEGLOBAL then
      Exit;
    if LDelta < -8 * KEEN_PIXGLOBAL then
    begin
      AObject^.XDir := 1;
      Exit;
    end;
  end
  else
  begin
    LDelta := Difference(LPlayer^.Left, AObject^.Right);
    if LDelta > KEEN_TILEGLOBAL then
      Exit;
    if LDelta < -8 * KEEN_PIXGLOBAL then
    begin
      AObject^.XDir := -1;
      Exit;
    end;
  end;
  FContext.Events.PlaySound(KEEN_SND_TATERSWINGSND);
  AObject^.State := KEEN_STATE_S_TATERATTACK1;
end;

procedure TKeenAct2Actions.BackupReact(AObject: PKeenObject);
begin
  if AObject^.HitNorth = 0 then
  begin
    AObject^.X := TKeenArithmetic.ToWord(AObject^.X - AObject^.XMove);
    AObject^.Y := TKeenArithmetic.ToWord(AObject^.Y - AObject^.YMove);
  end;
  FContext.PlaceSprite(AObject, 0);
end;

// ---- Cantaloupe Cart ----

procedure TKeenAct2Actions.SpawnCart(ATileX, ATileY: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcCart;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord((ATileY shl 8) - 3 * KEEN_PIXGLOBAL);
  LNew^.XDir := 1;
  LNew^.YDir := 1;
  LNew^.Active := kaAllways;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_CARTROLL1);
end;

procedure TKeenAct2Actions.CartReact(AObject: PKeenObject);
var
  LColumn: Integer;
begin
  if (AObject^.XDir = 1) and (AObject^.HitWest <> 0) then
    AObject^.XDir := -1
  else if (AObject^.XDir = -1) and (AObject^.HitEast <> 0) then
    AObject^.XDir := 1;
  if AObject^.XDir = 1 then
    LColumn := AObject^.TileRight
  else
    LColumn := AObject^.TileLeft;
  if FContext.NorthWall(FContext.Tile(1, LColumn, Integer(AObject^.TileBottom) + 1)) = 0 then
    AObject^.XDir := -AObject^.XDir;
  FContext.PlaceSprite(AObject, 0);
end;

// ---- Frenchy ----

procedure TKeenAct2Actions.SpawnFrenchy(ATileX, ATileY: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcFrenchy;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord((ATileY shl 8) - 2 * KEEN_BLOCKSIZE);
  LNew^.XDir := 1;
  LNew^.YDir := 1;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_FRENCHYWALK1);
end;

procedure TKeenAct2Actions.FrenchyThrow(AObject: PKeenObject);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(True);
  LNew^.ObClass := kcShot;
  if AObject^.XDir = 1 then
  begin
    LNew^.X := TKeenArithmetic.ToWord(AObject^.X + 24 * 16);
    LNew^.Y := TKeenArithmetic.ToWord(AObject^.Y + 8 * 16);
  end
  else
  begin
    LNew^.X := AObject^.X;
    LNew^.Y := TKeenArithmetic.ToWord(AObject^.Y + 8 * 16);
  end;
  LNew^.XDir := AObject^.XDir;
  LNew^.YDir := 1;
  LNew^.XSpeed := TKeenArithmetic.ToInt16(AObject^.XDir * FRY_X_SPEED - (FContext.Random.RndT shr 4));
  LNew^.YSpeed := FRY_Y_SPEED;
  LNew^.Active := kaRemovable;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_FRY1);
  AObject^.NoThink := 2;
end;

procedure TKeenAct2Actions.FrenchyThink(AObject: PKeenObject);
var
  LDelta: Integer;
  LPlayer: PKeenObject;
begin
  LPlayer := FContext.Objects.Player;
  if Abs(Difference(AObject^.Y, LPlayer^.Y)) > 3 * KEEN_TILEGLOBAL then
  begin
    if FContext.Random.RndT < 8 then
      AObject^.XDir := -AObject^.XDir; // turn randomly
    Exit;
  end;
  LDelta := Difference(LPlayer^.X, AObject^.X);
  if LDelta < -8 * KEEN_TILEGLOBAL then
    AObject^.XDir := -1; // walk closer
  if LDelta < -4 * KEEN_TILEGLOBAL then
  begin
    // throw
    AObject^.XDir := -1;
    AObject^.State := KEEN_STATE_S_FRENCHYTHROW1;
  end
  else if LDelta < 0 then
  begin
    // run away
    AObject^.XDir := 1;
    AObject^.State := KEEN_STATE_S_FRENCHYRUN1;
    AObject^.NoThink := 8;
  end
  else if LDelta < 4 * KEEN_TILEGLOBAL then
  begin
    // run away
    AObject^.XDir := -1;
    AObject^.State := KEEN_STATE_S_FRENCHYRUN1;
    AObject^.NoThink := 8;
  end
  else if LDelta < 8 * KEEN_TILEGLOBAL then
  begin
    // throw and walk closer
    AObject^.XDir := 1;
    AObject^.State := KEEN_STATE_S_FRENCHYTHROW1;
  end
  else
    AObject^.XDir := 1; // walk closer
end;

// ---- Melon Lips ----

procedure TKeenAct2Actions.SpawnMelon(ATileX, ATileY, ADirection: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcMelon;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord(ATileY shl 8);
  if ADirection <> 0 then
    LNew^.XDir := 1
  else
    LNew^.XDir := -1;
  if ADirection < 2 then
    FContext.Physics.NewState(LNew, KEEN_STATE_S_MELONSIDE)
  else
    FContext.Physics.NewState(LNew, KEEN_STATE_S_MELONDOWN);
  LNew^.TicCount := FContext.Random.RndT shr 1;
  LNew^.Temp1 := ADirection;
end;

procedure TKeenAct2Actions.MelonSpitThink(AObject: PKeenObject);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcShot;
  case AObject^.Temp1 of
    0:
      begin
        LNew^.X := TKeenArithmetic.ToWord(AObject^.X + 24 * 16);
        LNew^.Y := TKeenArithmetic.ToWord(AObject^.Y + 8 * 16);
        LNew^.XDir := AObject^.XDir;
        LNew^.YDir := 1;
        LNew^.XSpeed := TKeenArithmetic.ToInt16(-SPIT_X_SPEED - (FContext.Random.RndT shr 4));
        LNew^.YSpeed := SPIT_Y_SPEED;
        FContext.Physics.NewState(LNew, KEEN_STATE_S_MELONSEED1);
      end;
    1:
      begin
        LNew^.X := AObject^.X;
        LNew^.Y := TKeenArithmetic.ToWord(AObject^.Y + 8 * 16);
        LNew^.XDir := AObject^.XDir;
        LNew^.YDir := 1;
        LNew^.XSpeed := TKeenArithmetic.ToInt16(SPIT_X_SPEED + (FContext.Random.RndT shr 4));
        LNew^.YSpeed := SPIT_Y_SPEED;
        FContext.Physics.NewState(LNew, KEEN_STATE_S_MELONSEED1);
      end;
    2:
      begin
        LNew^.X := TKeenArithmetic.ToWord(AObject^.X + 8 * 16);
        LNew^.Y := TKeenArithmetic.ToWord(AObject^.Y + 24 * 16);
        LNew^.YDir := 1;
        LNew^.YSpeed := -SPIT_Y_SPEED;
        FContext.Physics.NewState(LNew, KEEN_STATE_S_MELONSEEDD1);
      end;
  end;
  LNew^.Active := kaRemovable;
end;

procedure TKeenAct2Actions.ProjectileReact(AObject: PKeenObject);
begin
  FContext.PlaceSprite(AObject, 0);
  if (AObject^.HitEast <> 0) or (AObject^.HitWest <> 0) then
    AObject^.XSpeed := TKeenArithmetic.ToInt16(-Integer(AObject^.XSpeed) div 2);
  if AObject^.HitSouth <> 0 then
    AObject^.YSpeed := TKeenArithmetic.ToInt16(-Integer(AObject^.YSpeed) div 2);
  if AObject^.HitNorth <> 0 then
    if FContext.BounceOffFloor(AObject) < 256 * 16 then
      FContext.Objects.RemoveObj(AObject);
end;

// ---- Squasher ----

procedure TKeenAct2Actions.SpawnSquasher(ATileX, ATileY: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcSquash;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord((ATileY shl 8) - 2 * KEEN_BLOCKSIZE);
  LNew^.XDir := 1;
  LNew^.YDir := 1;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_SQUASHERWALK1);
end;

procedure TKeenAct2Actions.SquasherThink(AObject: PKeenObject);
var
  LDelta: Integer;
  LPlayer: PKeenObject;
begin
  LPlayer := FContext.Objects.Player;
  if Abs(Difference(AObject^.Y, LPlayer^.Y)) > 3 * KEEN_TILEGLOBAL then
  begin
    if FContext.Random.RndT < 8 then
      AObject^.XDir := -AObject^.XDir; // turn randomly
    Exit;
  end;
  LDelta := Difference(LPlayer^.X, AObject^.X);
  if AObject^.XDir = -1 then
  begin
    if LDelta < -6 * KEEN_TILEGLOBAL then
      Exit;
    if LDelta > 8 * KEEN_PIXGLOBAL then
    begin
      AObject^.XDir := 1;
      Exit;
    end;
  end
  else
  begin
    if LDelta > 6 * KEEN_TILEGLOBAL then
      Exit;
    if LDelta < -8 * KEEN_PIXGLOBAL then
    begin
      AObject^.XDir := 1; // the C turns it to the right here too
      Exit;
    end;
  end;
  AObject^.YSpeed := -SPD_SQUASH_LEAP_Y;
  AObject^.XSpeed := TKeenArithmetic.ToInt16(LDelta div 60);
  AObject^.State := KEEN_STATE_S_SQUASHERJUMP1;
end;

procedure TKeenAct2Actions.SquasherJumpReact(AObject: PKeenObject);
begin
  if AObject^.HitSouth <> 0 then
    AObject^.YSpeed := 0;
  if AObject^.HitNorth <> 0 then
    FContext.ChangeState(AObject, KEEN_STATE_S_SQUASHERWAIT);
  FContext.PlaceSprite(AObject, 0);
end;

// ---- Apel ----

procedure TKeenAct2Actions.SpawnApel(ATileX, ATileY: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcApel;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord((ATileY shl 8) - 2 * KEEN_BLOCKSIZE);
  LNew^.XDir := 1;
  LNew^.YDir := 1;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_APELWALK1);
end;

procedure TKeenAct2Actions.ApelThink(AObject: PKeenObject);
var
  LPlayer: PKeenObject;
  LRow: Integer;
begin
  LPlayer := FContext.Objects.Player;
  if (AObject^.Top > LPlayer^.Bottom) or (AObject^.Bottom < LPlayer^.Top) then
  begin
    // try to climb a pole to reach the player
    if AObject^.Y < LPlayer^.Y then
      LRow := AObject^.TileBottom
    else
      LRow := AObject^.TileTop;
    if (FContext.InTile(FContext.Tile(1, AObject^.TileMidX, LRow)) and $7F) = 1 then
    begin
      AObject^.XMove := TKeenArithmetic.ToInt16((Integer(AObject^.TileMidX) shl 8) - Integer(AObject^.X));
      AObject^.YMove := 0;
      AObject^.Temp4 := AObject^.TileMidX; // for future reference
      AObject^.NeedToClip := False; // can climb through pole holes
      if AObject^.Y < LPlayer^.Y then
        AObject^.State := KEEN_STATE_S_APELSLIDE1
      else
        AObject^.State := KEEN_STATE_S_APELCLIMB1;
      Exit;
    end;
  end;
  if FContext.Random.RndT > 32 then
    Exit; // do not turn around all the time
  if AObject^.X < LPlayer^.X then
    AObject^.XDir := 1
  else
    AObject^.XDir := -1;
end;

procedure TKeenAct2Actions.ApelClimbThink(AObject: PKeenObject);
begin
  if (FContext.InTile(FContext.Tile(1, AObject^.Temp4, AObject^.TileTop)) and $7F) <> 1 then
  begin
    AObject^.NeedToClip := True;
    AObject^.State := KEEN_STATE_S_APELFALL;
  end;
end;

procedure TKeenAct2Actions.ApelSlideThink(AObject: PKeenObject);
begin
  if (FContext.InTile(FContext.Tile(1, AObject^.Temp4, AObject^.TileBottom)) and $7F) <> 1 then
  begin
    AObject^.NeedToClip := True;
    AObject^.State := KEEN_STATE_S_APELFALL;
  end;
end;

// ---- Pea Brain and Pea Pod ----

procedure TKeenAct2Actions.SpawnPeaBrain(ATileX, ATileY: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcPeaBrain;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord(ATileY shl 8);
  FContext.Physics.NewState(LNew, KEEN_STATE_S_PEABRAINWALK1);
end;

procedure TKeenAct2Actions.SpawnPeaPod(ATileX, ATileY: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcPeaPod;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord((ATileY shl 8) - 2 * KEEN_BLOCKSIZE);
  LNew^.XDir := 1;
  LNew^.YDir := 1;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_PEAPODWALK1);
end;

procedure TKeenAct2Actions.SpitPeaBrain(AObject: PKeenObject);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(True);
  LNew^.ObClass := kcPeaBrain;
  if AObject^.XDir = 1 then
  begin
    LNew^.X := TKeenArithmetic.ToWord(AObject^.X + 8 * 16);
    LNew^.Y := TKeenArithmetic.ToWord(AObject^.Y + 8 * 16);
  end
  else
  begin
    LNew^.X := AObject^.X;
    LNew^.Y := TKeenArithmetic.ToWord(AObject^.Y + 8 * 16);
  end;
  LNew^.XDir := AObject^.XDir;
  LNew^.YDir := 1;
  LNew^.XSpeed := TKeenArithmetic.ToInt16(AObject^.XDir * PEA_X_SPEED - (FContext.Random.RndT shr 4));
  LNew^.YSpeed := PEA_Y_SPEED;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_PEABRAINFLY);
end;

procedure TKeenAct2Actions.PeaPodThink(AObject: PKeenObject);
var
  LPlayer: PKeenObject;
begin
  LPlayer := FContext.Objects.Player;
  if Abs(Difference(AObject^.Y, LPlayer^.Y)) > 3 * KEEN_TILEGLOBAL then
    Exit;
  if (LPlayer^.X < AObject^.X) and (AObject^.XDir = 1) then
    Exit;
  if (LPlayer^.X > AObject^.X) and (AObject^.XDir = -1) then
    Exit;
  if (FContext.Random.RndT < 8) and (AObject^.Temp1 < MAX_PEA_SPIT) then
  begin
    Inc(AObject^.Temp1);
    AObject^.State := KEEN_STATE_S_PEAPODSPIT1;
    AObject^.XMove := 0;
  end;
end;

// ---- King Boobus Tuber ----

procedure TKeenAct2Actions.SpawnBoobus(ATileX, ATileY: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcBoobus;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord((ATileY shl 8) - 11 * KEEN_BLOCKSIZE);
  LNew^.XDir := -1;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_BOOBUSWALK1);
  LNew^.Temp4 := 12; // hit points
end;

procedure TKeenAct2Actions.FragThink(AObject: PKeenObject);
var
  LNew: PKeenObject;
begin
  Inc(AObject^.Temp1);
  if AObject^.Temp1 = PRE_FRAG_THINK then
    AObject^.State := KEEN_STATE_S_BOOBUSDIE2;
  Inc(AObject^.Temp1);
  if AObject^.Temp1 = POST_FRAG_THINK then
  begin
    FContext.View.RemoveSprite(AObject^.Sprite);
    AObject^.State := KEEN_STATE_S_BOOBUSDIE3;
  end;
  FContext.Events.PlaySound(KEEN_SND_BOMBBOOMSND);
  LNew := FContext.Objects.GetNewObj(True);
  LNew^.X := TKeenArithmetic.ToWord(AObject^.X - KEEN_BLOCKSIZE + 5 * FContext.Random.RndT);
  LNew^.Y := TKeenArithmetic.ToWord(AObject^.Y - KEEN_BLOCKSIZE + 5 * FContext.Random.RndT);
  LNew^.XSpeed := 0;
  LNew^.YSpeed := 0;
  FContext.Random.RndT; // keep rnd from even wrapping
  FContext.ChangeState(LNew, KEEN_STATE_S_DEATHBOOM1);
end;

procedure TKeenAct2Actions.FinishThink(AObject: PKeenObject);
begin
  FContext.Play.PlayState := keVictorious;
  FContext.Events.PlaySound(KEEN_SND_BOOBUSGONESND);
end;

procedure TKeenAct2Actions.BoobusThink(AObject: PKeenObject);
var
  LPlayer: PKeenObject;
  LInLine: Boolean;
begin
  LPlayer := FContext.Objects.Player;
  LInLine := False;
  if AObject^.Left > LPlayer^.Right then
    AObject^.XDir := -1
  else if AObject^.Right < LPlayer^.Left then
    AObject^.XDir := 1
  else
    LInLine := True;
  if (LPlayer^.Top < AObject^.Bottom) and (LPlayer^.Bottom > AObject^.Top) then
    Exit; // on the same level as the player, so it charges
  // above or below the player: get directly in line and jump
  if not LInLine then
    Exit;
  if AObject^.Y < LPlayer^.Y then
  begin
    // drop down
    Inc(AObject^.TileBottom);
    AObject^.Bottom := TKeenArithmetic.ToWord(AObject^.Bottom + 8 * KEEN_PIXGLOBAL);
    AObject^.Y := TKeenArithmetic.ToWord(AObject^.Y + 8 * KEEN_PIXGLOBAL);
    AObject^.State := KEEN_STATE_S_BOOBUSJUMP;
    AObject^.YSpeed := 0;
    AObject^.XMove := 0;
    AObject^.XSpeed := 0;
    AObject^.YMove := 0;
  end
  else
  begin
    // jump up
    AObject^.State := KEEN_STATE_S_BOOBUSJUMP;
    AObject^.YSpeed := -SPD_BOOBUS_JUMP;
    AObject^.XSpeed := 0;
  end;
end;

procedure TKeenAct2Actions.BoobusGroundReact(AObject: PKeenObject);
begin
  if (AObject^.XDir = 1) and (AObject^.HitWest <> 0) then
  begin
    AObject^.X := TKeenArithmetic.ToWord(AObject^.X - AObject^.XMove);
    AObject^.XDir := -1;
    AObject^.NoThink := FContext.Random.RndT shr 5;
    FContext.ChangeState(AObject, AObject^.State);
  end
  else if (AObject^.XDir = -1) and (AObject^.HitEast <> 0) then
  begin
    AObject^.X := TKeenArithmetic.ToWord(AObject^.X - AObject^.XMove);
    AObject^.XDir := 1;
    AObject^.NoThink := FContext.Random.RndT shr 5;
    FContext.ChangeState(AObject, AObject^.State);
  end
  else if AObject^.HitNorth = 0 then
  begin
    if AObject^.Bottom >= FContext.Objects.Player^.Bottom then
    begin
      // jump over
      AObject^.X := TKeenArithmetic.ToWord(AObject^.X - AObject^.XMove);
      AObject^.Y := TKeenArithmetic.ToWord(AObject^.Y - AObject^.YMove);
      AObject^.YSpeed := -SPD_BOOBUS_JUMP;
      AObject^.XSpeed := TKeenArithmetic.ToInt16(AObject^.XDir * SPD_BOOBUS_RUN_JUMP);
    end
    else
    begin
      // drop down
      AObject^.XSpeed := 0;
      AObject^.YSpeed := 0;
    end;
    FContext.ChangeState(AObject, KEEN_STATE_S_BOOBUSJUMP);
  end;
  FContext.PlaceSprite(AObject, 0);
end;

procedure TKeenAct2Actions.BoobusAirReact(AObject: PKeenObject);
begin
  if AObject^.HitSouth <> 0 then
    AObject^.YSpeed := 0;
  if AObject^.HitNorth <> 0 then
    FContext.ChangeState(AObject, KEEN_STATE_S_BOOBUSWALK1);
  FContext.PlaceSprite(AObject, 0);
end;

end.
