{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TMikModEngine                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mikmod.Engine;

{
  NOT covered here, on purpose: a successful IMikMod.Initialize and everything
  that needs the players (load, play, pause, volume, update). They load the
  embedded MikWin.dll and open the audio device (DirectSound), which the tests
  must never do: no audio, no window, no sleep. The accepted calls are proved
  by the client tests (against a fake) and by running the game with a music
  module, see "Build e prove" in CLAUDE.md.

  What is covered is everything the engine decides before touching the sound
  library: argument validation and the state machine of an engine that has
  not been initialised.
}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Mikmod.Intf;

type
  [TestFixture]
  [Category('mikmod')]
  TTestMikModEngine = class(TObject)
  private
    // Always held as an interface: the engine is reference counted
    FMikMod: IMikMod;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestVersionIsLibmikmod3_1_5;
    [Test]
    procedure TestIsNotInitializedAfterCreate;
    [Test]
    procedure TestCreatePlayerBeforeInitializeReturnsNotInitialized;
    [Test]
    procedure TestShutdownWithoutInitializeIsHarmless;
    [Test]
    [TestCase('Zero', '0')]
    [TestCase('Troppo bassa', '3999')]
    [TestCase('Troppo alta', '65536')]
    procedure TestInitializeRejectsInvalidFrequency(AFrequency: Integer);
    [Test]
    procedure TestInitializeRejectsNegativeBufferSize;
    [Test]
    procedure TestRejectedInitializeLeavesTheEngineUnusable;
    [Test]
    procedure TestLastErrorIsEmptyAtStart;
    [Test]
    procedure TestLastErrorWithoutBufferReturnsTheLength;
    [Test]
    procedure TestLastErrorTerminatesTheBuffer;
  end;

implementation

uses
  DelphiDoom.Mikmod.Engine;

{ TTestMikModEngine }

procedure TTestMikModEngine.Setup;
begin
  FMikMod := TMikModEngine.Create;
end;

procedure TTestMikModEngine.TearDown;
begin
  FMikMod := nil;
end;

procedure TTestMikModEngine.TestVersionIsLibmikmod3_1_5;
begin
  Assert.AreEqual($030105, Integer(FMikMod.GetVersion));
end;

procedure TTestMikModEngine.TestIsNotInitializedAfterCreate;
begin
  Assert.IsFalse(FMikMod.IsInitialized);
end;

procedure TTestMikModEngine.TestCreatePlayerBeforeInitializeReturnsNotInitialized;
var
  LPlayer: IMikModPlayer;
begin
  Assert.AreEqual(MIKMOD_ERR_NOT_INITIALIZED, FMikMod.CreatePlayer(LPlayer));
  Assert.IsFalse(Assigned(LPlayer));
end;

procedure TTestMikModEngine.TestShutdownWithoutInitializeIsHarmless;
begin
  FMikMod.Shutdown;
  FMikMod.Shutdown;

  Assert.IsFalse(FMikMod.IsInitialized);
end;

procedure TTestMikModEngine.TestInitializeRejectsInvalidFrequency(
  AFrequency: Integer);
begin
  Assert.AreEqual(MIKMOD_ERR_INVALID_ARGUMENT,
    FMikMod.Initialize(Cardinal(AFrequency), True, True, True, 0, 0));
  Assert.IsFalse(FMikMod.IsInitialized);
end;

procedure TTestMikModEngine.TestInitializeRejectsNegativeBufferSize;
begin
  Assert.AreEqual(MIKMOD_ERR_INVALID_ARGUMENT,
    FMikMod.Initialize(44100, True, True, True, 0, -1));
  Assert.IsFalse(FMikMod.IsInitialized);
end;

procedure TTestMikModEngine.TestRejectedInitializeLeavesTheEngineUnusable;
var
  LPlayer: IMikModPlayer;
begin
  FMikMod.Initialize(0, True, True, True, 0, 0);

  Assert.AreEqual(MIKMOD_ERR_NOT_INITIALIZED, FMikMod.CreatePlayer(LPlayer));
end;

procedure TTestMikModEngine.TestLastErrorIsEmptyAtStart;
var
  LBuffer: array[0..15] of AnsiChar;
begin
  LBuffer[0] := 'x';

  Assert.AreEqual(0, Integer(FMikMod.GetLastError(@LBuffer[0], Length(LBuffer))));
  Assert.AreEqual(0, Integer(Ord(LBuffer[0])));
end;

procedure TTestMikModEngine.TestLastErrorWithoutBufferReturnsTheLength;
begin
  Assert.AreEqual(0, Integer(FMikMod.GetLastError(nil, 0)));
  Assert.AreEqual(0, Integer(FMikMod.GetLastError(nil, 100)));
end;

procedure TTestMikModEngine.TestLastErrorTerminatesTheBuffer;
var
  LBuffer: array[0..3] of AnsiChar;
begin
  LBuffer[0] := 'a';
  LBuffer[1] := 'b';

  // A zero sized buffer must stay untouched
  FMikMod.GetLastError(@LBuffer[0], 0);
  Assert.AreEqual(Ord('a'), Integer(Ord(LBuffer[0])));

  FMikMod.GetLastError(@LBuffer[0], Length(LBuffer));
  Assert.AreEqual(0, Integer(Ord(LBuffer[0])));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMikModEngine);

end.
