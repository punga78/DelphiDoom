{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the server calls of        }
{  qagame: configstrings, user infos, commands of the server, bots, real time,  }
{  snap vector, and the world (link, area entities, trace, point contents,      }
{  contact, brush models) on the synthetic BSP of the collision tests           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.GameWorld;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Qvm.Intf, DelphiDoom.Console.Q3.Factory, DelphiDoom.Collision.Q3.Types,
  DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Services.Intf, DelphiDoom.Q3Host.ServerState, DelphiDoom.Q3Host.ClipMap,
  DelphiDoom.Tests.Q3Host.Services;

type
  /// <summary>The state calls of the server game, without a map</summary>
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3ServerCalls = class
  strict private
    FConsole: TQ3Console;
    FState: TQ3HostServerState;
    FStateIntf: IQ3HostServerState;
    FCommands: TQ3RecordingServerCommands;
    FCommandsIntf: IQ3HostServerCommands;
    FHost: IQ3SyscallHost;
    FMachine: IQvmMachine;
    FChanges: Integer;
    function Call(const AValues: array of Integer): Integer;
    procedure Put(AAddress: Integer; const AText: AnsiString);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LeConfigstringDovrebberoEssereScrittePerUnaVoltaESoloSeCambiano;
    [Test]
    procedure UnaConfigstringNullaDovrebbeEssereVuota;
    [Test]
    procedure UnIndiceNonValidoODiBufferZeroDovrebbeEssereUnErrore;
    [Test]
    procedure LeUserinfoDovrebberoEssereTroncateALimiteDelBuffer;
    [Test]
    procedure IComandiDelServerDovrebberoIgnorareIClientCheNonCi;
    [Test]
    procedure LUltimoComandoDovrebbeEssereScrittoPer24Byte;
    [Test]
    procedure IBotDovrebberoPrendereIlPrimoPostoLibero;
    [Test]
    procedure LaOraRealeDovrebbeScrivereLaStrutturaDiNoveInteri;
    [Test]
    procedure LoSnapVectorDovrebbeArrotondareAlPariComeLX87;
    [Test]
    procedure IPoligoniDiDebugDovrebberoRispondereZero;
    [Test]
    procedure IlTokenDellEntitaSenzaMappaDovrebbeEssereFinito;
  end;

  /// <summary>The world of the server game on a map</summary>
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3GameWorld = class
  strict private
    FConsole: TQ3Console;
    FClipMap: TQ3HostClipMap;
    FClipMapIntf: IQ3HostClipMap;
    FHost: IQ3SyscallHost;
    FMachine: IQvmMachine;
    FFree: TQ3Vec3;
    function Call(const AValues: array of Integer): Integer;
    procedure PutVec(AAddress: Integer; AX, AY, AZ: Single);
    procedure SetEntity(ANumber: Integer; const AOrigin: TQ3Vec3; AContents: Integer);
    function EntityAddress(ANumber: Integer): Integer;
    function Trace(const AStart, AEnd: TQ3Vec3; APass, AMask: Integer): TQ3Trace;
    function FindFreeRun: TQ3Vec3;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlCollegamentoDovrebbeScrivereIlBoxAssolutoELaDimensione;
    [Test]
    procedure LEntitaCollegataDovrebbeEssereNellaListaDellAreaEDopoLoScollegamentoNo;
    [Test]
    procedure UnNuovoCollegamentoNonDovrebbeDuplicareLEntita;
    [Test]
    procedure UnaTracciaControUnEntitaDovrebbeFermarsiSulSuoBox;
    [Test]
    procedure IlPassEntityEISuoiMissiliDovrebberoEssereSaltati;
    [Test]
    procedure LaMascheraDovrebbeEscludereLeEntitaSenzaQuelContenuto;
    [Test]
    procedure IlContenutoDiUnPuntoDovrebbeIncludereLEntita;
    [Test]
    procedure IlContattoDovrebbeEssereVeroSoloDentroLEntita;
    [Test]
    procedure UnModelloDiBrushDovrebbePrendereLeMisureDelModello;
    [Test]
    procedure UnNomeCheNonEUnModelloDiBrushDovrebbeEssereUnErrore;
    [Test]
    procedure UnaEntitaFuoriIntervalloDovrebbeEssereUnErrore;
    [Test]
    procedure LaListaEntitaDovrebbeFermarsiAlMassimoRichiesto;
    [Test]
    procedure PuntiNellaStessaAreaDovrebberoVedersiNelPvs;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Factory, DelphiDoom.Console.Q3.Types,
  DelphiDoom.Collision.Q3.Intf, DelphiDoom.Collision.Q3.Factory, DelphiDoom.MapFile.Bsp.Factory,
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Factory, DelphiDoom.Q3Host.GameWorld,
  DelphiDoom.Q3Host.TraceMemory, DelphiDoom.Tests.Qvm.Programs, DelphiDoom.Tests.Qvm.Support,
  DelphiDoom.Tests.Q3Host.Support, DelphiDoom.Tests.Shared.Files;

const
  TEXT_ADDRESS = 1000;
  BUFFER_ADDRESS = 6000;
  ENTITY_BASE = 2200;
  ENTITY_SIZE = 516;
  ENTITY_COUNT = 7;
  VEC_START = 1100;
  VEC_MINS = 1116;
  VEC_MAXS = 1132;
  VEC_END = 1148;
  TRACE_ADDRESS = 1200;
  LIST_ADDRESS = 1300;
  CONTENTS_BODY = $2000000;
  CONTENTS_SOLID = 1;

{ TTestQ3ServerCalls }

procedure TTestQ3ServerCalls.Setup;
var
  LServices: TQ3HostServices;
  LText: Integer;
begin
  FConsole := TQ3Console.Create;
  FConsole.Init;
  FConsole.CVars.Get('sv_maxclients', '8', 0);
  FState := TQ3HostServerState.Create(FConsole.CVars);
  FStateIntf := FState;
  FChanges := 0;
  FState.OnConfigstringChanged :=
    procedure(AIndex: Integer; const AValue: AnsiString)
    begin
      Inc(FChanges);
    end;
  FCommands := TQ3RecordingServerCommands.Create;
  FCommandsIntf := FCommands;
  LServices := Default(TQ3HostServices);
  LServices.CVars := FConsole.CVars;
  LServices.Arguments := FConsole.Arguments;
  LServices.Buffer := FConsole.Buffer;
  LServices.Commands := FConsole.Commands;
  LServices.ClipMap := TQ3HostClipMap.Create(nil);
  LServices.State := FStateIntf;
  LServices.ServerCommands := FCommandsIntf;
  LServices.Calendar := TQ3FixedCalendar.Create;
  FHost := TQ3HostFactory.CreateHostWithServices(TQ3Module.Game, TQ3RecordingConsole.Create(nil),
    TQ3FixedTime.Create(0), LServices);
  FMachine := TQvmFactory.CreateMachine('state', TQvmPrograms.AnySystemCall(LText), FHost);
end;

procedure TTestQ3ServerCalls.TearDown;
begin
  FMachine := nil;
  FHost := nil;
  FState.OnConfigstringChanged := nil;
  FConsole.Free;
end;

function TTestQ3ServerCalls.Call(const AValues: array of Integer): Integer;
begin
  Result := TQ3TestCalls.Invoke(FHost, FMachine, AValues);
end;

procedure TTestQ3ServerCalls.Put(AAddress: Integer; const AText: AnsiString);
begin
  FMachine.Memory.WriteString(AAddress, AText, Length(AText) + 1);
end;

procedure TTestQ3ServerCalls.LeConfigstringDovrebberoEssereScrittePerUnaVoltaESoloSeCambiano;
begin
  Put(TEXT_ADDRESS, 'n\mapname\q3dm1');
  Call([G_SET_CONFIGSTRING, 4, TEXT_ADDRESS]);
  Assert.AreEqual(1, FChanges);
  // the same text: no update is sent
  Call([G_SET_CONFIGSTRING, 4, TEXT_ADDRESS]);
  Assert.AreEqual(1, FChanges);
  Call([G_GET_CONFIGSTRING, 4, BUFFER_ADDRESS, 64]);
  Assert.AreEqual('n\mapname\q3dm1', string(FMachine.Memory.ReadString(BUFFER_ADDRESS)));
  // cut to the buffer with the zero
  Call([G_GET_CONFIGSTRING, 4, BUFFER_ADDRESS, 4]);
  Assert.AreEqual('n\m', string(FMachine.Memory.ReadString(BUFFER_ADDRESS)));
  // a string that was never set is empty
  Call([G_GET_CONFIGSTRING, 5, BUFFER_ADDRESS, 64]);
  Assert.AreEqual('', string(FMachine.Memory.ReadString(BUFFER_ADDRESS)));
end;

procedure TTestQ3ServerCalls.UnaConfigstringNullaDovrebbeEssereVuota;
begin
  Put(TEXT_ADDRESS, 'x');
  Call([G_SET_CONFIGSTRING, 7, TEXT_ADDRESS]);
  Call([G_SET_CONFIGSTRING, 7, 0]);
  Call([G_GET_CONFIGSTRING, 7, BUFFER_ADDRESS, 64]);
  Assert.AreEqual('', string(FMachine.Memory.ReadString(BUFFER_ADDRESS)));
  Assert.AreEqual(2, FChanges);
end;

procedure TTestQ3ServerCalls.UnIndiceNonValidoODiBufferZeroDovrebbeEssereUnErrore;
begin
  Put(TEXT_ADDRESS, 'x');
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      Call([G_SET_CONFIGSTRING, 1024, TEXT_ADDRESS]);
    end, EQ3HostException));
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      Call([G_GET_CONFIGSTRING, -1, BUFFER_ADDRESS, 8]);
    end, EQ3HostException));
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      Call([G_GET_CONFIGSTRING, 3, BUFFER_ADDRESS, 0]);
    end, EQ3HostException));
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      Call([G_GET_USERINFO, 8, BUFFER_ADDRESS, 8]);
    end, EQ3HostException));
