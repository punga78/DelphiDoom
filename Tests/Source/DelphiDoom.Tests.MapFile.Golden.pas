{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - parity with the real idlib of   }
{  Doom 3 (idMapFile, idMapEntity, idMapBrush, idMapPatch)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.Golden;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('MapFile')]
  TTestMapFileGolden = class
  strict private
    function DataFolder: string;
    function LoadText(const AName: string): AnsiString;
    function LoadLines(const AName: string): TStringList;
    procedure RunCase(const AName: string; const AIgnoreRegion: Boolean; const AOutput: TStrings);
    function SameLine(const AExpected, AActual: string): Boolean;
  public
    /// <summary>
    ///   The golden file is the output of the real MapFile.cpp, Lexer.cpp, Dict.cpp and the rest of idlib
    ///   (bcc32c, 32 bit) on the files of Tests\Data\MapFile; see the README there. The texture vectors
    ///   (lines "TV") go through sin, cos and atan2 and may differ by a few units in the last place
    /// </summary>
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroIdlib;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Types, DelphiDoom.MapFile.Map, DelphiDoom.MapFile.Intf,
  DelphiDoom.MapFile.Factory, DelphiDoom.Tests.IdLib.Fakes, DelphiDoom.Tests.MapFile.Dump;

const
  // largest difference accepted for the texture vectors, in units in the last place
  TEXTURE_VECTOR_ULP = 2;

function TTestMapFileGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\MapFile\');
end;

function TTestMapFileGolden.LoadText(const AName: string): AnsiString;
var
  LBytes: TBytes;
begin
  Result := '';
  if not TFile.Exists(DataFolder + AName) then
    Exit;
  LBytes := TFile.ReadAllBytes(DataFolder + AName);
  if Length(LBytes) > 0 then
  begin
    SetLength(Result, Length(LBytes));
    Move(LBytes[0], Result[1], Length(LBytes));
  end;
end;

