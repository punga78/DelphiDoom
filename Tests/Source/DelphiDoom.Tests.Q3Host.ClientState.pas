{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the state of the client     }
{  (game state, snapshots, server commands, user commands) and the system calls  }
{  of cgame and ui that read it, written on cl_cgame.c and cl_ui.c; the layout   }
{  of the structures against the real headers (client-layout.golden.txt)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.ClientState;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Q3Host.Types, DelphiDoom.Tests.Q3Host.ClientSupport;

type
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3ClientState = class
  strict private
    FRig: TQ3ClientRig;
    procedure Put(AModule: TQ3Module; AAddress: Integer; const AText: AnsiString);
    procedure AddSnapshot(AMessageNum, AEntities, AFill: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LeConfigstringDovrebberoRiempireIlGameStateComeIlC;
    [Test]
    procedure UnaConfigstringUgualeNonDovrebbeFarNulla;
    [Test]
    procedure LaModificaDiSysteminfoDovrebbeChiamareLEvento;
    [Test]
    procedure UnaConfigstringVuotaDovrebbeTogliereLaStringa;
    [Test]
    procedure IlGameStatePienoDovrebbeEssereUnErrore;
    [Test]
    procedure UnIndiceFuoriDaiLimitiDovrebbeEssereUnErrore;
    [Test]
    procedure UnComandoDelServerDovrebbeEssereDivisoInArgomenti;
    [Test]
    procedure IlComandoCsDovrebbeCambiareLaConfigstring;
    [Test]
    procedure UnaConfigstringGrandeDovrebbeEssereRimessaInsiemeDaBcs;
    [Test]
    procedure IlComandoDisconnectDovrebbeEssereUnErrore;
    [Test]
    procedure UnComandoCheNonCePiuDovrebbeEssereUnErroreOFalsoInUnaDemo;
    [Test]
    procedure UnComandoNonArrivatoDovrebbeEssereUnErrore;
    [Test]
    procedure MapRestartDovrebbeAzzerareIComandiDellUtente;
    [Test]
    procedure UnoSnapshotDovrebbeTornareConLeSueEntita;
    [Test]
    procedure UnoSnapshotMaiArrivatoODaScartareDovrebbeEssereFalsoOUnErrore;
    [Test]
    procedure UnoSnapshotChiHaPersoLeEntitaDovrebbeEssereFalso;
    [Test]
    procedure LeEntitaDiUnoSnapshotDovrebberoEssereTagliateA256;
    [Test]
    procedure IComandiDellUtenteDovrebberoSeguireLeRegoleDelBuffer;
    [Test]
    procedure IComandiAffidabiliNonConfermatiDovrebberoFinireInErrore;
    [Test]
    procedure IlGameStateDiCgameDovrebbeEssereScrittoNellaMemoria;
    [Test]
    procedure LoSnapshotDiCgameDovrebbeScrivereSoloICampiDelC;
    [Test]
    procedure IComandiDelServerDiCgameDovrebberoPassareAgliArgomenti;
    [Test]
    procedure ILComandiUtenteDiCgameDovrebberoEssereQuelliDelClient;
    [Test]
    procedure UiDovrebbeLeggereLeConfigstringEIlClientState;
    [Test]
    procedure LeChiamateDiSistemaDovrebberoDareIValoriFissi;
    [Test]
    procedure LeDimensioniDelleStruttureDovrebberoEssereQuelleDelC;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Client.Types,
  DelphiDoom.Q3Host.Client.Intf, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Q3Host.Services;

const
  BUFFER = 4096;

procedure TTestQ3ClientState.Setup;
begin
  FRig := TQ3ClientRig.Create;
end;

procedure TTestQ3ClientState.TearDown;
begin
  FRig.Free;
end;

procedure TTestQ3ClientState.Put(AModule: TQ3Module; AAddress: Integer; const AText: AnsiString);
begin
  FRig.Memory(AModule).WriteString(AAddress, AText, Length(AText) + 1);
end;

// a snapshot whose entities are filled with the byte AFill + the number of the entity
procedure TTestQ3ClientState.AddSnapshot(AMessageNum, AEntities, AFill: Integer);
var
  LSnapshot: TQ3ClientSnapshot;
  LEntities: TBytes;
  LIndex: Integer;
begin
  LSnapshot := Default(TQ3ClientSnapshot);
  LSnapshot.MessageNum := AMessageNum;
  LSnapshot.SnapFlags := 3;
  LSnapshot.ServerTime := AMessageNum * 50;
  LSnapshot.ServerCommandNum := 11;
  LSnapshot.Ping := 40 + AMessageNum;
  LSnapshot.AreaMask[0] := $A5;
  LSnapshot.AreaMask[31] := $5A;
  LSnapshot.PlayerState[140] := 7; // clientNum
  LSnapshot.PlayerState[467] := $EE;
  LSnapshot.NumEntities := AEntities;
  SetLength(LEntities, AEntities * Q3_ENTITYSTATE_SIZE);
  for LIndex := 0 to Length(LEntities) - 1 do
    LEntities[LIndex] := Byte(AFill + LIndex div Q3_ENTITYSTATE_SIZE);
  FRig.State.AddSnapshot(LSnapshot, LEntities);
end;

procedure TTestQ3ClientState.LeConfigstringDovrebberoRiempireIlGameStateComeIlC;
var
  LState: TBytes;
  LAnswer: AnsiString;
begin
  FRig.State.ConfigstringModified(5, 'abc');
  FRig.State.ConfigstringModified(2, 'x');
  LState := FRig.State.GameState;
  Assert.AreEqual(Q3_GAMESTATE_SIZE, Length(LState));
  // the strings are rebuilt in the order of the indexes after the first zero: x at 1, abc at 3
  Assert.AreEqual(1, PInteger(@LState[2 * 4])^);
  Assert.AreEqual(3, PInteger(@LState[5 * 4])^);
  Assert.AreEqual(0, PInteger(@LState[3 * 4])^);
  Assert.AreEqual(7, PInteger(@LState[Q3_GAMESTATE_COUNT_OFFSET])^);
  Assert.AreEqual(Ord('x'), Integer(LState[Q3_GAMESTATE_DATA_OFFSET + 1]));
  Assert.AreEqual(Ord('a'), Integer(LState[Q3_GAMESTATE_DATA_OFFSET + 3]));
  Assert.AreEqual(0, Integer(LState[Q3_GAMESTATE_DATA_OFFSET + 6]));
  Assert.IsTrue(FRig.State.TryGetConfigString(5, LAnswer));
  Assert.AreEqual('abc', string(LAnswer));
  // a string that was never set (offset 0) and an index out of range are both "no"
  Assert.IsFalse(FRig.State.TryGetConfigString(3, LAnswer));
  Assert.IsFalse(FRig.State.TryGetConfigString(Q3_MAX_CONFIGSTRINGS, LAnswer));
  Assert.IsFalse(FRig.State.TryGetConfigString(-1, LAnswer));
end;

procedure TTestQ3ClientState.UnaConfigstringUgualeNonDovrebbeFarNulla;
var
  LChanged: Integer;
begin
  LChanged := 0;
  FRig.State.OnSystemInfoChanged :=
    procedure
    begin
      Inc(LChanged);
    end;
  FRig.State.ConfigstringModified(Q3_CS_SYSTEMINFO, '\sv_serverid\1');
  FRig.State.ConfigstringModified(Q3_CS_SYSTEMINFO, '\sv_serverid\1');
  Assert.AreEqual(1, LChanged);
  FRig.State.OnSystemInfoChanged := nil;
end;

procedure TTestQ3ClientState.LaModificaDiSysteminfoDovrebbeChiamareLEvento;
var
  LChanged: Integer;
begin
  LChanged := 0;
  FRig.State.OnSystemInfoChanged :=
    procedure
    begin
      Inc(LChanged);
    end;
  FRig.State.ConfigstringModified(0, 'not the system info');
  Assert.AreEqual(0, LChanged);
  FRig.State.ConfigstringModified(Q3_CS_SYSTEMINFO, 'a');
  FRig.State.ConfigstringModified(Q3_CS_SYSTEMINFO, 'b');
  Assert.AreEqual(2, LChanged);
  FRig.State.OnSystemInfoChanged := nil;
end;

procedure TTestQ3ClientState.UnaConfigstringVuotaDovrebbeTogliereLaStringa;
var
  LAnswer: AnsiString;
  LState: TBytes;
begin
  FRig.State.ConfigstringModified(5, 'abc');
  FRig.State.ConfigstringModified(5, '');
  Assert.IsFalse(FRig.State.TryGetConfigString(5, LAnswer));
  LState := FRig.State.GameState;
  Assert.AreEqual(1, PInteger(@LState[Q3_GAMESTATE_COUNT_OFFSET])^);
end;

procedure TTestQ3ClientState.IlGameStatePienoDovrebbeEssereUnErrore;
begin
  FRig.State.ConfigstringModified(0, AnsiString(StringOfChar('a', 15990)));
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      FRig.State.ConfigstringModified(1, AnsiString(StringOfChar('b', 20)));
    end, EQ3HostException));
