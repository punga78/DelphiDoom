{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the BOTLIB system calls    }
{  of qagame through the host: the arguments read, the answers written in the   }
{  data of the program, the guards of the C before the library is set up and    }
{  before a map is loaded. The library behind the calls is the real one (the    }
{  bot AI and the AAS, which have their own parity with the C), on the botfiles  }
{  and the synthetic AAS of Tests\Data\BotAi                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.BotCalls;

interface

uses
  DUnitX.TestFramework, System.Classes, System.SysUtils, System.Generics.Collections, DelphiDoom.Qvm.Intf,
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.Console.Q3.Factory, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Types,
  DelphiDoom.Q3Host.ServerState, DelphiDoom.Q3Host.Services.Intf, DelphiDoom.Q3Host.Bot.Server,
  DelphiDoom.Tests.Q3Host.Support;

type
  /// <summary>botfiles from folders and a map of names to files (the .aas of the maps)</summary>
  TBotTestFiles = class(TInterfacedObject, IBotFileSource)
  strict private
    FRoots: TStringList;
    FNames: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddRoot(const AFolder: string);
    procedure Map(const AName, AFile: string);
    function TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
  end;

  [TestFixture]
  [Category('Q3Host')]
  [Category('Q3HostBot')]
  TTestQ3HostBotCalls = class
  strict private
    FConsole: TQ3Console;
    FPrinted: TQ3RecordingConsole;
    FPrintedIntf: IQ3HostConsole;
    FState: TQ3HostServerState;
    FStateIntf: IQ3HostServerState;
    FServer: TQ3HostBotServer;
    FServerIntf: IInterface;
    FHost: IQ3SyscallHost;
    FMachine: IQvmMachine;
    FCommands: TStringList;
    FChecksum: Integer;
    function Call(const AValues: array of Integer): Integer;
    procedure Put(AAddress: Integer; const AText: AnsiString);
    function Text(AAddress: Integer): string;
    function Bits(AValue: Single): Integer;
    function Float(AValue: Integer): Single;
    function PadWord: Integer;
    procedure SetUpHost(ABotEnable: Boolean; AWithBot: Boolean);
    function SetUpLibrary: Integer;
    procedure LoadBotWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure SenzaIServiziDelBotNessunaTrappaBotlibDovrebbeEssereRegistrata;
    [Test]
    procedure ConIServiziTutteLeBotlibTrannePcDovrebberoEssereRegistrate;
    [Test]
    procedure LaChiusuraSenzaSetupDovrebbeStampareELeggereUno;
    [Test]
    procedure ConBotEnableAZeroIlSetupNonDovrebbeFareNulla;
    [Test]
    procedure LeVariabiliDellaLibreriaDovrebberoTornareIndietroTroncate;
    [Test]
    procedure IlSetupDovrebbeTornareZeroELChiusuraDovrebbeRipartire;
    [Test]
    procedure IlFotogrammoELaMappaPrimaDelSetupDovrebberoDareErroreDelC;
    [Test]
    procedure UnEntitaFuoriIntervalloDovrebbeDareIlCodiceDelC;
    [Test]
    procedure LeAzioniElementariDovrebberoDareUnInputDelBot;
    [Test]
    procedure LAzioneGenericaDovrebbeTornareMenoUno;
    [Test]
    procedure UnComandoDiUnBotDovrebbeArrivareAlServerNelGioco;
    [Test]
    procedure IlComandoUtenteDovrebbeEssereMemorizzatoEFarePensareIlGioco;
    [Test]
    procedure IMessaggiDelServerDovrebberoArrivareAlBot;
    [Test]
    procedure UnCarattereDovrebbeDareLeSueCaratteristiche;
    [Test]
    procedure LaChatDovrebbeCodareEDareIMessaggiDellaConsole;
    [Test]
    procedure IlTestoDellaChatDovrebbeEssereModificatoSulPosto;
    [Test]
    procedure UnaSelezioneGeneticaDovrebbeScrivereITreNumeri;
    [Test]
    procedure LAasDovrebbeTornareLeRispostePrimaDellaMappa;
    [Test]
    procedure LaMappaDovrebbeInizializzareLAasEDareLeAree;
    [Test]
    procedure UnaEntitaAggiornataDovrebbeComparireNelleInformazioni;
    [Test]
    procedure UnaTracciaDelleAreeDovrebbeScrivereAreeEPunti;
    [Test]
    procedure IlRoutingDovrebbeEssereDelLaMappaInizializzata;
    [Test]
    procedure GliObiettiviDovrebberoEssereScrittiSoloDoveIlCLiScrive;
    [Test]
    procedure IlMovimentoDovrebbeScrivereIlRisultato;
    [Test]
    procedure UnaArmaDovrebbeDareLeSueInformazioniSoloSeEsiste;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Factory, DelphiDoom.MathCore.Types, DelphiDoom.Console.Q3.Types,
  DelphiDoom.Collision.Q3.Intf, DelphiDoom.Collision.Q3.Factory, DelphiDoom.MapFile.Bsp.Factory,
  DelphiDoom.Aas.Types, DelphiDoom.Aas.HeaderCipher, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.OpcodeCatalog,
  DelphiDoom.Q3Host.Factory, DelphiDoom.Q3Host.ClipMap, DelphiDoom.Q3Host.Bot.Intf,
  DelphiDoom.Q3Host.Bot.Memory, DelphiDoom.BotAi.Ea.Types, DelphiDoom.Tests.Qvm.Programs, DelphiDoom.Tests.Qvm.Support,
  DelphiDoom.Tests.Q3Host.Services, DelphiDoom.Tests.Shared.Files;

const
  // addresses in the data of the program
  ARG_A = 1000;
  ARG_B = 1100;
  ARG_C = 1200;
  BUFFER = 3000;
  OUT_A = 5000;
  OUT_B = 6000;
  PAD = $AB;
  MAP_NAME = 'botworld';

{ TBotTestFiles }

constructor TBotTestFiles.Create;
begin
  inherited Create;
  FRoots := TStringList.Create;
  FNames := TDictionary<string, string>.Create;
end;

destructor TBotTestFiles.Destroy;
begin
  FNames.Free;
  FRoots.Free;
  inherited Destroy;
end;

procedure TBotTestFiles.AddRoot(const AFolder: string);
begin
  FRoots.Add(AFolder);
end;

procedure TBotTestFiles.Map(const AName, AFile: string);
begin
  FNames.AddOrSetValue(LowerCase(AName), AFile);
end;

function TBotTestFiles.TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
var
  LFile, LRoot: string;
begin
  if FNames.TryGetValue(LowerCase(string(APath)), LFile) then
  begin
    AData := TFile.ReadAllBytes(LFile);
    Exit(True);
  end;
  for LRoot in FRoots do
  begin
    LFile := TPath.Combine(LRoot, StringReplace(string(APath), '/', PathDelim, [rfReplaceAll]));
    if TFile.Exists(LFile) then
    begin
      AData := TFile.ReadAllBytes(LFile);
      Exit(True);
    end;
  end;
  Result := False;
end;

{ TTestQ3HostBotCalls }

procedure TTestQ3HostBotCalls.Setup;
begin
  FCommands := TStringList.Create;
end;

procedure TTestQ3HostBotCalls.TearDown;
begin
  FMachine := nil;
  FHost := nil;
  FServerIntf := nil;
  FStateIntf := nil;
  FPrintedIntf := nil;
  FConsole.Free;
  FConsole := nil;
  FCommands.Free;
end;

function TTestQ3HostBotCalls.Call(const AValues: array of Integer): Integer;
begin
  Result := TQ3TestCalls.Invoke(FHost, FMachine, AValues);
end;

procedure TTestQ3HostBotCalls.Put(AAddress: Integer; const AText: AnsiString);
begin
  FMachine.Memory.WriteString(AAddress, AText, Length(AText) + 1);
end;

function TTestQ3HostBotCalls.Text(AAddress: Integer): string;
begin
  Result := string(FMachine.Memory.ReadString(AAddress));
end;

function TTestQ3HostBotCalls.Bits(AValue: Single): Integer;
begin
  Result := TQ3TestCalls.Bits(AValue);
end;

function TTestQ3HostBotCalls.PadWord: Integer;
var
  LValue: Cardinal;
begin
  LValue := $ABABABAB;
  Result := PInteger(@LValue)^;
end;

function TTestQ3HostBotCalls.Float(AValue: Integer): Single;
begin
  Result := TQ3TestCalls.Float(AValue);
end;

// the host of qagame with the services of phase 2b and, if AWithBot, the botfiles of the tests and a server with no
// network; the world is the synthetic BSP of the collision tests
procedure TTestQ3HostBotCalls.SetUpHost(ABotEnable: Boolean; AWithBot: Boolean);
var
  LServices: TQ3HostServices;
  LText: Integer;
  LModel: IQ3CollisionModel;
  LClipMap: TQ3HostClipMap;
  LFiles: TBotTestFiles;
  LHeader: TAasFileHeader;
  LBytes: TBytes;
  LGoalData: string;
begin
  FConsole := TQ3Console.Create;
  FConsole.Init;
  FConsole.CVars.Get('sv_maxclients', '8', 0);
  FConsole.CVars.Get('bot_enable', IntToStr(Ord(ABotEnable)), 0);
  LModel := TQ3CollisionFactory.CreateFromBytes(TBspFactory.CreateReader,
    TFile.ReadAllBytes(TTestFiles.DataFile('Collision', 'q3world0.bsp')), 'test.bsp',
    TQ3CollisionFactory.CreatePatchBuilder);
  LClipMap := TQ3HostClipMap.Create(nil);
  LClipMap.SetModel(LModel, 'maps/test.bsp');
  FState := TQ3HostServerState.Create(FConsole.CVars);
  FStateIntf := FState;
  FServer := TQ3HostBotServer.Create(FState,
    procedure(const AMachine: IQvmMachine; AClient: Integer; const ACommand: AnsiString)
    begin
      FCommands.Add(Format('%d %s', [AClient, string(ACommand)]));
    end);
  FServerIntf := FServer;
  FPrinted := TQ3RecordingConsole.Create(nil);
  FPrintedIntf := FPrinted;
  LServices := Default(TQ3HostServices);
  LServices.CVars := FConsole.CVars;
  LServices.Arguments := FConsole.Arguments;
  LServices.Buffer := FConsole.Buffer;
  LServices.Commands := FConsole.Commands;
  LServices.ClipMap := LClipMap;
  LServices.State := FStateIntf;
  LServices.ServerCommands := FServer;
  if AWithBot then
  begin
    LFiles := TBotTestFiles.Create;
    LFiles.AddRoot(TTestFiles.FindFolderUp('Tests\Data\BotAi'));
    LGoalData := TTestFiles.FindFolderUp('Tests\Data\BotAi\goal');
    LFiles.AddRoot(LGoalData);
    LFiles.Map('maps/' + MAP_NAME + '.aas', TPath.Combine(LGoalData, 'botworld.aas'));
    LServices.Bot.Files := LFiles;
    LServices.Bot.Server := FServer;
    // the checksum of the BSP the .aas was made for (the header is ciphered)
    LBytes := TFile.ReadAllBytes(TPath.Combine(LGoalData, 'botworld.aas'));
    Move(LBytes[0], LHeader, SizeOf(LHeader));
    if LHeader.Version = AAS_VERSION then
      TAasHeaderCipher.Apply(LHeader);
    FChecksum := LHeader.BspChecksum;
  end;
  FHost := TQ3HostFactory.CreateHostWithServices(TQ3Module.Game, FPrintedIntf, TQ3FixedTime.Create(0), LServices);
  FMachine := TQvmFactory.CreateMachine('botcalls', TQvmPrograms.AnySystemCall(LText), FHost);
  Call([G_LOCATE_GAME_DATA, 20000, 8, 516, 0, 0]);
end;

// BotInitLibrary of the game: the variables, then the setup; the result of BOTLIB_SETUP
function TTestQ3HostBotCalls.SetUpLibrary: Integer;
begin
  Put(ARG_A, 'sv_mapChecksum');
  Put(ARG_B, AnsiString(IntToStr(FChecksum)));
  Call([BOTLIB_LIBVAR_SET, ARG_A, ARG_B]);
  Put(ARG_A, 'maxclients');
  Put(ARG_B, '8');
  Call([BOTLIB_LIBVAR_SET, ARG_A, ARG_B]);
  Result := Call([BOTLIB_SETUP]);
end;

procedure TTestQ3HostBotCalls.LoadBotWorld;
begin
  Assert.AreEqual(0, SetUpLibrary);
  Put(ARG_A, MAP_NAME);
  Assert.AreEqual(0, Call([BOTLIB_LOAD_MAP, ARG_A]));
  // the initialization of the AAS goes on in the frames
  Call([BOTLIB_START_FRAME, Bits(1.0)]);
  Call([BOTLIB_START_FRAME, Bits(1.1)]);
end;

procedure TTestQ3HostBotCalls.SenzaIServiziDelBotNessunaTrappaBotlibDovrebbeEssereRegistrata;
begin
  SetUpHost(True, False);
  Assert.IsFalse(FHost.Registry.IsRegistered(BOTLIB_SETUP));
  Assert.IsFalse(FHost.Registry.IsRegistered(BOTLIB_EA_ATTACK));
  Assert.IsFalse(FHost.Registry.IsRegistered(BOTLIB_AI_MOVE_TO_GOAL));
end;

procedure TTestQ3HostBotCalls.ConIServiziTutteLeBotlibTrannePcDovrebberoEssereRegistrate;
var
  LEntry: TQ3OpcodeEntry;
  LBotlib, LMissing: Integer;
  LMissingNames: string;
begin
  SetUpHost(True, True);
  LBotlib := 0;
  LMissing := 0;
  LMissingNames := '';
  for LEntry in TQ3OpcodeCatalog.ImportEntries(TQ3Module.Game) do
    if LEntry.Name.StartsWith('BOTLIB_') then
    begin
      Inc(LBotlib);
      if not FHost.Registry.IsRegistered(LEntry.Value) then
      begin
        Inc(LMissing);
        LMissingNames := LMissingNames + ' ' + LEntry.Name;
      end;
    end;
  Assert.AreEqual(137, LBotlib);
  // the five PC_ calls: no module of Quake III or OpenArena calls them (trap_PC_* is in the .asm of cgame and ui only)
  Assert.AreEqual(5, LMissing, LMissingNames);
  Assert.IsTrue(LMissingNames.Contains('BOTLIB_PC_LOAD_SOURCE'), LMissingNames);
  Assert.IsFalse(FHost.Registry.IsRegistered(BOTLIB_PC_READ_TOKEN));
end;

procedure TTestQ3HostBotCalls.LaChiusuraSenzaSetupDovrebbeStampareELeggereUno;
begin
  SetUpHost(True, True);
  // BotLibSetup( "BotLibShutdown" ) fails: BLERR_LIBRARYNOTSETUP, and the message of be_interface.c
  Assert.AreEqual(1, Call([BOTLIB_SHUTDOWN]));
  Assert.AreEqual('^1Error: BotLibShutdown: bot library used before being setup'#10, FPrinted.Texts[FPrinted.Texts.Count - 1]);
end;

procedure TTestQ3HostBotCalls.ConBotEnableAZeroIlSetupNonDovrebbeFareNulla;
begin
  SetUpHost(False, True);
  Assert.AreEqual(0, SetUpLibrary);
  // nothing was set up, so a frame is still a use before the setup
  Assert.AreEqual(1, Call([BOTLIB_START_FRAME, Bits(1.0)]));
end;

procedure TTestQ3HostBotCalls.LeVariabiliDellaLibreriaDovrebberoTornareIndietroTroncate;
begin
  SetUpHost(True, True);
  Put(ARG_A, 'botvar');
  Put(ARG_B, 'abcdef');
  Assert.AreEqual(0, Call([BOTLIB_LIBVAR_SET, ARG_A, ARG_B]));
  FMachine.Memory.Fill(OUT_A, PAD, 16);
  Assert.AreEqual(0, Call([BOTLIB_LIBVAR_GET, ARG_A, OUT_A, 4]));
  // strncpy( value, text, size - 1 ) and the zero
  Assert.AreEqual('abc', Text(OUT_A));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_A + 4)));
  // a variable that does not exist is the empty text, and size 1 is only the zero
  Put(ARG_A, 'nothing');
  Assert.AreEqual(0, Call([BOTLIB_LIBVAR_GET, ARG_A, OUT_A, 8]));
  Assert.AreEqual('', Text(OUT_A));
