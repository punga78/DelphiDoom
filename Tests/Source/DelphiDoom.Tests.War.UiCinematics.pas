{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the introduction (scene of the       }
{  animations)                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.UiCinematics;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Cinematic.Flic.Scene.Intf,
  DelphiDoom.Cinematic.Flic.Scene.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Cinematic.Intf,
  DelphiDoom.War.Ui.Game, DelphiDoom.War.Ui.Types, DelphiDoom.Tests.War.UiFakes;

type
  /// <summary>An animation of a fake: it ends after a number of updates (0 = a loop that only a skip stops)</summary>
  TFakeFlicScene = class(TInterfacedObject, IFlicScene)
  strict private
    FName: string;
    FLength: Integer;
    FLog: TStrings;
    FUpdates: Integer;
    FState: TFlicSceneState;
  public
    constructor Create(const AName: string; ALength: Integer; const ALog: TStrings);
    function GetName: string;
    function GetState: TFlicSceneState;
    function Update(AMilliseconds: Integer; ASkipRequested: Boolean): TFlicSceneFrame;
  end;

  /// <summary>The animations of a fake: the names that exist, one that is a broken file, and the log of what was opened</summary>
  TFakeDirector = class(TInterfacedObject, IWarCinematicDirector)
  strict private
    FLog: TStrings;
    FMissing: string;
    FBroken: string;
  public
    /// <param name="AMissing">The name of an animation the game has not got ('*' for all of them)</param>
    /// <param name="ABroken">The name of a file that is there and is not an animation</param>
    constructor Create(const ALog: TStrings; const AMissing: string = ''; const ABroken: string = '');
    function TryOpen(const AName: string; APlayerRace: TWarRace): IFlicScene;
  end;

  [TestFixture]
  [Category('War')]
  TTestWarUiCinematics = class
  strict private
    FSprites: TFakeUiSprites;
    FSpritesRef: IInterface;
    FLog: TStringList;
    FGame: TWarUiGame;
    procedure NewGame(const ACinematics: IWarCinematicDirector; AIntroductionAfterLogo: Boolean);
    procedure Tick(ACount: Integer = 1);
    procedure PressKey(AKey: TWarKey);
    procedure Click(AX, AY: Single);
    function SceneKind: TWarSceneType;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSuonareLeAnimazioniInOrdineEAndareAlMenu;
    [Test]
    procedure DovrebbeSaltareSoloLAnimazioneCorrenteConUnTasto;
    [Test]
    procedure DovrebbeSaltareTuttoConEsc;
    [Test]
    procedure DovrebbeIgnorareUnTastoModificatore;
    [Test]
    procedure DovrebbePassareOltreUnaAnimazioneMancanteOGuasta;
    [Test]
    procedure DovrebbeDisegnareLImmagineDellAnimazione;
    [Test]
    procedure DovrebbeDareALaScenaIlTempoRealeInMillisecondi;
    [Test]
    procedure DovrebbeAndareAlMenuSeNonCiSonoAnimazioni;
    [Test]
    procedure DovrebbeFareSeguireLIntroduzioneAlLogoSoloSeRichiesto;
    [Test]
    procedure DovrebbeLasciareInerteIlTastoSenzaAnimazioni;
    [Test]
    procedure DovrebbeFareSuonareLIntroduzioneDalTastoDelMenu;
    [Test]
    procedure DovrebbeSalvareELeggereIlFlagDellIntroduzione;
    [Test]
    procedure DovrebbeLeggereUnSalvataggioVecchioSenzaIntroduzione;
    [Test]
    procedure DovrebbeLeggereLOpzioneNointro;
    [Test]
    procedure DovrebbeSuonareLeAnimazioniVereDelGiocoDosSeCiSono;
  end;

implementation

uses
  DelphiDoom.Cinematic.Flic.Types, DelphiDoom.War.Ui.Intf, DelphiDoom.War.Types,
  DelphiDoom.War.Ui.Factory, DelphiDoom.War.Factory, DelphiDoom.War.Campaign.Catalog, DelphiDoom.War.Ui.SceneBase,
  DelphiDoom.War.Ui.SceneCinematics, DelphiDoom.War.Save.Types, DelphiDoom.War.Save.Writer, DelphiDoom.War.Save.Reader,
  DelphiDoom.War.App.Options, DelphiDoom.War.App.OptionsParser, DelphiDoom.War.Cinematic.Factory,
  DelphiDoom.Cinematic.Flic.SceneFactory, DelphiDoom.War.Sound.Factory, DelphiDoom.War.Sound.SeededRandom,
  DUnitX.Exceptions, DelphiDoom.Tests.War.RealData;

const
  // the main menu button "Replay introduction"
  REPLAY_X = 150;
  REPLAY_Y = 132;

{ TFakeFlicScene }

constructor TFakeFlicScene.Create(const AName: string; ALength: Integer; const ALog: TStrings);
begin
  inherited Create;
  FName := AName;
  FLength := ALength;
  FLog := ALog;
end;

function TFakeFlicScene.GetName: string;
begin
  Result := FName;
end;

function TFakeFlicScene.GetState: TFlicSceneState;
begin
  Result := FState;
end;

function TFakeFlicScene.Update(AMilliseconds: Integer; ASkipRequested: Boolean): TFlicSceneFrame;
begin
  Result := Default(TFlicSceneFrame);
  if FState in [fssEnded, fssSkipped] then
  begin
    Result.State := FState;
    Exit;
  end;
  FState := fssPlaying;
  Inc(FUpdates);
  FLog.Add(Format('update %s %d %s', [FName, AMilliseconds, BoolToStr(ASkipRequested, True)]));
  if ASkipRequested then
    FState := fssSkipped
  else if (FLength > 0) and (FUpdates >= FLength) then
    FState := fssEnded;
  Result.State := FState;
  Result.FrameChanged := True;
  // a picture of 2 x 2 red pixels $AABBGGRR
  Result.Image.Width := 2;
  Result.Image.Height := 2;
  SetLength(Result.Image.Pixels, 4);
  Result.Image.Pixels[0] := $FF0000FF;
  Result.Image.Pixels[1] := $FF0000FF;
  Result.Image.Pixels[2] := $FF0000FF;
  Result.Image.Pixels[3] := $FF0000FF;
end;

{ TFakeDirector }

constructor TFakeDirector.Create(const ALog: TStrings; const AMissing: string; const ABroken: string);
begin
  inherited Create;
  FLog := ALog;
  FMissing := AMissing;
  FBroken := ABroken;
end;

function TFakeDirector.TryOpen(const AName: string; APlayerRace: TWarRace): IFlicScene;
begin
  FLog.Add('open ' + AName);
  if (FMissing = '*') or SameText(AName, FMissing) then
    Result := nil
  else if SameText(AName, FBroken) then
    raise EFlicInvalidDataException.Create('not a FLIC')
  else if SameText(AName, 'CAVE1') then
    Result := TFakeFlicScene.Create(AName, 3, FLog)
  else if SameText(AName, 'CAVE2') then
    Result := TFakeFlicScene.Create(AName, 0, FLog)
  else if SameText(AName, 'CAVE3') then
    Result := TFakeFlicScene.Create(AName, 2, FLog)
  else if SameText(AName, 'TITLE') then
    Result := TFakeFlicScene.Create(AName, 2, FLog)
  else
    Result := nil;
end;

{ TTestWarUiCinematics }

procedure TTestWarUiCinematics.Setup;
begin
  FSprites := TFakeUiSprites.Create;
  FSpritesRef := FSprites;
  FLog := TStringList.Create;
end;

procedure TTestWarUiCinematics.TearDown;
begin
  FreeAndNil(FGame);
  FreeAndNil(FLog);
  FSpritesRef := nil;
end;

procedure TTestWarUiCinematics.NewGame(const ACinematics: IWarCinematicDirector; AIntroductionAfterLogo: Boolean);
begin
  FreeAndNil(FGame);
  FGame := TWarUiFactory.CreateGameOnSprites(FSpritesRef as IWarUiSprites, TWarFactory.CreateFontMetrics,
    TFakeUiRig.FontImages, TWarCampaigns.Create, nil, nil, False, 320, 200, nil, ACinematics, AIntroductionAfterLogo);
end;

procedure TTestWarUiCinematics.Tick(ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
  begin
    FGame.Manager.RunFrame(Single(1) / Single(60));
    FGame.Manager.BeginInputFrame;
  end;
end;

procedure TTestWarUiCinematics.PressKey(AKey: TWarKey);
begin
  FGame.Input.SetKey(AKey, True);
  FGame.Input.SetKey(AKey, False);
  Tick;
end;

procedure TTestWarUiCinematics.Click(AX, AY: Single);
begin
  FGame.Input.SetPosition(AX, AY);
  FGame.Input.SetButton(wmbLeft, True);
  Tick;
  FGame.Input.SetButton(wmbLeft, False);
  Tick;
end;

function TTestWarUiCinematics.SceneKind: TWarSceneType;
begin
  Result := FGame.Manager.Scene.SceneType;
end;

procedure TTestWarUiCinematics.DovrebbeSuonareLeAnimazioniInOrdineEAndareAlMenu;
begin
  NewGame(TFakeDirector.Create(FLog), False);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateIntroduction, 0);
  Tick(8);
  Assert.AreEqual(Ord(wstCinematics), Ord(SceneKind), 'CAVE1 ha tre aggiornamenti, poi CAVE2 resta in ciclo');
  PressKey(wkSpace);
  // CAVE3 e TITLE hanno due aggiornamenti l'una, poi 0,3 secondi di nero prima del menu
  Tick(30);
  Assert.AreEqual(Ord(wstMainMenu), Ord(SceneKind), 'dopo CAVE3 e TITLE il menu');
  Assert.AreEqual('open CAVE1', FLog[0]);
  Assert.IsTrue(FLog.IndexOf('open CAVE2') < FLog.IndexOf('open CAVE3'));
  Assert.IsTrue(FLog.IndexOf('open CAVE3') < FLog.IndexOf('open TITLE'));
end;

procedure TTestWarUiCinematics.DovrebbeSaltareSoloLAnimazioneCorrenteConUnTasto;
begin
  NewGame(TFakeDirector.Create(FLog), False);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateIntroduction, 0);
  Tick;
  PressKey(wkEnter);
  Assert.IsTrue(FLog.IndexOf('open CAVE2') >= 0, 'CAVE1 saltata: parte CAVE2');
  Assert.AreEqual(Ord(wstCinematics), Ord(SceneKind));
