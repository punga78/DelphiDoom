{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the engine of MikMod made with the Pascal tracker      }
{                                                                              }
{  Nothing is played here: no audio device is opened                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Mikmod.TrackerEngine;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Mikmod.Intf,
  DelphiDoom.Mikmod.TrackerEngine;

type
  [TestFixture]
  [Category('mikmod')]
  TTestTrackerMikModEngine = class(TObject)
  private
    FMikMod: IMikMod;
    function MinimalMod: TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNonInizializzatoPrimaDiInitialize;
    [Test]
    procedure TestFrequenzaFuoriLimitiVieneRifiutata;
    [Test]
    procedure TestInizializzaUnaVolta;
    [Test]
    procedure TestSpegnimento;
    [Test]
    procedure TestUnSoloPlayerAlLaVolta;
    [Test]
    procedure TestIlPlayerLiberatoLasciaIlPosto;
    [Test]
    procedure TestCreaPlayerSenzaInizializzare;
    [Test]
    procedure TestCaricaUnModuloValido;
    [Test]
    procedure TestRifiutaDatiNonValidi;
    [Test]
    procedure TestCaricaDaFile;
    [Test]
    procedure TestSenzaModuloNonSiSuona;
    [Test]
    procedure TestVolumeFuoriLimiti;
    [Test]
    procedure TestNonStaSuonandoPrimaDiPlay;
  end;

implementation

uses
  System.IOUtils;

const
  SOME_RATE = 22050;

{ TTestTrackerMikModEngine }

procedure TTestTrackerMikModEngine.Setup;
begin
  FMikMod := TTrackerMikModEngine.Create;
end;

procedure TTestTrackerMikModEngine.TearDown;
begin
  FMikMod := nil;
end;

// A MOD of four channels with one empty pattern and no samples
function TTestTrackerMikModEngine.MinimalMod: TBytes;
begin
  SetLength(Result, 1084 + 1024);
  Result[950] := 1;
  Result[1080] := Ord('M');
  Result[1081] := Ord('.');
  Result[1082] := Ord('K');
  Result[1083] := Ord('.');
end;

procedure TTestTrackerMikModEngine.TestNonInizializzatoPrimaDiInitialize;
begin
  Assert.IsFalse(FMikMod.IsInitialized);
end;

procedure TTestTrackerMikModEngine.TestFrequenzaFuoriLimitiVieneRifiutata;
begin
  Assert.AreEqual(MIKMOD_ERR_INVALID_ARGUMENT, FMikMod.Initialize(100, True, True, True, 0, 0));
  Assert.AreEqual(MIKMOD_ERR_INVALID_ARGUMENT, FMikMod.Initialize(70000, True, True, True, 0, 0));
  Assert.AreEqual(MIKMOD_ERR_INVALID_ARGUMENT, FMikMod.Initialize(SOME_RATE, True, True, True, 0, -1));
  Assert.IsFalse(FMikMod.IsInitialized);
end;

procedure TTestTrackerMikModEngine.TestInizializzaUnaVolta;
begin
  Assert.AreEqual(MIKMOD_OK, FMikMod.Initialize(SOME_RATE, True, True, True, 0, 0));
  Assert.IsTrue(FMikMod.IsInitialized);
  Assert.AreEqual(MIKMOD_ERR_ALREADY_INITIALIZED, FMikMod.Initialize(SOME_RATE, True, True, True, 0, 0));
end;

procedure TTestTrackerMikModEngine.TestSpegnimento;
begin
  FMikMod.Initialize(SOME_RATE, True, True, True, 0, 0);

  FMikMod.Shutdown;

  Assert.IsFalse(FMikMod.IsInitialized);
  Assert.AreEqual(MIKMOD_OK, FMikMod.Initialize(SOME_RATE, True, True, True, 0, 0));
end;

procedure TTestTrackerMikModEngine.TestCreaPlayerSenzaInizializzare;
var
  LPlayer: IMikModPlayer;
begin
  Assert.AreEqual(MIKMOD_ERR_NOT_INITIALIZED, FMikMod.CreatePlayer(LPlayer));
  Assert.IsNull(Pointer(LPlayer));
end;

procedure TTestTrackerMikModEngine.TestUnSoloPlayerAlLaVolta;
var
  LFirst, LSecond: IMikModPlayer;
begin
  FMikMod.Initialize(SOME_RATE, True, True, True, 0, 0);

  Assert.AreEqual(MIKMOD_OK, FMikMod.CreatePlayer(LFirst));
  Assert.AreEqual(MIKMOD_ERR_BUSY, FMikMod.CreatePlayer(LSecond));
  Assert.IsNull(Pointer(LSecond));
end;

procedure TTestTrackerMikModEngine.TestIlPlayerLiberatoLasciaIlPosto;
var
  LFirst, LSecond: IMikModPlayer;
begin
  FMikMod.Initialize(SOME_RATE, True, True, True, 0, 0);
  FMikMod.CreatePlayer(LFirst);

  LFirst := nil;

  Assert.AreEqual(MIKMOD_OK, FMikMod.CreatePlayer(LSecond));
end;

procedure TTestTrackerMikModEngine.TestCaricaUnModuloValido;
var
  LPlayer: IMikModPlayer;
  LData: TBytes;
begin
  FMikMod.Initialize(SOME_RATE, True, True, True, 0, 0);
  FMikMod.CreatePlayer(LPlayer);
  LData := MinimalMod;

  Assert.AreEqual(MIKMOD_OK, LPlayer.LoadFromMemory(@LData[0], Length(LData)));
end;

procedure TTestTrackerMikModEngine.TestRifiutaDatiNonValidi;
var
  LPlayer: IMikModPlayer;
  LGarbage: TBytes;
begin
  FMikMod.Initialize(SOME_RATE, True, True, True, 0, 0);
  FMikMod.CreatePlayer(LPlayer);
  LGarbage := TEncoding.ASCII.GetBytes('this is not a module');

  Assert.AreEqual(MIKMOD_ERR_INVALID_ARGUMENT, LPlayer.LoadFromMemory(nil, 10));
  Assert.AreEqual(MIKMOD_ERR_INVALID_ARGUMENT, LPlayer.LoadFromMemory(@LGarbage[0], 0));
  Assert.AreEqual(MIKMOD_ERR_LOAD_MODULE, LPlayer.LoadFromMemory(@LGarbage[0], Length(LGarbage)));
  Assert.AreEqual(MIKMOD_ERR_INVALID_ARGUMENT, LPlayer.LoadFromFile(nil));
  Assert.AreEqual(MIKMOD_ERR_LOAD_MODULE,
    LPlayer.LoadFromFile(PAnsiChar('no_such_dir_ddmikmod\missing.mod')));
end;

procedure TTestTrackerMikModEngine.TestCaricaDaFile;
var
  LPlayer: IMikModPlayer;
  LPath: string;
begin
  FMikMod.Initialize(SOME_RATE, True, True, True, 0, 0);
  FMikMod.CreatePlayer(LPlayer);
  LPath := TPath.Combine(TPath.GetTempPath, 'ddmikmod_test_' + IntToStr(Random(MaxInt)) + '.mod');
  TFile.WriteAllBytes(LPath, MinimalMod);
  try
    Assert.AreEqual(MIKMOD_OK, LPlayer.LoadFromFile(PAnsiChar(AnsiString(LPath))));
  finally
    TFile.Delete(LPath);
  end;
end;

procedure TTestTrackerMikModEngine.TestSenzaModuloNonSiSuona;
var
  LPlayer: IMikModPlayer;
begin
  FMikMod.Initialize(SOME_RATE, True, True, True, 0, 0);
  FMikMod.CreatePlayer(LPlayer);

  Assert.AreEqual(MIKMOD_ERR_NO_MODULE, LPlayer.Play(False));
  Assert.AreEqual(MIKMOD_ERR_NO_MODULE, LPlayer.SetPaused(True));
  Assert.AreEqual(MIKMOD_OK, LPlayer.Stop);
end;

procedure TTestTrackerMikModEngine.TestVolumeFuoriLimiti;
var
  LPlayer: IMikModPlayer;
begin
  FMikMod.Initialize(SOME_RATE, True, True, True, 0, 0);
  FMikMod.CreatePlayer(LPlayer);

  Assert.AreEqual(MIKMOD_ERR_INVALID_ARGUMENT, LPlayer.SetVolume(-1));
  Assert.AreEqual(MIKMOD_ERR_INVALID_ARGUMENT, LPlayer.SetVolume(MIKMOD_MAX_VOLUME + 1));
  Assert.AreEqual(MIKMOD_OK, LPlayer.SetVolume(MIKMOD_MAX_VOLUME));
  Assert.AreEqual(MIKMOD_OK, LPlayer.SetVolume(0));
end;

procedure TTestTrackerMikModEngine.TestNonStaSuonandoPrimaDiPlay;
var
  LPlayer: IMikModPlayer;
  LData: TBytes;
begin
  FMikMod.Initialize(SOME_RATE, True, True, True, 0, 0);
  FMikMod.CreatePlayer(LPlayer);
  LData := MinimalMod;
  LPlayer.LoadFromMemory(@LData[0], Length(LData));

  Assert.IsFalse(LPlayer.IsPlaying);
  Assert.IsFalse(LPlayer.IsPaused);
  Assert.AreEqual(MIKMOD_OK, LPlayer.Update);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTrackerMikModEngine);

end.