end;

procedure TTestQ3ServerCalls.LeUserinfoDovrebberoEssereTroncateALimiteDelBuffer;
begin
  Put(TEXT_ADDRESS, '\name\Player\skill\5');
  Call([G_SET_USERINFO, 2, TEXT_ADDRESS]);
  Call([G_GET_USERINFO, 2, BUFFER_ADDRESS, 64]);
  Assert.AreEqual('\name\Player\skill\5', string(FMachine.Memory.ReadString(BUFFER_ADDRESS)));
  Call([G_GET_USERINFO, 2, BUFFER_ADDRESS, 8]);
  Assert.AreEqual('\name\P', string(FMachine.Memory.ReadString(BUFFER_ADDRESS)));
  // NULL is empty
  Call([G_SET_USERINFO, 2, 0]);
  Call([G_GET_USERINFO, 2, BUFFER_ADDRESS, 64]);
  Assert.AreEqual('', string(FMachine.Memory.ReadString(BUFFER_ADDRESS)));
end;

procedure TTestQ3ServerCalls.IComandiDelServerDovrebberoIgnorareIClientCheNonCi;
begin
  Put(TEXT_ADDRESS, 'print "hi"');
  Call([G_SEND_SERVER_COMMAND, -1, TEXT_ADDRESS]);
  Call([G_SEND_SERVER_COMMAND, 3, TEXT_ADDRESS]);
  Call([G_SEND_SERVER_COMMAND, 8, TEXT_ADDRESS]);
  Call([G_SEND_SERVER_COMMAND, -2, TEXT_ADDRESS]);
  Assert.AreEqual(2, FCommands.Sent.Count);
  Assert.AreEqual('-1:print "hi"', FCommands.Sent[0]);
  Assert.AreEqual('3:print "hi"', FCommands.Sent[1]);
  Put(TEXT_ADDRESS, 'kicked');
  Call([G_DROP_CLIENT, 1, TEXT_ADDRESS]);
  Call([G_DROP_CLIENT, 9, TEXT_ADDRESS]);
  Assert.AreEqual(1, FCommands.Dropped.Count);
  Assert.AreEqual('1:kicked', FCommands.Dropped[0]);
