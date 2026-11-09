{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the font library - reads the golden files               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Font.Golden;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections;

type
  /// <summary>
  ///   The golden files of issue #167 (what the old DD_FONT gave, made by a harness that is outside of the
  ///   repository): each line starts with a word, the kind, then a number and what the old code answered
  /// </summary>
  TFontGolden = class sealed
  public
    /// <summary>The lines of a file of Tests\Data whose first word is AKind, without that word</summary>
    class function Lines(const AFileName, AKind: string): TArray<string>; static;
    /// <summary>The words of a line, separated by a space</summary>
    class function Words(const ALine: string): TArray<string>; static;
  end;

implementation

{ TFontGolden }

class function TFontGolden.Lines(const AFileName, AKind: string): TArray<string>;
var
  LLines: TStringList;
  LResult: TList<string>;
  LLine: string;
  LPrefix: string;
begin
  LResult := TList<string>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\' + AFileName));
    LPrefix := AKind + ' ';
    for LLine in LLines do
      if LLine.StartsWith(LPrefix) then
        LResult.Add(Copy(LLine, Length(LPrefix) + 1, MaxInt));
    Result := LResult.ToArray;
  finally
    LLines.Free;
    LResult.Free;
  end;
end;

class function TFontGolden.Words(const ALine: string): TArray<string>;
begin
  Result := ALine.Split([' ']);
end;

end.