end;

procedure TTestQ3HostBotCalls.IlSetupDovrebbeTornareZeroELChiusuraDovrebbeRipartire;
begin
  SetUpHost(True, True);
  Assert.AreEqual(0, SetUpLibrary);
  Assert.IsTrue(FPrinted.Texts.IndexOf('------- BotLib Initialization -------'#10) >= 0);
  Assert.AreEqual(0, Call([BOTLIB_SHUTDOWN]));
  // the variables went with it (LibVarDeAllocAll) and the setup can be done again
  Assert.AreEqual(0, SetUpLibrary);
  Assert.AreEqual(0, Call([BOTLIB_SHUTDOWN]));
  Assert.AreEqual(1, Call([BOTLIB_SHUTDOWN]));
end;

procedure TTestQ3HostBotCalls.IlFotogrammoELaMappaPrimaDelSetupDovrebberoDareErroreDelC;
begin
  SetUpHost(True, True);
  Assert.AreEqual(1, Call([BOTLIB_START_FRAME, Bits(1.0)]));
  Put(ARG_A, MAP_NAME);
  Assert.AreEqual(1, Call([BOTLIB_LOAD_MAP, ARG_A]));
  Assert.AreEqual(1, Call([BOTLIB_UPDATENTITY, 3, 0]));
  Assert.IsTrue(FPrinted.Texts.IndexOf('^1Error: BotStartFrame: bot library used before being setup'#10) >= 0);
  Assert.IsTrue(FPrinted.Texts.IndexOf('^1Error: BotLoadMap: bot library used before being setup'#10) >= 0);
  Assert.IsTrue(FPrinted.Texts.IndexOf('^1Error: BotUpdateEntity: bot library used before being setup'#10) >= 0);
end;

procedure TTestQ3HostBotCalls.UnEntitaFuoriIntervalloDovrebbeDareIlCodiceDelC;
begin
  SetUpHost(True, True);
  Assert.AreEqual(0, SetUpLibrary);
  // ValidEntityNumber: [0, maxentities], negative and above are BLERR_INVALIDENTITYNUMBER
  Assert.AreEqual(2, Call([BOTLIB_UPDATENTITY, -1, 0]));
  Assert.AreEqual(2, Call([BOTLIB_UPDATENTITY, 1025, 0]));
  Assert.IsTrue(FPrinted.Texts.IndexOf('^1Error: BotUpdateEntity: invalid entity number -1, [0, 1024]'#10) >= 0);
end;

procedure TTestQ3HostBotCalls.LeAzioniElementariDovrebberoDareUnInputDelBot;
var
  LIndex: Integer;
begin
  SetUpHost(True, True);
  Assert.AreEqual(0, SetUpLibrary);
  Call([BOTLIB_EA_MOVE_FORWARD, 2]);
  Call([BOTLIB_EA_ATTACK, 2]);
  Call([BOTLIB_EA_SELECT_WEAPON, 2, 5]);
  FMachine.Memory.WriteInt32(ARG_A, Bits(1));
  FMachine.Memory.WriteInt32(ARG_A + 4, Bits(0));
  FMachine.Memory.WriteInt32(ARG_A + 8, Bits(0.5));
  Call([BOTLIB_EA_MOVE, 2, ARG_A, Bits(250)]);
  FMachine.Memory.WriteInt32(ARG_B, Bits(10));
  FMachine.Memory.WriteInt32(ARG_B + 4, Bits(20));
  FMachine.Memory.WriteInt32(ARG_B + 8, Bits(30));
  Call([BOTLIB_EA_VIEW, 2, ARG_B]);
  FMachine.Memory.Fill(OUT_A, PAD, TQ3BotMemory.SIZE_INPUT + 8);
  Assert.AreEqual(0, Call([BOTLIB_EA_GET_INPUT, 2, Bits(0.05), OUT_A]));
  // bot_input_t: thinktime, dir, speed, viewangles, actionflags, weapon
  Assert.AreEqual(Single(0.05), Float(FMachine.Memory.ReadInt32(OUT_A)));
  Assert.AreEqual(Single(1), Float(FMachine.Memory.ReadInt32(OUT_A + 4)));
  Assert.AreEqual(Single(0.5), Float(FMachine.Memory.ReadInt32(OUT_A + 12)));
  Assert.AreEqual(Single(250), Float(FMachine.Memory.ReadInt32(OUT_A + 16)));
  Assert.AreEqual(Single(20), Float(FMachine.Memory.ReadInt32(OUT_A + 24)));
  Assert.AreEqual(ACTION_MOVEFORWARD or ACTION_ATTACK, FMachine.Memory.ReadInt32(OUT_A + 32) and (ACTION_MOVEFORWARD or ACTION_ATTACK));
  Assert.AreEqual(5, FMachine.Memory.ReadInt32(OUT_A + 36));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_A + TQ3BotMemory.SIZE_INPUT)));
  // the input of the bot goes back to nothing
  Assert.AreEqual(0, Call([BOTLIB_EA_RESET_INPUT, 2]));
  Call([BOTLIB_EA_GET_INPUT, 2, Bits(0.05), OUT_A]);
  for LIndex := 0 to 0 do
    Assert.AreEqual(0, FMachine.Memory.ReadInt32(OUT_A + 32) and (ACTION_MOVEFORWARD or ACTION_ATTACK));
end;

procedure TTestQ3HostBotCalls.LAzioneGenericaDovrebbeTornareMenoUno;
begin
  SetUpHost(True, True);
  Assert.AreEqual(0, SetUpLibrary);
  // BOTLIB_EA_ACTION ends its case with break: the function returns -1
  Assert.AreEqual(-1, Call([BOTLIB_EA_ACTION, 1, ACTION_JUMP]));
  Assert.AreEqual(0, Call([BOTLIB_EA_JUMP, 1]));
  // EA_EndRegular has an empty body
  Assert.AreEqual(0, Call([BOTLIB_EA_END_REGULAR, 1, Bits(0.1)]));
end;

procedure TTestQ3HostBotCalls.UnComandoDiUnBotDovrebbeArrivareAlServerNelGioco;
begin
  SetUpHost(True, True);
  Assert.AreEqual(0, SetUpLibrary);
  Put(ARG_A, 'say hello there');
  Call([BOTLIB_EA_COMMAND, 3, ARG_A]);
  Call([BOTLIB_EA_SAY, 3, ARG_A]);
  Call([BOTLIB_EA_SAY_TEAM, 4, ARG_A]);
  // EA_Command sends the line as it is; the other two put "say " and "say_team " in front
  Assert.AreEqual(3, FCommands.Count);
  Assert.AreEqual('3 say hello there', FCommands[0]);
  Assert.AreEqual('3 say say hello there', FCommands[1]);
  Assert.AreEqual('4 say_team say hello there', FCommands[2]);
end;

procedure TTestQ3HostBotCalls.IlComandoUtenteDovrebbeEssereMemorizzatoEFarePensareIlGioco;
var
  LIndex: Integer;
  LStored: TBytes;
begin
  SetUpHost(True, True);
  for LIndex := 0 to 23 do
    FMachine.Memory.WriteByte(ARG_A + LIndex, 100 + LIndex);
  // a client that is not active: the command is kept and the game does not think
  Assert.AreEqual(0, Call([BOTLIB_USER_COMMAND, 2, ARG_A]));
  LStored := FState.GetUsercmd(2);
  Assert.AreEqual(124 - 1, Integer(LStored[23]));
  Assert.AreEqual(100, Integer(LStored[0]));
  Assert.AreEqual(0, FPrinted.Texts.Count);
end;

procedure TTestQ3HostBotCalls.IMessaggiDelServerDovrebberoArrivareAlBot;
begin
  SetUpHost(True, True);
  FState.SetClientActive(1, True);
  FMachine.Memory.Fill(OUT_A, PAD, 64);
  // nothing yet: qfalse
  Assert.AreEqual(0, Call([BOTLIB_GET_CONSOLE_MESSAGE, 1, OUT_A, 64]));
  FServer.Send(-1, 'print "hello"');
  FServer.Send(1, 'chat "second"');
  Assert.AreEqual(1, Call([BOTLIB_GET_CONSOLE_MESSAGE, 1, OUT_A, 64]));
  Assert.AreEqual('print "hello"', Text(OUT_A));
  Assert.AreEqual(1, Call([BOTLIB_GET_CONSOLE_MESSAGE, 1, OUT_A, 8]));
  // Q_strncpyz( buf, command, size )
  Assert.AreEqual('chat "s', Text(OUT_A));
  Assert.AreEqual(0, Call([BOTLIB_GET_CONSOLE_MESSAGE, 1, OUT_A, 64]));
  // no snapshot: the entities of the last one are -1
  Assert.AreEqual(-1, Call([BOTLIB_GET_SNAPSHOT_ENTITY, 1, 0]));
  FServer.SetSnapshot(1, [5, 9]);
  Assert.AreEqual(9, Call([BOTLIB_GET_SNAPSHOT_ENTITY, 1, 1]));
  Assert.AreEqual(-1, Call([BOTLIB_GET_SNAPSHOT_ENTITY, 1, 2]));
end;

procedure TTestQ3HostBotCalls.UnCarattereDovrebbeDareLeSueCaratteristiche;
var
  LHandle: Integer;
begin
  SetUpHost(True, True);
  Assert.AreEqual(0, SetUpLibrary);
  Put(ARG_A, 'bots/default_c.c');
  LHandle := Call([BOTLIB_AI_LOAD_CHARACTER, ARG_A, Bits(1)]);
  Assert.IsTrue(LHandle > 0, 'handle');
  Assert.AreEqual(Single(0.25), Float(Call([BOTLIB_AI_CHARACTERISTIC_FLOAT, LHandle, 2])));
  Assert.AreEqual(7, Call([BOTLIB_AI_CHARACTERISTIC_INTEGER, LHandle, 3]));
  FMachine.Memory.Fill(OUT_A, PAD, 64);
  Assert.AreEqual(0, Call([BOTLIB_AI_CHARACTERISTIC_STRING, LHandle, 4, OUT_A, 64]));
  Assert.AreEqual('chat_default', Text(OUT_A));
  // bounded: the value is clamped to the range given
  Assert.AreEqual(Single(0.1), Float(Call([BOTLIB_AI_CHARACTERISTIC_BFLOAT, LHandle, 2, Bits(0), Bits(0.1)])));
  Assert.AreEqual(5, Call([BOTLIB_AI_CHARACTERISTIC_BINTEGER, LHandle, 3, 1, 5]));
  Assert.AreEqual(0, Call([BOTLIB_AI_FREE_CHARACTER, LHandle]));
end;

procedure TTestQ3HostBotCalls.LaChatDovrebbeCodareEDareIMessaggiDellaConsole;
var
  LChat: Integer;
begin
  SetUpHost(True, True);
  Assert.AreEqual(0, SetUpLibrary);
  LChat := Call([BOTLIB_AI_ALLOC_CHAT_STATE]);
  Assert.AreEqual(1, LChat);
  Put(ARG_A, 'hello bot');
  Assert.AreEqual(0, Call([BOTLIB_AI_QUEUE_CONSOLE_MESSAGE, LChat, 2, ARG_A]));
  Assert.AreEqual(1, Call([BOTLIB_AI_NUM_CONSOLE_MESSAGE, LChat]));
  FMachine.Memory.Fill(OUT_A, PAD, TQ3BotMemory.SIZE_CONSOLEMESSAGE + 8);
  // bot_consolemessage_t: handle, time, type, message[256], prev, next
  Assert.IsTrue(Call([BOTLIB_AI_NEXT_CONSOLE_MESSAGE, LChat, OUT_A]) > 0);
  Assert.AreEqual(2, FMachine.Memory.ReadInt32(OUT_A + 8));
  Assert.AreEqual('hello bot', Text(OUT_A + 12));
  Assert.AreEqual(0, FMachine.Memory.ReadInt32(OUT_A + 268));
  Assert.AreEqual(0, FMachine.Memory.ReadInt32(OUT_A + 272));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_A + TQ3BotMemory.SIZE_CONSOLEMESSAGE)));
  Assert.AreEqual(0, Call([BOTLIB_AI_REMOVE_CONSOLE_MESSAGE, LChat, 1]));
  // no more messages: 0 and the module's structure is left alone
  FMachine.Memory.Fill(OUT_B, PAD, 32);
  Assert.AreEqual(0, Call([BOTLIB_AI_NEXT_CONSOLE_MESSAGE, LChat, OUT_B]));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_B)));
  Assert.AreEqual(0, Call([BOTLIB_AI_FREE_CHAT_STATE, LChat]));
end;

procedure TTestQ3HostBotCalls.IlTestoDellaChatDovrebbeEssereModificatoSulPosto;
begin
  SetUpHost(True, True);
  Assert.AreEqual(0, SetUpLibrary);
  Put(ARG_A, 'hello   big    world');
  Assert.AreEqual(0, Call([BOTLIB_AI_UNIFY_WHITE_SPACES, ARG_A]));
  Assert.AreEqual('hello big world', Text(ARG_A));
  Put(ARG_A, 'Hello World');
  Put(ARG_B, 'world');
  // StringContains: the index of the second string in the first, case sensitive or not, -1 if it is not there
  Assert.AreEqual(6, Call([BOTLIB_AI_STRING_CONTAINS, ARG_A, ARG_B, 0]));
  Assert.AreEqual(-1, Call([BOTLIB_AI_STRING_CONTAINS, ARG_A, ARG_B, 1]));
  // the match is read, changed and written back (even when nothing matches: match->string is the text)
  Put(ARG_C, 'no template matches this text at all');
  FMachine.Memory.Fill(OUT_A, 0, TQ3BotMemory.SIZE_MATCH);
  Assert.AreEqual(0, Call([BOTLIB_AI_FIND_MATCH, ARG_C, OUT_A, 1]));
  Assert.AreEqual('no template matches this text at all', Text(OUT_A));
  // a variable that was not found is the empty string, and a variable out of range too
  FMachine.Memory.Fill(OUT_B, PAD, 16);
  Assert.AreEqual(0, Call([BOTLIB_AI_MATCH_VARIABLE, OUT_A, 20, OUT_B, 16]));
  Assert.AreEqual('', Text(OUT_B));
end;

procedure TTestQ3HostBotCalls.UnaSelezioneGeneticaDovrebbeScrivereITreNumeri;
var
  LIndex: Integer;
begin
  SetUpHost(True, True);
  Assert.AreEqual(0, SetUpLibrary);
  for LIndex := 0 to 4 do
    FMachine.Memory.WriteInt32(ARG_A + 4 * LIndex, Bits(1 + LIndex));
  FMachine.Memory.Fill(OUT_A, PAD, 16);
  Assert.AreEqual(1, Call([BOTLIB_AI_GENETIC_PARENTS_AND_CHILD_SELECTION, 5, ARG_A, OUT_A, OUT_A + 4, OUT_A + 8]));
  Assert.IsTrue(FMachine.Memory.ReadInt32(OUT_A) in [0..4]);
  Assert.IsTrue(FMachine.Memory.ReadInt32(OUT_A + 4) in [0..4]);
  Assert.IsTrue(FMachine.Memory.ReadInt32(OUT_A + 8) in [0..4]);
  // too few valid bots: false, and zeros
  FMachine.Memory.Fill(OUT_A, PAD, 16);
  Assert.AreEqual(0, Call([BOTLIB_AI_GENETIC_PARENTS_AND_CHILD_SELECTION, 2, ARG_A, OUT_A, OUT_A + 4, OUT_A + 8]));
  Assert.AreEqual(0, FMachine.Memory.ReadInt32(OUT_A));
  Assert.AreEqual(0, FMachine.Memory.ReadInt32(OUT_A + 8));
  // too many: false and zeros, and the ranks are not read
  FMachine.Memory.Fill(OUT_A, PAD, 16);
  Assert.AreEqual(0, Call([BOTLIB_AI_GENETIC_PARENTS_AND_CHILD_SELECTION, 257, ARG_A, OUT_A, OUT_A + 4, OUT_A + 8]));
  Assert.AreEqual(0, FMachine.Memory.ReadInt32(OUT_A + 4));
end;

procedure TTestQ3HostBotCalls.LAasDovrebbeTornareLeRispostePrimaDellaMappa;
begin
  SetUpHost(True, True);
  Assert.AreEqual(0, SetUpLibrary);
  Assert.AreEqual(0, Call([BOTLIB_AAS_INITIALIZED]));
  FMachine.Memory.WriteInt32(ARG_A, Bits(10));
  FMachine.Memory.WriteInt32(ARG_A + 4, Bits(20));
  FMachine.Memory.WriteInt32(ARG_A + 8, Bits(30));
  // no map: area 0, no reachability index, no travel time, no areas in a box
  Assert.AreEqual(0, Call([BOTLIB_AAS_POINT_AREA_NUM, ARG_A]));
  Assert.AreEqual(0, Call([BOTLIB_AAS_POINT_REACHABILITY_AREA_INDEX, ARG_A]));
  Assert.AreEqual(0, Call([BOTLIB_AAS_POINT_REACHABILITY_AREA_INDEX, 0]));
  Assert.AreEqual(0, Call([BOTLIB_AAS_AREA_TRAVEL_TIME_TO_GOAL_AREA, 1, ARG_A, 2, 0]));
  Assert.AreEqual(0, Call([BOTLIB_AAS_BBOX_AREAS, ARG_A, ARG_A, OUT_A, 8]));
  // AAS_AreaInfo says the number is out of range and keeps the structure; a NULL info is 0 without a word
  FMachine.Memory.Fill(OUT_B, PAD, 56);
  Assert.AreEqual(0, Call([BOTLIB_AAS_AREA_INFO, 1, OUT_B]));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_B)));
  Assert.AreEqual(0, Call([BOTLIB_AAS_AREA_INFO, 1, 0]));
  // AAS_AreaReachability: the AAS_Error of the C
  Assert.AreEqual(0, Call([BOTLIB_AAS_AREA_REACHABILITY, 5]));
  Assert.IsTrue(FPrinted.Texts.IndexOf('^1Fatal: AAS_AreaReachability: areanum 5 out of range'#10) >= 0);
  // a box of the player: AAS_PresenceTypeBoundingBox( PRESENCE_NORMAL )
  Assert.AreEqual(0, Call([BOTLIB_AAS_PRESENCE_TYPE_BOUNDING_BOX, 2, OUT_A, OUT_A + 12]));
  Assert.AreEqual(Single(-15), Float(FMachine.Memory.ReadInt32(OUT_A)));
  Assert.AreEqual(Single(-24), Float(FMachine.Memory.ReadInt32(OUT_A + 8)));
  Assert.AreEqual(Single(15), Float(FMachine.Memory.ReadInt32(OUT_A + 12)));
  Assert.AreEqual(Single(32), Float(FMachine.Memory.ReadInt32(OUT_A + 20)));
  // no AAS entity yet: the info is zeros
  FMachine.Memory.Fill(OUT_B, PAD, TQ3BotMemory.SIZE_ENTITYINFO);
  Call([BOTLIB_AAS_ENTITY_INFO, 1, OUT_B]);
  Assert.AreEqual(0, FMachine.Memory.ReadInt32(OUT_B));
  Assert.AreEqual(0, FMachine.Memory.ReadInt32(OUT_B + 4 * 10));
end;

procedure TTestQ3HostBotCalls.LaMappaDovrebbeInizializzareLAasEDareLeAree;
var
  LArea, LFound: Integer;
begin
  SetUpHost(True, True);
  LoadBotWorld;
  Assert.AreEqual(1, Call([BOTLIB_AAS_INITIALIZED]));
  Assert.AreEqual(Single(1.1), Float(Call([BOTLIB_AAS_TIME])));
  // the info of an area, and the point at its center is in the area
  LFound := 0;
  for LArea := 1 to 40 do
  begin
    FMachine.Memory.Fill(OUT_A, PAD, TQ3BotMemory.SIZE_AREAINFO + 8);
    if Call([BOTLIB_AAS_AREA_INFO, LArea, OUT_A]) <> TQ3BotMemory.SIZE_AREAINFO then
      Continue;
    Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_A + TQ3BotMemory.SIZE_AREAINFO)));
    Assert.AreEqual(LArea, Call([BOTLIB_AAS_POINT_AREA_NUM, OUT_A + 40]), 'area ' + IntToStr(LArea));
    // the box of the area finds the area
    FMachine.Memory.Fill(OUT_B, 0, 64);
    Assert.IsTrue(Call([BOTLIB_AAS_BBOX_AREAS, OUT_A + 16, OUT_A + 28, OUT_B, 16]) >= 1, 'box of area ' + IntToStr(LArea));
    Inc(LFound);
  end;
  Assert.IsTrue(LFound > 0, 'no area');
  Assert.IsTrue(Call([BOTLIB_AAS_AREA_REACHABILITY, 1]) >= 0);
  Assert.IsTrue(Call([BOTLIB_AAS_POINT_REACHABILITY_AREA_INDEX, 0]) > 0);
