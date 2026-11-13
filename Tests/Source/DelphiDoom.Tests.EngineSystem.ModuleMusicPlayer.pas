{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the engine system library - the tracker music player   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.EngineSystem.ModuleMusicPlayer;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Logging.Intf,
  DelphiDoom.Mikmod.Intf, DelphiDoom.EngineSystem.Types, DelphiDoom.EngineSystem.Intf,
  DelphiDoom.Tests.EngineSystem.Fakes;

type
  [TestFixture]
  [Category('enginesystem')]
  TTestModuleMusicPlayer = class(TObject)
  private
    FMikMod: TRecordingMikMod;
    FMikModRef: IMikMod;
    FSource: TFakeMikModClientSource;
    FSourceRef: IMikModClientSource;
    FLog: TRecordingLog;
    FLogRef: ILog;
    FPlayer: IModuleMusicPlayer;
    function Calls: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareParametriNulli;
    [Test]
    procedure DovrebbeNonFareNienteSenzaInitialize;
    [Test]
    procedure DovrebbeAprireLaPerifericaConLeImpostazioniDiSempre;
    [Test]
    procedure DovrebbeScrivereUnAvvisoSeLaPerifericaNonSiApre;
    [Test]
    procedure DovrebbeSuonareUnModuloInMemoria;
    [Test]
    procedure DovrebbeScrivereUnAvvisoSeIlModuloNonSiCarica;
    [Test]
    procedure DovrebbeMettereInPausaSoloSeNonELo;
    [Test]
    procedure DovrebbeRiprendereSoloSeInPausa;
    [Test]
    procedure DovrebbeIgnorareGliErroriSeNonCeNienteCaricato;
    [Test]
    procedure DovrebbeTradurreIlVolumeDelMenu;
    [Test]
    procedure DovrebbeLimitareIlVolumeAlleVociDellaTabella;
    [Test]
    procedure DovrebbeLasciareIlClientAllaFine;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Mikmod.Provider, DelphiDoom.EngineSystem.ModuleMusicPlayer,
  DelphiDoom.EngineSystem.MikModProviderSource, DelphiDoom.EngineSystem.Factory,
  DelphiDoom.Tests.EngineSystem.Legacy;

{ TTestModuleMusicPlayer }

procedure TTestModuleMusicPlayer.Setup;
begin
  FMikMod := TRecordingMikMod.Create;
  FMikModRef := FMikMod;
  FSource := TFakeMikModClientSource.Create(FMikMod);
  FSourceRef := FSource;
  FLog := TRecordingLog.Create;
  FLogRef := FLog;
  FPlayer := TModuleMusicPlayer.Create(FSourceRef, FLogRef,
    function: NativeUInt
    begin
      Result := 7;
    end);
end;

procedure TTestModuleMusicPlayer.TearDown;
begin
  FPlayer := nil;
  FLogRef := nil;
  FSourceRef := nil;
  FMikModRef := nil;
end;

function TTestModuleMusicPlayer.Calls: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FMikMod.Calls.Count - 1 do
  begin
    if LIndex > 0 then
      Result := Result + ';';
    Result := Result + FMikMod.Calls[LIndex];
  end;
end;

procedure TTestModuleMusicPlayer.DovrebbeRifiutareParametriNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TModuleMusicPlayer.Create(nil, FLogRef,
        function: NativeUInt
        begin
          Result := 0;
        end);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TModuleMusicPlayer.Create(FSourceRef, nil,
        function: NativeUInt
        begin
          Result := 0;
        end);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TModuleMusicPlayer.Create(FSourceRef, FLogRef, nil);
    end, EArgumentNilException);
end;

procedure TTestModuleMusicPlayer.DovrebbeNonFareNienteSenzaInitialize;
begin
  FPlayer.Play(nil, 10);
  FPlayer.Pause;
  FPlayer.Resume;
  FPlayer.Stop;
  FPlayer.SetVolume(5);
  FPlayer.Process;
  Assert.AreEqual('', Calls);
end;

procedure TTestModuleMusicPlayer.DovrebbeAprireLaPerifericaConLeImpostazioniDiSempre;
begin
  FPlayer.Initialize;
  Assert.AreEqual('initialize 44100 True True True 7 0', FMikMod.Calls[0]);
