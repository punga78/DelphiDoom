{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the mods of the xcom game: ModInfo, the catalog of the  }
{  mods of the disk (refreshMods), the saving of the mods in options.cfg and    }
{  the Mods screen (temporary folders and a fake file system: no real data)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.Mods;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Factory, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.ModInfo, DelphiDoom.XcomEngine.ModCatalog.Intf,
  DelphiDoom.XcomEngine.DiskModCatalog, DelphiDoom.XcomEngine.FileOptionsStore, DelphiDoom.XcomEngine.OptionsStore.Intf,
  DelphiDoom.XcomMenu.ModListState, DelphiDoom.XcomMenu.ModConfirmExtendedState, DelphiDoom.Tests.XcomEngine.World;

type
  [TestFixture]
  [Category('XcomMods')]
  TTestXcomModInfo = class
  public
    [Test]
    procedure SenzaMetadataValgonoIPredefiniti;
    [Test]
    procedure LaMetadataSostituisceIPredefiniti;
    [Test]
    procedure UnMasterNonHaUnMasterSeNonLoDice;
    [Test]
    procedure UnMasterPuoAvereUnMasterEsplicito;
    [Test]
    procedure UnMasterConAsteriscoNonHaMaster;
    [Test]
    procedure LoSpazioRiservatoStaTraUnoECento;
    [Test]
    procedure UnMotoreEstesoNonEAccettato;
    [Test]
    procedure CanActivateVaPerMasterIndipendentiEDipendenti;
  end;

  [TestFixture]
  [Category('XcomMods')]
  TTestXcomDiskModCatalog = class
  strict private
    FRoot: string;
    FStandard: string;
    FUser: string;
    procedure MakeMod(const AFolder, AName, AMetadata: string);
    function Catalog(const AInstalled: TArray<string>): IXcomModCatalog;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnaListaVuotaPrendeIMasterInTestaEGliAltriInOrdineDiId;
    [Test]
    procedure IMasterDiGiochiNonInstallatiSiSaltano;
    [Test]
    procedure IModScompariLeVengonoTolti;
    [Test]
    procedure DueMasterAttiviNeTienePrimoSoloUno;
    [Test]
    procedure SenzaNessunMasterAttivoSiAttivaQuelloStandard;
    [Test]
    procedure SenzaUnMasterECeUnErrore;
    [Test]
    procedure TryGetInfoDaLaDescrizioneDelMod;
    [Test]
    procedure TryGetInfoSenzaIlModDaFalso;
    [Test]
    procedure IlPrimoModConUnIdVince;
    [Test]
    procedure UnaMetadataRottaDaErrore;
    [Test]
    procedure UnaCartellaSenzaMetadataUsaIPredefiniti;
    [Test]
    procedure IFileNellaCartellaDeiModNonSonoMod;
    [Test]
    procedure IlMasterAttivoSiRicordaDiUnaRefreshAllAltra;
  end;

  [TestFixture]
  [Category('XcomMods')]
  TTestXcomModScreen = class
  strict private
    FRoot: string;
    FWorld: TTestWorld;
    FFiles: TFakeFileSystem;
    FFilesRef: IXcomFileSystem;
    procedure MakeMod(const AName, AMetadata: string);
    procedure Open;
    /// <summary>A click at a position of the 320 x 200 window (the display of the world is larger)</summary>
    procedure ClickAt(AX, AY: Integer);
    function State: TXcomModListState;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LaListaMostraSoloIModDelMasterInUso;
    [Test]
    procedure IlComboHaIMaster;
    [Test]
    procedure UnClicSuUnModLoAccendeELoSpegne;
    [Test]
    procedure OkSalvaIModNelFile;
    [Test]
    procedure CancelRimetteQuelliSalvati;
    [Test]
    procedure CancelNonRileggeIlFileETieneLeModificheDiFuoriDallaSchermata;
    [Test]
    procedure UnaFrecciaSpostaIlModInGiu;
    [Test]
    procedure UnaFrecciaSpostaIlModInSu;
    [Test]
    procedure IlModCheServeUnMotoreEstesoNonSiAccende;
    [Test]
    procedure LoSpostamentoCambiaLOrdineDelleOpzioni;
    [Test]
    procedure IlTastoModsDelMenuApreLaSchermata;
    [Test]
    procedure SenzaCatalogoIlTastoModsNonFaNulla;
    [Test]
    procedure LaSalvataggioDelleOpzioniTieneLaSezioneModDelFile;
  end;

implementation

uses
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomMenu.MainMenuState;

const
  MASTER_XCOM2 = 'name: "TFTD"'#10'id: xcom2'#10'isMaster: true'#10;
  MASTER_XCOM1 = 'name: "UFO"'#10'id: xcom1'#10'isMaster: true'#10;

{ TTestXcomModInfo }

procedure TTestXcomModInfo.SenzaMetadataValgonoIPredefiniti;
var
  LInfo: TXcomModInfo;
begin
  LInfo := TXcomModInfo.Create('C:\mods\My_Mod');
  try
    Assert.AreEqual('My_Mod', LInfo.Name);
    Assert.AreEqual('My_Mod', LInfo.Id);
    Assert.AreEqual('xcom1', LInfo.Master);
    Assert.AreEqual('1.0', LInfo.Version);
    Assert.AreEqual('unknown author', LInfo.Author);
    Assert.AreEqual('No description.', LInfo.Description);
    Assert.IsFalse(LInfo.IsMaster);
    Assert.IsFalse(LInfo.EngineOk);
    Assert.AreEqual(1, LInfo.ReservedSpace);
    Assert.AreEqual('C:\mods\My_Mod', LInfo.Path);
  finally
    LInfo.Free;
  end;
end;

procedure TTestXcomModInfo.LaMetadataSostituisceIPredefiniti;
var
  LInfo: TXcomModInfo;
begin
  LInfo := TXcomModInfo.Create('C:\mods\folder');
  try
    LInfo.Load(TTestWorld.Parse('name: "Nice"'#10'description: Does things'#10'version: 2.5'#10'author: Me'#10 +
      'id: nice'#10'master: xcom2'#10'reservedSpace: 7'#10));
    Assert.AreEqual('Nice', LInfo.Name);
    Assert.AreEqual('Does things', LInfo.Description);
    Assert.AreEqual('2.5', LInfo.Version);
    Assert.AreEqual('Me', LInfo.Author);
    Assert.AreEqual('nice', LInfo.Id);
    Assert.AreEqual('xcom2', LInfo.Master);
    Assert.AreEqual(7, LInfo.ReservedSpace);
    Assert.IsTrue(LInfo.EngineOk);
  finally
    LInfo.Free;
  end;
end;

procedure TTestXcomModInfo.UnMasterNonHaUnMasterSeNonLoDice;
var
  LInfo: TXcomModInfo;
begin
  LInfo := TXcomModInfo.Create('C:\mods\m');
  try
    LInfo.Load(TTestWorld.Parse('isMaster: true'#10));
    Assert.IsTrue(LInfo.IsMaster);
    Assert.AreEqual('', LInfo.Master);
  finally
    LInfo.Free;
  end;
end;

procedure TTestXcomModInfo.UnMasterPuoAvereUnMasterEsplicito;
var
  LInfo: TXcomModInfo;
begin
  LInfo := TXcomModInfo.Create('C:\mods\m');
  try
    LInfo.Load(TTestWorld.Parse('isMaster: true'#10'master: base'#10));
    Assert.AreEqual('base', LInfo.Master);
  finally
    LInfo.Free;
  end;
end;

procedure TTestXcomModInfo.UnMasterConAsteriscoNonHaMaster;
var
  LInfo: TXcomModInfo;
begin
  LInfo := TXcomModInfo.Create('C:\mods\m');
  try
    LInfo.Load(TTestWorld.Parse('master: "*"'#10));
    Assert.AreEqual('', LInfo.Master);
  finally
    LInfo.Free;
  end;
end;

procedure TTestXcomModInfo.LoSpazioRiservatoStaTraUnoECento;
var
  LInfo: TXcomModInfo;
begin
  LInfo := TXcomModInfo.Create('C:\mods\m');
  try
    LInfo.Load(TTestWorld.Parse('reservedSpace: 0'#10));
    Assert.AreEqual(1, LInfo.ReservedSpace);
    LInfo.Load(TTestWorld.Parse('reservedSpace: 500'#10));
    Assert.AreEqual(100, LInfo.ReservedSpace);
  finally
    LInfo.Free;
  end;
end;

procedure TTestXcomModInfo.UnMotoreEstesoNonEAccettato;
var
  LInfo: TXcomModInfo;
begin
  LInfo := TXcomModInfo.Create('C:\mods\m');
  try
    LInfo.Load(TTestWorld.Parse('requiredExtendedEngine: Extended'#10));
    Assert.IsFalse(LInfo.EngineOk);
    LInfo.Load(TTestWorld.Parse('requiredExtendedVersion: 7.0'#10));
    Assert.IsFalse(LInfo.EngineOk);
  finally
    LInfo.Free;
  end;
end;

procedure TTestXcomModInfo.CanActivateVaPerMasterIndipendentiEDipendenti;
var
  LInfo: TXcomModInfo;
begin
  LInfo := TXcomModInfo.Create('C:\mods\m');
  try
    // the default master is xcom1
    Assert.IsTrue(LInfo.CanActivate('xcom1'));
    Assert.IsFalse(LInfo.CanActivate('xcom2'));
    LInfo.Load(TTestWorld.Parse('master: "*"'#10));
    Assert.IsTrue(LInfo.CanActivate('anything'));
    LInfo.Load(TTestWorld.Parse('isMaster: true'#10'master: other'#10));
    Assert.IsTrue(LInfo.CanActivate('anything'));
  finally
    LInfo.Free;
  end;
end;

{ TTestXcomDiskModCatalog }

procedure TTestXcomDiskModCatalog.Setup;
begin
  FRoot := TPath.Combine(TPath.GetTempPath, 'ddmods_' + TGUID.NewGuid.ToString.Replace('{', '').Replace('}', ''));
  FStandard := TPath.Combine(FRoot, 'standard');
  FUser := TPath.Combine(FRoot, 'user');
  TDirectory.CreateDirectory(FStandard);
  TDirectory.CreateDirectory(FUser);
end;

procedure TTestXcomDiskModCatalog.TearDown;
begin
  if TDirectory.Exists(FRoot) then
    TDirectory.Delete(FRoot, True);
end;

procedure TTestXcomDiskModCatalog.MakeMod(const AFolder, AName, AMetadata: string);
begin
  TDirectory.CreateDirectory(TPath.Combine(AFolder, AName));
  if AMetadata <> '' then
    TFile.WriteAllText(TPath.Combine(TPath.Combine(AFolder, AName), 'metadata.yml'), AMetadata, TEncoding.UTF8);
end;

function TTestXcomDiskModCatalog.Catalog(const AInstalled: TArray<string>): IXcomModCatalog;
begin
  Result := TXcomDiskModCatalog.Create([FStandard, FUser], AInstalled, TYamlFactory.CreateParser);
end;

procedure TTestXcomDiskModCatalog.UnaListaVuotaPrendeIMasterInTestaEGliAltriInOrdineDiId;
var
  LCatalog: IXcomModCatalog;
  LMods: TArray<TXcomModSetting>;
begin
  MakeMod(FStandard, 'xcom2', MASTER_XCOM2);
  MakeMod(FStandard, 'zeta', 'master: xcom2'#10);
  MakeMod(FStandard, 'alpha', 'master: xcom2'#10);
  LCatalog := Catalog(['xcom2']);
  LMods := nil;
  LCatalog.Refresh(LMods);
  Assert.AreEqual(3, Integer(Length(LMods)));
  Assert.AreEqual('xcom2', LMods[0].Id);
  Assert.IsTrue(LMods[0].Active);
  Assert.AreEqual('alpha', LMods[1].Id);
  Assert.IsFalse(LMods[1].Active);
  Assert.AreEqual('zeta', LMods[2].Id);
  Assert.AreEqual('xcom2', LCatalog.ActiveMaster);
end;

procedure TTestXcomDiskModCatalog.IMasterDiGiochiNonInstallatiSiSaltano;
var
  LCatalog: IXcomModCatalog;
  LMods: TArray<TXcomModSetting>;
  LInfo: TXcomModInfo;
begin
  MakeMod(FStandard, 'xcom1', MASTER_XCOM1);
  MakeMod(FStandard, 'xcom2', MASTER_XCOM2);
  LCatalog := Catalog(['xcom2']);
  LMods := nil;
  LCatalog.Refresh(LMods);
  Assert.AreEqual(1, Integer(Length(LMods)));
  Assert.IsFalse(LCatalog.TryGetInfo('xcom1', LInfo));
end;

procedure TTestXcomDiskModCatalog.IModScompariLeVengonoTolti;
var
  LCatalog: IXcomModCatalog;
  LMods: TArray<TXcomModSetting>;
begin
  MakeMod(FStandard, 'xcom2', MASTER_XCOM2);
  LCatalog := Catalog(['xcom2']);
  LMods := [TXcomModSetting.Create('gone', True), TXcomModSetting.Create('xcom2', True)];
  LCatalog.Refresh(LMods);
  Assert.AreEqual(1, Integer(Length(LMods)));
  Assert.AreEqual('xcom2', LMods[0].Id);
end;

procedure TTestXcomDiskModCatalog.DueMasterAttiviNeTienePrimoSoloUno;
var
  LCatalog: IXcomModCatalog;
  LMods: TArray<TXcomModSetting>;
begin
  MakeMod(FStandard, 'master_a', 'isMaster: true'#10);
  MakeMod(FStandard, 'master_b', 'isMaster: true'#10);
  LCatalog := Catalog([]);
  LMods := [TXcomModSetting.Create('master_a', True), TXcomModSetting.Create('master_b', True)];
  LCatalog.Refresh(LMods);
  Assert.IsTrue(LMods[0].Active);
  Assert.IsFalse(LMods[1].Active);
  Assert.AreEqual('master_a', LCatalog.ActiveMaster);
end;

procedure TTestXcomDiskModCatalog.SenzaNessunMasterAttivoSiAttivaQuelloStandard;
var
  LCatalog: IXcomModCatalog;
  LMods: TArray<TXcomModSetting>;
begin
  MakeMod(FStandard, 'aaa_other', 'isMaster: true'#10);
  MakeMod(FStandard, 'xcom2', MASTER_XCOM2);
  LCatalog := Catalog(['xcom2']);
  LMods := [TXcomModSetting.Create('aaa_other', False), TXcomModSetting.Create('xcom2', False)];
  LCatalog.Refresh(LMods);
  // the standard master is preferred to a third party one
  Assert.AreEqual('xcom2', LCatalog.ActiveMaster);
  Assert.IsFalse(LMods[0].Active);
  Assert.IsTrue(LMods[1].Active);
end;

procedure TTestXcomDiskModCatalog.SenzaUnMasterECeUnErrore;
var
  LCatalog: IXcomModCatalog;
  LMods: TArray<TXcomModSetting>;
begin
  MakeMod(FStandard, 'plain', 'master: xcom2'#10);
  LCatalog := Catalog([]);
  LMods := nil;
  Assert.WillRaise(
    procedure
    begin
      LCatalog.Refresh(LMods);
    end, EXcomEngineException);
end;

procedure TTestXcomDiskModCatalog.TryGetInfoDaLaDescrizioneDelMod;
var
  LCatalog: IXcomModCatalog;
  LMods: TArray<TXcomModSetting>;
  LInfo: TXcomModInfo;
begin
  MakeMod(FStandard, 'xcom2', MASTER_XCOM2);
  MakeMod(FStandard, 'm', 'name: "The Mod"'#10'author: A'#10'master: xcom2'#10);
  LCatalog := Catalog(['xcom2']);
  LMods := nil;
  LCatalog.Refresh(LMods);
  Assert.IsTrue(LCatalog.TryGetInfo('m', LInfo));
  Assert.AreEqual('The Mod', LInfo.Name);
  Assert.AreEqual('A', LInfo.Author);
end;

procedure TTestXcomDiskModCatalog.TryGetInfoSenzaIlModDaFalso;
var
  LCatalog: IXcomModCatalog;
  LInfo: TXcomModInfo;
begin
  LCatalog := Catalog([]);
  Assert.IsFalse(LCatalog.TryGetInfo('nope', LInfo));
end;

procedure TTestXcomDiskModCatalog.IlPrimoModConUnIdVince;
var
  LCatalog: IXcomModCatalog;
  LMods: TArray<TXcomModSetting>;
  LInfo: TXcomModInfo;
begin
  MakeMod(FStandard, 'xcom2', MASTER_XCOM2);
  MakeMod(FStandard, 'one', 'id: same'#10'name: First'#10'master: xcom2'#10);
  MakeMod(FUser, 'two', 'id: same'#10'name: Second'#10'master: xcom2'#10);
  LCatalog := Catalog(['xcom2']);
  LMods := nil;
  LCatalog.Refresh(LMods);
  Assert.AreEqual(2, Integer(Length(LMods)));
  Assert.IsTrue(LCatalog.TryGetInfo('same', LInfo));
  Assert.AreEqual('First', LInfo.Name);
end;

procedure TTestXcomDiskModCatalog.UnaMetadataRottaDaErrore;
var
  LCatalog: IXcomModCatalog;
  LMods: TArray<TXcomModSetting>;
begin
  MakeMod(FStandard, 'broken', 'name: [unclosed'#10);
  LCatalog := Catalog(['xcom2']);
  LMods := nil;
  Assert.WillRaise(
    procedure
    begin
      LCatalog.Refresh(LMods);
    end, EXcomEngineException);
end;

procedure TTestXcomDiskModCatalog.UnaCartellaSenzaMetadataUsaIPredefiniti;
var
  LCatalog: IXcomModCatalog;
  LMods: TArray<TXcomModSetting>;
  LInfo: TXcomModInfo;
begin
  MakeMod(FStandard, 'xcom1', MASTER_XCOM1);
  MakeMod(FStandard, 'bare', '');
  LCatalog := Catalog(['xcom1']);
  LMods := nil;
  LCatalog.Refresh(LMods);
  Assert.IsTrue(LCatalog.TryGetInfo('bare', LInfo));
  Assert.AreEqual('xcom1', LInfo.Master);
end;

procedure TTestXcomDiskModCatalog.IFileNellaCartellaDeiModNonSonoMod;
var
  LCatalog: IXcomModCatalog;
  LMods: TArray<TXcomModSetting>;
begin
  MakeMod(FStandard, 'xcom2', MASTER_XCOM2);
  TFile.WriteAllText(TPath.Combine(FStandard, 'README.txt'), 'hello');
  LCatalog := Catalog(['xcom2']);
  LMods := nil;
  LCatalog.Refresh(LMods);
  Assert.AreEqual(1, Integer(Length(LMods)));
end;

procedure TTestXcomDiskModCatalog.IlMasterAttivoSiRicordaDiUnaRefreshAllAltra;
var
  LCatalog: IXcomModCatalog;
  LMods: TArray<TXcomModSetting>;
begin
  MakeMod(FStandard, 'master_a', 'isMaster: true'#10);
  MakeMod(FStandard, 'master_b', 'isMaster: true'#10);
  LCatalog := Catalog([]);
  LMods := [TXcomModSetting.Create('master_a', True), TXcomModSetting.Create('master_b', False)];
  LCatalog.Refresh(LMods);
  // the user switches the masters in the list; the next scan keeps the master the catalog knew
  LMods[0].Active := False;
  LMods[1].Active := True;
  LCatalog.Refresh(LMods);
  Assert.AreEqual('master_a', LCatalog.ActiveMaster);
  Assert.IsTrue(LMods[0].Active);
  Assert.IsFalse(LMods[1].Active);
end;

{ TTestXcomModScreen }

procedure TTestXcomModScreen.Setup;
begin
  FRoot := TPath.Combine(TPath.GetTempPath, 'ddmods_' + TGUID.NewGuid.ToString.Replace('{', '').Replace('}', ''));
  TDirectory.CreateDirectory(FRoot);
  FWorld := TTestWorld.Create;
  FFiles := TFakeFileSystem.Create;
  FFilesRef := FFiles;
  MakeMod('xcom2', MASTER_XCOM2);
  MakeMod('xcom1', MASTER_XCOM1);
  MakeMod('a_first', 'name: "First mod"'#10'master: xcom2'#10);
  MakeMod('b_second', 'name: "Second mod"'#10'master: xcom2'#10);
  MakeMod('c_ufo_only', 'name: "UFO only"'#10'master: xcom1'#10);
  MakeMod('d_needs_engine', 'name: "Needs engine"'#10'master: xcom2'#10'requiredExtendedEngine: Extended'#10);
  FWorld.Game.SetModCatalog(TXcomDiskModCatalog.Create([FRoot], ['xcom1', 'xcom2'], TYamlFactory.CreateParser));
  FWorld.Game.SetOptionsStore(TXcomFileOptionsStore.Create(FFilesRef, TYamlFactory.CreateParser, 'user'));
  FWorld.Game.Options.Mods := [TXcomModSetting.Create('xcom2', True)];
  FFiles.Put('user\options.cfg', 'mods:'#10'  - xcom2: true'#10'options:'#10'  musicVolume: 10'#10);
end;

procedure TTestXcomModScreen.TearDown;
begin
  FWorld.Free;
  FFilesRef := nil;
  if TDirectory.Exists(FRoot) then
    TDirectory.Delete(FRoot, True);
end;

procedure TTestXcomModScreen.MakeMod(const AName, AMetadata: string);
begin
  TDirectory.CreateDirectory(TPath.Combine(FRoot, AName));
  TFile.WriteAllText(TPath.Combine(TPath.Combine(FRoot, AName), 'metadata.yml'), AMetadata, TEncoding.UTF8);
end;

procedure TTestXcomModScreen.Open;
begin
  FWorld.Game.PushState(TXcomModListState.Create(FWorld.Game));
  FWorld.Wait(400);
end;

procedure TTestXcomModScreen.ClickAt(AX, AY: Integer);
begin
  FWorld.Click(Round(AX * FWorld.Game.Screen.XScale), Round(AY * FWorld.Game.Screen.YScale));
end;

function TTestXcomModScreen.State: TXcomModListState;
begin
  Result := FWorld.Game.TopState as TXcomModListState;
end;

procedure TTestXcomModScreen.LaListaMostraSoloIModDelMasterInUso;
begin
  Open;
  // the masters and the mod of the other game are not in the list
  Assert.AreEqual(3, State.List.GetTexts);
  Assert.AreEqual('First mod', State.List.GetCellText(0, 0));
  Assert.AreEqual('Second mod', State.List.GetCellText(1, 0));
  Assert.AreEqual('Needs engine', State.List.GetCellText(2, 0));
  Assert.AreEqual('STR_NO', State.List.GetCellText(0, 2));
end;

procedure TTestXcomModScreen.IlComboHaIMaster;
begin
  Open;
  // xcom1 and xcom2, the two masters of the folder
  Assert.AreEqual(2, State.Masters.List.GetTexts);
end;

procedure TTestXcomModScreen.UnClicSuUnModLoAccendeELoSpegne;
begin
  Open;
  ClickAt(60, 40 + 4);
  Assert.AreEqual('STR_YES', State.List.GetCellText(0, 2));
  ClickAt(60, 40 + 4);
  Assert.AreEqual('STR_NO', State.List.GetCellText(0, 2));
end;

procedure TTestXcomModScreen.OkSalvaIModNelFile;
var
  LText: string;
begin
  Open;
  ClickAt(60, 40 + 4);
  // OK is at 8,176 (100 x 16)
  ClickAt(50, 184);
  FWorld.Wait(50);
  Assert.IsFalse(FWorld.Game.TopState is TXcomModListState);
  LText := TEncoding.UTF8.GetString(FFiles.ReadAll('user\options.cfg'));
  Assert.IsTrue(LText.Contains('- active: true'#10'    id: a_first'), LText);
  Assert.IsTrue(LText.Contains('- active: true'#10'    id: xcom2'), LText);
  // the options of the file are written too
  Assert.IsTrue(LText.Contains('options:'));
end;

procedure TTestXcomModScreen.CancelRimetteQuelliSalvati;
begin
  Open;
  ClickAt(60, 40 + 4);
  // Cancel is at 212,176
  ClickAt(260, 184);
  FWorld.Wait(50);
  Assert.IsFalse(FWorld.Game.TopState is TXcomModListState);
  // the mods of the file are back: only xcom2
  Assert.AreEqual(1, Integer(Length(FWorld.Game.Options.Mods)));
  Assert.AreEqual('xcom2', FWorld.Game.Options.Mods[0].Id);
end;

procedure TTestXcomModScreen.CancelNonRileggeIlFileETieneLeModificheDiFuoriDallaSchermata;
begin
  // a volume changed in memory and not written yet: Cancel of the mods must not read options.cfg (musicVolume: 10)
  FWorld.Game.Options.MusicVolume := 55;
  Open;
  ClickAt(60, 40 + 4);
  ClickAt(260, 184);
  FWorld.Wait(50);
  Assert.AreEqual(55, FWorld.Game.Options.MusicVolume);
  Assert.AreEqual(1, Integer(Length(FWorld.Game.Options.Mods)));
end;

procedure TTestXcomModScreen.UnaFrecciaSpostaIlModInGiu;
begin
  Open;
  // the arrows of the first row (down is the second one)
  ClickAt(State.List.GetArrowsLeftEdge + 18, 40 + 4);
  Assert.AreEqual('Second mod', State.List.GetCellText(0, 0));
  Assert.AreEqual('First mod', State.List.GetCellText(1, 0));
  Assert.IsTrue(State.ReloadNeeded);
end;

procedure TTestXcomModScreen.UnaFrecciaSpostaIlModInSu;
begin
  Open;
  // the up arrow of the second row (rows are 8 pixels high)
  ClickAt(State.List.GetArrowsLeftEdge + 4, 40 + 8 + 4);
  Assert.AreEqual('Second mod', State.List.GetCellText(0, 0));
  Assert.AreEqual('First mod', State.List.GetCellText(1, 0));
end;

procedure TTestXcomModScreen.IlModCheServeUnMotoreEstesoNonSiAccende;
var
  LList: TXcomModListState;
begin
  Open;
  LList := State;
  ClickAt(60, 40 + 16 + 4);
  // ModConfirmExtendedState: the question with the name of the engine, over the list
  Assert.IsTrue(FWorld.Game.TopState is TXcomModConfirmExtendedState, 'prima chiede conferma');
  Assert.AreEqual('STR_OXCE_REQUIRED_QUESTION', TXcomModConfirmExtendedState(FWorld.Game.TopState).Title.GetText,
    'la domanda (senza lingua resta la chiave)');
  Assert.AreEqual('STR_NO', LList.List.GetCellText(2, 2));
  FWorld.Wait(400);
  // No
  ClickAt(230, 131);
  Assert.AreSame(LList, FWorld.Game.TopState);
  Assert.AreEqual('STR_NO', State.List.GetCellText(2, 2), 'con No il mod resta spento');
  ClickAt(60, 40 + 16 + 4);
  FWorld.Wait(400);
  // Yes
  ClickAt(90, 131);
  Assert.AreSame(LList, FWorld.Game.TopState);
  Assert.AreEqual('STR_YES', State.List.GetCellText(2, 2), 'con Si'' si accende');
end;

procedure TTestXcomModScreen.LoSpostamentoCambiaLOrdineDelleOpzioni;
begin
  Open;
  ClickAt(State.List.GetArrowsLeftEdge + 18, 40 + 4);
  // the masters (the new one in front), then the mods in the new order
  Assert.AreEqual('xcom1', FWorld.Game.Options.Mods[0].Id);
  Assert.AreEqual('xcom2', FWorld.Game.Options.Mods[1].Id);
  Assert.AreEqual('b_second', FWorld.Game.Options.Mods[2].Id);
  Assert.AreEqual('a_first', FWorld.Game.Options.Mods[3].Id);
end;

procedure TTestXcomModScreen.IlTastoModsDelMenuApreLaSchermata;
begin
  FWorld.Game.SetState(TXcomMainMenuState.Create(FWorld.Game, 'v'));
  FWorld.Wait(500);
  // Mods is at 64,146 (92 x 20) in the menu
  ClickAt(110, 156);
  FWorld.Wait(50);
  Assert.IsTrue(FWorld.Game.TopState is TXcomModListState);
end;

procedure TTestXcomModScreen.SenzaCatalogoIlTastoModsNonFaNulla;
var
  LWorld: TTestWorld;
begin
  LWorld := TTestWorld.Create;
  try
    LWorld.Game.SetState(TXcomMainMenuState.Create(LWorld.Game, 'v'));
    LWorld.Wait(500);
    LWorld.Click(Round(110 * LWorld.Game.Screen.XScale), Round(156 * LWorld.Game.Screen.YScale));
    LWorld.Wait(50);
    Assert.IsTrue(LWorld.Game.TopState is TXcomMainMenuState);
  finally
    LWorld.Free;
  end;
end;

procedure TTestXcomModScreen.LaSalvataggioDelleOpzioniTieneLaSezioneModDelFile;
var
  LText: string;
begin
  // with no mods in the options the store leaves the mods section of the file as it is
  FWorld.Game.Options.Mods := nil;
  FWorld.Game.OptionsStore.Save(FWorld.Game.Options);
  LText := TEncoding.UTF8.GetString(FFiles.ReadAll('user\options.cfg'));
  Assert.IsTrue(LText.Contains('- xcom2: true'), LText);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomModInfo);
  TDUnitX.RegisterTestFixture(TTestXcomDiskModCatalog);
  TDUnitX.RegisterTestFixture(TTestXcomModScreen);

end.
