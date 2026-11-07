{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Screenshot library - the golden files              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Screenshot.Golden;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   Tests\Data\Screenshot\*.golden.txt: one "name=value" line for each case, written by a
  ///   harness that ran the old code of the engine on the inputs of the Samples unit
  /// </summary>
  TScreenshotGolden = class sealed
  public
    class function DataDir: string; static;
    class function Value(const AFile, AName: string): string; static;
    class procedure Check(const AFile, AName, AActual: string); static;
  end;

implementation

{ TScreenshotGolden }

class function TScreenshotGolden.DataDir: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Screenshot\'));
end;

class function TScreenshotGolden.Value(const AFile, AName: string): string;
var
  LLines: TStringList;
  LIndex: Integer;
begin
  LLines := TStringList.Create;
  try
    LLines.NameValueSeparator := '=';
    LLines.LoadFromFile(TPath.Combine(DataDir, AFile));
    LIndex := LLines.IndexOfName(AName);
    if LIndex < 0 then
      raise Exception.CreateFmt('The case "%s" is not in %s', [AName, AFile]);
    Result := LLines.ValueFromIndex[LIndex];
  finally
    LLines.Free;
  end;
end;

class procedure TScreenshotGolden.Check(const AFile, AName, AActual: string);
begin
  Assert.AreEqual(Value(AFile, AName), AActual, AFile + ': ' + AName);
end;

end.