end;

procedure TTestQ3HostBotCalls.UnaEntitaAggiornataDovrebbeComparireNelleInformazioni;
var
  LIndex: Integer;
begin
  SetUpHost(True, True);
  LoadBotWorld;
  // bot_entitystate_t: the entity at 3 with a type and an origin
  FMachine.Memory.Fill(ARG_A, 0, TQ3BotMemory.SIZE_ENTITYSTATE);
  FMachine.Memory.WriteInt32(ARG_A, 2);
  FMachine.Memory.WriteInt32(ARG_A + 8, Bits(100));
  FMachine.Memory.WriteInt32(ARG_A + 12, Bits(200));
  FMachine.Memory.WriteInt32(ARG_A + 16, Bits(300));
  FMachine.Memory.WriteInt32(ARG_A + 76, 41);
  Assert.AreEqual(0, Call([BOTLIB_UPDATENTITY, 3, ARG_A]));
  FMachine.Memory.Fill(OUT_A, PAD, TQ3BotMemory.SIZE_ENTITYINFO + 8);
  Call([BOTLIB_AAS_ENTITY_INFO, 3, OUT_A]);
  Assert.AreEqual(1, FMachine.Memory.ReadInt32(OUT_A));
  Assert.AreEqual(2, FMachine.Memory.ReadInt32(OUT_A + 4));
  Assert.AreEqual(3, FMachine.Memory.ReadInt32(OUT_A + 20));
  Assert.AreEqual(Single(100), Float(FMachine.Memory.ReadInt32(OUT_A + 24)));
  Assert.AreEqual(Single(300), Float(FMachine.Memory.ReadInt32(OUT_A + 32)));
  Assert.AreEqual(41, FMachine.Memory.ReadInt32(OUT_A + 104));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_A + TQ3BotMemory.SIZE_ENTITYINFO)));
  // not updated in the next frame: it is not valid any more
  Call([BOTLIB_START_FRAME, Bits(1.2)]);
  Call([BOTLIB_AAS_ENTITY_INFO, 3, OUT_A]);
  Assert.AreEqual(0, FMachine.Memory.ReadInt32(OUT_A));
  for LIndex := 0 to 0 do
    // a NULL state unlinks the entity
    Assert.AreEqual(0, Call([BOTLIB_UPDATENTITY, 3, 0]));
