{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - Keen, the player                                  }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  the think, contact and react functions, the flower power and SpawnKeen of    }
{  kd_keen.c, and the mini Keen of the world map                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.PlayerActions;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.InputTypes, DelphiDoom.Keen.Intf,
  DelphiDoom.Keen.UnmanagedObject, DelphiDoom.Keen.ScoreBox;

type
  /// <summary>
  ///   The functions of the player: standing, walking, jumping, the pole, throwing the flower power, what happens
  ///   when he touches another actor, the mini Keen on the map of the world and the flower power and bomb that
  ///   he throws. jumptime and leavepoletime, the two variables of kd_keen.c, are fields
  /// </summary>
  TKeenPlayerActions = class(TKeenUnmanagedObject, IKeenActionGroup)
  strict private
    FContext: IKeenActionContext;
    FFlowers: IKeenFlowerChanger;
    FScoreBox: TKeenScoreBox;
    FJumpTime: Integer;
    FLeavePoleTime: Integer;
    function Hold: TKeenControlInfo;
    procedure ThrowPower(AX, AY: Word; ADirection: TKeenDirection);
    procedure PowerCount(AObject: PKeenObject);
    procedure PowerContact(AObject, AHit: PKeenObject);
    procedure PowerReact(AObject: PKeenObject);
    procedure CheckEnterLevel(AObject: PKeenObject);
    procedure KeenWorldThink(AObject: PKeenObject);
    procedure KeenWorldWalk(AObject: PKeenObject);
    function CheckGrabPole(AObject: PKeenObject): Boolean;
    procedure KeenStandThink(AObject: PKeenObject);
    procedure KeenPauseThink(AObject: PKeenObject);
    procedure KeenGoSleepThink(AObject: PKeenObject);
    procedure KeenSleepThink(AObject: PKeenObject);
    procedure KeenDuckThink(AObject: PKeenObject);
    procedure KeenWalkThink(AObject: PKeenObject);
    procedure KeenAirThink(AObject: PKeenObject);
    procedure PoleActions(AObject: PKeenObject);
    procedure KeenPoleThink(AObject: PKeenObject);
    procedure KeenClimbThink(AObject: PKeenObject);
    procedure KeenDropThink(AObject: PKeenObject);
    procedure KeenThrow(AObject: PKeenObject);
    procedure KeenContact(AObject, AHit: PKeenObject);
    procedure KeenStandReact(AObject: PKeenObject);
    procedure KeenWalkReact(AObject: PKeenObject);
    procedure KeenAirReact(AObject: PKeenObject);
    procedure PushedOffPole(AObject: PKeenObject);
  public
    /// <param name="AFlowers">What a flower power calls to change an enemy into a flower</param>
    constructor Create(const AContext: IKeenActionContext; const AFlowers: IKeenFlowerChanger;
      const AGraphics: IKeenGraphics; const ASprites: IKeenSpriteCache);
    destructor Destroy; override;
    /// <summary>The score box that this player owns</summary>
    property ScoreBox: TKeenScoreBox read FScoreBox;
    function TryThink(AAction: Word; AObject: PKeenObject): Boolean;
    function TryContact(AAction: Word; AObject, AOther: PKeenObject): Boolean;
    function TryReact(AAction: Word; AObject: PKeenObject): Boolean;
    procedure SpawnKeen(ATileX, ATileY, ADirection: Integer);
    procedure SpawnWorldKeen(ATileX, ATileY: Integer);
    /// <summary>KillKeen: the player dies (nothing happens in god mode)</summary>
    procedure KillKeen;
    /// <summary>jumptime of kd_keen.c: the tics of the jump that are left</summary>
    property JumpTime: Integer read FJumpTime write FJumpTime;
    /// <summary>leavepoletime of kd_keen.c: TimeCount when Keen jumped off a pole</summary>
    property LeavePoleTime: Integer read FLeavePoleTime write FLeavePoleTime;
  end;

implementation

uses
  DelphiDoom.Keen.ActionIds, DelphiDoom.Keen.AudioIds, DelphiDoom.Keen.GraphicsIds, DelphiDoom.Keen.StateTable,
  DelphiDoom.Keen.Arithmetic;

const
  MIN_POLE_JUMP_TICS = 19;
  SPD_RUN_JUMP = 16;
  SPD_POLE_SIDE_JUMP = 8;
  WALK_AIR_SPEED = 8;
  JUMP_TIME = 16;
  POLE_JUMP_TIME = 10;
  SPD_JUMP = 40;
  SPD_POLE_JUMP = 20;
  SPD_POWER_UP = -64;
  SPD_POWER = 64;
  SPD_POWER_Y = -20;
  POWER_COUNT = 50;
  MAX_X_SPEED = 24;
  KEEN_PRIORITY = 1;

  SLOPE_SPEED: array[0..7] of Integer = (0, 0, 4, 4, 8, -4, -4, -8);
  POLE_X_SPEED: array[0..2] of Integer = (-SPD_POLE_SIDE_JUMP, 0, SPD_POLE_SIDE_JUMP);
  BONUS_POINTS: array[0..5] of Integer = (100, 200, 500, 1000, 2000, 5000);
  WORLD_SHAPES: array[0..7] of Integer = (KEEN_GFX_WORLDKEENU1SPR - 1, KEEN_GFX_WORLDKEENUR1SPR - 1,
    KEEN_GFX_WORLDKEENR1SPR - 1, KEEN_GFX_WORLDKEENDR1SPR - 1, KEEN_GFX_WORLDKEEND1SPR - 1,
    KEEN_GFX_WORLDKEENDL1SPR - 1, KEEN_GFX_WORLDKEENL1SPR - 1, KEEN_GFX_WORLDKEENUL1SPR - 1);
  WORLD_ANIMS: array[0..3] of Integer = (2, 3, 1, 3);

{ TKeenPlayerActions }

constructor TKeenPlayerActions.Create(const AContext: IKeenActionContext; const AFlowers: IKeenFlowerChanger;
  const AGraphics: IKeenGraphics; const ASprites: IKeenSpriteCache);
begin
  inherited Create;
  if not Assigned(AContext) then
    raise EArgumentNilException.Create('AContext');
  if not Assigned(AFlowers) then
    raise EArgumentNilException.Create('AFlowers');
  FContext := AContext;
  FFlowers := AFlowers;
  FScoreBox := TKeenScoreBox.Create(AContext, AGraphics, ASprites);
end;

destructor TKeenPlayerActions.Destroy;
begin
  FScoreBox.Free;
  inherited Destroy;
end;

function TKeenPlayerActions.Hold: TKeenControlInfo;
begin
  Result := FContext.Play.Control;
end;

function TKeenPlayerActions.TryThink(AAction: Word; AObject: PKeenObject): Boolean;
begin
  Result := True;
  case AAction of
    KEEN_ACTION_SCORETHINK:
      FScoreBox.ScoreThink(AObject);
    KEEN_ACTION_POWERCOUNT:
      PowerCount(AObject);
    KEEN_ACTION_KEENWORLDTHINK:
      KeenWorldThink(AObject);
    KEEN_ACTION_KEENWORLDWALK:
      KeenWorldWalk(AObject);
    KEEN_ACTION_KEENSTANDTHINK:
      KeenStandThink(AObject);
    KEEN_ACTION_KEENPAUSETHINK:
      KeenPauseThink(AObject);
    KEEN_ACTION_KEENGOSLEEPTHINK:
      KeenGoSleepThink(AObject);
    KEEN_ACTION_KEENSLEEPTHINK:
      KeenSleepThink(AObject);
    KEEN_ACTION_KEENDIETHINK:
      FContext.Play.PlayState := keDied;
    KEEN_ACTION_KEENDUCKTHINK:
      KeenDuckThink(AObject);
    KEEN_ACTION_KEENDROPDOWNTHINK:
      AObject^.NeedToClip := True;
    KEEN_ACTION_KEENWALKTHINK:
      KeenWalkThink(AObject);
    KEEN_ACTION_KEENAIRTHINK:
      KeenAirThink(AObject);
    KEEN_ACTION_KEENPOLETHINK:
      KeenPoleThink(AObject);
    KEEN_ACTION_KEENCLIMBTHINK:
      KeenClimbThink(AObject);
    KEEN_ACTION_KEENDROPTHINK:
      KeenDropThink(AObject);
    KEEN_ACTION_KEENTHROW:
      KeenThrow(AObject);
  else
    Result := False;
  end;
end;

function TKeenPlayerActions.TryContact(AAction: Word; AObject, AOther: PKeenObject): Boolean;
begin
  Result := True;
  case AAction of
    KEEN_ACTION_KEENCONTACT:
      KeenContact(AObject, AOther);
    KEEN_ACTION_POWERCONTACT:
      PowerContact(AObject, AOther);
  else
    Result := False;
  end;
end;

function TKeenPlayerActions.TryReact(AAction: Word; AObject: PKeenObject): Boolean;
begin
  Result := True;
  case AAction of
    KEEN_ACTION_SCOREREACT:
      FScoreBox.ScoreReact(AObject);
    KEEN_ACTION_POWERREACT:
      PowerReact(AObject);
    KEEN_ACTION_KEENSIMPLEREACT:
      FContext.PlaceSprite(AObject, KEEN_PRIORITY);
    KEEN_ACTION_KEENSTANDREACT:
      KeenStandReact(AObject);
    KEEN_ACTION_KEENWALKREACT:
      KeenWalkReact(AObject);
    KEEN_ACTION_KEENAIRREACT:
      KeenAirReact(AObject);
  else
    Result := False;
  end;
end;

// ---- flower power and bombs ----

procedure TKeenPlayerActions.ThrowPower(AX, AY: Word; ADirection: TKeenDirection);
var
  LState: PKeenGameState;
  LNew: PKeenObject;
begin
  LState := FContext.Play.GameState;
  if FContext.Play.MapOn = 15 then
  begin
    if LState^.BoobusBombs = 0 then
    begin
      FContext.Events.PlaySound(KEEN_SND_NOWAYSND);
      Exit; // no bombs to throw
    end;
    FContext.Events.PlaySound(KEEN_SND_THROWBOMBSND);
    Dec(LState^.BombsThisLevel);
    Dec(LState^.BoobusBombs);
  end
  else
  begin
    if LState^.FlowerPowers = 0 then
    begin
      FContext.Events.PlaySound(KEEN_SND_NOWAYSND);
      Exit; // no flower power to throw
    end;
    FContext.Events.PlaySound(KEEN_SND_THROWSND);
    Dec(LState^.FlowerPowers);
  end;
  LNew := FContext.Objects.GetNewObj(True);
  LNew^.ObClass := kcPower;
  LNew^.Temp2 := Ord(ADirection);
  LNew^.X := AX;
  LNew^.Y := AY;
  LNew^.TileLeft := AX shr 8;
  LNew^.TileRight := AX shr 8;
  LNew^.TileTop := AY shr 8;
  LNew^.TileBottom := AY shr 8;
  LNew^.YDir := -1;
  case ADirection of
    kdNorth:
      begin
        LNew^.XSpeed := 0;
        LNew^.YSpeed := SPD_POWER_UP;
      end;
    kdEast:
      begin
        LNew^.XSpeed := SPD_POWER;
        LNew^.YSpeed := SPD_POWER_Y;
      end;
    kdSouth:
      begin
        LNew^.XSpeed := 0;
        LNew^.YSpeed := SPD_POWER;
      end;
    kdWest:
      begin
        LNew^.XSpeed := -SPD_POWER;
        LNew^.YSpeed := SPD_POWER_Y;
      end;
  else
    raise EKeenException.Create('ThrowPower: Bad dir!');
  end;
  LNew^.Active := kaRemovable;
  if FContext.Play.MapOn <> 15 then
  begin
    LNew^.Temp1 := 8; // flower power bonus
    FContext.Physics.NewState(LNew, KEEN_STATE_S_FLOWERPOWER1);
  end
  else
  begin
    LNew^.Temp1 := 10; // boobus bomb bonus
    FContext.Physics.NewState(LNew, KEEN_STATE_S_BOOBUSBOMB1);
  end;
end;

procedure TKeenPlayerActions.PowerCount(AObject: PKeenObject);
begin
  AObject^.Temp2 := TKeenArithmetic.ToInt16(AObject^.Temp2 + FContext.View.Tics);
  AObject^.ShapeNum := 0;
  if AObject^.Temp2 > POWER_COUNT then
    FContext.Objects.RemoveObj(AObject);
end;

procedure TKeenPlayerActions.PowerContact(AObject, AHit: PKeenObject);
begin
  case AHit^.ObClass of
    kcBrocco, kcTomat, kcCarrot, kcCelery, kcAspar, kcTater, kcFrenchy, kcSquash, kcApel, kcPeaPod, kcPeaBrain:
      begin
        FFlowers.ChangeToFlower(AHit);
        FContext.Objects.RemoveObj(AObject);
      end;
    kcBoobus:
      begin
        Dec(AHit^.Temp4);
        if AHit^.Temp4 = 0 then
        begin
          // killed boobus
          FContext.Play.GivePoints(50000);
          FContext.Play.GivePoints(50000);
          AHit^.ObClass := kcInert;
          FContext.ChangeState(AHit, KEEN_STATE_S_BOOBUSDIE);
          AHit^.Temp1 := 0; // death count
        end;
        FContext.Events.PlaySound(KEEN_SND_BOMBBOOMSND);
        FContext.ChangeState(AObject, KEEN_STATE_S_BOMBEXPLODE);
      end;
  end;
end;

procedure TKeenPlayerActions.PowerReact(AObject: PKeenObject);
var
  LSpeed: Cardinal;
begin
  FContext.PlaceSprite(AObject, KEEN_PRIORITY);
  if (AObject^.HitEast <> 0) or (AObject^.HitWest <> 0) then
  begin
    AObject^.XSpeed := TKeenArithmetic.ToInt16(-Integer(AObject^.XSpeed) div 2);
    AObject^.ObClass := kcBonus;
  end;
  if AObject^.HitSouth <> 0 then
  begin
    if AObject^.HitSouth = 17 then
    begin
      // go through pole holes
      if AObject^.Temp2 <> Ord(kdNorth) then
        AObject^.ObClass := kcBonus;
      AObject^.Top := TKeenArithmetic.ToWord(AObject^.Top - 32);
      AObject^.Y := TKeenArithmetic.ToWord(AObject^.Y - 32);
      AObject^.XSpeed := 0;
      AObject^.X := TKeenArithmetic.ToWord(AObject^.TileMidX * KEEN_TILEGLOBAL + 4 * KEEN_PIXGLOBAL);
    end
    else
      AObject^.YSpeed := TKeenArithmetic.ToInt16(-Integer(AObject^.YSpeed) div 2);
    Exit;
  end;
  if AObject^.HitNorth = 17 then
  begin
    // go through pole holes
    if AObject^.Temp2 <> Ord(kdSouth) then
      AObject^.ObClass := kcBonus;
    AObject^.Bottom := TKeenArithmetic.ToWord(AObject^.Bottom + 32);
    AObject^.Y := TKeenArithmetic.ToWord(AObject^.Y + 32);
    AObject^.XSpeed := 0;
    AObject^.X := TKeenArithmetic.ToWord(AObject^.TileMidX * KEEN_TILEGLOBAL + 4 * KEEN_PIXGLOBAL);
  end
  else if AObject^.HitNorth <> 0 then
  begin
    AObject^.ObClass := kcBonus;
    LSpeed := FContext.BounceOffFloor(AObject);
    if LSpeed < 256 * 16 then
    begin
      if FContext.Play.MapOn = 15 then
      begin
        AObject^.YDir := -1; // bonus stuff flies up when touched
        AObject^.ShapeNum := KEEN_GFX_BOOBUSBOMB1SPR;
        AObject^.Temp2 := KEEN_GFX_BOOBUSBOMB1SPR;
        AObject^.Temp3 := AObject^.Temp2 + 2;
        AObject^.NeedToClip := False;
        FContext.ChangeState(AObject, KEEN_STATE_S_BONUS);
      end
      else
      begin
        FContext.ChangeState(AObject, KEEN_STATE_S_POWERBLINK1);
        AObject^.NeedToClip := False;
        AObject^.Temp2 := 0; // blink time
      end;
    end;
  end;
end;

// ---- the mini Keen of the world map ----

procedure TKeenPlayerActions.SpawnWorldKeen(ATileX, ATileY: Integer);
var
  LPlayer: PKeenObject;
  LState: PKeenGameState;
begin
  LPlayer := FContext.Objects.Player;
  LState := FContext.Play.GameState;
  LPlayer^.ObClass := kcKeen;
  if LState^.WorldX = 0 then
  begin
    LPlayer^.X := TKeenArithmetic.ToWord(ATileX shl 8);
    LPlayer^.Y := TKeenArithmetic.ToWord(ATileY shl 8);
  end
  else
  begin
    LPlayer^.X := LState^.WorldX;
    LPlayer^.Y := LState^.WorldY;
  end;
  LPlayer^.Active := kaYes;
  LPlayer^.NeedToClip := True;
  LPlayer^.XDir := 0;
  LPlayer^.YDir := 0;
  LPlayer^.Temp1 := Ord(kdWest);
  LPlayer^.Temp2 := 3;
  LPlayer^.ShapeNum := 3 + KEEN_GFX_WORLDKEENL1SPR - 1; // feet together
  FContext.Physics.NewState(LPlayer, KEEN_STATE_S_WORLDKEEN);
end;

procedure TKeenPlayerActions.CheckEnterLevel(AObject: PKeenObject);
var
  LX: Integer;
  LY: Integer;
  LTile: Integer;
  LState: PKeenGameState;
begin
  LState := FContext.Play.GameState;
  for LY := AObject^.TileTop to AObject^.TileBottom do
    for LX := AObject^.TileLeft to AObject^.TileRight do
    begin
      LTile := FContext.Tile(2, LX, LY);
      if (LTile >= 3) and (LTile <= 18) then
      begin
        // enter level!
        if LTile = 17 then
          if LState^.BoobusBombs < 12 then
          begin
            FContext.Events.ShowNeedBombs;
            Exit;
          end;
        LState^.WorldX := AObject^.X;
        LState^.WorldY := AObject^.Y;
        LState^.MapOn := LTile - 2;
        FContext.Play.PlayState := keLevelComplete;
        FContext.Events.PlaySound(KEEN_SND_ENTERLEVELSND);
      end;
    end;
end;

procedure TKeenPlayerActions.KeenWorldThink(AObject: PKeenObject);
var
  LControl: TKeenControlInfo;
begin
  LControl := Hold;
  if LControl.Direction <> kdNone then
  begin
    AObject^.State := KEEN_STATE_S_WORLDWALK;
    AObject^.Temp2 := 0;
    KeenWorldWalk(AObject);
  end;
  LControl := Hold;
  if LControl.Button0 or LControl.Button1 then
    CheckEnterLevel(AObject);
end;

procedure TKeenPlayerActions.KeenWorldWalk(AObject: PKeenObject);
var
  LControl: TKeenControlInfo;
begin
  LControl := Hold;
  AObject^.XDir := LControl.XAxis;
  AObject^.YDir := LControl.YAxis;
  Inc(AObject^.Temp2);
  if AObject^.Temp2 = 4 then
    AObject^.Temp2 := 0;
  if LControl.Button0 or LControl.Button1 then
    CheckEnterLevel(AObject);
  if LControl.Direction = kdNone then
  begin
    AObject^.State := KEEN_STATE_S_WORLDKEEN;
    AObject^.ShapeNum := Word(WORLD_SHAPES[AObject^.Temp1 and 7] + 3);
    Exit;
  end;
  AObject^.Temp1 := Ord(LControl.Direction);
  AObject^.ShapeNum := Word(WORLD_SHAPES[AObject^.Temp1] + WORLD_ANIMS[AObject^.Temp2 and 3]);
end;

// ---- Keen in the levels ----

procedure TKeenPlayerActions.SpawnKeen(ATileX, ATileY, ADirection: Integer);
var
  LPlayer: PKeenObject;
begin
  LPlayer := FContext.Objects.Player;
  LPlayer^.ObClass := kcKeen;
  LPlayer^.Active := kaYes;
  LPlayer^.NeedToClip := True;
  LPlayer^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LPlayer^.Y := TKeenArithmetic.ToWord((ATileY shl 8) - KEEN_BLOCKSIZE * 2);
  LPlayer^.XDir := ADirection;
  LPlayer^.YDir := 1;
  FContext.Physics.NewState(LPlayer, KEEN_STATE_S_KEENSTAND);
end;

function TKeenPlayerActions.CheckGrabPole(AObject: PKeenObject): Boolean;
var
  LControl: TKeenControlInfo;
  LRow: Integer;
  LX: Integer;
  LNow: Integer;
begin
  Result := False;
  LControl := Hold;
  // kludgy bit to not let you grab a pole the instant you jump off it
  LNow := FContext.View.TimeCount;
  if LNow < FLeavePoleTime then
    FLeavePoleTime := 0
  else if LNow - FLeavePoleTime < MIN_POLE_JUMP_TICS then
    Exit;
  if LControl.YAxis = -1 then
    LRow := TKeenArithmetic.ToWord(AObject^.Top + 6 * KEEN_PIXGLOBAL) div KEEN_TILEGLOBAL
  else
    LRow := AObject^.TileBottom;
  LX := TKeenArithmetic.ToWord(AObject^.Left + TKeenArithmetic.ToWord(AObject^.Right - AObject^.Left) div 2) shr 8;
  if (FContext.InTile(FContext.Tile(1, LX, LRow)) and $7F) = 1 then
  begin
    AObject^.XMove := TKeenArithmetic.ToInt16(((LX shl 8) - 8 * KEEN_PIXGLOBAL) - Integer(AObject^.X));
    AObject^.YMove := TKeenArithmetic.ToInt16(LControl.YAxis * 32);
    AObject^.Temp4 := LX; // for future reference
    AObject^.NeedToClip := False; // can climb through pole holes
    AObject^.State := KEEN_STATE_S_KEENPOLE;
    Result := True;
  end;
end;

procedure TKeenPlayerActions.KeenStandThink(AObject: PKeenObject);
var
  LControl: TKeenControlInfo;
  LPlay: IKeenPlayState;
begin
  LPlay := FContext.Play;
  LControl := LPlay.Control;
  if LControl.XAxis <> 0 then
  begin
    // started walking
    AObject^.XDir := LControl.XAxis;
    AObject^.State := KEEN_STATE_S_KEENWALK1;
    AObject^.XMove := TKeenArithmetic.ToInt16(AObject^.XDir * FContext.States[KEEN_STATE_S_KEENWALK1].XMove *
      FContext.View.Tics);
    KeenWalkThink(AObject);
    Exit;
  end;
  if LControl.Button0 and not LPlay.Button0Held then
  begin
    // jump straight up
    FContext.Events.PlaySound(KEEN_SND_JUMPSND);
    AObject^.XSpeed := 0;
    AObject^.YSpeed := -SPD_JUMP;
    AObject^.XMove := 0;
    AObject^.YMove := 0;
    FJumpTime := JUMP_TIME;
    AObject^.State := KEEN_STATE_S_KEENJUMPUP1;
    LPlay.Button0Held := True;
    Exit;
  end;
  if LControl.Button1 and not LPlay.Button1Held then
  begin
    // throw current xdir
    if LControl.YAxis = -1 then
      AObject^.State := KEEN_STATE_S_KEENTHROWUP1
    else
      AObject^.State := KEEN_STATE_S_KEENTHROW1;
    LPlay.Button1Held := True;
    Exit;
  end;
  case LControl.YAxis of
    -1:
      if not CheckGrabPole(AObject) then // try to go up/down pole first
        AObject^.State := KEEN_STATE_S_KEENLOOKUP;
    0:
      AObject^.State := KEEN_STATE_S_KEENSTAND;
    1:
      if not CheckGrabPole(AObject) then
        AObject^.State := KEEN_STATE_S_KEENDUCK;
  end;
end;

procedure TKeenPlayerActions.KeenPauseThink(AObject: PKeenObject);
var
  LControl: TKeenControlInfo;
  LNext: Integer;
  LLimit: Integer;
begin
  LControl := Hold;
  if (LControl.Direction <> kdNone) or LControl.Button0 or LControl.Button1 then
  begin
    AObject^.Temp1 := 0;
    AObject^.Temp2 := 0; // not paused any more
    AObject^.State := KEEN_STATE_S_KEENSTAND;
    KeenStandThink(AObject);
    Exit;
  end;
  if (Word(AObject^.HitNorth) and not 7) <> 24 then // if it is 0 now, keen is standing on a sprite
    AObject^.Temp1 := TKeenArithmetic.ToInt16(AObject^.Temp1 + FContext.View.Tics);
  case AObject^.Temp2 of
    0:
      begin
        LLimit := 200;
        LNext := KEEN_STATE_S_KEENPAUSELOOK;
      end;
    1:
      begin
        LLimit := 300;
        LNext := KEEN_STATE_S_KEENWAIT1;
      end;
    2:
      begin
        LLimit := 700;
        LNext := KEEN_STATE_S_KEENYAWN1;
      end;
    3:
      begin
        LLimit := 400;
        LNext := KEEN_STATE_S_KEENPAUSELOOK;
      end;
    4:
      begin
        LLimit := 700;
        LNext := KEEN_STATE_S_KEENYAWN1;
      end;
    5:
      begin
        LLimit := 400;
        LNext := KEEN_STATE_S_KEENGOSLEEP1;
      end;
  else
    Exit;
  end;
  if AObject^.Temp1 > LLimit then
  begin
    Inc(AObject^.Temp2);
    AObject^.State := LNext;
    if AObject^.Temp2 <> 6 then // the last stage (to sleep) does not clear the time
      AObject^.Temp1 := 0;
  end;
end;

procedure TKeenPlayerActions.KeenGoSleepThink(AObject: PKeenObject);
var
  LNew: PKeenObject;
  LPlayer: PKeenObject;
begin
  // spawn the zees above keens head
  LNew := FContext.Objects.GetNewObj(True);
  LPlayer := FContext.Objects.Player;
  LNew^.ObClass := kcInert;
  LNew^.X := LPlayer^.X;
  LNew^.Y := TKeenArithmetic.ToWord(LPlayer^.Y - 4 * KEEN_PIXGLOBAL);
  LNew^.XDir := 1;
  LNew^.YDir := -1;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_KEENZEE1);
  AObject^.Temp1 := LNew^.Slot; // so they can be removed later
