{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixBitmapOps                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.BitmapOps;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.BitmapOps;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixBitmapOps = class(TObject)
  public
    [Test]
    procedure DovrebbeTrasporreUnBuffer;
    [Test]
    procedure DovrebbeRibaltareLeRighe;
    [Test]
    procedure DovrebbeCopiareUnaFinestraDiColonne;
    [Test]
    procedure DovrebbeSostituireUnColore;
  end;

implementation

function Join(const ABytes: TBytes): string;
var
  LByte: Byte;
begin
  Result := '';
  for LByte in ABytes do
    Result := Result + IntToStr(LByte) + ',';
end;

{ TTestRadixBitmapOps }

procedure TTestRadixBitmapOps.DovrebbeTrasporreUnBuffer;
var
  LBuffer: TBytes;
begin
  // a 3 x 2 buffer (width 3, height 2): the transposed one is written back in the same cells
  LBuffer := TBytes.Create(1, 2, 3, 4, 5, 6);
  TRadixBitmapOps.Rotate90(LBuffer, 3, 2);
  Assert.AreEqual(Join(TBytes.Create(1, 4, 2, 5, 3, 6)), Join(LBuffer));
end;

procedure TTestRadixBitmapOps.DovrebbeRibaltareLeRighe;
var
  LBuffer: TBytes;
begin
  LBuffer := TBytes.Create(1, 2, 3, 4, 5, 6);
  TRadixBitmapOps.FlipHorizontal(LBuffer, 3, 2);
  Assert.AreEqual(Join(TBytes.Create(4, 5, 6, 1, 2, 3)), Join(LBuffer));
end;

procedure TTestRadixBitmapOps.DovrebbeCopiareUnaFinestraDiColonne;
var
  LInput: TBytes;
begin
  // 3 columns of 4 pixels: the columns 1..2, the rows 1..2
  LInput := TBytes.Create(0, 1, 2, 3, 10, 11, 12, 13, 20, 21, 22, 23);
  Assert.AreEqual(Join(TBytes.Create(11, 12, 21, 22)), Join(TRadixBitmapOps.Blt(LInput, 4, 1, 2, 1, 2)));
end;

procedure TTestRadixBitmapOps.DovrebbeSostituireUnColore;
var
  LBuffer: TBytes;
begin
  LBuffer := TBytes.Create(1, 2, 1, 3);
  TRadixBitmapOps.ColorReplace(LBuffer, 3, 1, 9);
  Assert.AreEqual(Join(TBytes.Create(9, 2, 9, 3)), Join(LBuffer));
end;

end.

