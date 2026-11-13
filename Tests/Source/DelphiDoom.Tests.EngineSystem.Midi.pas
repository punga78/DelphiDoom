{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the engine system library - the MIDI classes           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.EngineSystem.Midi;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Logging.Intf,
  DelphiDoom.EngineSystem.Types, DelphiDoom.EngineSystem.Intf, DelphiDoom.Tests.EngineSystem.Fakes;

type
  [TestFixture]
  [Category('enginesystem')]
  TTestMidiPlayerSelection = class(TObject)
  public
    [Test]
    procedure DovrebbeLasciareLaScelteConfigurataSenzaOpzioni;
    [Test]
    procedure DovrebbeLeggereLeTreOpzioni;
    [Test]
    procedure DovrebbeDareLUltimaOpzioneNellOrdineDelCodice;
    [Test]
    procedure DovrebbeRiconoscereIlPlayerLegacy;
    [Test]
    procedure DovrebbeDareIlMapperSenzaOpzione;
    [Test]
    procedure DovrebbeLeggereLaPeriferica;
    [Test]
    procedure DovrebbeDareIlMapperSeLaPerifericaManca;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDelVecchioCodice;
    [Test]
    procedure DovrebbeLeggereLaPerifericaComeAtoui;
  end;

  [TestFixture]
  [Category('enginesystem')]
  TTestMidiPlaylist = class(TObject)
  public
    [Test]
    procedure DovrebbeEssereVuotaAllInizio;
    [Test]
    procedure DovrebbeSelezionareUnaCanzone;
    [Test]
    procedure DovrebbeRifiutareUnIndiceFuoriDallaLista;
    [Test]
    procedure DovrebbeAndareAvantiInCerchio;
    [Test]
    procedure DovrebbeSvuotarsiERipartireDaZero;
    [Test]
    procedure DovrebbeMaiuscolizzareSoloLeLettereAscii;
  end;

  [TestFixture]
  [Category('enginesystem')]
  TTestLegacyMidiPlayer = class(TObject)
  private
    FSequencer: TFakeMciSequencer;
    FSequencerRef: IMciSequencer;
    FWindow: TFakeNotifyWindow;
    FWindowRef: IMidiNotifyWindow;
    FLog: TRecordingLog;
    FLogRef: ILog;
    FPlayer: ILegacyMidiPlayer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareParametriNulli;
    [Test]
    procedure DovrebbeSuonareLaCanzoneCheLeSiDice;
    [Test]
    procedure DovrebbeControllareChLaPortaSiaIlMapper;
    [Test]
    procedure DovrebbeNonSuonareSeLaPortaNonELMapper;
    [Test]
    procedure DovrebbeNonChiudereLaPerifericaSeNonSiApre;
    [Test]
    procedure DovrebbeChiudereLaPerifericaSeLaPortaDaErrore;
    [Test]
    procedure DovrebbeChiudereLaPerifericaSeSuonareDaErrore;
    [Test]
    procedure DovrebbeScrivereIlMessaggioSeLIndiceNonEValido;
    [Test]
    procedure DovrebbePassareAllaCanzoneSuccessivaAllaFine;
    [Test]
    procedure DovrebbeRicominciareSeEUnaCanzoneSola;
    [Test]
    procedure DovrebbeIgnorareUnaNotificaNonRiuscita;
    [Test]
    procedure DovrebbeIgnorareUnaNotificaConLaListaVuota;
    [Test]
    procedure DovrebbeFermareEChiudereLaFinestra;
    [Test]
    procedure DovrebbeFarePausaERiprendere;
    [Test]
    procedure DovrebbeNonFareNienteConVolumeEProcess;
    [Test]
    procedure DovrebbeRicominciareDaCapoConInitialize;
    [Test]
    procedure DovrebbeFermareLaPerifericaConShutDown;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.CommandLine.Factory, DelphiDoom.EngineSystem.Factory,
  DelphiDoom.EngineSystem.MidiPlayerSelection, DelphiDoom.EngineSystem.MidiPlaylist,
  DelphiDoom.EngineSystem.LegacyMidiPlayer, DelphiDoom.Tests.EngineSystem.Legacy;

function Join(AList: TStrings): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to AList.Count - 1 do
  begin
    if LIndex > 0 then
      Result := Result + ';';
    Result := Result + AList[LIndex];
  end;
end;

function Args(const AItems: array of string): TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AItems));
  for LIndex := 0 to High(AItems) do
    Result[LIndex] := AItems[LIndex];