end;

procedure TTestQ3ServerCalls.LUltimoComandoDovrebbeEssereScrittoPer24Byte;
var
  LCommand: TBytes;
  LIndex: Integer;
begin
  SetLength(LCommand, 24);
  for LIndex := 0 to 23 do
    LCommand[LIndex] := LIndex + 1;
  FState.SetUsercmd(3, LCommand);
  FMachine.Memory.Fill(BUFFER_ADDRESS, $EE, 32);
  Call([G_GET_USERCMD, 3, BUFFER_ADDRESS]);
  for LIndex := 0 to 23 do
    Assert.AreEqual(LIndex + 1, Integer(FMachine.Memory.ReadByte(BUFFER_ADDRESS + LIndex)));
  Assert.AreEqual($EE, Integer(FMachine.Memory.ReadByte(BUFFER_ADDRESS + 24)));
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      Call([G_GET_USERCMD, 9, BUFFER_ADDRESS]);
    end, EQ3HostException));
end;

procedure TTestQ3ServerCalls.IBotDovrebberoPrendereIlPrimoPostoLibero;
var
  LMemory: IQvmMemory;
begin
  LMemory := FMachine.Memory;
  // 8 entities of 516 bytes at ENTITY_BASE
  Call([G_LOCATE_GAME_DATA, ENTITY_BASE, ENTITY_COUNT, ENTITY_SIZE, 7000, 100]);
  FState.SetClientActive(0, True);
  Assert.AreEqual(1, Call([G_BOT_ALLOCATE_CLIENT]));
  Assert.AreEqual(1, LMemory.ReadInt32(ENTITY_BASE + ENTITY_SIZE));
  Assert.AreEqual(2, Call([G_BOT_ALLOCATE_CLIENT]));
  // freeing clears SVF_BOT of the entity (r.svFlags is at 424)
  LMemory.WriteInt32(ENTITY_BASE + ENTITY_SIZE + 424, 8 or 1);
  Call([G_BOT_FREE_CLIENT, 1]);
  Assert.AreEqual(1, LMemory.ReadInt32(ENTITY_BASE + ENTITY_SIZE + 424));
  Assert.AreEqual(1, Call([G_BOT_ALLOCATE_CLIENT]));
  // all the 8 slots in use: none is left
  FState.SetClientActive(3, True);
  FState.SetClientActive(4, True);
  FState.SetClientActive(5, True);
  FState.SetClientActive(6, True);
  FState.SetClientActive(7, True);
  Assert.AreEqual(-1, Call([G_BOT_ALLOCATE_CLIENT]));
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      Call([G_BOT_FREE_CLIENT, 8]);
    end, EQ3HostException));
