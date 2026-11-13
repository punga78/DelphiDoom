{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRoqQuadMap                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.QuadMap;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('cinematic')]
  TTestRoqQuadMap = class(TObject)
  public
    [Test]
    procedure DovrebbeDareVentiBloccoPerMacroblocco;
    [Test]
    procedure DovrebbeSeguireLOrdineOttoPerOttoESuoiQuattroPerQuattro;
    [Test]
    procedure DovrebbeSeguireLeMacroblocchePerRiga;
    [Test]
    procedure DovrebbeUsareLaLarghezzaComePasso;
  end;

implementation

uses
  DelphiDoom.Cinematic.QuadMap;

{ TTestRoqQuadMap }

procedure TTestRoqQuadMap.DovrebbeDareVentiBloccoPerMacroblocco;
var
  LMap: TRoqQuadMap;
begin
  LMap := TRoqQuadMap.Create(16, 16);
  try
    Assert.AreEqual(20, LMap.Count);
  finally
    LMap.Free;
  end;
  LMap := TRoqQuadMap.Create(48, 32);
  try
    Assert.AreEqual(6 * 20, LMap.Count);
  finally
    LMap.Free;
  end;
end;

procedure TTestRoqQuadMap.DovrebbeSeguireLOrdineOttoPerOttoESuoiQuattroPerQuattro;
var
  LMap: TRoqQuadMap;
begin
  LMap := TRoqQuadMap.Create(16, 16);
  try
    // the 8x8 block at (0, 0), then its 4x4 blocks (0,0) (4,0) (0,4) (4,4)
    Assert.AreEqual(0, LMap.Offset(0));
    Assert.AreEqual(0, LMap.Offset(1));
    Assert.AreEqual(4, LMap.Offset(2));
    Assert.AreEqual(4 * 16, LMap.Offset(3));
    Assert.AreEqual(4 * 16 + 4, LMap.Offset(4));
    // then the 8x8 block at (8, 0) and the one at (0, 8)
    Assert.AreEqual(8, LMap.Offset(5));
    Assert.AreEqual(8 * 16, LMap.Offset(10));
    Assert.AreEqual(8 * 16 + 8, LMap.Offset(15));
  finally
    LMap.Free;
  end;
end;

procedure TTestRoqQuadMap.DovrebbeSeguireLeMacroblocchePerRiga;
var
  LMap: TRoqQuadMap;
begin
  LMap := TRoqQuadMap.Create(32, 32);
  try
    Assert.AreEqual(16, LMap.Offset(20));
    Assert.AreEqual(16 * 32, LMap.Offset(40));
    Assert.AreEqual(16 * 32 + 16, LMap.Offset(60));
  finally
    LMap.Free;
  end;
end;

procedure TTestRoqQuadMap.DovrebbeUsareLaLarghezzaComePasso;
var
  LMap: TRoqQuadMap;
begin
  LMap := TRoqQuadMap.Create(64, 16);
  try
    Assert.AreEqual(4 * 20, LMap.Count);
    Assert.AreEqual(4 * 64, LMap.Offset(3));
    Assert.AreEqual(48, LMap.Offset(60));
  finally
    LMap.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRoqQuadMap);

end.