end;

{ TTestMidiPlayerSelection }

procedure TTestMidiPlayerSelection.DovrebbeLasciareLaScelteConfigurataSenzaOpzioni;
begin
  Assert.AreEqual(2, TMidiPlayerSelection.ResolvePlayer(
    TCommandLineFactory.CreateCommandLine(Args(['D'])), 2));
  Assert.AreEqual(0, TMidiPlayerSelection.ResolvePlayer(
    TCommandLineFactory.CreateCommandLine(Args(['D'])), 0));
end;

procedure TTestMidiPlayerSelection.DovrebbeLeggereLeTreOpzioni;
begin
  Assert.AreEqual(MIDI_PLAYER_LEGACY, TMidiPlayerSelection.ResolvePlayer(
    TCommandLineFactory.CreateCommandLine(Args(['D', '-uselegacymidiplayer'])), 2));
  Assert.AreEqual(MIDI_PLAYER_STREAM, TMidiPlayerSelection.ResolvePlayer(
    TCommandLineFactory.CreateCommandLine(Args(['D', '-nouselegacymidiplayer'])), 2));
  Assert.AreEqual(MIDI_PLAYER_INTERNAL, TMidiPlayerSelection.ResolvePlayer(
    TCommandLineFactory.CreateCommandLine(Args(['D', '-internalmidiplayer'])), 1));
end;

procedure TTestMidiPlayerSelection.DovrebbeDareLUltimaOpzioneNellOrdineDelCodice;
begin
  // the order of the questions decides, not the order of the arguments
  Assert.AreEqual(MIDI_PLAYER_INTERNAL, TMidiPlayerSelection.ResolvePlayer(
    TCommandLineFactory.CreateCommandLine(
      Args(['D', '-internalmidiplayer', '-uselegacymidiplayer'])), 0));
end;

procedure TTestMidiPlayerSelection.DovrebbeRiconoscereIlPlayerLegacy;
begin
  Assert.IsTrue(TMidiPlayerSelection.IsLegacy(1));
  Assert.IsFalse(TMidiPlayerSelection.IsLegacy(0));
  Assert.IsFalse(TMidiPlayerSelection.IsLegacy(2));
end;

procedure TTestMidiPlayerSelection.DovrebbeDareIlMapperSenzaOpzione;
begin
  Assert.AreEqual(Cardinal($FFFFFFFF), TMidiPlayerSelection.ResolveDevice(
    TCommandLineFactory.CreateCommandLine(Args(['D'])), $FFFFFFFF));
end;

procedure TTestMidiPlayerSelection.DovrebbeLeggereLaPeriferica;
begin
  Assert.AreEqual(Cardinal(3), TMidiPlayerSelection.ResolveDevice(
    TCommandLineFactory.CreateCommandLine(Args(['D', '-mididevice', '3'])), $FFFFFFFF));
end;

procedure TTestMidiPlayerSelection.DovrebbeDareIlMapperSeLaPerifericaManca;
begin
  Assert.AreEqual(Cardinal(9), TMidiPlayerSelection.ResolveDevice(
    TCommandLineFactory.CreateCommandLine(Args(['D', '-mididevice'])), 9));
  Assert.AreEqual(Cardinal(9), TMidiPlayerSelection.ResolveDevice(
    TCommandLineFactory.CreateCommandLine(Args(['D', '-mididevice', 'ABC'])), 9));
end;

procedure TTestMidiPlayerSelection.DovrebbeLeggereLaPerifericaComeAtoui;
begin
  Assert.AreEqual(Cardinal(16), TMidiPlayerSelection.ParseDevice('0x10', 5));
  Assert.AreEqual(Cardinal(12), TMidiPlayerSelection.ParseDevice('#12', 5));
  Assert.AreEqual(Cardinal(5), TMidiPlayerSelection.ParseDevice('#', 5));
  Assert.AreEqual(Cardinal(5), TMidiPlayerSelection.ParseDevice('0xZZ', 5));
  Assert.AreEqual(Cardinal(5), TMidiPlayerSelection.ParseDevice('', 5));