end;

procedure TTestQ3ClientState.UnIndiceFuoriDaiLimitiDovrebbeEssereUnErrore;
begin
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      FRig.State.ConfigstringModified(Q3_MAX_CONFIGSTRINGS, 'x');
    end, EQ3HostException));
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      FRig.State.ConfigstringModified(-1, 'x');
    end, EQ3HostException));
end;

procedure TTestQ3ClientState.UnComandoDelServerDovrebbeEssereDivisoInArgomenti;
var
  LNumber: Integer;
begin
  LNumber := FRig.State.AddServerCommand('print "hello world"');
  Assert.AreEqual(1, LNumber);
  Assert.IsTrue(FRig.State.GetServerCommand(LNumber));
  Assert.AreEqual(2, FRig.Console.Arguments.Count);
  Assert.AreEqual('print', string(FRig.Console.Arguments.Argv(0)));
  Assert.AreEqual('hello world', string(FRig.Console.Arguments.Argv(1)));
  Assert.AreEqual(1, FRig.State.LastExecutedServerCommand);
end;

procedure TTestQ3ClientState.IlComandoCsDovrebbeCambiareLaConfigstring;
var
  LAnswer: AnsiString;
begin
  Assert.IsTrue(FRig.State.GetServerCommand(FRig.State.AddServerCommand('cs 7 "a b"')));
  Assert.IsTrue(FRig.State.TryGetConfigString(7, LAnswer));
  Assert.AreEqual('a b', string(LAnswer));
  // the command is tokenized again for the module
  Assert.AreEqual('cs', string(FRig.Console.Arguments.Argv(0)));