end;

procedure TTestQ3ServerCalls.LaOraRealeDovrebbeScrivereLaStrutturaDiNoveInteri;
var
  LMemory: IQvmMemory;
begin
  LMemory := FMachine.Memory;
  LMemory.Fill(BUFFER_ADDRESS, $EE, 40);
  Assert.AreEqual(1780000000, Call([G_REAL_TIME, BUFFER_ADDRESS]));
  Assert.AreEqual(1, LMemory.ReadInt32(BUFFER_ADDRESS));
  Assert.AreEqual(126, LMemory.ReadInt32(BUFFER_ADDRESS + 20));
  Assert.AreEqual(155, LMemory.ReadInt32(BUFFER_ADDRESS + 28));
  Assert.AreEqual(1, LMemory.ReadInt32(BUFFER_ADDRESS + 32));
  Assert.AreEqual($EE, Integer(LMemory.ReadByte(BUFFER_ADDRESS + 36)));
  // a null pointer asks only for the seconds
  Assert.AreEqual(1780000000, Call([G_REAL_TIME, 0]));
end;

procedure TTestQ3ServerCalls.LoSnapVectorDovrebbeArrotondareAlPariComeLX87;
var
  LMemory: IQvmMemory;
begin
  LMemory := FMachine.Memory;
  LMemory.WriteInt32(BUFFER_ADDRESS, TQ3TestCalls.Bits(1.5));
  LMemory.WriteInt32(BUFFER_ADDRESS + 4, TQ3TestCalls.Bits(2.5));
  LMemory.WriteInt32(BUFFER_ADDRESS + 8, TQ3TestCalls.Bits(-0.4));
  Call([G_SNAPVECTOR, BUFFER_ADDRESS]);
  Assert.AreEqual(Single(2), TQ3TestCalls.Float(LMemory.ReadInt32(BUFFER_ADDRESS)));
  Assert.AreEqual(Single(2), TQ3TestCalls.Float(LMemory.ReadInt32(BUFFER_ADDRESS + 4)));
  // fistp gives the integer 0 and the float of it is +0
  Assert.AreEqual(0, LMemory.ReadInt32(BUFFER_ADDRESS + 8));
  LMemory.WriteInt32(BUFFER_ADDRESS, TQ3TestCalls.Bits(1.0E10));
  LMemory.WriteInt32(BUFFER_ADDRESS + 4, TQ3TestCalls.Bits(-3.5));
  LMemory.WriteInt32(BUFFER_ADDRESS + 8, Integer($7FC00000));
  Call([G_SNAPVECTOR, BUFFER_ADDRESS]);
  // the integer indefinite of fistp
  Assert.AreEqual(Single(-2147483648.0), TQ3TestCalls.Float(LMemory.ReadInt32(BUFFER_ADDRESS)));
  Assert.AreEqual(Single(-4), TQ3TestCalls.Float(LMemory.ReadInt32(BUFFER_ADDRESS + 4)));
  Assert.AreEqual(Single(-2147483648.0), TQ3TestCalls.Float(LMemory.ReadInt32(BUFFER_ADDRESS + 8)));
end;

procedure TTestQ3ServerCalls.IPoligoniDiDebugDovrebberoRispondereZero;
begin
  Assert.AreEqual(0, Call([G_DEBUG_POLYGON_CREATE, 1, 4, BUFFER_ADDRESS]));
  Assert.AreEqual(0, Call([G_DEBUG_POLYGON_DELETE, 1]));
end;

procedure TTestQ3ServerCalls.IlTokenDellEntitaSenzaMappaDovrebbeEssereFinito;
begin
  FMachine.Memory.Fill(BUFFER_ADDRESS, $55, 8);
  // no map: the text is empty, so the first token is the end
  Assert.AreEqual(0, Call([G_GET_ENTITY_TOKEN, BUFFER_ADDRESS, 8]));
  Assert.AreEqual(0, Integer(FMachine.Memory.ReadByte(BUFFER_ADDRESS)));
end;

{ TTestQ3GameWorld }

procedure TTestQ3GameWorld.Setup;
var
  LServices: TQ3HostServices;
  LText: Integer;
  LModel: IQ3CollisionModel;
  LPath: string;
