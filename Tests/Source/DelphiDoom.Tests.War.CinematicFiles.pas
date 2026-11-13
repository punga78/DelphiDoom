{******************************************************************************}
{                                                                              }
{  DelphiDoom: the animations of the DOS game, played by the scene of Libs\    }
{  Cinematic through the director of Libs\War                                  }
{                                                                              }
{  They need the files of the game (DELPHIDOOM_WAR_DATA or Reference\_dati\    }
{  warcraft): without them the tests are ignored. HMAP01-12, OMAP01-12, LOSE1  }
{  and WIN1 are not on that disk: the director gives nil and they are skipped. }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.CinematicFiles;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Cinematic.Intf, DelphiDoom.Tests.War.MusicFakes;

type
  [TestFixture]
  [Category('war')]
  TTestWarCinematicFiles = class
  strict private
    FMixer: TFakeSoundMixer;
    FMixerHold: IInterface;
    function Director: IWarCinematicDirector;
  public
    [Test]
    procedure DovrebbeSaltareLe26AnimazioniCheNonSonoSulDisco;
    [Test]
    procedure DovrebbeFarGiocareFinoAllaFineLeAnimazioniSenzaCiclo;
    [Test]
    procedure DovrebbeTenereLeAnimazioniInCicloFinoAlSalto;
    [Test]
    procedure DovrebbeSuonareLaPortaDellaGrottaEFermarlaSeSaltata;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Cinematic.Flic.Intf, DelphiDoom.Cinematic.Flic.Scene.Types,
  DelphiDoom.Cinematic.Flic.Scene.Intf, DelphiDoom.Cinematic.Flic.SceneFactory, DelphiDoom.War.Audio.Intf,
  DelphiDoom.War.Level.Types, DelphiDoom.War.Sound.Ids, DelphiDoom.War.Sound.Factory,
  DelphiDoom.War.Cinematic.Types, DelphiDoom.War.Cinematic.Factory, DelphiDoom.Tests.War.RealData;

{ TTestWarCinematicFiles }

function TTestWarCinematicFiles.Director: IWarCinematicDirector;
var
  LFolder: string;
  LMixer: IWarSoundMixer;
begin
  LFolder := ExtractFilePath(TWarRealData.RequireDataWar);
  FMixer := TFakeSoundMixer.Create;
  LMixer := FMixer;
  FMixerHold := LMixer;
  Result := TWarCinematicFactory.CreateDirector(
    TFlicSceneFactory.CreateMaker(TFlicSceneFactory.CreateFolderSource(LFolder, '.WAR')), LMixer,
    TWarSoundFactory.CreatePicker(TWarSoundFactory.CreateRandom(1)));
end;

procedure TTestWarCinematicFiles.DovrebbeSaltareLe26AnimazioniCheNonSonoSulDisco;
var
  LCatalog: IWarCinematicCatalog;
  LDirector: IWarCinematicDirector;
  LIndex, LFound, LMissing: Integer;
  LMissingNames: string;
begin
  LDirector := Director;
  LCatalog := TWarCinematicFactory.CreateCatalog;
  LFound := 0;
  LMissing := 0;
  LMissingNames := '';
  for LIndex := 0 to LCatalog.Count - 1 do
    if Assigned(LDirector.TryOpen(LCatalog.Item(LIndex).Name, wraHumans)) then
      Inc(LFound)
    else
    begin
      Inc(LMissing);
      LMissingNames := LMissingNames + LCatalog.Item(LIndex).Name + ' ';
    end;
  Assert.AreEqual<Integer>(13, LFound);
  Assert.AreEqual<Integer>(26, LMissing);
  Assert.IsTrue(LMissingNames.Contains('LOSE1 '));
  Assert.IsTrue(LMissingNames.Contains('WIN1 '));
  Assert.IsTrue(LMissingNames.Contains('HMAP12 '));
  Assert.IsTrue(LMissingNames.Contains('OMAP01 '));
end;