end;

procedure TTestQ3ClientState.UnaConfigstringGrandeDovrebbeEssereRimessaInsiemeDaBcs;
var
  LAnswer: AnsiString;
begin
  Assert.IsFalse(FRig.State.GetServerCommand(FRig.State.AddServerCommand('bcs0 9 "AAA"')));
  Assert.IsFalse(FRig.State.GetServerCommand(FRig.State.AddServerCommand('bcs1 9 "BBB"')));
  Assert.IsFalse(FRig.State.TryGetConfigString(9, LAnswer));
  Assert.IsTrue(FRig.State.GetServerCommand(FRig.State.AddServerCommand('bcs2 9 "CCC"')));
  Assert.IsTrue(FRig.State.TryGetConfigString(9, LAnswer));
  Assert.AreEqual('AAABBBCCC', string(LAnswer));
end;

procedure TTestQ3ClientState.IlComandoDisconnectDovrebbeEssereUnErrore;
var
  LNumber: Integer;
begin
  LNumber := FRig.State.AddServerCommand('disconnect "bye bye"');
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      FRig.State.GetServerCommand(LNumber);
    end, EQ3HostException));
  try
    FRig.State.GetServerCommand(LNumber);
  except
    on E: EQ3HostException do
      Assert.IsTrue(Pos('bye bye', E.Message) > 0);
  end;
end;

procedure TTestQ3ClientState.UnComandoCheNonCePiuDovrebbeEssereUnErroreOFalsoInUnaDemo;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 70 do
    FRig.State.AddServerCommand(AnsiString('echo ' + IntToStr(LIndex)));
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      FRig.State.GetServerCommand(6);
    end, EQ3HostException));
  Assert.IsTrue(FRig.State.GetServerCommand(7));
  FRig.State.DemoPlaying := True;
  Assert.IsFalse(FRig.State.GetServerCommand(6));
end;

procedure TTestQ3ClientState.UnComandoNonArrivatoDovrebbeEssereUnErrore;
begin
  FRig.State.AddServerCommand('echo 1');
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      FRig.State.GetServerCommand(2);
    end, EQ3HostException));
end;

procedure TTestQ3ClientState.MapRestartDovrebbeAzzerareIComandiDellUtente;
var
  LCommand, LRead: TQ3HostUserCmd;