end;

procedure TTestQ3HostBotCalls.UnaTracciaDelleAreeDovrebbeScrivereAreeEPunti;
var
  LCount: Integer;
begin
  SetUpHost(True, True);
  LoadBotWorld;
  Assert.AreEqual(TQ3BotMemory.SIZE_AREAINFO, Call([BOTLIB_AAS_AREA_INFO, 1, OUT_A]));
  // from the center of the first area to a point just above it
  FMachine.Memory.WriteInt32(ARG_C, FMachine.Memory.ReadInt32(OUT_A + 40));
  FMachine.Memory.WriteInt32(ARG_C + 4, FMachine.Memory.ReadInt32(OUT_A + 44));
  FMachine.Memory.WriteInt32(ARG_C + 8, Bits(Float(FMachine.Memory.ReadInt32(OUT_A + 48)) + 2));
  FMachine.Memory.Fill(OUT_B, PAD, 400);
  LCount := Call([BOTLIB_AAS_TRACE_AREAS, OUT_A + 40, ARG_C, OUT_B, OUT_B + 100, 8]);
  Assert.IsTrue(LCount >= 1, 'areas');
  Assert.AreEqual(1, FMachine.Memory.ReadInt32(OUT_B), 'first area');
  // one point per area, and nothing after the ones that were written
  Assert.AreNotEqual(PadWord, FMachine.Memory.ReadInt32(OUT_B + 100));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_B + 4 * LCount)));
  // a NULL list of areas and points is allowed
  Assert.AreEqual(LCount, Call([BOTLIB_AAS_TRACE_AREAS, OUT_A + 40, ARG_C, 0, 0, 8]));
