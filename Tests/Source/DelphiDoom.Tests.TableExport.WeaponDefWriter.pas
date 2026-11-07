{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the TableExport library - the WEAPON writer            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TableExport.WeaponDefWriter;

interface

uses
  DUnitX.TestFramework, DelphiDoom.TableExport.Types, DelphiDoom.TableExport.Intf,
  DelphiDoom.TableExport.Profile, DelphiDoom.Tests.TableExport.Fakes;

type
  [TestFixture]
  [Category('tableexport')]
  TTestTableExportWeaponDefWriter = class(TObject)
  private
    FWeapons: TFakeWeapons;
    FWeaponsIntf: IExportWeaponSource;
    FStates: TFakeStates;
    FStatesIntf: IExportStateSource;
    FNames: IInterface;
    function Writer(AGame: TExportGame): IExportWeaponDefWriter;
    function Pistol: TExportWeapon;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestDovrebbeScrivereLArmaDiDoom;
    [Test]
    procedure TestDovrebbeScrivereIlLivelloDiHeretic;
    [Test]
    procedure TestDovrebbeScrivereLaClasseDiHexen;
    [Test]
    procedure TestDovrebbeScrivereLeMunizioniComeNumeroSeNonHannoNome;
    [Test]
    procedure TestDovrebbeScrivereLeArmiDiHexenAnchePerLaClasse;
    [Test]
    procedure TestDovrebbeRifiutareUnaSorgenteMancante;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.TableExport.Factory;

const
  EOL = #13#10;

{ TTestTableExportWeaponDefWriter }

procedure TTestTableExportWeaponDefWriter.Setup;
begin
  FWeapons := TFakeWeapons.Create;
  FWeaponsIntf := FWeapons;
  FStates := TFakeStates.Create;
  FStatesIntf := FStates;
  FStates.AddState('NULL', 0, 0, 0);
  FStates.AddState('TROO', 0, 10, 0);
  FNames := TFakeNames.Create;
end;

procedure TTestTableExportWeaponDefWriter.TearDown;
begin
  FNames := nil;
  FStatesIntf := nil;
  FWeaponsIntf := nil;
end;

function TTestTableExportWeaponDefWriter.Writer(AGame: TExportGame): IExportWeaponDefWriter;
begin
  Result := TTableExportFactory.CreateWeaponDefWriter(AGame, FWeaponsIntf, FStatesIntf,
    FNames as IExportEnumNames, FNames as IExportFlagNames);
end;

function TTestTableExportWeaponDefWriter.Pistol: TExportWeapon;
begin
  Result := Default(TExportWeapon);
  Result.WeaponNo := 1;
  Result.Numbers[wfAmmo] := 0;
  Result.Numbers[wfAmmoPerShot] := 1;
  Result.Numbers[wfMbf21Bits] := 2;
  Result.Numbers[wfUpState] := 1;
end;

procedure TTestTableExportWeaponDefWriter.TestDovrebbeScrivereLArmaDiDoom;
begin
  FWeapons.Items.Add(Pistol);
  Assert.AreEqual('// WP_PISTOL' + EOL + 'WEAPON WP_PISTOL' + EOL + '{' + EOL + '  Ammo AM_CLIP' + EOL +
    '  AmmoPerShot 1' + EOL + '  +WPF_SILENT' + EOL + '  States' + EOL + '  {' + EOL + '    Up:' + EOL +
    '    {' + EOL + '      TROO A 10' + EOL + '      Stop' + EOL + '    }' + EOL + '  }' + EOL + '}' + EOL + EOL,
    Writer(TExportGame.Doom).WriteAll);
end;

procedure TTestTableExportWeaponDefWriter.TestDovrebbeScrivereIlLivelloDiHeretic;
var
  LWeapon: TExportWeapon;
begin
  LWeapon := Pistol;
  LWeapon.Level := 2;
  FWeapons.Items.Add(LWeapon);
  Assert.IsTrue(Pos('{' + EOL + '  Level LEVEL2' + EOL + '  Ammo AM_CLIP', Writer(TExportGame.Heretic).WriteAll) > 0);
end;

procedure TTestTableExportWeaponDefWriter.TestDovrebbeScrivereLaClasseDiHexen;
var
  LWeapon: TExportWeapon;
begin
  LWeapon := Pistol;
  LWeapon.PlayerClass := 1;
  FWeapons.Items.Add(LWeapon);
  Assert.IsTrue(Pos('  PlayerClass PCLASS_CLERIC' + EOL, Writer(TExportGame.Hexen).WriteAll) > 0);
  Assert.AreEqual(0, Pos('PlayerClass', Writer(TExportGame.Doom).WriteAll));
end;

procedure TTestTableExportWeaponDefWriter.TestDovrebbeScrivereLeMunizioniComeNumeroSeNonHannoNome;
var
  LWeapon: TExportWeapon;
begin
  LWeapon := Pistol;
  LWeapon.Numbers[wfAmmo] := 9;
  FWeapons.Items.Add(LWeapon);
  Assert.IsTrue(Pos('  Ammo 9' + EOL, Writer(TExportGame.Doom).WriteAll) > 0);
end;

procedure TTestTableExportWeaponDefWriter.TestDovrebbeScrivereLeArmiDiHexenAnchePerLaClasse;
var
  LWeapon: TExportWeapon;
begin
  // regression: the old code never set the weapon of Hexen and read an undefined record
  LWeapon := Pistol;
  FWeapons.Items.Add(LWeapon);
  LWeapon.PlayerClass := 1;
  FWeapons.Items.Add(LWeapon);
  Assert.AreEqual(2, Length(Writer(TExportGame.Hexen).WriteAll.Split(['WEAPON WP_PISTOL'])) - 1);
end;

procedure TTestTableExportWeaponDefWriter.TestDovrebbeRifiutareUnaSorgenteMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TTableExportFactory.CreateWeaponDefWriter(TExportGame.Doom, nil, FStatesIntf,
        FNames as IExportEnumNames, FNames as IExportFlagNames);
    end, EArgumentNilException);
end;

end.