begin
  FillChar(LCommand, SizeOf(LCommand), $42);
  FRig.State.AddUserCommand(LCommand);
  Assert.IsTrue(FRig.State.TryGetUserCmd(1, LRead));
  Assert.AreEqual($42, Integer(LRead[0]));
  Assert.IsTrue(FRig.State.GetServerCommand(FRig.State.AddServerCommand('map_restart')));
  Assert.IsTrue(FRig.State.TryGetUserCmd(1, LRead));
  Assert.AreEqual(0, Integer(LRead[0]));
end;

procedure TTestQ3ClientState.UnoSnapshotDovrebbeTornareConLeSueEntita;
var
  LSnapshot: TQ3HostSnapshot;
  LNumber, LTime: Integer;
begin
  AddSnapshot(1, 2, $10);
  FRig.State.CurrentSnapshotNumber(LNumber, LTime);
  Assert.AreEqual(1, LNumber);
  Assert.AreEqual(50, LTime);
  Assert.IsTrue(FRig.State.TryGetSnapshot(1, LSnapshot));
  Assert.AreEqual(3, LSnapshot.SnapFlags);
  Assert.AreEqual(11, LSnapshot.ServerCommandSequence);
  Assert.AreEqual(41, LSnapshot.Ping);
  Assert.AreEqual(50, LSnapshot.ServerTime);
  Assert.AreEqual($A5, Integer(LSnapshot.AreaMask[0]));
  Assert.AreEqual($5A, Integer(LSnapshot.AreaMask[31]));
  Assert.AreEqual(7, Integer(LSnapshot.PlayerState[140]));
  Assert.AreEqual(2, LSnapshot.NumEntities);
  Assert.AreEqual(2 * Q3_ENTITYSTATE_SIZE, Length(LSnapshot.Entities));
  Assert.AreEqual($10, Integer(LSnapshot.Entities[0]));
  Assert.AreEqual($11, Integer(LSnapshot.Entities[Q3_ENTITYSTATE_SIZE]));
  Assert.AreEqual(7, FRig.State.ClientNumber);
end;

procedure TTestQ3ClientState.UnoSnapshotMaiArrivatoODaScartareDovrebbeEssereFalsoOUnErrore;
var
  LSnapshot, LOther: TQ3HostSnapshot;
  LIndex: Integer;
begin
  AddSnapshot(1, 0, 0);
  // number 0 never arrived: not valid, no error
  Assert.IsFalse(FRig.State.TryGetSnapshot(0, LSnapshot));
  // a number after the current one is an error
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      FRig.State.TryGetSnapshot(2, LOther);
    end, EQ3HostException));
  for LIndex := 2 to 40 do
    AddSnapshot(LIndex, 0, 0);
  // 40 - 5 = 35 snapshots ago: out of the ring of 32; 40 - 10 = 30: still there
  Assert.IsFalse(FRig.State.TryGetSnapshot(5, LSnapshot));
  Assert.IsTrue(FRig.State.TryGetSnapshot(10, LSnapshot));
  Assert.IsFalse(FRig.State.TryGetSnapshot(8, LSnapshot));
  Assert.IsTrue(FRig.State.TryGetSnapshot(9, LSnapshot));
end;

procedure TTestQ3ClientState.UnoSnapshotChiHaPersoLeEntitaDovrebbeEssereFalso;
var
  LSnapshot: TQ3HostSnapshot;
  LIndex: Integer;
begin
  for LIndex := 1 to 9 do
    AddSnapshot(LIndex, 256, LIndex);
  // 9 * 256 = 2304 entities parsed: the first snapshot started at 0 (2304 >= 2048), the second at 256 (2048 >= 2048),
  // the third at 512 (1792: still in the circular buffer)
  Assert.IsFalse(FRig.State.TryGetSnapshot(1, LSnapshot));
  Assert.IsFalse(FRig.State.TryGetSnapshot(2, LSnapshot));
  Assert.IsTrue(FRig.State.TryGetSnapshot(3, LSnapshot));
  Assert.AreEqual(3, Integer(LSnapshot.Entities[0]));
end;

procedure TTestQ3ClientState.LeEntitaDiUnoSnapshotDovrebberoEssereTagliateA256;
var
  LSnapshot: TQ3HostSnapshot;