end;

procedure TKeenPlayerActions.KeenSleepThink(AObject: PKeenObject);
var
  LControl: TKeenControlInfo;
begin
  LControl := Hold;
  if (LControl.Direction <> kdNone) or LControl.Button0 or LControl.Button1 then
  begin
    if AObject^.Temp1 <> KEEN_DUMMY_SLOT then
      FContext.Objects.RemoveObj(FContext.Objects[AObject^.Temp1]); // remove the zees
    AObject^.Temp1 := 0;
    AObject^.Temp2 := 0; // not paused any more
    AObject^.State := KEEN_STATE_S_KEENGETUP;
  end;
end;

procedure TKeenPlayerActions.KeenDuckThink(AObject: PKeenObject);
var
  LControl: TKeenControlInfo;
  LPlay: IKeenPlayState;
  LMidTile: Integer;
  LBottomTile: Integer;
  LMove: Integer;
  LRow: Integer;
begin
  LPlay := FContext.Play;
  LControl := LPlay.Control;
  if LControl.YAxis <> 1 then
  begin
    AObject^.State := KEEN_STATE_S_KEENSTAND;
    KeenStandThink(AObject);
    Exit;
  end;
  if LControl.XAxis <> 0 then
    AObject^.XDir := LControl.XAxis;
  if LControl.Button0 and not LPlay.Button0Held then
  begin
    // drop down a level
    LPlay.Button0Held := True;
    LMidTile := (Integer(AObject^.TileLeft) + Integer(AObject^.TileRight)) shr 1;
    LBottomTile := AObject^.TileBottom;
    for LRow := LBottomTile to LBottomTile + 1 do
      if (FContext.WestWall(FContext.Tile(1, LMidTile, LRow)) <> 0) or
        (FContext.EastWall(FContext.Tile(1, LMidTile, LRow)) <> 0) or
        (FContext.SouthWall(FContext.Tile(1, LMidTile, LRow)) <> 0) then
        Exit; // a wall prevents the drop down
    if FContext.View.Tics < 4 then
      LMove := KEEN_PIXGLOBAL * 4
    else
      LMove := KEEN_PIXGLOBAL * FContext.View.Tics;
    AObject^.Bottom := TKeenArithmetic.ToWord(AObject^.Bottom + LMove);
    AObject^.Y := TKeenArithmetic.ToWord(AObject^.Y + LMove);
    AObject^.XMove := 0;
    AObject^.YMove := 0;
    AObject^.State := KEEN_STATE_S_KEENJUMPUP3;
    AObject^.Temp2 := 1; // already in the last stage
    AObject^.XSpeed := 0;
    AObject^.YSpeed := 0;
    FContext.Events.PlaySound(KEEN_SND_PLUMMETSND);
  end;
