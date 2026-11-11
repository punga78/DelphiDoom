{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the options of the xcom menus (the options class,  }
{  the stores, the languages and the options screens)                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.OptionsScreens;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Yaml.Factory, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.OptionsStore.Intf,
  DelphiDoom.XcomEngine.LanguageProvider.Intf, DelphiDoom.XcomEngine.FileOptionsStore,
  DelphiDoom.XcomEngine.FolderLanguageProvider, DelphiDoom.XcomMenu.OptionsTypes,
  DelphiDoom.XcomMenu.OptionsNavigator.Intf, DelphiDoom.XcomMenu.OptionsVideoState, DelphiDoom.XcomMenu.OptionsAudioState,
  DelphiDoom.XcomMenu.OptionsConfirmState, DelphiDoom.Tests.XcomEngine.World;

type
  TFlatState = class(TXcomState)
  end;

  TFakeStore = class(TInterfacedObject, IXcomOptionsStore)
  public
    Saves: Integer;
    Loads: Integer;
    procedure Load(AOptions: TXcomOptions);
    procedure Save(AOptions: TXcomOptions);
  end;

  TFakeNavigator = class(TInterfacedObject, IXcomOptionsNavigator)
  public
    Restarts: Integer;
    Created: TXcomOptionsCategory;
    function CreateCategory(ACategory: TXcomOptionsCategory; AOrigin: TXcomOptionsOrigin;
      AHost: TXcomStateHost): TXcomState;
    procedure Restart(AOrigin: TXcomOptionsOrigin; AHost: TXcomStateHost);
  end;

  TFolderProviderForScreens = class(TInterfacedObject, IXcomLanguageProvider)
  public
    procedure List(out ACodes, ANames: TArray<string>);
    function Load(const ALanguageId: string; AWordwrap: TXcomTextWrapping;
      const AResources: IXcomResources): TXcomLanguage;
  end;

  TFakeAudio = class(TInterfacedObject, IXcomAudioDevice)
  public
    Waves: Integer;
    Sound: Integer;
    Music: Integer;
    Ui: Integer;
    function IsAvailable: Boolean;
    procedure SetVolume(ASound, AMusic, AUi: Integer);
    procedure PlayWave(const AWave: TBytes);
  end;

  TFakeModes = class(TInterfacedObject, IXcomDisplayModes)
  public
    function Modes: TArray<TXcomDisplayMode>;
  end;

  [TestFixture]
  [Category('XcomOptions')]
  TTestXcomOptions = class
  public
    [Test]
    procedure SwitchDisplayScambiaICorrentiConIPendenti;
    [Test]
    procedure SwitchDisplayDuePulteRiportaAllOriginale;
    [Test]
    procedure IlCaricamentoAllineaIPendenti;
    [Test]
    procedure IlSalvataggioEIlCaricamentoTornano;
    [Test]
    procedure LeImpostazioniDiPartenzaHannoIPendentiUguali;
  end;

  [TestFixture]
  [Category('XcomOptions')]
  TTestXcomLanguageProvider = class
  strict private
    FFiles: TFakeFileSystem;
    FFilesRef: IXcomFileSystem;
    FProvider: IXcomLanguageProvider;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure ElencaIFileConIlNomeDellaLingua;
    [Test]
    procedure CaricaSopraEnUS;
    [Test]
    procedure UnaLinguaSenzaFileRestaEnUS;
    [Test]
    procedure IlNomeDiUnaLinguaSconosciutaELSuoCodice;
    [Test]
    procedure ILNomiSonoQuelliDelMenu;
  end;

  [TestFixture]
  [Category('XcomOptions')]
  TTestXcomOptionsAudio = class
  strict private
    FWorld: TTestWorld;
    FAudio: TFakeAudio;
    FAudioRef: IXcomAudioDevice;
    FNavigator: TFakeNavigator;
    FNavigatorRef: IXcomOptionsNavigator;
    procedure Open;
    procedure ClickAt(AX, AY: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure ElSliderDelVolumeDellaMusicaImpostaLOpzioneEIlVolume;
    [Test]
    procedure ILFormatoDellaMusicaChiedeIlRicaricamento;
    [Test]
    procedure IlSilenzioInSecondoPianoSiImposta;
    [Test]
    procedure ISlidersPartonoDalleOpzioni;
    [Test]
    procedure RilasciareIlCursoreDeiSuoniFaSuonareLaProva;
    [Test]
    procedure RilasciareIlCursoreDellInterfacciaFaSuonareIlPulsante;
    [Test]
    procedure RilasciareIlCursoreDellaMusicaNonFaSuonareNulla;
    [Test]
    procedure SenzaIlSuonoNelleRisorseNonSuonaNulla;
  end;

  [TestFixture]
  [Category('XcomOptions')]
  TTestXcomOptionsScreens = class
  strict private
    FWorld: TTestWorld;
    FStore: TFakeStore;
    FStoreRef: IXcomOptionsStore;
    FNavigator: TFakeNavigator;
    FNavigatorRef: IXcomOptionsNavigator;
    FState: TXcomOptionsVideoState;
    procedure Open;
    /// <summary>A click at a place of the 320 x 200 game picture, scaled to the display</summary>
    procedure ClickAt(AX, AY: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure MostraLaRisoluzioneCorrente;
    [Test]
    procedure LaModalitaSceltaVaNeiPendenti;
    [Test]
    procedure IlFiltroSceltoVaNeiPendenti;
    [Test]
    procedure LeFreccePassanoITraIModi;
    [Test]
    procedure ScrivereLaLarghezzaAggiornaIPendenti;
    [Test]
    procedure OkSalvaERitornaSeNullaCambia;
    [Test]
    procedure OkChiedeLaConfermaSeLaRisoluzioneCambia;
    [Test]
    procedure LaConfermaConta15SecondiEPoAnnulla;
    [Test]
    procedure SiAccettaLaConfermaRestaConLeNuoveImpostazioni;
    [Test]
    procedure AnnullaRicaricaLeOpzioni;
    [Test]
    procedure RipristinareIPredefinitiChiedeEFa;
    [Test]
    procedure UnaCategoriaNonPortataNonChiudeLaSchermata;
  end;

implementation

procedure TFakeStore.Load(AOptions: TXcomOptions);
begin
  Inc(Loads);
end;

procedure TFakeStore.Save(AOptions: TXcomOptions);
begin
  Inc(Saves);
end;

function TFakeNavigator.CreateCategory(ACategory: TXcomOptionsCategory; AOrigin: TXcomOptionsOrigin;
  AHost: TXcomStateHost): TXcomState;
begin
  Created := ACategory;
  Result := nil;
end;

procedure TFakeNavigator.Restart(AOrigin: TXcomOptionsOrigin; AHost: TXcomStateHost);
begin
  Inc(Restarts);
end;

procedure TFolderProviderForScreens.List(out ACodes, ANames: TArray<string>);
begin
  ACodes := ['en-US', 'it'];
  ANames := ['English (US)', 'Italiano'];
end;

function TFolderProviderForScreens.Load(const ALanguageId: string; AWordwrap: TXcomTextWrapping;
  const AResources: IXcomResources): TXcomLanguage;
begin
  Result := TXcomLanguage.Create(ALanguageId, AWordwrap, nil, nil);
end;

function TFakeAudio.IsAvailable: Boolean;
begin
  Result := True;
end;

procedure TFakeAudio.PlayWave(const AWave: TBytes);
begin
  Inc(Waves);
end;

procedure TFakeAudio.SetVolume(ASound, AMusic, AUi: Integer);
begin
  Sound := ASound;
  Music := AMusic;
  Ui := AUi;
end;

function TFakeModes.Modes: TArray<TXcomDisplayMode>;
begin
  SetLength(Result, 3);
  Result[0].Width := 1024;
  Result[0].Height := 768;
  Result[1].Width := 800;
  Result[1].Height := 600;
  Result[2].Width := 640;
  Result[2].Height := 400;
end;

{ TTestXcomOptions }

procedure TTestXcomOptions.LeImpostazioniDiPartenzaHannoIPendentiUguali;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    Assert.AreEqual(LOptions.DisplayWidth, LOptions.NewDisplayWidth);
    Assert.AreEqual(LOptions.GeoscapeScale, LOptions.NewGeoscapeScale);
    Assert.AreEqual(LOptions.Fullscreen, LOptions.NewFullscreen);
    Assert.AreEqual(3, LOptions.MousewheelSpeed);
    Assert.IsTrue(LOptions.KeyboardMode = kmOn);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptions.SwitchDisplayScambiaICorrentiConIPendenti;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.NewDisplayWidth := 1024;
    LOptions.NewDisplayHeight := 768;
    LOptions.NewFullscreen := True;
    LOptions.NewGeoscapeScale := 2;
    LOptions.NewOpenGLShader := 'x';
    LOptions.NewWindowedModePositionX := 7;
    LOptions.SwitchDisplay;
    Assert.AreEqual(1024, LOptions.DisplayWidth);
    Assert.AreEqual(640, LOptions.NewDisplayWidth);
    Assert.AreEqual(768, LOptions.DisplayHeight);
    Assert.IsTrue(LOptions.Fullscreen);
    Assert.IsFalse(LOptions.NewFullscreen);
    Assert.AreEqual(2, LOptions.GeoscapeScale);
    Assert.AreEqual('x', LOptions.UseOpenGLShader);
    Assert.AreEqual(7, LOptions.WindowedModePositionX);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptions.SwitchDisplayDuePulteRiportaAllOriginale;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.NewDisplayWidth := 1024;
    LOptions.NewBorderless := True;
    LOptions.SwitchDisplay;
    LOptions.SwitchDisplay;
    Assert.AreEqual(640, LOptions.DisplayWidth);
    Assert.AreEqual(1024, LOptions.NewDisplayWidth);
    Assert.IsFalse(LOptions.Borderless);
    Assert.IsTrue(LOptions.NewBorderless);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptions.IlCaricamentoAllineaIPendenti;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.NewDisplayWidth := 5;
    LOptions.Load(TTestWorld.Parse('options:'#10'  displayWidth: 800'#10'  fullscreen: true'#10 +
      '  geoscapeScale: 3'#10));
    Assert.AreEqual(800, LOptions.DisplayWidth);
    Assert.AreEqual(800, LOptions.NewDisplayWidth);
    Assert.IsTrue(LOptions.NewFullscreen);
    Assert.AreEqual(3, LOptions.NewGeoscapeScale);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptions.IlSalvataggioEIlCaricamentoTornano;
var
  LFiles: TFakeFileSystem;
  LFilesRef: IXcomFileSystem;
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
  LCopy: TXcomOptions;
begin
  LFiles := TFakeFileSystem.Create;
  LFilesRef := LFiles;
  LStore := TXcomFileOptionsStore.Create(LFilesRef, TYamlFactory.CreateParser, 'user');
  LOptions := TXcomOptions.Create;
  LCopy := TXcomOptions.Create;
  try
    // nothing to read: the options stay as they are
    LStore.Load(LCopy);
    Assert.AreEqual(640, LCopy.DisplayWidth);
    LOptions.DisplayWidth := 1280;
    LOptions.RootWindowedMode := True;
    LOptions.WindowedModePositionX := 40;
    LOptions.CaptureMouse := True;
    LOptions.MousewheelSpeed := 6;
    LOptions.Language := 'it';
    LStore.Save(LOptions);
    LStore.Load(LCopy);
    Assert.AreEqual(1280, LCopy.DisplayWidth);
    Assert.IsTrue(LCopy.RootWindowedMode);
    Assert.AreEqual(40, LCopy.WindowedModePositionX);
    Assert.IsTrue(LCopy.CaptureMouse);
    Assert.AreEqual(6, LCopy.MousewheelSpeed);
    Assert.AreEqual('it', LCopy.Language);
  finally
    LCopy.Free;
    LOptions.Free;
  end;
end;

{ TTestXcomLanguageProvider }

procedure TTestXcomLanguageProvider.Setup;
begin
  FFiles := TFakeFileSystem.Create;
  FFilesRef := FFiles;
  FFiles.Put('data\common\Language\en-US.yml', 'en-US:'#10'  STR_OK: "OK"'#10'  STR_YES: "Yes"'#10);
  FFiles.Put('data\common\Language\de.yml', 'de:'#10'  STR_OK: "Gut"'#10);
  FFiles.Put('data\common\Language\it.yml', 'it:'#10'  STR_OK: "Va bene"'#10);
  FFiles.Put('data\common\Language\xx.yml', 'xx:'#10'  STR_OK: "xx"'#10);
  FFiles.Put('data\standard\xcom2\Language\en-US.yml', 'en-US:'#10'  STR_MOD: "Mod"'#10);
  FProvider := TXcomFolderLanguageProvider.Create('data', 'data\standard\xcom2', FFilesRef,
    TYamlFactory.CreateParser);
end;

procedure TTestXcomLanguageProvider.TearDown;
begin
  FProvider := nil;
  FFilesRef := nil;
end;

procedure TTestXcomLanguageProvider.ElencaIFileConIlNomeDellaLingua;
var
  LCodes: TArray<string>;
  LNames: TArray<string>;
begin
  FProvider.List(LCodes, LNames);
  // the fake file system does not keep the case of the names, the disk one does
  Assert.AreEqual(4, Length(LCodes));
  Assert.AreEqual('de', LCodes[0]);
  Assert.AreEqual('Deutsch', LNames[0]);
  Assert.AreEqual('it', LCodes[2]);
  Assert.AreEqual('Italiano', LNames[2]);
  Assert.AreEqual('xx', LNames[3]);
end;

procedure TTestXcomLanguageProvider.CaricaSopraEnUS;
var
  LLanguage: TXcomLanguage;
begin
  LLanguage := FProvider.Load('it', twAuto, nil);
  try
    Assert.AreEqual('it', LLanguage.LanguageId);
    Assert.AreEqual('Va bene', string(LLanguage.GetString('STR_OK')));
    // what the language does not have comes from en-US, and the mod adds its own
    Assert.AreEqual('Yes', string(LLanguage.GetString('STR_YES')));
    Assert.AreEqual('Mod', string(LLanguage.GetString('STR_MOD')));
  finally
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguageProvider.UnaLinguaSenzaFileRestaEnUS;
var
  LLanguage: TXcomLanguage;
begin
  LLanguage := FProvider.Load('zz', twAuto, nil);
  try
    Assert.AreEqual('en-US', LLanguage.LanguageId);
  finally
    LLanguage.Free;
  end;
  LLanguage := FProvider.Load('', twAuto, nil);
  try
    Assert.AreEqual('en-US', LLanguage.LanguageId);
  finally
    LLanguage.Free;
  end;
end;

procedure TTestXcomLanguageProvider.IlNomeDiUnaLinguaSconosciutaELSuoCodice;
begin
  Assert.AreEqual('zz', TXcomLanguage.NameOf('zz'));
end;

procedure TTestXcomLanguageProvider.ILNomiSonoQuelliDelMenu;
begin
  Assert.AreEqual('Deutsch', TXcomLanguage.NameOf('de'));
  Assert.AreEqual('Fran' + #$E7 + 'ais (FR)', TXcomLanguage.NameOf('fr'));
  Assert.AreEqual(#$0420#$0443#$0441#$0441#$043A#$0438#$0439, TXcomLanguage.NameOf('ru'));
  Assert.AreEqual('Portugu' + #$EA + 's (BR)', TXcomLanguage.NameOf('pt-BR'));
end;

{ TTestXcomOptionsAudio }

procedure TTestXcomOptionsAudio.Setup;
begin
  FWorld := TTestWorld.Create;
  FAudio := TFakeAudio.Create;
  FAudioRef := FAudio;
  FNavigator := TFakeNavigator.Create;
  FNavigatorRef := FNavigator;
  FWorld.Game.SetAudioDevice(FAudioRef);
end;

procedure TTestXcomOptionsAudio.TearDown;
begin
  FNavigatorRef := nil;
  FAudioRef := nil;
  FWorld.Free;
end;

procedure TTestXcomOptionsAudio.ClickAt(AX, AY: Integer);
begin
  FWorld.Click(Round(AX * FWorld.Game.Screen.XScale), Round(AY * FWorld.Game.Screen.YScale));
end;

procedure TTestXcomOptionsAudio.Open;
begin
  FWorld.Game.PushState(TXcomOptionsAudioState.Create(FWorld.Game, ooMenu, FNavigatorRef));
  FWorld.Wait(400);
end;

procedure TTestXcomOptionsAudio.RilasciareIlCursoreDeiSuoniFaSuonareLaProva;
begin
  FWorld.Resources.Wave := [1, 2, 3];
  Open;
  // the slider of the sounds is at 94,50
  ClickAt(150, 58);
  Assert.AreEqual(1, FAudio.Waves);
end;

procedure TTestXcomOptionsAudio.RilasciareIlCursoreDellInterfacciaFaSuonareIlPulsante;
begin
  FWorld.Resources.Wave := [1, 2, 3];
  Open;
  // the slider of the interface is at 94,82
  ClickAt(150, 90);
  Assert.AreEqual(1, FAudio.Waves);
end;

procedure TTestXcomOptionsAudio.RilasciareIlCursoreDellaMusicaNonFaSuonareNulla;
begin
  FWorld.Resources.Wave := [1, 2, 3];
  Open;
  ClickAt(150, 26);
  Assert.AreEqual(0, FAudio.Waves);
end;

procedure TTestXcomOptionsAudio.SenzaIlSuonoNelleRisorseNonSuonaNulla;
begin
  Open;
  ClickAt(150, 58);
  Assert.AreEqual(0, FAudio.Waves);
end;

procedure TTestXcomOptionsAudio.ISlidersPartonoDalleOpzioni;
begin
  Assert.AreEqual(84, FWorld.Game.Options.MusicVolume);
  Open;
  // nothing changes until a slider is moved
  Assert.AreEqual(84, FWorld.Game.Options.MusicVolume);
  Assert.AreEqual(0, FAudio.Music);
end;

procedure TTestXcomOptionsAudio.ElSliderDelVolumeDellaMusicaImpostaLOpzioneEIlVolume;
begin
  Open;
  // the slider of the music is at 94,18 (104 wide): a click at its right end gives the maximum
  ClickAt(196, 26);
  Assert.AreEqual(128, FWorld.Game.Options.MusicVolume);
  Assert.AreEqual(128, FAudio.Music);
  Assert.AreEqual(FWorld.Game.Options.SoundVolume, FAudio.Sound);
end;

procedure TTestXcomOptionsAudio.ILFormatoDellaMusicaChiedeIlRicaricamento;
begin
  Open;
  // the combo of the music format is at 206,50; its list opens below, 9 pixels a row from 69
  ClickAt(258, 58);
  ClickAt(258, 91);
  FWorld.Wait(50);
  Assert.AreEqual(2, FWorld.Game.Options.PreferredMusic);
  Assert.IsTrue(FWorld.Game.Options.Reload);
end;

procedure TTestXcomOptionsAudio.IlSilenzioInSecondoPianoSiImposta;
begin
  Open;
  ClickAt(146, 122);
  Assert.IsTrue(FWorld.Game.Options.BackgroundMute);
  ClickAt(146, 122);
  Assert.IsFalse(FWorld.Game.Options.BackgroundMute);
end;

{ TTestXcomOptionsScreens }

procedure TTestXcomOptionsScreens.ClickAt(AX, AY: Integer);
begin
  // the screen follows the video options: after OK the window can be of another size
  FWorld.Click(Round(AX * FWorld.Game.Screen.XScale), Round(AY * FWorld.Game.Screen.YScale));
end;

procedure TTestXcomOptionsScreens.Open;
begin
  // the game owns the state from here; the popups need time to open
  FWorld.Game.PushState(FState);
  FState := nil;
  FWorld.Wait(400);
end;

procedure TTestXcomOptionsScreens.Setup;
begin
  FWorld := TTestWorld.Create;
  FStore := TFakeStore.Create;
  FStoreRef := FStore;
  FNavigator := TFakeNavigator.Create;
  FNavigatorRef := FNavigator;
  FWorld.Game.SetOptionsStore(FStoreRef);
  FWorld.Game.SetDisplayModes(TFakeModes.Create);
  FWorld.Game.SetLanguageProvider(TFolderProviderForScreens.Create);
  FState := TXcomOptionsVideoState.Create(FWorld.Game, ooMenu, FNavigatorRef);
end;

procedure TTestXcomOptionsScreens.TearDown;
begin
  FState.Free;
  FNavigatorRef := nil;
  FStoreRef := nil;
  FWorld.Free;
end;

procedure TTestXcomOptionsScreens.MostraLaRisoluzioneCorrente;
begin
  // the pending resolution starts equal to the current one
  Assert.AreEqual(FWorld.Game.Options.DisplayWidth, FWorld.Game.Options.NewDisplayWidth);
  Assert.AreEqual(Ord(ooMenu), Ord(FState.Origin));
end;

procedure TTestXcomOptionsScreens.LaModalitaSceltaVaNeiPendenti;
begin
  Open;
  // the combo of the display mode is at 206,32; its list opens below it, 9 pixels a row from 51
  ClickAt(258, 40);
  ClickAt(258, 64);
  FWorld.Wait(50);
  Assert.IsTrue(FWorld.Game.Options.NewFullscreen);
  Assert.IsFalse(FWorld.Game.Options.NewBorderless);
  Assert.IsFalse(FWorld.Game.Options.Fullscreen);
end;

procedure TTestXcomOptionsScreens.IlFiltroSceltoVaNeiPendenti;
begin
  Open;
  ClickAt(258, 70);
  ClickAt(258, 94);
  FWorld.Wait(50);
  Assert.IsTrue(FWorld.Game.Options.NewScaleFilter);
  Assert.IsFalse(FWorld.Game.Options.NewHQXFilter);
  Assert.IsFalse(FWorld.Game.Options.UseScaleFilter);
end;

procedure TTestXcomOptionsScreens.LeFreccePassanoITraIModi;
begin
  Open;
  // the arrow down at 186,36 chooses the next mode of the display, and the pending options follow
  ClickAt(193, 43);
  // the window is 640 x 400: the current mode is the last of the list, so down wraps to the first
  Assert.AreEqual(1024, FWorld.Game.Options.NewDisplayWidth);
  Assert.AreEqual(768, FWorld.Game.Options.NewDisplayHeight);
  ClickAt(193, 43);
  Assert.AreEqual(800, FWorld.Game.Options.NewDisplayWidth);
  ClickAt(193, 43);
  Assert.AreEqual(640, FWorld.Game.Options.NewDisplayWidth);
  // and the arrow up goes the other way
  ClickAt(193, 25);
  Assert.AreEqual(800, FWorld.Game.Options.NewDisplayWidth);
end;

procedure TTestXcomOptionsScreens.ScrivereLaLarghezzaAggiornaIPendenti;
var
  LEvent: TXcomInputEvent;
begin
  Open;
  // a click in the box gives the focus, a digit is added to the 640
  ClickAt(114, 34);
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Character := Ord('1');
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
  Assert.AreEqual(6401, FWorld.Game.Options.NewDisplayWidth);
  Assert.AreEqual(640, FWorld.Game.Options.DisplayWidth);
end;

procedure TTestXcomOptionsScreens.OkSalvaERitornaSeNullaCambia;
begin
  FState.OkClick(nil);
  Assert.AreEqual(1, FStore.Saves);
  Assert.AreEqual(1, FNavigator.Restarts);
end;

procedure TTestXcomOptionsScreens.OkChiedeLaConfermaSeLaRisoluzioneCambia;
begin
  FWorld.Game.Options.NewDisplayWidth := 800;
  FWorld.Game.Options.NewDisplayHeight := 600;
  FState.OkClick(nil);
  Assert.AreEqual(800, FWorld.Game.Options.DisplayWidth);
  Assert.AreEqual(640, FWorld.Game.Options.NewDisplayWidth);
  Assert.AreEqual(0, FNavigator.Restarts);
  Assert.IsTrue(FWorld.Game.TopState is TXcomOptionsConfirmState);
end;

procedure TTestXcomOptionsScreens.LaConfermaConta15SecondiEPoAnnulla;
var
  LConfirm: TXcomOptionsConfirmState;
  LIndex: Integer;
begin
  FWorld.Game.Options.NewDisplayWidth := 800;
  FState.OkClick(nil);
  LConfirm := FWorld.Game.TopState as TXcomOptionsConfirmState;
  Assert.AreEqual(15, LConfirm.Countdown);
  for LIndex := 1 to 14 do
  begin
    FWorld.Clock.Advance(1000);
    LConfirm.Think;
  end;
  Assert.AreEqual(1, LConfirm.Countdown);
  Assert.AreEqual(0, FNavigator.Restarts);
  FWorld.Clock.Advance(1000);
  LConfirm.Think;
  // no answer: the old options come back and the screens restart
  Assert.AreEqual(640, FWorld.Game.Options.DisplayWidth);
  Assert.AreEqual(1, FNavigator.Restarts);
end;

procedure TTestXcomOptionsScreens.SiAccettaLaConfermaRestaConLeNuoveImpostazioni;
begin
  // a filter does not change the size of the window, so the popup stays where it is
  FWorld.Game.Options.NewScaleFilter := True;
  FState.OkClick(nil);
  FWorld.Wait(400);
  Assert.IsTrue(FWorld.Game.TopState is TXcomOptionsConfirmState);
  // Yes is at 70,120 of the popup
  ClickAt(95, 130);
  Assert.IsTrue(FWorld.Game.Options.UseScaleFilter);
  Assert.AreEqual(1, FNavigator.Restarts);
  Assert.IsFalse(FWorld.Game.TopState is TXcomOptionsConfirmState);
end;

procedure TTestXcomOptionsScreens.AnnullaRicaricaLeOpzioni;
begin
  FWorld.Game.Options.Reload := True;
  Open;
  (FWorld.Game.TopState as TXcomOptionsVideoState).CancelClick(nil);
  Assert.AreEqual(1, FStore.Loads);
  Assert.IsFalse(FWorld.Game.Options.Reload);
end;

procedure TTestXcomOptionsScreens.RipristinareIPredefinitiChiedeEFa;
begin
  FWorld.Game.Options.DisplayWidth := 1280;
  FWorld.Game.Options.SyncPendingDisplay;
  Open;
  // Restore Defaults is at 212,176; Yes of the question at 60,122
  ClickAt(260, 184);
  FWorld.Wait(400);
  ClickAt(90, 131);
  Assert.AreEqual(640, FWorld.Game.Options.DisplayWidth);
  Assert.IsTrue(FStore.Saves >= 1);
  Assert.AreEqual(1, FNavigator.Restarts);
end;

procedure TTestXcomOptionsScreens.UnaCategoriaNonPortataNonChiudeLaSchermata;
begin
  Open;
  // the Audio button at 8,28
  ClickAt(40, 36);
  Assert.AreEqual(Ord(ocAudio), Ord(FNavigator.Created));
  Assert.IsTrue(FWorld.Game.TopState is TXcomOptionsVideoState);
end;

end.
