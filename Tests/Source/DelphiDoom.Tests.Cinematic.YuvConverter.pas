{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRoqYuvConverter                                       }
{                                                                              }
{  The golden line (Tests\Data\Cinematic\tables.golden.txt) is made by the     }
{  code of Quake III Arena (cl_cin.c) compiled with gcc: Tools\Verifica\114.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.YuvConverter;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('cinematic')]
  TTestRoqYuvConverter = class(TObject)
  public
    [Test]
    procedure DovrebbeDareGrigioPerCrECbCentrali;
    [Test]
    procedure DovrebbeSaturareICanali;
    [Test]
    procedure DovrebbeUsareLAlphaDato;
    [Test]
    procedure DovrebbeDareLeStessePixelDelCPerTutteLeTerne;
  end;

implementation

uses
  System.SysUtils, System.Classes,
  DelphiDoom.MathCore.Crc32,
  DelphiDoom.Cinematic.YuvConverter,
  DelphiDoom.Tests.Cinematic.Support;

{ TTestRoqYuvConverter }

procedure TTestRoqYuvConverter.DovrebbeDareGrigioPerCrECbCentrali;
var
  LConverter: TRoqYuvConverter;
  LPixel: Cardinal;
begin
  LConverter := TRoqYuvConverter.Create($FF);
  try
    LPixel := LConverter.ToPixel(128, 128, 128);
    // the three channels are almost equal, never far from the luma
    Assert.IsTrue(Abs(Integer(LPixel and $FF) - 128) <= 3);
    Assert.IsTrue(Abs(Integer((LPixel shr 8) and $FF) - 128) <= 3);
    Assert.IsTrue(Abs(Integer((LPixel shr 16) and $FF) - 128) <= 3);
    Assert.AreEqual($FF, Integer(LPixel shr 24));
  finally
    LConverter.Free;
  end;
end;

procedure TTestRoqYuvConverter.DovrebbeSaturareICanali;
var
  LConverter: TRoqYuvConverter;
begin
  LConverter := TRoqYuvConverter.Create($FF);
  try
    // black with the lowest chroma: the negative red and blue become 0
    Assert.AreEqual(0, Integer(LConverter.ToPixel(0, 0, 0) and $FF));
    Assert.AreEqual(0, Integer((LConverter.ToPixel(0, 0, 0) shr 16) and $FF));
    // the brightest luma with the highest chroma: red and blue go over 255 and are clamped
    Assert.AreEqual(255, Integer(LConverter.ToPixel(255, 255, 255) and $FF));
    Assert.AreEqual(255, Integer((LConverter.ToPixel(255, 255, 255) shr 16) and $FF));
  finally
    LConverter.Free;
  end;
end;

procedure TTestRoqYuvConverter.DovrebbeUsareLAlphaDato;
var
  LOpaque, LClear: TRoqYuvConverter;
begin
  LOpaque := TRoqYuvConverter.Create($FF);
  LClear := TRoqYuvConverter.Create(0);
  try
    Assert.AreEqual(0, Integer(LClear.ToPixel(100, 90, 80) shr 24));
    Assert.AreEqual(Cardinal(LClear.ToPixel(100, 90, 80)) or $FF000000,
      Cardinal(LOpaque.ToPixel(100, 90, 80)));
  finally
    LClear.Free;
    LOpaque.Free;
  end;
end;

procedure TTestRoqYuvConverter.DovrebbeDareLeStessePixelDelCPerTutteLeTerne;
var
  LConverter: TRoqYuvConverter;
  LCrc: TCrc32;
  LRow: array[0..255] of Cardinal;
  LLuma, LU, LV: Integer;
  LGolden: TStringList;
  LExpected: string;
begin
  LGolden := TRoqTestData.ReadLines('tables.golden.txt');
  LConverter := TRoqYuvConverter.Create($FF);
  LCrc := TCrc32.Create;
  try
    for LLuma := 0 to 255 do
      for LU := 0 to 255 do
      begin
        for LV := 0 to 255 do
          LRow[LV] := LConverter.ToPixel(LLuma, LU, LV);
        LCrc.Update(LRow, SizeOf(LRow));
      end;
    LExpected := LGolden[0];
    Assert.AreEqual('yuv crc ' + LowerCase(IntToHex(LCrc.Value, 8)), LExpected);
  finally
    LCrc.Free;
    LConverter.Free;
    LGolden.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRoqYuvConverter);

end.