end;

procedure TKeenPlayerActions.KeenWalkThink(AObject: PKeenObject);
var
  LControl: TKeenControlInfo;
  LPlay: IKeenPlayState;
begin
  LPlay := FContext.Play;
  LControl := LPlay.Control;
  if LControl.XAxis = 0 then
  begin
    // stopped running
    KeenStandThink(AObject);
    Exit;
  end;
  AObject^.XDir := LControl.XAxis;
  if (LControl.YAxis <> 0) and CheckGrabPole(AObject) then // try to go up/down pole
    Exit;
  if LControl.Button0 and not LPlay.Button0Held then
  begin
    // running jump
    FContext.Events.PlaySound(KEEN_SND_JUMPSND);
    AObject^.XSpeed := TKeenArithmetic.ToInt16(AObject^.XDir * SPD_RUN_JUMP);
    AObject^.YSpeed := -SPD_JUMP;
    AObject^.XMove := 0;
    AObject^.YMove := 0;
    LPlay.Button0Held := True;
    FJumpTime := JUMP_TIME;
    AObject^.State := KEEN_STATE_S_KEENJUMP1;
  end;
  if LControl.Button1 and not LPlay.Button1Held then
  begin
    // throw
    AObject^.State := KEEN_STATE_S_KEENTHROW1;
    LPlay.Button1Held := True;
    Exit;
  end;
  // give speed for slopes
  AObject^.XMove := TKeenArithmetic.ToInt16(AObject^.XMove + FContext.View.Tics * SLOPE_SPEED[AObject^.HitNorth and 7]);
