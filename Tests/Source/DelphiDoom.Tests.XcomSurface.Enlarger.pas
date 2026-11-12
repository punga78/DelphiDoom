{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the pictures enlarged by the nearest pixel         }
{  (issue 183)                                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSurface.Enlarger;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomSurface.Enlarger;

type
  [TestFixture]
  [Category('XcomSurface')]
  TTestXcomSurfaceEnlarger = class
  strict private
    FSource: TXcomSurface;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('uguale', '1')]
    [TestCase('doppio', '2')]
    [TestCase('triplo', '3')]
    procedure OgniPixelDovrebbeDiventareUnQuadrato(AScale: Integer);
    [Test]
    procedure IlColoreZeroDovrebbeLasciareCioCheCESotto;
    [Test]
    procedure CioCheEsceDalBersaglioDovrebbeEssereTagliato;
    [Test]
    procedure UnInsiemeDovrebbeTenereINumeriDeiFotogrammi;
    [Test]
    procedure LaSovrapposizioneDovrebbeCoprireSoloDoveNonEZero;
    [Test]
    procedure UnaScalaSottoUnoDovrebbeSollevare;
    [Test]
    procedure UnaSovrapposizioneDiMisuraDiversaDovrebbeSollevare;
  end;

implementation

procedure TTestXcomSurfaceEnlarger.Setup;
begin
  // 3 x 2:  1 0 3
  //         4 5 6
  FSource := TXcomSurface.Create(3, 2);
  FSource.SetPixel(0, 0, 1);
  FSource.SetPixel(2, 0, 3);
  FSource.SetPixel(0, 1, 4);
  FSource.SetPixel(1, 1, 5);
  FSource.SetPixel(2, 1, 6);
end;

procedure TTestXcomSurfaceEnlarger.TearDown;
begin
  FSource.Free;
end;

procedure TTestXcomSurfaceEnlarger.OgniPixelDovrebbeDiventareUnQuadrato(AScale: Integer);
var
  LLarge: TXcomSurface;
  LX: Integer;
  LY: Integer;
begin
  LLarge := TXcomSurfaceEnlarger.Enlarge(FSource, AScale);
  try
    Assert.AreEqual(3 * AScale, LLarge.Width);
    Assert.AreEqual(2 * AScale, LLarge.Height);
    for LY := 0 to LLarge.Height - 1 do
      for LX := 0 to LLarge.Width - 1 do
        Assert.AreEqual(FSource.GetPixel(LX div AScale, LY div AScale), LLarge.GetPixel(LX, LY),
          Format('%d,%d', [LX, LY]));
  finally
    LLarge.Free;
  end;
end;

procedure TTestXcomSurfaceEnlarger.IlColoreZeroDovrebbeLasciareCioCheCESotto;
var
  LTarget: TXcomSurface;
begin
  LTarget := TXcomSurface.Create(10, 10);
  try
    LTarget.DrawRect(0, 0, 10, 10, 9);
    TXcomSurfaceEnlarger.BlitEnlarged(FSource, LTarget, 2, 3, 2);
    Assert.AreEqual(Byte(1), LTarget.GetPixel(2, 3));
    Assert.AreEqual(Byte(1), LTarget.GetPixel(3, 4));
    Assert.AreEqual(Byte(9), LTarget.GetPixel(4, 3), 'il pixel trasparente della sorgente');
    Assert.AreEqual(Byte(9), LTarget.GetPixel(5, 4));
    Assert.AreEqual(Byte(3), LTarget.GetPixel(6, 3));
    Assert.AreEqual(Byte(6), LTarget.GetPixel(7, 6));
    Assert.AreEqual(Byte(9), LTarget.GetPixel(8, 6), 'oltre il bordo destro della sorgente');
    Assert.AreEqual(Byte(9), LTarget.GetPixel(1, 3));
  finally
    LTarget.Free;
  end;
end;

