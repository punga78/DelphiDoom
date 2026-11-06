{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the types of the Imaging library                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.Types;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types;

type
  [TestFixture]
  [Category('imaging')]
  TTestImagingTypes = class(TObject)
  public
    [Test]
    procedure TestPatchHeaderSizeIsEightBytes;
    [Test]
    procedure TestPostHeaderSizeIsThreeBytes;
    [Test]
    procedure TestPatchHeaderFieldsAreInOrder;
    [Test]
    procedure TestConstantsAreThoseOfTheEngine;
  end;

implementation

procedure TTestImagingTypes.TestPatchHeaderSizeIsEightBytes;
begin
  Assert.AreEqual(8, SizeOf(TImagingPatchHeader), 'dovrebbe avere 8 byte come l''intestazione di un patch');
end;

procedure TTestImagingTypes.TestPostHeaderSizeIsThreeBytes;
begin
  Assert.AreEqual(3, SizeOf(TImagingPostHeader), 'dovrebbe avere 3 byte come l''intestazione di un post');
end;

procedure TTestImagingTypes.TestPatchHeaderFieldsAreInOrder;
var
  LBytes: array[0..7] of Byte;
  LHeader: TImagingPatchHeader;
begin
  LBytes[0] := 1; LBytes[1] := 0;
  LBytes[2] := 2; LBytes[3] := 0;
  LBytes[4] := $FE; LBytes[5] := $FF;
  LBytes[6] := 4; LBytes[7] := 0;
  Move(LBytes[0], LHeader, SizeOf(LHeader));
  Assert.AreEqual(1, Integer(LHeader.Width), 'dovrebbe leggere la larghezza per prima');
  Assert.AreEqual(2, Integer(LHeader.Height), 'dovrebbe leggere poi l''altezza');
  Assert.AreEqual(-2, Integer(LHeader.LeftOffset), 'dovrebbe leggere lo scostamento sinistro con segno');
  Assert.AreEqual(4, Integer(LHeader.TopOffset), 'dovrebbe leggere per ultimo lo scostamento alto');
end;

procedure TTestImagingTypes.TestConstantsAreThoseOfTheEngine;
begin
  Assert.AreEqual(65536, IMAGING_FRACUNIT, 'dovrebbe avere FRACUNIT 65536');
  Assert.AreEqual(81920, IMAGING_SINE_TABLE_SIZE, 'dovrebbe avere cinque quarti di cerchio a 16 bit');
  Assert.AreEqual(4096, IMAGING_FLAT_PIXELS, 'dovrebbe avere 4096 pixel nel flat base');
  Assert.AreEqual(8, IMAGING_HIRES_FACTOR, 'dovrebbe avere 8 livelli');
end;

end.
