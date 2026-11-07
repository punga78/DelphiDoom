{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegGrayConverter                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.GrayConverter;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegGrayConverter = class(TObject)
  public
    [Test]
    procedure TestCopiesTheSamples;
  end;

implementation

uses
  DelphiDoom.Jpeg.ColorConverter, DelphiDoom.Jpeg.GrayConverter;

{ TTestJpegGrayConverter }

procedure TTestJpegGrayConverter.TestCopiesTheSamples;
var
  LConverter: IJpegColorConverter;
  LInput: TBytes;
  LOutput: TBytes;
begin
  LConverter := TJpegGrayConverter.Create;
  LInput := TBytes.Create(1, 2, 3, 4);
  SetLength(LOutput, 4);
  LConverter.ConvertRow([@LInput[0]], @LOutput[0], 4);
  Assert.AreEqual(4, Integer(LOutput[3]));
  Assert.AreEqual(2, Integer(LOutput[1]));
  Assert.AreEqual(1, LConverter.OutputComponents);
end;

end.
