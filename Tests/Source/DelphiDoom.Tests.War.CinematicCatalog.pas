{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the list of the animations of Libs\War                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.CinematicCatalog;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Cinematic.Intf;

type
  [TestFixture]
  [Category('war')]
  TTestWarCinematicCatalog = class
  strict private
    FCatalog: IWarCinematicCatalog;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeAvereLeTrentanoveAnimazioniDiCinematicsTxt;
    [Test]
    procedure DovrebbeAvereNomiTuttiDiversi;
    [Test]
    procedure DovrebbeTrovareUnaAnimazioneSenzaDistinguereMaiuscole;
    [Test]
    procedure DovrebbeNonTrovareUnaAnimazioneCheNonCe;
    [Test]
    procedure DovrebbeSegnareIlCicloSoloDoveCinematicsTxtDiceLoop;
    [Test]
    procedure DovrebbeDareIlSuonoDellaPortaAllaPortaDellaGrotta;
    [Test]
    procedure DovrebbeDareUnSuonoDiVittoriaESconfittaPerLaRazzaDelGiocatore;
    [Test]
    procedure DovrebbeDareIFinaliDiOgniRazza;
    [Test]
    procedure DovrebbeLasciareSenzaSuonoLeAnimazioniDoveIlNomeNonLoDice;
    [Test]
    procedure DovrebbeDareUnaVoceSoloAnimazioniConUnSuonoCheEsiste;
    [Test]
    procedure DovrebbeRifiutareUnIndiceFuoriDallaLista;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Sound.Types, DelphiDoom.War.Sound.Ids,
  DelphiDoom.War.Cinematic.Types, DelphiDoom.War.Cinematic.Factory;

{ TTestWarCinematicCatalog }

procedure TTestWarCinematicCatalog.Setup;
begin
  FCatalog := TWarCinematicFactory.CreateCatalog;
end;

procedure TTestWarCinematicCatalog.DovrebbeAvereLeTrentanoveAnimazioniDiCinematicsTxt;
var
  LEntry: TWarCinematicEntry;
  LMission: Integer;
begin
  // 3 cave, HFINALE, 2 HINTRO, 12 HMAP, 2 LOSE, OFINALE, 3 OINTRO, 12 OMAP, TITLE, 2 WIN
  Assert.AreEqual<Integer>(39, FCatalog.Count);
  for LMission := 1 to 12 do
  begin
    Assert.IsTrue(FCatalog.TryFind(Format('HMAP%.2d', [LMission]), LEntry));
    Assert.IsTrue(FCatalog.TryFind(Format('OMAP%.2d', [LMission]), LEntry));
  end;
end;

procedure TTestWarCinematicCatalog.DovrebbeAvereNomiTuttiDiversi;
var
  LFirst, LSecond: Integer;
begin
  for LFirst := 0 to FCatalog.Count - 1 do
    for LSecond := LFirst + 1 to FCatalog.Count - 1 do
      Assert.AreNotEqual(FCatalog.Item(LFirst).Name, FCatalog.Item(LSecond).Name);
end;

procedure TTestWarCinematicCatalog.DovrebbeTrovareUnaAnimazioneSenzaDistinguereMaiuscole;
var
  LEntry: TWarCinematicEntry;
begin
  Assert.IsTrue(FCatalog.TryFind('cave1', LEntry));
  Assert.AreEqual('CAVE1', LEntry.Name);
end;

procedure TTestWarCinematicCatalog.DovrebbeNonTrovareUnaAnimazioneCheNonCe;
var
  LEntry: TWarCinematicEntry;
begin
  Assert.IsFalse(FCatalog.TryFind('NOSUCH', LEntry));
  Assert.IsFalse(FCatalog.TryFind('', LEntry));
  Assert.AreEqual('', LEntry.Name);
end;

procedure TTestWarCinematicCatalog.DovrebbeSegnareIlCicloSoloDoveCinematicsTxtDiceLoop;
var
  LIndex: Integer;
  LLoops: string;
  LEntry: TWarCinematicEntry;
begin
  LLoops := '';
  for LIndex := 0 to FCatalog.Count - 1 do
  begin
    LEntry := FCatalog.Item(LIndex);
    if LEntry.Looping then
      LLoops := LLoops + LEntry.Name + ' ';
  end;
  // CAVE2, HINTRO2, LOSE2, OFINALE, OINTRO2 and WIN2 are the "Loop of ..." lines
  Assert.AreEqual('CAVE2 HINTRO2 LOSE2 OFINALE OINTRO2 WIN2 ', LLoops);
end;

procedure TTestWarCinematicCatalog.DovrebbeDareIlSuonoDellaPortaAllaPortaDellaGrotta;
var
  LEntry: TWarCinematicEntry;
begin
  Assert.IsTrue(FCatalog.TryFind('CAVE3', LEntry));
  Assert.AreEqual<Integer>(Ord(wcsFixed), Ord(LEntry.SoundKind));
  Assert.AreEqual<Integer>(WAR_SND_INTRO_DOOR, LEntry.Sound);
end;

procedure TTestWarCinematicCatalog.DovrebbeDareUnSuonoDiVittoriaESconfittaPerLaRazzaDelGiocatore;
var
  LEntry: TWarCinematicEntry;
begin
  Assert.IsTrue(FCatalog.TryFind('WIN1', LEntry));
  Assert.AreEqual<Integer>(Ord(wcsEvent), Ord(LEntry.SoundKind));
  Assert.AreEqual<Integer>(Ord(wseVictory), Ord(LEntry.SoundEvent));
  Assert.AreEqual<Integer>(Ord(wraNeutral), Ord(LEntry.SoundRace), 'The race of the player');
  Assert.IsTrue(FCatalog.TryFind('LOSE1', LEntry));
  Assert.AreEqual<Integer>(Ord(wseDefeat), Ord(LEntry.SoundEvent));
end;

procedure TTestWarCinematicCatalog.DovrebbeDareIFinaliDiOgniRazza;
var
  LEntry: TWarCinematicEntry;
begin
  Assert.IsTrue(FCatalog.TryFind('HFINALE', LEntry));
  Assert.AreEqual<Integer>(WAR_SND_CAMPAIGNS_HUMAN_ENDING_FIRST, LEntry.Sound);
  Assert.IsTrue(FCatalog.TryFind('OFINALE', LEntry));
  Assert.AreEqual<Integer>(WAR_SND_CAMPAIGNS_ORC_ENDING_FIRST, LEntry.Sound);
  Assert.IsTrue(FCatalog.TryFind('TITLE', LEntry));
  Assert.AreEqual<Integer>(WAR_SND_INTRO_LAST, LEntry.Sound);
end;

procedure TTestWarCinematicCatalog.DovrebbeLasciareSenzaSuonoLeAnimazioniDoveIlNomeNonLoDice;
var
  LEntry: TWarCinematicEntry;
  LName: string;
begin
  for LName in ['CAVE1', 'CAVE2', 'HINTRO1', 'HINTRO2', 'OINTRO1', 'OINTRO2', 'OINTRO3', 'HMAP01', 'OMAP12'] do
  begin
    Assert.IsTrue(FCatalog.TryFind(LName, LEntry), LName);
    Assert.AreEqual<Integer>(Ord(wcsNone), Ord(LEntry.SoundKind), LName);
  end;
end;

procedure TTestWarCinematicCatalog.DovrebbeDareUnaVoceSoloAnimazioniConUnSuonoCheEsiste;
var
  LIndex: Integer;
  LEntry: TWarCinematicEntry;
begin
  for LIndex := 0 to FCatalog.Count - 1 do
  begin
    LEntry := FCatalog.Item(LIndex);
    if LEntry.SoundKind = wcsFixed then
      Assert.IsTrue((LEntry.Sound >= 472) and (LEntry.Sound <= 582), LEntry.Name);
  end;
end;

procedure TTestWarCinematicCatalog.DovrebbeRifiutareUnIndiceFuoriDallaLista;
begin
  Assert.WillRaise(
    procedure
    begin
      FCatalog.Item(-1);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FCatalog.Item(39);
    end, EWarException);
end;

end.
