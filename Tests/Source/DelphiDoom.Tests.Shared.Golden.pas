{******************************************************************************}
{                                                                              }
{  DelphiDoom: common code of the test suites - the lines of a golden file      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Shared.Golden;

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>
  ///   A golden file is the answer of the old code (or of the original program), a line for each case: the test
  ///   fails at the first line that differs and says which one, instead of saying only that two texts differ
  /// </summary>
  TTestGolden = class
  public
    /// <summary>Fails the test at the first line of AActual that is missing or is not the one of AGolden, or when AActual has more lines</summary>
    class procedure AssertSameLines(AGolden, AActual: TStrings); static;
  end;

implementation

uses
  DUnitX.TestFramework;

const
  SMissingLines = 'mancano le righe dalla %d: "%s"';
  SDifferentLine = 'riga %d: atteso "%s" ottenuto "%s"';
  SLineCount = 'numero di righe';

class procedure TTestGolden.AssertSameLines(AGolden, AActual: TStrings);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AGolden.Count - 1 do
  begin
    if LIndex >= AActual.Count then
      Assert.Fail(Format(SMissingLines, [LIndex + 1, AGolden[LIndex]]));
    if AGolden[LIndex] <> AActual[LIndex] then
      Assert.Fail(Format(SDifferentLine, [LIndex + 1, AGolden[LIndex], AActual[LIndex]]));
  end;
  Assert.AreEqual(AGolden.Count, AActual.Count, SLineCount);
end;

end.