begin
  AddSnapshot(1, 300, 1);
  Assert.IsTrue(FRig.State.TryGetSnapshot(1, LSnapshot));
  Assert.AreEqual(Q3_MAX_ENTITIES_IN_SNAPSHOT, LSnapshot.NumEntities);
  Assert.AreEqual(Q3_MAX_ENTITIES_IN_SNAPSHOT * Q3_ENTITYSTATE_SIZE, Length(LSnapshot.Entities));
end;

procedure TTestQ3ClientState.IComandiDellUtenteDovrebberoSeguireLeRegoleDelBuffer;
var
  LCommand, LRead, LOther: TQ3HostUserCmd;
  LIndex: Integer;
begin
  for LIndex := 1 to 3 do
  begin
    FillChar(LCommand, SizeOf(LCommand), LIndex);
    Assert.AreEqual(LIndex, FRig.State.AddUserCommand(LCommand));
  end;
  Assert.AreEqual(3, FRig.State.CurrentCommandNumber);
  Assert.IsTrue(FRig.State.TryGetUserCmd(2, LRead));
  Assert.AreEqual(2, Integer(LRead[23]));
  // a command that was not made yet is an error
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      FRig.State.TryGetUserCmd(4, LOther);
    end, EQ3HostException));
  for LIndex := 4 to 70 do
    FRig.State.AddUserCommand(LCommand);
  // 70 - 64 = 6: the commands up to number 6 were overwritten
  Assert.IsFalse(FRig.State.TryGetUserCmd(6, LRead));
  Assert.IsTrue(FRig.State.TryGetUserCmd(7, LRead));
end;

procedure TTestQ3ClientState.IComandiAffidabiliNonConfermatiDovrebberoFinireInErrore;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 65 do
    FRig.State.AddReliableCommand(AnsiString('say ' + IntToStr(LIndex)));
  Assert.AreEqual('say 65', string(FRig.State.ReliableCommand(65)));
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      FRig.State.AddReliableCommand('say 66');
    end, EQ3HostException));
  FRig.State.AcknowledgeReliableCommands(10);
  FRig.State.AddReliableCommand('say 66');
  Assert.AreEqual(66, FRig.State.ReliableSequence);
end;

procedure TTestQ3ClientState.IlGameStateDiCgameDovrebbeEssereScrittoNellaMemoria;
var
  LMemory: IQvmMemory;
begin
  FRig.State.ConfigstringModified(4, 'map');
  LMemory := FRig.Memory(TQ3Module.CGame);
  LMemory.Fill(BUFFER, $77, Q3_GAMESTATE_SIZE + 4);
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_GETGAMESTATE, BUFFER]));
  Assert.AreEqual(1, LMemory.ReadInt32(BUFFER + 4 * 4));
  Assert.AreEqual(0, LMemory.ReadInt32(BUFFER + 5 * 4));
  // the first byte is the zero of the strings that were never set, then "map" and its zero
  Assert.AreEqual(5, LMemory.ReadInt32(BUFFER + Q3_GAMESTATE_COUNT_OFFSET));
  Assert.AreEqual($77, Integer(LMemory.ReadByte(BUFFER + Q3_GAMESTATE_SIZE)));
  Assert.AreEqual('map', string(LMemory.ReadString(BUFFER + Q3_GAMESTATE_DATA_OFFSET + 1)));
end;

procedure TTestQ3ClientState.LoSnapshotDiCgameDovrebbeScrivereSoloICampiDelC;
var
  LMemory: IQvmMemory;
