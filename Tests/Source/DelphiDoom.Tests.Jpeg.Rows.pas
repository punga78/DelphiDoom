{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the JPEG decoder - checks of rows of samples           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Rows;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Checks that a row of samples starts with the values that are expected
  /// </summary>
  TJpegRowChecks = class
  public
    class procedure AssertStartsWith(const AExpected: array of Byte; const AActual: TBytes); static;
  end;

implementation

uses
  DUnitX.TestFramework;

{ TJpegRowChecks }

class procedure TJpegRowChecks.AssertStartsWith(const AExpected: array of Byte;
  const AActual: TBytes);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AExpected) do
    Assert.AreEqual(Integer(AExpected[LIndex]), Integer(AActual[LIndex]),
      'Sample ' + IntToStr(LIndex));
end;

end.
