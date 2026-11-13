{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of how options.cfg is written and read back          }
{  (issue 186): the trace, the write in one step, the copy .bak, the keys that }
{  the class does not know, and the merge by key of two writers                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.OptionsPersistence;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Options,
  DelphiDoom.XcomEngine.FileOptionsStore, DelphiDoom.XcomEngine.OptionsStore.Intf,
  DelphiDoom.XcomEngine.AtomicFiles.Intf, DelphiDoom.XcomEngine.OptionsAudit.Intf,
  DelphiDoom.XcomEngine.OptionsAuditLog, DelphiDoom.XcomEngine.FontChoices,
  DelphiDoom.XcomEngine.ExtraChoiceOptions.Intf;

type
  /// <summary>
  ///   Files in memory that also replace in one step. A write whose path ends with FailSuffix stores half of the bytes
  ///   and raises, as a program that dies in the middle of the write would leave the file
  /// </summary>
  TPersistFiles = class(TInterfacedObject, IXcomFileSystem, IXcomAtomicFiles)
  strict private
    FFiles: TDictionary<string, TBytes>;
  public
    FailSuffix: string;
    constructor Create;
    destructor Destroy; override;
    procedure Put(const APath, AText: string);
    function Text(const APath: string): string;
    function FileExists(const APath: string): Boolean;
    function FolderExists(const APath: string): Boolean;
    function ReadAll(const APath: string): TBytes;
    procedure WriteAll(const APath: string; const ABytes: TBytes);
    function FolderContents(const AFolder, AExtension: string): TArray<string>;
    procedure ReplaceFile(const ASource, ADestination: string);
    procedure CopyFile(const ASource, ADestination: string);
    procedure DeleteFile(const APath: string);
  end;

  TPersistAudit = class(TInterfacedObject, IXcomOptionsAudit)
  public
    Reports: TStringList;
    Warnings: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure Report(const AReason, AMessage: string);
    procedure Warning(const AMessage: string);
  end;

  TCaptureLog = class(TInterfacedObject, IXcomLog)
  public
    Lines: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure Write(const ALevel, AMessage: string);
  end;

  [TestFixture]
  [Category('XcomOptions')]
  TTestXcomOptionsPersistence = class
  strict private
    FFiles: TPersistFiles;
    FFilesRef: IXcomFileSystem;
    FAudit: TPersistAudit;
    FAuditRef: IXcomOptionsAudit;
    function NewStore: IXcomOptionsStore;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LaTracciaDiceLeChiaviCheCambiano;
    [Test]
    procedure LaTracciaDiceDoveIlFileEStatoCambiatoDaFuori;
    [Test]
    procedure LaTracciaHaIlMotivoDiChiLaChiede;
    [Test]
    procedure UnaScritturaInterrottaLasciaIlFileIntatto;
    [Test]
    procedure UnaScritturaRiuscitaNonLasciaIlFileTemporaneo;
    [Test]
    procedure SalvaTieneUnaCopiaDellUltimaVersioneBuona;
    [Test]
    procedure UnFileVuotoNonSostituisceLaCopiaBuona;
    [Test]
    procedure IlCaricamentoUsaLaCopiaSeIlFileEVuoto;
    [Test]
    procedure IlCaricamentoUsaLaCopiaSeIlFileEIllegibile;
    [Test]
    procedure IlCaricamentoNonUsaLaCopiaSeIlFileEBuono;
    [Test]
    procedure SenzaCopiaUnFileVuotoDaiPredefinitiEUnAvviso;
    [Test]
    procedure LeChiaviNonScalariSiConservano;
    [Test]
    procedure DueIstanzeCheSalvanoChiaviDiverseSiSommano;
    [Test]
    procedure DueIstanzeInOrdineInversoSiSommano;
    [Test]
    procedure UnaModificaDaFuoriNonVieneAnnullata;
    [Test]
    procedure LaStessaChiaveCambiataDaTuttiVinceLUltimo;
    [Test]
    procedure UnaChiaveRimessaAlValoreDelFileNonSiRiscrive;
    [Test]
    procedure IModNonCambiatiNonSiRiscrivono;
    [Test]
    procedure IModCambiatiSiScrivono;
    [Test]
    procedure UnFileSenzaOpzioniVieneCompletatoAlSalvataggio;
    [Test]
    procedure UnFileSvuotatoDaFuoriVieneRiscrittoPerIntero;
    [Test]
    procedure SalvaDueVolteDiSeguitoNonCambiaIlFile;
    [Test]
    procedure UnaScritturaInterrottaDiFontsCfgLasciaIlFileIntatto;
  end;

implementation

const
  USER_FILE = 'user\options.cfg';

{ TPersistFiles }

constructor TPersistFiles.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create;
end;

destructor TPersistFiles.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TPersistFiles.Put(const APath, AText: string);
begin
  FFiles.AddOrSetValue(LowerCase(APath), TEncoding.UTF8.GetBytes(AText));
end;

function TPersistFiles.Text(const APath: string): string;
begin
  Result := TEncoding.UTF8.GetString(ReadAll(APath));
end;

function TPersistFiles.FileExists(const APath: string): Boolean;
begin
  Result := FFiles.ContainsKey(LowerCase(APath));
end;

function TPersistFiles.FolderExists(const APath: string): Boolean;
begin
  Result := True;
end;

function TPersistFiles.ReadAll(const APath: string): TBytes;
begin
  if not FFiles.TryGetValue(LowerCase(APath), Result) then
    raise EXcomEngineException.Create('no file ' + APath);
end;

procedure TPersistFiles.WriteAll(const APath: string; const ABytes: TBytes);
begin
  if (FailSuffix <> '') and LowerCase(APath).EndsWith(LowerCase(FailSuffix)) then
  begin
    FFiles.AddOrSetValue(LowerCase(APath), Copy(ABytes, 0, Length(ABytes) div 2));
    raise EXcomEngineException.Create('disk full while writing ' + APath);
  end;
  FFiles.AddOrSetValue(LowerCase(APath), ABytes);
end;

function TPersistFiles.FolderContents(const AFolder, AExtension: string): TArray<string>;
begin
  Result := nil;
end;

procedure TPersistFiles.ReplaceFile(const ASource, ADestination: string);
begin
  FFiles.AddOrSetValue(LowerCase(ADestination), ReadAll(ASource));
  FFiles.Remove(LowerCase(ASource));
end;

procedure TPersistFiles.CopyFile(const ASource, ADestination: string);
begin
  FFiles.AddOrSetValue(LowerCase(ADestination), ReadAll(ASource));
end;

procedure TPersistFiles.DeleteFile(const APath: string);
begin
  FFiles.Remove(LowerCase(APath));
end;

{ TPersistAudit }

constructor TPersistAudit.Create;
begin
  inherited Create;
  Reports := TStringList.Create;
  Warnings := TStringList.Create;
end;

destructor TPersistAudit.Destroy;
begin
  Warnings.Free;
  Reports.Free;
  inherited Destroy;
end;

procedure TPersistAudit.Report(const AReason, AMessage: string);
begin
  Reports.Add(AReason + ' | ' + AMessage);
end;

procedure TPersistAudit.Warning(const AMessage: string);
begin
  Warnings.Add(AMessage);
end;

{ TCaptureLog }

constructor TCaptureLog.Create;
begin
  inherited Create;
  Lines := TStringList.Create;
end;

destructor TCaptureLog.Destroy;
begin
  Lines.Free;
  inherited Destroy;
end;

procedure TCaptureLog.Write(const ALevel, AMessage: string);
begin
  Lines.Add(ALevel + '|' + AMessage);
end;

{ TTestXcomOptionsPersistence }

procedure TTestXcomOptionsPersistence.Setup;
begin
  FFiles := TPersistFiles.Create;
  FFilesRef := FFiles;
  FAudit := TPersistAudit.Create;
  FAuditRef := FAudit;
end;

procedure TTestXcomOptionsPersistence.TearDown;
begin
  FAuditRef := nil;
  FFilesRef := nil;
end;

function TTestXcomOptionsPersistence.NewStore: IXcomOptionsStore;
begin
  Result := TXcomFileOptionsStore.Create(FFilesRef, TYamlFactory.CreateParser, 'user', FAuditRef);
end;

procedure TTestXcomOptionsPersistence.LaTracciaDiceLeChiaviCheCambiano;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  FFiles.Put(USER_FILE, 'options:'#10'  displayWidth: 800'#10'  keyOk: 14'#10);
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Load(LOptions, 'start');
    LOptions.DisplayWidth := 1024;
    LStore.Save(LOptions, 'ok');
    Assert.AreEqual(2, FAudit.Reports.Count);
    Assert.IsTrue(FAudit.Reports[0].StartsWith('start load'), FAudit.Reports[0]);
    Assert.IsTrue(FAudit.Reports[1].StartsWith('ok save'), FAudit.Reports[1]);
    Assert.IsTrue(Pos('displayWidth: 800 -> 1024', FAudit.Reports[1]) > 0, FAudit.Reports[1]);
    Assert.IsTrue(Pos('keyOk', FAudit.Reports[1]) = 0, 'an unchanged key is not listed: ' + FAudit.Reports[1]);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.LaTracciaDiceDoveIlFileEStatoCambiatoDaFuori;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  FFiles.Put(USER_FILE, 'options:'#10'  FPS: 60'#10'  keyOk: 14'#10);
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Load(LOptions);
    FFiles.Put(USER_FILE, 'options:'#10'  FPS: 30'#10'  keyOk: 14'#10);
    LOptions.KeyOk := 13;
    LStore.Save(LOptions, 'exit');
    Assert.IsTrue(Pos('changed in the file by someone else, kept: FPS: memory 60, file 30', FAudit.Reports[1]) > 0,
      FAudit.Reports[1]);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.LaTracciaHaIlMotivoDiChiLaChiede;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
  LAudit: IXcomOptionsAudit;
  LTrace: TCaptureLog;
  LTraceRef: IXcomLog;
begin
  LTrace := TCaptureLog.Create;
  LTraceRef := LTrace;
  LAudit := TXcomOptionsAuditLog.Create(LTraceRef, nil,
    function: string
    begin
      Result := '2026-11-13 10:00:00.000';
    end, 4242);
  LAudit.Report('ok', 'one key');
  Assert.AreEqual(1, LTrace.Lines.Count);
  Assert.AreEqual('OPTIONS|2026-11-13 10:00:00.000 pid=4242 [ok] one key', LTrace.Lines[0]);
  // without a log nothing is written and nothing fails
  LAudit := TXcomOptionsAuditLog.Create(nil, nil,
    function: string
    begin
      Result := 'T';
    end, 1);
  LAudit.Report('ok', 'x');
  LAudit.Warning('x');
  LOptions := TXcomOptions.Create;
  try
    LStore := NewStore;
    LStore.Save(LOptions, 'defaults');
    Assert.IsTrue(FAudit.Reports[0].StartsWith('defaults save'), FAudit.Reports[0]);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.UnaScritturaInterrottaLasciaIlFileIntatto;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
  LBefore: string;
  LRaised: Boolean;
begin
  FFiles.Put(USER_FILE, 'options:'#10'  displayWidth: 800'#10'  keyOk: 14'#10);
  LBefore := FFiles.Text(USER_FILE);
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Load(LOptions);
    LOptions.DisplayWidth := 1024;
    FFiles.FailSuffix := '.tmp';
    LRaised := False;
    try
      LStore.Save(LOptions, 'ok');
    except
      on EXcomEngineException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised, 'the error of the disk is not hidden');
    Assert.AreEqual(LBefore, FFiles.Text(USER_FILE), 'options.cfg is as it was');
    Assert.IsFalse(FFiles.FileExists(USER_FILE + '.tmp'), 'the half written file is removed');
    // the next write, when the disk is back, has what was lost
    FFiles.FailSuffix := '';
    LStore.Save(LOptions, 'ok');
    Assert.IsTrue(Pos('displayWidth: 1024', FFiles.Text(USER_FILE)) > 0);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.UnaScritturaRiuscitaNonLasciaIlFileTemporaneo;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Save(LOptions);
    Assert.IsTrue(FFiles.FileExists(USER_FILE));
    Assert.IsFalse(FFiles.FileExists(USER_FILE + '.tmp'));
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.SalvaTieneUnaCopiaDellUltimaVersioneBuona;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
  LFirst: string;
begin
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Save(LOptions);
    LFirst := FFiles.Text(USER_FILE);
    Assert.IsFalse(FFiles.FileExists(USER_FILE + '.bak'), 'nothing to keep the first time');
    LOptions.KeyOk := 99;
    LStore.Save(LOptions);
    Assert.AreEqual(LFirst, FFiles.Text(USER_FILE + '.bak'));
    Assert.AreNotEqual(LFirst, FFiles.Text(USER_FILE));
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.UnFileVuotoNonSostituisceLaCopiaBuona;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  FFiles.Put(USER_FILE + '.bak', 'options:'#10'  keyOk: 14'#10);
  FFiles.Put(USER_FILE, '');
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Save(LOptions);
    Assert.AreEqual('options:'#10'  keyOk: 14'#10, FFiles.Text(USER_FILE + '.bak'));
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.IlCaricamentoUsaLaCopiaSeIlFileEVuoto;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  FFiles.Put(USER_FILE + '.bak', 'options:'#10'  keyOk: 14'#10);
  FFiles.Put(USER_FILE, '');
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Load(LOptions);
    Assert.AreEqual(14, LOptions.KeyOk);
    Assert.AreEqual(1, FAudit.Warnings.Count);
    Assert.IsTrue(Pos('options.cfg.bak', FAudit.Warnings[0]) > 0, FAudit.Warnings[0]);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.IlCaricamentoUsaLaCopiaSeIlFileEIllegibile;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  FFiles.Put(USER_FILE + '.bak', 'options:'#10'  keyOk: 14'#10);
  FFiles.Put(USER_FILE, 'options:'#10'  keyOk: [14,'#10'  fps: {{{'#10);
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Load(LOptions);
    Assert.AreEqual(14, LOptions.KeyOk);
    Assert.IsTrue(FAudit.Warnings.Count >= 1);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.IlCaricamentoNonUsaLaCopiaSeIlFileEBuono;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  FFiles.Put(USER_FILE + '.bak', 'options:'#10'  keyOk: 14'#10);
  FFiles.Put(USER_FILE, 'options:'#10'  keyOk: 15'#10);
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Load(LOptions);
    Assert.AreEqual(15, LOptions.KeyOk);
    Assert.AreEqual(0, FAudit.Warnings.Count);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.SenzaCopiaUnFileVuotoDaiPredefinitiEUnAvviso;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
  LDefault: Integer;
begin
  FFiles.Put(USER_FILE, '');
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LDefault := LOptions.KeyOk;
    LStore.Load(LOptions);
    Assert.AreEqual(LDefault, LOptions.KeyOk);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.LeChiaviNonScalariSiConservano;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
  LText: string;
begin
  FFiles.Put(USER_FILE, 'options:'#10'  keyOk: 14'#10'  keyboard:'#10'    - first'#10'    - second'#10 +
    '  nightlyMap:'#10'    a: 1'#10'    b: 2'#10'mods:'#10'  - active: true'#10'    id: xcom2'#10);
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Load(LOptions);
    LOptions.DisplayWidth := 1024;
    LStore.Save(LOptions);
    LText := FFiles.Text(USER_FILE);
    Assert.IsTrue(Pos('  keyboard:'#10'    - first'#10'    - second'#10, LText) > 0, LText);
    Assert.IsTrue(Pos('  nightlyMap:'#10'    a: 1'#10'    b: 2'#10, LText) > 0, LText);
    Assert.IsTrue(Pos('  displayWidth: 1024'#10, LText) > 0, LText);
    Assert.IsTrue(Pos('mods:'#10'  - active: true'#10'    id: xcom2'#10, LText) > 0, LText);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.DueIstanzeCheSalvanoChiaviDiverseSiSommano;
var
  LFirst: IXcomOptionsStore;
  LSecond: IXcomOptionsStore;
  LOne: TXcomOptions;
  LTwo: TXcomOptions;
  LCheck: TXcomOptions;
begin
  FFiles.Put(USER_FILE, 'options:'#10'  displayWidth: 640'#10'  keyOk: 14'#10);
  LFirst := NewStore;
  LSecond := NewStore;
  LOne := TXcomOptions.Create;
  LTwo := TXcomOptions.Create;
  LCheck := TXcomOptions.Create;
  try
    LFirst.Load(LOne);
    LSecond.Load(LTwo);
    LOne.DisplayWidth := 1024;
    LTwo.KeyOk := 13;
    LFirst.Save(LOne, 'ok');
    // the second one leaves the game last, with the old width in memory: it must not take the new width back
    LSecond.Save(LTwo, 'exit');
    NewStore.Load(LCheck);
    Assert.AreEqual(1024, LCheck.DisplayWidth);
    Assert.AreEqual(13, LCheck.KeyOk);
  finally
    LCheck.Free;
    LTwo.Free;
    LOne.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.DueIstanzeInOrdineInversoSiSommano;
var
  LFirst: IXcomOptionsStore;
  LSecond: IXcomOptionsStore;
  LOne: TXcomOptions;
  LTwo: TXcomOptions;
  LCheck: TXcomOptions;
begin
  FFiles.Put(USER_FILE, 'options:'#10'  displayWidth: 640'#10'  keyOk: 14'#10);
  LFirst := NewStore;
  LSecond := NewStore;
  LOne := TXcomOptions.Create;
  LTwo := TXcomOptions.Create;
  LCheck := TXcomOptions.Create;
  try
    LFirst.Load(LOne);
    LSecond.Load(LTwo);
    LOne.DisplayWidth := 1024;
    LTwo.KeyOk := 13;
    LSecond.Save(LTwo, 'exit');
    LFirst.Save(LOne, 'ok');
    NewStore.Load(LCheck);
    Assert.AreEqual(1024, LCheck.DisplayWidth);
    Assert.AreEqual(13, LCheck.KeyOk);
  finally
    LCheck.Free;
    LTwo.Free;
    LOne.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.UnaModificaDaFuoriNonVieneAnnullata;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
  LCheck: TXcomOptions;
begin
  FFiles.Put(USER_FILE, 'options:'#10'  FPS: 60'#10'  keyOk: 14'#10);
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  LCheck := TXcomOptions.Create;
  try
    LStore.Load(LOptions);
    // a person edits the file while the game runs
    FFiles.Put(USER_FILE, 'options:'#10'  FPS: 30'#10'  keyOk: 14'#10);
    LOptions.KeyOk := 13;
    LStore.Save(LOptions, 'exit');
    NewStore.Load(LCheck);
    Assert.AreEqual(30, LCheck.FPS, 'the edit of the file stays');
    Assert.AreEqual(13, LCheck.KeyOk, 'and the change of the game is written');
  finally
    LCheck.Free;
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.LaStessaChiaveCambiataDaTuttiVinceLUltimo;
var
  LFirst: IXcomOptionsStore;
  LSecond: IXcomOptionsStore;
  LOne: TXcomOptions;
  LTwo: TXcomOptions;
  LCheck: TXcomOptions;
begin
  FFiles.Put(USER_FILE, 'options:'#10'  keyOk: 14'#10);
  LFirst := NewStore;
  LSecond := NewStore;
  LOne := TXcomOptions.Create;
  LTwo := TXcomOptions.Create;
  LCheck := TXcomOptions.Create;
  try
    LFirst.Load(LOne);
    LSecond.Load(LTwo);
    LOne.KeyOk := 11;
    LTwo.KeyOk := 12;
    LFirst.Save(LOne);
    LSecond.Save(LTwo);
    NewStore.Load(LCheck);
    Assert.AreEqual(12, LCheck.KeyOk);
  finally
    LCheck.Free;
    LTwo.Free;
    LOne.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.UnaChiaveRimessaAlValoreDelFileNonSiRiscrive;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  FFiles.Put(USER_FILE, 'options:'#10'  keyOk: 14'#10);
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Load(LOptions);
    LOptions.KeyOk := 13;
    LOptions.KeyOk := 14;
    FFiles.Put(USER_FILE, 'options:'#10'  keyOk: 99'#10);
    LStore.Save(LOptions);
    Assert.IsTrue(Pos('keyOk: 99', FFiles.Text(USER_FILE)) > 0, 'what the game never changed is not written');
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.IModNonCambiatiNonSiRiscrivono;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  FFiles.Put(USER_FILE, 'options:'#10'  keyOk: 14'#10'mods:'#10'  - active: true'#10'    id: xcom2'#10);
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Load(LOptions);
    FFiles.Put(USER_FILE, 'options:'#10'  keyOk: 14'#10'mods:'#10'  - active: true'#10'    id: xcom2'#10 +
      '  - active: true'#10'    id: extra'#10);
    LOptions.KeyOk := 13;
    LStore.Save(LOptions);
    Assert.IsTrue(Pos('id: extra', FFiles.Text(USER_FILE)) > 0);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.IModCambiatiSiScrivono;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  FFiles.Put(USER_FILE, 'options:'#10'  keyOk: 14'#10'mods:'#10'  - active: true'#10'    id: xcom2'#10);
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Load(LOptions);
    Assert.AreEqual(1, Length(LOptions.Mods));
    LOptions.Mods[0].Active := False;
    LStore.Save(LOptions);
    Assert.IsTrue(Pos('  - active: false'#10'    id: xcom2'#10, FFiles.Text(USER_FILE)) > 0, FFiles.Text(USER_FILE));
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.UnFileSenzaOpzioniVieneCompletatoAlSalvataggio;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  FFiles.Put(USER_FILE, 'options:'#10'  keyOk: 14'#10);
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Load(LOptions);
    LStore.Save(LOptions);
    // the keys the file did not have are written with their value
    Assert.IsTrue(Pos('  keyCancel: ', FFiles.Text(USER_FILE)) > 0);
    Assert.IsTrue(Pos('  keyOk: 14'#10, FFiles.Text(USER_FILE)) > 0);
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.UnFileSvuotatoDaFuoriVieneRiscrittoPerIntero;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
begin
  FFiles.Put(USER_FILE, 'options:'#10'  keyOk: 14'#10);
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Load(LOptions);
    FFiles.Put(USER_FILE, '');
    LOptions.DisplayWidth := 1024;
    LStore.Save(LOptions);
    Assert.IsTrue(Pos('  displayWidth: 1024'#10, FFiles.Text(USER_FILE)) > 0);
    Assert.IsTrue(Pos('  keyOk: 14'#10, FFiles.Text(USER_FILE)) > 0, 'nothing of the options is lost');
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.SalvaDueVolteDiSeguitoNonCambiaIlFile;
var
  LStore: IXcomOptionsStore;
  LOptions: TXcomOptions;
  LFirst: string;
begin
  FFiles.Put(USER_FILE, 'options:'#10'  keyOk: 14'#10'mods:'#10'  - active: true'#10'    id: xcom2'#10);
  LStore := NewStore;
  LOptions := TXcomOptions.Create;
  try
    LStore.Load(LOptions);
    LOptions.DisplayWidth := 1024;
    LStore.Save(LOptions);
    LFirst := FFiles.Text(USER_FILE);
    LStore.Save(LOptions);
    Assert.AreEqual(LFirst, FFiles.Text(USER_FILE));
  finally
    LOptions.Free;
  end;
end;

procedure TTestXcomOptionsPersistence.UnaScritturaInterrottaDiFontsCfgLasciaIlFileIntatto;
var
  LChoices: TXcomFontChoices;
  LChoicesRef: IXcomExtraChoiceOptions;
  LAfterFirst: string;
  LRaised: Boolean;
begin
  LChoices := TXcomFontChoices.Create(FFilesRef, TYamlFactory.CreateParser, 'user\fonts.cfg', '', nil, nil);
  LChoicesRef := LChoices;
  // the first font takes the next family of the list, and the choice is kept
  LChoicesRef.Step(0, 1);
  LChoices.Commit;
  LAfterFirst := FFiles.Text('user\fonts.cfg');
  Assert.IsTrue(LAfterFirst <> '');
  Assert.IsFalse(FFiles.FileExists('user\fonts.cfg.tmp'));
  // the disk fails in the middle of the next write
  LChoicesRef.Step(0, 1);
  FFiles.FailSuffix := '.tmp';
  LRaised := False;
  try
    LChoices.Commit;
  except
    on EXcomEngineException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
  Assert.AreEqual(LAfterFirst, FFiles.Text('user\fonts.cfg'));
  Assert.IsFalse(FFiles.FileExists('user\fonts.cfg.tmp'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomOptionsPersistence);

end.