begin
  LMemory := FRig.Memory(TQ3Module.CGame);
  AddSnapshot(1, 3, $20);
  LMemory.Fill(BUFFER, $77, Q3_SNAPSHOT_SIZE);
  Assert.AreEqual(1, FRig.Call(TQ3Module.CGame, [CG_GETSNAPSHOT, 1, BUFFER]));
  Assert.AreEqual(3, LMemory.ReadInt32(BUFFER));
  Assert.AreEqual(41, LMemory.ReadInt32(BUFFER + Q3_SNAPSHOT_PING));
  Assert.AreEqual(50, LMemory.ReadInt32(BUFFER + Q3_SNAPSHOT_SERVERTIME));
  Assert.AreEqual($A5, Integer(LMemory.ReadByte(BUFFER + Q3_SNAPSHOT_AREAMASK)));
  Assert.AreEqual($5A, Integer(LMemory.ReadByte(BUFFER + Q3_SNAPSHOT_AREAMASK + 31)));
  Assert.AreEqual(7, Integer(LMemory.ReadByte(BUFFER + Q3_SNAPSHOT_PS + 140)));
  Assert.AreEqual($EE, Integer(LMemory.ReadByte(BUFFER + Q3_SNAPSHOT_PS + 467)));
  Assert.AreEqual(3, LMemory.ReadInt32(BUFFER + Q3_SNAPSHOT_NUMENTITIES));
  Assert.AreEqual($20, Integer(LMemory.ReadByte(BUFFER + Q3_SNAPSHOT_ENTITIES)));
  Assert.AreEqual($22, Integer(LMemory.ReadByte(BUFFER + Q3_SNAPSHOT_ENTITIES + 2 * Q3_ENTITYSTATE_SIZE)));
  Assert.AreEqual(11, LMemory.ReadInt32(BUFFER + Q3_SNAPSHOT_SERVERCOMMANDSEQUENCE));
  // numServerCommands and the entities after the third are left as they were: the "FIXME" of the C
  Assert.AreEqual($77777777, LMemory.ReadInt32(BUFFER + 53764));
  Assert.AreEqual($77, Integer(LMemory.ReadByte(BUFFER + Q3_SNAPSHOT_ENTITIES + 3 * Q3_ENTITYSTATE_SIZE)));
  // a snapshot that is not valid is 0 and writes nothing
  LMemory.Fill(BUFFER, $55, 64);
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_GETSNAPSHOT, 0, BUFFER]));
  Assert.AreEqual($55, Integer(LMemory.ReadByte(BUFFER)));
  // the number of the current snapshot
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_GETCURRENTSNAPSHOTNUMBER, BUFFER, BUFFER + 4]));
  Assert.AreEqual(1, LMemory.ReadInt32(BUFFER));
  Assert.AreEqual(50, LMemory.ReadInt32(BUFFER + 4));
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      FRig.Call(TQ3Module.CGame, [CG_GETSNAPSHOT, 2, BUFFER]);
    end, EQ3HostException));
end;

procedure TTestQ3ClientState.IComandiDelServerDiCgameDovrebberoPassareAgliArgomenti;
var
  LMemory: IQvmMemory;
begin
  LMemory := FRig.Memory(TQ3Module.CGame);
  FRig.State.AddServerCommand('chat "hi all" 3');
  Assert.AreEqual(1, FRig.Call(TQ3Module.CGame, [CG_GETSERVERCOMMAND, 1]));
  Assert.AreEqual(3, FRig.Call(TQ3Module.CGame, [CG_ARGC]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_ARGV, 1, BUFFER, 64]));
  Assert.AreEqual('hi all', string(LMemory.ReadString(BUFFER)));
  FRig.State.AddServerCommand('bcs0 3 "x"');
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_GETSERVERCOMMAND, 2]));
  Put(TQ3Module.CGame, BUFFER, 'say hello');
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_SENDCLIENTCOMMAND, BUFFER]));
  Assert.AreEqual('say hello', string(FRig.State.ReliableCommand(1)));
end;

procedure TTestQ3ClientState.ILComandiUtenteDiCgameDovrebberoEssereQuelliDelClient;
var
  LMemory: IQvmMemory;
  LCommand: TQ3HostUserCmd;
begin
  LMemory := FRig.Memory(TQ3Module.CGame);
  FillChar(LCommand, SizeOf(LCommand), $31);
  FRig.State.AddUserCommand(LCommand);
  FillChar(LCommand, SizeOf(LCommand), $32);
  FRig.State.AddUserCommand(LCommand);
  Assert.AreEqual(2, FRig.Call(TQ3Module.CGame, [CG_GETCURRENTCMDNUMBER]));
  LMemory.Fill(BUFFER, $77, 32);
  Assert.AreEqual(1, FRig.Call(TQ3Module.CGame, [CG_GETUSERCMD, 1, BUFFER]));
  Assert.AreEqual($31, Integer(LMemory.ReadByte(BUFFER)));
  Assert.AreEqual($31, Integer(LMemory.ReadByte(BUFFER + 23)));
  Assert.AreEqual($77, Integer(LMemory.ReadByte(BUFFER + 24)));
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      FRig.Call(TQ3Module.CGame, [CG_GETUSERCMD, 3, BUFFER]);
    end, EQ3HostException));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_SETUSERCMDVALUE, 5, TQ3TestCalls.Bits(1.5)]));
  Assert.AreEqual(5, FRig.State.UserCmdValue);
  Assert.AreEqual(Single(1.5), FRig.State.Sensitivity);
