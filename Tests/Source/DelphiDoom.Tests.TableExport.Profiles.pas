{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the TableExport library - the profiles of the games    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TableExport.Profiles;

interface

uses
  DUnitX.TestFramework, DelphiDoom.TableExport.Profile, DelphiDoom.TableExport.Profiles;

type
  [TestFixture]
  [Category('tableexport')]
  TTestTableExportProfiles = class(TObject)
  private
    function HasToken(const ALines: TArray<TExportLine>; const AToken: string): Boolean;
    function HasPascal(const ALines: TArray<TExportPascalLine>; const AName: string): Boolean;
  public
    [Test]
    procedure TestDovrebbeNominareIGiochi;
    [Test]
    procedure TestDovrebbeIniziareOgniCosaConIlNome;
    [Test]
    procedure TestDovrebbeAvereIFlags2SoloInHereticEHexen;
    [Test]
    procedure TestDovrebbeAvereIlSecondoNomeSoloInStrife;
    [Test]
    procedure TestDovrebbeAvereLeMunizioniDiOgniGioco;
    [Test]
    procedure TestDovrebbeAvereLeRigheMiscDiOgniGioco;
    [Test]
    procedure TestDovrebbeAvereIParSoloInDoomEHeretic;
    [Test]
    procedure TestDovrebbeAvereLaClasseNellIntestazioneDelleArmiSoloInHexen;
    [Test]
    procedure TestDovrebbeAvereLaManaAlPostoDelleMunizioniInHexen;
    [Test]
    procedure TestDovrebbeAvereIlLivelloDelleArmiSoloInHeretic;
    [Test]
    procedure TestDovrebbeAvereIlGruppoDeiProiettiliConLaSuaEtichetta;
    [Test]
    procedure TestDovrebbeAvereLeStesseRigheDegliStatiInOgniGioco;
    [Test]
    procedure TestDovrebbeAvereIlCommentoDelGioco;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.TableExport.Types;

{ TTestTableExportProfiles }

function TTestTableExportProfiles.HasToken(const ALines: TArray<TExportLine>; const AToken: string): Boolean;
var
  LLine: TExportLine;
begin
  for LLine in ALines do
    if LLine.Token = AToken then
      Exit(True);
  Result := False;
end;

function TTestTableExportProfiles.HasPascal(const ALines: TArray<TExportPascalLine>;
  const AName: string): Boolean;
var
  LLine: TExportPascalLine;
begin
  for LLine in ALines do
    if LLine.Name = AName then
      Exit(True);
  Result := False;
end;

procedure TTestTableExportProfiles.TestDovrebbeNominareIGiochi;
begin
  Assert.AreEqual('DOOM', TExportProfiles.NameOf(TExportGame.Doom));
  Assert.AreEqual('HERETIC', TExportProfiles.NameOf(TExportGame.Heretic));
  Assert.AreEqual('HEXEN', TExportProfiles.NameOf(TExportGame.Hexen));
  Assert.AreEqual('STRIFE', TExportProfiles.NameOf(TExportGame.Strife));
end;

procedure TTestTableExportProfiles.TestDovrebbeIniziareOgniCosaConIlNome;
var
  LGame: TExportGame;
begin
  for LGame := Low(TExportGame) to High(TExportGame) do
  begin
    Assert.AreEqual('NAME', TExportProfiles.ForGame(LGame).ThingLines[0].Token);
    Assert.AreEqual('INHERITSFROM', TExportProfiles.ForGame(LGame).ThingLines[1].Token);
  end;
end;

procedure TTestTableExportProfiles.TestDovrebbeAvereIFlags2SoloInHereticEHexen;
begin
  Assert.IsFalse(HasToken(TExportProfiles.ForGame(TExportGame.Doom).ThingLines, 'BITS2'));
  Assert.IsTrue(HasToken(TExportProfiles.ForGame(TExportGame.Heretic).ThingLines, 'BITS2'));
  Assert.IsTrue(HasToken(TExportProfiles.ForGame(TExportGame.Hexen).ThingLines, 'BITS2'));
  Assert.IsFalse(HasToken(TExportProfiles.ForGame(TExportGame.Strife).ThingLines, 'BITS2'));
  Assert.IsFalse(HasPascal(TExportProfiles.ForGame(TExportGame.Doom).PascalThingLines, 'flags2'));
  Assert.IsTrue(HasPascal(TExportProfiles.ForGame(TExportGame.Hexen).PascalThingLines, 'flags2'));
end;

procedure TTestTableExportProfiles.TestDovrebbeAvereIlSecondoNomeSoloInStrife;
var
  LGame: TExportGame;
begin
  for LGame := Low(TExportGame) to High(TExportGame) do
  begin
    Assert.AreEqual(LGame = TExportGame.Strife, HasPascal(TExportProfiles.ForGame(LGame).PascalThingLines, 'name2'));
    Assert.AreEqual(LGame = TExportGame.Strife, HasToken(TExportProfiles.ForGame(LGame).ThingLines, 'NAME2'));
  end;
end;

procedure TTestTableExportProfiles.TestDovrebbeAvereLeMunizioniDiOgniGioco;
begin
  Assert.AreEqual(2, Length(TExportProfiles.ForGame(TExportGame.Doom).AmmoLines));
  Assert.AreEqual(1, Length(TExportProfiles.ForGame(TExportGame.Heretic).AmmoLines));
  Assert.AreEqual(0, Length(TExportProfiles.ForGame(TExportGame.Hexen).AmmoLines));
  Assert.AreEqual(2, Length(TExportProfiles.ForGame(TExportGame.Strife).AmmoLines));
end;

procedure TTestTableExportProfiles.TestDovrebbeAvereLeRigheMiscDiOgniGioco;
begin
  Assert.AreEqual(16, Length(TExportProfiles.ForGame(TExportGame.Doom).MiscLines));
  Assert.AreEqual(11, Length(TExportProfiles.ForGame(TExportGame.Heretic).MiscLines));
  Assert.AreEqual(5, Length(TExportProfiles.ForGame(TExportGame.Hexen).MiscLines));
  Assert.AreEqual(9, Length(TExportProfiles.ForGame(TExportGame.Strife).MiscLines));
  Assert.AreEqual(4, TExportProfiles.ForGame(TExportGame.Hexen).MiscLines[4].Index);
end;

procedure TTestTableExportProfiles.TestDovrebbeAvereIParSoloInDoomEHeretic;
begin
  Assert.AreEqual(3, TExportProfiles.ForGame(TExportGame.Doom).ParEpisodes);
  Assert.AreEqual(32, TExportProfiles.ForGame(TExportGame.Doom).ParCommercialMaps);
  Assert.AreEqual(5, TExportProfiles.ForGame(TExportGame.Heretic).ParEpisodes);
  Assert.AreEqual(0, TExportProfiles.ForGame(TExportGame.Heretic).ParCommercialMaps);
  Assert.AreEqual(0, TExportProfiles.ForGame(TExportGame.Hexen).ParEpisodes);
  Assert.AreEqual(0, TExportProfiles.ForGame(TExportGame.Strife).ParEpisodes);
end;

procedure TTestTableExportProfiles.TestDovrebbeAvereLaClasseNellIntestazioneDelleArmiSoloInHexen;
begin
  Assert.IsTrue(TExportProfiles.ForGame(TExportGame.Hexen).WeaponHeaderHasClass);
  Assert.IsFalse(TExportProfiles.ForGame(TExportGame.Doom).WeaponHeaderHasClass);
  Assert.IsFalse(TExportProfiles.ForGame(TExportGame.Heretic).WeaponHeaderHasClass);
end;

procedure TTestTableExportProfiles.TestDovrebbeAvereLaManaAlPostoDelleMunizioniInHexen;
begin
  Assert.IsTrue(HasToken(TExportProfiles.ForGame(TExportGame.Hexen).WeaponLines, 'MANA TYPE'));
  Assert.IsFalse(HasToken(TExportProfiles.ForGame(TExportGame.Hexen).WeaponLines, 'AMMO TYPE'));
  Assert.IsTrue(HasToken(TExportProfiles.ForGame(TExportGame.Doom).WeaponLines, 'AMMO TYPE'));
end;

procedure TTestTableExportProfiles.TestDovrebbeAvereIlLivelloDelleArmiSoloInHeretic;
begin
  Assert.IsTrue(HasToken(TExportProfiles.ForGame(TExportGame.Heretic).WeaponLines, 'LEVEL'));
  Assert.IsFalse(HasToken(TExportProfiles.ForGame(TExportGame.Doom).WeaponLines, 'LEVEL'));
  Assert.IsFalse(HasToken(TExportProfiles.ForGame(TExportGame.Hexen).WeaponLines, 'LEVEL'));
end;

procedure TTestTableExportProfiles.TestDovrebbeAvereIlGruppoDeiProiettiliConLaSuaEtichetta;
var
  LGame: TExportGame;
  LLine: TExportLine;
  LFound: Boolean;
begin
  for LGame := Low(TExportGame) to High(TExportGame) do
  begin
    LFound := False;
    for LLine in TExportProfiles.ForGame(LGame).ThingLines do
      if (LLine.Kind = lkGroup) and (LLine.Group = egProjectile) then
      begin
        LFound := True;
        Assert.AreEqual('PROJECTILE GROUP', LLine.Token);
      end;
    Assert.IsTrue(LFound);
  end;
end;

procedure TTestTableExportProfiles.TestDovrebbeAvereLeStesseRigheDegliStatiInOgniGioco;
var
  LGame: TExportGame;
begin
  for LGame := Low(TExportGame) to High(TExportGame) do
  begin
    Assert.AreEqual(11, Length(TExportProfiles.ForGame(LGame).StateLines));
    Assert.AreEqual(9, Length(TExportProfiles.ForGame(LGame).PascalStateLines));
  end;
end;

procedure TTestTableExportProfiles.TestDovrebbeAvereIlCommentoDelGioco;
begin
  Assert.IsTrue(HasToken(TExportProfiles.ForGame(TExportGame.Strife).StateLines,
    '# Flags_ex is DelphiStrife specific and declares transparency and light effects'));
  Assert.IsTrue(HasToken(TExportProfiles.ForGame(TExportGame.Doom).ThingLines,
    '# The following fields are DelphiDoom specific enhancements'));
end;

end.