function TTestMapFileGolden.LoadLines(const AName: string): TStringList;
begin
  Result := TStringList.Create;
  Result.LineBreak := #10;
  // the lines as they are, whatever the line end of the checkout
  Result.Text := StringReplace(string(LoadText(AName)), #13#10, #10, [rfReplaceAll]);
end;

procedure TTestMapFileGolden.RunCase(const AName: string; const AIgnoreRegion: Boolean; const AOutput: TStrings);
var
  LFileSystem: TIdLibMemoryFileSystem;
  LFileSystemIntf: IIdLibFileSystem;
  LLog: TIdLibLogRecorder;
  LLogIntf: IIdLibLog;
  LReader: IMapFileReader;
  LWriter: IMapFileWriter;
  LMap: TMapFile;
  LDump: TMapDump;
  LOutput: TStringList;
  LIndex: Integer;
  LNumber: Integer;

  procedure FlushLog;
  var
    LEntry: Integer;
  begin
    for LEntry := 0 to LLog.Entries.Count - 1 do
      AOutput.Add(Copy(LLog.Entries[LEntry], 1, 2) + ' ' + TMapDump.Escape(AnsiString(Copy(LLog.Entries[LEntry], 3, MaxInt))));
    LLog.Entries.Clear;
  end;

begin
  LFileSystem := TIdLibMemoryFileSystem.Create;
  LFileSystemIntf := LFileSystem;
  LLog := TIdLibLogRecorder.Create;
  LLogIntf := LLog;
  // a name without a .map file is a missing file for the reader
  if TFile.Exists(DataFolder + AName + '.map') then
    LFileSystem.SetFile(AnsiString(AName + '.map'), LoadText(AName + '.map'));
  if TFile.Exists(DataFolder + AName + '.reg') then
    LFileSystem.SetFile(AnsiString(AName + '.reg'), LoadText(AName + '.reg'));
  LReader := TMapFileFactory.CreateReader(LFileSystemIntf, LLogIntf);
  LWriter := TMapFileFactory.CreateWriter(LFileSystemIntf, LLogIntf);
  AOutput.Add('CASE ' + AName + IfThen(AIgnoreRegion, ' !', ''));
  try
    LMap := LReader.Parse(AnsiString(AName), AIgnoreRegion);
    try
      FlushLog;
      AOutput.Add('PARSE ' + IntToStr(Ord(Assigned(LMap))));
      if Assigned(LMap) then
      begin
        LDump := TMapDump.Create(AOutput);
        try
          LDump.Dump(LMap);
        finally
          LDump.Free;
        end;
        LNumber := Ord(LWriter.Write(LMap, AnsiString(AName), 'out'));
        FlushLog;
        AOutput.Add('WRITE ' + IntToStr(LNumber));
        LOutput := TStringList.Create;
        try
          LOutput.LineBreak := #10;
          LOutput.Text := string(LFileSystem.GetFile(AnsiString(AName + '.out')));
          for LIndex := 0 to LOutput.Count - 1 do
            AOutput.Add('| ' + TMapDump.Escape(AnsiString(LOutput[LIndex])));
        finally
          LOutput.Free;
        end;
        AOutput.Add('ENDWRITE');
      end;
    finally
      LMap.Free;
    end;
  except
    on E: EMapFileException do
      AOutput.Add('ERR ' + TMapDump.Escape(AnsiString(E.Message)));
  end;
end;

function TTestMapFileGolden.SameLine(const AExpected, AActual: string): Boolean;
var
  LExpectedParts, LActualParts: TArray<string>;
  LIndex: Integer;
  LExpectedBits, LActualBits: Integer;
  LDifference: Int64;
begin
  if AExpected = AActual then
    Exit(True);
  if not AExpected.StartsWith('  TV ') or not AActual.StartsWith('  TV ') then
    Exit(False);
  LExpectedParts := AExpected.Split([' ']);
  LActualParts := AActual.Split([' ']);
  if Length(LExpectedParts) <> Length(LActualParts) then
    Exit(False);
  Result := True;
  // the line starts with two spaces: the parts are '', '', 'TV' and then the eight values
  for LIndex := 3 to High(LExpectedParts) do
  begin
    LExpectedBits := Integer(StrToUInt('$' + Copy(LExpectedParts[LIndex], 2, 8)));
    LActualBits := Integer(StrToUInt('$' + Copy(LActualParts[LIndex], 2, 8)));
    // the bits of a negative float order backwards: map them onto a line of integers
    if LExpectedBits < 0 then
      LExpectedBits := Integer($80000000) - LExpectedBits;
    if LActualBits < 0 then
      LActualBits := Integer($80000000) - LActualBits;
    LDifference := Abs(Int64(LExpectedBits) - Int64(LActualBits));
    if LDifference > TEXTURE_VECTOR_ULP then
      Exit(False);
  end;
end;

procedure TTestMapFileGolden.DovrebbeDareLeStesseRisposteDelVeroIdlib;
var
  LCases, LExpected, LActual: TStringList;
  LIndex, LDifferences: Integer;
  LName, LFirst: string;
  LIgnore: Boolean;
begin
  LCases := LoadLines('cases.txt');
  LExpected := LoadLines('mapfile.golden.txt');
  LActual := TStringList.Create;
  try
    // a data folder that is not there must not make the test pass without comparing anything
    Assert.IsTrue(LExpected.Count > 100, 'mapfile.golden.txt not found in ' + DataFolder);
    for LIndex := 0 to LCases.Count - 1 do
    begin
      LName := Trim(LCases[LIndex]);
      if (LName = '') or (LName[1] = '#') then
        Continue;
      LIgnore := LName.EndsWith(' !');
      if LIgnore then
        LName := Copy(LName, 1, Length(LName) - 2);
      RunCase(LName, LIgnore, LActual);
    end;
    LDifferences := 0;
    LFirst := '';
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      if (LIndex >= LActual.Count) or not SameLine(LExpected[LIndex], LActual[LIndex]) then
      begin
        Inc(LDifferences);
        if LFirst = '' then
        begin
          LFirst := Format('line %d: expected "%s", got "%s"', [LIndex + 1, LExpected[LIndex],
            IfThen(LIndex < LActual.Count, LActual[LIndex], '<missing>')]);
        end;
      end;
    end;
    if LActual.Count <> LExpected.Count then
      Inc(LDifferences);
    if LDifferences > 0 then
      LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.mapfile.actual.txt'));
    Assert.AreEqual(0, LDifferences, Format('%d lines differ, the first at %s', [LDifferences, LFirst]));
  finally
    LActual.Free;
    LExpected.Free;
    LCases.Free;
  end;
end;

end.