end;

procedure TTestQ3ClientState.UiDovrebbeLeggereLeConfigstringEIlClientState;
var
  LMemory: IQvmMemory;
  LState: TQ3HostUiClientState;
begin
  LMemory := FRig.Memory(TQ3Module.Ui);
  FRig.State.ConfigstringModified(6, 'sixth');
  LMemory.Fill(BUFFER, $77, 32);
  Assert.AreEqual(1, FRig.Call(TQ3Module.Ui, [UI_GETCONFIGSTRING, 6, BUFFER, 4]));
  Assert.AreEqual('six', string(LMemory.ReadString(BUFFER)));
  // never set: no, and the buffer is emptied when it has room
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_GETCONFIGSTRING, 7, BUFFER, 4]));
  Assert.AreEqual(0, Integer(LMemory.ReadByte(BUFFER)));
  LMemory.Fill(BUFFER, $77, 4);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_GETCONFIGSTRING, 7, BUFFER, 0]));
  Assert.AreEqual($77, Integer(LMemory.ReadByte(BUFFER)));
  // out of range: no, and the buffer is not touched
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_GETCONFIGSTRING, -1, BUFFER, 4]));
  Assert.AreEqual($77, Integer(LMemory.ReadByte(BUFFER)));

  LState := Default(TQ3HostUiClientState);
  LState.ConnectPacketCount := 3;
  LState.ConnectionState := 8;
  LState.ClientNumber := 2;
  LState.ServerName := 'localhost:27960';
  LState.UpdateInfoString := 'update';
  LState.MessageString := 'welcome';
  FRig.Connection.State := LState;
  LMemory.Fill(BUFFER, $77, Q3_UICLIENTSTATE_SIZE);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_GETCLIENTSTATE, BUFFER]));
  Assert.AreEqual(8, LMemory.ReadInt32(BUFFER));
  Assert.AreEqual(3, LMemory.ReadInt32(BUFFER + 4));
  Assert.AreEqual(2, LMemory.ReadInt32(BUFFER + 8));
  Assert.AreEqual('localhost:27960', string(LMemory.ReadString(BUFFER + Q3_UICLIENTSTATE_SERVERNAME)));
  Assert.AreEqual('update', string(LMemory.ReadString(BUFFER + Q3_UICLIENTSTATE_UPDATEINFO)));
  Assert.AreEqual('welcome', string(LMemory.ReadString(BUFFER + Q3_UICLIENTSTATE_MESSAGE)));
  Assert.AreEqual(0, Integer(LMemory.ReadByte(BUFFER + Q3_UICLIENTSTATE_SERVERNAME + 1023)));
end;

procedure TTestQ3ClientState.LeChiamateDiSistemaDovrebberoDareIValoriFissi;
var
  LMemory: IQvmMemory;
begin
  LMemory := FRig.Memory(TQ3Module.Ui);
  Assert.AreEqual(Q3_HUNK_FREE, FRig.Call(TQ3Module.CGame, [CG_MEMORY_REMAINING]));
  Assert.AreEqual(Q3_HUNK_FREE, FRig.Call(TQ3Module.Ui, [UI_MEMORY_REMAINING]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_UPDATESCREEN]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_UPDATESCREEN]));
  Assert.AreEqual(2, FRig.ClientSystem.Updates);
  FRig.ClientSystem.Clipboard := 'pasted text';
  LMemory.Fill(BUFFER, $77, 32);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_GETCLIPBOARDDATA, BUFFER, 7]));
  Assert.AreEqual('pasted', string(LMemory.ReadString(BUFFER)));
  FRig.ClientSystem.Clipboard := '';
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_GETCLIPBOARDDATA, BUFFER, 7]));
  Assert.AreEqual('', string(LMemory.ReadString(BUFFER)));
end;

procedure TTestQ3ClientState.LeDimensioniDelleStruttureDovrebberoEssereQuelleDelC;
var
  LLines: TStringList;
  LLine: string;
  LName: string;
  LSplit: Integer;
  LValues: TStringList;
  function Golden(const AName: string): Integer;
  begin
    Assert.IsTrue(LValues.IndexOfName(AName) >= 0, AName);
    Result := StrToInt(LValues.Values[AName]);
  end;