begin
  FConsole := TQ3Console.Create;
  FConsole.Init;
  FConsole.CVars.Get('sv_maxclients', '8', 0);
  LPath := TTestFiles.DataFile('Collision', 'q3world0.bsp');
  LModel := TQ3CollisionFactory.CreateFromBytes(TBspFactory.CreateReader, TFile.ReadAllBytes(LPath), 'test.bsp',
    TQ3CollisionFactory.CreatePatchBuilder);
  FClipMap := TQ3HostClipMap.Create(nil);
  FClipMapIntf := FClipMap;
  FClipMap.SetModel(LModel, 'maps/test.bsp');
  LServices := Default(TQ3HostServices);
  LServices.CVars := FConsole.CVars;
  LServices.Arguments := FConsole.Arguments;
  LServices.Buffer := FConsole.Buffer;
  LServices.Commands := FConsole.Commands;
  LServices.ClipMap := FClipMapIntf;
  LServices.State := TQ3HostServerState.Create(FConsole.CVars);
  LServices.ServerCommands := TQ3RecordingServerCommands.Create;
  FHost := TQ3HostFactory.CreateHostWithServices(TQ3Module.Game, TQ3RecordingConsole.Create(nil),
    TQ3FixedTime.Create(0), LServices);
  FMachine := TQvmFactory.CreateMachine('world', TQvmPrograms.AnySystemCall(LText), FHost);
  Call([G_LOCATE_GAME_DATA, ENTITY_BASE, ENTITY_COUNT, ENTITY_SIZE, 0, 0]);
  FFree := FindFreeRun;
end;

procedure TTestQ3GameWorld.TearDown;
begin
  FMachine := nil;
  FHost := nil;
  FClipMapIntf := nil;
  FConsole.Free;
end;

function TTestQ3GameWorld.Call(const AValues: array of Integer): Integer;
begin
  Result := TQ3TestCalls.Invoke(FHost, FMachine, AValues);
end;

procedure TTestQ3GameWorld.PutVec(AAddress: Integer; AX, AY, AZ: Single);
begin
  FMachine.Memory.WriteInt32(AAddress, TQ3TestCalls.Bits(AX));
  FMachine.Memory.WriteInt32(AAddress + 4, TQ3TestCalls.Bits(AY));
  FMachine.Memory.WriteInt32(AAddress + 8, TQ3TestCalls.Bits(AZ));
end;

function TTestQ3GameWorld.EntityAddress(ANumber: Integer): Integer;
begin
  Result := ENTITY_BASE + ENTITY_SIZE * ANumber;
end;

procedure TTestQ3GameWorld.SetEntity(ANumber: Integer; const AOrigin: TQ3Vec3; AContents: Integer);
var
  LAddress: Integer;
begin
  LAddress := EntityAddress(ANumber);
  FMachine.Memory.Fill(LAddress, 0, ENTITY_SIZE);
  FMachine.Memory.WriteInt32(LAddress + TQ3GameWorld.OFFSET_NUMBER, ANumber);
  PutVec(LAddress + TQ3GameWorld.OFFSET_ORIGIN, AOrigin[0], AOrigin[1], AOrigin[2]);
  PutVec(LAddress + TQ3GameWorld.OFFSET_CURRENTORIGIN, AOrigin[0], AOrigin[1], AOrigin[2]);
  PutVec(LAddress + TQ3GameWorld.OFFSET_MINS, -15, -15, -24);
  PutVec(LAddress + TQ3GameWorld.OFFSET_MAXS, 15, 15, 32);
  FMachine.Memory.WriteInt32(LAddress + TQ3GameWorld.OFFSET_CONTENTS, AContents);
  FMachine.Memory.WriteInt32(LAddress + TQ3GameWorld.OFFSET_OWNERNUM, TQ3GameWorld.ENTITYNUM_NONE);
end;

function TTestQ3GameWorld.Trace(const AStart, AEnd: TQ3Vec3; APass, AMask: Integer): TQ3Trace;
begin
  PutVec(VEC_START, AStart[0], AStart[1], AStart[2]);
  PutVec(VEC_END, AEnd[0], AEnd[1], AEnd[2]);
  // a null mins and maxs is the zero vector
  Call([G_TRACE, TRACE_ADDRESS, VEC_START, 0, 0, VEC_END, APass, AMask]);
  Result := TQ3TraceMemory.ReadTrace(FMachine.Memory, TRACE_ADDRESS);
end;

// a point in free space with 256 free units to its +x, found in the map with the box of the entities
function TTestQ3GameWorld.FindFreeRun: TQ3Vec3;
var
  LModel: IQ3CollisionModel;
  LMins, LMaxs, LBoxMins, LBoxMaxs, LEnd: TQ3Vec3;
  LTrace: TQ3Trace;
  LX, LY, LZ: Single;
