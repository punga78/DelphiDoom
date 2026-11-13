{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - parity of the .aas reader with  }
{  the real idAASFileLocal::Load of Doom 3 (aas.golden.txt)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.AasGolden;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('MapFile')]
  TTestAasGolden = class
  strict private
    function DataFolder: string;
    function LoadBytesAsText(const AName: string): AnsiString;
    procedure RunCase(const AName: string; const ACrc: Cardinal; const AOutput: TStrings);
    function Expected: TStringList;
  public
    /// <summary>
    ///   aas.golden.txt is what the real AASFile.cpp (with the idLexer, idDict and the math of
    ///   idlib, compiled with bcc32c, 32 bit) prints for the files of Tests\Data\MapFile; the
    ///   "P:" lines that carry the depth of the tree and the number of reachabilities are kept
    ///   as DEPTH and NUMREACH, the others are the log
    /// </summary>
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroIdlib;
  end;

implementation

uses
  System.IOUtils, System.StrUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Aas.AasFile, DelphiDoom.MapFile.Aas.Intf, DelphiDoom.MapFile.Aas.Types,
  DelphiDoom.MapFile.Aas.Factory, DelphiDoom.Tests.IdLib.Fakes, DelphiDoom.Tests.MapFile.AasDump;

{ TTestAasGolden }

function TTestAasGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\MapFile\');
end;

function TTestAasGolden.LoadBytesAsText(const AName: string): AnsiString;
var
  LBytes: TBytes;
begin
  Result := '';
  if not TFile.Exists(DataFolder + AName) then
    Exit;
  LBytes := TFile.ReadAllBytes(DataFolder + AName);
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

function TTestAasGolden.Expected: TStringList;
var
  LRaw: TStringList;
  LLine: string;
begin
  Result := TStringList.Create;
  LRaw := TStringList.Create;
  try
    if TFile.Exists(DataFolder + 'aas.golden.txt') then
      LRaw.LoadFromFile(DataFolder + 'aas.golden.txt');
    for LLine in LRaw do
      if LLine.StartsWith('P: ') then
      begin
        if LLine.EndsWith(' max tree depth\n') then
          Result.Add('DEPTH ' + Trim(StringReplace(Copy(LLine, 4, MaxInt), ' max tree depth\n', '', [])))
        else if LLine.EndsWith(' reachabilities\n') then
          Result.Add('NUMREACH ' + Trim(StringReplace(Copy(LLine, 4, MaxInt), ' reachabilities\n', '', [])));
      end
      else if LLine.StartsWith('P ') then
        // the last number is MaxAreaTravelTime, left uninitialised by the C++
        Result.Add(Copy(LLine, 1, LLine.LastIndexOf(' ')))
      else if not (LLine.StartsWith('W: ') or LLine.StartsWith('ERR ')) and (Trim(LLine) <> '') then
        Result.Add(LLine);
  finally
    LRaw.Free;
  end;
end;

procedure TTestAasGolden.RunCase(const AName: string; const ACrc: Cardinal; const AOutput: TStrings);
var
  LFileSystem: TIdLibMemoryFileSystem;
  LReader: IAasFileReader;
  LFile: TAasFile;
  LText: AnsiString;
begin
  AOutput.Add(Format('CASE %s %u', [AName, ACrc]));
  LFileSystem := TIdLibMemoryFileSystem.Create;
  LReader := TAasFileFactory.CreateReader(LFileSystem);
  LText := LoadBytesAsText(AName);
  if LText <> '' then
    LFileSystem.SetFile(AnsiString(AName), LText);
  try
    LFile := LReader.Parse(AnsiString(AName), ACrc);
  except
    on E: EAasFileException do
      LFile := nil;
  end;
  try
    if Assigned(LFile) then
    begin
      AOutput.Add('LOAD 1');
      TAasDump.Dump(LFile, AOutput, ACrc);
    end
    else
      AOutput.Add('LOAD 0');
  finally
    LFile.Free;
  end;
end;

procedure TTestAasGolden.DovrebbeDareLeStesseRisposteDelVeroIdlib;
var
  LCases, LExpected, LActual: TStringList;
  LLine, LName: string;
  LParts: TArray<string>;
  LIndex, LDifferences: Integer;
  LReport: string;
begin
  LCases := TStringList.Create;
  LExpected := Expected;
  LActual := TStringList.Create;
  try
    // a data folder that is not there must not make the test pass without comparing anything
    Assert.IsTrue(LExpected.Count > 100, 'aas.golden.txt not found in ' + DataFolder);
    LCases.LoadFromFile(DataFolder + 'aas_cases.txt');
    for LLine in LCases do
    begin
      LName := Trim(LLine);
      if (LName = '') or LName.StartsWith('#') then
        Continue;
      LParts := LName.Split([' ']);
      RunCase(LParts[0], StrToUInt64(LParts[1]), LActual);
    end;
    LDifferences := 0;
    LReport := '';
    for LIndex := 0 to LExpected.Count - 1 do
      if (LIndex >= LActual.Count) or (LExpected[LIndex] <> LActual[LIndex]) then
      begin
        Inc(LDifferences);
        if LDifferences <= 8 then
          LReport := LReport + Format('line %d: expected "%s", got "%s"'#10, [LIndex + 1, LExpected[LIndex],
            IfThen(LIndex < LActual.Count, LActual[LIndex], '<none>')]);
      end;
    if LActual.Count <> LExpected.Count then
      LReport := LReport + Format('%d lines expected, %d got'#10, [LExpected.Count, LActual.Count]);
    if (LDifferences > 0) or (LActual.Count <> LExpected.Count) then
    begin
      LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.aas.actual.txt'));
      Assert.Fail(Format('%d differences'#10'%s', [LDifferences, LReport]));
    end;
  finally
    LActual.Free;
    LExpected.Free;
    LCases.Free;
  end;
end;

end.
