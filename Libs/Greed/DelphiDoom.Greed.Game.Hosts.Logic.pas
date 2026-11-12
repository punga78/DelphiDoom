{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the parts of the game as they call each other    }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the calls between           }
{  raven.pas, sprites.pas, spawn.pas, event.pas, utils.pas and modplay.pas      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Game.Hosts.Logic;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Player.Intf,
  DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.Level.Intf, DelphiDoom.Greed.Elevator.Intf,
  DelphiDoom.Greed.Door.Intf, DelphiDoom.Greed.SpriteLogic.Intf, DelphiDoom.Greed.SpriteDeath,
  DelphiDoom.Greed.PlayerMovement, DelphiDoom.Greed.Game.Parts;

type
  /// <summary>
  ///   What a part of the game asks of the other parts: in the original these are calls between units (the sprites
  ///   call hurt and KillSprite of utils.pas, the elevators RunEvent of event.pas, everything SoundEffect of
  ///   modplay.pas). Each method is one call to the part that does it. The object does not own the parts: it finds
  ///   them in the TGreedGameParts of its game, that outlives it
  /// </summary>
  TGreedGameLogicHost = class(TInterfacedObject, IGreedGameSound, IGreedPlayerHealth, IGreedSpriteKiller,
    IGreedSpriteHost, IGreedDeathHost, IGreedPlayerContext, IGreedPlayerFeedback, IGreedMovementHost,
    IGreedDoorSoundSink, IGreedElevatorHost, IGreedDoorHost, IGreedSwitchHost, IGreedTicParts,
    IGreedPlayerControlHost)
  strict private
    FParts: TGreedGameParts;
  public
    /// <summary>EArgumentNilException if AParts is nil</summary>
    constructor Create(AParts: TGreedGameParts);
    // IGreedGameSound
    procedure SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    // IGreedPlayerHealth
    procedure Hurt(AAmount: Integer);
    procedure Heal(AAmount: Integer);
    procedure MedPaks(AAmount: Integer);
    procedure AddScore(AAmount: Integer);
    // IGreedSpriteKiller
    procedure KillSprite(ASprite, AWeapon: Integer);
    // IGreedSpriteHost
    function ThrustPlayer(AAngle: Integer; ASpeed: TGreedFixed): Boolean;
    // IGreedDeathHost
    function RandomNumber: Integer;
    function GetClock: Integer;
    function GetPlayerNumber: Integer;
    function GetFirstCharacterLump: Integer;
    procedure RunEvent(AEvent: Integer);
    procedure PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    function SpawnSprite(AKind, AX, AY, AZ, AOwner: Integer): Integer;
    // IGreedPlayerContext
    function GetGodMode: Boolean;
    function GetSpecialEffect: Integer;
    function GetNetMode: Boolean;
    function GetTimeCount: Integer;
    function GetNetHurtSoundTime: Integer;
    procedure SetNetHurtSoundTime(AValue: Integer);
    // IGreedPlayerFeedback
    procedure ShowHurtBorder;
    procedure PlayNetSound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    // IGreedMovementHost
    procedure NetOpenDoor(AX, AY: TGreedFixed);
    // IGreedDoorSoundSink
    procedure DoorBumped(ADoorX, ADoorY: Integer);
    // IGreedDoorHost
    procedure PlayDoorSound(AX, AY: TGreedFixed);
    // IGreedSwitchHost
    function TryDoor(ACenterX, ACenterY: TGreedFixed): Boolean;
    // IGreedTicParts
    procedure UpdateInput;
    procedure UpdateSound;
    procedure RunProcesses;
    procedure ClearTileLights;
    procedure MoveSprites;
    procedure CheckElevators;
    // IGreedPlayerControlHost
    function CheckForSwitch(ATileX, ATileY, AAngle: Integer; ADoubleSwitch: Boolean): Boolean;
    procedure SwitchWall(ATileX, ATileY, AAngle: Integer; ADoubleSwitch: Boolean);
    procedure SetLights(ABlackZ: TGreedFixed);
  end;

implementation

uses
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Tables, DelphiDoom.Greed.PlayerRules;

{ TGreedGameLogicHost }

constructor TGreedGameLogicHost.Create(AParts: TGreedGameParts);
begin
  inherited Create;
  if not Assigned(AParts) then
    raise EArgumentNilException.Create('AParts');
  FParts := AParts;
end;

procedure TGreedGameLogicHost.SoundEffect(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  FParts.Effects.Start(ASound, AVariation, AX, AY);
end;

procedure TGreedGameLogicHost.Hurt(AAmount: Integer);
begin
  FParts.PlayerRules.Hurt(FParts.State.Player, AAmount);
end;

procedure TGreedGameLogicHost.Heal(AAmount: Integer);
begin
  FParts.PlayerRules.Heal(FParts.State.Player, AAmount);
end;

procedure TGreedGameLogicHost.MedPaks(AAmount: Integer);
begin
  FParts.PlayerRules.MedPaks(FParts.State.Player, AAmount);
end;

procedure TGreedGameLogicHost.AddScore(AAmount: Integer);
begin
  TGreedPlayerRules.AddScore(FParts.State.Player, AAmount);
end;

procedure TGreedGameLogicHost.KillSprite(ASprite, AWeapon: Integer);
begin
  FParts.Death.Kill(ASprite);
end;

function TGreedGameLogicHost.ThrustPlayer(AAngle: Integer; ASpeed: TGreedFixed): Boolean;
begin
  Result := FParts.Movement.Thrust(FParts.State.Player, AAngle, ASpeed);
end;

function TGreedGameLogicHost.RandomNumber: Integer;
begin
  Result := FParts.Random.Next;
end;

function TGreedGameLogicHost.GetClock: Integer;
begin
  Result := Integer(FParts.Clock.Clock);
end;

function TGreedGameLogicHost.GetPlayerNumber: Integer;
begin
  Result := FParts.State.PlayerNum;
end;

function TGreedGameLogicHost.GetFirstCharacterLump: Integer;
begin
  Result := FParts.Archive.RequireIndexOf(TGreedGameTables.CharacterNames[0]);
end;

procedure TGreedGameLogicHost.RunEvent(AEvent: Integer);
begin
  FParts.EventsIntf.RunEvent(AEvent, False);
end;

procedure TGreedGameLogicHost.PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  SoundEffect(ASound, AVariation, AX, AY);
end;

function TGreedGameLogicHost.SpawnSprite(AKind, AX, AY, AZ, AOwner: Integer): Integer;
begin
  Result := FParts.SpawnerIntf.SpawnSprite(AKind, AX, AY, AZ, 0, 0, 0, False, AOwner);
end;

function TGreedGameLogicHost.GetGodMode: Boolean;
begin
  Result := FParts.State.GodMode;
end;

function TGreedGameLogicHost.GetSpecialEffect: Integer;
begin
  Result := FParts.State.SpecialEffect;
end;

function TGreedGameLogicHost.GetNetMode: Boolean;
begin
  Result := False;
end;

function TGreedGameLogicHost.GetTimeCount: Integer;
begin
  Result := FParts.State.TimeCount;
end;

function TGreedGameLogicHost.GetNetHurtSoundTime: Integer;
begin
  Result := FParts.NetHurtSoundTime;
end;

procedure TGreedGameLogicHost.SetNetHurtSoundTime(AValue: Integer);
begin
  FParts.NetHurtSoundTime := AValue;
end;

procedure TGreedGameLogicHost.ShowHurtBorder;
begin
  FParts.State.HurtBorder := True;
end;

procedure TGreedGameLogicHost.PlayNetSound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  // the net game is not ported: there is nobody else to tell
end;

procedure TGreedGameLogicHost.NetOpenDoor(AX, AY: TGreedFixed);
begin
  // the net game is not ported
end;

procedure TGreedGameLogicHost.DoorBumped(ADoorX, ADoorY: Integer);
begin
  FParts.State.DoorSound := True;
  FParts.State.DoorX := ADoorX;
  FParts.State.DoorY := ADoorY;
end;

procedure TGreedGameLogicHost.PlayDoorSound(AX, AY: TGreedFixed);
begin
  SoundEffect(GREED_SN_DOOR, 15, AX, AY);
end;

function TGreedGameLogicHost.TryDoor(ACenterX, ACenterY: TGreedFixed): Boolean;
begin
  Result := FParts.Movement.TryDoor(ACenterX, ACenterY);
end;

procedure TGreedGameLogicHost.UpdateInput;
begin
  // UpdateMouse of xGreed is empty: the commands are read by the timer
end;

procedure TGreedGameLogicHost.UpdateSound;
begin
  FParts.Effects.Update;
end;

procedure TGreedGameLogicHost.RunProcesses;
begin
  FParts.Events.Process;
end;

procedure TGreedGameLogicHost.ClearTileLights;
var
  LLights: PGreedTileLights;
begin
  LLights := FParts.SpriteLogic.RealLight;
  if Assigned(LLights) then
    FillChar(LLights^, SizeOf(TGreedTileLights), 0);
end;

procedure TGreedGameLogicHost.MoveSprites;
begin
  FParts.SpriteLogic.MoveSprites;
end;

procedure TGreedGameLogicHost.CheckElevators;
begin
  FParts.ElevatorRules.Check(FParts.State.Player, FParts.State.FallRate);
end;

function TGreedGameLogicHost.CheckForSwitch(ATileX, ATileY, AAngle: Integer; ADoubleSwitch: Boolean): Boolean;
begin
  Result := FParts.Switches.CheckForSwitch(ATileX, ATileY, AAngle, ADoubleSwitch);
end;

procedure TGreedGameLogicHost.SwitchWall(ATileX, ATileY, AAngle: Integer; ADoubleSwitch: Boolean);
begin
  FParts.Switches.SwitchWall(ATileX, ATileY, AAngle, ADoubleSwitch);
end;

procedure TGreedGameLogicHost.SetLights(ABlackZ: TGreedFixed);
begin
  FParts.Renderer.SetLights(ABlackZ);
end;

end.