procedure TTestXcomSurfaceEnlarger.CioCheEsceDalBersaglioDovrebbeEssereTagliato;
var
  LTarget: TXcomSurface;
begin
  LTarget := TXcomSurface.Create(4, 3);
  try
    TXcomSurfaceEnlarger.BlitEnlarged(FSource, LTarget, -1, -1, 2);
    // the source pixel (0,0) covers (-1..0, -1..0): only its last corner is inside
    Assert.AreEqual(Byte(1), LTarget.GetPixel(0, 0));
    Assert.AreEqual(Byte(0), LTarget.GetPixel(1, 0));
    Assert.AreEqual(Byte(3), LTarget.GetPixel(3, 0));
    Assert.AreEqual(Byte(4), LTarget.GetPixel(0, 1));
    Assert.AreEqual(Byte(5), LTarget.GetPixel(1, 2));
    Assert.AreEqual(Byte(6), LTarget.GetPixel(3, 2));
    TXcomSurfaceEnlarger.BlitEnlarged(FSource, LTarget, 100, 100, 2);
    TXcomSurfaceEnlarger.BlitEnlarged(FSource, LTarget, -100, -100, 2);
    Assert.AreEqual(Byte(1), LTarget.GetPixel(0, 0));
  finally
    LTarget.Free;
  end;
end;

procedure TTestXcomSurfaceEnlarger.UnInsiemeDovrebbeTenereINumeriDeiFotogrammi;
var
  LSet: TXcomSurfaceSet;
  LLarge: TXcomSurfaceSet;
begin
  LSet := TXcomSurfaceSet.Create(2, 2);
  try
    LSet.AddFrame(0).SetPixel(0, 0, 7);
    LSet.AddFrame(5).SetPixel(1, 1, 8);
    LLarge := TXcomSurfaceEnlarger.EnlargeSet(LSet, 3);
    try
      Assert.AreEqual(6, LLarge.Width);
      Assert.AreEqual(6, LLarge.Height);
      Assert.AreEqual(2, LLarge.TotalFrames);
      Assert.IsTrue(LLarge.GetFrame(1) = nil);
      Assert.AreEqual(Byte(7), LLarge.GetFrame(0).GetPixel(2, 2));
      Assert.AreEqual(Byte(0), LLarge.GetFrame(0).GetPixel(3, 2));
      Assert.AreEqual(Byte(8), LLarge.GetFrame(5).GetPixel(3, 3));
      Assert.AreEqual(Byte(8), LLarge.GetFrame(5).GetPixel(5, 5));
    finally
      LLarge.Free;
    end;
  finally
    LSet.Free;
  end;
end;

procedure TTestXcomSurfaceEnlarger.LaSovrapposizioneDovrebbeCoprireSoloDoveNonEZero;
var
  LTarget: TXcomSurface;
begin
  LTarget := TXcomSurface.Create(3, 2);
  try
    LTarget.DrawRect(0, 0, 3, 2, 9);
    TXcomSurfaceEnlarger.Overlay(FSource, LTarget);
    Assert.AreEqual(Byte(1), LTarget.GetPixel(0, 0));
    Assert.AreEqual(Byte(9), LTarget.GetPixel(1, 0));
    Assert.AreEqual(Byte(6), LTarget.GetPixel(2, 1));
  finally
    LTarget.Free;
  end;
end;

procedure TTestXcomSurfaceEnlarger.UnaScalaSottoUnoDovrebbeSollevare;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomSurfaceEnlarger.Enlarge(FSource, 0);
    end, EXcomSurfaceException);
end;

procedure TTestXcomSurfaceEnlarger.UnaSovrapposizioneDiMisuraDiversaDovrebbeSollevare;
var
  LTarget: TXcomSurface;
begin
  LTarget := TXcomSurface.Create(4, 2);
  try
    Assert.WillRaise(
      procedure
      begin
        TXcomSurfaceEnlarger.Overlay(FSource, LTarget);
      end, EXcomSurfaceException);
  finally
    LTarget.Free;
  end;
end;

end.