end;

procedure TTestMidiPlayerSelection.DovrebbeDareLoStessoRisultatoDelVecchioCodice;
const
  WORDS: array[0..12] of string = ('-uselegacymidiplayer', '-nouselegacymidiplayer',
    '-internalmidiplayer', '-mididevice', '2', '0x1F', '#9', 'X', '', '-X', '4294967295', '-1', '#');
var
  LCase: Integer;
  LIndex: Integer;
  LCount: Integer;
  LArguments: TArray<string>;
  LLegacy: TLegacyMidiSelection;
  LConfigured: Integer;
begin
  RandSeed := 1851;
  for LCase := 1 to 3000 do
  begin
    LCount := 1 + Random(7);
    SetLength(LArguments, LCount);
    LArguments[0] := 'D';
    for LIndex := 1 to LCount - 1 do
      LArguments[LIndex] := WORDS[Random(Length(WORDS))];
    LConfigured := Random(3);

    LLegacy := TLegacyMidiSelection.Create(LArguments);
    try
      LLegacy.snd_uselegacymidiplayer := LConfigured;
      LLegacy.I_InitMidi;
      Assert.AreEqual(LLegacy.snd_uselegacymidiplayer, TMidiPlayerSelection.ResolvePlayer(
        TCommandLineFactory.CreateCommandLine(LArguments), LConfigured));
      Assert.AreEqual(LLegacy.uselegacymidiplayer, TMidiPlayerSelection.IsLegacy(
        LLegacy.snd_uselegacymidiplayer));
      Assert.AreEqual(LLegacy.I_SelectDefaultMidiDevice, TMidiPlayerSelection.ResolveDevice(
        TCommandLineFactory.CreateCommandLine(LArguments), $FFFFFFFF));
    finally
      LLegacy.Free;
    end;
  end;
end;

{ TTestMidiPlaylist }

procedure TTestMidiPlaylist.DovrebbeEssereVuotaAllInizio;
var
  LList: TMidiPlaylist;
begin
  LList := TMidiPlaylist.Create;
  try
    Assert.AreEqual(0, LList.Count);
    Assert.AreEqual(0, LList.CurrentIndex);
  finally
    LList.Free;
  end;
end;

procedure TTestMidiPlaylist.DovrebbeSelezionareUnaCanzone;
var
  LList: TMidiPlaylist;
begin
  LList := TMidiPlaylist.Create;
  try
    LList.Add('a.mid');
    LList.Add('b.mid');
    Assert.IsTrue(LList.Select(1));
    Assert.AreEqual('b.mid', LList.CurrentName);
    Assert.AreEqual(1, LList.CurrentIndex);
  finally
    LList.Free;
  end;
end;

procedure TTestMidiPlaylist.DovrebbeRifiutareUnIndiceFuoriDallaLista;
var
  LList: TMidiPlaylist;
begin
  LList := TMidiPlaylist.Create;
  try
    LList.Add('a.mid');
    Assert.IsFalse(LList.Select(-1));
    Assert.IsFalse(LList.Select(1));
    Assert.AreEqual(0, LList.CurrentIndex);
  finally
    LList.Free;
  end;
end;

procedure TTestMidiPlaylist.DovrebbeAndareAvantiInCerchio;
var
  LList: TMidiPlaylist;
begin
  LList := TMidiPlaylist.Create;
  try
    LList.Add('a');
    LList.Add('b');
    LList.Add('c');
    Assert.AreEqual('b', LList.Advance);
    Assert.AreEqual('c', LList.Advance);
    Assert.AreEqual('a', LList.Advance);
  finally
    LList.Free;
  end;
end;

procedure TTestMidiPlaylist.DovrebbeSvuotarsiERipartireDaZero;
var
  LList: TMidiPlaylist;