end;

procedure TKeenPlayerActions.KeenAirThink(AObject: PKeenObject);
var
  LControl: TKeenControlInfo;
  LPlay: IKeenPlayState;
  LTics: Integer;
begin
  LPlay := FContext.Play;
  LControl := LPlay.Control;
  LTics := FContext.View.Tics;
  if FJumpTime <> 0 then
  begin
    // jumptime is an int and tics an unsigned: the comparison is unsigned
    if Word(FJumpTime) < Word(LTics) then
    begin
      AObject^.YMove := TKeenArithmetic.ToInt16(AObject^.YSpeed * FJumpTime);
      FJumpTime := 0;
    end
    else
    begin
      AObject^.YMove := TKeenArithmetic.ToInt16(AObject^.YSpeed * LTics);
      if not FContext.Events.IsJumpCheat then
        Dec(FJumpTime, LTics);
    end;
    if not LControl.Button0 then
      FJumpTime := 0;
    if FJumpTime = 0 then
    begin
      AObject^.Temp2 := 0;
      AObject^.State := FContext.States[AObject^.State].NextState; // switch to second jump stage
    end;
  end
  else
  begin
    FContext.DoGravity(AObject);
    if (AObject^.YSpeed > 0) and (AObject^.Temp2 = 0) then
    begin
      AObject^.State := FContext.States[AObject^.State].NextState; // switch to third jump stage
      AObject^.Temp2 := 1;
    end;
  end;
  if LControl.XAxis <> 0 then
  begin
    AObject^.XDir := LControl.XAxis;
    FContext.AccelerateX(AObject, LControl.XAxis * 2, MAX_X_SPEED);
  end
  else
    FContext.FrictionX(AObject);
  if LControl.Button1 and not LPlay.Button1Held then
  begin
    LPlay.Button1Held := True;
    // throw
    case LControl.YAxis of
      -1:
        begin
          AObject^.State := KEEN_STATE_S_KEENAIRTHROWUP1;
          Exit;
        end;
      0:
        begin
          AObject^.State := KEEN_STATE_S_KEENAIRTHROW1;
          Exit;
        end;
      1:
        begin
          AObject^.State := KEEN_STATE_S_KEENAIRTHROWDOWN1;
          Exit;
        end;
    end;
  end;
  if AObject^.HitSouth = 17 then
  begin
    // going through a pole hole
    AObject^.XSpeed := 0;
    AObject^.XMove := 0;
  end;
  if LControl.YAxis = -1 then
    CheckGrabPole(AObject);
