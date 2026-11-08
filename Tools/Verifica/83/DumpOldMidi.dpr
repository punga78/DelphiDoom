{ Records what the old code gave: the blocks of events that TMidi (i_midi_new) wrote for the
  midi stream, and the pieces of events that the MUS code of the backend gave (the choice of
  the events in Process and the rewriting of the volume in SetVolume, as they were before the
  MIDI library). The songs are the ones of Tests\Source\DelphiDoom.Tests.Midi.Scenarios and the
  MIDI and MUS lumps of the WADs.

  DumpOldMidi <golden file> [<bin folder> [<folder of the .bin files>]]

  The golden file goes to Tests\Data\Midi\stream.golden.txt. The folder of the WADs is the bin
  of the repository (bin\Doom, bin\Heretic, bin\Hexen, bin\Strife); without it only the songs
  in memory are written. See RUN.md in the root of the repository. }
program DumpOldMidi;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  DelphiDoom.Audio.Types in '..\..\..\Libs\Audio\DelphiDoom.Audio.Types.pas',
  DelphiDoom.Audio.MusConverter in '..\..\..\Libs\Audio\DelphiDoom.Audio.MusConverter.pas',
  DelphiDoom.Tests.M2m.MidiBuilder in '..\..\..\Tests\Source\DelphiDoom.Tests.M2m.MidiBuilder.pas',
  DelphiDoom.Tests.Midi.Scenarios in '..\..\..\Tests\Source\DelphiDoom.Tests.Midi.Scenarios.pas',
  OldMidiShims in 'OldMidiShims.pas',
  OldMidiNew in 'OldMidiNew.pas';

const
  // the table of the sound menu, as the old i_midi had it
  OLD_MIDIVOLUMECONTROL: array[0..15] of Integer = (
    0, 7, 13, 20, 27, 33, 40, 47, 53, 60, 67, 73, 80, 87, 93, 100
  );

var
  GLines: TStringList;
  GBinFolder: string;

function SafeName(const AName: string): string;
begin
  Result := StringReplace(StringReplace(StringReplace(AName, ':', '_', [rfReplaceAll]),
    '#', '_', [rfReplaceAll]), '/', '_', [rfReplaceAll]);
end;

procedure WriteBin(const ALabel: string; const ARun: TMidiRunRecord);
var
  LStream: TFileStream;
  LBlock: TBytes;
begin
  if GBinFolder = '' then
    Exit;
  ForceDirectories(GBinFolder);
  LStream := TFileStream.Create(TPath.Combine(GBinFolder, SafeName(ALabel) + '.bin'), fmCreate);
  try
    for LBlock in ARun.Blocks do
      if Length(LBlock) > 0 then
        LStream.WriteBuffer(LBlock[0], Length(LBlock));
  finally
    LStream.Free;
  end;
end;

function ToRecord(const AOld: TOldRun): TMidiRunRecord;
var
  LIndex: Integer;
begin
  Result := Default(TMidiRunRecord);
  Result.Failed := AOld.Failed;
  for LIndex := 0 to High(AOld.Blocks) do
    Result.AddBlock(AOld.Blocks[LIndex].Code, AOld.Blocks[LIndex].Bytes);
end;

procedure DumpSong(const ASong: TMidiScenarioFile);
var
  LRun: TMidiRunRecord;
  LLabel: string;
begin
  // protocol looped: no tempo event requested
  LRun := ToRecord(OldMidiRun(ASong.Bytes, omLooped, SCENARIO_ROUNDS));
  GLines.Add(LRun.ToLine(ASong.Name, mpLooped));
  WriteBin(ASong.Name + '.looped', LRun);

  // protocol tempo: Play(True), with the pointer of the tempo event corrected
  LRun := ToRecord(OldMidiRun(ASong.Bytes, omTempo, SCENARIO_ROUNDS));
  GLines.Add(LRun.ToLine(ASong.Name, mpLoopedWithTempo));
  WriteBin(ASong.Name + '.tempo', LRun);

  // protocol once: the song is not repeated
  LRun := ToRecord(OldMidiRun(ASong.Bytes, omOnce, SCENARIO_ROUNDS));
  GLines.Add(LRun.ToLine(ASong.Name, mpOnce));
  WriteBin(ASong.Name + '.once', LRun);

  // the same as tempo with the pointer as it was: the bytes that the old player really gave
  // (information only, the tests do not read these lines)
  LLabel := ASong.Name + '/legacy-tempo';
  LRun := ToRecord(OldMidiRun(ASong.Bytes, omTempoLegacy, SCENARIO_ROUNDS));
  GLines.Add(LRun.ToText(LLabel));
  WriteBin(ASong.Name + '.legacy-tempo', LRun);