begin
  LList := TMidiPlaylist.Create;
  try
    LList.Add('a');
    LList.Add('b');
    LList.Select(1);
    LList.Clear;
    Assert.AreEqual(0, LList.Count);
    // the index is not touched by Clear (MidiID of the old code)
    Assert.AreEqual(1, LList.CurrentIndex);
    LList.Reset;
    Assert.AreEqual(0, LList.CurrentIndex);
  finally
    LList.Free;
  end;
end;

procedure TTestMidiPlaylist.DovrebbeMaiuscolizzareSoloLeLettereAscii;
begin
  Assert.AreEqual('ABC DEF.MID', TMidiPlaylist.Normalize('abc Def.mid'));
  Assert.AreEqual('C:\MUSICA\'#$00C8#$00E0'.MID', TMidiPlaylist.Normalize('c:\musica\'#$00C8#$00E0'.mid'));
end;

{ TTestLegacyMidiPlayer }

procedure TTestLegacyMidiPlayer.Setup;
begin
  FSequencer := TFakeMciSequencer.Create;
  FSequencerRef := FSequencer;
  FWindow := TFakeNotifyWindow.Create(100);
  FWindowRef := FWindow;
  FLog := TRecordingLog.Create;
  FLogRef := FLog;
  FPlayer := TEngineSystemFactory.CreateLegacyMidiPlayer(FSequencerRef, FWindowRef, FLogRef);
end;

procedure TTestLegacyMidiPlayer.TearDown;
begin
  FPlayer := nil;
  FLogRef := nil;
  FWindowRef := nil;
  FSequencerRef := nil;
end;

procedure TTestLegacyMidiPlayer.DovrebbeRifiutareParametriNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TLegacyMidiPlayer.Create(nil, FWindowRef, FLogRef);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TLegacyMidiPlayer.Create(FSequencerRef, nil, FLogRef);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TLegacyMidiPlayer.Create(FSequencerRef, FWindowRef, nil);
    end, EArgumentNilException);
end;

procedure TTestLegacyMidiPlayer.DovrebbeSuonareLaCanzoneCheLeSiDice;
begin
  FPlayer.Initialize;
  FPlayer.AddFile('song.mid');
  FPlayer.Play(0);
  Assert.AreEqual('open', Join(FWindow.Commands));
  Assert.AreEqual('open song.mid;port 11;play 11 window=100', Join(FSequencer.Commands));
end;

procedure TTestLegacyMidiPlayer.DovrebbeControllareChLaPortaSiaIlMapper;
begin
  FPlayer.AddFile('a.mid');
  FPlayer.Play(0);
  Assert.AreEqual('open a.mid', FSequencer.Commands[0]);
  Assert.AreEqual('port 11', FSequencer.Commands[1]);
  Assert.AreEqual('', FLog.InfoText);
end;

procedure TTestLegacyMidiPlayer.DovrebbeNonSuonareSeLaPortaNonELMapper;
begin
  FSequencer.IsMapper := False;
  FPlayer.AddFile('a.mid');
  FPlayer.Play(0);
  // the device stays open and nothing plays; the message has no line break
  Assert.AreEqual(2, FSequencer.Commands.Count);
  Assert.AreEqual('MIDI mapper unavailable', FLog.InfoText);
end;

procedure TTestLegacyMidiPlayer.DovrebbeNonChiudereLaPerifericaSeNonSiApre;
begin
  FSequencer.OpenResult := 263;
  FPlayer.AddFile('a.mid');
  FPlayer.Play(0);
  // not even closed: the device did not open
  Assert.AreEqual(1, FSequencer.Commands.Count);
end;

procedure TTestLegacyMidiPlayer.DovrebbeChiudereLaPerifericaSeLaPortaDaErrore;
begin
  FSequencer.StatusResult := 5;
  FPlayer.AddFile('a.mid');
  FPlayer.Play(0);
  Assert.AreEqual('close 11', FSequencer.Commands[FSequencer.Commands.Count - 1]);
end;

procedure TTestLegacyMidiPlayer.DovrebbeChiudereLaPerifericaSeSuonareDaErrore;
begin
  FSequencer.PlayResult := 7;
  FPlayer.AddFile('a.mid');
  FPlayer.Play(0);
  Assert.AreEqual('close 11', FSequencer.Commands[FSequencer.Commands.Count - 1]);
  // no song is current: the end of the song plays the next one
  FSequencer.Commands.Clear;
  FWindow.Notify(True);
  Assert.AreEqual('stop 11', FSequencer.Commands[0]);
