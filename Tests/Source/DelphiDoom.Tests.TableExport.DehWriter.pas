{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the TableExport library - the patch writer             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TableExport.DehWriter;

interface

uses
  DUnitX.TestFramework, DelphiDoom.TableExport.Types, DelphiDoom.TableExport.Intf,
  DelphiDoom.TableExport.Profile, DelphiDoom.Tests.TableExport.Fakes;

type
  [TestFixture]
  [Category('tableexport')]
  TTestTableExportDehWriter = class(TObject)
  private
    FThings: TFakeThings;
    FThingsIntf: IExportThingSource;
    FStates: TFakeStates;
    FStatesIntf: IExportStateSource;
    FWeapons: TFakeWeapons;
    FWeaponsIntf: IExportWeaponSource;
    FSettings: IExportSettingsSource;
    FNames: IInterface;
    function Lines(AGame: TExportGame): TArray<string>;
    /// <summary>The position of the first line equal to AText, from AFrom; -1 if none</summary>
    function IndexOf(const ALines: TArray<string>; const AText: string; AFrom: Integer = 0): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestDovrebbeScrivereLIntestazione;
    [Test]
    procedure TestDovrebbeScrivereLeRigheDiUnaCosa;
    [Test]
    procedure TestDovrebbeScrivereIFlagElencatiOZero;
    [Test]
    procedure TestDovrebbeScrivereIlCommentoSoloPerLaPrimaCosa;
    [Test]
    procedure TestDovrebbeScrivereLeFrasiTraVirgolette;
    [Test]
    procedure TestDovrebbeSaltareLoStatoZeroEScrivereIlSuoNome;
    [Test]
    procedure TestDovrebbeScrivereLAzioneSoloSeLoStatoLAve;
    [Test]
    procedure TestDovrebbeScrivereLeArmiDiDoom;
    [Test]
    procedure TestDovrebbeScrivereILivelliDelleArmiDiHeretic;
    [Test]
    procedure TestDovrebbeScrivereLeClassiDelleArmiDiHexen;
    [Test]
    procedure TestDovrebbeScrivereIFlagDelleArmiDiHereticComeQuelliDiDoom;
    [Test]
    procedure TestDovrebbeScrivereLeMunizioniSoloDoveCiSono;
    [Test]
    procedure TestDovrebbeScrivereLaSezioneMiscDelGioco;
    [Test]
    procedure TestDovrebbeScrivereIParSoloDoveCiSono;
    [Test]
    procedure TestDovrebbeScrivereStringheMusicaESuoni;
    [Test]
    procedure TestDovrebbeScrivereLaFineDelFile;
    [Test]
    procedure TestDovrebbeEtichettareIlGruppoDeiProiettiliInHeretic;
    [Test]
    procedure TestDovrebbeRifiutareUnaSorgenteMancante;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.TableExport.Factory;

{ TTestTableExportDehWriter }

procedure TTestTableExportDehWriter.Setup;
var
  LThing: TExportThing;
begin
  FThings := TFakeThings.Create;
  FThingsIntf := FThings;
  FStates := TFakeStates.Create;
  FStatesIntf := FStates;
  FWeapons := TFakeWeapons.Create;
  FWeaponsIntf := FWeapons;
  FSettings := TFakeSettings.Create;
  FNames := TFakeNames.Create;
  LThing := TFakeThings.Blank('Imp');
  LThing.Numbers[tfDoomedNum] := 3001;
  LThing.Numbers[tfSpawnState] := 1;
  LThing.Numbers[tfFlags] := 6;
  LThing.Texts[ttObituary] := 'was burnt';
  FThings.Items.Add(LThing);
  FStates.AddState('NULL', 0, 0, 0);
  FStates.AddState('TROO', 0, 4, 2, 'CHASE');
  FStates.AddState('TROO', 1, 4, 1);
  FStates.Names.AddRange(['S_NULL', 'S_FIRST', 'S_SECOND']);
end;

procedure TTestTableExportDehWriter.TearDown;
begin
  FNames := nil;
  FSettings := nil;
  FWeaponsIntf := nil;
  FStatesIntf := nil;
  FThingsIntf := nil;
end;

function TTestTableExportDehWriter.Lines(AGame: TExportGame): TArray<string>;
begin
  Result := TTableExportFactory.CreateDehWriter(AGame, FThingsIntf, FStatesIntf, FWeaponsIntf, FSettings,
    FNames as IExportFlagNames, FNames as IExportLookups).Write;
end;

function TTestTableExportDehWriter.IndexOf(const ALines: TArray<string>; const AText: string;
  AFrom: Integer): Integer;
begin
  for Result := AFrom to High(ALines) do
    if ALines[Result] = AText then
      Exit;
  Result := -1;
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereLIntestazione;
var
  LLines: TArray<string>;
begin
  LLines := Lines(TExportGame.Doom);
  Assert.AreEqual('Patch File for DeHackEd', LLines[0]);
  Assert.AreEqual('# Created with Fake 1.0, built today', LLines[1]);
  Assert.AreEqual('# Command line options:', LLines[2]);
  Assert.AreEqual('# fake.exe -iwad x.wad'#13#10, LLines[3]);
  Assert.IsTrue(IndexOf(LLines, 'Doom version = 21') > 0);
  Assert.IsTrue(IndexOf(LLines, 'Patch format = 6') > 0);
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereLeRigheDiUnaCosa;
var
  LLines: TArray<string>;
  LAt: Integer;
begin
  LLines := Lines(TExportGame.Doom);
  LAt := IndexOf(LLines, 'Thing 1');
  Assert.IsTrue(LAt > 0);
  Assert.AreEqual('Name = Imp', LLines[LAt + 1]);
  Assert.AreEqual('Inheritsfrom = -1', LLines[LAt + 2]);
  Assert.AreEqual('Id # = 3001', LLines[LAt + 3]);
  Assert.AreEqual('Initial Frame = 1', LLines[LAt + 4]);
  Assert.AreEqual('', LLines[IndexOf(LLines, '# States') - 1]);
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereIFlagElencatiOZero;
var
  LLines: TArray<string>;
begin
  LLines := Lines(TExportGame.Doom);
  Assert.IsTrue(IndexOf(LLines, 'Bits = MF_SOLID, MF_SHOOTABLE') > 0);
  Assert.IsTrue(IndexOf(LLines, 'Flags_ex = 0') > 0);
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereIlCommentoSoloPerLaPrimaCosa;
var
  LLines: TArray<string>;
  LAt: Integer;
  LCount: Integer;
begin
  FThings.Items.Add(TFakeThings.Blank('Second'));
  LLines := Lines(TExportGame.Heretic);
  LCount := 0;
  for LAt := 0 to High(LLines) do
    if LLines[LAt] = '# The following fields are DelphiHeretic specific enhancements' then
      Inc(LCount);
  Assert.AreEqual(1, LCount);
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereLeFrasiTraVirgolette;
begin
  Assert.IsTrue(IndexOf(Lines(TExportGame.Doom), 'Obituary = "was burnt"') > 0);
end;

procedure TTestTableExportDehWriter.TestDovrebbeSaltareLoStatoZeroEScrivereIlSuoNome;
var
  LLines: TArray<string>;
  LAt: Integer;
begin
  LLines := Lines(TExportGame.Doom);
  Assert.AreEqual(-1, IndexOf(LLines, 'Frame 0'));
  LAt := IndexOf(LLines, 'Frame 1');
  Assert.AreEqual('# S_FIRST', LLines[LAt - 1]);
  Assert.AreEqual('Sprite Number = 0', LLines[LAt + 1]);
  Assert.AreEqual('Sprite Subnumber = 0', LLines[LAt + 2]);
  Assert.AreEqual('Duration = 4', LLines[LAt + 3]);
  Assert.AreEqual('Duration 2 = 4', LLines[LAt + 4]);
  Assert.AreEqual('Next Frame = 2', LLines[LAt + 5]);
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereLAzioneSoloSeLoStatoLAve;
var
  LLines: TArray<string>;
  LAt: Integer;
begin
  LLines := Lines(TExportGame.Doom);
  LAt := IndexOf(LLines, 'Frame 1');
  Assert.AreEqual('Codep Frame = CHASE', LLines[LAt + 6]);
  LAt := IndexOf(LLines, 'Frame 2');
  Assert.AreEqual('Unknown 1 = 0', LLines[LAt + 6]);
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereLeArmiDiDoom;
var
  LLines: TArray<string>;
  LAt: Integer;
  LWeapon: TExportWeapon;
begin
  LWeapon := Default(TExportWeapon);
  LWeapon.WeaponNo := 1;
  LWeapon.Numbers[wfAmmo] := 1;
  LWeapon.Numbers[wfUpState] := 5;
  LWeapon.Numbers[wfAmmoPerShot] := 2;
  LWeapon.Numbers[wfMbf21Bits] := 3;
  FWeapons.Items.Add(LWeapon);
  LLines := Lines(TExportGame.Doom);
  LAt := IndexOf(LLines, 'Weapon WP_PISTOL');
  Assert.IsTrue(LAt > 0);
  Assert.AreEqual('Ammo Type = AM_SHELL', LLines[LAt + 1]);
  Assert.AreEqual('Deselect Frame = 5', LLines[LAt + 2]);
  Assert.AreEqual('Ammo Per Shot = 2', LLines[LAt + 8]);
  Assert.AreEqual('Mbf21 Bits = WPF_NOTHRUST, WPF_SILENT', LLines[LAt + 9]);
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereILivelliDelleArmiDiHeretic;
var
  LLines: TArray<string>;
  LAt: Integer;
  LWeapon: TExportWeapon;
begin
  LWeapon := Default(TExportWeapon);
  LWeapon.Level := 2;
  FWeapons.Items.Add(LWeapon);
  LLines := Lines(TExportGame.Heretic);
  LAt := IndexOf(LLines, 'Weapon WP_FIST');
  Assert.AreEqual('Level = 2', LLines[LAt + 1]);
  Assert.AreEqual('Ammo Type = AM_CLIP', LLines[LAt + 2]);
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereLeClassiDelleArmiDiHexen;
var
  LLines: TArray<string>;
  LWeapon: TExportWeapon;
begin
  LWeapon := Default(TExportWeapon);
  LWeapon.PlayerClass := 1;
  FWeapons.Items.Add(LWeapon);
  LLines := Lines(TExportGame.Hexen);
  Assert.IsTrue(IndexOf(LLines, 'Weapon WP_FIST PCLASS_CLERIC') > 0);
  Assert.IsTrue(IndexOf(LLines, 'Mana Type = AM_CLIP') > 0);
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereIFlagDelleArmiDiHereticComeQuelliDiDoom;
var
  LLines: TArray<string>;
  LWeapon: TExportWeapon;
begin
  // regression: the old code of Heretic tested the bit of the level and not the ones of the flags
  LWeapon := Default(TExportWeapon);
  LWeapon.Level := 1;
  LWeapon.Numbers[wfMbf21Bits] := 2;
  FWeapons.Items.Add(LWeapon);
  LLines := Lines(TExportGame.Heretic);
  Assert.IsTrue(IndexOf(LLines, 'Mbf21 Bits = WPF_SILENT') > 0);
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereLeMunizioniSoloDoveCiSono;
var
  LLines: TArray<string>;
  LAt: Integer;
begin
  LLines := Lines(TExportGame.Doom);
  LAt := IndexOf(LLines, 'Ammo 1');
  Assert.AreEqual('Max Ammo = 200', LLines[LAt + 1]);
  Assert.AreEqual('Per Ammo = 201', LLines[LAt + 2]);
  Assert.AreEqual('', LLines[LAt + 3]);
  Assert.AreEqual(-1, IndexOf(Lines(TExportGame.Hexen), '# Ammo'));
  LLines := Lines(TExportGame.Heretic);
  LAt := IndexOf(LLines, 'Ammo 0');
  Assert.AreEqual('Max Ammo = 100', LLines[LAt + 1]);
  Assert.AreEqual('', LLines[LAt + 2]);
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereLaSezioneMiscDelGioco;
var
  LLines: TArray<string>;
  LAt: Integer;
begin
  LLines := Lines(TExportGame.Strife);
  LAt := IndexOf(LLines, 'Misc');
  Assert.AreEqual('', LLines[LAt + 1]);
  Assert.AreEqual('Max Health = 10', LLines[LAt + 2]);
  Assert.AreEqual('Blue Armor Class = 18', LLines[LAt + 10]);
  Assert.AreEqual('', LLines[LAt + 11]);
  LLines := Lines(TExportGame.Hexen);
  Assert.IsTrue(IndexOf(LLines, 'Max Mana = 14') > 0);
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereIParSoloDoveCiSono;
var
  LLines: TArray<string>;
begin
  LLines := Lines(TExportGame.Doom);
  Assert.IsTrue(IndexOf(LLines, '# Doom 1') > 0);
  Assert.IsTrue(IndexOf(LLines, 'PAR 3 9 309') > 0);
  Assert.IsTrue(IndexOf(LLines, '# Doom 2 (commercial)') > 0);
  Assert.IsTrue(IndexOf(LLines, 'PAR 32 1031') > 0);
  LLines := Lines(TExportGame.Heretic);
  Assert.IsTrue(IndexOf(LLines, '# Heretic') > 0);
  Assert.IsTrue(IndexOf(LLines, 'PAR 5 9 509') > 0);
  Assert.AreEqual(-1, IndexOf(LLines, '# Doom 2 (commercial)'));
  Assert.AreEqual(-1, IndexOf(Lines(TExportGame.Strife), '[PARS]'));
  Assert.AreEqual(-1, IndexOf(Lines(TExportGame.Hexen), '[PARS]'));
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereStringheMusicaESuoni;
var
  LLines: TArray<string>;
begin
  LLines := Lines(TExportGame.Doom);
  Assert.IsTrue(IndexOf(LLines, 'STR0 = one\ntwo') > 0);
  Assert.IsTrue(IndexOf(LLines, 'STR1 = plain') > 0);
  Assert.IsTrue(IndexOf(LLines, '1 = mus1') > 0);
  Assert.IsTrue(IndexOf(LLines, '2 = mus2   ' + '      (Map: MAP02)') < 0);
  Assert.IsTrue(IndexOf(LLines, '2 = mus2 ' + StringOfChar(' ', 6 - 4) + '(Map: MAP02)') > 0);
  Assert.IsTrue(IndexOf(LLines, '1 = snd1') > 0);
  Assert.IsTrue(IndexOf(LLines, '2 = snd2') > 0);
end;

procedure TTestTableExportDehWriter.TestDovrebbeScrivereLaFineDelFile;
var
  LLines: TArray<string>;
begin
  LLines := Lines(TExportGame.Doom);
  Assert.AreEqual(StringOfChar('#', 80), LLines[High(LLines)]);
  Assert.AreEqual('# End of file', LLines[High(LLines) - 1]);
  Assert.AreEqual(StringOfChar('#', 80), LLines[High(LLines) - 2]);
end;

procedure TTestTableExportDehWriter.TestDovrebbeEtichettareIlGruppoDeiProiettiliInHeretic;
var
  LLines: TArray<string>;
begin
  // regression: Heretic and Hexen wrote the group as "Weave Index Z"
  LLines := Lines(TExportGame.Heretic);
  Assert.IsTrue(IndexOf(LLines, 'Projectile Group = G1_0') > 0);
  Assert.AreEqual(-1, IndexOf(LLines, 'Weave Index Z = G1_0'));
  LLines := Lines(TExportGame.Hexen);
  Assert.IsTrue(IndexOf(LLines, 'Projectile Group = G1_0') > 0);
end;

procedure TTestTableExportDehWriter.TestDovrebbeRifiutareUnaSorgenteMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TTableExportFactory.CreateDehWriter(TExportGame.Doom, nil, FStatesIntf, FWeaponsIntf, FSettings,
        FNames as IExportFlagNames, FNames as IExportLookups);
    end, EArgumentNilException);
end;

end.
