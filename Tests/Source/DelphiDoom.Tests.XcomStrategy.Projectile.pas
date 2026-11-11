{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom strategy library - the projectiles of a  }
{  dogfight (CraftWeaponProjectile)                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomStrategy.Projectile;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSave.CraftWeaponProjectile;

type
  [TestFixture]
  [Category('xcom-strategy')]
  TTestXcomCraftWeaponProjectile = class(TObject)
  public
    [Test]
    procedure DovrebbeFarSvanireUnRaggioDimezzandoLoStato;
    [Test]
    procedure DovrebbeFermareUnMissileAllaGittata;
    [Test]
    procedure DovrebbeSegnareMancatoIlMissileOltreLaGittata;
    [Test]
    procedure DovrebbePartireDaZeroSeSparatoInAlto;
  end;

implementation

procedure TTestXcomCraftWeaponProjectile.DovrebbeFarSvanireUnRaggioDimezzandoLoStato;
var
  LProjectile: TXcomCraftWeaponProjectile;
  LSteps: Integer;
begin
  LProjectile := TXcomCraftWeaponProjectile.Create;
  try
    LProjectile.SetType(ptPlasmaBeam);
    Assert.AreEqual(8, LProjectile.State);
    LSteps := 0;
    while not LProjectile.ToBeRemoved do
    begin
      LProjectile.Move;
      Inc(LSteps);
    end;
    // 8 -> 4 -> 2 -> 1
    Assert.AreEqual(3, LSteps);
    Assert.IsTrue(LProjectile.Kind = pkBeam);
  finally
    LProjectile.Free;
  end;
end;

procedure TTestXcomCraftWeaponProjectile.DovrebbeFermareUnMissileAllaGittata;
var
  LProjectile: TXcomCraftWeaponProjectile;
begin
  LProjectile := TXcomCraftWeaponProjectile.Create;
  try
    LProjectile.SetType(ptCannonRound);
    LProjectile.Speed := 30;
    LProjectile.Range := 10;
    LProjectile.SetDirection(TXcomCraftWeaponProjectile.DIRECTION_UP);
    // la gittata e' 10 * 8 = 80 unita': 30, 60, poi l'ultimo passo si ferma a 80
    LProjectile.Move;
    LProjectile.Move;
    LProjectile.Move;
    Assert.AreEqual(80, LProjectile.Position);
    Assert.IsFalse(LProjectile.Missed);
  finally
    LProjectile.Free;
  end;
end;

procedure TTestXcomCraftWeaponProjectile.DovrebbeSegnareMancatoIlMissileOltreLaGittata;
var
  LProjectile: TXcomCraftWeaponProjectile;
begin
  LProjectile := TXcomCraftWeaponProjectile.Create;
  try
    LProjectile.SetType(ptStingrayMissile);
    LProjectile.Speed := 40;
    LProjectile.Range := 10;
    LProjectile.SetDirection(TXcomCraftWeaponProjectile.DIRECTION_UP);
    LProjectile.Move;
    LProjectile.Move;
    LProjectile.Move;
    // al passo dopo la gittata il missile e' mancato
    LProjectile.Move;
    Assert.IsTrue(LProjectile.Missed);
  finally
    LProjectile.Free;
  end;
end;

procedure TTestXcomCraftWeaponProjectile.DovrebbePartireDaZeroSeSparatoInAlto;
var
  LProjectile: TXcomCraftWeaponProjectile;
begin
  LProjectile := TXcomCraftWeaponProjectile.Create;
  try
    LProjectile.Position := 500;
    LProjectile.SetDirection(TXcomCraftWeaponProjectile.DIRECTION_UP);
    Assert.AreEqual(0, LProjectile.Position);
    LProjectile.Position := 500;
    LProjectile.SetDirection(TXcomCraftWeaponProjectile.DIRECTION_DOWN);
    Assert.AreEqual(500, LProjectile.Position);
  finally
    LProjectile.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomCraftWeaponProjectile);

end.
