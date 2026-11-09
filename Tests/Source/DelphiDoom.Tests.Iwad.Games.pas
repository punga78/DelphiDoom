{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the IWAD library - the profiles of the games            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Iwad.Games;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Iwad.Types, DelphiDoom.Iwad.Intf,
  DelphiDoom.Iwad.Games, DelphiDoom.Iwad.Profile;

type
  [TestFixture]
  [Category('iwad')]
  TTestIwadGames = class(TObject)
  strict private
    function FindEntry(const AProfile: IIwadProfile; const AFileName: string): TIwadEntry;
  public
    [Test]
    procedure DovrebbeDareIlNomeDiOgniGioco;
    [Test]
    procedure DovrebbeRiconoscereIlGiocoDalNomeSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeDareIlProfiloDiRadixConIlFileDeiDati;
    [Test]
    procedure DovrebbeDareFalsoPerUnNomeSconosciuto;
    [Test]
    procedure DovrebbeDareIlProfiloDiDoomConGliIwadNellOrdineDelVecchioCodice;
    [Test]
    procedure DovrebbeSegnareLeEdizioniBfgComeNonCercabiliNelleAltreCartelle;
    [Test]
    procedure DovrebbeSegnareIlDoomIIFrancese;
    [Test]
    procedure DovrebbeUsareLaFaseDirettaSoloInDoom;
    [Test]
    procedure DovrebbeDareLeVariabiliDiHereticEDelloStandard;
    [Test]
    procedure DovrebbeDareLeApplicazioniSteamDiOgniGioco;
    [Test]
    procedure DovrebbeDareLaRegolaDiHexenPerLEspansione;
    [Test]
    procedure DovrebbeDareLeVociDiStrifeConLeVoci;
    [Test]
    procedure DovrebbeDareEccezioneSeUnProfiloNonHaIwad;
  end;

implementation

{ TTestIwadGames }

function TTestIwadGames.FindEntry(const AProfile: IIwadProfile;
  const AFileName: string): TIwadEntry;
var
  LEntry: TIwadEntry;
begin
  for LEntry in AProfile.Entries do
    if LEntry.FileName = AFileName then
      Exit(LEntry);
  raise EIwadException.CreateFmt('Entry %s not found', [AFileName]);
end;

procedure TTestIwadGames.DovrebbeDareIlNomeDiOgniGioco;
begin
  Assert.AreEqual('DOOM', TIwadGames.NameOf(igDoom));
  Assert.AreEqual('HERETIC', TIwadGames.NameOf(igHeretic));
  Assert.AreEqual('HEXEN', TIwadGames.NameOf(igHexen));
  Assert.AreEqual('STRIFE', TIwadGames.NameOf(igStrife));
  Assert.AreEqual('STRIFE', TIwadGames.CreateProfile(igStrife).GameName);
end;

procedure TTestIwadGames.DovrebbeRiconoscereIlGiocoDalNomeSenzaDistinguereLeMaiuscole;
var
  LGame: TIwadGame;
begin
  Assert.IsTrue(TIwadGames.TryFromName('hexen', LGame));
  Assert.IsTrue(LGame = igHexen);
  Assert.IsTrue(TIwadGames.TryFromName('Heretic', LGame));
  Assert.IsTrue(LGame = igHeretic);
end;

procedure TTestIwadGames.DovrebbeDareIlProfiloDiRadixConIlFileDeiDati;
var
  LGame: TIwadGame;
  LProfile: IIwadProfile;
begin
  Assert.IsTrue(TIwadGames.TryFromName('Radix', LGame));
  Assert.IsTrue(LGame = igRadix);
  LProfile := TIwadGames.CreateProfile(igRadix);
  Assert.AreEqual('RADIX', LProfile.GameName);
  Assert.AreEqual('radix.dat', LProfile.Entries[0].FileName);
  Assert.AreEqual('RADIXWADDIR', LProfile.DirectoryVariables[0]);
end;

procedure TTestIwadGames.DovrebbeDareFalsoPerUnNomeSconosciuto;
var
  LGame: TIwadGame;
begin
  Assert.IsFalse(TIwadGames.TryFromName('QUAKE', LGame));
  Assert.IsFalse(TIwadGames.TryFromName('', LGame));
end;

procedure TTestIwadGames.DovrebbeDareIlProfiloDiDoomConGliIwadNellOrdineDelVecchioCodice;
var
  LEntries: TArray<TIwadEntry>;
  LExpected: TArray<string>;
  LIndex: Integer;
begin
  LEntries := TIwadGames.CreateProfile(igDoom).Entries;
  LExpected := TArray<string>.Create('doom2bfg.wad', 'doom2f.wad', 'doom2.wad', 'plutonia.wad',
    'tnt.wad', 'doombfg.wad', 'doomu.wad', 'doom.wad', 'doom1.wad');
  Assert.AreEqual(Integer(Length(LExpected)), Integer(Length(LEntries)));
  for LIndex := 0 to High(LExpected) do
    Assert.AreEqual(LExpected[LIndex], LEntries[LIndex].FileName);
  Assert.IsTrue(FindEntry(TIwadGames.CreateProfile(igDoom), 'doomu.wad').Mode = igmIndetermined);
  Assert.IsTrue(FindEntry(TIwadGames.CreateProfile(igDoom), 'doom1.wad').Mode = igmShareware);
  Assert.IsTrue(FindEntry(TIwadGames.CreateProfile(igDoom), 'tnt.wad').Mission = imsTnt);
  Assert.IsTrue(FindEntry(TIwadGames.CreateProfile(igDoom), 'plutonia.wad').Mission = imsPlutonia);
end;

procedure TTestIwadGames.DovrebbeSegnareLeEdizioniBfgComeNonCercabiliNelleAltreCartelle;
var
  LProfile: IIwadProfile;
begin
  LProfile := TIwadGames.CreateProfile(igDoom);
  Assert.IsFalse(FindEntry(LProfile, 'doom2bfg.wad').Searchable);
  Assert.IsTrue(FindEntry(LProfile, 'doom2bfg.wad').IsBfg2);
  Assert.IsFalse(FindEntry(LProfile, 'doombfg.wad').Searchable);
  Assert.IsTrue(FindEntry(LProfile, 'doom2.wad').Searchable);
end;

procedure TTestIwadGames.DovrebbeSegnareIlDoomIIFrancese;
var
  LProfile: IIwadProfile;
begin
  LProfile := TIwadGames.CreateProfile(igDoom);
  Assert.IsTrue(FindEntry(LProfile, 'doom2f.wad').IsFrench);
  Assert.IsFalse(FindEntry(LProfile, 'doom2.wad').IsFrench);
end;

procedure TTestIwadGames.DovrebbeUsareLaFaseDirettaSoloInDoom;
begin
  Assert.AreEqual('DOOMWADDIR', TIwadGames.CreateProfile(igDoom).DirectPhaseVariable);
  Assert.AreEqual('', TIwadGames.CreateProfile(igHeretic).DirectPhaseVariable);
  Assert.AreEqual('', TIwadGames.CreateProfile(igHexen).DirectPhaseVariable);
  Assert.AreEqual('', TIwadGames.CreateProfile(igStrife).DirectPhaseVariable);
end;

procedure TTestIwadGames.DovrebbeDareLeVariabiliDiHereticEDelloStandard;
var
  LProfile: IIwadProfile;
begin
  LProfile := TIwadGames.CreateProfile(igHeretic);
  Assert.AreEqual(2, Integer(Length(LProfile.DirectoryVariables)));
  Assert.AreEqual('HERETICWADDIR', LProfile.DirectoryVariables[0]);
  Assert.AreEqual('DOOMWADDIR', LProfile.DirectoryVariables[1]);
  Assert.AreEqual('HERETICWADPATH', LProfile.PathVariables[0]);
  Assert.AreEqual('DOOMWADPATH', LProfile.PathVariables[1]);
  Assert.AreEqual(1, Integer(Length(TIwadGames.CreateProfile(igDoom).DirectoryVariables)));
end;

procedure TTestIwadGames.DovrebbeDareLeApplicazioniSteamDiOgniGioco;
begin
  Assert.AreEqual(3, Integer(Length(TIwadGames.CreateProfile(igDoom).SteamApplications)));
  Assert.AreEqual(2280, TIwadGames.CreateProfile(igDoom).SteamApplications[0]);
  Assert.AreEqual(2390, TIwadGames.CreateProfile(igHeretic).SteamApplications[0]);
  Assert.AreEqual(2360, TIwadGames.CreateProfile(igHexen).SteamApplications[0]);
  Assert.AreEqual(2370, TIwadGames.CreateProfile(igHexen).SteamApplications[1]);
  Assert.AreEqual(317040, TIwadGames.CreateProfile(igStrife).SteamApplications[0]);
end;

procedure TTestIwadGames.DovrebbeDareLaRegolaDiHexenPerLEspansione;
var
  LRules: TArray<TIwadCustomRule>;
begin
  LRules := TIwadGames.CreateProfile(igHexen).CustomRules;
  Assert.AreEqual(1, Integer(Length(LRules)));
  Assert.AreEqual('HEXDD.WAD', LRules[0].Trigger);
  Assert.IsTrue(LRules[0].Kind = icrPrerequisite);
  Assert.AreEqual('hexen.wad', LRules[0].FileName);
end;

procedure TTestIwadGames.DovrebbeDareLeVociDiStrifeConLeVoci;
var
  LProfile: IIwadProfile;
begin
  LProfile := TIwadGames.CreateProfile(igStrife);
  Assert.AreEqual('voices.wad', FindEntry(LProfile, 'strife1.wad').CompanionFileName);
  Assert.AreEqual('', FindEntry(LProfile, 'strife0.wad').CompanionFileName);
  Assert.IsTrue(LProfile.CustomRules[0].Kind = icrCompanion);
  Assert.AreEqual('STRIFE1.WAD', LProfile.CustomRules[0].Trigger);
end;

procedure TTestIwadGames.DovrebbeDareEccezioneSeUnProfiloNonHaIwad;
begin
  Assert.WillRaise(
    procedure
    begin
      TIwadProfile.Create('X', nil, nil, nil, nil, nil, '');
    end, EIwadException);
end;

end.