end;

procedure TTestModuleMusicPlayer.DovrebbeScrivereUnAvvisoSeLaPerifericaNonSiApre;
begin
  FMikMod.InitializeResult := MIKMOD_ERR_INIT;
  FPlayer.Initialize;
  Assert.AreEqual(1, FLog.Entries.Count);
  Assert.IsTrue(Pos('W:I_InitMik(): MikMod error', FLog.Entries[0]) = 1);
  // not initialized: nothing works
  FPlayer.Process;
  Assert.AreEqual(1, FMikMod.Calls.Count);
end;

procedure TTestModuleMusicPlayer.DovrebbeSuonareUnModuloInMemoria;
begin
  FPlayer.Initialize;
  FPlayer.Play(@FMikMod, 99);
  Assert.AreEqual('load 99', FMikMod.Calls[FMikMod.Calls.Count - 2]);
  Assert.AreEqual('play True', FMikMod.Calls[FMikMod.Calls.Count - 1]);
end;

procedure TTestModuleMusicPlayer.DovrebbeScrivereUnAvvisoSeIlModuloNonSiCarica;
begin
  FPlayer.Initialize;
  FMikMod.LoadResult := MIKMOD_ERR_LOAD_MODULE;
  FPlayer.Play(@FMikMod, 99);
  Assert.IsTrue(Pos('W:I_PlayMik(): MikMod error', FLog.Entries[0]) = 1);
  Assert.AreEqual(1, FLog.Entries.Count);
end;

procedure TTestModuleMusicPlayer.DovrebbeMettereInPausaSoloSeNonELo;
begin
  FPlayer.Initialize;
  FPlayer.Pause;
  FPlayer.Pause;
  // the second call finds the music paused and does nothing
  Assert.AreEqual(2, FMikMod.Calls.Count);
end;

procedure TTestModuleMusicPlayer.DovrebbeRiprendereSoloSeInPausa;
begin
  FPlayer.Initialize;
  FPlayer.Resume;
  Assert.AreEqual(1, FMikMod.Calls.Count);
  FPlayer.Pause;
  FPlayer.Resume;
  Assert.AreEqual('paused False', FMikMod.Calls[FMikMod.Calls.Count - 1]);
end;

procedure TTestModuleMusicPlayer.DovrebbeIgnorareGliErroriSeNonCeNienteCaricato;
begin
  FPlayer.Initialize;
  FMikMod.NothingLoaded := True;
  FPlayer.Stop;
  FPlayer.Process;
  FPlayer.SetVolume(4);
  FPlayer.Pause;
  FPlayer.Resume;
  Assert.AreEqual(0, FLog.Entries.Count);
end;

procedure TTestModuleMusicPlayer.DovrebbeTradurreIlVolumeDelMenu;
begin
  FPlayer.Initialize;
  FPlayer.SetVolume(8);
  Assert.AreEqual('volume 68', FMikMod.Calls[FMikMod.Calls.Count - 1]);
  FPlayer.SetVolume(15);
  Assert.AreEqual('volume 127', FMikMod.Calls[FMikMod.Calls.Count - 1]);
end;

procedure TTestModuleMusicPlayer.DovrebbeLimitareIlVolumeAlleVociDellaTabella;
begin
  FPlayer.Initialize;
  FPlayer.SetVolume(-5);
  Assert.AreEqual('volume 9', FMikMod.Calls[FMikMod.Calls.Count - 1]);
  FPlayer.SetVolume(0);
  Assert.AreEqual('volume 9', FMikMod.Calls[FMikMod.Calls.Count - 1]);
  FPlayer.SetVolume(400);
  Assert.AreEqual('volume 127', FMikMod.Calls[FMikMod.Calls.Count - 1]);
end;

procedure TTestModuleMusicPlayer.DovrebbeLasciareIlClientAllaFine;
begin
  FPlayer.Initialize;
  FPlayer.ShutDown;
  Assert.AreEqual(1, FSource.Releases);
  FPlayer.Process;
  Assert.AreEqual('shutdown', FMikMod.Calls[FMikMod.Calls.Count - 1]);
