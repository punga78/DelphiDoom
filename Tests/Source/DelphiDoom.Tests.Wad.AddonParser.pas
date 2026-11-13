{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - file system of id Tech 4, addon.conf }
{  (ParseAddonDef) and the addon paks of the search list                       }
{                                                                              }
{  The expected values come from reading framework\FileSystem.cpp of Doom 3;  }
{  the checksum texts are checked against the C++ in TTestGamePureParity.      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.AddonParser;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Wad.Fs.Types,
  DelphiDoom.Wad.Fs.Intf, DelphiDoom.Tests.Wad.MemoryWriteDisk;

type
  /// <summary>The log of the tests: everything it is told, one line each</summary>
  TCollectingLog = class(TInterfacedObject, IIdLibLog)
  strict private
    FLines: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
    /// <summary>True when a line contains the text</summary>
    function Contains(const AText: string): Boolean;
    property Lines: TStringList read FLines;
  end;

  [TestFixture]
  [Category('wad')]
  TTestGameAddonParser = class(TObject)
  strict private
    FLog: TCollectingLog;
    FLogIntf: IIdLibLog;
    FInfo: TGameAddonInfo;
    function Parse(const AText: AnsiString): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereIChecksumDiUnAddonDef;
    [Test]
    procedure DovrebbeAccettareUnAddonSenzaMapDef;
    [Test]
    procedure DovrebbeLeggereIMapDef;
    [Test]
    procedure DovrebbeAvvisareUnaChiaveDefinitaDueVolte;
    [Test]
    procedure DovrebbeDareFalsoSenzaAddonDef;
    [Test]
    procedure DovrebbeDareFalsoSenzaGraffaDopoAddonDef;
    [Test]
    procedure DovrebbeDareFalsoPerUnChecksumNonStringa;
    [Test]
    procedure DovrebbeDareFalsoPerUnChecksumNonNumerico;
    [Test]
    procedure DovrebbeDareFalsoSeAddonDefNonSiChiude;
    [Test]
    procedure DovrebbeDareFalsoPerUnMapDefSenzaPercorso;
    [Test]
    procedure DovrebbeDareFalsoPerUnMapDefSenzaGraffa;
    [Test]
    procedure DovrebbeDareFalsoPerUnaChiaveNonStringa;
    [Test]
    procedure DovrebbeDareFalsoPerUnaChiaveSenzaValore;
    [Test]
    procedure DovrebbeAccettareUnMapDefNonChiuso;
    [Test]
    procedure DovrebbeFunzionareSenzaLog;
    [Test]
    procedure DovrebbeSvuotareLeMapDefLetteSuUnErrore;
    [Test]
    procedure DovrebbeLeggereUnChecksumNegativoEUnoTroppoLungo;
  end;

  [TestFixture]
  [Category('wad')]
  TTestGameFileSystemAddons = class(TObject)
  strict private
    FDisk: TMemoryWriteDisk;
    FDiskIntf: IGameDisk;
    FSettings: TGameFsSettings;
    function Start: IGameFileSystem;
    function AddonChecksum(const ASystem: IGameFileSystem; const AFileName: string): Cardinal;
    function ConfOf(const AChecksums: array of Cardinal): string;
    function PackFileNames(const ASystem: IGameFileSystem): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLasciareFuoriGliAddonSenzaChecksumRichiesti;
    [Test]
    procedure DovrebbeTenereUnAddonRichiestoPerChecksum;
    [Test]
    procedure DovrebbeSeguireLeDipendenzeDiUnAddon;
    [Test]
    procedure DovrebbeSeguireUnaDipendenzaRipetutaUnaVoltaSola;
  [Test]
    procedure DovrebbeIgnorareUnaDipendenzaSconosciuta;
    [Test]
    procedure DovrebbeTenereTuttiGliAddonConSearchAddons;
    [Test]
    procedure DovrebbeDareLeInformazioniDellAddonConf;
    [Test]
    procedure DovrebbeNonAvereInformazioniSeLAddonConfEVuoto;
    [Test]
    procedure DovrebbeNonAvereInformazioniSeLAddonConfEDifettoso;
    [Test]
    procedure DovrebbeDareLaCartellaDelGioco;
    [Test]
    procedure DovrebbeDareLeListeDeiPak;
    [Test]
    procedure DovrebbeCercareIPakConLEstensioneDelleImpostazioni;
  end;

implementation

uses
  DelphiDoom.Wad.Fs.AddonParser, DelphiDoom.Wad.Fs.Factory, DelphiDoom.Tests.Wad.MemoryDisk;

{ TCollectingLog }

constructor TCollectingLog.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
end;

destructor TCollectingLog.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

procedure TCollectingLog.Printf(const AMessage: string);
begin
  FLines.Add(AMessage);
end;

procedure TCollectingLog.Warning(const AMessage: string);
begin
  FLines.Add(AMessage);
end;

function TCollectingLog.Contains(const AText: string): Boolean;
var
  LLine: string;
begin
  for LLine in FLines do
    if LLine.Contains(AText) then
      Exit(True);
  Result := False;
end;

{ TTestGameAddonParser }

procedure TTestGameAddonParser.Setup;
begin
  FLog := TCollectingLog.Create;
  FLogIntf := FLog;
end;

procedure TTestGameAddonParser.TearDown;
begin
  FLogIntf := nil;
  FLog := nil;
end;

function TTestGameAddonParser.Parse(const AText: AnsiString): Boolean;
begin
  Result := TGameAddonParser.Parse(AText, FInfo, FLogIntf);
end;

procedure TTestGameAddonParser.DovrebbeLeggereIChecksumDiUnAddonDef;
begin
  Assert.IsTrue(Parse('addonDef { "0x11223344" "AABBCCDD" }'));
  Assert.AreEqual<Integer>(2, Length(FInfo.Depends));
  Assert.AreEqual<Cardinal>($11223344, FInfo.Depends[0]);
  Assert.AreEqual<Cardinal>($AABBCCDD, FInfo.Depends[1]);
  Assert.AreEqual<Integer>(0, Length(FInfo.MapDefs));
  Assert.AreEqual(0, FLog.Lines.Count);
end;

procedure TTestGameAddonParser.DovrebbeAccettareUnAddonSenzaMapDef;
begin
  Assert.IsTrue(Parse('// an addon with nothing to say' + #10 + 'addonDef { }'));
  Assert.AreEqual<Integer>(0, Length(FInfo.Depends));
  Assert.AreEqual<Integer>(0, Length(FInfo.MapDefs));
end;

procedure TTestGameAddonParser.DovrebbeLeggereIMapDef;
begin
  Assert.IsTrue(Parse(
    'addonDef { }' + #10 +
    'mapDef "maps/a" { "name" "Alpha" "author" "me" }' + #10 +
    'mapDef "maps/b" { "x" "1" }'));
  Assert.AreEqual<Integer>(2, Length(FInfo.MapDefs));
  Assert.AreEqual('path,name,author', string.Join(',', FInfo.MapDefs[0].Keys));
  Assert.AreEqual('maps/a,Alpha,me', string.Join(',', FInfo.MapDefs[0].Values));
  Assert.AreEqual('path,x', string.Join(',', FInfo.MapDefs[1].Keys));
  Assert.AreEqual('maps/b,1', string.Join(',', FInfo.MapDefs[1].Values));
end;

procedure TTestGameAddonParser.DovrebbeAvvisareUnaChiaveDefinitaDueVolte;
begin
  Assert.IsTrue(Parse('addonDef { } mapDef "p" { "k" "one" "other" "x" "K" "two" }'));
  // idDict::Set replaces the value and keeps the place of the key (the keys ignore the case)
  Assert.AreEqual('path,k,other', string.Join(',', FInfo.MapDefs[0].Keys));
  Assert.AreEqual('p,two,x', string.Join(',', FInfo.MapDefs[0].Values));
  Assert.IsTrue(FLog.Contains('''K'' already defined'));
  // the key "path" is a key like the others
  Assert.IsTrue(Parse('addonDef { } mapDef "p" { "path" "other" }'));
  Assert.AreEqual('other', FInfo.MapDefs[0].Values[0]);
  Assert.AreEqual<Integer>(1, Length(FInfo.MapDefs[0].Keys));
end;

procedure TTestGameAddonParser.DovrebbeDareFalsoSenzaAddonDef;
begin
  Assert.IsFalse(Parse('nothing here'));
  Assert.IsTrue(FLog.Contains('ParseAddonDef: no addonDef'));
end;

procedure TTestGameAddonParser.DovrebbeDareFalsoSenzaGraffaDopoAddonDef;
begin
  Assert.IsFalse(Parse('addonDef'));
  Assert.IsTrue(FLog.Contains('Expected {'));
end;

procedure TTestGameAddonParser.DovrebbeDareFalsoPerUnChecksumNonStringa;
begin
  Assert.IsFalse(Parse('addonDef { 12 }'));
  Assert.IsTrue(FLog.Contains('Expected quoted string, but found ''12'''));
end;

procedure TTestGameAddonParser.DovrebbeDareFalsoPerUnChecksumNonNumerico;
begin
  Assert.IsFalse(Parse('addonDef { "xyz" }'));
  Assert.IsTrue(FLog.Contains('Could not parse checksum ''xyz'''));
  Assert.IsFalse(Parse('addonDef { "" }'));
  Assert.IsTrue(FLog.Contains('Could not parse checksum '''''));
end;

procedure TTestGameAddonParser.DovrebbeDareFalsoSeAddonDefNonSiChiude;
begin
  Assert.IsFalse(Parse('addonDef { "11"'));
  Assert.AreEqual(0, FLog.Lines.Count);
end;

procedure TTestGameAddonParser.DovrebbeDareFalsoPerUnMapDefSenzaPercorso;
begin
  Assert.IsFalse(Parse('addonDef { } mapDef'));
  Assert.IsTrue(FLog.Contains('Expected map path'));
end;

procedure TTestGameAddonParser.DovrebbeDareFalsoPerUnMapDefSenzaGraffa;
begin
  Assert.IsFalse(Parse('addonDef { } mapDef "p"'));
  Assert.IsTrue(FLog.Contains('Expected {'));
end;

procedure TTestGameAddonParser.DovrebbeDareFalsoPerUnaChiaveNonStringa;
begin
  Assert.IsFalse(Parse('addonDef { } mapDef "p" { 5 }'));
  Assert.IsTrue(FLog.Contains('Expected quoted string, but found ''5'''));
end;

procedure TTestGameAddonParser.DovrebbeDareFalsoPerUnaChiaveSenzaValore;
begin
  Assert.IsFalse(Parse('addonDef { } mapDef "p" { "k"'));
  Assert.IsTrue(FLog.Contains('Unexpected end of file'));
end;

procedure TTestGameAddonParser.DovrebbeAccettareUnMapDefNonChiuso;
begin
  // the end of the text inside a mapDef ends it, as the original does
  Assert.IsTrue(Parse('addonDef { } mapDef "p" { "k" "v"'));
  Assert.AreEqual<Integer>(1, Length(FInfo.MapDefs));
  Assert.AreEqual('p,v', string.Join(',', FInfo.MapDefs[0].Values));
end;

procedure TTestGameAddonParser.DovrebbeFunzionareSenzaLog;
begin
  Assert.IsFalse(TGameAddonParser.Parse('nothing', FInfo));
  Assert.IsTrue(TGameAddonParser.Parse('addonDef { "1" }', FInfo));
  Assert.AreEqual<Cardinal>(1, FInfo.Depends[0]);
end;

procedure TTestGameAddonParser.DovrebbeSvuotareLeMapDefLetteSuUnErrore;
begin
  Assert.IsFalse(Parse('addonDef { } mapDef "a" { "k" "v" } mapDef "b" { 5 }'));
  Assert.AreEqual<Integer>(0, Length(FInfo.MapDefs));
end;

procedure TTestGameAddonParser.DovrebbeLeggereUnChecksumNegativoEUnoTroppoLungo;
var
  LValue: Cardinal;
begin
  Assert.IsTrue(TGameAddonParser.ParseChecksum('-1', LValue));
  Assert.AreEqual<Cardinal>($FFFFFFFF, LValue);
  Assert.IsTrue(TGameAddonParser.ParseChecksum('0x1ffffffff', LValue));
  Assert.AreEqual<Cardinal>($FFFFFFFF, LValue);
  Assert.IsTrue(TGameAddonParser.ParseChecksum('+0x10', LValue));
  Assert.AreEqual<Cardinal>($10, LValue);
  Assert.IsFalse(TGameAddonParser.ParseChecksum('-', LValue));
end;

{ TTestGameFileSystemAddons }

procedure TTestGameFileSystemAddons.Setup;
begin
  FDisk := TMemoryWriteDisk.Create;
  FDiskIntf := FDisk;
  FSettings := Default(TGameFsSettings);
  FSettings.BasePath := 'C:\d3';
  FDisk.AddFile('C:\d3\base\pak000.pk4', TMemoryZip.Make(['a.txt'], ['base text']));
end;

procedure TTestGameFileSystemAddons.TearDown;
begin
  FDiskIntf := nil;
  FDisk := nil;
end;

function TTestGameFileSystemAddons.Start: IGameFileSystem;
begin
  Result := TGameFileSystemFactory.CreateWithDisk(FDiskIntf, FSettings);
  Result.Startup;
end;

function TTestGameFileSystemAddons.AddonChecksum(const ASystem: IGameFileSystem; const AFileName: string): Cardinal;
var
  LState: IGameFileSystemInspector;
  LPack: IGamePack;
begin
  Assert.IsTrue(Supports(ASystem, IGameFileSystemInspector, LState));
  for LPack in LState.AddonPacks do
    if LPack.FileName.EndsWith(AFileName, True) then
      Exit(LPack.Checksum);
  for LPack in LState.Packs do
    if LPack.FileName.EndsWith(AFileName, True) then
      Exit(LPack.Checksum);
  Result := 0;
  Assert.Fail('no pak ' + AFileName);
end;

function TTestGameFileSystemAddons.ConfOf(const AChecksums: array of Cardinal): string;
var
  LChecksum: Cardinal;
begin
  Result := 'addonDef {';
  for LChecksum in AChecksums do
    Result := Result + ' "0x' + IntToHex(LChecksum, 1) + '"';
  Result := Result + ' }';
end;

function TTestGameFileSystemAddons.PackFileNames(const ASystem: IGameFileSystem): string;
var
  LPath: TGameSearchPath;
  LList: TStringList;
begin
  LList := TStringList.Create;
  try
    LList.Delimiter := ',';
    LList.StrictDelimiter := True;
    for LPath in ASystem.SearchPaths do
      if not LPath.IsDirectory then
        LList.Add(ExtractFileName(StringReplace(LPath.PackFileName, '/', '\', [rfReplaceAll])));
    LList.Sort;
    Result := LList.DelimitedText;
  finally
    LList.Free;
  end;
end;

procedure TTestGameFileSystemAddons.DovrebbeLasciareFuoriGliAddonSenzaChecksumRichiesti;
var
  LSystem: IGameFileSystem;
begin
  FDisk.AddFile('C:\d3\base\addon1.pk4', TMemoryZip.Make(['addon.conf', 'x.txt'], ['addonDef { }', 'x']));
  LSystem := Start;
  Assert.AreEqual('pak000.pk4', PackFileNames(LSystem));
  Assert.AreEqual<Integer>(1, Length(LSystem.AddonPackFileNames));
  Assert.IsFalse(LSystem.FileIsInPak('x.txt'));
end;

procedure TTestGameFileSystemAddons.DovrebbeTenereUnAddonRichiestoPerChecksum;
var
  LSystem: IGameFileSystem;
  LChecksum: Cardinal;
begin
  FDisk.AddFile('C:\d3\base\addon1.pk4', TMemoryZip.Make(['addon.conf', 'x.txt'], ['addonDef { }', 'x']));
  FDisk.AddFile('C:\d3\base\addon2.pk4', TMemoryZip.Make(['addon.conf', 'y.txt'], ['addonDef { }', 'y']));
  LChecksum := AddonChecksum(Start, 'addon2.pk4');
  FSettings.AddonChecksums := [LChecksum];
  LSystem := Start;
  Assert.AreEqual('addon2.pk4,pak000.pk4', PackFileNames(LSystem));
  Assert.IsTrue(LSystem.FileIsInPak('y.txt'));
  Assert.IsFalse(LSystem.FileIsInPak('x.txt'));
  Assert.AreEqual<Integer>(1, Length(LSystem.AddonPackFileNames));
end;

procedure TTestGameFileSystemAddons.DovrebbeSeguireLeDipendenzeDiUnAddon;
var
  LSystem: IGameFileSystem;
  LDependency: Cardinal;
  LFirst: Cardinal;
begin
  FDisk.AddFile('C:\d3\base\addon2.pk4', TMemoryZip.Make(['addon.conf', 'dep.txt'], ['addonDef { }', 'dep']));
  FDisk.AddFile('C:\d3\base\addon3.pk4', TMemoryZip.Make(['addon.conf', 'other.txt'], ['addonDef { }', 'other']));
  LDependency := AddonChecksum(Start, 'addon2.pk4');
  FDisk.AddFile('C:\d3\base\addon1.pk4', TMemoryZip.Make(['addon.conf', 'x.txt'], [ConfOf([LDependency]), 'x']));
  LFirst := AddonChecksum(Start, 'addon1.pk4');
  FSettings.AddonChecksums := [LFirst];
  LSystem := Start;
  // the addon asked for and the addon it depends on are searched, the third addon is not
  Assert.AreEqual('addon1.pk4,addon2.pk4,pak000.pk4', PackFileNames(LSystem));
  Assert.IsTrue(LSystem.FileIsInPak('dep.txt'));
  Assert.IsFalse(LSystem.FileIsInPak('other.txt'));
end;

procedure TTestGameFileSystemAddons.DovrebbeSeguireUnaDipendenzaRipetutaUnaVoltaSola;
var
  LSystem: IGameFileSystem;
  LOne, LTwo: Cardinal;
begin
  // a cycle cannot be built (the checksum of a pak depends on its addon.conf); the same dependency twice
  // exercises the check that a pak is followed once
  FDisk.AddFile('C:\d3\base\addon2.pk4', TMemoryZip.Make(['addon.conf', 'two.txt'], ['addonDef { }', 'two']));
  LTwo := AddonChecksum(Start, 'addon2.pk4');
  FDisk.AddFile('C:\d3\base\addon1.pk4', TMemoryZip.Make(['addon.conf', 'one.txt'], [ConfOf([LTwo, LTwo]), 'one']));
  LOne := AddonChecksum(Start, 'addon1.pk4');
  FSettings.AddonChecksums := [LOne, LOne];
  LSystem := Start;
  Assert.AreEqual('addon1.pk4,addon2.pk4,pak000.pk4', PackFileNames(LSystem));
end;

procedure TTestGameFileSystemAddons.DovrebbeIgnorareUnaDipendenzaSconosciuta;
var
  LSystem: IGameFileSystem;
  LChecksum: Cardinal;
begin
  FDisk.AddFile('C:\d3\base\addon1.pk4', TMemoryZip.Make(['addon.conf', 'x.txt'], [ConfOf([$DEADBEEF]), 'x']));
  LChecksum := AddonChecksum(Start, 'addon1.pk4');
  FSettings.AddonChecksums := [LChecksum];
  LSystem := Start;
  Assert.AreEqual('addon1.pk4,pak000.pk4', PackFileNames(LSystem));
end;

procedure TTestGameFileSystemAddons.DovrebbeTenereTuttiGliAddonConSearchAddons;
var
  LSystem: IGameFileSystem;
begin
  FDisk.AddFile('C:\d3\base\addon1.pk4', TMemoryZip.Make(['addon.conf', 'x.txt'], ['addonDef { }', 'x']));
  FDisk.AddFile('C:\d3\base\addon2.pk4', TMemoryZip.Make(['addon.conf', 'y.txt'], ['addonDef { }', 'y']));
  FSettings.SearchAddons := True;
  LSystem := Start;
  Assert.AreEqual('addon1.pk4,addon2.pk4,pak000.pk4', PackFileNames(LSystem));
  Assert.AreEqual<Integer>(0, Length(LSystem.AddonPackFileNames));
end;

procedure TTestGameFileSystemAddons.DovrebbeDareLeInformazioniDellAddonConf;
var
  LSystem: IGameFileSystem;
  LState: IGameFileSystemInspector;
  LPack: IGamePack;
begin
  FDisk.AddFile('C:\d3\base\addon1.pk4', TMemoryZip.Make(['addon.conf'],
    ['addonDef { "0x11" } mapDef "maps/a" { "name" "Alpha" }']));
  FSettings.SearchAddons := True;
  LSystem := Start;
  Assert.IsTrue(Supports(LSystem, IGameFileSystemInspector, LState));
  for LPack in LState.Packs do
    if LPack.IsAddon then
    begin
      Assert.IsTrue(LPack.HasAddonInfo);
      Assert.AreEqual<Cardinal>($11, LPack.AddonInfo.Depends[0]);
      Assert.AreEqual('Alpha', LPack.AddonInfo.MapDefs[0].Values[1]);
      Exit;
    end;
  Assert.Fail('no addon pak');
end;

procedure TTestGameFileSystemAddons.DovrebbeNonAvereInformazioniSeLAddonConfEVuoto;
var
  LState: IGameFileSystemInspector;
  LPack: IGamePack;
begin
  FDisk.AddFile('C:\d3\base\addon1.pk4', TMemoryZip.Make(['addon.conf'], ['']));
  FSettings.SearchAddons := True;
  Assert.IsTrue(Supports(Start, IGameFileSystemInspector, LState));
  for LPack in LState.Packs do
    if LPack.IsAddon then
    begin
      Assert.IsFalse(LPack.HasAddonInfo);
      Assert.AreEqual<Integer>(0, Length(LPack.AddonInfo.Depends));
      Exit;
    end;
  Assert.Fail('no addon pak');
end;

procedure TTestGameFileSystemAddons.DovrebbeNonAvereInformazioniSeLAddonConfEDifettoso;
var
  LState: IGameFileSystemInspector;
  LPack: IGamePack;
begin
  FDisk.AddFile('C:\d3\base\addon1.pk4', TMemoryZip.Make(['addon.conf'], ['no definition here']));
  FSettings.SearchAddons := True;
  Assert.IsTrue(Supports(Start, IGameFileSystemInspector, LState));
  for LPack in LState.Packs do
    if LPack.IsAddon then
    begin
      Assert.IsTrue(LPack.IsAddon);
      Assert.IsFalse(LPack.HasAddonInfo);
      Exit;
    end;
  Assert.Fail('no addon pak');
end;

procedure TTestGameFileSystemAddons.DovrebbeDareLaCartellaDelGioco;
var
  LSystem: IGameFileSystem;
  LState: IGameFileSystemInspector;
begin
  LSystem := TGameFileSystemFactory.CreateWithDisk(FDiskIntf, FSettings);
  Assert.IsTrue(Supports(LSystem, IGameFileSystemInspector, LState));
  Assert.AreEqual('', LState.GameFolder);
  Assert.IsFalse(LState.IsInitialized);
  LSystem.Startup;
  Assert.AreEqual('base', LState.GameFolder);
  Assert.IsTrue(LState.IsInitialized);
  FSettings.Game := 'mod';
  LSystem := TGameFileSystemFactory.CreateWithDisk(FDiskIntf, FSettings);
  LSystem.Startup;
  Assert.IsTrue(Supports(LSystem, IGameFileSystemInspector, LState));
  Assert.AreEqual('mod', LState.GameFolder);
  LSystem.Shutdown;
  Assert.AreEqual('', LState.GameFolder);
end;

procedure TTestGameFileSystemAddons.DovrebbeDareLeListeDeiPak;
var
  LSystem: IGameFileSystem;
  LState: IGameFileSystemInspector;
begin
  FDisk.AddFile('C:\d3\base\addon1.pk4', TMemoryZip.Make(['addon.conf'], ['addonDef { }']));
  LSystem := Start;
  Assert.IsTrue(Supports(LSystem, IGameFileSystemInspector, LState));
  Assert.AreEqual<Integer>(1, Length(LState.Packs));
  Assert.AreEqual<Integer>(1, Length(LState.AddonPacks));
  LSystem.Shutdown;
  Assert.WillRaise(procedure begin LState.Packs; end, EGameFsException);
  Assert.WillRaise(procedure begin LState.AddonPacks; end, EGameFsException);
end;

procedure TTestGameFileSystemAddons.DovrebbeCercareIPakConLEstensioneDelleImpostazioni;
var
  LSystem: IGameFileSystem;
  LData: TBytes;
begin
  // Quake III keeps its files in PK3, the same ZIP as a PK4
  FDisk.AddFile('C:\d3\baseq3\pak0.pk3', TMemoryZip.Make(['scripts/a.shader'], ['shader text']));
  FSettings.Game := 'baseq3';
  LSystem := Start;
  Assert.IsFalse(LSystem.ReadFile('scripts/a.shader', LData), 'not with the default extension');
  FSettings.PakExtension := '.pk3';
  LSystem := Start;
  Assert.IsTrue(LSystem.ReadFile('scripts/a.shader', LData));
  Assert.AreEqual('shader text', TEncoding.UTF8.GetString(LData));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGameAddonParser);
  TDUnitX.RegisterTestFixture(TTestGameFileSystemAddons);

end.