begin
  LLines := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'client-layout.golden.txt'));
  LValues := TStringList.Create;
  try
    for LLine in LLines do
    begin
      LSplit := LLine.LastDelimiter(' ');
      LName := Copy(LLine, 1, LSplit);
      LValues.Add(StringReplace(Trim(LName), ' ', '_', [rfReplaceAll]) + '=' + Copy(LLine, LSplit + 2, MaxInt));
    end;
    Assert.AreEqual(Q3_GAMESTATE_SIZE, Golden('sizeof_gameState_t'));
    Assert.AreEqual(Q3_GAMESTATE_DATA_OFFSET, Golden('gameState_t.stringData'));
    Assert.AreEqual(Q3_GAMESTATE_COUNT_OFFSET, Golden('gameState_t.dataCount'));
    Assert.AreEqual(Q3_SNAPSHOT_SIZE, Golden('sizeof_snapshot_t'));
    Assert.AreEqual(Q3_PLAYERSTATE_SIZE, Golden('sizeof_playerState_t'));
    Assert.AreEqual(Q3_ENTITYSTATE_SIZE, Golden('sizeof_entityState_t'));
    Assert.AreEqual(Q3_USERCMD_SIZE, Golden('sizeof_usercmd_t'));
    Assert.AreEqual(Q3_UICLIENTSTATE_SIZE, Golden('sizeof_uiClientState_t'));
    Assert.AreEqual(Q3_GLCONFIG_SIZE, Golden('sizeof_glconfig_t'));
    Assert.AreEqual(Q3_PCTOKEN_SIZE, Golden('sizeof_pc_token_t'));
    Assert.AreEqual(Q3_SNAPSHOT_PING, Golden('snapshot_t.ping'));
    Assert.AreEqual(Q3_SNAPSHOT_SERVERTIME, Golden('snapshot_t.serverTime'));
    Assert.AreEqual(Q3_SNAPSHOT_AREAMASK, Golden('snapshot_t.areamask'));
    Assert.AreEqual(Q3_SNAPSHOT_PS, Golden('snapshot_t.ps'));
    Assert.AreEqual(Q3_SNAPSHOT_NUMENTITIES, Golden('snapshot_t.numEntities'));
    Assert.AreEqual(Q3_SNAPSHOT_ENTITIES, Golden('snapshot_t.entities'));
    Assert.AreEqual(Q3_SNAPSHOT_SERVERCOMMANDSEQUENCE, Golden('snapshot_t.serverCommandSequence'));
    Assert.AreEqual(140, Golden('playerState_t.clientNum'));
    Assert.AreEqual(Q3_UICLIENTSTATE_SERVERNAME, Golden('uiClientState_t.servername'));
    Assert.AreEqual(Q3_UICLIENTSTATE_UPDATEINFO, Golden('uiClientState_t.updateInfoString'));
    Assert.AreEqual(Q3_UICLIENTSTATE_MESSAGE, Golden('uiClientState_t.messageString'));
    Assert.AreEqual(Q3_PCTOKEN_STRING, Golden('pc_token_t.string'));
    Assert.AreEqual(11264, Golden('glconfig_t.maxTextureSize'));
    Assert.AreEqual(11304, Golden('glconfig_t.vidWidth'));
    Assert.AreEqual(Q3_MAX_CONFIGSTRINGS, Golden('const_MAX_CONFIGSTRINGS'));
    Assert.AreEqual(Q3_MAX_GAMESTATE_CHARS, Golden('const_MAX_GAMESTATE_CHARS'));
    Assert.AreEqual(Q3_MAX_ENTITIES_IN_SNAPSHOT, Golden('const_MAX_ENTITIES_IN_SNAPSHOT'));
    Assert.AreEqual(Q3_BIG_INFO_STRING, Golden('const_BIG_INFO_STRING'));
    Assert.AreEqual(Q3_MAX_RELIABLE_COMMANDS, Golden('const_MAX_RELIABLE_COMMANDS'));
    Assert.AreEqual(Q3_MAX_NAME_LENGTH, Golden('const_MAX_NAME_LENGTH'));
    Assert.AreEqual(Q3_MAX_OSPATH, Golden('const_MAX_OSPATH'));
  finally
    LValues.Free;
    LLines.Free;
  end;
end;

end.
