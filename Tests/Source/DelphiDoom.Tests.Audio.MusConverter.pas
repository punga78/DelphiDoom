{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the audio library - MUS songs to midi events           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.MusConverter;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder,
  DelphiDoom.Logging.Factory,
  DelphiDoom.Audio.Types, DelphiDoom.Audio.MusConverter;

type
  /// <summary>
  ///   The mus.* lines of Tests\Data\Audio\audio.golden.txt were written by GetSongLength and
  ///   I_MusToMidi of the old i_music, copied as they were in a harness out of the repository, on
  ///   the songs of TAudioScenarios (with the bytes after the song set to zero)
  /// </summary>
  [TestFixture]
  [Category('audio')]
  TTestAudioMusConverter = class(TObject)
  private
    FGolden: TDictionary<string, string>;
    FRecorder: TLogRecorder;
    FRecorderIntf: ILogSink;
    FLog: ILog;
    function Song(const AScore: array of Byte): TBytes;
    function Convert(const ABytes: TBytes; ATempo: Byte): TArray<TMusMidiEvent>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeConvertireComeIlVecchioCodice;
    [Test]
    procedure DovrebbeAvereEventiDiDodiciByte;
    [Test]
    procedure DovrebbeIniziareConDueEventiDiTempo;
    [Test]
    procedure DovrebbeScambiareICanaliDelleBatterie;
    [Test]
    procedure DovrebbeLeggereIlRitardoDopoLEvento;
    [Test]
    procedure DovrebbeTenereIlVolumeDelCanale;
    [Test]
    procedure DovrebbeDareFalsoSenzaAvvisoPerUnFileMidi;
    [Test]
    procedure DovrebbeAvvisareSeNonEMus;
    [Test]
    procedure DovrebbeDareErrorePerUnControlloSconosciuto;
    [Test]
    procedure DovrebbeDareIlControllerZeroOltreLaTabella;
    [Test]
    procedure DovrebbeContareDueEventiSeNonEMus;
  end;

implementation

uses
  DelphiDoom.Tests.Audio.Scenarios;

{ TTestAudioMusConverter }

procedure TTestAudioMusConverter.Setup;
var
  LLines: TStringList;
  LIndex: Integer;
  LSeparator: Integer;
begin
  FRecorder := TLogRecorder.Create;
  FRecorderIntf := FRecorder;
  FLog := TLogFactory.CreateLog(TArray<ILogSink>.Create(FRecorderIntf), nil);
  FGolden := TDictionary<string, string>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..\..\Tests\Data\Audio\audio.golden.txt')));
    for LIndex := 0 to LLines.Count - 1 do
    begin
      LSeparator := Pos('=', LLines[LIndex]);
      if LSeparator > 1 then
        FGolden.Add(Copy(LLines[LIndex], 1, LSeparator - 1), Copy(LLines[LIndex], LSeparator + 1, MaxInt));
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestAudioMusConverter.TearDown;
begin
  FGolden.Free;
  FLog := nil;
  FRecorderIntf := nil;
end;

function TTestAudioMusConverter.Song(const AScore: array of Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 16 + Length(AScore));
  FillChar(Result[0], Length(Result), 0);
  Result[0] := Ord('M');
  Result[1] := Ord('U');
  Result[2] := Ord('S');
  Result[3] := $1A;
  Result[4] := Length(AScore);
  Result[6] := 16;
  for LIndex := 0 to High(AScore) do
    Result[16 + LIndex] := AScore[LIndex];
end;

function TTestAudioMusConverter.Convert(const ABytes: TBytes; ATempo: Byte): TArray<TMusMidiEvent>;
begin
  Assert.IsTrue(TMusConverter.TryConvert(PByte(ABytes), Length(ABytes), ATempo, FLog, Result));
end;

procedure TTestAudioMusConverter.DovrebbeConvertireComeIlVecchioCodice;
var
  LSongs: TArray<TBytes>;
  LIndex: Integer;
  LCount: Integer;
  LEvents: TArray<TMusMidiEvent>;
  LResult: string;
  LHash: string;
  LZeros: TBytes;
  LWarnings: string;
  LEntry: Integer;
  LExpected: string;
  LKey: string;
begin
  LSongs := TAudioScenarios.MusSongs;
  for LIndex := 0 to High(LSongs) do
  begin
    FRecorder.Clear;
    LCount := TMusConverter.EventCount(PByte(LSongs[LIndex]), Length(LSongs[LIndex]));
    LEvents := nil;
    try
      if TMusConverter.TryConvert(PByte(LSongs[LIndex]), Length(LSongs[LIndex]),
        TAudioScenarios.MusTempo(LIndex), FLog, LEvents) then
        LResult := 'true'
      else
        LResult := 'false';
    except
      on E: EMusConversionException do
        LResult := 'error:' + E.Message;
    end;
    if Length(LEvents) >= LCount then
      LHash := TAudioScenarios.Fingerprint(PByte(LEvents), LCount * SizeOf(TMusMidiEvent))
    else
    begin
      // no events: the old buffer was zero
      SetLength(LZeros, LCount * SizeOf(TMusMidiEvent));
      FillChar(LZeros[0], Length(LZeros), 0);
      LHash := TAudioScenarios.Fingerprint(PByte(LZeros), Length(LZeros));
    end;
    LWarnings := '';
    for LEntry := 0 to FRecorder.Count - 1 do
      if FRecorder[LEntry].Channel = TLogChannel.ErrorFile then
        LWarnings := LWarnings + '|' + StringReplace(Copy(FRecorder[LEntry].Text,
          Length('I_Warning: ') + 1, MaxInt), #13#10, '\n', [rfReplaceAll]);
    LKey := 'mus.' + IntToStr(LIndex);
    Assert.IsTrue(FGolden.TryGetValue(LKey, LExpected), 'missing golden key ' + LKey);
    Assert.AreEqual(LExpected, Format('%d,%s,%s%s', [LCount, LResult, LHash, LWarnings]), LKey);
  end;
end;

procedure TTestAudioMusConverter.DovrebbeAvereEventiDiDodiciByte;
begin
  Assert.AreEqual(12, Integer(SizeOf(TMusMidiEvent)));
end;

procedure TTestAudioMusConverter.DovrebbeIniziareConDueEventiDiTempo;
var
  LEvents: TArray<TMusMidiEvent>;
  LIndex: Integer;
begin
  LEvents := Convert(Song([$60]), 77);
  Assert.AreEqual(3, Integer(Length(LEvents)));
  for LIndex := 0 to 1 do
  begin
    Assert.AreEqual<Integer>(1, LEvents[LIndex].EventType);
    Assert.AreEqual<Integer>(0, LEvents[LIndex].Data[0]);
    Assert.AreEqual<Integer>(77, LEvents[LIndex].Data[1]);
    Assert.AreEqual<Integer>(2, LEvents[LIndex].Data[2]);
  end;
end;

procedure TTestAudioMusConverter.DovrebbeScambiareICanaliDelleBatterie;
var
  LEvents: TArray<TMusMidiEvent>;
begin
  // release note on channel 15, then on 9, then on 3
  LEvents := Convert(Song([$0F, 35, $09, 36, $03, 37, $60]), 160);
  Assert.AreEqual<Integer>($89, LEvents[2].Data[0]);
  Assert.AreEqual<Integer>(35, LEvents[2].Data[1]);
  Assert.AreEqual<Integer>($8F, LEvents[3].Data[0]);
  Assert.AreEqual<Integer>($83, LEvents[4].Data[0]);
end;

procedure TTestAudioMusConverter.DovrebbeLeggereIlRitardoDopoLEvento;
var
  LEvents: TArray<TMusMidiEvent>;
begin
  // the delay goes to the next event. Defect of the old code, kept: the last byte of a delay of
  // more bytes is added without the shift, so $81 $05 is 1 + 5 and not 1 * 128 + 5
  LEvents := Convert(Song([$80, 40, $05, $80, 41, $81, $05, $00, 42, $60]), 160);
  Assert.AreEqual<Cardinal>(0, LEvents[2].Time);
  Assert.AreEqual<Cardinal>(5, LEvents[3].Time);
  Assert.AreEqual<Cardinal>(6, LEvents[4].Time);
end;

procedure TTestAudioMusConverter.DovrebbeTenereIlVolumeDelCanale;
var
  LEvents: TArray<TMusMidiEvent>;
begin
  // play with volume 100, play without volume, release
  LEvents := Convert(Song([$12, $80 or 60, 100, $12, 61, $02, 60, $60]), 160);
  Assert.AreEqual<Integer>($92, LEvents[2].Data[0]);
  Assert.AreEqual<Integer>(60, LEvents[2].Data[1]);
  Assert.AreEqual<Integer>(100, LEvents[2].Data[2]);
  Assert.AreEqual<Integer>(100, LEvents[3].Data[2]);
  Assert.AreEqual<Integer>(100, LEvents[4].Data[2]);
end;

procedure TTestAudioMusConverter.DovrebbeDareFalsoSenzaAvvisoPerUnFileMidi;
var
  LBytes: TBytes;
  LEvents: TArray<TMusMidiEvent>;
begin
  LBytes := TBytes.Create(Ord('M'), Ord('T'), Ord('h'), Ord('d'), 0, 0, 0, 6);
  Assert.IsTrue(TMusConverter.IsMidiFile(PByte(LBytes), Length(LBytes)));
  Assert.IsFalse(TMusConverter.TryConvert(PByte(LBytes), Length(LBytes), 160, FLog, LEvents));
  Assert.AreEqual(0, Integer(Length(LEvents)));
  Assert.AreEqual(0, FRecorder.Count);
end;

procedure TTestAudioMusConverter.DovrebbeAvvisareSeNonEMus;
var
  LBytes: TBytes;
  LEvents: TArray<TMusMidiEvent>;
begin
  LBytes := TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8);
  Assert.IsFalse(TMusConverter.IsMus(PByte(LBytes), Length(LBytes)));
  Assert.IsFalse(TMusConverter.TryConvert(PByte(LBytes), Length(LBytes), 160, FLog, LEvents));
  Assert.AreEqual('I_Warning: I_MusToMidi(): Not a MUS file'#13#10,
    FRecorder.TextOf(TLogChannel.ErrorFile));
  // without a log it is only false
  Assert.IsFalse(TMusConverter.TryConvert(PByte(LBytes), Length(LBytes), 160, nil, LEvents));
  Assert.IsFalse(TMusConverter.IsMus(nil, 10));
end;

procedure TTestAudioMusConverter.DovrebbeDareErrorePerUnControlloSconosciuto;
var
  LBytes: TBytes;
begin
  LBytes := Song([$30, 9, $60]);
  Assert.WillRaiseWithMessage(
    procedure
    var
      LEvents: TArray<TMusMidiEvent>;
    begin
      TMusConverter.TryConvert(PByte(LBytes), Length(LBytes), 160, FLog, LEvents);
    end, EMusConversionException, 'XLateMUSControl(): Unknown control 9');
end;

procedure TTestAudioMusConverter.DovrebbeDareIlControllerZeroOltreLaTabella;
var
  LEvents: TArray<TMusMidiEvent>;
begin
  // controller 3 is the volume (7); 20 is not in the table
  LEvents := Convert(Song([$40, 3, 90, $40, 20, 91, $40, 0, 12, $60]), 160);
  Assert.AreEqual<Integer>($B0, LEvents[2].Data[0]);
  Assert.AreEqual<Integer>(7, LEvents[2].Data[1]);
  Assert.AreEqual<Integer>(90, LEvents[2].Data[2]);
  Assert.AreEqual<Integer>(0, LEvents[3].Data[1]);
  Assert.AreEqual<Integer>(91, LEvents[3].Data[2]);
  // controller 0 is the instrument
  Assert.AreEqual<Integer>($C0, LEvents[4].Data[0]);
  Assert.AreEqual<Integer>(12, LEvents[4].Data[1]);
  Assert.AreEqual<Integer>(64, LEvents[4].Data[2]);
end;

procedure TTestAudioMusConverter.DovrebbeContareDueEventiSeNonEMus;
var
  LBytes: TBytes;
begin
  LBytes := TBytes.Create(1, 2, 3, 4);
  Assert.AreEqual(2, TMusConverter.EventCount(PByte(LBytes), Length(LBytes)));
  LBytes := Song([$00, 1, $10, 2, $60]);
  Assert.AreEqual(5, TMusConverter.EventCount(PByte(LBytes), Length(LBytes)));
end;

end.
