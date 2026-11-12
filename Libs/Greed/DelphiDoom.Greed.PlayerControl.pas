{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the commands of the player                       }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): ControlMovement,            }
{  ControlBobbing, PlayerCommand, CheckHere, newlights and ChangeScroll of      }
{  raven.pas                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.PlayerControl;

// the positions are 16.16 fixed point numbers: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.PlayerMovement, DelphiDoom.Greed.PlayerControl.Intf;

const
  /// <summary>NETMSGSIZE: the longest message to the other players</summary>
  GREED_NET_MESSAGE_SIZE = 30;
  /// <summary>SECRETBUFSIZE: the last characters typed, where the secret codes are looked for</summary>
  GREED_SECRET_BUFFER_SIZE = 20;
  /// <summary>DEFAULTVRANGLE of raven.pas</summary>
  GREED_DEFAULT_VR_ANGLE = 4;
  /// <summary>MAXSCROLL1 of r_public_h.pas: how far the look goes up and down at full resolution</summary>
  GREED_MAXSCROLL1 = 120;

type
  /// <summary>
  ///   ControlMovement of raven.pas, line by line: every tic it moves the head and the weapon (ControlBobbing) and,
  ///   on the odd tics, reads the commands: the mouse, the keys of the menus and of the modes (they only raise the
  ///   flags of TGreedGameState that PlayLoop serves), the look up and down, the inventory, the change of weapon,
  ///   the jump, the walk and the run with their acceleration (MoveRate, StrafRate), the turn, the use, the fire,
  ///   the step up, the floors that push, the fall and the ceiling. With it: CheckHere (the use of what is in front
  ///   of the player: doors, switches, elevators), newlights and ChangeScroll, that PlayLoop calls.
  ///   The globals of the original are the fields of TGreedGameState. The ones that are not there are properties
  ///   of this class: the state of the mouse (MouseDX, MouseDY and the three buttons of d_ints.pas), the settings
  ///   that the original reads from SC and d_ints (MouseEnabled, MouseSensitivity, MouseSensitivityX,
  ///   MouseSensitivityY, InvertMouseTurn, InvertMouseLook, ScreenSize, VrAngle), ResizeScreen and BiggerScreen,
  ///   AdjustVrAngle and AdjustVrDistance, the message of the net game (NetMsgStatus, NetMsgIndex, NetMsg),
  ///   ScrollRate and MaxScroll (variables in the original: halved at low resolution) and FirePending (the action
  ///   hook of the renderer: the original shoots inside RF_RenderView; here PlayLoop calls RunActionHook where it
  ///   draws the view). switches[x][y] of event.pas is Switches[x * 64 + y] of the state.
  ///   Not ported: the net game (NetCheckHere; the message can be typed only when NetMode is true), the demos
  ///   (recording and playback) and the joystick, that xGreed does not read either.
  ///   Kept defects of the original: the search of the floor to step on looks only at the first column of the tiles
  ///   under the player (the inner counter is not reset); when the tile found has no floor above 0 the floor under
  ///   the player is used; in CheckHere, once an elevator has swapped, the wall is switched again for every
  ///   elevator that follows in the list; SHIFT with F1, F4 or F5 also opens the help, the quick exit and the
  ///   briefing.
  ///   Differences: a tile outside the map reads 0 (the original read the memory near the arrays); a slot without
  ///   a weapon (-1) does not fire (the original read before the table of the weapons)
  /// </summary>
  TGreedPlayerControl = class
  strict private
    FState: TGreedGameState;
    FMovement: TGreedPlayerMovement;
    FControls: IGreedControls;
    FHost: IGreedPlayerControlHost;
    FEvents: IGreedEventRunner;
    FWeapons: IGreedPlayerWeapons;
    FMouseDX: Integer;
    FMouseDY: Integer;
    FMouseButtons: array[TGreedMouseButton] of Boolean;
    FMouseEnabled: Boolean;
    FMouseSensitivity: Integer;
    FMouseSensitivityX: Integer;
    FMouseSensitivityY: Integer;
    FInvertMouseTurn: Boolean;
    FInvertMouseLook: Boolean;
    FScreenSize: Integer;
    FVrAngle: Integer;
    FResizeScreen: Boolean;
    FBiggerScreen: Boolean;
    FAdjustVrAngle: Integer;
    FAdjustVrDistance: Single;
    FNetMsgStatus: Integer;
    FNetMsgIndex: Integer;
    FNetMsg: array[0..GREED_NET_MESSAGE_SIZE - 1] of Char;
    FScrollRate: Integer;
    FMaxScroll: Integer;
    FFirePending: Boolean;
    function FloorZ(AX, AY: TGreedFixed): TGreedFixed;
    function FloorPic(ASpot: Integer): Integer;
    function OnWater: Boolean;
    procedure CheckCeiling;
    procedure WarpFall;
    procedure ReadMouse;
    function KeysReady: Boolean;
    procedure KeyDelay;
    procedure ReadSystemKeys;
    function ReadViewSizeKeys: Boolean;
    procedure ReadMapZoomKeys;
    procedure ReadLook(ALookMove: Integer);
    procedure ReadModeKeys;
    procedure ReadTyping;
    procedure ReadInventoryKeys;
    procedure DeadPlayer;
    procedure ReadWeaponKeys;
    procedure ReadStrafe(AMouseTurn: Integer; ASpeed: TGreedFixed; AMoveUnit: Integer);
    procedure ReadForward(ASpeed: TGreedFixed; AMoveUnit: Integer);
    procedure ReadFire;
    procedure StepAndFall;
    function GetMouseButton(AButton: TGreedMouseButton): Boolean;
    function GetNetMessage: string;
  public
    /// <summary>
    ///   AState has the player and the globals of the game; AMovement is the movement of the player against the
    ///   map (TryDoor, Thrust); AControls is the state of the commands; AHost has the switches and the lights;
    ///   AEvents is RunEvent; AWeapons shoots. EArgumentNilException if one is nil
    /// </summary>
    constructor Create(AState: TGreedGameState; AMovement: TGreedPlayerMovement; const AControls: IGreedControls;
      const AHost: IGreedPlayerControlHost; const AEvents: IGreedEventRunner; const AWeapons: IGreedPlayerWeapons);
    /// <summary>ControlBobbing: the head and the weapon swing while the player moves and come back when it stops</summary>
    procedure ControlBobbing;
    /// <summary>ControlMovement: one tic of the commands of the player</summary>
    procedure ControlMovement;
    /// <summary>PlayerCommand: what the timer of the original calls at every tic</summary>
    procedure PlayerCommand;
    /// <summary>
    ///   The action hook of the renderer (RF_CheckActionFlag): if a fire was asked since the last call the weapon
    ///   shoots now. PlayLoop calls it where the original draws the view
    /// </summary>
    procedure RunActionHook;
    /// <summary>
    ///   CheckHere(useit, cx, cy, angle): the door, the switch and the elevators of the tile of (cx, cy). AUseIt is
    ///   True when the player pressed the use command (the switch must be in front of it)
    /// </summary>
    procedure CheckHere(AUseIt: Boolean; ACenterX, ACenterY: TGreedFixed; AAngle: Integer);
    /// <summary>newlights: ChangeLight is added to Lighting (1 .. 4096) and the renderer is told</summary>
    procedure NewLights;
    /// <summary>ChangeScroll: the look of the player moves by ScrollView, inside MaxScroll</summary>
    procedure ChangeScroll;
    /// <summary>mousedx and mousedy of d_ints.pas: the movement of the mouse still to use (it halves every tic)</summary>
    property MouseDX: Integer read FMouseDX write FMouseDX;
    property MouseDY: Integer read FMouseDY write FMouseDY;
    /// <summary>mousebuttons of d_ints.pas, as the last odd tic left them</summary>
    property MouseButton[AButton: TGreedMouseButton]: Boolean read GetMouseButton;
    /// <summary>SC.mouse = 1. False as the original starts</summary>
    property MouseEnabled: Boolean read FMouseEnabled write FMouseEnabled;
    /// <summary>SC.mousesensitivity (0), mousesensitivityx (10) and mousesensitivityy (5)</summary>
    property MouseSensitivity: Integer read FMouseSensitivity write FMouseSensitivity;
    property MouseSensitivityX: Integer read FMouseSensitivityX write FMouseSensitivityX;
    property MouseSensitivityY: Integer read FMouseSensitivityY write FMouseSensitivityY;
    property InvertMouseTurn: Boolean read FInvertMouseTurn write FInvertMouseTurn;
    property InvertMouseLook: Boolean read FInvertMouseLook write FInvertMouseLook;
    /// <summary>SC.screensize: 0 .. GREED_MAXVIEWSIZE - 1, changed by the commands of the size of the view</summary>
    property ScreenSize: Integer read FScreenSize write FScreenSize;
    /// <summary>SC.vrangle</summary>
    property VrAngle: Integer read FVrAngle write FVrAngle;
    /// <summary>resizeScreen and biggerScreen: PlayLoop changes the size of the view and lowers ResizeScreen</summary>
    property ResizeScreen: Boolean read FResizeScreen write FResizeScreen;
    property BiggerScreen: Boolean read FBiggerScreen write FBiggerScreen;
    /// <summary>adjustvrangle and adjustvrdist: what the keys of the VR helmet ask</summary>
    property AdjustVrAngle: Integer read FAdjustVrAngle write FAdjustVrAngle;
    property AdjustVrDistance: Single read FAdjustVrDistance write FAdjustVrDistance;
    /// <summary>netmsgstatus: 0 nothing, 1 the message is being typed, 2 it must be sent</summary>
    property NetMsgStatus: Integer read FNetMsgStatus write FNetMsgStatus;
    property NetMsgIndex: Integer read FNetMsgIndex;
    /// <summary>netmsg: the message as it is typed, with the cursor</summary>
    property NetMessage: string read GetNetMessage;
    /// <summary>SCROLLRATE (4) and MAXSCROLL (120): half of them at low resolution</summary>
    property ScrollRate: Integer read FScrollRate write FScrollRate;
    property MaxScroll: Integer read FMaxScroll write FMaxScroll;
    /// <summary>actionflag of r_public.pas: a fire waits for the next image</summary>
    property FirePending: Boolean read FFirePending write FFirePending;
  end;

implementation

uses
  DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool,
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Tables, DelphiDoom.Greed.Terrain;

const
  MOVE_UNIT = GREED_FRACUNIT;
  FALL_UNIT = GREED_FRACUNIT;
  TIC_RATE = 70;
  SCROLL_CENTER = 255;
  // the flags of a floor that pushes (F_RIGHT, F_LEFT, F_UP, F_DOWN of r_refdef.pas)
  F_RIGHT = 1 shl 0;
  F_LEFT = 1 shl 1;
  F_UP = 1 shl 2;
  F_DOWN = 1 shl 3;
  WATER_FIRST = 57;
  WATER_LAST = 59;
  WEAPON_SPREAD = 4;
  WEAPON_GREEN = 18;
  SECRET_CHARACTERS = ['A'..'Z', '0'..'9'];

{ TGreedPlayerControl }

constructor TGreedPlayerControl.Create(AState: TGreedGameState; AMovement: TGreedPlayerMovement;
  const AControls: IGreedControls; const AHost: IGreedPlayerControlHost; const AEvents: IGreedEventRunner;
  const AWeapons: IGreedPlayerWeapons);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(AMovement) then
    raise EArgumentNilException.Create('AMovement');
  if not Assigned(AControls) then
    raise EArgumentNilException.Create('AControls');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  if not Assigned(AEvents) then
    raise EArgumentNilException.Create('AEvents');
  if not Assigned(AWeapons) then
    raise EArgumentNilException.Create('AWeapons');
  FState := AState;
  FMovement := AMovement;
  FControls := AControls;
  FHost := AHost;
  FEvents := AEvents;
  FWeapons := AWeapons;
  FMouseSensitivityX := 10;
  FMouseSensitivityY := 5;
  FScrollRate := GREED_SCROLLRATE1;
  FMaxScroll := GREED_MAXSCROLL1;
end;

function TGreedPlayerControl.GetMouseButton(AButton: TGreedMouseButton): Boolean;
begin
  Result := FMouseButtons[AButton];
end;

function TGreedPlayerControl.GetNetMessage: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := Low(FNetMsg) to High(FNetMsg) do
  begin
    if FNetMsg[LIndex] = #0 then
      Break;
    Result := Result + FNetMsg[LIndex];
  end;
end;

function TGreedPlayerControl.FloorZ(AX, AY: TGreedFixed): TGreedFixed;
begin
  Result := TGreedTerrain.FloorZ(FState.World, AX, AY);
end;

function TGreedPlayerControl.FloorPic(ASpot: Integer): Integer;
begin
  Result := FState.World.GetValue(gpFloorPic, ASpot);
end;

function TGreedPlayerControl.OnWater: Boolean;
var
  LPic: Integer;
begin
  LPic := FloorPic(FState.Player.MapSpot);
  Result := (LPic >= WATER_FIRST) and (LPic <= WATER_LAST);
end;

procedure TGreedPlayerControl.ControlBobbing;
var
  LLast: Integer;
begin
  // the two branches of the original for a move forward and a move backward are the same
  if FState.MoveRate <> 0 then
  begin
    if FState.HeadBob >= GREED_HEADBOBFACTOR * GREED_MAXBOBS - 1 then
      FState.HeadBob := 0
    else
      Inc(FState.HeadBob, GREED_HEADBOBFACTOR div 2);
    if FState.HeadBob >= GREED_HEADBOBFACTOR * GREED_MAXBOBS then
      FState.HeadBob := 0;
    if FState.WeapBob >= GREED_WEAPONBOBFACTOR * GREED_MAXBOBS - 1 then
      FState.WeapBob := 0
    else
      Inc(FState.WeapBob);
  end
  else
  begin
    if TGreedGameTables.WeaponMove[FState.WeapBob] <> 0 then
    begin
      LLast := TGreedGameTables.WeaponMove[FState.WeapBob - 1];
      if Abs(LLast) < Abs(TGreedGameTables.WeaponMove[FState.WeapBob]) then
        Dec(FState.WeapBob, 2)
      else
        Inc(FState.WeapBob, 2);
      if FState.WeapBob >= GREED_WEAPONBOBFACTOR * GREED_MAXBOBS then
        FState.WeapBob := 0
      else if FState.WeapBob <= 0 then
        FState.WeapBob := 0;
    end
    else
      FState.WeapBob := 0;
    if TGreedGameTables.HeadMove[FState.HeadBob] <> 0 then
    begin
      LLast := TGreedGameTables.HeadMove[FState.HeadBob - 1];
      if Abs(LLast) < Abs(TGreedGameTables.HeadMove[FState.HeadBob]) then
        Dec(FState.HeadBob)
      else
      begin
        Inc(FState.HeadBob);
        if FState.HeadBob >= GREED_HEADBOBFACTOR * GREED_MAXBOBS then
          FState.HeadBob := 0;
      end;
    end
    else
      FState.HeadBob := 0;
  end;
end;

// _checkceiling of ControlMovement: the head stays 10 units under the ceiling and the player starts to fall
procedure TGreedPlayerControl.CheckCeiling;
var
  LCeilingZ: TGreedFixed;
begin
  LCeilingZ := TGreedTerrain.CeilingZ(FState.World, FState.Player.X, FState.Player.Y);
  if FState.Player.Z + (10 * GREED_FRACUNIT) > LCeilingZ then
  begin
    FState.Player.Z := LCeilingZ - 10 * GREED_FRACUNIT;
    FState.FallRate := FALL_UNIT;
  end;
end;

// while a warp is going on the player only falls to the floor
procedure TGreedPlayerControl.WarpFall;
var
  LFloorZ: TGreedFixed;
begin
  LFloorZ := FloorZ(FState.Player.X, FState.Player.Y) + FState.Player.Height;
  if FState.Player.Z > LFloorZ then
  begin
    FState.FallRate := FState.FallRate + MOVE_UNIT;
    FState.Player.Z := FState.Player.Z - FState.FallRate;
    if FState.Player.Z < LFloorZ then
      FState.Player.Z := LFloorZ;
  end
  else if FState.Player.Z < LFloorZ then
  begin
    FState.Player.Z := LFloorZ;
    FState.FallRate := 0;
  end;
end;

procedure TGreedPlayerControl.ReadMouse;
begin
  if FMouseEnabled then
  begin
    FMouseButtons[gmbFire] := FControls.IsMouseDown(gmbFire);
    FMouseButtons[gmbUse] := FControls.IsMouseDown(gmbUse);
    FMouseButtons[gmbNorth] := FControls.IsMouseDown(gmbNorth);
    FMouseDX := FMouseDX + ((FControls.MouseDeltaX * GREED_FRACUNIT * (FMouseSensitivity + 5)) div 10) *
      (FMouseSensitivityX + 1) div 5;
    FMouseDY := FMouseDY + ((FControls.MouseDeltaY * GREED_FRACUNIT * (FMouseSensitivity + 5)) div 10) *
      (FMouseSensitivityY + 1) div 5;
  end
  else
  begin
    FMouseButtons[gmbFire] := False;
    FMouseButtons[gmbUse] := False;
    FMouseButtons[gmbNorth] := False;
    FMouseDX := 0;
    FMouseDY := 0;
  end;
end;

function TGreedPlayerControl.KeysReady: Boolean;
begin
  Result := FState.TimeCount > FState.KeyboardDelay;
end;

procedure TGreedPlayerControl.KeyDelay;
begin
  FState.KeyboardDelay := FState.TimeCount + GREED_KBDELAY;
end;

procedure TGreedPlayerControl.ReadSystemKeys;
begin
  if FControls.IsFresh(gcMenu) and KeysReady and (FNetMsgStatus = 0) then
  begin
    FControls.Eat(gcMenu);
    FState.ActivateMenu := True;
    FState.KeyboardDelay := FState.TimeCount + GREED_ACTIVATEMENUDELAY;
  end;
  if FControls.IsDown(gcBriefing) and FControls.IsDown(gcShift) and KeysReady then
  begin
    FAdjustVrAngle := -FVrAngle + GREED_DEFAULT_VR_ANGLE;
    FAdjustVrDistance := -1;
    KeyDelay;
  end;
  if FControls.IsDown(gcQuickExit) and FControls.IsDown(gcShift) and KeysReady then
  begin
    FAdjustVrDistance := 72090;
    KeyDelay;
  end;
  if FControls.IsDown(gcVrDistanceNear) and FControls.IsDown(gcShift) and KeysReady then
  begin
    FAdjustVrDistance := 59578;
    KeyDelay;
  end;
  if FControls.IsDown(gcVrAngleUp) and FControls.IsDown(gcShift) and KeysReady then
  begin
    FAdjustVrAngle := 1;
    KeyDelay;
  end;
  if FControls.IsDown(gcHelp) and FControls.IsDown(gcShift) and KeysReady then
  begin
    FAdjustVrAngle := -1;
    KeyDelay;
  end;
  if FControls.IsDown(gcHelp) and KeysReady then
  begin
    FState.ActivateHelp := True;
    KeyDelay;
  end;
  if (FControls.IsDown(gcQuickExit) or (FControls.IsDown(gcAlt) and FControls.IsDown(gcQuit))) and KeysReady then
  begin
    FState.QuickExit := True;
    KeyDelay;
  end;
  if FControls.IsDown(gcBriefing) and KeysReady and not FState.NetMode then
  begin
    FState.ActivateBrief := True;
    KeyDelay;
  end;
  if FControls.IsFresh(gcPause) and KeysReady and (FNetMsgStatus = 0) then
  begin
    FControls.Eat(gcPause);
    FState.Paused := True;
    KeyDelay;
  end;
end;

// True when the size of the view changes: the original leaves ControlMovement there
function TGreedPlayerControl.ReadViewSizeKeys: Boolean;
begin
  if FControls.IsDown(gcViewBigger) and not FResizeScreen and KeysReady then
  begin
    FResizeScreen := True;
    FBiggerScreen := True;
    KeyDelay;
    if FScreenSize < GREED_MAXVIEWSIZE - 1 then
      Inc(FScreenSize);
    Exit(True);
  end;
  if FControls.IsDown(gcViewSmaller) and not FResizeScreen and KeysReady then
  begin
    FResizeScreen := True;
    FBiggerScreen := False;
    KeyDelay;
    if FScreenSize > 0 then
      Dec(FScreenSize);
    Exit(True);
  end;
  Result := False;
end;

procedure TGreedPlayerControl.ReadMapZoomKeys;
begin
  if FControls.IsDown(gcMapZoomOut) and KeysReady and (FNetMsgStatus = 0) then
  begin
    case FState.MapZoom of
      8:
        FState.MapZoom := 4;
      16:
        FState.MapZoom := 8;
    end;
    KeyDelay;
  end;
  if FControls.IsDown(gcMapZoomIn) and KeysReady and (FNetMsgStatus = 0) then
  begin
    case FState.MapZoom of
      4:
        FState.MapZoom := 8;
      8:
        FState.MapZoom := 16;
    end;
    KeyDelay;
  end;
end;

procedure TGreedPlayerControl.ReadLook(ALookMove: Integer);
begin
  if (FControls.IsDown(gcLookUp) or (ALookMove > GREED_FRACUNIT div 4)) and (FNetMsgStatus = 0) then
  begin
    FState.ScrollView := FState.ScrollView - FScrollRate;
    if ALookMove > GREED_FRACUNIT div 2 then
      FState.ScrollView := FState.ScrollView - FScrollRate;
  end;
  if (FControls.IsDown(gcLookDown) or (ALookMove < -GREED_FRACUNIT div 4)) and (FNetMsgStatus = 0) then
  begin
    FState.ScrollView := FState.ScrollView + FScrollRate;
    if ALookMove < -GREED_FRACUNIT div 2 then
      FState.ScrollView := FState.ScrollView + FScrollRate;
  end;
  if FControls.IsDown(gcCenterView) and (FNetMsgStatus = 0) then
    FState.ScrollView := SCROLL_CENTER;
  if FState.ScrollView = SCROLL_CENTER then
  begin
    if FState.Player.ScrollMin < 0 then
    begin
      FState.Player.ScrollMin := FState.Player.ScrollMin + FScrollRate;
      FState.Player.ScrollMax := FState.Player.ScrollMax + FScrollRate;
    end
    else if FState.Player.ScrollMin > 0 then
    begin
      FState.Player.ScrollMin := FState.Player.ScrollMin - FScrollRate;
      FState.Player.ScrollMax := FState.Player.ScrollMax - FScrollRate;
    end
    else
      FState.ScrollView := 0;
  end;
end;

procedure TGreedPlayerControl.ReadModeKeys;
begin
  if FControls.IsDown(gcMapMode) and KeysReady and (FNetMsgStatus = 0) then
  begin
    FState.ToggleMapMode := True;
    KeyDelay;
  end;
  if FControls.IsDown(gcHeatMode) and KeysReady and (FNetMsgStatus = 0) then
  begin
    FState.ToggleHeatMode := True;
    KeyDelay;
  end;
  if FControls.IsDown(gcMotionMode) and KeysReady and (FNetMsgStatus = 0) then
  begin
    FState.ToggleMotionMode := True;
    KeyDelay;
  end;
  if FControls.IsDown(gcRearView) and KeysReady and (FNetMsgStatus = 0) then
  begin
    FState.ToggleRearView := True;
    KeyDelay;
  end;
  if FControls.IsDown(gcGoalItem) and KeysReady and (FNetMsgStatus = 0) then
  begin
    FState.ToggleGoalItem := True;
    KeyDelay;
  end;
  if FControls.IsDown(gcAutoRun) and KeysReady then
  begin
    FState.ToggleAutoRun := True;
    KeyDelay;
  end;
  if FControls.IsDown(gcAutoTarget) and KeysReady then
  begin
    FState.ToggleAutoTarget := True;
    KeyDelay;
  end;
end;

// the characters typed: the buffer of the secret codes and, in a net game, the message to the other players
procedure TGreedPlayerControl.ReadTyping;
var
  LCharacter: Char;
begin
  if FControls.TakeCharacter(LCharacter) then
  begin
    if CharInSet(UpCase(LCharacter), SECRET_CHARACTERS) then
    begin
      if Length(FState.SecretBuf) >= GREED_SECRET_BUFFER_SIZE - 1 then
        Delete(FState.SecretBuf, 1, 1);
      FState.SecretBuf := FState.SecretBuf + LCharacter;
    end;
    // getting message
    if FNetMsgStatus = 1 then
    begin
      case Ord(LCharacter) of
        27:
          FNetMsgStatus := 0;
        8:
          begin
            FNetMsg[FNetMsgIndex] := ' ';
            if FNetMsgIndex > 0 then
              Dec(FNetMsgIndex);
            FNetMsg[FNetMsgIndex] := '_';
          end;
        13:
          begin
            // sending
            FNetMsgStatus := 2;
            FNetMsg[FNetMsgIndex] := ' ';
          end;
      else
        FNetMsg[FNetMsgIndex] := LCharacter;
        if FNetMsgIndex < GREED_NET_MESSAGE_SIZE - 1 then
          Inc(FNetMsgIndex);
        FNetMsg[FNetMsgIndex] := '_';
      end;
    end;
    FState.SecretDelay := FState.TimeCount + GREED_KBDELAY * 5;
  end;
  if FState.TimeCount > FState.SecretDelay then
    FState.SecretDelay := FState.TimeCount + GREED_KBDELAY;
  if FControls.IsDown(gcNetMessage) and FState.NetMode and (FNetMsgStatus = 0) and KeysReady then
  begin
    FillChar(FNetMsg, SizeOf(FNetMsg), 0);
    FNetMsgStatus := 1;
    FNetMsgIndex := 0;
    FNetMsg[0] := '_';
    KeyDelay;
  end;
  if FControls.IsDown(gcNewSong) and KeysReady then
  begin
    FState.NewSong := True;
    KeyDelay;
  end;
end;

procedure TGreedPlayerControl.ReadInventoryKeys;
begin
  if FControls.IsDown(gcInventoryRight) and (FState.TimeCount > FState.InventoryDelay) then
  begin
    FState.GoIRight := True;
    FState.InventoryDelay := FState.TimeCount + GREED_KBDELAY;
    FState.InventoryTime := FState.TimeCount + (3 * TIC_RATE);
  end;
  if FControls.IsDown(gcInventoryLeft) and (FState.TimeCount > FState.InventoryDelay) then
  begin
    FState.GoILeft := True;
    FState.InventoryDelay := FState.TimeCount + GREED_KBDELAY;
    FState.InventoryTime := FState.TimeCount + (3 * TIC_RATE);
  end;
end;

// he's dead jim! The body sinks to the floor (to 40 units on the water, to 12 elsewhere)
procedure TGreedPlayerControl.DeadPlayer;
var
  LRest: TGreedFixed;
begin
  if OnWater then
    LRest := 40 * GREED_FRACUNIT
  else
    LRest := 12 * GREED_FRACUNIT;
  if FState.Player.Z > FloorZ(FState.Player.X, FState.Player.Y) + LRest then
    FState.Player.Z := FState.Player.Z - GREED_FRACUNIT
  else if FState.Player.Z < FloorZ(FState.Player.X, FState.Player.Y) + LRest then
    FState.Player.Z := FloorZ(FState.Player.X, FState.Player.Y) + LRest;
  if FControls.IsDown(gcRestart) then
    FState.DeadRestart := True;
end;

procedure TGreedPlayerControl.ReadWeaponKeys;
const
  WEAPON_COMMANDS: array[0..4] of TGreedCommand = (gcWeapon1, gcWeapon2, gcWeapon3, gcWeapon4, gcWeapon5);
var
  LSlot: Integer;
begin
  // the first key that can change the weapon wins; the slot 0 always has a weapon
  for LSlot := 0 to 4 do
    if FControls.IsDown(WEAPON_COMMANDS[LSlot]) and not FState.ChangingWeapons and
      (FState.Player.CurrentWeapon <> LSlot) and ((LSlot = 0) or (FState.Player.Weapons[LSlot] <> -1)) and
      (FNetMsgStatus = 0) then
    begin
      FState.ChangingWeapons := True;
      FState.WeaponLowering := True;
      FState.NewWeapon := LSlot;
      Break;
    end;
end;

procedure TGreedPlayerControl.ReadStrafe(AMouseTurn: Integer; ASpeed: TGreedFixed; AMoveUnit: Integer);
begin
  if (FControls.IsDown(gcStrafe) or FControls.IsDown(gcSlideLeft) or FControls.IsDown(gcSlideRight)) and
    (FNetMsgStatus = 0) then
  begin
    if FControls.IsDown(gcWest) or FControls.IsDown(gcSlideLeft) or (AMouseTurn >= GREED_FRACUNIT) then
    begin
      if not FControls.IsDown(gcSlideRight) then
      begin
        FState.StrafRate := FState.StrafRate - AMoveUnit;
        if FState.StrafRate < -ASpeed then
          FState.StrafRate := FState.StrafRate + AMoveUnit;
      end;
    end;
    if FControls.IsDown(gcEast) or FControls.IsDown(gcSlideRight) or (AMouseTurn <= -GREED_FRACUNIT) then
    begin
      if not FControls.IsDown(gcSlideLeft) then
      begin
        FState.StrafRate := FState.StrafRate + AMoveUnit;
        if FState.StrafRate > ASpeed then
          FState.StrafRate := FState.StrafRate - AMoveUnit;
      end;
    end
    else if (not FControls.IsDown(gcWest)) and (not FControls.IsDown(gcSlideLeft)) and
      (AMouseTurn > -GREED_FRACUNIT) and (AMouseTurn < GREED_FRACUNIT) then
    begin
      if FState.StrafRate < 0 then
        FState.StrafRate := FState.StrafRate + MOVE_UNIT
      else if FState.StrafRate > 0 then
        FState.StrafRate := FState.StrafRate - MOVE_UNIT;
    end;
  end
  else
  begin
    if FState.StrafRate < 0 then
      FState.StrafRate := FState.StrafRate + MOVE_UNIT
    else if FState.StrafRate > 0 then
      FState.StrafRate := FState.StrafRate - MOVE_UNIT;
  end;
end;

procedure TGreedPlayerControl.ReadForward(ASpeed: TGreedFixed; AMoveUnit: Integer);
begin
  // forward/backwards move
  if FControls.IsDown(gcNorth) or FMouseButtons[gmbNorth] then
    FState.MoveForward := 1
  else if FControls.IsDown(gcSouth) then
    FState.MoveForward := -1
  else
    FState.MoveForward := 0;
  // compute move vectors
  if FState.MoveForward = 1 then
  begin
    if FState.MoveRate < ASpeed then
      FState.MoveRate := FState.MoveRate + AMoveUnit;
    if FState.MoveRate > ASpeed then
      FState.MoveRate := FState.MoveRate - AMoveUnit;
  end
  else if FState.MoveForward = -1 then
  begin
    if FState.MoveRate > -ASpeed then
      FState.MoveRate := FState.MoveRate - AMoveUnit;
    if FState.MoveRate < -ASpeed then
      FState.MoveRate := FState.MoveRate + AMoveUnit;
  end
  else if FState.MoveRate <> 0 then
  begin
    if FState.MoveRate < 0 then
      FState.MoveRate := FState.MoveRate + MOVE_UNIT
    else
      FState.MoveRate := FState.MoveRate - MOVE_UNIT;
  end;
  // move along move vector
  if FState.MoveRate < 0 then
  begin
    if not FMovement.Thrust(FState.Player, FState.Player.Angle + GREED_WEST, -FState.MoveRate) then
      FState.MoveRate := 0;
  end
  else if FState.MoveRate > 0 then
  begin
    if not FMovement.Thrust(FState.Player, FState.Player.Angle, FState.MoveRate) then
      FState.MoveRate := 0;
  end;
end;

procedure TGreedPlayerControl.ReadFire;
var
  LWeapon: Integer;
begin
  LWeapon := FState.Player.Weapons[FState.Player.CurrentWeapon];
  if LWeapon < 0 then
    Exit;
  if (FControls.IsDown(gcFire) or FMouseButtons[gmbFire]) and (FState.Weapons[LWeapon].Charge = 100) and
    not FState.ChangingWeapons then
  begin
    if (LWeapon = WEAPON_GREEN) or (LWeapon = WEAPON_SPREAD) then
    begin
      // these two shoot at the end of their animation (AdvanceWeaponMode)
      if (FState.Player.Ammo[FState.Weapons[LWeapon].AmmoType] >= FState.Weapons[LWeapon].AmmoRate) and
        (FState.WeapMode = 0) then
        FState.WeapMode := 1;
    end
    else
      FFirePending := True;
  end;
end;

// compute falling or stepping up higher
procedure TGreedPlayerControl.StepAndFall;
var
  LFloorZ, LTileFloorZ, LMaxZ: TGreedFixed;
  LXLow, LYLow, LXHigh, LYHigh, LMaxX, LMaxY, LSpot, LFlags: Integer;
begin
  LXLow := (FState.Player.X - GREED_FRACUNIT * 8) div GREED_FRACTILEUNIT;
  LXHigh := (FState.Player.X + GREED_FRACUNIT * 8) div GREED_FRACTILEUNIT;
  LYLow := (FState.Player.Y - GREED_FRACUNIT * 8) div GREED_FRACTILEUNIT;
  LYHigh := (FState.Player.Y + GREED_FRACUNIT * 8) div GREED_FRACTILEUNIT;
  LFloorZ := FState.Player.Z - FState.Player.Height;
  LMaxZ := 0;
  LMaxX := 0;
  LMaxY := 0;
  while LXLow <= LXHigh do
  begin
    // LYLow is not reset: after the first column the inner loop does nothing, as in the original
    while LYLow <= LYHigh do
    begin
      LTileFloorZ := FloorZ((LXLow * 64 + 32) * GREED_FRACUNIT, (LYLow * 64 + 32) * GREED_FRACUNIT);
      if (LTileFloorZ > LMaxZ) and (LTileFloorZ < LFloorZ + (20 * GREED_FRACUNIT)) then
      begin
        LMaxZ := LTileFloorZ;
        LMaxX := LXLow;
        LMaxY := LYLow;
      end;
      Inc(LYLow);
    end;
    Inc(LXLow);
  end;
  if LMaxZ = 0 then
  begin
    LMaxZ := FloorZ(FState.Player.X, FState.Player.Y);
    LMaxX := FState.Player.X div GREED_FRACTILEUNIT;
    LMaxY := FState.Player.Y div GREED_FRACTILEUNIT;
  end;
  LFloorZ := LMaxZ + FState.Player.Height;
  if Abs(FState.Player.Z - LFloorZ) <= 10 * GREED_FRACUNIT then
  begin
    // a floor that pushes; the flags are read again after every push only in the tile, that does not change
    LSpot := LMaxY * GREED_MAP_SIZE + LMaxX;
    LFlags := FState.World.GetValue(gpFloorFlags, LSpot);
    if LFlags and F_RIGHT <> 0 then
      FMovement.Thrust(FState.Player, GREED_EAST, GREED_FRACUNIT * 4);
    if LFlags and F_LEFT <> 0 then
      FMovement.Thrust(FState.Player, GREED_WEST, GREED_FRACUNIT * 4);
    if LFlags and F_UP <> 0 then
      FMovement.Thrust(FState.Player, GREED_NORTH, GREED_FRACUNIT * 4);
    if LFlags and F_DOWN <> 0 then
      FMovement.Thrust(FState.Player, GREED_SOUTH, GREED_FRACUNIT * 4);
  end;
  LFloorZ := FloorZ(FState.Player.X, FState.Player.Y) + FState.Player.Height;
  FState.Player.Z := FState.Player.Z - FState.FallRate;
  if FState.Player.Z > LFloorZ then
    FState.FallRate := FState.FallRate + FALL_UNIT
  else if FState.Player.Z < LFloorZ then
  begin
    if FState.FallRate >= 12 * GREED_FRACUNIT then
      FState.FallDamage := (FState.FallRate div GREED_FRACUNIT) div 7;
    FState.Player.Z := FState.Player.Z + 4 * GREED_FRACUNIT;
    if FState.Player.Z > LFloorZ then
      FState.Player.Z := LFloorZ;
    FState.FallRate := 0;
  end;
end;

procedure TGreedPlayerControl.ControlMovement;
var
  LSpeed: TGreedFixed;
  LMoveUnit, LTurnUnit, LTurn, LMouseTurn, LMouseLook: Integer;
begin
  ControlBobbing;
  if FState.Warping <> 0 then
  begin
    WarpFall;
    CheckCeiling;
    Exit;
  end;
  // the commands are read on the odd tics
  if FState.TimeCount and 1 = 0 then
  begin
    CheckCeiling;
    Exit;
  end;
  ReadMouse;
  // JVAL: invert mouse
  if FInvertMouseTurn then
    LMouseTurn := -FMouseDX
  else
    LMouseTurn := FMouseDX;
  if FInvertMouseLook then
    LMouseLook := -FMouseDY
  else
    LMouseLook := FMouseDY;
  // for smooth mouse movement
  if FMouseDX <> 0 then
    FMouseDX := FMouseDX div 2;
  if FMouseDY <> 0 then
    FMouseDY := FMouseDY div 2;
  ReadSystemKeys;
  if ReadViewSizeKeys then
    Exit;
  ReadMapZoomKeys;
  ReadLook(LMouseLook);
  ReadModeKeys;
  ReadTyping;
  ReadInventoryKeys;
  if FState.Player.Angst = 0 then
  begin
    DeadPlayer;
    Exit;
  end;
  if FControls.IsDown(gcUseItem) and (FState.TimeCount > FState.UseDelay) then
  begin
    FState.UseItem := True;
    FState.UseDelay := FState.TimeCount + GREED_KBDELAY;
    FState.InventoryTime := FState.TimeCount + (3 * TIC_RATE);
  end;
  ReadWeaponKeys;
  if FControls.IsDown(gcJump) and (FState.TimeCount > FState.JumpDelay) and (FState.FallRate = 0) and
    (FNetMsgStatus = 0) then
  begin
    FState.FallRate := FState.FallRate - (FALL_UNIT * 9 + FState.Player.JumpMod);
    FState.JumpDelay := FState.TimeCount + GREED_KBDELAY;
  end;
  // check run/slow keys (modifiedTurn and modifiedturnunit of the original are computed and never used)
  if FControls.IsDown(gcRun) xor FState.AutoRun then
  begin
    LSpeed := TGreedGameTables.PlayerMoveSpeed * 6 + FState.Player.RunMod;
    LMoveUnit := MOVE_UNIT * 2;
    LTurnUnit := 1024;
  end
  else
  begin
    LSpeed := (TGreedGameTables.PlayerMoveSpeed * 7) div 2 + FState.Player.WalkMod;
    LMoveUnit := MOVE_UNIT;
    LTurnUnit := 512;
  end;
  if OnWater then
  begin
    if FState.Player.Z = FloorZ(FState.Player.X, FState.Player.Y) + FState.Player.Height then
      LSpeed := LSpeed div 2;
  end;
  ReadStrafe(LMouseTurn, LSpeed, LMoveUnit);
  LTurn := 0;
  if FControls.IsDown(gcEast) then
    LTurn := LTurn - LTurnUnit;
  if FControls.IsDown(gcWest) then
    LTurn := LTurn + LTurnUnit;
  LTurn := LTurn + LMouseTurn div 16384;
  FState.PlayerAngle64 := FState.PlayerAngle64 + LTurn;
  FState.PlayerAngle64 := FState.PlayerAngle64 and (GREED_FRACUNIT - 1);
  FState.Player.Angle := FState.PlayerAngle64 div 64;
  FState.Player.Angle := FState.Player.Angle and GREED_ANGLES;
  if FState.StrafRate < 0 then
  begin
    if not FMovement.Thrust(FState.Player, FState.Player.Angle + GREED_NORTH, -FState.StrafRate) then
    begin
      FState.MoveRate := 0;
      FState.StrafRate := 0;
    end;
  end
  else if FState.StrafRate > 0 then
  begin
    if not FMovement.Thrust(FState.Player, FState.Player.Angle + GREED_SOUTH, FState.StrafRate) then
    begin
      FState.MoveRate := 0;
      FState.StrafRate := 0;
    end;
  end;
  ReadForward(LSpeed, LMoveUnit);
  // try to open a door in front of player
  if (FControls.IsDown(gcUse) or FMouseButtons[gmbUse]) and KeysReady and (FNetMsgStatus = 0) then
  begin
    FState.CheckTrigger := True;
    FState.KeyboardDelay := FState.TimeCount + GREED_KBDELAY * 2;
  end;
  ReadFire;
  StepAndFall;
  CheckCeiling;
end;

procedure TGreedPlayerControl.PlayerCommand;
begin
  ControlMovement;
end;

procedure TGreedPlayerControl.RunActionHook;
begin
  if not FFirePending then
    Exit;
  FWeapons.FireWeapon;
  FFirePending := False;
end;

procedure TGreedPlayerControl.CheckHere(AUseIt: Boolean; ACenterX, ACenterY: TGreedFixed; AAngle: Integer);
var
  LSpot, LX, LY, LOtherX, LOtherY, LIndex, LSwitch: Integer;
  LElevator: TGreedLinkedPool<TGreedElevator>.PItem;
  LSwitchIt, LSkip: Boolean;
begin
  FMovement.TryDoor(ACenterX, ACenterY);
  LX := ACenterX div GREED_FRACTILEUNIT;
  LY := ACenterY div GREED_FRACTILEUNIT;
  LSpot := LY * GREED_MAP_SIZE + LX;
  LSwitchIt := False;
  LSwitch := 0;
  if (LX >= 0) and (LX < GREED_MAP_SIZE) and (LY >= 0) and (LY < GREED_MAP_SIZE) then
    LSwitch := FState.Switches[LX * GREED_MAP_SIZE + LY];
  if LSwitch <> 0 then
  begin
    LSkip := AUseIt and not FHost.CheckForSwitch(LX, LY, AAngle, True);
    if not LSkip then
    begin
      FHost.SwitchWall(LX, LY, AAngle, True);
      FEvents.RunEvent(LSwitch, False);
    end;
  end;
  case FState.World.GetValue(gpMapSprites, LSpot) of
    GREED_SM_SWAPSWITCH:
      begin
        if AUseIt and not FHost.CheckForSwitch(LX, LY, AAngle, True) then
          Exit;
        LIndex := FState.Elevators.First;
        while LIndex <> GREED_POOL_NIL do
        begin
          LElevator := FState.Elevators.Item(LIndex);
          if LElevator^.Kind = getSwap then
          begin
            if LElevator^.Position = LElevator^.Ceiling then
            begin
              LElevator^.Down := True;
              LElevator^.Timer := FState.TimeCount;
              LSwitchIt := True;
            end
            else if LElevator^.Position = LElevator^.Floor then
            begin
              LElevator^.Up := True;
              LElevator^.Timer := FState.TimeCount;
              LSwitchIt := True;
            end;
          end;
          // LSwitchIt stays true for the elevators that follow, as in the original
          if LSwitchIt then
          begin
            FHost.SwitchWall(LX, LY, AAngle, True);
            FState.SwitchTime := FState.TimeCount + 3 * TIC_RATE;
          end;
          LIndex := FState.Elevators.Next(LIndex);
        end;
      end;
    GREED_SM_STRIGGER:
      begin
        LIndex := FState.Elevators.First;
        while LIndex <> GREED_POOL_NIL do
        begin
          LElevator := FState.Elevators.Item(LIndex);
          if (LElevator^.Kind = getSecret) and not LElevator^.Down and not LElevator^.Up then
          begin
            LOtherX := LElevator^.MapSpot mod GREED_MAP_SIZE;
            LOtherY := LElevator^.MapSpot div GREED_MAP_SIZE;
            if (Abs(LOtherX - LX) < 2) and (Abs(LOtherY - LY) < 2) then
            begin
              LElevator^.Down := True;
              LElevator^.Timer := FState.TimeCount;
              CheckHere(False, LOtherX * GREED_FRACTILEUNIT, LOtherY * GREED_FRACTILEUNIT, AAngle);
            end;
          end;
          LIndex := FState.Elevators.Next(LIndex);
        end;
      end;
  end;
end;

procedure TGreedPlayerControl.NewLights;
begin
  if FState.Lighting + FState.ChangeLight > 4096 then
    FState.Lighting := 4096
  else
    FState.Lighting := FState.Lighting + FState.ChangeLight;
  if FState.Lighting <= 0 then
    FState.Lighting := 1;
  FHost.SetLights(FState.Lighting * GREED_FRACUNIT);
  FState.ChangeLight := 0;
end;

procedure TGreedPlayerControl.ChangeScroll;
begin
  if FState.ScrollView = SCROLL_CENTER then
    Exit;
  if (FState.Player.ScrollMin + FState.ScrollView <= -FMaxScroll) or
    (FState.Player.ScrollMin + FState.ScrollView >= FMaxScroll) then
  begin
    FState.ScrollView := 0;
    Exit;
  end;
  FState.Player.ScrollMin := FState.Player.ScrollMin + FState.ScrollView;
  FState.Player.ScrollMax := FState.Player.ScrollMax + FState.ScrollView;
  FState.ScrollView := 0;
end;

end.
