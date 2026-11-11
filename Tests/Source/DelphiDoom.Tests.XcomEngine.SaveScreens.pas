{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the saved game list: the catalog of a folder, the  }
{  Load Game screen, the delete question, the error window and loading          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.SaveScreens;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.SaveInfo,
  DelphiDoom.XcomEngine.SaveCatalog.Intf, DelphiDoom.XcomEngine.DiskSaveCatalog, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.Tests.XcomEngine.World;

type
  TFakeCatalog = class(TInterfacedObject, IXcomSaveCatalog)
  public
    Saves: TArray<TXcomSaveInfo>;
    Deleted: TStringList;
    CanDelete: Boolean;
    constructor Create;
    destructor Destroy; override;
    function List(ALanguage: TXcomLanguage; AAutoQuick: Boolean): TArray<TXcomSaveInfo>;
    function DeleteSave(const AFileName: string): Boolean;
    function NameBefore(const AFirst, ASecond: string): Boolean;
  end;

  [TestFixture]
  [Category('XcomSaves')]
  TTestXcomDiskSaveCatalog = class
  strict private
    FFolder: string;
    FLanguage: TXcomLanguage;
    procedure Put(const AName, AText: string);
    function Catalog: IXcomSaveCatalog;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure ElencaISalvataggiDelMasterAttivo;
    [Test]
    procedure IFileCheNonSonoSalvataggiSiSaltano;
    [Test]
    procedure IDettagliDellaGeoscape;
    [Test]
    procedure IDettagliDellaBattaglia;
    [Test]
    procedure LeSlotRiservateHannoIlNome;
    [Test]
    procedure SenzaAutoQuickNonCiSonoGliAutosalvataggi;
    [Test]
    procedure UnaCartellaSenzaFileDaLaListaVuota;
    [Test]
    procedure CancellaUnSalvataggio;
    [Test]
    procedure IlNumeroDentroAlNomeConta;
    [Test]
    procedure IlNomeSenzaNomeNelFileEQuelloDelFile;
  end;

  [TestFixture]
  [Category('XcomSaves')]
  TTestXcomSaveScreens = class
  strict private
    FWorld: TTestWorld;
    FCatalog: TFakeCatalog;
    FCatalogRef: IXcomSaveCatalog;
    /// <summary>Moves the mouse down the list until it is over the first row; gives its position in the window</summary>
    procedure HoverFirstRow(AList: TXcomTextList; out AX, AY: Integer);
    function Info(const AName: string; ADate: TDateTime; AReserved: Boolean = False): TXcomSaveInfo;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LaListaHaUnaRigaPerSalvataggioOrdinataPerDataDecrescente;
    [Test]
    procedure LeSlotRiservateStannoInCima;
    [Test]
    procedure SenzaCatalogoLaListaEVuota;
    [Test]
    procedure UnClicSullaDataInvertLOrdine;
    [Test]
    procedure UnClicSulNomeOrdinaPerNome;
    [Test]
    procedure IlMouseSopraUnaRigaLaSeleziona;
    [Test]
    procedure CancelChiudeLaLista;
    [Test]
    procedure IlClicDestroApreLaDomandaECancellaSeSi;
    [Test]
    procedure SeLaCancellazioneFallisceMostraLErrore;
    [Test]
    procedure LaDomandaNoNonCancellaNulla;
    [Test]
    procedure UnClicSinistroAvviaIlCaricamentoCheFallisceSenzaLaGeoscape;
    [Test]
    procedure UnTastoSenzaGestoreNonFaNulla;
    [Test]
    procedure UnSalvataggioCheUsaUnModNonAttivoChiedeConferma;
    [Test]
    procedure UnSalvataggioCheUsaSoloModAttiviCaricaSenzaChiedere;
    [Test]
    procedure LaConfermaNoChiudeLaDomanda;
    [Test]
    procedure LaConfermaSiAvviaIlCaricamento;
  end;

  [TestFixture]
  [Category('XcomSaves')]
  TTestXcomModSupport = class
  public
    [Test]
    [TestCase('con versione', 'xcom2 ver: 1.0,xcom2')]
    [TestCase('senza versione', 'xcom2,xcom2')]
    [TestCase('versione vuota', 'a ver: ,a')]
    [TestCase('solo il primo taglio', 'a ver: 1 ver: 2,a')]
    procedure SanitizeTagliaIlTestoDopoVer(const AName, AExpected: string);
    [Test]
    procedure LeOpzioniLeggonoLaListaDeiMod;
    [Test]
    procedure UnModSenzaValoreBooleanoNonEAttivo;
    [Test]
    procedure SenzaLaSezioneModLaListaNonCambia;
    [Test]
    procedure UnModAttivoSiTrovaPerId;
  end;

implementation

uses
  DelphiDoom.XcomEngine.ModNames, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomMenu.ConfirmLoadState,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomMenu.ListLoadState,
  DelphiDoom.XcomMenu.ListGamesState, DelphiDoom.XcomMenu.DeleteGameState, DelphiDoom.XcomMenu.LoadGameState,
  DelphiDoom.XcomMenu.ErrorMessageState;

{ TFakeCatalog }

constructor TFakeCatalog.Create;
begin
  inherited Create;
  Deleted := TStringList.Create;
  CanDelete := True;
end;

destructor TFakeCatalog.Destroy;
begin
  Deleted.Free;
  inherited Destroy;
end;

function TFakeCatalog.List(ALanguage: TXcomLanguage; AAutoQuick: Boolean): TArray<TXcomSaveInfo>;
begin
  Result := Saves;
end;

function TFakeCatalog.DeleteSave(const AFileName: string): Boolean;
begin
  Deleted.Add(AFileName);
  Result := CanDelete;
end;

function TFakeCatalog.NameBefore(const AFirst, ASecond: string): Boolean;
begin
  Result := CompareText(AFirst, ASecond) < 0;
end;

{ TTestXcomDiskSaveCatalog }

procedure TTestXcomDiskSaveCatalog.Setup;
begin
  FFolder := TPath.Combine(TPath.GetTempPath, 'ddxcom_saves_' + TPath.GetGUIDFileName);
  TDirectory.CreateDirectory(FFolder);
  FLanguage := TXcomLanguage.Create('en-US', twAuto, nil, nil);
end;

procedure TTestXcomDiskSaveCatalog.TearDown;
begin
  FLanguage.Free;
  TDirectory.Delete(FFolder, True);
end;

procedure TTestXcomDiskSaveCatalog.Put(const AName, AText: string);
begin
  TFile.WriteAllText(TPath.Combine(FFolder, AName), AText, TEncoding.UTF8);
end;

function TTestXcomDiskSaveCatalog.Catalog: IXcomSaveCatalog;
begin
  Result := TXcomDiskSaveCatalog.Create(FFolder, 'xcom2', TYamlFactory.CreateParser);
end;

procedure TTestXcomDiskSaveCatalog.ElencaISalvataggiDelMasterAttivo;
var
  LList: TArray<TXcomSaveInfo>;
begin
  Put('a.sav', 'name: Alpha'#10'mods:'#10'  - xcom2'#10'---'#10'x: 1'#10);
  Put('b.sav', 'name: Beta'#10'mods:'#10'  - "xcom2 ver: 1.0"'#10'---'#10);
  Put('c.sav', 'name: Gamma'#10'mods:'#10'  - xcom1'#10'---'#10);
  // no mods: an old-style save, for xcom1
  Put('d.sav', 'name: Delta'#10'---'#10);
  Put('e.txt', 'name: Not a save'#10'mods:'#10'  - xcom2'#10);
  LList := Catalog.List(FLanguage, False);
  Assert.AreEqual(2, Integer(Length(LList)));
  Assert.AreEqual('a.sav', LList[0].FileName);
  Assert.AreEqual('Alpha', LList[0].DisplayName);
  Assert.AreEqual('b.sav', LList[1].FileName);
  Assert.AreEqual(1, Integer(Length(LList[0].Mods)));
  Assert.AreEqual(FormatDateTime('yyyy-mm-dd', LList[0].Timestamp), LList[0].IsoDate);
  Assert.AreEqual(5, Integer(Length(LList[0].IsoTime)));
end;

procedure TTestXcomDiskSaveCatalog.IFileCheNonSonoSalvataggiSiSaltano;
begin
  Put('a.sav', '{{{ not yaml');
  Put('b.sav', 'name: Fine'#10'mods:'#10'  - xcom2'#10);
  Assert.AreEqual(1, Integer(Length(Catalog.List(FLanguage, False))));
end;

procedure TTestXcomDiskSaveCatalog.IDettagliDellaGeoscape;
var
  LList: TArray<TXcomSaveInfo>;
begin
  Put('a.sav', 'name: A'#10'mods:'#10'  - xcom2'#10'time:'#10'  day: 22'#10'  month: 12'#10'  year: 2000'#10 +
    '  hour: 9'#10'  minute: 5'#10'ironman: true'#10);
  LList := Catalog.List(FLanguage, False);
  // the language has no strings, so the keys show; the day ends in 2: STR_DATE_SECOND
  Assert.AreEqual('STR_GEOSCAPE: STR_DATE_SECOND STR_DEC 2000, 9:05 (STR_IRONMAN)', LList[0].Details);
end;

procedure TTestXcomDiskSaveCatalog.IDettagliDellaBattaglia;
var
  LList: TArray<TXcomSaveInfo>;
begin
  Put('a.sav', 'name: A'#10'mods:'#10'  - xcom2'#10'turn: 5'#10'mission: STR_X'#10);
  LList := Catalog.List(FLanguage, False);
  Assert.AreEqual('STR_BATTLESCAPE: STR_X, STR_TURN', LList[0].Details);
end;

procedure TTestXcomDiskSaveCatalog.LeSlotRiservateHannoIlNome;
var
  LList: TArray<TXcomSaveInfo>;
begin
  Put('_quick_.asav', 'name: q'#10'mods:'#10'  - xcom2'#10);
  Put('_autogeo_.asav', 'mods:'#10'  - xcom2'#10);
  Put('_autobattle_.asav', 'mods:'#10'  - xcom2'#10);
  LList := Catalog.List(FLanguage, True);
  Assert.AreEqual(3, Integer(Length(LList)));
  Assert.IsTrue(LList[0].Reserved);
  Assert.AreEqual('STR_AUTO_SAVE_BATTLESCAPE_SLOT', LList[0].DisplayName);
  Assert.AreEqual('STR_AUTO_SAVE_GEOSCAPE_SLOT', LList[1].DisplayName);
  Assert.AreEqual('STR_QUICK_SAVE_SLOT', LList[2].DisplayName);
end;

procedure TTestXcomDiskSaveCatalog.SenzaAutoQuickNonCiSonoGliAutosalvataggi;
begin
  Put('_quick_.asav', 'mods:'#10'  - xcom2'#10);
  Put('a.sav', 'mods:'#10'  - xcom2'#10);
  Assert.AreEqual(1, Integer(Length(Catalog.List(FLanguage, False))));
end;

procedure TTestXcomDiskSaveCatalog.UnaCartellaSenzaFileDaLaListaVuota;
begin
  Assert.AreEqual(0, Integer(Length(Catalog.List(FLanguage, True))));
  Assert.AreEqual(0, Integer(Length(TXcomDiskSaveCatalog.Create(TPath.Combine(FFolder, 'nope'), 'xcom2',
    TYamlFactory.CreateParser).List(FLanguage, True))));
end;

procedure TTestXcomDiskSaveCatalog.CancellaUnSalvataggio;
begin
  Put('a.sav', 'name: A'#10);
  Assert.IsTrue(Catalog.DeleteSave('a.sav'));
  Assert.IsFalse(TFile.Exists(TPath.Combine(FFolder, 'a.sav')));
  Assert.IsFalse(Catalog.DeleteSave('a.sav'));
end;

procedure TTestXcomDiskSaveCatalog.IlNumeroDentroAlNomeConta;
begin
  Assert.IsTrue(Catalog.NameBefore('game 2', 'game 10'));
  Assert.IsFalse(Catalog.NameBefore('game 10', 'game 2'));
end;

procedure TTestXcomDiskSaveCatalog.IlNomeSenzaNomeNelFileEQuelloDelFile;
var
  LList: TArray<TXcomSaveInfo>;
begin
  Put('my game.sav', 'mods:'#10'  - xcom2'#10);
  LList := Catalog.List(FLanguage, False);
  Assert.AreEqual('my game', LList[0].DisplayName);
end;

{ TTestXcomSaveScreens }

procedure TTestXcomSaveScreens.Setup;
begin
  FWorld := TTestWorld.Create;
  FCatalog := TFakeCatalog.Create;
  FCatalogRef := FCatalog;
  FWorld.Game.SetSaveCatalog(FCatalogRef);
end;

procedure TTestXcomSaveScreens.TearDown;
begin
  FCatalogRef := nil;
  FWorld.Free;
end;

procedure TTestXcomSaveScreens.HoverFirstRow(AList: TXcomTextList; out AX, AY: Integer);
var
  LEvent: TXcomInputEvent;
begin
  AX := AList.X + 20;
  AY := AList.Y;
  while AY < AList.Y + 30 do
  begin
    LEvent := TXcomInputEvent.Make(ekMouseMotion);
    LEvent.X := Round(AX * FWorld.Game.Screen.XScale);
    LEvent.Y := Round(AY * FWorld.Game.Screen.YScale);
    FWorld.Events.Enqueue(LEvent);
    FWorld.Wait(20);
    if AList.GetSelectedRow = 0 then
      Exit;
    Inc(AY);
  end;
  Assert.Fail('the first row was not found');
end;

function TTestXcomSaveScreens.Info(const AName: string; ADate: TDateTime; AReserved: Boolean): TXcomSaveInfo;
begin
  Result := Default(TXcomSaveInfo);
  Result.FileName := AName + '.sav';
  Result.DisplayName := AName;
  Result.Timestamp := ADate;
  Result.IsoDate := FormatDateTime('yyyy-mm-dd', ADate);
  Result.IsoTime := '10:00';
  Result.Details := 'details of ' + AName;
  Result.Reserved := AReserved;
end;

procedure TTestXcomSaveScreens.LaListaHaUnaRigaPerSalvataggioOrdinataPerDataDecrescente;
var
  LState: TXcomListLoadState;
begin
  FCatalog.Saves := [Info('old', 40000), Info('new', 40100), Info('mid', 40050)];
  LState := TXcomListLoadState.Create(FWorld.Game, ooMenu);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  Assert.AreEqual(3, LState.List.GetRows);
  Assert.AreEqual('new', LState.List.GetCellText(0, 0));
  Assert.AreEqual('mid', LState.List.GetCellText(1, 0));
  Assert.AreEqual('old', LState.List.GetCellText(2, 0));
  Assert.AreEqual(FormatDateTime('yyyy-mm-dd', 40100), LState.List.GetCellText(0, 1));
end;

procedure TTestXcomSaveScreens.LeSlotRiservateStannoInCima;
var
  LState: TXcomListLoadState;
begin
  FCatalog.Saves := [Info('zeta', 40100), Info('quick', 40000, True), Info('alpha', 40200)];
  LState := TXcomListLoadState.Create(FWorld.Game, ooMenu);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  Assert.AreEqual('quick', LState.List.GetCellText(0, 0));
  Assert.AreEqual('alpha', LState.List.GetCellText(1, 0));
end;

procedure TTestXcomSaveScreens.SenzaCatalogoLaListaEVuota;
var
  LState: TXcomListLoadState;
begin
  FWorld.Game.SetSaveCatalog(nil);
  LState := TXcomListLoadState.Create(FWorld.Game, ooMenu);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  Assert.AreEqual(0, LState.List.GetRows);
end;

procedure TTestXcomSaveScreens.UnClicSullaDataInvertLOrdine;
var
  LState: TXcomListLoadState;
begin
  FCatalog.Saves := [Info('a', 40000), Info('b', 40100)];
  LState := TXcomListLoadState.Create(FWorld.Game, ooMenu);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  // the arrow of the date is at 204 + the width of the heading + 5, 32; it starts descending (3)
  Assert.AreEqual(3, FWorld.Game.Options.GetValue('saveOrder'));
  FWorld.Click(Round((LState.SortDateButton.X + 5) * FWorld.Game.Screen.XScale),
    Round((LState.SortDateButton.Y + 4) * FWorld.Game.Screen.YScale));
  Assert.AreEqual(2, FWorld.Game.Options.GetValue('saveOrder'));
  Assert.AreEqual('a', LState.List.GetCellText(0, 0));
end;

procedure TTestXcomSaveScreens.UnClicSulNomeOrdinaPerNome;
var
  LState: TXcomListLoadState;
begin
  FCatalog.Saves := [Info('b', 40000), Info('a', 40100)];
  LState := TXcomListLoadState.Create(FWorld.Game, ooMenu);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  FWorld.Click(Round((LState.SortNameButton.X + 5) * FWorld.Game.Screen.XScale),
    Round((LState.SortNameButton.Y + 4) * FWorld.Game.Screen.YScale));
  Assert.AreEqual(0, FWorld.Game.Options.GetValue('saveOrder'));
  Assert.AreEqual('a', LState.List.GetCellText(0, 0));
  FWorld.Click(Round((LState.SortNameButton.X + 5) * FWorld.Game.Screen.XScale),
    Round((LState.SortNameButton.Y + 4) * FWorld.Game.Screen.YScale));
  Assert.AreEqual(1, FWorld.Game.Options.GetValue('saveOrder'));
  Assert.AreEqual('b', LState.List.GetCellText(0, 0));
end;

procedure TTestXcomSaveScreens.IlMouseSopraUnaRigaLaSeleziona;
var
  LState: TXcomListLoadState;
  LX: Integer;
  LY: Integer;
begin
  FCatalog.Saves := [Info('a', 40000)];
  LState := TXcomListLoadState.Create(FWorld.Game, ooMenu);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  HoverFirstRow(LState.List, LX, LY);
  Assert.AreEqual(0, LState.List.GetSelectedRow);
  // the mouse out of the list clears the selection of details (the screen stays)
  Assert.IsTrue(FWorld.Game.TopState is TXcomListLoadState);
end;

procedure TTestXcomSaveScreens.CancelChiudeLaLista;
var
  LState: TXcomListLoadState;
begin
  LState := TXcomListLoadState.Create(FWorld.Game, ooMenu);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  // Cancel is at 180,172 in the 320x200 window
  FWorld.Click(Round(200 * FWorld.Game.Screen.XScale), Round(180 * FWorld.Game.Screen.YScale));
  FWorld.Wait(50);
  Assert.IsFalse(FWorld.Game.TopState is TXcomListLoadState);
end;

procedure TTestXcomSaveScreens.IlClicDestroApreLaDomandaECancellaSeSi;
var
  LState: TXcomListLoadState;
  LEvent: TXcomInputEvent;
  LX: Integer;
  LY: Integer;
begin
  FCatalog.Saves := [Info('a', 40000)];
  LState := TXcomListLoadState.Create(FWorld.Game, ooMenu);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  HoverFirstRow(LState.List, LX, LY);
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := Round(LX * FWorld.Game.Screen.XScale);
  LEvent.Y := Round(LY * FWorld.Game.Screen.YScale);
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
  LEvent.Kind := ekMouseDown;
  LEvent.Button := XCOM_BUTTON_RIGHT;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(40);
  LEvent.Kind := ekMouseUp;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(400);
  Assert.IsTrue(FWorld.Game.TopState is TXcomDeleteGameState);
  // Yes is at 60,122 in the popup (32,50 and 256x100)
  FWorld.Click(Round(90 * FWorld.Game.Screen.XScale), Round(131 * FWorld.Game.Screen.YScale));
  FWorld.Wait(50);
  Assert.AreEqual(1, FCatalog.Deleted.Count);
  Assert.AreEqual('a.sav', FCatalog.Deleted[0]);
end;

procedure TTestXcomSaveScreens.SeLaCancellazioneFallisceMostraLErrore;
var
  LState: TXcomDeleteGameState;
begin
  FCatalog.CanDelete := False;
  LState := TXcomDeleteGameState.Create(FWorld.Game, ooMenu, 'a.sav');
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  FWorld.Click(Round(90 * FWorld.Game.Screen.XScale), Round(131 * FWorld.Game.Screen.YScale));
  FWorld.Wait(400);
  Assert.IsTrue(FWorld.Game.TopState is TXcomErrorMessageState);
  // OK closes it
  FWorld.Click(Round(160 * FWorld.Game.Screen.XScale), Round(163 * FWorld.Game.Screen.YScale));
  FWorld.Wait(50);
  Assert.IsFalse(FWorld.Game.TopState is TXcomErrorMessageState);
end;

procedure TTestXcomSaveScreens.LaDomandaNoNonCancellaNulla;
begin
  FWorld.Game.PushState(TXcomDeleteGameState.Create(FWorld.Game, ooMenu, 'a.sav'));
  FWorld.Wait(400);
  FWorld.Click(Round(230 * FWorld.Game.Screen.XScale), Round(131 * FWorld.Game.Screen.YScale));
  FWorld.Wait(50);
  Assert.AreEqual(0, FCatalog.Deleted.Count);
  Assert.IsFalse(FWorld.Game.TopState is TXcomDeleteGameState);
end;

procedure TTestXcomSaveScreens.UnClicSinistroAvviaIlCaricamentoCheFallisceSenzaLaGeoscape;
var
  LState: TXcomListLoadState;
  LX: Integer;
  LY: Integer;
begin
  FCatalog.Saves := [Info('a', 40000)];
  LState := TXcomListLoadState.Create(FWorld.Game, ooMenu);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  HoverFirstRow(LState.List, LX, LY);
  FWorld.Click(Round(LX * FWorld.Game.Screen.XScale), Round(LY * FWorld.Game.Screen.YScale));
  // after ten turns the loading goes away and the error window comes
  FWorld.Wait(400);
  Assert.IsTrue(FWorld.Game.TopState is TXcomErrorMessageState);
end;

procedure TTestXcomSaveScreens.UnTastoSenzaGestoreNonFaNulla;
begin
  FWorld.Game.PushState(TXcomListLoadState.Create(FWorld.Game, ooMenu));
  FWorld.Wait(400);
  FWorld.Click(Round(100 * FWorld.Game.Screen.XScale), Round(180 * FWorld.Game.Screen.YScale));
  Assert.IsTrue(FWorld.Game.TopState is TXcomListLoadState);
end;

procedure TTestXcomSaveScreens.UnSalvataggioCheUsaUnModNonAttivoChiedeConferma;
var
  LState: TXcomListLoadState;
  LInfo: TXcomSaveInfo;
  LX: Integer;
  LY: Integer;
begin
  FWorld.Game.Options.Mods := [];
  LInfo := Info('a', 40000);
  LInfo.Mods := ['extra ver: 2'];
  FCatalog.Saves := [LInfo];
  LState := TXcomListLoadState.Create(FWorld.Game, ooMenu);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  HoverFirstRow(LState.List, LX, LY);
  FWorld.Click(Round(LX * FWorld.Game.Screen.XScale), Round(LY * FWorld.Game.Screen.YScale));
  FWorld.Wait(400);
  Assert.IsTrue(FWorld.Game.TopState is TXcomConfirmLoadState);
end;

procedure TTestXcomSaveScreens.UnSalvataggioCheUsaSoloModAttiviCaricaSenzaChiedere;
var
  LState: TXcomListLoadState;
  LInfo: TXcomSaveInfo;
  LX: Integer;
  LY: Integer;
begin
  FWorld.Game.Options.Mods := [TXcomModSetting.Create('xcom2', True), TXcomModSetting.Create('off', False)];
  LInfo := Info('a', 40000);
  LInfo.Mods := ['xcom2 ver: 1.0'];
  FCatalog.Saves := [LInfo];
  LState := TXcomListLoadState.Create(FWorld.Game, ooMenu);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  HoverFirstRow(LState.List, LX, LY);
  FWorld.Click(Round(LX * FWorld.Game.Screen.XScale), Round(LY * FWorld.Game.Screen.YScale));
  FWorld.Wait(400);
  // it went straight to the loading, which fails here without the geoscape
  Assert.IsTrue(FWorld.Game.TopState is TXcomErrorMessageState);
end;

procedure TTestXcomSaveScreens.LaConfermaNoChiudeLaDomanda;
begin
  FWorld.Game.PushState(TXcomConfirmLoadState.Create(FWorld.Game, ooMenu, 'a.sav'));
  FWorld.Wait(400);
  Assert.IsTrue(FWorld.Game.TopState is TXcomConfirmLoadState);
  // No is at 200,120 (50 x 20) in the popup
  FWorld.Click(Round(225 * FWorld.Game.Screen.XScale), Round(130 * FWorld.Game.Screen.YScale));
  FWorld.Wait(50);
  Assert.IsFalse(FWorld.Game.TopState is TXcomConfirmLoadState);
end;

procedure TTestXcomSaveScreens.LaConfermaSiAvviaIlCaricamento;
begin
  FWorld.Game.PushState(TXcomConfirmLoadState.Create(FWorld.Game, ooMenu, 'a.sav'));
  FWorld.Wait(400);
  // Yes is at 70,120
  FWorld.Click(Round(95 * FWorld.Game.Screen.XScale), Round(130 * FWorld.Game.Screen.YScale));
  // the loading closes itself after ten turns and, without the geoscape, ends in the error window
  Assert.IsFalse(FWorld.Game.TopState is TXcomConfirmLoadState);
  FWorld.Wait(100);
  Assert.IsTrue(FWorld.Game.TopState is TXcomErrorMessageState);
end;

{ TTestXcomModSupport }

procedure TTestXcomModSupport.SanitizeTagliaIlTestoDopoVer(const AName, AExpected: string);
begin
  Assert.AreEqual(AExpected, TXcomModNames.Sanitize(AName));
end;

procedure TTestXcomModSupport.LeOpzioniLeggonoLaListaDeiMod;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.Load(TTestWorld.Parse('mods:'#10'  - xcom2: true'#10'  - extra: false'#10'options:'#10'  mute: false'#10));
    Assert.AreEqual(2, Integer(Length(LOptions.Mods)));
    Assert.AreEqual('xcom2', LOptions.Mods[0].Id);
    Assert.IsTrue(LOptions.Mods[0].Active);
    Assert.AreEqual('extra', LOptions.Mods[1].Id);
    Assert.IsFalse(LOptions.Mods[1].Active);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomModSupport.UnModSenzaValoreBooleanoNonEAttivo;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.Load(TTestWorld.Parse('mods:'#10'  - xcom2: banana'#10'  - plain'#10));
    // the item that is not a map is skipped; the bad value is not active
    Assert.AreEqual(1, Integer(Length(LOptions.Mods)));
    Assert.IsFalse(LOptions.Mods[0].Active);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomModSupport.SenzaLaSezioneModLaListaNonCambia;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.Mods := [TXcomModSetting.Create('keep', True)];
    LOptions.Load(TTestWorld.Parse('options:'#10'  mute: false'#10));
    Assert.AreEqual(1, Integer(Length(LOptions.Mods)));
    Assert.AreEqual('keep', LOptions.Mods[0].Id);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomModSupport.UnModAttivoSiTrovaPerId;
var
  LOptions: TXcomOptions;
begin
  LOptions := TXcomOptions.Create;
  try
    LOptions.Mods := [TXcomModSetting.Create('a', True), TXcomModSetting.Create('b', False)];
    Assert.IsTrue(LOptions.IsModActive('a'));
    Assert.IsFalse(LOptions.IsModActive('b'));
    Assert.IsFalse(LOptions.IsModActive('c'));
  finally
    LOptions.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomDiskSaveCatalog);
  TDUnitX.RegisterTestFixture(TTestXcomSaveScreens);
  TDUnitX.RegisterTestFixture(TTestXcomModSupport);

end.