end;

procedure TTestModuleMusicPlayer.DovrebbeDareLeStesseChiamateDelVecchioCodice;
var
  LCase: Integer;
  LStep: Integer;
  LOld: TLegacyMik;
  LOldMikMod: TRecordingMikMod;
  LOldMikModRef: IMikMod;
  LNewMikMod: TRecordingMikMod;
  LNewMikModRef: IMikMod;
  LNewSource: TFakeMikModClientSource;
  LNewSourceRef: IMikModClientSource;
  LNewLog: TRecordingLog;
  LNewLogRef: ILog;
  LNew: IModuleMusicPlayer;
  LOperation: Integer;
  LValue: Integer;
  LWarnings: string;
  LOldWarnings: string;
  LIndex: Integer;
begin
  RandSeed := 1853;
  for LCase := 1 to 300 do
  begin
    LOldMikMod := TRecordingMikMod.Create;
    LOldMikModRef := LOldMikMod;
    LNewMikMod := TRecordingMikMod.Create;
    LNewMikModRef := LNewMikMod;
    LNewSource := TFakeMikModClientSource.Create(LNewMikMod);
    LNewSourceRef := LNewSource;
    LNewLog := TRecordingLog.Create;
    LNewLogRef := LNewLog;
    LOld := TLegacyMik.Create;
    LNew := TModuleMusicPlayer.Create(LNewSourceRef, LNewLogRef,
      function: NativeUInt
      begin
        Result := 7;
      end);
    TMikModProvider.Use(LOldMikModRef);
    try
      for LStep := 1 to 40 do
      begin
        LOperation := Random(10);
        LValue := Random(24) - 4;
        LOldMikMod.NothingLoaded := Random(4) = 0;
        LNewMikMod.NothingLoaded := LOldMikMod.NothingLoaded;
        case LOperation of
          0:
            begin
              LOldMikMod.InitializeResult := Ord(Random(3) = 0) * MIKMOD_ERR_INIT;
              LNewMikMod.InitializeResult := LOldMikMod.InitializeResult;
              LOld.I_InitMik;
              LNew.Initialize;
            end;
          1:
            begin
              LOldMikMod.LoadResult := Ord(Random(3) = 0) * MIKMOD_ERR_LOAD_MODULE;
              LNewMikMod.LoadResult := LOldMikMod.LoadResult;
              LOld.I_PlayMik(@LValue, LValue + 10);
              LNew.Play(@LValue, LValue + 10);
            end;
          2:
            begin
              LOld.I_PauseMik;
              LNew.Pause;
            end;
          3:
            begin
              LOld.I_ResumeMik;
              LNew.Resume;
            end;
          4:
            begin
              LOld.I_StopMik;
              LNew.Stop;
            end;
          5, 6:
            begin
              LOld.I_SetMusicVolumeMik(LValue);
              LNew.SetVolume(LValue);
            end;
          7, 8:
            begin
              LOld.I_ProcessMik;
              LNew.Process;
            end;
          9:
            begin
              LOld.I_ShutDownMik;
              LNew.ShutDown;
              // the provider makes a real tracker when it has no MikMod: give it the fake again
              TMikModProvider.Use(LOldMikModRef);
              LOldMikMod.Paused := False;
              LNewMikMod.Paused := False;
            end;
        end;
        Assert.AreEqual(LOldMikMod.Calls.Text, LNewMikMod.Calls.Text,
          Format('case %d step %d', [LCase, LStep]));
        LWarnings := '';
        for LIndex := 0 to LNewLog.Entries.Count - 1 do
          LWarnings := LWarnings + Copy(LNewLog.Entries[LIndex], 3, MaxInt);
        LOldWarnings := '';
        for LIndex := 0 to LOld.Warnings.Count - 1 do
          LOldWarnings := LOldWarnings + LOld.Warnings[LIndex];
        Assert.AreEqual(LOldWarnings, LWarnings);
      end;
    finally
      TMikModProvider.Release;
      LOld.Free;
      LNew := nil;
    end;
  end;
end;

end.
