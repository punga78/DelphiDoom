{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - vectors, time and straight velocity  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelMath;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Model.Types;

type
  [TestFixture]
  [Category('war')]
  TTestWarModelMath = class(TObject)
  public
    [Test]
    procedure DovrebbeSommareESottrarreIVettori;
    [Test]
    procedure DovrebbeDareLunghezzeEDistanze;
    [Test]
    procedure DovrebbeNormalizzareEDareZeroPerIlVettoreNullo;
    [Test]
    procedure DovrebbeDareLaDistanzaInCaselleComeIlPiuGrandeDeiDueScarti;
    [Test]
    procedure DovrebbePassareDaPixelACaselleArrotondandoPerDifettoAncheSottoZero;
    [Test]
    procedure DovrebbePassareDaCaselleAPixelAncheAlCentro;
    [TestCase('nordovest', '-1,-1,7')]
    [TestCase('nord', '0,-1,0')]
    [TestCase('nordest', '1,-1,1')]
    [TestCase('ovest', '-1,0,6')]
    [TestCase('est', '1,0,2')]
    [TestCase('sudovest', '-1,1,5')]
    [TestCase('sud', '0,1,4')]
    [TestCase('sudest', '1,1,3')]
    [TestCase('fermo', '0,0,0')]
    procedure DovrebbeDareLaDirezioneDiUnoScarto(AX, AY, AExpected: Integer);
    [Test]
    procedure DovrebbeDareLaPercentualeTroncata;
    [Test]
    procedure DovrebbeDareSecondiDaiFotogrammi;
    [Test]
    procedure DovrebbeScalareIlTempoSecondoLaVelocitaDellaMappa;
  end;

implementation

uses
  DelphiDoom.War.Model.Math;

{ TTestWarModelMath }

procedure TTestWarModelMath.DovrebbeSommareESottrarreIVettori;
var
  LSum: TWarVec2;
  LDifference: TWarVec2;
  LScaled: TWarVec2;
  LHalf: TWarVec2;
begin
  LSum := TWarModelMath.Add(TWarModelMath.Vec(1, 2), TWarModelMath.Vec(3, 5));
  LDifference := TWarModelMath.Sub(TWarModelMath.Vec(1, 2), TWarModelMath.Vec(3, 5));
  LScaled := TWarModelMath.Scale(TWarModelMath.Vec(1, 2), 3);
  LHalf := TWarModelMath.Half(TWarModelMath.Vec(5, 2));
  Assert.AreEqual<Single>(4, LSum.X);
  Assert.AreEqual<Single>(7, LSum.Y);
  Assert.AreEqual<Single>(-2, LDifference.X);
  Assert.AreEqual<Single>(-3, LDifference.Y);
  Assert.AreEqual<Single>(3, LScaled.X);
  Assert.AreEqual<Single>(6, LScaled.Y);
  Assert.AreEqual<Single>(2.5, LHalf.X);
  Assert.AreEqual<Single>(1, LHalf.Y);
end;

procedure TTestWarModelMath.DovrebbeDareLunghezzeEDistanze;
begin
  Assert.AreEqual<Single>(25, TWarModelMath.LengthSqr(TWarModelMath.Vec(3, 4)));
  Assert.AreEqual<Single>(5, TWarModelMath.Length(TWarModelMath.Vec(3, 4)));
  Assert.AreEqual<Single>(25, TWarModelMath.DistanceSqr(TWarModelMath.Vec(1, 1), TWarModelMath.Vec(4, 5)));
end;

procedure TTestWarModelMath.DovrebbeNormalizzareEDareZeroPerIlVettoreNullo;
var
  LUnit: TWarVec2;
  LZero: TWarVec2;
begin
  LUnit := TWarModelMath.Normalize(TWarModelMath.Vec(0, 7));
  LZero := TWarModelMath.Normalize(TWarModelMath.Vec(0, 0));
  Assert.AreEqual<Single>(0, LUnit.X);
  Assert.AreEqual<Single>(1, LUnit.Y);
  Assert.AreEqual<Single>(0, LZero.X);
  Assert.AreEqual<Single>(0, LZero.Y);
end;

procedure TTestWarModelMath.DovrebbeDareLaDistanzaInCaselleComeIlPiuGrandeDeiDueScarti;
begin
  Assert.AreEqual<Single>(7, TWarModelMath.DistanceInTiles(TWarModelMath.Vec(1, 1), TWarModelMath.Vec(8, 3)));
  Assert.AreEqual<Single>(7, TWarModelMath.DistanceInTiles(TWarModelMath.Vec(1, 1), TWarModelMath.Vec(3, 8)));
end;

procedure TTestWarModelMath.DovrebbePassareDaPixelACaselleArrotondandoPerDifettoAncheSottoZero;
var
  LTile: TWarVec2;
begin
  LTile := TWarModelMath.MapToTile(TWarModelMath.Vec(47, 16));
  Assert.AreEqual<Single>(2, LTile.X);
  Assert.AreEqual<Single>(1, LTile.Y);
  LTile := TWarModelMath.MapToTile(TWarModelMath.Vec(-1, -17));
  Assert.AreEqual<Single>(-1, LTile.X);
  Assert.AreEqual<Single>(-2, LTile.Y);
end;

procedure TTestWarModelMath.DovrebbePassareDaCaselleAPixelAncheAlCentro;
var
  LCorner: TWarVec2;
  LCenter: TWarVec2;
begin
  LCorner := TWarModelMath.TileToMap(TWarModelMath.Vec(2, 3), False);
  LCenter := TWarModelMath.TileToMap(TWarModelMath.Vec(2, 3), True);
  Assert.AreEqual<Single>(32, LCorner.X);
  Assert.AreEqual<Single>(48, LCorner.Y);
  Assert.AreEqual<Single>(40, LCenter.X);
  Assert.AreEqual<Single>(56, LCenter.Y);
end;

procedure TTestWarModelMath.DovrebbeDareLaDirezioneDiUnoScarto(AX, AY, AExpected: Integer);
begin
  Assert.AreEqual<Integer>(AExpected, TWarModelMath.DirectionFromDiff(AX, AY));
end;

procedure TTestWarModelMath.DovrebbeDareLaPercentualeTroncata;
begin
  Assert.AreEqual<Integer>(33, TWarModelMath.PercentOf(1, 3));
  Assert.AreEqual<Integer>(100, TWarModelMath.PercentOf(7, 7));
  Assert.AreEqual<Integer>(0, TWarModelMath.PercentOf(0, 7));
end;

procedure TTestWarModelMath.DovrebbeDareSecondiDaiFotogrammi;
begin
  Assert.AreEqual<Single>(1, TWarModelMath.FramesToSeconds(60));
  Assert.AreEqual<Single>(0.5, TWarModelMath.FramesToSeconds(30));
end;

procedure TTestWarModelMath.DovrebbeScalareIlTempoSecondoLaVelocitaDellaMappa;
var
  LClock: TWarGameClock;
begin
  LClock := Default(TWarGameClock);
  LClock.GlobalSpeed := 1;
  LClock.GameSpeed := 2;
  Assert.AreEqual<Single>(4, TWarModelMath.ScaledTime(LClock, 4));
  LClock.GameSpeed := 4;
  Assert.AreEqual<Single>(2, TWarModelMath.ScaledTime(LClock, 4));
  LClock.GameSpeed := 0;
  Assert.AreEqual<Single>(8, TWarModelMath.ScaledTime(LClock, 4));
  LClock.GameSpeed := 2;
  LClock.GlobalSpeed := 2;
  Assert.AreEqual<Single>(2, TWarModelMath.ScaledTime(LClock, 4));
end;

end.