end;

procedure TTestQ3HostBotCalls.IlRoutingDovrebbeEssereDelLaMappaInizializzata;
var
  LAreaA, LAreaB, LTime, LReach: Integer;
begin
  SetUpHost(True, True);
  LoadBotWorld;
  LAreaA := 0;
  LAreaB := 0;
  // two areas with a reachability: the travel time of the first to the second is not 0 and the route is a route
  for LAreaA := 1 to 40 do
    if Call([BOTLIB_AAS_AREA_REACHABILITY, LAreaA]) > 0 then
      Break;
  Assert.IsTrue(LAreaA <= 40, 'no area with reachabilities');
  LAreaB := LAreaA + 1;
  LTime := Call([BOTLIB_AAS_AREA_TRAVEL_TIME_TO_GOAL_AREA, LAreaA, 0, LAreaB, -1]);
  Assert.IsTrue(LTime >= 0);
  // PredictRoute writes the whole aas_predictroute_t, and the end area is the goal when there is a way
  FMachine.Memory.WriteInt32(ARG_A, 0);
  FMachine.Memory.WriteInt32(ARG_A + 4, 0);
  FMachine.Memory.WriteInt32(ARG_A + 8, 0);
  FMachine.Memory.Fill(OUT_A, PAD, TQ3BotMemory.SIZE_PREDICTROUTE + 8);
  LReach := Call([BOTLIB_AAS_PREDICT_ROUTE, OUT_A, LAreaA, ARG_A, LAreaA, -1, 10, 100, 0, 0, 0, 0]);
  Assert.AreEqual(1, LReach, 'the start is the goal');
  Assert.AreEqual(LAreaA, FMachine.Memory.ReadInt32(OUT_A + 12));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_A + TQ3BotMemory.SIZE_PREDICTROUTE)));
  // EnableRoutingArea answers with the old flag
  Assert.AreEqual(0, Call([BOTLIB_AAS_ENABLE_ROUTING_AREA, 0, 1]));
