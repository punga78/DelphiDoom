{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Imaging library - reads the golden files           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.Golden;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   Tests\Data\Imaging\*.golden.txt: one "name=value" line for each case, written by a
  ///   harness that ran the old code of the engine on the inputs of the Samples unit
  /// </summary>
  TImagingGolden = class sealed
  public
    class function DataDir: string; static;
    class function Load(const AFile: string): TStringList; static;
    /// <summary>The golden value of a case; fails the test if the file or the case is missing</summary>
    class function Value(const AFile, AName: string): string; static;
    class procedure Check(const AFile, AName, AActual: string); static;
  end;

implementation

{ TImagingGolden }

class function TImagingGolden.DataDir: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Imaging\'));
end;

class function TImagingGolden.Load(const AFile: string): TStringList;
begin
  Result := TStringList.Create;
  try
    Result.NameValueSeparator := '=';
    Result.LoadFromFile(TPath.Combine(DataDir, AFile));
  except
    Result.Free;
    raise;
  end;
end;

class function TImagingGolden.Value(const AFile, AName: string): string;
var
  LLines: TStringList;
  LIndex: Integer;
begin
  LLines := Load(AFile);
  try
    LIndex := LLines.IndexOfName(AName);
    if LIndex < 0 then
      raise Exception.CreateFmt('The case "%s" is not in %s', [AName, AFile]);
    Result := LLines.ValueFromIndex[LIndex];
  finally
    LLines.Free;
  end;
end;

class procedure TImagingGolden.Check(const AFile, AName, AActual: string);
begin
  Assert.AreEqual(Value(AFile, AName), AActual, AFile + ': ' + AName);
end;

end.