end;

procedure TTestWarUiCinematics.DovrebbeSaltareTuttoConEsc;
begin
  NewGame(TFakeDirector.Create(FLog), False);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateIntroduction, 0);
  Tick;
  PressKey(wkEsc);
  Tick;
  Assert.AreEqual(Ord(wstMainMenu), Ord(SceneKind));
  Assert.AreEqual(-1, FLog.IndexOf('open CAVE2'), 'Esc non apre le altre');
end;

procedure TTestWarUiCinematics.DovrebbeIgnorareUnTastoModificatore;
begin
  NewGame(TFakeDirector.Create(FLog), False);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateIntroduction, 0);
  Tick;
  PressKey(wkEnter);
  Assert.IsTrue(FLog.IndexOf('open CAVE2') >= 0, 'CAVE1 saltata, CAVE2 in ciclo');
  PressKey(wkShift);
  PressKey(wkCtrl);
  PressKey(wkAlt);
  Tick(5);
  Assert.AreEqual(-1, FLog.IndexOf('open CAVE3'), 'un modificatore non salta');
end;

procedure TTestWarUiCinematics.DovrebbePassareOltreUnaAnimazioneMancanteOGuasta;
begin
  // CAVE1 non c'e', CAVE2 e' un file che non e' un'animazione: si passa a CAVE3
  NewGame(TFakeDirector.Create(FLog, 'CAVE1', 'CAVE2'), False);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateIntroduction, 0);
  Tick(3);
  Assert.IsTrue(FLog.IndexOf('open CAVE1') >= 0);
  Assert.IsTrue(FLog.IndexOf('open CAVE2') >= 0);
  Assert.IsTrue(FLog.IndexOf('open CAVE3') >= 0, 'la terza animazione parte');
  Assert.AreEqual(Ord(wstCinematics), Ord(SceneKind));