end;

procedure TTestQ3HostBotCalls.GliObiettiviDovrebberoEssereScrittiSoloDoveIlCLiScrive;
var
  LState, LIndex: Integer;
begin
  SetUpHost(True, True);
  LoadBotWorld;
  LState := Call([BOTLIB_AI_ALLOC_GOAL_STATE, 1]);
  Assert.AreEqual(1, LState);
  // a goal that the module pushes comes back as the top goal, in the same 56 bytes
  FMachine.Memory.Fill(ARG_A, 0, TQ3BotMemory.SIZE_GOAL);
  FMachine.Memory.WriteInt32(ARG_A, Bits(11));
  FMachine.Memory.WriteInt32(ARG_A + 12, 5);
  FMachine.Memory.WriteInt32(ARG_A + 40, 6);
  FMachine.Memory.WriteInt32(ARG_A + 44, 7);
  FMachine.Memory.WriteInt32(ARG_A + 48, 8);
  FMachine.Memory.WriteInt32(ARG_A + 52, 9);
  Assert.AreEqual(0, Call([BOTLIB_AI_PUSH_GOAL, LState, ARG_A]));
  FMachine.Memory.Fill(OUT_A, PAD, TQ3BotMemory.SIZE_GOAL + 8);
  Assert.AreEqual(1, Call([BOTLIB_AI_GET_TOP_GOAL, LState, OUT_A]));
  for LIndex := 0 to TQ3BotMemory.SIZE_GOAL div 4 - 1 do
    Assert.AreEqual(FMachine.Memory.ReadInt32(ARG_A + 4 * LIndex), FMachine.Memory.ReadInt32(OUT_A + 4 * LIndex));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_A + TQ3BotMemory.SIZE_GOAL)));
  // an empty stack: false, and the goal of the module is not touched
  Assert.AreEqual(0, Call([BOTLIB_AI_POP_GOAL, LState]));
  FMachine.Memory.Fill(OUT_A, PAD, TQ3BotMemory.SIZE_GOAL);
  Assert.AreEqual(0, Call([BOTLIB_AI_GET_TOP_GOAL, LState, OUT_A]));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_A)));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_A + TQ3BotMemory.SIZE_GOAL - 1)));
  // an item that is not in the level (-1) leaves the goal as it was; the name of the goal is written in a buffer
  Put(ARG_B, 'item_that_is_not_there');
  FMachine.Memory.Fill(OUT_B, PAD, TQ3BotMemory.SIZE_GOAL);
  Assert.AreEqual(-1, Call([BOTLIB_AI_GET_LEVEL_ITEM_GOAL, 0, ARG_B, OUT_B]));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_B)));
  FMachine.Memory.Fill(OUT_B, PAD, 32);
  Assert.AreEqual(0, Call([BOTLIB_AI_GOAL_NAME, 0, OUT_B, 32]));
  Assert.AreEqual(0, Call([BOTLIB_AI_FREE_GOAL_STATE, LState]));
