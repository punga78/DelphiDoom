{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound of the animations of Libs\War                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.CinematicAudio;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Cinematic.Flic.Scene.Intf, DelphiDoom.War.Cinematic.Types,
  DelphiDoom.War.Level.Types, DelphiDoom.War.Audio.Intf, DelphiDoom.Tests.War.MusicFakes;

type
  [TestFixture]
  [Category('war')]
  TTestWarCinematicAudio = class
  strict private
    FMixer: TFakeSoundMixer;
    FMixerHold: IWarSoundMixer;
    function Audio(const AEntry: TWarCinematicEntry; APlayerRace: TWarRace; const ARandom: array of Integer): IFlicSceneAudio;
    class function Fixed(ASound: Integer): TWarCinematicEntry; static;
    class function Event(AKind: Integer; ARace: TWarRace): TWarCinematicEntry; static;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeSuonareIlSuonoFissoQuandoLaScenaParte;
    [Test]
    procedure DovrebbeNonSuonarePrimaDellInizioDellaScena;
    [Test]
    procedure DovrebbeFermareLaVoceSeLaScenaESaltata;
    [Test]
    procedure DovrebbeLasciareFinireLaVoceSeLaScenaFinisceDaSola;
    [Test]
    procedure DovrebbeScegliereLaVittoriaDellaRazzaDelGiocatore;
    [Test]
    procedure DovrebbeScegliereLaSconfittaDellaRazzaDelGiocatore;
    [Test]
    procedure DovrebbeUsareLaRazzaDellaVoceSeLaVoceNeHaUna;
    [Test]
    procedure DovrebbeNonSuonareNullaSenzaSuono;
    [Test]
    procedure DovrebbeNonFermareNullaSeNonCeUnaVoce;
    [Test]
    procedure DovrebbeFermareUnaVoceUnaSolaVolta;
    [Test]
    procedure DovrebbeRifiutareMixerOSceltaNulli;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Sound.Types, DelphiDoom.War.Sound.Ids, DelphiDoom.War.Sound.Factory,
  DelphiDoom.War.Cinematic.Audio;

{ TTestWarCinematicAudio }

procedure TTestWarCinematicAudio.Setup;
begin
  FMixer := TFakeSoundMixer.Create;
  FMixerHold := FMixer;
end;

class function TTestWarCinematicAudio.Fixed(ASound: Integer): TWarCinematicEntry;
begin
  Result := Default(TWarCinematicEntry);
  Result.Name := 'X';
  Result.SoundKind := wcsFixed;
  Result.Sound := ASound;
end;

class function TTestWarCinematicAudio.Event(AKind: Integer; ARace: TWarRace): TWarCinematicEntry;
begin
  Result := Default(TWarCinematicEntry);
  Result.Name := 'X';
  Result.SoundKind := wcsEvent;
  Result.SoundEvent := TWarSoundEvent(AKind);
  Result.SoundRace := ARace;
end;

function TTestWarCinematicAudio.Audio(const AEntry: TWarCinematicEntry; APlayerRace: TWarRace;
  const ARandom: array of Integer): IFlicSceneAudio;
begin
  Result := TWarCinematicAudio.Create(FMixer, TWarSoundFactory.CreatePicker(TScriptedRandom.Create(ARandom)), AEntry,
    APlayerRace);
end;

procedure TTestWarCinematicAudio.DovrebbeSuonareIlSuonoFissoQuandoLaScenaParte;
var
  LAudio: IFlicSceneAudio;
begin
  LAudio := Audio(Fixed(WAR_SND_INTRO_DOOR), wraHumans, []);
  LAudio.SceneStarted;
  Assert.AreEqual<Integer>(1, Length(FMixer.Played));
  Assert.AreEqual<Integer>(WAR_SND_INTRO_DOOR, FMixer.Played[0]);
end;

procedure TTestWarCinematicAudio.DovrebbeNonSuonarePrimaDellInizioDellaScena;
begin
  Audio(Fixed(WAR_SND_INTRO_DOOR), wraHumans, []);
  Assert.AreEqual<Integer>(0, Length(FMixer.Played));
end;

procedure TTestWarCinematicAudio.DovrebbeFermareLaVoceSeLaScenaESaltata;
var
  LAudio: IFlicSceneAudio;
begin
  LAudio := Audio(Fixed(WAR_SND_INTRO_DOOR), wraHumans, []);
  LAudio.SceneStarted;
  LAudio.SceneFinished(True);
  Assert.AreEqual<Integer>(1, Length(FMixer.Stopped));
  Assert.AreEqual<Integer>(1, FMixer.Stopped[0], 'The handle of the voice');
end;

procedure TTestWarCinematicAudio.DovrebbeLasciareFinireLaVoceSeLaScenaFinisceDaSola;
var
  LAudio: IFlicSceneAudio;
begin
  LAudio := Audio(Fixed(WAR_SND_INTRO_DOOR), wraHumans, []);
  LAudio.SceneStarted;
  LAudio.SceneFinished(False);
  Assert.AreEqual<Integer>(0, Length(FMixer.Stopped));
end;

procedure TTestWarCinematicAudio.DovrebbeScegliereLaVittoriaDellaRazzaDelGiocatore;
var
  LAudio: IFlicSceneAudio;
begin
  LAudio := Audio(Event(Ord(wseVictory), wraNeutral), wraHumans, [2]);
  LAudio.SceneStarted;
  Assert.AreEqual<Integer>(WAR_SND_HUMAN_VICTORY_LAST, FMixer.Played[0]);
  LAudio := Audio(Event(Ord(wseVictory), wraNeutral), wraOrcs, [1]);
  LAudio.SceneStarted;
  Assert.AreEqual<Integer>(WAR_SND_ORC_VICTORY_FIRST + 1, FMixer.Played[1]);
end;

procedure TTestWarCinematicAudio.DovrebbeScegliereLaSconfittaDellaRazzaDelGiocatore;
var
  LAudio: IFlicSceneAudio;
begin
  LAudio := Audio(Event(Ord(wseDefeat), wraNeutral), wraOrcs, []);
  LAudio.SceneStarted;
  Assert.AreEqual<Integer>(WAR_SND_ORC_DEFEAT, FMixer.Played[0]);
  LAudio := Audio(Event(Ord(wseDefeat), wraNeutral), wraHumans, []);
  LAudio.SceneStarted;
  Assert.AreEqual<Integer>(WAR_SND_HUMAN_DEFEAT, FMixer.Played[1]);
end;

procedure TTestWarCinematicAudio.DovrebbeUsareLaRazzaDellaVoceSeLaVoceNeHaUna;
var
  LAudio: IFlicSceneAudio;
begin
  LAudio := Audio(Event(Ord(wseDefeat), wraHumans), wraOrcs, []);
  LAudio.SceneStarted;
  Assert.AreEqual<Integer>(WAR_SND_HUMAN_DEFEAT, FMixer.Played[0]);
end;

procedure TTestWarCinematicAudio.DovrebbeNonSuonareNullaSenzaSuono;
var
  LAudio: IFlicSceneAudio;
  LEntry: TWarCinematicEntry;
begin
  LEntry := Default(TWarCinematicEntry);
  LAudio := Audio(LEntry, wraHumans, []);
  LAudio.SceneStarted;
  Assert.AreEqual<Integer>(0, Length(FMixer.Played));
end;

procedure TTestWarCinematicAudio.DovrebbeNonFermareNullaSeNonCeUnaVoce;
var
  LAudio: IFlicSceneAudio;
  LEntry: TWarCinematicEntry;
begin
  LEntry := Default(TWarCinematicEntry);
  LAudio := Audio(LEntry, wraHumans, []);
  LAudio.SceneStarted;
  LAudio.SceneFinished(True);
  Assert.AreEqual<Integer>(0, Length(FMixer.Stopped));
end;

procedure TTestWarCinematicAudio.DovrebbeFermareUnaVoceUnaSolaVolta;
var
  LAudio: IFlicSceneAudio;
begin
  LAudio := Audio(Fixed(WAR_SND_LOGO), wraHumans, []);
  LAudio.SceneStarted;
  LAudio.SceneFinished(True);
  LAudio.SceneFinished(True);
  Assert.AreEqual<Integer>(1, Length(FMixer.Stopped));
end;

procedure TTestWarCinematicAudio.DovrebbeRifiutareMixerOSceltaNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarCinematicAudio.Create(nil, TWarSoundFactory.CreatePicker(TScriptedRandom.Create([])), Fixed(1), wraNeutral);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarCinematicAudio.Create(FMixer, nil, Fixed(1), wraNeutral);
    end, EWarException);
end;

end.