end;

procedure TTestWarUiCinematics.DovrebbeDisegnareLImmagineDellAnimazione;
begin
  NewGame(TFakeDirector.Create(FLog), False);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateIntroduction, 0);
  Tick(2);
  // l'immagine di 2 x 2 pixel rossi riempie lo schermo
  // (non il pixel 0, 0: ci sta il cursore del mouse)
  Assert.AreEqual(255, Integer(FGame.Canvas.Blitter.Pixels[(100 * 320 + 100) * 4]));
  Assert.AreEqual(0, Integer(FGame.Canvas.Blitter.Pixels[(100 * 320 + 100) * 4 + 1]));
  Assert.AreEqual(0, Integer(FGame.Canvas.Blitter.Pixels[(100 * 320 + 100) * 4 + 2]));
  Assert.AreEqual(255, Integer(FGame.Canvas.Blitter.Pixels[(199 * 320 + 319) * 4]));
end;

procedure TTestWarUiCinematics.DovrebbeDareALaScenaIlTempoRealeInMillisecondi;
var
  LFirst: Integer;
  LThird: Integer;
  LIndex: Integer;
  LParts: TArray<string>;
begin
  NewGame(TFakeDirector.Create(FLog), False);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateIntroduction, 0);
  Tick(3);
  LFirst := -1;
  LThird := -1;
  for LIndex := 0 to FLog.Count - 1 do
    if FLog[LIndex].StartsWith('update CAVE1') then
    begin
      LParts := FLog[LIndex].Split([' ']);
      if LFirst < 0 then
        LFirst := StrToInt(LParts[2])
      else
        LThird := StrToInt(LParts[2]);
    end;
  Assert.IsTrue(LThird >= 0, 'tre aggiornamenti');
  // due fotogrammi a 1/60 di secondo: 33 millisecondi (arrotondati)
  Assert.AreEqual(33, LThird - LFirst, 1);