begin
  LModel := FClipMapIntf.Model;
  LModel.ModelBounds(LModel.InlineModel(0), LMins, LMaxs);
  LBoxMins[0] := -40;
  LBoxMins[1] := -40;
  LBoxMins[2] := -40;
  LBoxMaxs[0] := 40;
  LBoxMaxs[1] := 40;
  LBoxMaxs[2] := 60;
  LZ := LMins[2] + 64;
  while LZ < LMaxs[2] - 64 do
  begin
    LY := LMins[1] + 64;
    while LY < LMaxs[1] - 64 do
    begin
      LX := LMins[0] + 64;
      while LX < LMaxs[0] - 320 do
      begin
        Result[0] := LX;
        Result[1] := LY;
        Result[2] := LZ;
        LEnd := Result;
        LEnd[0] := LX + 256;
        LTrace := LModel.BoxTrace(Result, LEnd, LBoxMins, LBoxMaxs, 0, CONTENTS_SOLID, False);
        if (LTrace.Fraction = 1) and not LTrace.StartSolid and (LModel.PointContents(Result, 0) = 0) then
          Exit;
        LX := LX + 32;
      end;
      LY := LY + 32;
    end;
    LZ := LZ + 32;
  end;
  Assert.Fail('no free run of 256 units in the test map');
end;

procedure TTestQ3GameWorld.IlCollegamentoDovrebbeScrivereIlBoxAssolutoELaDimensione;
var
  LMemory: IQvmMemory;
  LAddress: Integer;
begin
  LMemory := FMachine.Memory;
  SetEntity(1, FFree, CONTENTS_BODY);
  LAddress := EntityAddress(1);
  Call([G_LINKENTITY, LAddress]);
  Assert.AreEqual(1, LMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_LINKED));
  Assert.AreEqual(1, LMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_LINKCOUNT));
  // origin + mins - 1 and origin + maxs + 1
  Assert.AreEqual(Single(FFree[0] - 16), TQ3TestCalls.Float(LMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_ABSMIN)));
  Assert.AreEqual(Single(FFree[2] - 25), TQ3TestCalls.Float(LMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_ABSMIN + 8)));
  Assert.AreEqual(Single(FFree[1] + 16), TQ3TestCalls.Float(LMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_ABSMAX + 4)));
  Assert.AreEqual(Single(FFree[2] + 33), TQ3TestCalls.Float(LMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_ABSMAX + 8)));
  // s.solid: x (15), -z (24), z + 32 (64) as bytes
  Assert.AreEqual((64 shl 16) or (24 shl 8) or 15, LMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_SOLID));
end;

procedure TTestQ3GameWorld.LEntitaCollegataDovrebbeEssereNellaListaDellAreaEDopoLoScollegamentoNo;
var
  LAddress, LCount: Integer;
begin
  SetEntity(1, FFree, CONTENTS_BODY);
  LAddress := EntityAddress(1);
  Call([G_LINKENTITY, LAddress]);
  PutVec(VEC_MINS, FFree[0] - 5, FFree[1] - 5, FFree[2] - 5);
  PutVec(VEC_MAXS, FFree[0] + 5, FFree[1] + 5, FFree[2] + 5);
  LCount := Call([G_ENTITIES_IN_BOX, VEC_MINS, VEC_MAXS, LIST_ADDRESS, 16]);
  Assert.AreEqual(1, LCount);
  Assert.AreEqual(1, FMachine.Memory.ReadInt32(LIST_ADDRESS));
  // a box far away does not touch it
  PutVec(VEC_MINS, FFree[0] + 500, FFree[1], FFree[2]);
  PutVec(VEC_MAXS, FFree[0] + 600, FFree[1], FFree[2]);
  Assert.AreEqual(0, Call([G_ENTITIES_IN_BOX, VEC_MINS, VEC_MAXS, LIST_ADDRESS, 16]));
  Call([G_UNLINKENTITY, LAddress]);
  Assert.AreEqual(0, FMachine.Memory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_LINKED));
  PutVec(VEC_MINS, FFree[0] - 5, FFree[1] - 5, FFree[2] - 5);
  PutVec(VEC_MAXS, FFree[0] + 5, FFree[1] + 5, FFree[2] + 5);
  Assert.AreEqual(0, Call([G_ENTITIES_IN_BOX, VEC_MINS, VEC_MAXS, LIST_ADDRESS, 16]));
end;

procedure TTestQ3GameWorld.UnNuovoCollegamentoNonDovrebbeDuplicareLEntita;
begin
  SetEntity(2, FFree, CONTENTS_BODY);
  Call([G_LINKENTITY, EntityAddress(2)]);
  Call([G_LINKENTITY, EntityAddress(2)]);
  PutVec(VEC_MINS, FFree[0] - 5, FFree[1] - 5, FFree[2] - 5);
  PutVec(VEC_MAXS, FFree[0] + 5, FFree[1] + 5, FFree[2] + 5);
  Assert.AreEqual(1, Call([G_ENTITIES_IN_BOX, VEC_MINS, VEC_MAXS, LIST_ADDRESS, 16]));
  Assert.AreEqual(2, FMachine.Memory.ReadInt32(EntityAddress(2) + TQ3GameWorld.OFFSET_LINKCOUNT));
