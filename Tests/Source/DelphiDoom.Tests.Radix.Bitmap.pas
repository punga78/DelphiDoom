{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixBitmap                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.Bitmap;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Bitmap;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixBitmap = class(TObject)
  strict private
    FBitmap: TRadixBitmap;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeTenereIPixelPerColonne;
    [Test]
    procedure DovrebbeLeggereZeroFuoriDallImmagine;
    [Test]
    procedure DovrebbeIgnorareLeScrittureFuoriDallImmagine;
    [Test]
    procedure DovrebbeRiempireDiUnColore;
    [Test]
    procedure DovrebbeTagliareTenendoIPixelInComune;
    [Test]
    procedure DovrebbeTogliereLUltimaRigaSoloSeETuttaDiBuchi;
    [Test]
    procedure DovrebbeApplicareUnaTabellaDiTraduzione;
    [Test]
    procedure DovrebbePrendereLeDimensioniEIPixelDiUnBuffer;
  end;

implementation

{ TTestRadixBitmap }

procedure TTestRadixBitmap.Setup;
begin
  FBitmap := TRadixBitmap.Create;
  FBitmap.Width := 3;
  FBitmap.Height := 2;
  FBitmap.Clear(0);
end;

procedure TTestRadixBitmap.TearDown;
begin
  FBitmap.Free;
end;

procedure TTestRadixBitmap.DovrebbeTenereIPixelPerColonne;
begin
  FBitmap[2, 1] := 7;
  Assert.AreEqual(7, Integer(FBitmap.Image[2 * 2 + 1]));
end;

procedure TTestRadixBitmap.DovrebbeLeggereZeroFuoriDallImmagine;
begin
  FBitmap.Clear(9);
  Assert.AreEqual(0, Integer(FBitmap[3, 0]));
  Assert.AreEqual(0, Integer(FBitmap[0, -1]));
end;

procedure TTestRadixBitmap.DovrebbeIgnorareLeScrittureFuoriDallImmagine;
begin
  FBitmap[3, 0] := 5;
  FBitmap[0, 2] := 5;
  Assert.AreEqual(6, Length(FBitmap.Image));
  Assert.AreEqual(0, Integer(FBitmap[2, 1]));
end;

procedure TTestRadixBitmap.DovrebbeRiempireDiUnColore;
var
  LIndex: Integer;
begin
  FBitmap.Clear(254);
  for LIndex := 0 to 5 do
    Assert.AreEqual(254, Integer(FBitmap.Image[LIndex]));
end;

procedure TTestRadixBitmap.DovrebbeTagliareTenendoIPixelInComune;
begin
  FBitmap[1, 1] := 4;
  FBitmap[2, 0] := 8;
  FBitmap.Crop(2, 2);
  Assert.AreEqual(2, FBitmap.Width);
  Assert.AreEqual(4, Integer(FBitmap[1, 1]));
  Assert.AreEqual(0, Integer(FBitmap[2, 0]));
end;

procedure TTestRadixBitmap.DovrebbeTogliereLUltimaRigaSoloSeETuttaDiBuchi;
begin
  FBitmap.Clear(254);
  Assert.IsTrue(FBitmap.BottomCrop);
  Assert.AreEqual(1, FBitmap.Height);
  FBitmap.Height := 2;
  FBitmap.Clear(254);
  FBitmap[1, 1] := 3;
  Assert.IsFalse(FBitmap.BottomCrop);
  Assert.AreEqual(2, FBitmap.Height);
end;

procedure TTestRadixBitmap.DovrebbeApplicareUnaTabellaDiTraduzione;
var
  LTable: TBytes;
  LIndex: Integer;
begin
  SetLength(LTable, 256);
  for LIndex := 0 to 255 do
    LTable[LIndex] := 255 - LIndex;
  FBitmap[0, 0] := 10;
  FBitmap.ApplyTranslationTable(LTable);
  Assert.AreEqual(245, Integer(FBitmap[0, 0]));
  Assert.AreEqual(255, Integer(FBitmap[1, 1]));
end;

procedure TTestRadixBitmap.DovrebbePrendereLeDimensioniEIPixelDiUnBuffer;
begin
  FBitmap.AttachImage(TBytes.Create(1, 2, 3, 4), 2, 2);
  Assert.AreEqual(2, FBitmap.Width);
  Assert.AreEqual(2, FBitmap.Height);
  Assert.AreEqual(3, Integer(FBitmap[1, 0]));
end;

end.