procedure TTestWarCinematicFiles.DovrebbeFarGiocareFinoAllaFineLeAnimazioniSenzaCiclo;
var
  LCatalog: IWarCinematicCatalog;
  LDirector: IWarCinematicDirector;
  LScene: IFlicScene;
  LFrame: TFlicSceneFrame;
  LIndex, LTime, LChanged, LPlayed: Integer;
  LEntry: TWarCinematicEntry;
begin
  LDirector := Director;
  LCatalog := TWarCinematicFactory.CreateCatalog;
  LPlayed := 0;
  for LIndex := 0 to LCatalog.Count - 1 do
  begin
    LEntry := LCatalog.Item(LIndex);
    LScene := LDirector.TryOpen(LEntry.Name, wraOrcs);
    if (LScene = nil) or LEntry.Looping then
      Continue;
    LTime := 0;
    LChanged := 0;
    repeat
      LFrame := LScene.Update(LTime, False);
      if LFrame.FrameChanged then
        Inc(LChanged);
      Inc(LTime, 50);
    until (LFrame.State <> fssPlaying) or (LTime > 30000);
    Assert.AreEqual<Integer>(Ord(fssEnded), Ord(LFrame.State), LEntry.Name);
    Assert.IsTrue(LChanged > 10, LEntry.Name + ' has frames');
    Assert.IsTrue((LFrame.Image.Width > 0) and (LFrame.Image.Height > 0), LEntry.Name);
    Assert.IsTrue(LFrame.Image.Status = fpsEnded, LEntry.Name);
    Inc(LPlayed);
  end;
  // CAVE1, CAVE3, HFINALE, HINTRO1, OINTRO1, OINTRO3, TITLE
  Assert.AreEqual<Integer>(7, LPlayed);
end;

procedure TTestWarCinematicFiles.DovrebbeTenereLeAnimazioniInCicloFinoAlSalto;
var
  LCatalog: IWarCinematicCatalog;
  LDirector: IWarCinematicDirector;
  LScene: IFlicScene;
  LFrame: TFlicSceneFrame;
  LIndex, LTime, LLooped: Integer;
  LEntry: TWarCinematicEntry;
begin
  LDirector := Director;
  LCatalog := TWarCinematicFactory.CreateCatalog;
  LLooped := 0;
  for LIndex := 0 to LCatalog.Count - 1 do
  begin
    LEntry := LCatalog.Item(LIndex);
    LScene := LDirector.TryOpen(LEntry.Name, wraHumans);
    if (LScene = nil) or not LEntry.Looping then
      Continue;
    // two minutes of a loop of two seconds: it is still playing
    for LTime := 0 to 2400 do
    begin
      LFrame := LScene.Update(LTime * 50, False);
      Assert.AreEqual<Integer>(Ord(fssPlaying), Ord(LFrame.State), LEntry.Name);
    end;
    LFrame := LScene.Update(121000, True);
    Assert.AreEqual<Integer>(Ord(fssSkipped), Ord(LFrame.State), LEntry.Name);
    Inc(LLooped);
  end;
  // CAVE2, HINTRO2, LOSE2, OFINALE, OINTRO2, WIN2
  Assert.AreEqual<Integer>(6, LLooped);
end;

procedure TTestWarCinematicFiles.DovrebbeSuonareLaPortaDellaGrottaEFermarlaSeSaltata;
var
  LScene: IFlicScene;
  LFrame: TFlicSceneFrame;
begin
  LScene := Director.TryOpen('CAVE3', wraHumans);
  Assert.IsNotNull(LScene);
  LFrame := LScene.Update(0, False);
  Assert.AreEqual<Integer>(Ord(fssPlaying), Ord(LFrame.State));
  Assert.AreEqual<Integer>(1, Length(FMixer.Played));
  Assert.AreEqual<Integer>(WAR_SND_INTRO_DOOR, FMixer.Played[0]);
  LFrame := LScene.Update(100, True);
  Assert.AreEqual<Integer>(Ord(fssSkipped), Ord(LFrame.State));
  Assert.AreEqual<Integer>(1, Length(FMixer.Stopped));
end;

end.