end;

procedure TTestQ3GameWorld.UnaTracciaControUnEntitaDovrebbeFermarsiSulSuoBox;
var
  LOrigin, LEnd: TQ3Vec3;
  LTrace: TQ3Trace;
begin
  LOrigin := FFree;
  LOrigin[0] := FFree[0] + 128;
  SetEntity(3, LOrigin, CONTENTS_BODY);
  Call([G_LINKENTITY, EntityAddress(3)]);
  LEnd := FFree;
  LEnd[0] := FFree[0] + 256;
  LTrace := Trace(FFree, LEnd, TQ3GameWorld.ENTITYNUM_NONE, CONTENTS_SOLID or CONTENTS_BODY);
  Assert.AreEqual(3, LTrace.EntityNum);
  // the box starts 15 units before the origin of the entity: 113 / 256, less the epsilon of the clip
  Assert.IsTrue((LTrace.Fraction > 0.43) and (LTrace.Fraction < 0.442), FloatToStr(LTrace.Fraction));
  Assert.IsFalse(LTrace.StartSolid);
  Assert.IsTrue(LTrace.EndPos[0] > FFree[0] + 110);
  Assert.IsTrue(LTrace.EndPos[0] < FFree[0] + 114);
  // the plane is the face of the box: normal -x
  Assert.AreEqual(Single(-1), LTrace.Plane.Normal[0]);
end;

procedure TTestQ3GameWorld.IlPassEntityEISuoiMissiliDovrebberoEssereSaltati;
var
  LOrigin, LEnd: TQ3Vec3;
  LTrace: TQ3Trace;
begin
  LOrigin := FFree;
  LOrigin[0] := FFree[0] + 128;
  SetEntity(3, LOrigin, CONTENTS_BODY);
  Call([G_LINKENTITY, EntityAddress(3)]);
  LEnd := FFree;
  LEnd[0] := FFree[0] + 256;
  // the pass entity itself
  LTrace := Trace(FFree, LEnd, 3, CONTENTS_SOLID or CONTENTS_BODY);
  Assert.AreEqual(Single(1), LTrace.Fraction);
  Assert.AreEqual(TQ3GameWorld.ENTITYNUM_NONE, LTrace.EntityNum);
  // an entity owned by the pass entity (a missile of the player 5)
  FMachine.Memory.WriteInt32(EntityAddress(3) + TQ3GameWorld.OFFSET_OWNERNUM, 5);
  LTrace := Trace(FFree, LEnd, 5, CONTENTS_SOLID or CONTENTS_BODY);
  Assert.AreEqual(Single(1), LTrace.Fraction);
  // another pass entity does see it
  LTrace := Trace(FFree, LEnd, 6, CONTENTS_SOLID or CONTENTS_BODY);
  Assert.AreEqual(3, LTrace.EntityNum);
end;

procedure TTestQ3GameWorld.LaMascheraDovrebbeEscludereLeEntitaSenzaQuelContenuto;
var
  LOrigin, LEnd: TQ3Vec3;
  LTrace: TQ3Trace;
begin
  LOrigin := FFree;
  LOrigin[0] := FFree[0] + 128;
  SetEntity(3, LOrigin, CONTENTS_BODY);
  Call([G_LINKENTITY, EntityAddress(3)]);
  LEnd := FFree;
  LEnd[0] := FFree[0] + 256;
  LTrace := Trace(FFree, LEnd, TQ3GameWorld.ENTITYNUM_NONE, CONTENTS_SOLID);
  Assert.AreEqual(Single(1), LTrace.Fraction);
end;

procedure TTestQ3GameWorld.IlContenutoDiUnPuntoDovrebbeIncludereLEntita;
begin
  SetEntity(3, FFree, CONTENTS_BODY);
  Call([G_LINKENTITY, EntityAddress(3)]);
  PutVec(VEC_START, FFree[0], FFree[1], FFree[2]);
  Assert.AreEqual(CONTENTS_BODY, Call([G_POINT_CONTENTS, VEC_START, TQ3GameWorld.ENTITYNUM_NONE]) and CONTENTS_BODY);
  // the entity itself is skipped when it is the pass entity
  Assert.AreEqual(0, Call([G_POINT_CONTENTS, VEC_START, 3]) and CONTENTS_BODY);
end;

