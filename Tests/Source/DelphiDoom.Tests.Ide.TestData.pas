{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - where the files of the tests are     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.TestData;

interface

uses
  System.SysUtils,
  System.Classes;

type
  /// <summary>The files of Tests\Data\Ide, which the old DD_IDE code produced or read</summary>
  TIdeTestData = class
  public
    class function Path(const ARelativePath: string): string; static;
    class function Exists(const ARelativePath: string): Boolean; static;
    /// <summary>The bytes of a file</summary>
    class function ReadBytes(const ARelativePath: string): AnsiString; static;
    /// <summary>The lines of a text file</summary>
    class function ReadLines(const ARelativePath: string): TStringList; static;
    /// <summary>Compares the lines of a golden file with the ones that were made</summary>
    class function Compare(const AGoldenPath: string; const AActual: TStrings): string; static;
  end;

implementation

uses
  System.IOUtils;

{ TIdeTestData }

class function TIdeTestData.Path(const ARelativePath: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Ide\' + ARelativePath));
end;

class function TIdeTestData.Exists(const ARelativePath: string): Boolean;
begin
  Result := TFile.Exists(Path(ARelativePath));
end;

class function TIdeTestData.ReadBytes(const ARelativePath: string): AnsiString;
var
  LBytes: TBytes;
begin
  LBytes := TFile.ReadAllBytes(Path(ARelativePath));
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

class function TIdeTestData.ReadLines(const ARelativePath: string): TStringList;
begin
  Result := TStringList.Create;
  try
    Result.LoadFromFile(Path(ARelativePath));
  except
    Result.Free;
    raise;
  end;
end;

class function TIdeTestData.Compare(const AGoldenPath: string; const AActual: TStrings): string;
var
  LGolden: TStringList;
  LIndex: Integer;
begin
  Result := '';
  LGolden := ReadLines(AGoldenPath);
  try
    for LIndex := 0 to LGolden.Count - 1 do
    begin
      if LIndex >= AActual.Count then
        Exit(Format('%s: line %d is missing, expected "%s"', [AGoldenPath, LIndex + 1, LGolden[LIndex]]));
      if LGolden[LIndex] <> AActual[LIndex] then
        Exit(Format('%s: line %d is "%s", expected "%s"',
          [AGoldenPath, LIndex + 1, AActual[LIndex], LGolden[LIndex]]));
    end;
    if AActual.Count > LGolden.Count then
      Result := Format('%s: %d lines more than expected, the first is "%s"',
        [AGoldenPath, AActual.Count - LGolden.Count, AActual[LGolden.Count]]);
  finally
    LGolden.Free;
  end;
end;

end.
