{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of what the options file has after each way out of   }
{  the options screens and of the game (issue 186): Cancel that undoes only    }
{  what the screens changed, OK, defaults, the video confirmation that runs    }
{  out, the mods, and the end of the game by an error                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.OptionsFlows;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Yaml.Factory, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.OptionsStore.Intf, DelphiDoom.XcomEngine.FileOptionsStore,
  DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.OptionsNavigator.Intf, DelphiDoom.XcomMenu.OptionsVideoState,
  DelphiDoom.XcomMenu.OptionsConfirmState, DelphiDoom.XcomMenu.MainMenuState, DelphiDoom.Tests.XcomEngine.World,
  DelphiDoom.Tests.XcomEngine.OptionsScreens, DelphiDoom.Tests.XcomEngine.OptionsPersistence;

type
  /// <summary>A state whose Think raises, as a bug in a frame does</summary>
  TRaisingState = class(TXcomState)
  public
    procedure Think; override;
  end;

  /// <summary>A store that cannot write: the disk is full</summary>
  TBrokenStore = class(TInterfacedObject, IXcomOptionsStore)
  public
    Attempts: Integer;
    procedure Load(AOptions: TXcomOptions; const AReason: string = '');
    procedure Save(AOptions: TXcomOptions; const AReason: string = '');
  end;

  [TestFixture]
  [Category('XcomOptions')]
  TTestXcomOptionsCancel = class
  strict private
    FOptions: TXcomOptions;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure AnnullaRimetteSoloCioCheLeSchermeHannoCambiato;
    [Test]
    procedure AnnullaNonToccaUnaModificaFattaPrimaDiAprireLeSchermate;
    [Test]
    procedure AnnullaNonRiportaIndietroLaMisuraDellaFinestra;
    [Test]
    procedure AnnullaRimetteLeChiaviSconosciute;
    [Test]
    procedure AnnullaRimetteIMod;
    [Test]
    procedure AnnullaRiallineaLeImpostazioniVideoPendenti;
    [Test]
    procedure SenzaLaCopiaAnnullaNonCambiaNulla;
    [Test]
    procedure DopoOkAnnullaNonRimetteNulla;
    [Test]
    procedure IlDisegnoA32BitAnnullatoERiapertoRestaSpento;
    [Test]
    procedure IlDisegnoA32BitConfermatoRestaAcceso;
    [Test]
    procedure RiaprireLeSchermateFaUnaCopiaNuova;
  end;

  [TestFixture]
  [Category('XcomOptions')]
  TTestXcomOptionsFlows = class
  strict private
    FWorld: TTestWorld;
    FFiles: TPersistFiles;
    FFilesRef: IXcomFileSystem;
    FStoreRef: IXcomOptionsStore;
    FNavigator: TFakeNavigator;
    FNavigatorRef: IXcomOptionsNavigator;
    procedure ClickAt(AX, AY: Integer);
    function FileText: string;
    function OpenFromMainMenu: TXcomOptionsVideoState;
    function OpenVideo: TXcomOptionsVideoState;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlMenuPrincipaleApreLeOpzioniConLaCopia;
    [Test]
    procedure AnnullaDalMenuNonRileggeIlFile;
    [Test]
    procedure AnnullaDalMenuNonCambiaIlFile;
    [Test]
    procedure OkScriveLeModificheDelleSchermeEIlResto;
    [Test]
    procedure OkNonAnnullaUnaModificaDelFileFattaDaFuori;
    [Test]
    procedure LaConfermaScadutaRimetteNelFileIValoriDiPrima;
    [Test]
    procedure LaConfermaAccettataTieneNelFileIValoriNuovi;
    [Test]
    procedure IPredefinitiScrivonoIPredefinitiNelFile;
    [Test]
    procedure LErroreInUnFotogrammaSalvaLeOpzioniEPropagaLErrore;
    [Test]
    procedure UnErroreNelSalvataggioDopoUnErroreNonCopreLErroreVero;
    [Test]
    procedure LUscitaNormaleSalvaLaMisuraDellaFinestraRidimensionata;
  end;

implementation

const
  USER_FILE = 'user\options.cfg';

{ TRaisingState }

procedure TRaisingState.Think;
begin
  raise EXcomEngineException.Create('bug in the frame');
end;

{ TBrokenStore }

procedure TBrokenStore.Load(AOptions: TXcomOptions; const AReason: string);
begin
end;

procedure TBrokenStore.Save(AOptions: TXcomOptions; const AReason: string);
begin
  Inc(Attempts);
  raise EXcomEngineException.Create('disk full');
end;

{ TTestXcomOptionsCancel }

procedure TTestXcomOptionsCancel.Setup;
begin
  FOptions := TXcomOptions.Create;
end;

procedure TTestXcomOptionsCancel.TearDown;
begin
  FOptions.Free;
end;

procedure TTestXcomOptionsCancel.AnnullaRimetteSoloCioCheLeSchermeHannoCambiato;
begin
  FOptions.KeyOk := 14;
  FOptions.SoundVolume := 40;
  FOptions.Language := 'it-IT';
  FOptions.BeginEdit;
  FOptions.KeyOk := 99;
  FOptions.SoundVolume := 100;
  FOptions.Language := 'en-US';
  FOptions.SetBool('autosave', not FOptions.GetBool('autosave'));
  Assert.IsTrue(FOptions.CancelEdit);
  Assert.AreEqual(14, FOptions.KeyOk);
  Assert.AreEqual(40, FOptions.SoundVolume);
  Assert.AreEqual('it-IT', FOptions.Language);
  Assert.AreEqual(True, FOptions.GetBool('autosave'));
end;

procedure TTestXcomOptionsCancel.AnnullaNonToccaUnaModificaFattaPrimaDiAprireLeSchermate;
begin
  // a change in memory that is not written yet, made before the screens were opened, is not an edit of the screens
  FOptions.FPS := 45;
  FOptions.BeginEdit;
  FOptions.KeyOk := 99;
  FOptions.CancelEdit;
  Assert.AreEqual(45, FOptions.FPS);
end;

procedure TTestXcomOptionsCancel.AnnullaNonRiportaIndietroLaMisuraDellaFinestra;
begin
  FOptions.BeginEdit;
  // the player drags the border of the window while a screen is open
  FOptions.DisplayWidth := 900;
  FOptions.DisplayHeight := 600;
  FOptions.WindowedModePositionX := 30;
  FOptions.WindowedModePositionY := 40;
  FOptions.CancelEdit;
  Assert.AreEqual(900, FOptions.DisplayWidth);
  Assert.AreEqual(600, FOptions.DisplayHeight);
  Assert.AreEqual(30, FOptions.WindowedModePositionX);
  Assert.AreEqual(40, FOptions.WindowedModePositionY);
  // and the pending values follow the window
  Assert.AreEqual(900, FOptions.NewDisplayWidth);
end;

procedure TTestXcomOptionsCancel.AnnullaRimetteLeChiaviSconosciute;
begin
  FOptions.UnknownOptions.AddOrSetValue('ambienceVolume', '17');
  FOptions.BeginEdit;
  FOptions.UnknownOptions.AddOrSetValue('ambienceVolume', '99');
  FOptions.UnknownOptions.AddOrSetValue('newKey', 'x');
  FOptions.CancelEdit;
  Assert.AreEqual('17', FOptions.UnknownOptions['ambienceVolume']);
  Assert.IsFalse(FOptions.UnknownOptions.ContainsKey('newKey'));
end;

procedure TTestXcomOptionsCancel.AnnullaRimetteIMod;
begin
  FOptions.Mods := [TXcomModSetting.Create('xcom2', True)];
  FOptions.BeginEdit;
  FOptions.Mods := [TXcomModSetting.Create('xcom2', True), TXcomModSetting.Create('extra', True)];
  FOptions.CancelEdit;
  Assert.AreEqual(1, Integer(Length(FOptions.Mods)));
  Assert.AreEqual('xcom2', FOptions.Mods[0].Id);
end;

procedure TTestXcomOptionsCancel.AnnullaRiallineaLeImpostazioniVideoPendenti;
begin
  FOptions.BeginEdit;
  FOptions.NewFullscreen := True;
  FOptions.NewGeoscapeScale := 3;
  FOptions.CancelEdit;
  Assert.IsFalse(FOptions.NewFullscreen);
  Assert.AreEqual(FOptions.GeoscapeScale, FOptions.NewGeoscapeScale);
end;

procedure TTestXcomOptionsCancel.SenzaLaCopiaAnnullaNonCambiaNulla;
begin
  FOptions.KeyOk := 14;
  Assert.IsFalse(FOptions.CancelEdit);
  Assert.AreEqual(14, FOptions.KeyOk);
end;

procedure TTestXcomOptionsCancel.DopoOkAnnullaNonRimetteNulla;
begin
  FOptions.BeginEdit;
  FOptions.KeyOk := 99;
  FOptions.EndEdit;
  Assert.IsFalse(FOptions.CancelEdit);
  Assert.AreEqual(99, FOptions.KeyOk);
end;

procedure TTestXcomOptionsCancel.IlDisegnoA32BitAnnullatoERiapertoRestaSpento;
begin
  // the setting lives in one place (the unknown keys of the options): toggle, Cancel, open again
  FOptions.UnknownOptions.AddOrSetValue('trueColor', 'false');
  FOptions.BeginEdit;
  FOptions.UnknownOptions.AddOrSetValue('trueColor', 'true');
  FOptions.CancelEdit;
  FOptions.BeginEdit;
  Assert.AreEqual('false', FOptions.UnknownOptions['trueColor']);
end;

procedure TTestXcomOptionsCancel.IlDisegnoA32BitConfermatoRestaAcceso;
begin
  FOptions.UnknownOptions.AddOrSetValue('trueColor', 'false');
  FOptions.BeginEdit;
  FOptions.UnknownOptions.AddOrSetValue('trueColor', 'true');
  FOptions.EndEdit;
  FOptions.BeginEdit;
  Assert.AreEqual('true', FOptions.UnknownOptions['trueColor']);
  FOptions.CancelEdit;
  Assert.AreEqual('true', FOptions.UnknownOptions['trueColor']);
end;

procedure TTestXcomOptionsCancel.RiaprireLeSchermateFaUnaCopiaNuova;
begin
  FOptions.KeyOk := 14;
  FOptions.BeginEdit;
  FOptions.KeyOk := 99;
  FOptions.EndEdit;
  FOptions.BeginEdit;
  FOptions.KeyOk := 7;
  FOptions.CancelEdit;
  Assert.AreEqual(99, FOptions.KeyOk, 'the second copy has what the first OK kept');
end;

{ TTestXcomOptionsFlows }

procedure TTestXcomOptionsFlows.Setup;
begin
  FWorld := TTestWorld.Create;
  FFiles := TPersistFiles.Create;
  FFilesRef := FFiles;
  FStoreRef := TXcomFileOptionsStore.Create(FFilesRef, TYamlFactory.CreateParser, 'user');
  FNavigator := TFakeNavigator.Create;
  FNavigatorRef := FNavigator;
  FFiles.Put(USER_FILE, 'options:'#10'  FPS: 60'#10'  keyOk: 14'#10'  soundVolume: 40'#10);
  FWorld.Game.SetOptionsStore(FStoreRef);
  FWorld.Game.SetDisplayModes(TFakeModes.Create);
  FWorld.Game.SetLanguageProvider(TFolderProviderForScreens.Create);
  FStoreRef.Load(FWorld.Game.Options, 'start');
end;

procedure TTestXcomOptionsFlows.TearDown;
begin
  FWorld.Game.SetOptionsStore(nil);
  FNavigatorRef := nil;
  FStoreRef := nil;
  FFilesRef := nil;
  FWorld.Free;
end;

procedure TTestXcomOptionsFlows.ClickAt(AX, AY: Integer);
begin
  FWorld.Click(Round(AX * FWorld.Game.Screen.XScale), Round(AY * FWorld.Game.Screen.YScale));
end;

function TTestXcomOptionsFlows.FileText: string;
begin
  Result := FFiles.Text(USER_FILE);
end;

function TTestXcomOptionsFlows.OpenFromMainMenu: TXcomOptionsVideoState;
begin
  FWorld.Game.SetState(TXcomMainMenuState.Create(FWorld.Game, 'v'));
  FWorld.Wait(400);
  // Options is the button at 164,118 of 92x20
  ClickAt(210, 128);
  Result := FWorld.Game.TopState as TXcomOptionsVideoState;
end;

function TTestXcomOptionsFlows.OpenVideo: TXcomOptionsVideoState;
begin
  // what the menus do before they open the screens
  FWorld.Game.Options.BeginEdit;
  FWorld.Game.PushState(TXcomOptionsVideoState.Create(FWorld.Game, ooMenu, FNavigatorRef));
  FWorld.Wait(400);
  Result := FWorld.Game.TopState as TXcomOptionsVideoState;
end;

procedure TTestXcomOptionsFlows.IlMenuPrincipaleApreLeOpzioniConLaCopia;
begin
  OpenFromMainMenu;
  FWorld.Game.Options.KeyOk := 99;
  Assert.IsTrue(FWorld.Game.Options.CancelEdit, 'the main menu made the copy');
  Assert.AreEqual(14, FWorld.Game.Options.KeyOk);
end;

procedure TTestXcomOptionsFlows.AnnullaDalMenuNonRileggeIlFile;
var
  LState: TXcomOptionsVideoState;
begin
  // the size of the window and a volume changed in memory and not written yet
  FWorld.Game.Options.FPS := 45;
  LState := OpenFromMainMenu;
  FWorld.Game.Options.KeyOk := 99;
  FWorld.Game.Options.UnknownOptions.AddOrSetValue('trueColor', 'true');
  FWorld.Game.Options.DisplayWidth := 900;
  LState.CancelClick(nil);
  Assert.AreEqual(14, FWorld.Game.Options.KeyOk, 'what the screen changed is undone');
  Assert.IsFalse(FWorld.Game.Options.UnknownOptions.ContainsKey('trueColor'));
  Assert.AreEqual(45, FWorld.Game.Options.FPS, 'what was not the screen''s stays (the file says 60)');
  Assert.AreEqual(900, FWorld.Game.Options.DisplayWidth, 'and so does the window');
end;

procedure TTestXcomOptionsFlows.AnnullaDalMenuNonCambiaIlFile;
var
  LBefore: string;
  LState: TXcomOptionsVideoState;
begin
  LBefore := FileText;
  LState := OpenFromMainMenu;
  FWorld.Game.Options.KeyOk := 99;
  LState.CancelClick(nil);
  Assert.AreEqual(LBefore, FileText);
end;

procedure TTestXcomOptionsFlows.OkScriveLeModificheDelleSchermeEIlResto;
var
  LState: TXcomOptionsVideoState;
begin
  LState := OpenVideo;
  FWorld.Game.Options.KeyOk := 99;
  LState.OkClick(nil);
  Assert.IsTrue(Pos('  keyOk: 99'#10, FileText) > 0, FileText);
  Assert.IsFalse(FWorld.Game.Options.CancelEdit, 'OK drops the copy');
end;

procedure TTestXcomOptionsFlows.OkNonAnnullaUnaModificaDelFileFattaDaFuori;
var
  LState: TXcomOptionsVideoState;
begin
  LState := OpenVideo;
  // another process (or the player with an editor) sets the volume while the screens are open
  FFiles.Put(USER_FILE, 'options:'#10'  FPS: 60'#10'  keyOk: 14'#10'  soundVolume: 77'#10);
  FWorld.Game.Options.KeyOk := 99;
  LState.OkClick(nil);
  Assert.IsTrue(Pos('  soundVolume: 77'#10, FileText) > 0, FileText);
  Assert.IsTrue(Pos('  keyOk: 99'#10, FileText) > 0, FileText);
end;

procedure TTestXcomOptionsFlows.LaConfermaScadutaRimetteNelFileIValoriDiPrima;
var
  LState: TXcomOptionsVideoState;
  LConfirm: TXcomOptionsConfirmState;
  LIndex: Integer;
begin
  LState := OpenVideo;
  FWorld.Game.Options.NewDisplayWidth := 800;
  LState.OkClick(nil);
  Assert.IsTrue(Pos('  displayWidth: 800'#10, FileText) > 0, 'the video that is being tried is written first');
  LConfirm := FWorld.Game.TopState as TXcomOptionsConfirmState;
  for LIndex := 1 to 15 do
  begin
    FWorld.Clock.Advance(1000);
    LConfirm.Think;
  end;
  Assert.AreEqual(640, FWorld.Game.Options.DisplayWidth);
  Assert.IsTrue(Pos('  displayWidth: 640'#10, FileText) > 0, 'after the revert the file has the old video: ' + FileText);
end;

procedure TTestXcomOptionsFlows.LaConfermaAccettataTieneNelFileIValoriNuovi;
var
  LState: TXcomOptionsVideoState;
begin
  FWorld.Game.Options.NewScaleFilter := True;
  LState := OpenVideo;
  FWorld.Game.Options.NewScaleFilter := True;
  LState.OkClick(nil);
  FWorld.Wait(400);
  Assert.IsTrue(FWorld.Game.TopState is TXcomOptionsConfirmState);
  // Yes is at 70,120 of the popup
  ClickAt(95, 130);
  Assert.IsTrue(Pos('  useScaleFilter: true'#10, FileText) > 0, FileText);
end;

procedure TTestXcomOptionsFlows.IPredefinitiScrivonoIPredefinitiNelFile;
begin
  OpenVideo;
  // Restore Defaults is at 212,176; Yes of the question at 60,122
  ClickAt(260, 184);
  FWorld.Wait(400);
  ClickAt(90, 131);
  Assert.IsTrue(Pos('  keyOk: 13'#10, FileText) > 0, FileText);
  Assert.IsTrue(Pos('  soundVolume: 84'#10, FileText) > 0, FileText);
  Assert.AreEqual(1, FNavigator.Restarts);
end;

procedure TTestXcomOptionsFlows.LErroreInUnFotogrammaSalvaLeOpzioniEPropagaLErrore;
var
  LRaised: Boolean;
begin
  FWorld.Game.PushState(TRaisingState.Create(FWorld.Game));
  FWorld.Game.Options.KeyOk := 99;
  LRaised := False;
  try
    FWorld.Game.Run;
  except
    on E: EXcomEngineException do
      LRaised := E.Message = 'bug in the frame';
  end;
  Assert.IsTrue(LRaised, 'the error of the frame is the one that arrives');
  Assert.IsTrue(Pos('  keyOk: 99'#10, FileText) > 0, 'and the options were written all the same');
  Assert.AreEqual('', FWorld.Game.OptionsSaveError);
end;

procedure TTestXcomOptionsFlows.UnErroreNelSalvataggioDopoUnErroreNonCopreLErroreVero;
var
  LBroken: TBrokenStore;
  LBrokenRef: IXcomOptionsStore;
  LRaised: Boolean;
begin
  LBroken := TBrokenStore.Create;
  LBrokenRef := LBroken;
  FWorld.Game.SetOptionsStore(LBrokenRef);
  FWorld.Game.PushState(TRaisingState.Create(FWorld.Game));
  LRaised := False;
  try
    FWorld.Game.Run;
  except
    on E: EXcomEngineException do
      LRaised := E.Message = 'bug in the frame';
  end;
  Assert.IsTrue(LRaised, 'the writing that fails does not hide the bug');
  Assert.AreEqual(1, LBroken.Attempts);
  Assert.IsTrue(Pos('disk full', FWorld.Game.OptionsSaveError) > 0, FWorld.Game.OptionsSaveError);
end;

procedure TTestXcomOptionsFlows.LUscitaNormaleSalvaLaMisuraDellaFinestraRidimensionata;
var
  LEvent: TXcomInputEvent;
begin
  FWorld.Game.PushState(TFlatState.Create(FWorld.Game));
  FWorld.Wait(50);
  FWorld.Game.Options.AllowResize := True;
  LEvent := TXcomInputEvent.Make(ekResize);
  LEvent.X := 800;
  LEvent.Y := 500;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Game.RunFrame;
  FWorld.Game.SaveOptions;
  Assert.IsTrue(Pos('  displayWidth: 800'#10, FileText) > 0, FileText);
  Assert.IsTrue(Pos('  displayHeight: 500'#10, FileText) > 0, FileText);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomOptionsCancel);
  TDUnitX.RegisterTestFixture(TTestXcomOptionsFlows);

end.
