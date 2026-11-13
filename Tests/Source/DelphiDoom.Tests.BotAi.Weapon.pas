{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the weapon AI of the bots (DUnitX)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.Weapon;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.LibVars.Table,
  DelphiDoom.BotAi.Weight.Intf, DelphiDoom.BotAi.Weapon.Intf, DelphiDoom.Tests.BotAi.Support;

type
  [TestFixture]
  [Category('BotAi')]
  TTestBotWeapon = class
  strict private
    FImport: TFakeBotImport;
    FImportRef: IBotImport;
    FFiles: TMemoryBotFiles;
    FFilesRef: IBotFileSource;
    FLibVars: TBotLibVarTable;
    FLibVarsRef: IInterface;
    FWeights: IBotWeightCache;
    FSystem: IBotWeaponSystem;
    function Printed: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAvereLeDimensioniDelleStruttureDelC;
    [Test]
    procedure DovrebbeLeggereLeArmiEIProiettili;
    [Test]
    procedure DovrebbeCopiareIlProiettileNellArma;
    [Test]
    procedure DovrebbeScrivereIlModelloDelProiettileSuFlagsEGravity;
    [Test]
    procedure DovrebbeSegnalareIlFileDelleArmiMancante;
    [Test]
    procedure DovrebbeSegnalareUnNumeroDiArmaFuoriIntervallo;
    [Test]
    procedure DovrebbeSegnalareUnProiettileNonDefinito;
    [Test]
    procedure DovrebbeSegnalareUnaDefinizioneSconosciuta;
    [Test]
    procedure DovrebbeAvvisareSeNonCiSonoArmi;
    [Test]
    procedure DovrebbeSceglierLArmaConIlPesoMigliore;
    [Test]
    procedure DovrebbeDareZeroSenzaPesiONonConfigurato;
    [Test]
    procedure DovrebbeSegnalareIPesiMancanti;
    [Test]
    procedure DovrebbeDareLeInformazioniDellArma;
    [Test]
    procedure DovrebbeSegnalareUnaArmaFuoriIntervalloEUnStatoSbagliato;
    [Test]
    procedure DovrebbeSegnalareLInfoDiUnArmaPrimaDelSetup;
    [Test]
    procedure DovrebbeAllocareFinoA64StatiEPoiDareZero;
    [Test]
    procedure DovrebbeSegnalareUnStatoNonValido;
    [Test]
    procedure DovrebbeRiportareAlPredefinitoUnMaxNegativo;
    [Test]
    procedure DovrebbeCaricareDiNuovoDopoShutdown;
    [Test]
    procedure DovrebbeDareErroreSeIPesiSonoCaricatiPrimaDelSetup;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.BotAi.LibVars.Intf, DelphiDoom.BotAi.Weapon.Types, DelphiDoom.BotAi.Weapon.Config,
  DelphiDoom.BotAi.Weapon.Factory, DelphiDoom.BotAi.Weight.Factory;

type
  /// <summary>A store of variables that answers a negative number for max_weaponinfo and max_projectileinfo</summary>
  TNegativeLibVars = class(TInterfacedObject, IBotLibVars, IBotLibVarStore)
  strict private
  public
    Names: TArray<string>;
    function GetValue(const AName: AnsiString): Single;
    function GetValueOrCreate(const AName, ADefault: AnsiString): Single;
    function GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
    function GetString(const AName: AnsiString): AnsiString;
    procedure SetText(const AName, AText: AnsiString);
    function Changed(const AName: AnsiString): Boolean;
    procedure SetNotModified(const AName: AnsiString);
  end;

const
  WEAPONS =
    'projectileinfo { name "p_a" damage 5 } ' +
    'projectileinfo { name "p_b" flags 7 gravity 2.5 model "mmm" damage 9 } ' +
    'weaponinfo { number 1 name "Alpha" projectile "p_a" weaponindex 1 numprojectiles 1 recoil {1, 2, 3} } ' +
    'weaponinfo { number 3 name "Beta" projectile "p_b" ammoamount 2 hspread 1.5 }';
  WEIGHTS =
    'weight "Alpha" { switch(1) { case 5: return 10; default: return 100; } } weight "Beta" return 50;';

{ TNegativeLibVars }

function TNegativeLibVars.GetValue(const AName: AnsiString): Single;
begin
  Result := 0;
end;

function TNegativeLibVars.GetValueOrCreate(const AName, ADefault: AnsiString): Single;
begin
  if (AName = 'max_weaponinfo') or (AName = 'max_projectileinfo') then
    Result := -5
  else
    Result := 0;
end;

function TNegativeLibVars.GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
begin
  Result := ADefault;
end;

function TNegativeLibVars.GetString(const AName: AnsiString): AnsiString;
begin
  Result := '';
end;

procedure TNegativeLibVars.SetText(const AName, AText: AnsiString);
begin
  Names := Names + [string(AName) + '=' + string(AText)];
end;

function TNegativeLibVars.Changed(const AName: AnsiString): Boolean;
begin
  Result := False;
end;

procedure TNegativeLibVars.SetNotModified(const AName: AnsiString);
begin
end;

{ TTestBotWeapon }

procedure TTestBotWeapon.Setup;
begin
  FImport := TFakeBotImport.Create;
  FImportRef := FImport;
  FFiles := TMemoryBotFiles.Create;
  FFilesRef := FFiles;
  FLibVars := TBotLibVarTable.Create;
  FLibVarsRef := FLibVars;
  FFiles.Add('botfiles/weapons.c', WEAPONS);
  FFiles.Add('botfiles/w.c', WEIGHTS);
  FWeights := TBotWeightFactory.CreateWeightCache(FImport, FFiles, FLibVars);
  FSystem := TBotWeaponFactory.CreateWeaponSystem(FImport, FFiles, FLibVars, FWeights);
end;

procedure TTestBotWeapon.TearDown;
begin
  FSystem := nil;
  FWeights := nil;
  FLibVarsRef := nil;
  FFilesRef := nil;
  FImportRef := nil;
end;

function TTestBotWeapon.Printed: string;
begin
  Result := FImport.Lines.Text;
end;

procedure TTestBotWeapon.DovrebbeAvereLeDimensioniDelleStruttureDelC;
begin
  Assert.AreEqual(208, SizeOf(TBotProjectileInfo));
  Assert.AreEqual(552, SizeOf(TBotWeaponInfo));
end;

procedure TTestBotWeapon.DovrebbeLeggereLeArmiEIProiettili;
var
  LConfig: TBotWeaponConfig;
begin
  Assert.AreEqual(BLERR_NOERROR, FSystem.Setup);
  LConfig := FSystem.Config;
  Assert.AreEqual(32, LConfig.NumWeapons);
  Assert.AreEqual(2, LConfig.NumProjectiles);
  Assert.AreEqual(1, LConfig.Weapons[1].Valid);
  Assert.AreEqual(0, LConfig.Weapons[2].Valid);
  Assert.AreEqual('Alpha', string(BotFieldText(LConfig.Weapons[1].Name)));
  Assert.AreEqual(Double(3.0), Double(LConfig.Weapons[1].Recoil[2]));
  Assert.AreEqual(Double(1.5), Double(LConfig.Weapons[3].HorizontalSpread));
  Assert.AreEqual(2, LConfig.Weapons[3].AmmoAmount);
  Assert.Contains(Printed, 'loaded weapons.c');
end;

procedure TTestBotWeapon.DovrebbeCopiareIlProiettileNellArma;
begin
  FSystem.Setup;
  Assert.AreEqual('p_a', string(BotFieldText(FSystem.Config.Weapons[1].Proj.Name)));
  Assert.AreEqual(5, FSystem.Config.Weapons[1].Proj.Damage);
  Assert.AreEqual('p_b', string(BotFieldText(FSystem.Config.Weapons[3].Proj.Name)));
end;

procedure TTestBotWeapon.DovrebbeScrivereIlModelloDelProiettileSuFlagsEGravity;
begin
  FSystem.Setup;
  // the model is read at the offset of the weapon structure (88): 8 bytes into the model of the projectile,
  // so its zeros cover flags and gravity, which were read before it
  Assert.AreEqual('', string(BotFieldText(FSystem.Config.Projectiles[1].Model)));
  Assert.AreEqual(0, FSystem.Config.Projectiles[1].Flags);
  Assert.AreEqual(Double(0.0), Double(FSystem.Config.Projectiles[1].Gravity));
  Assert.AreEqual(9, FSystem.Config.Projectiles[1].Damage);
end;

procedure TTestBotWeapon.DovrebbeSegnalareIlFileDelleArmiMancante;
begin
  FLibVars.SetText('weaponconfig', 'nothing.c');
  Assert.AreEqual(BLERR_CANNOTLOADWEAPONCONFIG, FSystem.Setup);
  Assert.Contains(Printed, 'counldn''t load nothing.c');
  Assert.Contains(Printed, 'couldn''t load the weapon config');
  Assert.IsNull(FSystem.Config);
end;

procedure TTestBotWeapon.DovrebbeSegnalareUnNumeroDiArmaFuoriIntervallo;
begin
  FFiles.Add('botfiles/weapons.c', 'projectileinfo { name "p" } weaponinfo { number 32 name "x" projectile "p" }');
  Assert.AreEqual(BLERR_CANNOTLOADWEAPONCONFIG, FSystem.Setup);
  Assert.Contains(Printed, 'weapon info number 32 out of range in weapons.c');
end;

procedure TTestBotWeapon.DovrebbeSegnalareUnProiettileNonDefinito;
begin
  FFiles.Add('botfiles/weapons.c', 'weaponinfo { number 1 name "x" projectile "q" }');
  Assert.AreEqual(BLERR_CANNOTLOADWEAPONCONFIG, FSystem.Setup);
  Assert.Contains(Printed, 'weapon x uses undefined projectile in weapons.c');
  FFiles.Add('botfiles/weapons.c', 'weaponinfo { number 1 projectile "q" }');
  FSystem.Setup;
  Assert.Contains(Printed, 'weapon 1 has no name in weapons.c');
  FFiles.Add('botfiles/weapons.c', 'weaponinfo { number 1 name "x" }');
  FSystem.Setup;
  Assert.Contains(Printed, 'weapon x has no projectile in weapons.c');
end;

procedure TTestBotWeapon.DovrebbeSegnalareUnaDefinizioneSconosciuta;
begin
  FFiles.Add('botfiles/weapons.c', 'foo');
  Assert.AreEqual(BLERR_CANNOTLOADWEAPONCONFIG, FSystem.Setup);
  Assert.Contains(Printed, 'unknown definition foo in weapons.c');
  FLibVars.SetText('max_projectileinfo', '1');
  FFiles.Add('botfiles/weapons.c', 'projectileinfo { name "a" } projectileinfo { name "b" }');
  FSystem.Setup;
  Assert.Contains(Printed, 'more than 1 projectiles defined in weapons.c');
end;

procedure TTestBotWeapon.DovrebbeAvvisareSeNonCiSonoArmi;
begin
  FLibVars.SetText('max_weaponinfo', '0');
  FFiles.Add('botfiles/weapons.c', '// nothing');
  Assert.AreEqual(BLERR_NOERROR, FSystem.Setup);
  Assert.Contains(Printed, 'no weapon info loaded');
end;

procedure TTestBotWeapon.DovrebbeSceglierLArmaConIlPesoMigliore;
var
  LHandle: Integer;
begin
  FSystem.Setup;
  LHandle := FSystem.AllocWeaponState;
  Assert.AreEqual(BLERR_NOERROR, FSystem.LoadWeaponWeights(LHandle, 'w.c'));
  // with 0 Alpha weighs 10 and Beta 50; with 5 the next case counts (the scale is 0) and Alpha weighs 100
  Assert.AreEqual(1, FSystem.ChooseBestFightWeapon(LHandle, [0, 5]));
  Assert.AreEqual(3, FSystem.ChooseBestFightWeapon(LHandle, [0, 0]));
  FSystem.ResetWeaponState(LHandle);
  Assert.AreEqual(3, FSystem.ChooseBestFightWeapon(LHandle, [0, 0]));
end;

procedure TTestBotWeapon.DovrebbeDareZeroSenzaPesiONonConfigurato;
var
  LHandle: Integer;
begin
  LHandle := FSystem.AllocWeaponState;
  Assert.AreEqual(0, FSystem.ChooseBestFightWeapon(LHandle, [0, 0]));
  FSystem.Setup;
  Assert.AreEqual(0, FSystem.ChooseBestFightWeapon(LHandle, [0, 0]));
  Assert.AreEqual(0, FSystem.ChooseBestFightWeapon(9, [0, 0]));
end;

procedure TTestBotWeapon.DovrebbeSegnalareIPesiMancanti;
var
  LHandle: Integer;
begin
  FSystem.Setup;
  LHandle := FSystem.AllocWeaponState;
  Assert.AreEqual(BLERR_CANNOTLOADWEAPONWEIGHTS, FSystem.LoadWeaponWeights(LHandle, 'nothing.c'));
  Assert.Contains(Printed, 'couldn''t load weapon config nothing.c');
  Assert.AreEqual(BLERR_CANNOTLOADWEAPONWEIGHTS, FSystem.LoadWeaponWeights(9, 'w.c'));
end;

procedure TTestBotWeapon.DovrebbeDareLeInformazioniDellArma;
var
  LHandle: Integer;
  LInfo: TBotWeaponInfo;
begin
  FSystem.Setup;
  LHandle := FSystem.AllocWeaponState;
  Assert.IsTrue(FSystem.GetWeaponInfo(LHandle, 1, LInfo));
  Assert.AreEqual('Alpha', string(BotFieldText(LInfo.Name)));
  Assert.AreEqual(5, LInfo.Proj.Damage);
end;

procedure TTestBotWeapon.DovrebbeSegnalareUnaArmaFuoriIntervalloEUnStatoSbagliato;
var
  LHandle: Integer;
  LInfo: TBotWeaponInfo;
begin
  FSystem.Setup;
  LHandle := FSystem.AllocWeaponState;
  Assert.IsFalse(FSystem.GetWeaponInfo(LHandle, 0, LInfo));
  Assert.IsFalse(FSystem.GetWeaponInfo(LHandle, 33, LInfo));
  Assert.Contains(Printed, 'weapon number out of range');
  Assert.AreEqual(0, LInfo.Valid);
  Assert.IsFalse(FSystem.GetWeaponInfo(9, 1, LInfo));
  Assert.Contains(Printed, 'invalid move state 9');
end;

procedure TTestBotWeapon.DovrebbeSegnalareLInfoDiUnArmaPrimaDelSetup;
var
  LInfo: TBotWeaponInfo;
begin
  Assert.IsFalse(FSystem.GetWeaponInfo(FSystem.AllocWeaponState, 1, LInfo));
  Assert.Contains(Printed, 'weapon number out of range');
end;

procedure TTestBotWeapon.DovrebbeAllocareFinoA64StatiEPoiDareZero;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 64 do
    Assert.AreEqual(LIndex, FSystem.AllocWeaponState);
  Assert.AreEqual(0, FSystem.AllocWeaponState);
  FSystem.FreeWeaponState(10);
  Assert.AreEqual(10, FSystem.AllocWeaponState);
end;

procedure TTestBotWeapon.DovrebbeSegnalareUnStatoNonValido;
begin
  FSystem.FreeWeaponState(0);
  Assert.Contains(Printed, 'move state handle 0 out of range');
  FSystem.FreeWeaponState(5);
  Assert.Contains(Printed, 'invalid move state 5');
  FSystem.ResetWeaponState(65);
  Assert.Contains(Printed, 'move state handle 65 out of range');
end;

procedure TTestBotWeapon.DovrebbeRiportareAlPredefinitoUnMaxNegativo;
var
  LVars: TNegativeLibVars;
  LRef: IBotLibVarStore;
  LSystem: IBotWeaponSystem;
begin
  LVars := TNegativeLibVars.Create;
  LRef := LVars;
  LSystem := TBotWeaponFactory.CreateWeaponSystem(FImport, FFiles, LRef, FWeights);
  Assert.AreEqual(BLERR_NOERROR, LSystem.Setup);
  Assert.AreEqual(32, LSystem.Config.NumWeapons);
  Assert.Contains(Printed, 'max_weaponinfo = -5');
  Assert.Contains(Printed, 'max_projectileinfo = -5');
  Assert.AreEqual(2, Integer(Length(LVars.Names)));
  Assert.AreEqual('max_weaponinfo=32', LVars.Names[0]);
end;

procedure TTestBotWeapon.DovrebbeCaricareDiNuovoDopoShutdown;
var
  LHandle: Integer;
begin
  FSystem.Setup;
  LHandle := FSystem.AllocWeaponState;
  FSystem.LoadWeaponWeights(LHandle, 'w.c');
  FSystem.Shutdown;
  Assert.IsNull(FSystem.Config);
  // the states are freed too
  Assert.AreEqual(1, FSystem.AllocWeaponState);
  Assert.AreEqual(BLERR_NOERROR, FSystem.Setup);
end;

procedure TTestBotWeapon.DovrebbeDareErroreSeIPesiSonoCaricatiPrimaDelSetup;
var
  LHandle: Integer;
begin
  LHandle := FSystem.AllocWeaponState;
  Assert.AreEqual(BLERR_CANNOTLOADWEAPONCONFIG, FSystem.LoadWeaponWeights(LHandle, 'w.c'));
  FSystem.Setup;
  Assert.AreEqual(0, FSystem.ChooseBestFightWeapon(LHandle, [0, 0]));
end;

end.