end;

procedure TTestQ3HostBotCalls.IlMovimentoDovrebbeScrivereIlRisultato;
var
  LMove: Integer;
begin
  SetUpHost(True, True);
  LoadBotWorld;
  LMove := Call([BOTLIB_AI_ALLOC_MOVE_STATE]);
  Assert.AreEqual(1, LMove);
  // bot_initmove_t: the origin, the velocity, the view offset, the entity, the client, the think time ...
  FMachine.Memory.Fill(ARG_A, 0, TQ3BotMemory.SIZE_INITMOVE);
  FMachine.Memory.WriteInt32(ARG_A + 36, 1);
  FMachine.Memory.WriteInt32(ARG_A + 40, 1);
  FMachine.Memory.WriteInt32(ARG_A + 44, Bits(0.1));
  FMachine.Memory.WriteInt32(ARG_A + 48, 2);
  Assert.AreEqual(0, Call([BOTLIB_AI_INIT_MOVE_STATE, LMove, ARG_A]));
  // a goal in no area: the library has nothing to do and the result structure of the module is written whole
  FMachine.Memory.Fill(ARG_B, 0, TQ3BotMemory.SIZE_GOAL);
  FMachine.Memory.Fill(OUT_A, PAD, TQ3BotMemory.SIZE_MOVERESULT + 8);
  Assert.AreEqual(0, Call([BOTLIB_AI_MOVE_TO_GOAL, OUT_A, LMove, ARG_B, 0]));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_A + TQ3BotMemory.SIZE_MOVERESULT)));
  Assert.AreNotEqual(PadWord, FMachine.Memory.ReadInt32(OUT_A));
  Assert.AreEqual(0, Call([BOTLIB_AI_RESET_MOVE_STATE, LMove]));
  Assert.AreEqual(0, Call([BOTLIB_AI_FREE_MOVE_STATE, LMove]));
