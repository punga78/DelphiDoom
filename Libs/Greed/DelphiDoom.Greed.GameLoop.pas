{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the loop of the game: tics, input, picture       }
{  Port of xGreed (Jim Valavanis, GPL v2 or later), the part of PlayLoop of     }
{  raven.pas that moves the player; the rest of the logic is not ported yet     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.GameLoop;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Frame.Intf,
  DelphiDoom.Greed.PlayerMovement, DelphiDoom.Greed.Elevator.Intf, DelphiDoom.Greed.ElevatorRules,
  DelphiDoom.Clock.Intf, DelphiDoom.Greed.DoorRules;

const
  /// <summary>TICRATE: the game runs at 70 tics a second</summary>
  GREED_LOOP_TIC_RATE = 70;
  /// <summary>Tics that the loop catches up at most in one picture (a slow window must not freeze the game)</summary>
  GREED_LOOP_MAX_CATCH_UP = 10;
  /// <summary>The angles that the player turns in a tic (of 1024 in the circle)</summary>
  GREED_LOOP_TURN_SPEED = 8;
  /// <summary>The distance of a step in a tic, walking and running (fixed point)</summary>
  GREED_LOOP_WALK_SPEED = 4 * GREED_FRACUNIT;
  GREED_LOOP_RUN_SPEED = 8 * GREED_FRACUNIT;

type
  /// <summary>
  ///   The tics of the game and the picture. A tic reads the keys and moves the player with TGreedPlayerMovement
  ///   (the original ControlMovement has acceleration, bobbing, jumping and weapons: not ported; the speeds are
  ///   constant) and then moves the elevators of the level; a picture asks the renderer for the view and gives it
  ///   to the presenter. The time of the game is the clock: the tics that must have run are
  ///   Steps(GREED_LOOP_TIC_RATE)
  /// </summary>
  TGreedGameLoop = class
  strict private
    type
      TElevatorHost = class(TInterfacedObject, IGreedElevatorHost)
      strict private
        FLoop: TGreedGameLoop;
      public
        constructor Create(ALoop: TGreedGameLoop);
        function GetTimeCount: Integer;
        procedure PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
        procedure RunEvent(AEvent: Integer);
      end;
  strict private
    FWorld: IGreedWorld;
    FMovement: TGreedPlayerMovement;
    FElevators: TGreedElevatorRules;
    FRenderer: IGreedFrameRenderer;
    FPresenter: IGreedFramePresenter;
    FInput: IGreedInput;
    FClock: IClock;
    FColors: TGreedColors;
    FFrame: TGreedFrame;
    FPlayer: TGreedPlayerRecord;
    FFallRate: Integer;
    FTics: Integer;
    FDoors: TGreedDoorRules;
    procedure Move(AAngle: Integer; ASpeed: TGreedFixed);
  public
    constructor Create(const AWorld: IGreedWorld; const AMovement: TGreedPlayerMovement;
      const AElevatorList: TGreedLinkedPool<TGreedElevator>; const ARenderer: IGreedFrameRenderer;
      const APresenter: IGreedFramePresenter; const AInput: IGreedInput; const AClock: IClock;
      const AColors: TGreedColors; AFrameWidth, AFrameHeight: Integer);
    destructor Destroy; override;
    /// <summary>
    ///   A new game on the map that the world holds: the record of the first character and the player on its start
    ///   tile (mapsprites 1, the center of the tile, looking north), as ActivateSpritesFromMap and SpawnSprite do.
    ///   EGreedException if the map has no start
    /// </summary>
    procedure Start(AMapNumber: Integer);
    /// <summary>One tic of the game</summary>
    procedure Tick;
    /// <summary>The renderer draws the view and the presenter shows it</summary>
    procedure Frame;
    /// <summary>
    ///   Runs until the input says to quit (the window was closed, or the quit key) or AMaxTics tics were played
    ///   (0 = no limit); returns the tics played
    /// </summary>
    function Run(AMaxTics: Integer): Integer;
    /// <summary>The rules of the doors (CheckDoors), run at each tic; nil: the doors do not move. Not owned</summary>
    property Doors: TGreedDoorRules read FDoors write FDoors;
    property Player: TGreedPlayerRecord read FPlayer;
    property Tics: Integer read FTics;
    property FrameBuffer: TGreedFrame read FFrame;
  end;

implementation

uses
  DelphiDoom.Greed.PlayerRules, DelphiDoom.Greed.Terrain;

{ TGreedGameLoop.TElevatorHost }

constructor TGreedGameLoop.TElevatorHost.Create(ALoop: TGreedGameLoop);
begin
  inherited Create;
  FLoop := ALoop;
end;

function TGreedGameLoop.TElevatorHost.GetTimeCount: Integer;
begin
  Result := FLoop.FTics;
end;

procedure TGreedGameLoop.TElevatorHost.PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
begin
  // the sound device is not connected to the loop
end;

procedure TGreedGameLoop.TElevatorHost.RunEvent(AEvent: Integer);
begin
  // the scripts of the level (RunEvent of event.pas) are not ported yet
end;

{ TGreedGameLoop }

constructor TGreedGameLoop.Create(const AWorld: IGreedWorld; const AMovement: TGreedPlayerMovement;
  const AElevatorList: TGreedLinkedPool<TGreedElevator>; const ARenderer: IGreedFrameRenderer;
  const APresenter: IGreedFramePresenter; const AInput: IGreedInput; const AClock: IClock;
  const AColors: TGreedColors; AFrameWidth, AFrameHeight: Integer);
begin
  inherited Create;
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  if not Assigned(AMovement) then
    raise EArgumentNilException.Create('AMovement');
  if not Assigned(AElevatorList) then
    raise EArgumentNilException.Create('AElevatorList');
  if not Assigned(ARenderer) then
    raise EArgumentNilException.Create('ARenderer');
  if not Assigned(APresenter) then
    raise EArgumentNilException.Create('APresenter');
  if not Assigned(AInput) then
    raise EArgumentNilException.Create('AInput');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FWorld := AWorld;
  FMovement := AMovement;
  FRenderer := ARenderer;
  FPresenter := APresenter;
  FInput := AInput;
  FClock := AClock;
  FColors := AColors;
  FFrame := TGreedFrame.Make(AFrameWidth, AFrameHeight);
  FElevators := TGreedElevatorRules.Create(AWorld, AElevatorList, TElevatorHost.Create(Self));
end;

destructor TGreedGameLoop.Destroy;
begin
  FreeAndNil(FElevators);
  inherited Destroy;
end;

procedure TGreedGameLoop.Start(AMapNumber: Integer);
var
  LSpot: Integer;
begin
  TGreedPlayerRules.NewPlayer(FPlayer, AMapNumber, 0, 1, 0, FFrame.Height);
  for LSpot := 0 to GREED_MAP_TILES - 1 do
    if FWorld.GetValue(gpMapSprites, LSpot) = 1 then
    begin
      FPlayer.X := ((LSpot mod GREED_MAP_SIZE) * 64 + 32) * GREED_FRACUNIT;
      FPlayer.Y := ((LSpot div GREED_MAP_SIZE) * 64 + 32) * GREED_FRACUNIT;
      FPlayer.Z := TGreedTerrain.FloorZ(FWorld, FPlayer.X, FPlayer.Y) + FPlayer.Height;
      FPlayer.MapSpot := LSpot;
      FPlayer.Angle := 256;
      FWorld.SetValue(gpMapSprites, LSpot, 0);
      FFallRate := 0;
      FTics := 0;
      Exit;
    end;
  raise EGreedException.CreateFmt(SGreedNoPlayerStart, [AMapNumber]);
end;

procedure TGreedGameLoop.Move(AAngle: Integer; ASpeed: TGreedFixed);
begin
  FMovement.Thrust(FPlayer, AAngle, ASpeed);
end;

procedure TGreedGameLoop.Tick;
var
  LSpeed: TGreedFixed;
begin
  if FInput.IsDown(gkTurnLeft) then
    FPlayer.Angle := (FPlayer.Angle + GREED_LOOP_TURN_SPEED) and GREED_ANGLES;
  if FInput.IsDown(gkTurnRight) then
    FPlayer.Angle := (FPlayer.Angle - GREED_LOOP_TURN_SPEED) and GREED_ANGLES;
  if FInput.IsDown(gkRun) then
    LSpeed := GREED_LOOP_RUN_SPEED
  else
    LSpeed := GREED_LOOP_WALK_SPEED;
  if FInput.IsDown(gkForward) then
    Move(FPlayer.Angle, LSpeed);
  if FInput.IsDown(gkBackward) then
    Move(FPlayer.Angle + 512, LSpeed);
  if FInput.IsDown(gkStrafeLeft) then
    Move(FPlayer.Angle + 256, LSpeed);
  if FInput.IsDown(gkStrafeRight) then
    Move(FPlayer.Angle - 256, LSpeed);
  // the player stays on the floor (the original falls with the fall rate: not ported)
  FPlayer.Z := TGreedTerrain.FloorZ(FWorld, FPlayer.X, FPlayer.Y) + FPlayer.Height;
  FElevators.Check(FPlayer, FFallRate);
  if Assigned(FDoors) then
    FDoors.Check(FPlayer.X, FPlayer.Y);
  Inc(FTics);
end;

procedure TGreedGameLoop.Frame;
begin
  FRenderer.Render(FWorld, FPlayer, FFrame);
  FPresenter.Present(FFrame, FColors);
end;

function TGreedGameLoop.Run(AMaxTics: Integer): Integer;
var
  LTarget, LBehind, LPlayed: Integer;
begin
  Result := 0;
  while FInput.Pump and not FInput.IsDown(gkQuit) do
  begin
    LTarget := FClock.Steps(GREED_LOOP_TIC_RATE);
    LBehind := LTarget - FTics;
    if LBehind > GREED_LOOP_MAX_CATCH_UP then
    begin
      // the window was too slow: the game does not run all the tics it lost
      FTics := LTarget - GREED_LOOP_MAX_CATCH_UP;
      LBehind := GREED_LOOP_MAX_CATCH_UP;
    end;
    LPlayed := 0;
    while (LPlayed < LBehind) and ((AMaxTics = 0) or (Result < AMaxTics)) do
    begin
      Tick;
      Inc(LPlayed);
      Inc(Result);
    end;
    Frame;
    if (AMaxTics > 0) and (Result >= AMaxTics) then
      Break;
    if LPlayed = 0 then
      FClock.Wait(1);
  end;
end;

end.