end;

procedure TTestLegacyMidiPlayer.DovrebbeScrivereIlMessaggioSeLIndiceNonEValido;
begin
  FPlayer.AddFile('a.mid');
  FPlayer.Play(3);
  Assert.AreEqual('MIDI mapper unavailable', FLog.InfoText);
  Assert.AreEqual(0, FSequencer.Commands.Count);
end;

procedure TTestLegacyMidiPlayer.DovrebbePassareAllaCanzoneSuccessivaAllaFine;
begin
  FPlayer.AddFile('a.mid');
  FPlayer.AddFile('b.mid');
  FPlayer.Play(0);
  FSequencer.Commands.Clear;
  FWindow.Notify(True);
  // the name goes in capitals, as the old code gave it to MCI
  Assert.AreEqual('stop 11;close 11;open B.MID;play 12 window=100',
    Join(FSequencer.Commands));
end;

procedure TTestLegacyMidiPlayer.DovrebbeRicominciareSeEUnaCanzoneSola;
begin
  FPlayer.AddFile('a.mid');
  FPlayer.Play(0);
  FSequencer.Commands.Clear;
  FWindow.Notify(True);
  Assert.AreEqual('seek 11 window=100;play 11 window=100',
    Join(FSequencer.Commands));
end;

procedure TTestLegacyMidiPlayer.DovrebbeIgnorareUnaNotificaNonRiuscita;
begin
  FPlayer.AddFile('a.mid');
  FPlayer.Play(0);
  FSequencer.Commands.Clear;
  FWindow.Notify(False);
  Assert.AreEqual(0, FSequencer.Commands.Count);
end;

procedure TTestLegacyMidiPlayer.DovrebbeIgnorareUnaNotificaConLaListaVuota;
begin
  FPlayer.AddFile('a.mid');
  FPlayer.Play(0);
  FPlayer.ClearPlayList;
  FSequencer.Commands.Clear;
  // the old code raised an error here
  FWindow.Notify(True);
  Assert.AreEqual(0, FSequencer.Commands.Count);
end;

procedure TTestLegacyMidiPlayer.DovrebbeFermareEChiudereLaFinestra;
begin
  FPlayer.AddFile('a.mid');
  FPlayer.Play(0);
  FSequencer.Commands.Clear;
  FPlayer.Stop;
  Assert.AreEqual('stop 11;close 11', Join(FSequencer.Commands));
  Assert.AreEqual('close 100', FWindow.Commands[FWindow.Commands.Count - 1]);
  // stopped: nothing more to stop
  FSequencer.Commands.Clear;
  FPlayer.Stop;
  Assert.AreEqual(0, FSequencer.Commands.Count);
end;

procedure TTestLegacyMidiPlayer.DovrebbeFarePausaERiprendere;
begin
  FPlayer.AddFile('a.mid');
  FPlayer.Play(0);
  FSequencer.Commands.Clear;
  FPlayer.Pause;
  FPlayer.Resume;
  Assert.AreEqual('pause 11;resume 11', Join(FSequencer.Commands));
end;

procedure TTestLegacyMidiPlayer.DovrebbeNonFareNienteConVolumeEProcess;
begin
  FPlayer.SetVolume(7);
  FPlayer.Process;
  Assert.AreEqual(0, FSequencer.Commands.Count);
  Assert.AreEqual(0, FWindow.Commands.Count);
end;

procedure TTestLegacyMidiPlayer.DovrebbeRicominciareDaCapoConInitialize;
begin
  FPlayer.AddFile('a.mid');
  FPlayer.Initialize;
  FPlayer.Play(0);
  Assert.AreEqual('MIDI mapper unavailable', FLog.InfoText);
end;

procedure TTestLegacyMidiPlayer.DovrebbeFermareLaPerifericaConShutDown;
begin
  FPlayer.ShutDown;
  Assert.AreEqual('stop 0;close 0', Join(FSequencer.Commands));
end;