end;

procedure TKeenPlayerActions.PoleActions(AObject: PKeenObject);
var
  LControl: TKeenControlInfo;
  LPlay: IKeenPlayState;
begin
  LPlay := FContext.Play;
  LControl := LPlay.Control;
  if LControl.XAxis <> 0 then
    AObject^.XDir := LControl.XAxis;
  if LControl.Button0 and not LPlay.Button0Held then
  begin
    // jump off the pole
    FContext.Events.PlaySound(KEEN_SND_JUMPSND);
    AObject^.XSpeed := POLE_X_SPEED[LControl.XAxis + 1];
    AObject^.YSpeed := -SPD_POLE_JUMP;
    AObject^.NeedToClip := True;
    FJumpTime := POLE_JUMP_TIME;
    AObject^.State := KEEN_STATE_S_KEENJUMP1;
    AObject^.YDir := 1;
    LPlay.Button0Held := True;
    FLeavePoleTime := FContext.View.TimeCount;
    Exit;
  end;
  if LControl.Button1 and not LPlay.Button1Held then
  begin
    LPlay.Button1Held := True;
    case LControl.YAxis of
      -1:
        AObject^.State := KEEN_STATE_S_KEENPOLETHROWUP1;
      0:
        AObject^.State := KEEN_STATE_S_KEENPOLETHROW1;
      1:
        AObject^.State := KEEN_STATE_S_KEENPOLETHROWDOWN1;
    end;
  end;
