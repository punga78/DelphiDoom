{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedGameLoop, TGreedTopDownRenderer and TGreedFrame   }
{                                                                              }
{  The clock, the input and the presenter are fakes: no window, no time         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.GameLoop;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf,
  DelphiDoom.Greed.Frame.Intf, DelphiDoom.Greed.PlayerMovement, DelphiDoom.Greed.GameLoop,
  DelphiDoom.Clock.Intf;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedTopDownRenderer = class(TObject)
  private
    FWorld: IGreedWorld;
    FPlayer: TGreedPlayerRecord;
    FFrame: TGreedFrame;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDisegnareIlGiocatoreAlCentro;
    [Test]
    procedure DovrebbeDisegnarePavimentiMuriEPorte;
    [Test]
    procedure DovrebbeDareZeroFuoriDallaMappa;
    [Test]
    procedure DovrebbeSollevareConUnQuadroTroppoPiccolo;
    [Test]
    procedure DovrebbeCreareUnQuadroEControllareLeMisure;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedGameLoop = class(TObject)
  private
    FWorld: IGreedWorld;
    FPool: TGreedLinkedPool<TGreedElevator>;
    FMovement: TGreedPlayerMovement;
    FLoop: TGreedGameLoop;
    FInput: IGreedInput;
    FClock: IClock;
    FPresenter: IGreedFramePresenter;
    procedure Build(AWithStart: Boolean);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeMettereIlGiocatoreSulPuntoDiPartenza;
    [Test]
    procedure DovrebbeSollevareSenzaPuntoDiPartenza;
    [Test]
    procedure DovrebbeAndareAvantiVersoNord;
    [Test]
    procedure DovrebbeCorrereAPassoPiuLungo;
    [Test]
    procedure DovrebbeGirareESpostarsiDiLato;
    [Test]
    procedure DovrebbeFermarsiControUnMuro;
    [Test]
    procedure DovrebbeGiocareITicDelRelogioEMostrareLeImmagini;
    [Test]
    procedure DovrebbeFermarsiQuandoLaFinestraSiChiude;
    [Test]
    procedure DovrebbeFermarsiConIlTastoDiUscita;
    [Test]
    procedure DovrebbeSaltareITicPersiSeLaFinestraELenta;
    [Test]
    procedure DovrebbeAttenderePrimaDelProssimoTic;
    [Test]
    procedure DovrebbeSollevareConDipendenzeNulle;
  end;

implementation

uses
  DelphiDoom.Greed.Intf, DelphiDoom.Greed.Factory, DelphiDoom.Greed.World, DelphiDoom.Greed.TopDownRenderer,
  DelphiDoom.Tests.Greed.Builders;

type
  TFakeInput = class(TInterfacedObject, IGreedInput)
  public
    Keys: set of TGreedKey;
    PumpsLeft: Integer;
    constructor Create;
    function Pump: Boolean;
    function IsDown(AKey: TGreedKey): Boolean;
  end;

  TQuietHost = class(TInterfacedObject, IGreedMovementHost)
  public
    function GetNetMode: Boolean;
    procedure NetOpenDoor(AX, AY: TGreedFixed);
  end;

  TFakeClock = class(TInterfacedObject, IClock)
  public
    StepsNow: Integer;
    StepsEachCall: Integer;
    Waits: Integer;
    function Seconds: Double;
    function Steps(ARate: Integer): Integer;
    function ScaledSteps(ARate, AScale: Integer): Integer;
    procedure Sleep(AMilliseconds: Integer);
    procedure Wait(AMilliseconds: Integer);
  end;

  TFakePresenter = class(TInterfacedObject, IGreedFramePresenter)
  public
    Count: Integer;
    LastColors: TGreedColors;
    procedure Present(const AFrame: TGreedFrame; const AColors: TGreedColors);
  end;

function TQuietHost.GetNetMode: Boolean;
begin
  Result := False;
end;

procedure TQuietHost.NetOpenDoor(AX, AY: TGreedFixed);
begin
end;

constructor TFakeInput.Create;
begin
  inherited Create;
  PumpsLeft := MaxInt;
end;

function TFakeInput.Pump: Boolean;
begin
  Result := PumpsLeft > 0;
  if Result then
    Dec(PumpsLeft);
end;

function TFakeInput.IsDown(AKey: TGreedKey): Boolean;
begin
  Result := AKey in Keys;
end;

function TFakeClock.Seconds: Double;
begin
  Result := StepsNow / 70;
end;

function TFakeClock.Steps(ARate: Integer): Integer;
begin
  Inc(StepsNow, StepsEachCall);
  Result := StepsNow;
end;

function TFakeClock.ScaledSteps(ARate, AScale: Integer): Integer;
begin
  Result := StepsNow * AScale;
end;

procedure TFakeClock.Sleep(AMilliseconds: Integer);
begin
end;

procedure TFakeClock.Wait(AMilliseconds: Integer);
begin
  Inc(Waits);
end;

procedure TFakePresenter.Present(const AFrame: TGreedFrame; const AColors: TGreedColors);
begin
  Inc(Count);
  LastColors := AColors;
end;

// A room with a floor and a ceiling everywhere; the player starts on the tile (10, 10); AWallAt is the tile that
// has a wall on its north side (-1 for none)
function RoomWorld(AWithStart: Boolean; AWallAt: Integer): IGreedWorld;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  LBytes := TGreedLumps.MapBytes(nil);
  FillChar(LBytes[0], Length(LBytes), 0);
  for LIndex := 0 to 4095 do
  begin
    LBytes[Ord(gpFloorPic) * 4096 + LIndex] := 1;
    LBytes[Ord(gpCeilingHeight) * 4096 + LIndex] := 100;
  end;
  if AWithStart then
    LBytes[Ord(gpMapSprites) * 4096 + 10 * 64 + 10] := 1;
  if AWallAt >= 0 then
    LBytes[Ord(gpNorthWall) * 4096 + AWallAt] := 1;
  Result := TGreedWorld.Create;
  Result.Load(TGreedFactory.CreateMapReader.Read(LBytes));
end;

{ TTestGreedTopDownRenderer }

procedure TTestGreedTopDownRenderer.Setup;
begin
  FWorld := RoomWorld(False, 10 * 64 + 12);
  FFrame := TGreedFrame.Make(320, 200);
  FillChar(FPlayer, SizeOf(FPlayer), 0);
  FPlayer.X := (10 * 64 + 32) * GREED_FRACUNIT;
  FPlayer.Y := (10 * 64 + 32) * GREED_FRACUNIT;
  FPlayer.Angle := 256;
end;

procedure TTestGreedTopDownRenderer.DovrebbeDisegnareIlGiocatoreAlCentro;
begin
  TGreedTopDownRenderer.Create.Render(FWorld, FPlayer, FFrame);
  Assert.AreEqual(Integer(GREED_TOP_DOWN_PLAYER), Integer(FFrame.Pixels[100 * 320 + 160]));
  Assert.AreEqual(Integer(GREED_TOP_DOWN_PLAYER), Integer(FFrame.Pixels[98 * 320 + 158]));
  // the line goes north: up from the center
  Assert.AreEqual(Integer(GREED_TOP_DOWN_PLAYER), Integer(FFrame.Pixels[90 * 320 + 160]));
  Assert.AreNotEqual(Integer(GREED_TOP_DOWN_PLAYER), Integer(FFrame.Pixels[100 * 320 + 175]));
end;

procedure TTestGreedTopDownRenderer.DovrebbeDisegnarePavimentiMuriEPorte;
var
  LDoor: Integer;
begin
  LDoor := FWorld.AddDoor(8, 10);
  Assert.AreEqual(0, LDoor);
  TGreedTopDownRenderer.Create.Render(FWorld, FPlayer, FFrame);
  // the center of the picture is the middle of the tile (10, 10): the floor is around the player
  Assert.AreEqual(Integer(GREED_TOP_DOWN_FLOOR), Integer(FFrame.Pixels[100 * 320 + 175]));
  // the tile (12, 10) starts 2 tiles = 16 pixels after the center minus 4: its north wall is the row of its start
  Assert.AreEqual(Integer(GREED_TOP_DOWN_WALL), Integer(FFrame.Pixels[96 * 320 + 175]));
  // the tile (8, 10) is 2 tiles before: 16 pixels
  Assert.AreEqual(Integer(GREED_TOP_DOWN_DOOR), Integer(FFrame.Pixels[100 * 320 + 142]));
end;

procedure TTestGreedTopDownRenderer.DovrebbeDareZeroFuoriDallaMappa;
begin
  FPlayer.X := 4 * GREED_FRACUNIT;
  FPlayer.Y := 4 * GREED_FRACUNIT;
  TGreedTopDownRenderer.Create.Render(FWorld, FPlayer, FFrame);
  Assert.AreEqual(0, Integer(FFrame.Pixels[5 * 320 + 5]));
end;

procedure TTestGreedTopDownRenderer.DovrebbeSollevareConUnQuadroTroppoPiccolo;
var
  LFrame: TGreedFrame;
  LRaised: Boolean;
begin
  LFrame := TGreedFrame.Make(10, 10);
  LRaised := False;
  try
    TGreedTopDownRenderer.Create.Render(FWorld, FPlayer, LFrame);
  except
    on EGreedException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestGreedTopDownRenderer.DovrebbeCreareUnQuadroEControllareLeMisure;
var
  LRaised: Boolean;
begin
  Assert.AreEqual(64000, Length(TGreedFrame.Make(320, 200).Pixels));
  LRaised := False;
  try
    TGreedFrame.Make(0, 5);
  except
    on EGreedException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

{ TTestGreedGameLoop }

procedure TTestGreedGameLoop.Setup;
begin
  FPool := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
end;

procedure TTestGreedGameLoop.TearDown;
begin
  FreeAndNil(FLoop);
  FreeAndNil(FMovement);
  FreeAndNil(FPool);
end;

procedure TTestGreedGameLoop.Build(AWithStart: Boolean);
var
  LColors: TGreedColors;
begin
  FWorld := RoomWorld(AWithStart, -1);
  FInput := TFakeInput.Create;
  FClock := TFakeClock.Create;
  FPresenter := TFakePresenter.Create;
  FillChar(LColors, SizeOf(LColors), 0);
  LColors[1] := $00112233;
  FreeAndNil(FLoop);
  FreeAndNil(FMovement);
  FMovement := TGreedPlayerMovement.Create(FWorld, TQuietHost.Create);
  FLoop := TGreedGameLoop.Create(FWorld, FMovement, FPool, TGreedTopDownRenderer.Create, FPresenter, FInput,
    FClock, LColors, 320, 200);
end;

procedure TTestGreedGameLoop.DovrebbeMettereIlGiocatoreSulPuntoDiPartenza;
begin
  Build(True);
  FLoop.Start(0);
  Assert.AreEqual((10 * 64 + 32) * GREED_FRACUNIT, FLoop.Player.X);
  Assert.AreEqual((10 * 64 + 32) * GREED_FRACUNIT, FLoop.Player.Y);
  Assert.AreEqual(256, FLoop.Player.Angle);
  Assert.AreEqual(10 * 64 + 10, FLoop.Player.MapSpot);
  Assert.AreEqual(0, Integer(FWorld.GetValue(gpMapSprites, 10 * 64 + 10)), 'the start is taken away from the map');
  Assert.AreEqual(FLoop.Player.Height, FLoop.Player.Z);
end;

procedure TTestGreedGameLoop.DovrebbeSollevareSenzaPuntoDiPartenza;
var
  LRaised: Boolean;
begin
  Build(False);
  LRaised := False;
  try
    FLoop.Start(3);
  except
    on EGreedException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestGreedGameLoop.DovrebbeAndareAvantiVersoNord;
var
  LY: Integer;
begin
  Build(True);
  FLoop.Start(0);
  LY := FLoop.Player.Y;
  TFakeInput(FInput as TObject).Keys := [gkForward];
  FLoop.Tick;
  Assert.AreEqual(LY - GREED_LOOP_WALK_SPEED, FLoop.Player.Y);
  Assert.AreEqual(1, FLoop.Tics);
end;

procedure TTestGreedGameLoop.DovrebbeCorrereAPassoPiuLungo;
var
  LY: Integer;
begin
  Build(True);
  FLoop.Start(0);
  LY := FLoop.Player.Y;
  TFakeInput(FInput as TObject).Keys := [gkForward, gkRun];
  FLoop.Tick;
  Assert.AreEqual(LY - GREED_LOOP_RUN_SPEED, FLoop.Player.Y);
end;

procedure TTestGreedGameLoop.DovrebbeGirareESpostarsiDiLato;
var
  LX: Integer;
begin
  Build(True);
  FLoop.Start(0);
  LX := FLoop.Player.X;
  TFakeInput(FInput as TObject).Keys := [gkTurnLeft];
  FLoop.Tick;
  Assert.AreEqual(256 + GREED_LOOP_TURN_SPEED, FLoop.Player.Angle);
  TFakeInput(FInput as TObject).Keys := [gkTurnRight, gkTurnRight];
  FLoop.Tick;
  Assert.AreEqual(256, FLoop.Player.Angle);
  // to the right of a player that looks north is the east
  TFakeInput(FInput as TObject).Keys := [gkStrafeRight];
  FLoop.Tick;
  Assert.IsTrue(FLoop.Player.X > LX);
  TFakeInput(FInput as TObject).Keys := [gkBackward];
  FLoop.Tick;
  Assert.IsTrue(FLoop.Player.Y > (10 * 64 + 32) * GREED_FRACUNIT);
end;

procedure TTestGreedGameLoop.DovrebbeFermarsiControUnMuro;
var
  LIndex: Integer;
  LColors: TGreedColors;
begin
  FWorld := RoomWorld(True, 10 * 64 + 10);
  FInput := TFakeInput.Create;
  FClock := TFakeClock.Create;
  FPresenter := TFakePresenter.Create;
  FillChar(LColors, SizeOf(LColors), 0);
  FMovement := TGreedPlayerMovement.Create(FWorld, TQuietHost.Create);
  FLoop := TGreedGameLoop.Create(FWorld, FMovement, FPool, TGreedTopDownRenderer.Create, FPresenter, FInput,
    FClock, LColors, 320, 200);
  FLoop.Start(0);
  TFakeInput(FInput as TObject).Keys := [gkForward];
  for LIndex := 1 to 200 do
    FLoop.Tick;
  Assert.IsTrue(FLoop.Player.Y >= 10 * 64 * GREED_FRACUNIT, 'the wall stops the player');
  Assert.IsTrue(FLoop.Player.Y < (10 * 64 + 32) * GREED_FRACUNIT);
end;

procedure TTestGreedGameLoop.DovrebbeGiocareITicDelRelogioEMostrareLeImmagini;
begin
  Build(True);
  FLoop.Start(0);
  TFakeClock(FClock as TObject).StepsEachCall := 3;
  Assert.AreEqual(30, FLoop.Run(30));
  Assert.AreEqual(30, FLoop.Tics);
  Assert.AreEqual(10, TFakePresenter(FPresenter as TObject).Count, 'a picture every 3 tics');
  Assert.AreEqual(Cardinal($00112233), TFakePresenter(FPresenter as TObject).LastColors[1]);
end;

procedure TTestGreedGameLoop.DovrebbeFermarsiQuandoLaFinestraSiChiude;
begin
  Build(True);
  FLoop.Start(0);
  TFakeClock(FClock as TObject).StepsEachCall := 1;
  TFakeInput(FInput as TObject).PumpsLeft := 5;
  Assert.AreEqual(5, FLoop.Run(0));
end;

procedure TTestGreedGameLoop.DovrebbeFermarsiConIlTastoDiUscita;
begin
  Build(True);
  FLoop.Start(0);
  TFakeInput(FInput as TObject).Keys := [gkQuit];
  Assert.AreEqual(0, FLoop.Run(0));
end;

procedure TTestGreedGameLoop.DovrebbeSaltareITicPersiSeLaFinestraELenta;
begin
  Build(True);
  FLoop.Start(0);
  TFakeClock(FClock as TObject).StepsEachCall := 500;
  TFakeInput(FInput as TObject).PumpsLeft := 1;
  Assert.AreEqual(GREED_LOOP_MAX_CATCH_UP, FLoop.Run(0));
end;

procedure TTestGreedGameLoop.DovrebbeAttenderePrimaDelProssimoTic;
begin
  Build(True);
  FLoop.Start(0);
  TFakeClock(FClock as TObject).StepsEachCall := 0;
  TFakeInput(FInput as TObject).PumpsLeft := 4;
  Assert.AreEqual(0, FLoop.Run(0));
  Assert.AreEqual(4, TFakeClock(FClock as TObject).Waits);
end;

procedure TTestGreedGameLoop.DovrebbeSollevareConDipendenzeNulle;
var
  LColors: TGreedColors;
  LRaised: Boolean;
begin
  Build(True);
  FillChar(LColors, SizeOf(LColors), 0);
  LRaised := False;
  try
    TGreedGameLoop.Create(FWorld, FMovement, FPool, nil, FPresenter, FInput, FClock, LColors, 320, 200).Free;
  except
    on EArgumentNilException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

end.
