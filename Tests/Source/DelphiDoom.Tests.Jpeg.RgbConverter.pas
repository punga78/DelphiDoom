{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegRgbConverter                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.RgbConverter;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegRgbConverter = class(TObject)
  public
    [Test]
    procedure TestInterleavesTheComponentsInTheOrderOfTheStream;
  end;

implementation

uses
  DelphiDoom.Jpeg.ColorConverter, DelphiDoom.Jpeg.RgbConverter;

{ TTestJpegRgbConverter }

procedure TTestJpegRgbConverter.TestInterleavesTheComponentsInTheOrderOfTheStream;
var
  LConverter: IJpegColorConverter;
  LFirst, LSecond, LThird: TBytes;
  LOutput: TBytes;
begin
  LConverter := TJpegRgbConverter.Create;
  LFirst := TBytes.Create(1, 2);
  LSecond := TBytes.Create(11, 12);
  LThird := TBytes.Create(21, 22);
  SetLength(LOutput, 6);
  LConverter.ConvertRow([@LFirst[0], @LSecond[0], @LThird[0]], @LOutput[0], 2);
  Assert.AreEqual(1, Integer(LOutput[0]));
  Assert.AreEqual(11, Integer(LOutput[1]));
  Assert.AreEqual(21, Integer(LOutput[2]));
  Assert.AreEqual(2, Integer(LOutput[3]));
  Assert.AreEqual(22, Integer(LOutput[5]));
  Assert.AreEqual(3, LConverter.OutputComponents);
end;

end.