end;

procedure TTestQ3HostBotCalls.UnaArmaDovrebbeDareLeSueInformazioniSoloSeEsiste;
var
  LState: Integer;
begin
  SetUpHost(True, True);
  Assert.AreEqual(0, SetUpLibrary);
  LState := Call([BOTLIB_AI_ALLOC_WEAPON_STATE]);
  Assert.AreEqual(1, LState);
  FMachine.Memory.Fill(OUT_A, PAD, TQ3BotMemory.SIZE_WEAPONINFO + 8);
  // a weapon that does not exist (0 is not a valid number): the memory of the module is not touched
  Assert.AreEqual(0, Call([BOTLIB_AI_GET_WEAPON_INFO, LState, 0, OUT_A]));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_A)));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_A + TQ3BotMemory.SIZE_WEAPONINFO - 1)));
  // weapon 1 of the test configuration: valid, and the bytes are those of the 552 of weaponinfo_t
  Assert.AreEqual(0, Call([BOTLIB_AI_GET_WEAPON_INFO, LState, 1, OUT_A]));
  Assert.AreEqual(1, FMachine.Memory.ReadInt32(OUT_A));
  Assert.AreEqual(PAD, Integer(FMachine.Memory.ReadByte(OUT_A + TQ3BotMemory.SIZE_WEAPONINFO)));
  // the inventory of 256 integers: no weights, so no weapon
  FMachine.Memory.Fill(ARG_A, 0, 1024);
  Assert.AreEqual(0, Call([BOTLIB_AI_CHOOSE_BEST_FIGHT_WEAPON, LState, ARG_A]));
  Assert.AreEqual(0, Call([BOTLIB_AI_RESET_WEAPON_STATE, LState]));
  Assert.AreEqual(0, Call([BOTLIB_AI_FREE_WEAPON_STATE, LState]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3HostBotCalls);

end.
