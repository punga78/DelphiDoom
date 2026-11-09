{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the tires of an I3D car         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.I3dTireAnimator;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>The rotation of a tire from the distance it has run (the tire part of the old RenderGLEx)</summary>
  [TestFixture]
  [Category('models')]
  TTestModelsI3dTireAnimator = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLaRotazioneDiUnaGomma;
    [Test]
    procedure DovrebbeRiportareLaRotazioneAlPrimoGiro;
    [Test]
    procedure DovrebbeLasciareNegativaLaRotazioneNegativa;
    [Test]
    procedure DovrebbeDareZeroSeLaGommaNonHaAltezza;
    [Test]
    procedure DovrebbeDareLoStatoDelleQuattroGomme;
    [Test]
    procedure DovrebbeLasciareZeroLeGommeSenzaDistanza;
    [Test]
    procedure DovrebbeDareLoStatoVuotoAUnModelloSenzaGomme;
  end;

implementation

uses
  DelphiDoom.Models.I3d.Types, DelphiDoom.Models.I3d.TireAnimator, DelphiDoom.Models.I3d.Intf,
  DelphiDoom.Models.I3d.Factory, DelphiDoom.Tests.Models.I3dFileBuilder;

{ TTestModelsI3dTireAnimator }

procedure TTestModelsI3dTireAnimator.DovrebbeDareLaRotazioneDiUnaGomma;
begin
  // the length of the circle is 8 (the slowdown for the eye): 4 units are half a turn
  Assert.AreEqual(Single(180), TI3dTireAnimator.Rotation(4, I3D_DEFAULT_SCALE, 1, 1, 1));
  Assert.AreEqual(Single(90), TI3dTireAnimator.Rotation(2, I3D_DEFAULT_SCALE, 1, 1, 1));
end;

procedure TTestModelsI3dTireAnimator.DovrebbeRiportareLaRotazioneAlPrimoGiro;
begin
  // 2.5 turns
  Assert.AreEqual(Single(180), TI3dTireAnimator.Rotation(20, I3D_DEFAULT_SCALE, 1, 1, 1));
end;

procedure TTestModelsI3dTireAnimator.DovrebbeLasciareNegativaLaRotazioneNegativa;
begin
  Assert.AreEqual(Single(-180), TI3dTireAnimator.Rotation(-4, I3D_DEFAULT_SCALE, 1, 1, 1));
  Assert.AreEqual(Single(-900), TI3dTireAnimator.Rotation(-20, I3D_DEFAULT_SCALE, 1, 1, 1));
end;

procedure TTestModelsI3dTireAnimator.DovrebbeDareZeroSeLaGommaNonHaAltezza;
begin
  Assert.AreEqual(Single(0), TI3dTireAnimator.Rotation(100, 0, 1, 1, 1));
end;

procedure TTestModelsI3dTireAnimator.DovrebbeDareLoStatoDelleQuattroGomme;
var
  LModel: II3dModel;
  LState: TI3dTireState;
  LIndex: Integer;
begin
  LModel := TI3dFactory.CreateParser.Parse(TI3dFileBuilder.CarModel);
  LState := TI3dTireAnimator.State(LModel, [8, 16, 24, 32], 12.5, 1, 1);
  Assert.AreEqual(Single(12.5), LState.Angle);
  for LIndex := 0 to 3 do
    Assert.AreEqual(TI3dTireAnimator.Rotation(8 * (LIndex + 1), 600000, 1, 1, 3000000), LState.Rotation[LIndex]);
  Assert.IsTrue(LState.Rotation[3] > LState.Rotation[0]);
end;

procedure TTestModelsI3dTireAnimator.DovrebbeLasciareZeroLeGommeSenzaDistanza;
var
  LModel: II3dModel;
  LState: TI3dTireState;
begin
  LModel := TI3dFactory.CreateParser.Parse(TI3dFileBuilder.CarModel);
  LState := TI3dTireAnimator.State(LModel, [8], 0, 1, 1);
  Assert.IsTrue(LState.Rotation[0] > 0);
  Assert.AreEqual(Single(0), LState.Rotation[1]);
  Assert.AreEqual(Single(0), LState.Rotation[3]);
end;

procedure TTestModelsI3dTireAnimator.DovrebbeDareLoStatoVuotoAUnModelloSenzaGomme;
var
  LModel: II3dModel;
  LState: TI3dTireState;
begin
  LModel := TI3dFactory.CreateParser.Parse(TI3dFileBuilder.PlainModel);
  LState := TI3dTireAnimator.State(LModel, [8, 8, 8, 8], 33, 1, 1);
  Assert.AreEqual(Single(0), LState.Rotation[0]);
  Assert.AreEqual(Single(0), LState.Angle);
end;

end.
