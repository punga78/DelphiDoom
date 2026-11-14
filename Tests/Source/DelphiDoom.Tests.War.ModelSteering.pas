{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the velocity of a free unit          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelSteering;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Model.Types;

type
  [TestFixture]
  [Category('war')]
  TTestWarStraightSteering = class(TObject)
  public
    [Test]
    procedure DovrebbeLasciareUnaVelocitaCheNonSuperaIlMassimo;
    [Test]
    procedure DovrebbeLimitareUnaVelocitaTroppoGrande;
    [Test]
    procedure DovrebbeDareZeroPerUnaVelocitaNulla;
  end;


implementation

uses
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.StraightSteering;

{ TTestWarStraightSteering }

procedure TTestWarStraightSteering.DovrebbeLasciareUnaVelocitaCheNonSuperaIlMassimo;
var
  LVelocity: TWarVec2;
begin
  LVelocity := TWarStraightSteering.NewVelocity(TWarModelMath.Vec(3, 4), 10);
  Assert.AreEqual<Single>(3, LVelocity.X);
  Assert.AreEqual<Single>(4, LVelocity.Y);
end;

procedure TTestWarStraightSteering.DovrebbeLimitareUnaVelocitaTroppoGrande;
var
  LVelocity: TWarVec2;
begin
  LVelocity := TWarStraightSteering.NewVelocity(TWarModelMath.Vec(30, 40), 10);
  Assert.IsTrue(Abs(LVelocity.X - 6) < 0.001);
  Assert.IsTrue(Abs(LVelocity.Y - 8) < 0.001);
  // along an axis the ring has a candidate that is exactly the preferred direction
  LVelocity := TWarStraightSteering.NewVelocity(TWarModelMath.Vec(100, 0), 10);
  Assert.IsTrue(Abs(LVelocity.X - 10) < 0.001);
  Assert.IsTrue(Abs(LVelocity.Y) < 0.001);
end;

procedure TTestWarStraightSteering.DovrebbeDareZeroPerUnaVelocitaNulla;
var
  LVelocity: TWarVec2;
begin
  LVelocity := TWarStraightSteering.NewVelocity(TWarModelMath.Vec(0, 0), 10);
  Assert.AreEqual<Single>(0, LVelocity.X);
  Assert.AreEqual<Single>(0, LVelocity.Y);
end;


end.