end;

procedure TKeenPlayerActions.KeenPoleThink(AObject: PKeenObject);
var
  LControl: TKeenControlInfo;
begin
  LControl := Hold;
  case LControl.YAxis of
    -1:
      begin
        AObject^.State := KEEN_STATE_S_KEENCLIMB1;
        AObject^.YDir := -1;
        Exit;
      end;
    1:
      begin
        AObject^.State := KEEN_STATE_S_KEENSLIDE1;
        AObject^.YDir := 1;
        KeenDropThink(AObject);
        Exit;
      end;
  end;
  if LControl.XAxis <> 0 then
  begin
    // walk off the pole if right next to the ground
    if FContext.NorthWall(FContext.Tile(1, AObject^.TileMidX, Integer(AObject^.TileBottom) + 1)) <> 0 then
    begin
      AObject^.XSpeed := 0;
      AObject^.YSpeed := 0;
      AObject^.NeedToClip := True;
      FJumpTime := 0;
      AObject^.State := KEEN_STATE_S_KEENJUMP3;
      AObject^.YDir := 1;
      FContext.Events.PlaySound(KEEN_SND_PLUMMETSND);
      Exit;
    end;
  end;
  PoleActions(AObject);
end;

procedure TKeenPlayerActions.KeenClimbThink(AObject: PKeenObject);
var
  LControl: TKeenControlInfo;
begin
  LControl := Hold;
  if (FContext.InTile(FContext.Tile(1, AObject^.Temp4, AObject^.TileTop)) and $7F) <> 1 then
  begin
    AObject^.YMove := 0;
    AObject^.State := KEEN_STATE_S_KEENPOLE; // ran out of pole
    Exit;
  end;
  case LControl.YAxis of
    0:
      begin
        AObject^.State := KEEN_STATE_S_KEENPOLE;
        AObject^.YDir := 0;
      end;
    1:
      begin
        AObject^.State := KEEN_STATE_S_KEENSLIDE1;
        AObject^.YDir := 1;
        KeenDropThink(AObject);
      end;
  end;
  PoleActions(AObject);
end;

procedure TKeenPlayerActions.KeenDropThink(AObject: PKeenObject);
var
  LControl: TKeenControlInfo;
begin
  LControl := Hold;
  if (FContext.InTile(FContext.Tile(1, AObject^.Temp4, AObject^.TileBottom)) and $7F) <> 1 then
  begin
    FContext.Events.PlaySound(KEEN_SND_PLUMMETSND);
    AObject^.State := KEEN_STATE_S_KEENJUMP3; // ran out of pole
    FJumpTime := 0;
    AObject^.Temp2 := 1;
    AObject^.XSpeed := POLE_X_SPEED[LControl.XAxis + 1];
    AObject^.YSpeed := 0;
    AObject^.NeedToClip := True;
    Dec(AObject^.TileBottom);
    Exit;
  end;
  case LControl.YAxis of
    -1:
      begin
        AObject^.State := KEEN_STATE_S_KEENCLIMB1;
        AObject^.YDir := -1;
      end;
    0:
      begin
        AObject^.State := KEEN_STATE_S_KEENPOLE;
        AObject^.YDir := 0;
      end;
  end;
  PoleActions(AObject);
end;

procedure TKeenPlayerActions.KeenThrow(AObject: PKeenObject);
var
  LState: Integer;
  LNew: PKeenObject;
  LRight: Boolean;