procedure TTestLegacyMidiPlayer.DovrebbeDareLeStesseChiamateDelVecchioCodice;
const
  NAMES: array[0..3] of string = ('a.mid', 'b.mid', 'A.MID', 'c.mid');
var
  LCase: Integer;
  LStep: Integer;
  LOperation: Integer;
  LOldSequencer: TFakeMciSequencer;
  LOldSequencerRef: IMciSequencer;
  LNewSequencer: TFakeMciSequencer;
  LNewSequencerRef: IMciSequencer;
  LNewWindow: TFakeNotifyWindow;
  LNewWindowRef: IMidiNotifyWindow;
  LNewLog: TRecordingLog;
  LNewLogRef: ILog;
  LOld: TLegacyMidi;
  LNew: ILegacyMidiPlayer;
  LIndex: Integer;
begin
  RandSeed := 1852;
  for LCase := 1 to 400 do
  begin
    LOldSequencer := TFakeMciSequencer.Create;
    LOldSequencerRef := LOldSequencer;
    LNewSequencer := TFakeMciSequencer.Create;
    LNewSequencerRef := LNewSequencer;
    LNewWindow := TFakeNotifyWindow.Create(100);
    LNewWindowRef := LNewWindow;
    LNewLog := TRecordingLog.Create;
    LNewLogRef := LNewLog;
    LOldSequencer.IsMapper := Random(5) > 0;
    LOldSequencer.OpenResult := Cardinal(Ord(Random(8) = 0));
    LOldSequencer.StatusResult := Cardinal(Ord(Random(8) = 0));
    LOldSequencer.PlayResult := Cardinal(Ord(Random(8) = 0));
    LOldSequencer.SeekResult := Cardinal(Ord(Random(8) = 0));
    LNewSequencer.IsMapper := LOldSequencer.IsMapper;
    LNewSequencer.OpenResult := LOldSequencer.OpenResult;
    LNewSequencer.StatusResult := LOldSequencer.StatusResult;
    LNewSequencer.PlayResult := LOldSequencer.PlayResult;
    LNewSequencer.SeekResult := LOldSequencer.SeekResult;
    LOld := TLegacyMidi.Create(LOldSequencerRef, 100);
    LNew := TEngineSystemFactory.CreateLegacyMidiPlayer(LNewSequencerRef, LNewWindowRef, LNewLogRef);
    try
      LOld.I_InitMidi_Legacy;
      LNew.Initialize;
      for LStep := 1 to 40 do
      begin
        LOperation := Random(10);
        case LOperation of
          0, 1:
            begin
              LIndex := Random(4);
              LOld.AddMidiFileToPlayList_Legacy(NAMES[LIndex]);
              LNew.AddFile(NAMES[LIndex]);
            end;
          2:
            begin
              LOld.ClearMidiFilePlayList_Legacy;
              LNew.ClearPlayList;
            end;
          3, 4:
            begin
              LIndex := Random(4) - 1;
              LOld.I_PlayMidi_Legacy(LIndex);
              LNew.Play(LIndex);
            end;
          5:
            begin
              LOld.I_StopMidi_Legacy;
              LNew.Stop;
            end;
          6:
            begin
              LOld.I_PauseMidi_Legacy;
              LNew.Pause;
              LOld.I_ResumeMidi_Legacy;
              LNew.Resume;
            end;
          7, 8:
            // a notification can only come from a window that exists, and the old code needs a list
            if (LOld.Window <> 0) and (LOld.MidiFileNames.Count > 0) then
            begin
              LIndex := Random(3);
              LOld.WindowProcNotify(LIndex > 0);
              LNewWindow.Notify(LIndex > 0);
            end;
          9:
            begin
              LOld.I_ShutDownMidi_Legacy;
              LNew.ShutDown;
              LOld.I_InitMidi_Legacy;
              LNew.Initialize;
            end;
        end;
        Assert.AreEqual(LOldSequencer.Commands.Text, LNewSequencer.Commands.Text,
          Format('case %d step %d', [LCase, LStep]));
        Assert.AreEqual(LOld.Printed, LNewLog.InfoText);
      end;
    finally
      LOld.Free;
      LNew := nil;
    end;
  end;
end;

end.