end;

// The old SetVolume (the rewriting of the events) and ProcessMusic (the choice of the events)
function OldMusRun(const ABytes: TBytes): TMidiRunRecord;
var
  LEvents, LOriginal: TArray<TMusMidiEvent>;
  NextEvent, LVolume, LPiece, I, Len, First, Vol100: Integer;
  LPieceBytes: TBytes;
begin
  Result := Default(TMidiRunRecord);
  try
    if (Length(ABytes) = 0) or not TMusConverter.TryConvert(@ABytes[0], Length(ABytes),
      SCENARIO_MUS_TEMPO, nil, LEvents) then
    begin
      Result.Failed := True;
      Exit;
    end;
  except
    on EMusConversionException do
    begin
      Result.Failed := True;
      Exit;
    end;
  end;
  LOriginal := Copy(LEvents);
  NextEvent := 0;
  for LVolume := 0 to High(SCENARIO_MUS_VOLUMES) do
  begin
    Vol100 := SCENARIO_MUS_VOLUMES[LVolume];
    if Vol100 < 0 then
      Vol100 := 0;
    if Vol100 > 15 then
      Vol100 := 15;
    Vol100 := OLD_MIDIVOLUMECONTROL[Vol100];

    for I := 0 to Length(LEvents) - 1 do
      if LEvents[I].Event and $000000F0 = $B0 then
        if (LEvents[I].Event and $0000FF00) shr 8 = $07 then
          LEvents[I].Event := (LOriginal[I].Event and $FF80FFFF) or (Cardinal(Vol100) shl 16);

    for LPiece := 1 to SCENARIO_MUS_PIECES_PER_VOLUME do
    begin
      First := NextEvent;
      Len := Length(LEvents) - NextEvent;
      if Len > SCENARIO_MUS_PIECE then
      begin
        Len := SCENARIO_MUS_PIECE;
        NextEvent := NextEvent + SCENARIO_MUS_PIECE;
      end
      else
        NextEvent := 0;
      SetLength(LPieceBytes, Len * SizeOf(TMusMidiEvent));
      if Len > 0 then
        Move(LEvents[First], LPieceBytes[0], Length(LPieceBytes));
      Result.AddBlock(Len, LPieceBytes);
    end;
  end;
end;

procedure DumpWads(const ABin: string);
const
  GAMES: array[0..4] of string = ('Doom', 'Doom', 'Heretic', 'Strife', 'Hexen');
  FILES: array[0..4] of string = ('DOOM1.WAD', 'FREEDOOM2.WAD', 'HERETIC1.WAD', 'STRIFE0.WAD', 'HEXEN.WAD');
var
  LIndex: Integer;
  LPath: string;
  LSong: TMidiScenarioFile;
  LRun: TMidiRunRecord;
  LLabel: string;
begin
  for LIndex := 0 to High(GAMES) do
  begin
    LPath := TPath.Combine(TPath.Combine(ABin, GAMES[LIndex]), FILES[LIndex]);
    if not FileExists(LPath) then
    begin
      Writeln('not found: ', LPath);
      Continue;
    end;
    for LSong in TMidiScenarios.WadSongs(LPath, False) do
      DumpSong(LSong);
    for LSong in TMidiScenarios.WadSongs(LPath, True) do
    begin
      LLabel := LSong.Name + '/mus';
      LRun := OldMusRun(LSong.Bytes);
      GLines.Add(LRun.ToText(LLabel));
    end;
  end;
end;

var
  LSong: TMidiScenarioFile;

begin
  try
    if ParamCount < 1 then
    begin
      Writeln('DumpOldMidi <golden file> [<bin folder> [<folder of the .bin files>]]');
      Halt(2);
    end;
    GBinFolder := '';
    if ParamCount >= 3 then
      GBinFolder := ParamStr(3);
    GLines := TStringList.Create;
    try
      for LSong in TMidiScenarios.All do
        DumpSong(LSong);
      if ParamCount >= 2 then
        DumpWads(ParamStr(2));
      ForceDirectories(ExtractFilePath(ExpandFileName(ParamStr(1))));
      GLines.SaveToFile(ParamStr(1));
      Writeln(GLines.Count, ' lines written to ', ParamStr(1));
    finally
      GLines.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