begin
  LState := AObject^.State;
  LRight := AObject^.XDir > 0;
  if LState = KEEN_STATE_S_KEENTHROW3 then
  begin
    if LRight then
      ThrowPower(TKeenArithmetic.ToWord(AObject^.MidX - 4 * KEEN_PIXGLOBAL),
        TKeenArithmetic.ToWord(AObject^.Y + 8 * KEEN_PIXGLOBAL), kdEast)
    else
      ThrowPower(TKeenArithmetic.ToWord(AObject^.MidX - 4 * KEEN_PIXGLOBAL),
        TKeenArithmetic.ToWord(AObject^.Y + 8 * KEEN_PIXGLOBAL), kdWest);
  end
  else if LState = KEEN_STATE_S_KEENPOLETHROW2 then
  begin
    if LRight then
      ThrowPower(TKeenArithmetic.ToWord(AObject^.X + 24 * KEEN_PIXGLOBAL), AObject^.Y, kdEast)
    else
      ThrowPower(TKeenArithmetic.ToWord(AObject^.X - 8 * KEEN_PIXGLOBAL), AObject^.Y, kdWest);
  end
  else if LState = KEEN_STATE_S_KEENTHROWUP2 then
    ThrowPower(TKeenArithmetic.ToWord(AObject^.X + 4 * KEEN_PIXGLOBAL),
      TKeenArithmetic.ToWord(AObject^.Y - 8 * KEEN_PIXGLOBAL), kdNorth)
  else if LState = KEEN_STATE_S_KEENPOLETHROWUP2 then
    ThrowPower(TKeenArithmetic.ToWord(AObject^.X + 8 * KEEN_PIXGLOBAL),
      TKeenArithmetic.ToWord(AObject^.Y - 8 * KEEN_PIXGLOBAL), kdNorth)
  else if LState = KEEN_STATE_S_KEENPOLETHROWDOWN2 then
    ThrowPower(TKeenArithmetic.ToWord(AObject^.X + 8 * KEEN_PIXGLOBAL),
      TKeenArithmetic.ToWord(AObject^.Y + 8 * KEEN_PIXGLOBAL), kdSouth)
  else if (LState = KEEN_STATE_S_KEENAIRTHROW2) or (LState = KEEN_STATE_S_KEENAIRTHROWUP2) or
    (LState = KEEN_STATE_S_KEENAIRTHROWDOWN2) then
  begin
    if LState = KEEN_STATE_S_KEENAIRTHROW2 then
    begin
      if LRight then
        ThrowPower(TKeenArithmetic.ToWord(AObject^.MidX - 4 * KEEN_PIXGLOBAL),
          TKeenArithmetic.ToWord(AObject^.Y + 8 * KEEN_PIXGLOBAL), kdEast)
      else
        ThrowPower(TKeenArithmetic.ToWord(AObject^.MidX - 4 * KEEN_PIXGLOBAL),
          TKeenArithmetic.ToWord(AObject^.Y + 8 * KEEN_PIXGLOBAL), kdWest);
    end
    else if LState = KEEN_STATE_S_KEENAIRTHROWUP2 then
    begin
      if LRight then
        ThrowPower(TKeenArithmetic.ToWord(AObject^.X + 16 * KEEN_PIXGLOBAL), AObject^.Y, kdNorth)
      else
        ThrowPower(TKeenArithmetic.ToWord(AObject^.X + 4 * KEEN_PIXGLOBAL), AObject^.Y, kdNorth);
    end
    else
    begin
      if LRight then
        ThrowPower(TKeenArithmetic.ToWord(AObject^.X + 3 * KEEN_PIXGLOBAL),
          TKeenArithmetic.ToWord(AObject^.Y + 16 * KEEN_PIXGLOBAL), kdSouth)
      else
        ThrowPower(TKeenArithmetic.ToWord(AObject^.X + 12 * KEEN_PIXGLOBAL),
          TKeenArithmetic.ToWord(AObject^.Y + 16 * KEEN_PIXGLOBAL), kdSouth);
    end;
    // the C changes "new", that is the last actor made, even if no power was thrown (no flowers left)
    LNew := FContext.Objects.New;
    LNew^.XSpeed := TKeenArithmetic.ToInt16(LNew^.XSpeed + AObject^.XSpeed div 2);
    LNew^.YSpeed := TKeenArithmetic.ToInt16(LNew^.YSpeed + AObject^.YSpeed div 2);
  end
  else
    raise EKeenException.Create('KeenThrow: Bad state!');
end;

// ---- contact ----

procedure TKeenPlayerActions.KillKeen;
var
  LPlayer: PKeenObject;
begin
  if FContext.Events.IsGodMode then
    Exit;
  FContext.Events.PlaySound(KEEN_SND_WAKEUPSND);
  LPlayer := FContext.Objects.Player;
  LPlayer^.NeedToClip := False;
  FContext.ChangeState(LPlayer, KEEN_STATE_S_KEENDIE1);
end;

procedure TKeenPlayerActions.PushedOffPole(AObject: PKeenObject);
begin
  if not AObject^.NeedToClip then
  begin
    // got pushed off a pole
    FContext.Events.PlaySound(KEEN_SND_PLUMMETSND);
    AObject^.NeedToClip := True;
    AObject^.XSpeed := 0;
    AObject^.YSpeed := 0;
    FContext.ChangeState(AObject, KEEN_STATE_S_KEENJUMP3);
    AObject^.Temp2 := 1;
    FJumpTime := 0;
  end;
end;

procedure TKeenPlayerActions.KeenContact(AObject, AHit: PKeenObject);
var
  LState: PKeenGameState;
  LEvents: IKeenGameEvents;
begin
  LState := FContext.Play.GameState;
  LEvents := FContext.Events;
  case AHit^.ObClass of
    kcBonus:
      begin
        AHit^.ObClass := kcInert;
        case AHit^.Temp1 of
          0..5:
            begin
              LEvents.PlaySound(KEEN_SND_GETPOINTSSND);
              AHit^.ShapeNum := Word(KEEN_GFX_BONUS100SPR + AHit^.Temp1);
              FContext.Play.GivePoints(BONUS_POINTS[AHit^.Temp1]);
              FContext.ChangeState(AHit, KEEN_STATE_S_BONUSRISE);
            end;
          6:
            begin
              LEvents.PlaySound(KEEN_SND_EXTRAKEENSND);
              AHit^.ShapeNum := KEEN_GFX_BONUS1UPSPR;
              Inc(LState^.Lives);
              FContext.ChangeState(AHit, KEEN_STATE_S_BONUSRISE);
            end;
          7:
            begin
              LEvents.PlaySound(KEEN_SND_EXTRAKEENSND);
              AHit^.ShapeNum := KEEN_GFX_BONUSSUPERSPR;
              Inc(LState^.Lives, 3);
              Inc(LState^.FlowerPowers, 8);
              FContext.Play.GivePoints(10000);
              FContext.ChangeState(AHit, KEEN_STATE_S_BONUSRISE);
            end;
          8:
            begin
              LEvents.PlaySound(KEEN_SND_GETPOWERSND);
              AHit^.ShapeNum := KEEN_GFX_BONUSFLOWERSPR;
              Inc(LState^.FlowerPowers);
              FContext.ChangeState(AHit, KEEN_STATE_S_BONUSRISE);
            end;
          9:
            begin
              LEvents.PlaySound(KEEN_SND_GETPOWERSND);
              AHit^.ShapeNum := KEEN_GFX_BONUSFLOWERUPSPR;
              Inc(LState^.FlowerPowers, 5);
              FContext.ChangeState(AHit, KEEN_STATE_S_BONUSRISE);
            end;
          10:
            begin
              LEvents.PlaySound(KEEN_SND_GETBOMBSND);
              AHit^.ShapeNum := KEEN_GFX_BONUSBOMBSPR;
              Inc(LState^.BoobusBombs);
              Inc(LState^.BombsThisLevel);
              FContext.ChangeState(AHit, KEEN_STATE_S_BONUSRISE);
            end;
          11:
            begin
              LEvents.PlaySound(KEEN_SND_GETKEYSND);
              AHit^.ShapeNum := KEEN_GFX_BONUSKEYSPR;
              Inc(LState^.Keys);
              FContext.ChangeState(AHit, KEEN_STATE_S_BONUSRISE);
            end;
        end;
      end;
    kcDoor:
      if LState^.Keys <> 0 then
      begin
        if AHit^.State <> KEEN_STATE_S_DOORRAISE then
        begin
          LEvents.PlaySound(KEEN_SND_OPENDOORSND);
          Dec(LState^.Keys);
          FContext.ChangeState(AHit, KEEN_STATE_S_DOORRAISE);
        end;
      end
      else
      begin
        LEvents.PlaySound(KEEN_SND_NOWAYSND);
        FContext.Physics.ClipToSpriteSide(AObject, AHit);
      end;
    kcTater:
      if AHit^.State = KEEN_STATE_S_TATERATTACK2 then
        KillKeen;
    kcCarrot:
      begin
        FContext.Physics.ClipToSpriteSide(AObject, AHit);
        PushedOffPole(AObject);
      end;
    kcCart:
      FContext.Physics.ClipToSprite(AObject, AHit, True);
    kcBrocco:
      if (AHit^.State = KEEN_STATE_S_BROCCOSMASH3) or (AHit^.State = KEEN_STATE_S_BROCCOSMASH4) then
        KillKeen;
    kcSquash:
      if AHit^.State = KEEN_STATE_S_SQUASHERJUMP2 then
        KillKeen
      else
      begin
        FContext.Physics.ClipToSpriteSide(AObject, AHit);
        PushedOffPole(AObject);
      end;
    kcGrape:
      if AHit^.State = KEEN_STATE_S_GRAPEFALL then
        KillKeen;
    kcTomat, kcCelery, kcAspar, kcTurnip, kcCauli, kcBrussel, kcMushroom, kcApel, kcPeaBrain, kcBoobus, kcShot:
      KillKeen;
  end;