end;

procedure TTestWarUiCinematics.DovrebbeAndareAlMenuSeNonCiSonoAnimazioni;
begin
  NewGame(TFakeDirector.Create(FLog, '*'), False);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateIntroduction, 0);
  Tick(3);
  Assert.AreEqual(Ord(wstMainMenu), Ord(SceneKind));
end;

procedure TTestWarUiCinematics.DovrebbeFareSeguireLIntroduzioneAlLogoSoloSeRichiesto;
begin
  NewGame(TFakeDirector.Create(FLog), True);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateBlizzard, 0);
  Tick(215);
  Assert.AreEqual(Ord(wstCinematics), Ord(SceneKind), 'con il flag il logo va all''introduzione');
  NewGame(TFakeDirector.Create(FLog), False);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateBlizzard, 0);
  Tick(215);
  Assert.AreEqual(Ord(wstMainMenu), Ord(SceneKind), 'senza il flag va al menu, come l''originale');
  NewGame(nil, True);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateBlizzard, 0);
  Tick(215);
  Assert.AreEqual(Ord(wstMainMenu), Ord(SceneKind), 'senza animazioni il flag non conta');
end;

procedure TTestWarUiCinematics.DovrebbeLasciareInerteIlTastoSenzaAnimazioni;
begin
  NewGame(nil, False);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateMainMenu, 0);
  Tick(2);
  Click(REPLAY_X, REPLAY_Y);
  Tick(30);
  Assert.AreEqual(Ord(wstMainMenu), Ord(SceneKind));
end;

procedure TTestWarUiCinematics.DovrebbeFareSuonareLIntroduzioneDalTastoDelMenu;
begin
  NewGame(TFakeDirector.Create(FLog), False);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateMainMenu, 0);
  Tick(2);
  Click(REPLAY_X, REPLAY_Y);
  Tick(30);
  Assert.AreEqual(Ord(wstCinematics), Ord(SceneKind));
  Assert.AreEqual('open CAVE1', FLog[0]);
