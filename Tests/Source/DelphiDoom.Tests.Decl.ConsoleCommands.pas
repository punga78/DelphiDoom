{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the declaration manager - the console commands         }
{  (listDecls, reloadDecls, touch, list<Type>, print<Type>) and the numbers    }
{  behind them                                                                 }
{                                                                              }
{  The commands run in the real command system of Libs\Console (the idTech 4  }
{  profile) over a manager with decl files in memory. ListType and PrintType   }
{  were compared with the C++ in the golden of the manager; the text of the    }
{  commands themselves is checked against the code of DeclManager.cpp read     }
{  line by line (there is no harness of the C++ for the commands).             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.ConsoleCommands;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Console.CmdSystem.Types,
  DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Source.Intf, DelphiDoom.Decl.Source.Memory,
  DelphiDoom.Decl.Statistics.Intf, DelphiDoom.Decl.Console.Intf, DelphiDoom.Decl.Console.Commands,
  DelphiDoom.Tests.Scanner.IdFakes;

type
  /// <summary>A sound system that only remembers what it was told</summary>
  TFakeSoundMute = class(TInterfacedObject, IDeclSoundMute)
  strict private
    FCalls: string;
  public
    procedure SetMute(const AMute: Boolean);
    property Calls: string read FCalls;
  end;

  [TestFixture]
  [Category('decl')]
  TTestDeclConsoleCommands = class(TObject)
  strict private
    FSource: TDeclMemorySource;
    FSourceIntf: IDeclSource;
    FLogObject: TFakeIdLibLog;
    FLog: IIdLibLog;
    FManager: IDeclManager;
    FCommands: ICmdCommands;
    FBuffer: ICmdBuffer;
    FSound: TFakeSoundMute;
    FSoundIntf: IDeclSoundMute;
    FBinder: TDeclConsoleCommands;
    procedure Run(const ALine: string);
    function Output: string;
    procedure ClearOutput;
    function Completions(const ACommandLine: string): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareIlGestoreNil;
    [Test]
    procedure DovrebbeRifiutareIlSistemaDeiComandiNil;
    [Test]
    procedure DovrebbeRegistrareIComandiNellOrdineDelCodiceOriginale;
    [Test]
    procedure DovrebbeRegistrareTuttiIComandiComeSistema;
    [Test]
    procedure DovrebbeTenereLeDescrizioniDelCodiceOriginale;
    [Test]
    procedure DovrebbeElencareLeDichiarazioniDelTipo;
    [Test]
    procedure DovrebbeElencareLeDichiarazioniSenzaMaiuscole;
    [Test]
    procedure DovrebbeElencareSoloLeUsateOraDiDefault;
    [Test]
    procedure DovrebbeElencareQuelleUsateInUnLivelloPrecedente;
    [Test]
    procedure DovrebbeDareLeStatisticheDiListDecls;
    [Test]
    procedure DovrebbeSaltareITipiNonRegistratiInListDecls;
    [Test]
    procedure DovrebbeRicaricareSoloIFileCambiati;
    [Test]
    procedure DovrebbeRicaricareTuttiIFileConAll;
    [Test]
    procedure DovrebbeSilenziareIlSuonoMentreRicarica;
    [Test]
    procedure DovrebbeRicaricareSenzaSuono;
    [Test]
    procedure DovrebbeDireComeSiUsaTouch;
    [Test]
    procedure DovrebbeDireCheIlTipoNonEValido;
    [Test]
    procedure DovrebbeDireCheLaDichiarazioneManca;
    [Test]
    procedure DovrebbeUsareUnaDichiarazioneConTouch;
    [Test]
    procedure DovrebbeStampareUnaDichiarazione;
    [Test]
    procedure DovrebbeDireCheLaDichiarazioneDaStampareManca;
    [Test]
    procedure DovrebbeDireComeSiUsaPrint;
    [Test]
    procedure DovrebbeCompletareINomiDelleDichiarazioni;
    [Test]
    procedure DovrebbeCompletareLeParoleDelleListe;
    [Test]
    procedure DovrebbeFunzionareSenzaLog;
  end;

  [TestFixture]
  [Category('decl')]
  TTestDeclStatistics = class(TObject)
  strict private
    FSource: TDeclMemorySource;
    FSourceIntf: IDeclSource;
    FManager: IDeclManager;
    FStatistics: IDeclStatistics;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareIlNumeroDeiPosti;
    [Test]
    procedure DovrebbeDireQualiTipiSonoRegistrati;
    [Test]
    procedure DovrebbeSommareLeDimensioniDelleDichiarazioni;
    [Test]
    procedure DovrebbeContareIFileCaricati;
    [Test]
    procedure DovrebbeSommareLeDimensioniDeiFile;
    [Test]
    procedure DovrebbeContareUnFileCreatoDaCreateNewDecl;
    [Test]
    procedure DovrebbeRifiutareUnTipoNonRegistrato;
  end;

implementation

uses
  DelphiDoom.Console.CmdSystem.System, DelphiDoom.IdLib.Text.CmdArgs, DelphiDoom.Decl.Types, DelphiDoom.Decl.Factory;

const
  DEF_FILE = 'entityDef monster_a { "health" "100" }' + #10 + 'entityDef monster_b { "health" "200" }' + #10;

{ TFakeSoundMute }

procedure TFakeSoundMute.SetMute(const AMute: Boolean);
begin
  if AMute then
    FCalls := FCalls + 'mute;'
  else
    FCalls := FCalls + 'unmute;';
end;

{ TTestDeclConsoleCommands }

procedure TTestDeclConsoleCommands.Setup;
var
  LSystem: TCmdSystem;
begin
  FSource := TDeclMemorySource.Create;
  FSourceIntf := FSource;
  FSource.Add('def/a.def', DEF_FILE);
  FSource.Add('skins/s.skin', 'skin skin_a { }');
  FLogObject := TFakeIdLibLog.Create;
  FLog := FLogObject;
  FManager := TDeclFactory.CreateStandardManager(FSourceIntf, FLog);
  FManager.GetRegistry.RegisterDeclFolder('def', '.def', DECL_ENTITYDEF);
  LSystem := TCmdSystem.Create(FLog);
  FCommands := LSystem;
  FBuffer := LSystem;
  FSound := TFakeSoundMute.Create;
  FSoundIntf := FSound;
  FBinder := TDeclConsoleCommands.Create(FManager, FCommands, FLog, FSoundIntf);
  FBinder.Register;
end;

procedure TTestDeclConsoleCommands.TearDown;
begin
  FBinder.Free;
  FSoundIntf := nil;
  FSound := nil;
  FBuffer := nil;
  FCommands := nil;
  FManager := nil;
  FLog := nil;
  FLogObject := nil;
  FSourceIntf := nil;
  FSource := nil;
end;

procedure TTestDeclConsoleCommands.Run(const ALine: string);
begin
  FBuffer.BufferCommandText(TCmdExecution.ceAppend, AnsiString(ALine) + #10);
  FBuffer.ExecuteCommandBuffer;
end;

function TTestDeclConsoleCommands.Output: string;
begin
  Result := FLogObject.Lines.Text;
end;

procedure TTestDeclConsoleCommands.ClearOutput;
begin
  FLogObject.Lines.Clear;
end;

function TTestDeclConsoleCommands.Completions(const ACommandLine: string): string;
var
  LList: TStringList;
begin
  LList := TStringList.Create;
  try
    FCommands.ArgCompletion(AnsiString(ACommandLine),
      procedure(const AText: AnsiString)
      begin
        LList.Add(string(AText));
      end);
    LList.Delimiter := ';';
    LList.StrictDelimiter := True;
    Result := LList.DelimitedText;
  finally
    LList.Free;
  end;
end;

procedure TTestDeclConsoleCommands.DovrebbeRifiutareIlGestoreNil;
begin
  Assert.WillRaise(procedure begin TDeclConsoleCommands.Create(nil, FCommands); end, EArgumentNilException);
end;

procedure TTestDeclConsoleCommands.DovrebbeRifiutareIlSistemaDeiComandiNil;
begin
  Assert.WillRaise(procedure begin TDeclConsoleCommands.Create(FManager, nil); end, EArgumentNilException);
end;

procedure TTestDeclConsoleCommands.DovrebbeRegistrareIComandiNellOrdineDelCodiceOriginale;
var
  LInfos: TArray<TCmdInfo>;
  LNames: TStringList;
  LIndex: Integer;
begin
  LInfos := FCommands.Commands;
  Assert.AreEqual<Integer>(27, Length(LInfos));
  LNames := TStringList.Create;
  try
    // the last command registered is the first of the list
    for LIndex := High(LInfos) downto 0 do
      LNames.Add(string(LInfos[LIndex].Name));
    Assert.AreEqual(
      'listDecls,reloadDecls,touch,' +
      'listTables,listMaterials,listSkins,listSoundShaders,listEntityDefs,listFX,listParticles,listAF,' +
      'listPDAs,listEmails,listVideos,listAudios,' +
      'printTable,printMaterial,printSkin,printSoundShader,printEntityDef,printFX,printParticle,printAF,' +
      'printPDA,printEmail,printVideo,printAudio',
      LNames.CommaText.Replace('"', ''));
  finally
    LNames.Free;
  end;
end;

procedure TTestDeclConsoleCommands.DovrebbeRegistrareTuttiIComandiComeSistema;
var
  LInfo: TCmdInfo;
begin
  for LInfo in FCommands.Commands do
    Assert.AreEqual(CMD_FL_SYSTEM, LInfo.Flags, string(LInfo.Name));
end;

procedure TTestDeclConsoleCommands.DovrebbeTenereLeDescrizioniDelCodiceOriginale;
var
  LInfo: TCmdInfo;
  LFound: Integer;
begin
  LFound := 0;
  for LInfo in FCommands.Commands do
  begin
    if LInfo.Name = 'listDecls' then
      Assert.AreEqual('lists all decls', string(LInfo.Description));
    if LInfo.Name = 'touch' then
      Assert.AreEqual('touches a decl', string(LInfo.Description));
    if LInfo.Name = 'listFX' then
      Assert.AreEqual('lists FX systems', string(LInfo.Description));
    // the descriptions of the original have these two mistakes: kept
    if LInfo.Name = 'printVideo' then
      Assert.AreEqual('prints a Audio', string(LInfo.Description));
    if LInfo.Name = 'printAudio' then
      Assert.AreEqual('prints an Video', string(LInfo.Description));
    if LInfo.Name = 'printPDA' then
      Assert.AreEqual('prints an PDA', string(LInfo.Description));
    Inc(LFound);
  end;
  Assert.AreEqual(27, LFound);
end;

procedure TTestDeclConsoleCommands.DovrebbeElencareLeDichiarazioniDelTipo;
begin
  Run('listEntityDefs all');
  Assert.IsTrue(Output.Contains('--------------------'), Output);
  Assert.IsTrue(Output.Contains('2 of 2 entityDef'), Output);
  Assert.IsTrue(Output.Contains('monster_a'), Output);
  Assert.IsTrue(Output.Contains('monster_b'), Output);
end;

procedure TTestDeclConsoleCommands.DovrebbeElencareLeDichiarazioniSenzaMaiuscole;
begin
  Run('listEntityDefs ALL');
  Assert.IsTrue(Output.Contains('2 of 2 entityDef'), Output);
  ClearOutput;
  Run('listSkins All');
  Assert.IsTrue(Output.Contains('1 of 1 skin'), Output);
end;

procedure TTestDeclConsoleCommands.DovrebbeElencareSoloLeUsateOraDiDefault;
begin
  Run('listEntityDefs');
  Assert.IsTrue(Output.Contains('0 of 2 entityDef'), Output);
  ClearOutput;
  Run('touch entityDef monster_a');
  Run('listEntityDefs');
  Assert.IsTrue(Output.Contains('1 of 2 entityDef'), Output);
  Assert.IsTrue(Output.Contains('*'), Output);
end;

procedure TTestDeclConsoleCommands.DovrebbeElencareQuelleUsateInUnLivelloPrecedente;
begin
  // a decl first used while a level loads is purged when the next level starts (one used outside a level
  // load is never purged, as in the original)
  FManager.BeginLevelLoad;
  Run('touch entityDef monster_a');
  FManager.EndLevelLoad;
  FManager.BeginLevelLoad;
  FManager.EndLevelLoad;
  // parsed again without being referenced: the list of "ever" shows the parsed decls, "current" the referenced ones
  FManager.DeclByIndex(DECL_ENTITYDEF, 0, True);
  ClearOutput;
  Run('listEntityDefs');
  Assert.IsTrue(Output.Contains('0 of 2 entityDef'), Output);
  ClearOutput;
  Run('listEntityDefs ever');
  Assert.IsTrue(Output.Contains('1 of 2 entityDef'), Output);
end;

procedure TTestDeclConsoleCommands.DovrebbeDareLeStatisticheDiListDecls;
begin
  Run('listDecls');
  // "%4ik %4i %s": the size in KB, the number of decls and the name of the type, for each registered type
  Assert.IsTrue(Output.Contains('   2 entityDef'), Output);
  Assert.IsTrue(Output.Contains('   1 skin'), Output);
  Assert.IsTrue(Output.Contains('   0 table'), Output);
  Assert.IsTrue(Output.Contains('decl files'), Output);
  Assert.IsTrue(Output.Contains(' total decls is 2 decl files'), Output);
  Assert.IsTrue(Output.Contains('KB in text, '), Output);
  Assert.IsTrue(Output.Contains('KB in structures'), Output);
  // 3 decls: the two entity defs and the skin
  Assert.IsTrue(Output.Contains('3 total decls is 2 decl files'), Output);
end;

procedure TTestDeclConsoleCommands.DovrebbeSaltareITipiNonRegistratiInListDecls;
begin
  Run('listDecls');
  Assert.IsFalse(Output.Contains('modelDef'), Output);
  Assert.IsFalse(Output.Contains('export'), Output);
  Assert.IsTrue(Output.Contains('articulatedFigure'), Output);
  Assert.IsTrue(Output.Contains('mapDef'), Output);
end;

procedure TTestDeclConsoleCommands.DovrebbeRicaricareSoloIFileCambiati;
begin
  Run('touch entityDef monster_a');
  FSource.Add('def/a.def', 'entityDef monster_a { "health" "555" }' + #10 + 'entityDef monster_b { "health" "200" }' + #10);
  ClearOutput;
  Run('reloadDecls');
  Assert.IsTrue(Output.Contains('reloading changed decl files:'), Output);
  Assert.IsTrue(string(FManager.FindType(DECL_ENTITYDEF, 'monster_a', False).GetText).Contains('555'));
end;

procedure TTestDeclConsoleCommands.DovrebbeRicaricareTuttiIFileConAll;
var
  LReads: Integer;
begin
  Run('touch entityDef monster_a');
  LReads := FSource.ReadCount;
  Run('reloadDecls');
  Assert.AreEqual(LReads, FSource.ReadCount, 'nothing changed: nothing is read');
  ClearOutput;
  Run('reloadDecls all');
  Assert.IsTrue(Output.Contains('reloading all decl files:'), Output);
  Assert.IsTrue(FSource.ReadCount > LReads, 'every file is read again');
  ClearOutput;
  Run('reloadDecls ALL');
  Assert.IsTrue(Output.Contains('reloading all decl files:'), Output);
end;

procedure TTestDeclConsoleCommands.DovrebbeSilenziareIlSuonoMentreRicarica;
begin
  Run('reloadDecls');
  Assert.AreEqual('mute;unmute;', FSound.Calls);
end;

procedure TTestDeclConsoleCommands.DovrebbeRicaricareSenzaSuono;
var
  LBinder: TDeclConsoleCommands;
  LSystem: TCmdSystem;
  LCommands: ICmdCommands;
  LBuffer: ICmdBuffer;
begin
  LSystem := TCmdSystem.Create(FLog);
  LCommands := LSystem;
  LBuffer := LSystem;
  LBinder := TDeclConsoleCommands.Create(FManager, LCommands, FLog);
  try
    LBinder.Register;
    LBuffer.BufferCommandText(TCmdExecution.ceAppend, 'reloadDecls'#10);
    LBuffer.ExecuteCommandBuffer;
    Assert.IsTrue(Output.Contains('reloading changed decl files:'), Output);
  finally
    LBinder.Free;
  end;
end;

procedure TTestDeclConsoleCommands.DovrebbeDireComeSiUsaTouch;
begin
  Run('touch');
  Assert.IsTrue(Output.Contains('usage: touch <type> <name>'), Output);
  Assert.IsTrue(Output.Contains('valid types: table material skin sound entityDef fx particle articulatedFigure pda '),
    Output);
  ClearOutput;
  Run('touch entityDef');
  Assert.IsTrue(Output.Contains('usage: touch <type> <name>'), Output);
  ClearOutput;
  Run('touch entityDef a b');
  Assert.IsTrue(Output.Contains('usage: touch <type> <name>'), Output);
end;

procedure TTestDeclConsoleCommands.DovrebbeDireCheIlTipoNonEValido;
begin
  Run('touch widget x');
  Assert.IsTrue(Output.Contains('unknown decl type ''widget'''), Output);
end;

procedure TTestDeclConsoleCommands.DovrebbeDireCheLaDichiarazioneManca;
begin
  Run('touch entityDef nothing');
  Assert.IsTrue(Output.Contains('entityDef ''nothing'' not found'), Output);
  // the type is compared without regard to case
  ClearOutput;
  Run('touch ENTITYDEF nothing');
  Assert.IsTrue(Output.Contains('entityDef ''nothing'' not found'), Output);
end;

procedure TTestDeclConsoleCommands.DovrebbeUsareUnaDichiarazioneConTouch;
begin
  Run('touch entityDef monster_b');
  Assert.IsFalse(Output.Contains('not found'), Output);
  Assert.AreEqual(Ord(dsParsed), Ord(FManager.FindType(DECL_ENTITYDEF, 'monster_b', False).GetState));
end;

procedure TTestDeclConsoleCommands.DovrebbeStampareUnaDichiarazione;
begin
  Run('printEntityDef monster_a');
  Assert.IsTrue(Output.Contains('entityDef monster_a:'), Output);
  Assert.IsTrue(Output.Contains('source: def/a.def:'), Output);
  Assert.IsTrue(Output.Contains('"health" "100"'), Output);
  Assert.IsTrue(Output.Contains('Unparsed.'), Output);
  Assert.IsTrue(Output.Contains('Never referenced.'), Output);
end;

procedure TTestDeclConsoleCommands.DovrebbeDireCheLaDichiarazioneDaStampareManca;
begin
  Run('printSkin missing');
  Assert.IsTrue(Output.Contains('skin ''missing'' not found.'), Output);
end;

procedure TTestDeclConsoleCommands.DovrebbeDireComeSiUsaPrint;
begin
  Run('printEntityDef');
  Assert.IsTrue(Output.Contains('USAGE: Print<decl type> <decl name> [type specific parms]'), Output);
end;

procedure TTestDeclConsoleCommands.DovrebbeCompletareINomiDelleDichiarazioni;
begin
  Assert.AreEqual('printEntityDef monster_a;printEntityDef monster_b', Completions('printEntityDef '));
  Assert.AreEqual('printSkin skin_a', Completions('printSkin '));
  // the decls are not parsed by the completion
  Assert.AreEqual(Ord(dsUnparsed), Ord(FManager.DeclByIndex(DECL_ENTITYDEF, 0, False).GetState));
end;

procedure TTestDeclConsoleCommands.DovrebbeCompletareLeParoleDelleListe;
begin
  Assert.AreEqual('listTables current;listTables all;listTables ever', Completions('listTables '));
  Assert.AreEqual('', Completions('touch '));
end;

procedure TTestDeclConsoleCommands.DovrebbeFunzionareSenzaLog;
var
  LBinder: TDeclConsoleCommands;
  LSystem: TCmdSystem;
  LBuffer: ICmdBuffer;
  LCommands: ICmdCommands;
begin
  LSystem := TCmdSystem.Create(nil);
  LCommands := LSystem;
  LBuffer := LSystem;
  LBinder := TDeclConsoleCommands.Create(FManager, LCommands);
  try
    LBinder.Register;
    LBuffer.BufferCommandText(TCmdExecution.ceAppend, 'listDecls'#10'touch'#10'printSkin'#10'reloadDecls'#10'listSkins'#10);
    LBuffer.ExecuteCommandBuffer;
    Assert.IsTrue(True);
  finally
    LBinder.Free;
  end;
end;

{ TTestDeclStatistics }

procedure TTestDeclStatistics.Setup;
begin
  FSource := TDeclMemorySource.Create;
  FSourceIntf := FSource;
  FSource.Add('def/a.def', DEF_FILE);
  FManager := TDeclFactory.CreateStandardManager(FSourceIntf);
  FManager.GetRegistry.RegisterDeclFolder('def', '.def', DECL_ENTITYDEF);
  Assert.IsTrue(Supports(FManager, IDeclStatistics, FStatistics));
end;

procedure TTestDeclStatistics.TearDown;
begin
  FStatistics := nil;
  FManager := nil;
  FSourceIntf := nil;
  FSource := nil;
end;

procedure TTestDeclStatistics.DovrebbeDareIlNumeroDeiPosti;
begin
  // the list goes up to the highest number registered (mapDef, 14)
  Assert.AreEqual(15, FStatistics.GetTypeSlotCount);
end;

procedure TTestDeclStatistics.DovrebbeDireQualiTipiSonoRegistrati;
begin
  Assert.IsTrue(FStatistics.IsTypeRegistered(DECL_TABLE));
  Assert.IsTrue(FStatistics.IsTypeRegistered(DECL_MAPDEF));
  Assert.IsFalse(FStatistics.IsTypeRegistered(DECL_MODELDEF));
  Assert.IsFalse(FStatistics.IsTypeRegistered(DECL_MODELEXPORT));
  Assert.IsFalse(FStatistics.IsTypeRegistered(-1));
  Assert.IsFalse(FStatistics.IsTypeRegistered(99));
end;

procedure TTestDeclStatistics.DovrebbeSommareLeDimensioniDelleDichiarazioni;
var
  LBefore, LAfter: NativeInt;
begin
  Assert.AreEqual<NativeInt>(0, FStatistics.GetTypeSize(DECL_TABLE));
  LBefore := FStatistics.GetTypeSize(DECL_ENTITYDEF);
  Assert.IsTrue(LBefore > 0);
  // a decl that has its object takes more than one that has not
  FManager.FindType(DECL_ENTITYDEF, 'monster_a', False);
  LAfter := FStatistics.GetTypeSize(DECL_ENTITYDEF);
  Assert.IsTrue(LAfter >= LBefore);
end;

procedure TTestDeclStatistics.DovrebbeContareIFileCaricati;
begin
  Assert.AreEqual(1, FStatistics.GetLoadedFileCount);
end;

procedure TTestDeclStatistics.DovrebbeSommareLeDimensioniDeiFile;
begin
  Assert.AreEqual<Int64>(Length(DEF_FILE), FStatistics.GetLoadedFilesSize);
end;

procedure TTestDeclStatistics.DovrebbeContareUnFileCreatoDaCreateNewDecl;
begin
  FManager.CreateNewDecl(DECL_ENTITYDEF, 'created', 'def/new.def');
  Assert.AreEqual(2, FStatistics.GetLoadedFileCount);
end;

procedure TTestDeclStatistics.DovrebbeRifiutareUnTipoNonRegistrato;
begin
  Assert.WillRaise(procedure begin FStatistics.GetTypeSize(DECL_MODELDEF); end, EDeclException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclConsoleCommands);
  TDUnitX.RegisterTestFixture(TTestDeclStatistics);

end.
