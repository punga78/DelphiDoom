{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library tests - the blocks of the old player                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Midi.Parity;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  DUnitX.TestFramework,
  DelphiDoom.Tests.Midi.Scenarios,
  DelphiDoom.Tests.Midi.Driver;

type
  /// <summary>
  ///   Tests\Data\Midi\stream.golden.txt was written by Tools\Verifica\83 (DumpOldMidi) with the
  ///   code of TMidi and of I_ProcessMusicMus as they were before the library. The lines with the
  ///   protocols looped and once are the same bytes; those of the protocol tempo come from the old
  ///   code with the pointer of the inserted tempo event corrected (see TMidiStreamSequencer)
  /// </summary>
  [TestFixture]
  [Category('midi')]
  TTestMidiParity = class
  strict private
    FGolden: TDictionary<string, string>;
    function GoldenPath: string;
    function BinPath(const AGame, AFile: string): string;
    procedure CheckMidi(const ASongs: TArray<TMidiScenarioFile>; var ACompared: Integer;
      var AMismatches: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareGliStessiBlocchiDelVecchioPlayerSuiFileInMemoria;
    [Test]
    procedure DovrebbeDareGliStessiBlocchiDelVecchioPlayerSuiMidiDeiWad;
    [Test]
    procedure DovrebbeDareGliStessiPezziDelVecchioCodiceMusSuiMusDeiWad;
  end;

implementation

{ TTestMidiParity }

function TTestMidiParity.GoldenPath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Midi\stream.golden.txt'));
end;

function TTestMidiParity.BinPath(const AGame, AFile: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\bin\' + AGame + '\' + AFile));
end;

procedure TTestMidiParity.Setup;
var
  LLines: TStringList;
  LIndex, LSpace: Integer;
begin
  FGolden := TDictionary<string, string>.Create;
  if not FileExists(GoldenPath) then
    Exit;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(GoldenPath);
    for LIndex := 0 to LLines.Count - 1 do
    begin
      LSpace := Pos(' ', LLines[LIndex]);
      if LSpace > 1 then
        FGolden.AddOrSetValue(Copy(LLines[LIndex], 1, LSpace - 1), LLines[LIndex]);
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestMidiParity.TearDown;
begin
  FGolden.Free;
end;

procedure TTestMidiParity.CheckMidi(const ASongs: TArray<TMidiScenarioFile>;
  var ACompared: Integer; var AMismatches: string);
var
  LSong: TMidiScenarioFile;
  LProtocol: TMidiProtocol;
  LLine, LKey, LExpected: string;
begin
  for LSong in ASongs do
    for LProtocol := Low(TMidiProtocol) to High(TMidiProtocol) do
    begin
      LKey := LSong.Name + '/' + TMidiScenarios.ProtocolName(LProtocol);
      if not FGolden.TryGetValue(LKey, LExpected) then
        Continue;
      LLine := TMidiNewDriver.RunProtocol(LSong.Bytes, LProtocol).ToLine(LSong.Name, LProtocol);
      Inc(ACompared);
      if LLine <> LExpected then
        AMismatches := AMismatches + 'expected: ' + LExpected + sLineBreak + 'got:      ' + LLine +
          sLineBreak;
    end;
end;

procedure TTestMidiParity.DovrebbeDareGliStessiBlocchiDelVecchioPlayerSuiFileInMemoria;
var
  LCompared: Integer;
  LMismatches: string;
begin
  if FGolden.Count = 0 then
  begin
    Assert.Pass('stream.golden.txt has not been written yet');
    Exit;
  end;
  LCompared := 0;
  LMismatches := '';
  CheckMidi(TMidiScenarios.All, LCompared, LMismatches);
  Assert.AreEqual('', LMismatches);
  Assert.IsTrue(LCompared > 0, 'no scenario in the golden file');
end;

procedure TTestMidiParity.DovrebbeDareGliStessiBlocchiDelVecchioPlayerSuiMidiDeiWad;
var
  LCompared: Integer;
  LMismatches: string;
begin
  if FGolden.Count = 0 then
  begin
    Assert.Pass('stream.golden.txt has not been written yet');
    Exit;
  end;
  LCompared := 0;
  LMismatches := '';
  CheckMidi(TMidiScenarios.WadSongs(BinPath('Hexen', 'HEXEN.WAD'), False), LCompared, LMismatches);
  CheckMidi(TMidiScenarios.WadSongs(BinPath('Doom', 'DOOM1.WAD'), False), LCompared, LMismatches);
  CheckMidi(TMidiScenarios.WadSongs(BinPath('Doom', 'FREEDOOM2.WAD'), False), LCompared, LMismatches);
  CheckMidi(TMidiScenarios.WadSongs(BinPath('Heretic', 'HERETIC1.WAD'), False), LCompared, LMismatches);
  CheckMidi(TMidiScenarios.WadSongs(BinPath('Strife', 'STRIFE0.WAD'), False), LCompared, LMismatches);
  Assert.AreEqual('', LMismatches);
  if LCompared = 0 then
    Assert.Pass('no WAD with MIDI lumps in bin\ (or none in the golden file)');
end;

procedure TTestMidiParity.DovrebbeDareGliStessiPezziDelVecchioCodiceMusSuiMusDeiWad;
var
  LSongs: TArray<TMidiScenarioFile>;
  LSong: TMidiScenarioFile;
  LLine, LKey, LExpected, LMismatches: string;
  LCompared: Integer;

  procedure Collect(const AGame, AFile: string);
  var
    LMore: TArray<TMidiScenarioFile>;
  begin
    LMore := TMidiScenarios.WadSongs(BinPath(AGame, AFile), True);
    LSongs := LSongs + LMore;
  end;

begin
  if FGolden.Count = 0 then
  begin
    Assert.Pass('stream.golden.txt has not been written yet');
    Exit;
  end;
  LSongs := nil;
  Collect('Doom', 'DOOM1.WAD');
  Collect('Doom', 'FREEDOOM2.WAD');
  Collect('Heretic', 'HERETIC1.WAD');
  Collect('Strife', 'STRIFE0.WAD');
  Collect('Hexen', 'HEXEN.WAD');
  LCompared := 0;
  LMismatches := '';
  for LSong in LSongs do
  begin
    LKey := LSong.Name + '/mus';
    if not FGolden.TryGetValue(LKey, LExpected) then
      Continue;
    LLine := TMidiNewDriver.RunMus(LSong.Bytes).ToText(LKey);
    Inc(LCompared);
    if LLine <> LExpected then
      LMismatches := LMismatches + 'expected: ' + LExpected + sLineBreak + 'got:      ' + LLine +
        sLineBreak;
  end;
  Assert.AreEqual('', LMismatches);
  if LCompared = 0 then
    Assert.Pass('no WAD with MUS lumps in bin\ (or none in the golden file)');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMidiParity);

end.
