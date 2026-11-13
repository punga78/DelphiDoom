{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the director of the animations of Libs\War             }
{                                                                              }
{  A fake maker stands for the files: some animations are there, the others    }
{  are not (as HMAP, OMAP, LOSE1 and WIN1 on the disk of the DOS game).        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.CinematicDirector;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Cinematic.Flic.Scene.Types, DelphiDoom.Cinematic.Flic.Scene.Intf,
  DelphiDoom.War.Audio.Intf, DelphiDoom.War.Cinematic.Intf, DelphiDoom.Tests.War.MusicFakes;

type
  /// <summary>Makes a scene for the names it has; it writes down what it was asked</summary>
  TFakeSceneMaker = class(TInterfacedObject, IFlicSceneMaker)
  strict private
    FAvailable: TArray<string>;
  public
    LastName: string;
    LastOptions: TFlicSceneOptions;
    LastAudio: IFlicSceneAudio;
    Asked: Integer;
    constructor Create(const AAvailable: array of string);
    function TryCreateScene(const AName: string; const AOptions: TFlicSceneOptions;
      const AAudio: IFlicSceneAudio): IFlicScene;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarCinematicDirector = class
  strict private
    FMaker: TFakeSceneMaker;
    FMakerHold: IFlicSceneMaker;
    FMixer: TFakeSoundMixer;
    FMixerHold: IWarSoundMixer;
    FDirector: IWarCinematicDirector;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareLaScenaDiUnAnimazioneCheEsiste;
    [Test]
    procedure DovrebbeDareNilSeLAnimazioneNonEDelGioco;
    [Test]
    procedure DovrebbeDareNilSeIlFileDellAnimazioneNonCe;
    [Test]
    procedure DovrebbeChiedereIlCicloSoloPerLeAnimazioniInCiclo;
    [Test]
    procedure DovrebbeRendereLeScenePiuttostoSaltabili;
    [Test]
    procedure DovrebbeDareUnaVoceAUnaScenaConSuono;
    [Test]
    procedure DovrebbeNonDareUnaVoceAUnaScenaSenzaSuono;
    [Test]
    procedure DovrebbeSuonareLaVoceDellaRazzaDelGiocatore;
    [Test]
    procedure DovrebbeFarSuonareLaScenaSenzaMixerSenzaVoce;
    [Test]
    procedure DovrebbeSaltareTutteLeAnimazioniMancantiDelDiscoDelDos;
    [Test]
    procedure DovrebbeRifiutareCatalogoOProduttoreNulli;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Sound.Ids, DelphiDoom.War.Sound.Factory,
  DelphiDoom.War.Cinematic.Factory, DelphiDoom.War.Cinematic.Director;

type
  /// <summary>A scene that does nothing: only the way it was made counts</summary>
  TFakeScene = class(TInterfacedObject, IFlicScene)
  strict private
    FName: string;
  public
    constructor Create(const AName: string);
    function GetName: string;
    function GetState: TFlicSceneState;
    function Update(AMilliseconds: Integer; ASkipRequested: Boolean): TFlicSceneFrame;
  end;

{ TFakeScene }

constructor TFakeScene.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

function TFakeScene.GetName: string;
begin
  Result := FName;
end;

function TFakeScene.GetState: TFlicSceneState;
begin
  Result := fssPending;
end;

function TFakeScene.Update(AMilliseconds: Integer; ASkipRequested: Boolean): TFlicSceneFrame;
begin
  Result := Default(TFlicSceneFrame);
end;

{ TFakeSceneMaker }

constructor TFakeSceneMaker.Create(const AAvailable: array of string);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FAvailable, Length(AAvailable));
  for LIndex := 0 to High(AAvailable) do
    FAvailable[LIndex] := AAvailable[LIndex];
end;

function TFakeSceneMaker.TryCreateScene(const AName: string; const AOptions: TFlicSceneOptions;
  const AAudio: IFlicSceneAudio): IFlicScene;
var
  LName: string;
begin
  Inc(Asked);
  LastName := AName;
  LastOptions := AOptions;
  LastAudio := AAudio;
  for LName in FAvailable do
    if SameText(LName, AName) then
      Exit(TFakeScene.Create(AName));
  Result := nil;
end;

{ TTestWarCinematicDirector }

procedure TTestWarCinematicDirector.Setup;
begin
  FMaker := TFakeSceneMaker.Create(['CAVE1', 'CAVE2', 'CAVE3', 'WIN2', 'LOSE2', 'TITLE', 'HFINALE']);
  FMakerHold := FMaker;
  FMixer := TFakeSoundMixer.Create;
  FMixerHold := FMixer;
  FDirector := TWarCinematicFactory.CreateDirector(FMakerHold, FMixerHold,
    TWarSoundFactory.CreatePicker(TScriptedRandom.Create([1, 1])));
end;

