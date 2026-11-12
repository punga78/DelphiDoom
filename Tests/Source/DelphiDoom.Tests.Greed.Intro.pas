{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the intro, the mission briefings,   }
{  the endings and the script of screens                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Intro;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.MenuInput,
  DelphiDoom.Greed.Intro, DelphiDoom.Greed.Briefing, DelphiDoom.Greed.EndGame,
  DelphiDoom.Tests.Greed.MenuScenarios, DelphiDoom.Tests.Greed.IntroScenarios;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedIntro = class(TObject)
  strict private
    FRunner: TIntroLibraryRunner;
    FScenario: TIntroScenario;
    procedure Ticks(ACount: Integer);
    procedure Tap(AScanCode: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereIProfiliDeiCinqueCacciatori;
    [Test]
    procedure DovrebbeSaltareLaSequenzaDeiTitoliSeRedoEVero;
    [Test]
    procedure DovrebbeMostrareITitoliPrimaDeiRitratti;
    [Test]
    procedure DovrebbeFermareITitoliALPrimoSchermoMancante;
    [Test]
    procedure DovrebbeAprireIlMenuConInvioESaltarneIlRitorno;
    [Test]
    procedure DovrebbeFinireQuandoUnaPartitaEAvviata;
    [Test]
    procedure DovrebbeCambiareRitrattoDopoLaPausa;
    [Test]
    procedure DovrebbeRifiutareUnaDipendenzaMancante;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedBriefingEndGame = class(TObject)
  strict private
    FRunner: TIntroLibraryRunner;
    FScenario: TIntroScenario;
    procedure RunToEnd(AMaxTics: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeFinireSubitoSeLaMappaNonHaUnBriefing;
    [Test]
    procedure DovrebbeLasciareLoSchermoNeroELaPalettaDelGioco;
    [Test]
    procedure DovrebbeRimettereIlTempoDiPrima;
    [Test]
    procedure DovrebbeUscireDalBriefingConEsc;
    [Test]
    procedure DovrebbeIniziareUnEpisodioNelleMappeOttoESedici;
    [Test]
    procedure DovrebbeSalireDiEpisodioSenzaFilmati;
    [Test]
    procedure DovrebbeRifiutareUnFinaleCheNonEsiste;
    [Test]
    procedure DovrebbeSaltareLeSchermateDeiCreditiMancanti;
    [Test]
    procedure DovrebbeFinireDopoLeSchermateDelFinale;
  end;

implementation

uses
  DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Display;

{ TTestGreedIntro }

procedure TTestGreedIntro.Setup;
begin
  FRunner := TIntroLibraryRunner.Create(nil);
  FScenario := TIntroScenarios.Scenario(0);
  FScenario.Redo := False;
  FScenario.Sparse := False;
  FScenario.Base.Animation := False;
end;

procedure TTestGreedIntro.TearDown;
begin
  FRunner.Free;
end;

procedure TTestGreedIntro.Ticks(ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
    FRunner.Tick;
end;

procedure TTestGreedIntro.Tap(AScanCode: Integer);
begin
  FRunner.Input.SetKey(AScanCode, True);
  Ticks(3);
  FRunner.Input.SetKey(AScanCode, False);
  Ticks(3);
end;

procedure TTestGreedIntro.DovrebbeLeggereIProfiliDeiCinqueCacciatori;
begin
  Assert.AreEqual('CYBORG', TGreedIntro.ProfileLine(1, 0));
  Assert.AreEqual('DOMINATRIX', TGreedIntro.ProfileLine(5, 0));
  Assert.AreEqual('NAME: XITH', TGreedIntro.ProfileLine(2, 2));
  Assert.AreEqual('.', TGreedIntro.ProfileLine(2, 26));
  Assert.AreEqual('', TGreedIntro.ProfileLine(0, 0));
  Assert.AreEqual('', TGreedIntro.ProfileLine(6, 0));
  Assert.AreEqual('', TGreedIntro.ProfileLine(1, 27));
end;

procedure TTestGreedIntro.DovrebbeSaltareLaSequenzaDeiTitoliSeRedoEVero;
begin
  FScenario.Redo := True;
  FRunner.Prepare(FScenario);
  FRunner.Intro.Start(True);
  Assert.IsTrue(FRunner.Intro.Active);
  Assert.AreEqual(1, FRunner.Intro.Character);
  Assert.AreEqual(Ord(gipPortraitIn), Ord(FRunner.Intro.Phase));
  Assert.AreEqual(1, FRunner.Host.SoundUpdates + 1, 'nessun suono prima della prima riga');
end;

procedure TTestGreedIntro.DovrebbeMostrareITitoliPrimaDeiRitratti;
begin
  FRunner.Prepare(FScenario);
  FRunner.Intro.Start(False);
  Assert.AreEqual(Ord(gipTitle), Ord(FRunner.Intro.Phase));
  Assert.AreEqual(0, FRunner.Intro.Character);
  // the three logos and the nine slides take a few thousand tics
  Ticks(6400);
  Assert.IsTrue(FRunner.Intro.Character >= 1, 'i ritratti sono cominciati');
  Assert.IsTrue(FRunner.Intro.Active);
end;

procedure TTestGreedIntro.DovrebbeFermareITitoliALPrimoSchermoMancante;
begin
  FScenario.Sparse := True;
  FRunner.Prepare(FScenario);
  FRunner.Intro.Start(False);
  Ticks(3200);
  Assert.IsTrue(FRunner.Intro.Character >= 1, 'INTRO02 manca: i titoli finiscono e iniziano i ritratti');
end;

procedure TTestGreedIntro.DovrebbeAprireIlMenuConInvioESaltarneIlRitorno;
var
  LIndex: Integer;
begin
  FScenario.Redo := True;
  FRunner.Prepare(FScenario);
  FRunner.Intro.Start(True);
  Ticks(40);
  FRunner.Input.SetKey(GREED_SC_ENTER, True);
  Ticks(3);
  FRunner.Input.SetKey(GREED_SC_ENTER, False);
  // the menu opens when the line that is being written is finished
  LIndex := 0;
  while (FRunner.Intro.Phase <> gipMenu) and (LIndex < 100) do
  begin
    FRunner.Tick;
    Inc(LIndex);
  end;
  Assert.AreEqual(Ord(gipMenu), Ord(FRunner.Intro.Phase));
  Assert.IsTrue(FRunner.Menu.Active);
  // escape in the main menu closes it after 30 tics, and the portrait comes back
  Ticks(40);
  Tap(GREED_SC_ESCAPE);
  Ticks(10);
  Assert.AreNotEqual(Ord(gipMenu), Ord(FRunner.Intro.Phase));
  Assert.IsTrue(FRunner.Intro.Active);
end;

procedure TTestGreedIntro.DovrebbeFinireQuandoUnaPartitaEAvviata;
var
  LIndex: Integer;
begin
  FScenario.Redo := True;
  FRunner.Prepare(FScenario);
  FRunner.Intro.Start(True);
  Ticks(40);
  Tap(GREED_SC_ENTER);
  Ticks(40);
  // new game, the first character, the first difficulty
  Tap(GREED_SC_ENTER);
  Tap(GREED_SC_ENTER);
  FRunner.Input.SetKey(GREED_SC_ENTER, True);
  for LIndex := 1 to 30 do
    FRunner.Tick;
  Assert.IsFalse(FRunner.Intro.Active);
  Assert.IsTrue(FRunner.Host.Loaded);
end;

procedure TTestGreedIntro.DovrebbeCambiareRitrattoDopoLaPausa;
begin
  FScenario.Redo := True;
  FRunner.Prepare(FScenario);
  FRunner.Intro.Start(True);
  // 27 lines, then 50 pauses of 35 tics, then the fade out: the portrait changes after about 2000 tics
  Ticks(1900);
  Assert.AreEqual(1, FRunner.Intro.Character);
  Ticks(400);
  Assert.AreEqual(2, FRunner.Intro.Character);
end;

procedure TTestGreedIntro.DovrebbeRifiutareUnaDipendenzaMancante;
begin
  FRunner.Prepare(FScenario);
  Assert.WillRaise(
    procedure
    begin
      TGreedIntro.Create(FRunner.Display, FRunner.Input, FRunner.Printer, nil, nil, nil, FRunner.Menu,
        FRunner.Host).Free;
    end, EArgumentNilException);
end;

{ TTestGreedBriefingEndGame }

procedure TTestGreedBriefingEndGame.Setup;
begin
  FRunner := TIntroLibraryRunner.Create(nil);
  FScenario := TIntroScenarios.Scenario(24);
  FScenario.Sparse := False;
  FScenario.Base.Demo := False;
  FScenario.MovieNames := nil;
  FScenario.MovieBytes := nil;
end;

procedure TTestGreedBriefingEndGame.TearDown;
begin
  FRunner.Free;
end;

procedure TTestGreedBriefingEndGame.RunToEnd(AMaxTics: Integer);
var
  LTics: Integer;
begin
  LTics := 0;
  while FRunner.Active and (LTics < AMaxTics) do
  begin
    // a key every 30 tics gets through every page
    if LTics mod 30 = 5 then
      FRunner.Input.SetKey(GREED_SC_SPACE, True);
    if LTics mod 30 = 8 then
      FRunner.Input.SetKey(GREED_SC_SPACE, False);
    FRunner.Tick;
    Inc(LTics);
  end;
end;

procedure TTestGreedBriefingEndGame.DovrebbeFinireSubitoSeLaMappaNonHaUnBriefing;
begin
  FScenario.Map := 8;
  FScenario.Base.Episode := 1;
  FRunner.Prepare(FScenario);
  FRunner.Briefing.Start(8, FScenario.Stats);
  // no page and no wait: everything runs in Start, down to the black screen
  Assert.IsFalse(FRunner.Briefing.Active);
  Assert.AreEqual(Byte(0), FRunner.Canvas.GetPixel(10, 10));
  Assert.AreEqual(0, FRunner.Host.EpisodesStarted);
end;

procedure TTestGreedBriefingEndGame.DovrebbeLasciareLoSchermoNeroELaPalettaDelGioco;
var
  LPalette: TBytes;
  LIndex: Integer;
begin
  FRunner.Prepare(FScenario);
  FRunner.Briefing.Start(0, FScenario.Stats);
  RunToEnd(6000);
  Assert.IsFalse(FRunner.Briefing.Active);
  Assert.AreEqual(Byte(0), FRunner.Canvas.GetPixel(10, 10));
  LPalette := FRunner.Display.Archive.ReadLump(FRunner.Display.Archive.RequireIndexOf('palette'));
  for LIndex := 0 to 767 do
    Assert.AreEqual(Byte(LPalette[LIndex] * 4), FRunner.Display.Palette[LIndex]);
end;

procedure TTestGreedBriefingEndGame.DovrebbeRimettereIlTempoDiPrima;
var
  LStart: Integer;
begin
  FRunner.Prepare(FScenario);
  LStart := FRunner.Input.TimeCount;
  FRunner.Briefing.Start(0, FScenario.Stats);
  RunToEnd(6000);
  Assert.AreEqual(LStart, FRunner.Input.TimeCount);
end;

procedure TTestGreedBriefingEndGame.DovrebbeUscireDalBriefingConEsc;
var
  LTics: Integer;
begin
  FRunner.Prepare(FScenario);
  FRunner.Briefing.Start(0, FScenario.Stats);
  // the first page prints for 27 tics after the fade (64) and the second (70): an escape at the key wait ends it all
  for LTics := 1 to 400 do
    FRunner.Tick;
  FRunner.Input.SetKey(GREED_SC_ESCAPE, True);
  for LTics := 1 to 30 do
    FRunner.Tick;
  FRunner.Input.SetKey(GREED_SC_ESCAPE, False);
  FRunner.Tick;
  Assert.IsFalse(FRunner.Briefing.Active);
end;

procedure TTestGreedBriefingEndGame.DovrebbeIniziareUnEpisodioNelleMappeOttoESedici;
begin
  FScenario.Map := 8;
  FScenario.Base.Episode := 2;
  FRunner.Prepare(FScenario);
  FRunner.Briefing.Start(8, FScenario.Stats);
  Assert.AreEqual(1, FRunner.Host.EpisodesStarted);
  Assert.AreEqual(99, FRunner.Host.Songs[0]);
  RunToEnd(8000);
  Assert.AreEqual(8, FRunner.Host.Songs[High(FRunner.Host.Songs)]);
end;

procedure TTestGreedBriefingEndGame.DovrebbeSalireDiEpisodioSenzaFilmati;
begin
  FScenario.Map := 16;
  FScenario.Base.Episode := 3;
  FRunner.Prepare(FScenario);
  FRunner.Briefing.Start(16, FScenario.Stats);
  RunToEnd(8000);
  Assert.IsFalse(FRunner.Briefing.Active);
  Assert.AreEqual(1, FRunner.Host.EpisodesStarted);
end;

procedure TTestGreedBriefingEndGame.DovrebbeRifiutareUnFinaleCheNonEsiste;
begin
  FRunner.Prepare(FScenario);
  Assert.WillRaise(
    procedure
    begin
      FRunner.EndGame.Start(0);
    end, EGreedException);
  Assert.WillRaise(
    procedure
    begin
      FRunner.EndGame.Start(4);
    end, EGreedException);
end;

procedure TTestGreedBriefingEndGame.DovrebbeSaltareLeSchermateDeiCreditiMancanti;
begin
  FScenario.Sparse := True;
  FRunner.Prepare(FScenario);
  FRunner.EndGame.Start(2);
  RunToEnd(8000);
  Assert.IsFalse(FRunner.EndGame.Active);
  Assert.AreEqual(22, FRunner.Host.Songs[0]);
end;

procedure TTestGreedBriefingEndGame.DovrebbeFinireDopoLeSchermateDelFinale;
begin
  FRunner.Prepare(FScenario);
  FRunner.EndGame.Start(3);
  Assert.IsTrue(FRunner.EndGame.Active);
  RunToEnd(8000);
  Assert.IsFalse(FRunner.EndGame.Active);
  Assert.AreEqual(0, Length(FRunner.Host.Songs), 'il terzo finale non cambia canzone');
end;

end.