procedure TTestQ3GameWorld.IlContattoDovrebbeEssereVeroSoloDentroLEntita;
begin
  // the entity at the origin: a small box around the origin is inside, a box 50 away is not
  SetEntity(4, FFree, CONTENTS_BODY);
  FMachine.Memory.Fill(EntityAddress(4) + TQ3GameWorld.OFFSET_CURRENTORIGIN, 0, 12);
  PutVec(VEC_MINS, -5, -5, -5);
  PutVec(VEC_MAXS, 5, 5, 5);
  Assert.AreEqual(1, Call([G_ENTITY_CONTACT, VEC_MINS, VEC_MAXS, EntityAddress(4)]));
  Assert.AreEqual(1, Call([G_ENTITY_CONTACTCAPSULE, VEC_MINS, VEC_MAXS, EntityAddress(4)]));
  PutVec(VEC_MINS, 45, 45, 45);
  PutVec(VEC_MAXS, 55, 55, 55);
  Assert.AreEqual(0, Call([G_ENTITY_CONTACT, VEC_MINS, VEC_MAXS, EntityAddress(4)]));
end;

procedure TTestQ3GameWorld.UnModelloDiBrushDovrebbePrendereLeMisureDelModello;
var
  LMemory: IQvmMemory;
  LAddress: Integer;
  LMins, LMaxs: TQ3Vec3;
  LModel: IQ3CollisionModel;
begin
  LModel := FClipMapIntf.Model;
  Assert.IsTrue(LModel.NumInlineModels > 1, 'the test map has an inline model');
  LMemory := FMachine.Memory;
  SetEntity(5, FFree, 0);
  LAddress := EntityAddress(5);
  FMachine.Memory.WriteString(TEXT_ADDRESS, '*1', 3);
  Call([G_SET_BRUSH_MODEL, LAddress, TEXT_ADDRESS]);
  LModel.ModelBounds(LModel.InlineModel(1), LMins, LMaxs);
  Assert.AreEqual(1, LMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_MODELINDEX));
  Assert.AreEqual(1, LMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_BMODEL));
  Assert.AreEqual(-1, LMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_CONTENTS));
  Assert.AreEqual(LMins[0], TQ3TestCalls.Float(LMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_MINS)));
  Assert.AreEqual(LMaxs[2], TQ3TestCalls.Float(LMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_MAXS + 8)));
  Assert.AreEqual(TQ3GameWorld.SOLID_BMODEL, LMemory.ReadInt32(LAddress + TQ3GameWorld.OFFSET_SOLID));
end;

procedure TTestQ3GameWorld.UnNomeCheNonEUnModelloDiBrushDovrebbeEssereUnErrore;
begin
  SetEntity(5, FFree, 0);
  FMachine.Memory.WriteString(TEXT_ADDRESS, 'models/x.md3', 13);
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      Call([G_SET_BRUSH_MODEL, EntityAddress(5), TEXT_ADDRESS]);
    end, EQ3HostException));
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      Call([G_SET_BRUSH_MODEL, EntityAddress(5), 0]);
    end, EQ3HostException));
end;

procedure TTestQ3GameWorld.UnaEntitaFuoriIntervalloDovrebbeEssereUnErrore;
begin
  SetEntity(6, FFree, CONTENTS_BODY);
  FMachine.Memory.WriteInt32(EntityAddress(6) + TQ3GameWorld.OFFSET_NUMBER, 1024);
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      Call([G_LINKENTITY, EntityAddress(6)]);
    end, EQ3HostException));
end;

procedure TTestQ3GameWorld.LaListaEntitaDovrebbeFermarsiAlMassimoRichiesto;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 4 do
  begin
    SetEntity(LIndex, FFree, CONTENTS_BODY);
    Call([G_LINKENTITY, EntityAddress(LIndex)]);
  end;
  PutVec(VEC_MINS, FFree[0] - 5, FFree[1] - 5, FFree[2] - 5);
  PutVec(VEC_MAXS, FFree[0] + 5, FFree[1] + 5, FFree[2] + 5);
  Assert.AreEqual(4, Call([G_ENTITIES_IN_BOX, VEC_MINS, VEC_MAXS, LIST_ADDRESS, 16]));
  Assert.AreEqual(2, Call([G_ENTITIES_IN_BOX, VEC_MINS, VEC_MAXS, LIST_ADDRESS, 2]));
  // the entities of the node come out from the last one linked to the first
  Assert.AreEqual(4, FMachine.Memory.ReadInt32(LIST_ADDRESS));
  Assert.AreEqual(3, FMachine.Memory.ReadInt32(LIST_ADDRESS + 4));
end;

procedure TTestQ3GameWorld.PuntiNellaStessaAreaDovrebberoVedersiNelPvs;
begin
  PutVec(VEC_START, FFree[0], FFree[1], FFree[2]);
  PutVec(VEC_END, FFree[0] + 8, FFree[1], FFree[2]);
  Assert.AreEqual(1, Call([G_IN_PVS, VEC_START, VEC_END]));
  Assert.AreEqual(1, Call([G_IN_PVS_IGNORE_PORTALS, VEC_START, VEC_END]));
  Assert.AreEqual(1, Call([G_AREAS_CONNECTED, 0, 0]));
end;

end.