procedure TTestWarCinematicDirector.DovrebbeDareLaScenaDiUnAnimazioneCheEsiste;
var
  LScene: IFlicScene;
begin
  LScene := FDirector.TryOpen('CAVE1', wraHumans);
  Assert.IsNotNull(LScene);
  Assert.AreEqual('CAVE1', LScene.Name);
  Assert.AreEqual('CAVE1', FMaker.LastName);
end;

procedure TTestWarCinematicDirector.DovrebbeDareNilSeLAnimazioneNonEDelGioco;
begin
  Assert.IsNull(FDirector.TryOpen('NOSUCH', wraHumans));
  Assert.AreEqual<Integer>(0, FMaker.Asked, 'The maker is not asked for what the game has not');
end;

procedure TTestWarCinematicDirector.DovrebbeDareNilSeIlFileDellAnimazioneNonCe;
begin
  Assert.IsNull(FDirector.TryOpen('HMAP01', wraHumans));
  Assert.IsNull(FDirector.TryOpen('OMAP05', wraOrcs));
  Assert.IsNull(FDirector.TryOpen('LOSE1', wraHumans));
  Assert.IsNull(FDirector.TryOpen('WIN1', wraOrcs));
  Assert.AreEqual<Integer>(4, FMaker.Asked);
end;

procedure TTestWarCinematicDirector.DovrebbeChiedereIlCicloSoloPerLeAnimazioniInCiclo;
begin
  FDirector.TryOpen('CAVE2', wraHumans);
  Assert.IsTrue(FMaker.LastOptions.Looping);
  FDirector.TryOpen('CAVE1', wraHumans);
  Assert.IsFalse(FMaker.LastOptions.Looping);
end;

procedure TTestWarCinematicDirector.DovrebbeRendereLeScenePiuttostoSaltabili;
begin
  FDirector.TryOpen('CAVE1', wraHumans);
  Assert.IsTrue(FMaker.LastOptions.Skippable);
  FDirector.TryOpen('WIN2', wraHumans);
  Assert.IsTrue(FMaker.LastOptions.Skippable);
end;

procedure TTestWarCinematicDirector.DovrebbeDareUnaVoceAUnaScenaConSuono;
begin
  FDirector.TryOpen('CAVE3', wraHumans);
  Assert.IsNotNull(FMaker.LastAudio);
  FMaker.LastAudio.SceneStarted;
  Assert.AreEqual<Integer>(WAR_SND_INTRO_DOOR, FMixer.Played[0]);
end;

procedure TTestWarCinematicDirector.DovrebbeNonDareUnaVoceAUnaScenaSenzaSuono;
begin
  FDirector.TryOpen('CAVE1', wraHumans);
  Assert.IsNull(FMaker.LastAudio);
end;

procedure TTestWarCinematicDirector.DovrebbeSuonareLaVoceDellaRazzaDelGiocatore;
begin
  FDirector.TryOpen('WIN2', wraOrcs);
  FMaker.LastAudio.SceneStarted;
  // the picker answers 1: the second of the victories of the orcs
  Assert.AreEqual<Integer>(WAR_SND_ORC_VICTORY_FIRST + 1, FMixer.Played[0]);
  FDirector.TryOpen('LOSE2', wraHumans);
  FMaker.LastAudio.SceneStarted;
  Assert.AreEqual<Integer>(WAR_SND_HUMAN_DEFEAT, FMixer.Played[1]);
end;

procedure TTestWarCinematicDirector.DovrebbeFarSuonareLaScenaSenzaMixerSenzaVoce;
var
  LDirector: IWarCinematicDirector;
begin
  LDirector := TWarCinematicFactory.CreateDirector(FMakerHold, nil, nil);
  Assert.IsNotNull(LDirector.TryOpen('CAVE3', wraHumans));
  Assert.IsNull(FMaker.LastAudio);
end;

procedure TTestWarCinematicDirector.DovrebbeSaltareTutteLeAnimazioniMancantiDelDiscoDelDos;
var
  LCatalog: IWarCinematicCatalog;
  LIndex, LMade, LSkipped: Integer;
begin
  // the disk we have has 7 of these 39: the others give nil and the caller goes on
  LCatalog := TWarCinematicFactory.CreateCatalog;
  LMade := 0;
  LSkipped := 0;
  for LIndex := 0 to LCatalog.Count - 1 do
    if Assigned(FDirector.TryOpen(LCatalog.Item(LIndex).Name, wraHumans)) then
      Inc(LMade)
    else
      Inc(LSkipped);
  Assert.AreEqual<Integer>(7, LMade);
  Assert.AreEqual<Integer>(32, LSkipped);
end;

procedure TTestWarCinematicDirector.DovrebbeRifiutareCatalogoOProduttoreNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarCinematicDirector.Create(nil, FMakerHold, nil, nil);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarCinematicDirector.Create(TWarCinematicFactory.CreateCatalog, nil, nil, nil);
    end, EWarException);
end;

end.