end;

procedure TTestWarUiCinematics.DovrebbeSalvareELeggereIlFlagDellIntroduzione;
var
  LContent: TWarSaveContent;
  LRead: TWarSaveContent;
begin
  LContent := Default(TWarSaveContent);
  LContent.Seed := 7;
  LContent.DataSize := 100;
  LContent.Introduction := True;
  LRead := TWarSaveReader.Read(TWarSaveWriter.Write(LContent), 100);
  Assert.IsTrue(LRead.Introduction);
  LContent.Introduction := False;
  LRead := TWarSaveReader.Read(TWarSaveWriter.Write(LContent), 100);
  Assert.IsFalse(LRead.Introduction);
end;

procedure TTestWarUiCinematics.DovrebbeLeggereUnSalvataggioVecchioSenzaIntroduzione;
var
  LContent: TWarSaveContent;
  LBytes: TBytes;
  LFlags: Word;
begin
  LContent := Default(TWarSaveContent);
  LContent.DataSize := 100;
  LBytes := TWarSaveWriter.Write(LContent);
  // il campo che prima era "riservato" e' zero in un gioco senza introduzione: gli stessi byte di prima
  Move(LBytes[SizeOf(TWarSaveHeader) - 10], LFlags, SizeOf(LFlags));
  Assert.AreEqual(0, Integer(LFlags));
  Assert.IsFalse(TWarSaveReader.Read(LBytes, 100).Introduction);
end;

procedure TTestWarUiCinematics.DovrebbeLeggereLOpzioneNointro;
var
  LOptions: TWarAppOptions;
  LError: string;
begin
  Assert.IsTrue(TWarAppOptionsParser.TryParse([], LOptions, LError));
  Assert.IsFalse(LOptions.NoIntroduction);
  Assert.IsTrue(TWarAppOptionsParser.TryParse(['-nointro'], LOptions, LError));
  Assert.IsTrue(LOptions.NoIntroduction);
end;


procedure TTestWarUiCinematics.DovrebbeSuonareLeAnimazioniVereDelGiocoDosSeCiSono;
var
  LDirector: IWarCinematicDirector;
  LFolder: string;
  LFrames: Integer;
  LSeen: Boolean;
  LIndex: Integer;
begin
  LFolder := ExtractFilePath(TWarRealData.RequireDataWar);
  if not FileExists(LFolder + 'CAVE1.WAR') then
    raise ETestIgnored.Create('i file delle animazioni del gioco DOS non ci sono: prova ignorata');
  LDirector := TWarCinematicFactory.CreateDirector(TFlicSceneFactory.CreateMaker(TFlicSceneFactory.CreateFolderSource(
    LFolder, '.WAR')), nil, TWarSoundFactory.CreatePicker(TWarSeededRandom.Create(1)));
  NewGame(LDirector, False);
  FGame.Manager.SetNextScene(FGame.Scenes.CreateIntroduction, 0);
  LSeen := False;
  Tick;
  LFrames := 0;
  // un tasto ogni mezzo secondo porta in fondo alla sequenza (CAVE2 e'' un ciclo); dopo ogni salto un fotogramma di prova
  while (SceneKind <> wstMainMenu) and (LFrames < 20000) do
  begin
    Tick;
    Inc(LFrames);
    if SceneKind = wstCinematics then
      for LIndex := 0 to 320 * 200 - 1 do
        if FGame.Canvas.Blitter.Pixels[LIndex * 4 + 1] <> 0 then
        begin
          LSeen := True;
          Break;
        end;
    if LFrames mod 30 = 0 then
      PressKey(wkSpace);
  end;
  Assert.AreEqual(Ord(wstMainMenu), Ord(SceneKind), 'la sequenza finisce al menu');
  Assert.IsTrue(LSeen, 'almeno un fotogramma non e'' nero');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarUiCinematics);

end.