end;

// ---- reaction ----

procedure TKeenPlayerActions.KeenStandReact(AObject: PKeenObject);
begin
  if AObject^.HitNorth = 0 then
  begin
    // walked off an edge
    FContext.Events.PlaySound(KEEN_SND_PLUMMETSND);
    AObject^.XSpeed := TKeenArithmetic.ToInt16(AObject^.XDir * WALK_AIR_SPEED);
    FContext.ChangeState(AObject, KEEN_STATE_S_KEENJUMP3);
    AObject^.Temp2 := 1;
    FJumpTime := 0;
  end
  else if (Word(AObject^.HitNorth) and not 7) = 8 then // deadly floor!
    KillKeen;
  FContext.PlaceSprite(AObject, KEEN_PRIORITY);
end;

procedure TKeenPlayerActions.KeenWalkReact(AObject: PKeenObject);
begin
  if AObject^.HitNorth = 0 then
  begin
    // walked off an edge
    AObject^.XSpeed := TKeenArithmetic.ToInt16(AObject^.XDir * WALK_AIR_SPEED);
    AObject^.YSpeed := 0;
    FContext.ChangeState(AObject, KEEN_STATE_S_KEENJUMP3);
    AObject^.Temp2 := 1;
    FJumpTime := 0;
  end
  else if (Word(AObject^.HitNorth) and not 7) = 8 then // deadly floor!
  begin
    KillKeen;
    FContext.PlaceSprite(AObject, KEEN_PRIORITY);
    Exit;
  end;
  if AObject^.HitEast = 2 then
    // doors
  else if AObject^.HitWest = 2 then
    // doors
  else if (AObject^.HitEast <> 0) or (AObject^.HitWest <> 0) then
  begin
    // ran into a wall
    AObject^.TicCount := 0;
    AObject^.State := KEEN_STATE_S_KEENSTAND;
    if AObject^.XDir = 1 then
      AObject^.ShapeNum := Word(FContext.States[KEEN_STATE_S_KEENSTAND].RightShape)
    else
      AObject^.ShapeNum := Word(FContext.States[KEEN_STATE_S_KEENSTAND].LeftShape);
  end;
  FContext.PlaceSprite(AObject, KEEN_PRIORITY);
end;

procedure TKeenPlayerActions.KeenAirReact(AObject: PKeenObject);
var
  LX: Integer;
  LY: Integer;
  LThroughPoleHole: Boolean;
begin
  if (AObject^.HitEast <> 0) or (AObject^.HitWest <> 0) then
    AObject^.XSpeed := 0;
  LThroughPoleHole := False;
  for LY := AObject^.TileTop to AObject^.TileBottom do
    for LX := AObject^.TileLeft to AObject^.TileRight do
      if (not LThroughPoleHole) and (FContext.SouthWall(FContext.Tile(1, LX, LY)) = 17) then
      begin
        // jumping up through a pole hole
        AObject^.XSpeed := 0;
        AObject^.X := TKeenArithmetic.ToWord(AObject^.TileMidX * KEEN_TILEGLOBAL - 2 * KEEN_PIXGLOBAL);
        LThroughPoleHole := True;
      end;
  if (not LThroughPoleHole) and (AObject^.HitSouth <> 0) then
  begin
    if AObject^.HitSouth = 17 then
    begin
      // jumping up through a pole hole
      AObject^.Y := TKeenArithmetic.ToWord(AObject^.Y - 32);
      AObject^.Top := TKeenArithmetic.ToWord(AObject^.Top - 32);
      AObject^.XSpeed := 0;
      AObject^.X := TKeenArithmetic.ToWord(AObject^.TileMidX * KEEN_TILEGLOBAL - 2 * KEEN_PIXGLOBAL);
    end
    else
    begin
      FContext.Events.PlaySound(KEEN_SND_HITHEADSND);
      if AObject^.HitSouth > 1 then
      begin
        AObject^.YSpeed := TKeenArithmetic.ToInt16(AObject^.YSpeed + 16);
        if AObject^.YSpeed < 0 then
          AObject^.YSpeed := 0; // push away from slopes
      end
      else
        AObject^.YSpeed := 0;
      FJumpTime := 0;
    end;
  end;
  if AObject^.HitNorth <> 0 then
  begin
    // a kludge to allow jumping off sprites
    if not ((AObject^.HitNorth = 25) and (FJumpTime <> 0)) then
    begin
      AObject^.Temp1 := 0;
      AObject^.Temp2 := 0;
      FContext.ChangeState(AObject, KEEN_STATE_S_KEENSTAND);
      FContext.Events.PlaySound(KEEN_SND_LANDSND);
    end;
  end;
  FContext.PlaceSprite(AObject, KEEN_PRIORITY);
end;

end.
