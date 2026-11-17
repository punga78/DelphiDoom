{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the state of the client (gamestate,     }
{  snapshots, server commands and user commands)                                }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_cgame.c       }
{  (CL_GetGameState, CL_ConfigstringModified, CL_GetServerCommand,              }
{  CL_GetSnapshot, CL_GetUserCmd ...) and cl_main.c (CL_AddReliableCommand).    }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the      }
{  Quake III Arena source code and is therefore available under the GNU         }
{  General Public License, version 2 or (at your option) any later version.     }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.ClientState;

// Overflow and range checks are off: the counters of the C are 32 bit integers that count forever.

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Intf, DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.Client.Intf;

type
  /// <summary>
  ///   The part of clientActive_t and clientConnection_t that the modules read through the system calls. The
  ///   parser of the messages of the server (cl_parse.c, not here) fills it with ConfigstringModified,
  ///   AddServerCommand, AddSnapshot and AddUserCommand; the system calls read it with the rules of cl_cgame.c:
  ///   a snapshot that fell out of the circular buffers is not returned, a command that was never received is an
  ///   error (EQ3HostException, the ERR_DROP of the C)
  /// </summary>
  TQ3ClientState = class(TInterfacedObject, IQ3HostClientState)
  strict private
    FArguments: IQ3CommandArguments;
    FOffsets: array[0..Q3_MAX_CONFIGSTRINGS - 1] of Integer;
    FData: array[0..Q3_MAX_GAMESTATE_CHARS - 1] of Byte;
    FDataCount: Integer;
    FSnapshots: array[0..Q3_PACKET_BACKUP - 1] of TQ3ClientSnapshot;
    FSnapshot: TQ3ClientSnapshot;
    FParseEntities: TBytes;
    FParseEntitiesNum: Integer;
    FCommands: array[0..Q3_CMD_BACKUP - 1] of TQ3HostUserCmd;
    FCommandNumber: Integer;
    FServerCommands: array[0..Q3_MAX_RELIABLE_COMMANDS - 1] of AnsiString;
    FServerCommandSequence: Integer;
    FLastExecutedServerCommand: Integer;
    FBigConfigString: AnsiString;
    FReliableCommands: array[0..Q3_MAX_RELIABLE_COMMANDS - 1] of AnsiString;
    FReliableSequence: Integer;
    FReliableAcknowledge: Integer;
    FUserCmdValue: Integer;
    FSensitivity: Single;
    FDemoPlaying: Boolean;
    FOnSystemInfoChanged: TProc;
    FConnectedClientNumber: Integer;
    FChecksumFeed: Integer;
    function StringAt(AIndex: Integer): AnsiString;
  public
    constructor Create(const AArguments: IQ3CommandArguments);
    { IQ3HostClientState }
    function GameState: TBytes;
    function TryGetConfigString(AIndex: Integer; out AValue: AnsiString): Boolean;
    procedure CurrentSnapshotNumber(out ANumber, AServerTime: Integer);
    /// <summary>cl.snap.valid</summary>
    function SnapshotValid: Boolean;
    function TryGetSnapshot(ANumber: Integer; out ASnapshot: TQ3HostSnapshot): Boolean;
    function GetServerCommand(ANumber: Integer): Boolean;
    function CurrentCommandNumber: Integer;
    function TryGetUserCmd(ANumber: Integer; out ACommand: TQ3HostUserCmd): Boolean;
    procedure SetUserCmdValue(AValue: Integer; ASensitivity: Single);
    procedure AddReliableCommand(const AText: AnsiString);
    { what the parser of the messages does }
    /// <summary>
    ///   CL_ConfigstringModified: the string of the index becomes the value; the game state is rebuilt in the
    ///   order of the indexes, an empty string takes no room, and a change of CS_SYSTEMINFO calls OnSystemInfoChanged
    /// </summary>
    procedure ConfigstringModified(AIndex: Integer; const AValue: AnsiString);
    /// <summary>The string of a configstring ("" when it was never set)</summary>
    function ConfigString(AIndex: Integer): AnsiString;
    /// <summary>The server command that arrived (clc.serverCommandSequence goes up by one); the number it got</summary>
    function AddServerCommand(const AText: AnsiString): Integer;
    /// <summary>
    ///   CL_ClearState: memset( &cl, 0 ): the game state, the snapshots, the entities and the user commands are
    ///   forgotten (clc, the server commands and the reliable commands the client sent, stay)
    /// </summary>
    procedure ClearState;
    /// <summary>
    ///   CL_ParseCommandString: the command of sequence ASequence is stored when it is newer than the last one seen
    ///   (the sequence becomes ASequence, which may jump over lost commands); False for one already seen
    /// </summary>
    function StoreServerCommand(ASequence: Integer; const AText: AnsiString): Boolean;
    /// <summary>The "a gamestate always marks a server command sequence" of CL_ParseGamestate</summary>
    procedure SetServerCommandSequence(ASequence: Integer);
    /// <summary>
    ///   svc_configstring of a gamestate (CL_ParseGamestate): the string is appended to the data of the game
    ///   state, empty ones included, so the layout is the one of the C
    /// </summary>
    procedure GamestateConfigString(AIndex: Integer; const AValue: AnsiString);
    /// <summary>clc.clientNum and clc.checksumFeed, read at the end of a gamestate; CL_SystemInfoChanged follows</summary>
    procedure GamestateEnd(AClientNumber, AChecksumFeed: Integer);
    /// <summary>
    ///   A parsed snapshot as AddSnapshot does it, but the entities go to the slot the parser of the messages gave
    ///   them (cl.parseEntitiesNum of the parser, which also counts the entities of dropped snapshots)
    /// </summary>
    procedure AddParsedSnapshot(const ASnapshot: TQ3ClientSnapshot; const AEntities: TBytes);
    /// <summary>clc.clientNum</summary>
    property ConnectedClientNumber: Integer read FConnectedClientNumber;
    /// <summary>clc.checksumFeed</summary>
    property ChecksumFeed: Integer read FChecksumFeed;
    /// <summary>
    ///   A parsed snapshot: its entities (ASnapshot.NumEntities entityState_t in AEntities) go into the circular
    ///   buffer, the snapshot into the ring at its message number, and it becomes the current one (cl.snap)
    /// </summary>
    procedure AddSnapshot(const ASnapshot: TQ3ClientSnapshot; const AEntities: TBytes);
    /// <summary>The command the client built (cl.cmdNumber goes up by one); the number it got</summary>
    function AddUserCommand(const ACommand: TQ3HostUserCmd): Integer;
    /// <summary>The commands the client sent that the server did not acknowledge yet (clc.reliableAcknowledge)</summary>
    procedure AcknowledgeReliableCommands(ASequence: Integer);
    function ReliableCommand(ASequence: Integer): AnsiString;
    /// <summary>clc.serverCommands[ n &amp; 63 ] without marking it executed (what CL_WritePacket puts in its key)</summary>
    function ServerCommandText(ASequence: Integer): AnsiString;
    property ReliableSequence: Integer read FReliableSequence;
    /// <summary>clc.reliableAcknowledge: the last client command the server told it got</summary>
    property ReliableAcknowledge: Integer read FReliableAcknowledge;
    property ServerCommandSequence: Integer read FServerCommandSequence;
    property LastExecutedServerCommand: Integer read FLastExecutedServerCommand;
    property DemoPlaying: Boolean read FDemoPlaying write FDemoPlaying;
    property UserCmdValue: Integer read FUserCmdValue;
    property Sensitivity: Single read FSensitivity;
    /// <summary>The number of the client in the current snapshot (cl.snap.ps.clientNum)</summary>
    function ClientNumber: Integer;
    property OnSystemInfoChanged: TProc read FOnSystemInfoChanged write FOnSystemInfoChanged;
  end;

implementation

uses
  DelphiDoom.Q3Host.Types;

resourcestring
  SConfigstringRange = 'configstring > MAX_CONFIGSTRINGS';
  SGameStateOverflow = 'MAX_GAMESTATE_CHARS exceeded';
  SSnapshotNotReceived = 'CL_GetSnapshot: snapshotNumber > cl.snapshot.messageNum';
  SUserCmdNotCreated = 'CL_GetUserCmd: %d >= %d';
  SCommandCycledOut = 'CL_GetServerCommand: a reliable command was cycled out';
  SCommandNotReceived = 'CL_GetServerCommand: requested a command not received';
  SServerDisconnected = 'Server Disconnected - %s';
  SServerDisconnectedNoReason = 'Server disconnected';
  SBigConfigOverflow = 'bcs exceeded BIG_INFO_STRING';
  SClientCommandOverflow = 'Client command overflow';

// atoi of the C: blanks, a sign, digits; anything else is 0
function CAtoi(const AText: AnsiString): Integer;
var
  LIndex: Integer;
  LNegative: Boolean;
  LValue: Int64;
begin
  LIndex := 1;
  while (LIndex <= Length(AText)) and (AText[LIndex] in [#9, #10, #11, #12, #13, ' ']) do
    Inc(LIndex);
  LNegative := False;
  if (LIndex <= Length(AText)) and (AText[LIndex] in ['+', '-']) then
  begin
    LNegative := AText[LIndex] = '-';
    Inc(LIndex);
  end;
  LValue := 0;
  while (LIndex <= Length(AText)) and (AText[LIndex] in ['0'..'9']) do
  begin
    LValue := (LValue * 10 + Ord(AText[LIndex]) - Ord('0')) and $FFFFFFFF;
    Inc(LIndex);
  end;
  if LNegative then
    LValue := -LValue;
  Result := Integer(LValue and $FFFFFFFF);
end;

{ TQ3ClientState }

constructor TQ3ClientState.Create(const AArguments: IQ3CommandArguments);
begin
  inherited Create;
  FArguments := AArguments;
  FDataCount := 1;
  SetLength(FParseEntities, Q3_MAX_PARSE_ENTITIES * Q3_ENTITYSTATE_SIZE);
  // the first server command the client can ask for is 0, and nothing was received yet
  FServerCommandSequence := 0;
  FLastExecutedServerCommand := 0;
end;

function TQ3ClientState.StringAt(AIndex: Integer): AnsiString;
var
  LStart, LEnd: Integer;
begin
  LStart := FOffsets[AIndex];
  LEnd := LStart;
  while (LEnd < Q3_MAX_GAMESTATE_CHARS) and (FData[LEnd] <> 0) do
    Inc(LEnd);
  SetLength(Result, LEnd - LStart);
  if LEnd > LStart then
    Move(FData[LStart], Result[1], LEnd - LStart);
end;

function TQ3ClientState.GameState: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Q3_GAMESTATE_SIZE);
  for LIndex := 0 to Q3_MAX_CONFIGSTRINGS - 1 do
    PInteger(@Result[LIndex * 4])^ := FOffsets[LIndex];
  Move(FData[0], Result[Q3_GAMESTATE_DATA_OFFSET], Q3_MAX_GAMESTATE_CHARS);
  PInteger(@Result[Q3_GAMESTATE_COUNT_OFFSET])^ := FDataCount;
end;

function TQ3ClientState.ConfigString(AIndex: Integer): AnsiString;
begin
  if (AIndex < 0) or (AIndex >= Q3_MAX_CONFIGSTRINGS) then
    Exit('');
  Result := StringAt(AIndex);
end;

function TQ3ClientState.TryGetConfigString(AIndex: Integer; out AValue: AnsiString): Boolean;
begin
  AValue := '';
  if (AIndex < 0) or (AIndex >= Q3_MAX_CONFIGSTRINGS) then
    Exit(False);
  if FOffsets[AIndex] = 0 then
    Exit(False);
  AValue := StringAt(AIndex);
  Result := True;
end;

procedure TQ3ClientState.ConfigstringModified(AIndex: Integer; const AValue: AnsiString);
var
  LOldOffsets: array[0..Q3_MAX_CONFIGSTRINGS - 1] of Integer;
  LOldData: array[0..Q3_MAX_GAMESTATE_CHARS - 1] of Byte;
  LIndex, LLength, LStart: Integer;
  LText: AnsiString;
begin
  if (AIndex < 0) or (AIndex >= Q3_MAX_CONFIGSTRINGS) then
    raise EQ3HostException.Create(SConfigstringRange);
  if StringAt(AIndex) = AValue then
    Exit; // unchanged

  Move(FOffsets, LOldOffsets, SizeOf(FOffsets));
  Move(FData, LOldData, SizeOf(FData));
  FillChar(FOffsets, SizeOf(FOffsets), 0);
  FillChar(FData, SizeOf(FData), 0);
  // leave the first 0 for uninitialized strings
  FDataCount := 1;
  for LIndex := 0 to Q3_MAX_CONFIGSTRINGS - 1 do
  begin
    if LIndex = AIndex then
      LText := AValue
    else
    begin
      LStart := LOldOffsets[LIndex];
      LLength := 0;
      while (LStart + LLength < Q3_MAX_GAMESTATE_CHARS) and (LOldData[LStart + LLength] <> 0) do
        Inc(LLength);
      SetLength(LText, LLength);
      if LLength > 0 then
        Move(LOldData[LStart], LText[1], LLength);
    end;
    // leave with the default empty string
    if LText = '' then
      Continue;
    LLength := Length(LText);
    if LLength + 1 + FDataCount > Q3_MAX_GAMESTATE_CHARS then
      raise EQ3HostException.Create(SGameStateOverflow);
    FOffsets[LIndex] := FDataCount;
    Move(LText[1], FData[FDataCount], LLength);
    Inc(FDataCount, LLength + 1);
  end;

  if (AIndex = Q3_CS_SYSTEMINFO) and Assigned(FOnSystemInfoChanged) then
    FOnSystemInfoChanged();
end;

function TQ3ClientState.AddServerCommand(const AText: AnsiString): Integer;
begin
  Inc(FServerCommandSequence);
  Result := FServerCommandSequence;
  FServerCommands[Result and (Q3_MAX_RELIABLE_COMMANDS - 1)] := Copy(AText, 1, Q3_MAX_STRING_CHARS - 1);
end;

procedure TQ3ClientState.ClearState;
begin
  FillChar(FOffsets, SizeOf(FOffsets), 0);
  FillChar(FData, SizeOf(FData), 0);
  FDataCount := 0;
  FillChar(FSnapshots, SizeOf(FSnapshots), 0);
  FillChar(FSnapshot, SizeOf(FSnapshot), 0);
  FillChar(FCommands, SizeOf(FCommands), 0);
  FCommandNumber := 0;
  FParseEntitiesNum := 0;
  FillChar(FParseEntities[0], Length(FParseEntities), 0);
  FUserCmdValue := 0;
  FSensitivity := 0;
end;

function TQ3ClientState.StoreServerCommand(ASequence: Integer; const AText: AnsiString): Boolean;
begin
  // see if we have already executed stored it off
  if FServerCommandSequence >= ASequence then
    Exit(False);
  FServerCommandSequence := ASequence;
  FServerCommands[ASequence and (Q3_MAX_RELIABLE_COMMANDS - 1)] := Copy(AText, 1, Q3_MAX_STRING_CHARS - 1);
  Result := True;
end;

procedure TQ3ClientState.SetServerCommandSequence(ASequence: Integer);
begin
  FServerCommandSequence := ASequence;
end;

procedure TQ3ClientState.GamestateConfigString(AIndex: Integer; const AValue: AnsiString);
var
  LLength: Integer;
begin
  if (AIndex < 0) or (AIndex >= Q3_MAX_CONFIGSTRINGS) then
    raise EQ3HostException.Create(SConfigstringRange);
  // leave a 0 at the beginning for uninitialized configstrings
  if FDataCount = 0 then
    FDataCount := 1;
  LLength := Length(AValue);
  if LLength + 1 + FDataCount > Q3_MAX_GAMESTATE_CHARS then
    raise EQ3HostException.Create(SGameStateOverflow);
  FOffsets[AIndex] := FDataCount;
  if LLength > 0 then
    Move(AValue[1], FData[FDataCount], LLength);
  FData[FDataCount + LLength] := 0;
  Inc(FDataCount, LLength + 1);
end;

procedure TQ3ClientState.GamestateEnd(AClientNumber, AChecksumFeed: Integer);
begin
  FConnectedClientNumber := AClientNumber;
  FChecksumFeed := AChecksumFeed;
  // CL_SystemInfoChanged
  if Assigned(FOnSystemInfoChanged) then
    FOnSystemInfoChanged();
end;

function TQ3ClientState.GetServerCommand(ANumber: Integer): Boolean;
var
  LText, LCommand: AnsiString;
begin
  // if we have irretrievably lost a reliable command, drop the connection
  if ANumber <= FServerCommandSequence - Q3_MAX_RELIABLE_COMMANDS then
  begin
    // a demo recorded after the client got a lot of reliable commands never got the first ones
    if FDemoPlaying then
      Exit(False);
    raise EQ3HostException.Create(SCommandCycledOut);
  end;
  if ANumber > FServerCommandSequence then
    raise EQ3HostException.Create(SCommandNotReceived);

  LText := FServerCommands[ANumber and (Q3_MAX_RELIABLE_COMMANDS - 1)];
  FLastExecutedServerCommand := ANumber;

  // rescan: a complete big configstring is parsed again as a "cs" command
  while True do
  begin
    FArguments.Tokenize(LText);
    LCommand := FArguments.Argv(0);

    if LCommand = 'disconnect' then
    begin
      if FArguments.Count >= 2 then
        raise EQ3HostException.CreateFmt(SServerDisconnected, [FArguments.Argv(1)])
      else
        raise EQ3HostException.Create(SServerDisconnectedNoReason);
    end;

    if LCommand = 'bcs0' then
    begin
      FBigConfigString := 'cs ' + FArguments.Argv(1) + ' "' + FArguments.Argv(2);
      Exit(False);
    end;

    if LCommand = 'bcs1' then
    begin
      if Length(FBigConfigString) + Length(FArguments.Argv(2)) >= Q3_BIG_INFO_STRING then
        raise EQ3HostException.Create(SBigConfigOverflow);
      FBigConfigString := FBigConfigString + FArguments.Argv(2);
      Exit(False);
    end;

    if LCommand = 'bcs2' then
    begin
      if Length(FBigConfigString) + Length(FArguments.Argv(2)) + 1 >= Q3_BIG_INFO_STRING then
        raise EQ3HostException.Create(SBigConfigOverflow);
      FBigConfigString := FBigConfigString + FArguments.Argv(2) + '"';
      LText := FBigConfigString;
      Continue;
    end;

    if LCommand = 'cs' then
    begin
      ConfigstringModified(CAtoi(FArguments.Argv(1)), FArguments.ArgsFrom(2));
      // reparse the string, because ConfigstringModified may have tokenized another one
      FArguments.Tokenize(LText);
      Exit(True);
    end;

    if LCommand = 'map_restart' then
    begin
      // clear the outgoing commands before passing the restart to the cgame
      FillChar(FCommands, SizeOf(FCommands), 0);
      Exit(True);
    end;

    // clientLevelShot takes a screenshot of the local server; there is no local server here (com_sv_running is 0)
    if LCommand = 'clientLevelShot' then
      Exit(False);

    // cgame can now act on the command
    Exit(True);
  end;
end;

procedure TQ3ClientState.AddSnapshot(const ASnapshot: TQ3ClientSnapshot; const AEntities: TBytes);
var
  LSnapshot: TQ3ClientSnapshot;
  LIndex, LSlot: Integer;
begin
  LSnapshot := ASnapshot;
  LSnapshot.ParseEntitiesNum := FParseEntitiesNum;
  for LIndex := 0 to ASnapshot.NumEntities - 1 do
  begin
    LSlot := (FParseEntitiesNum + LIndex) and (Q3_MAX_PARSE_ENTITIES - 1);
    if (LIndex + 1) * Q3_ENTITYSTATE_SIZE <= Length(AEntities) then
      Move(AEntities[LIndex * Q3_ENTITYSTATE_SIZE], FParseEntities[LSlot * Q3_ENTITYSTATE_SIZE],
        Q3_ENTITYSTATE_SIZE)
    else
      FillChar(FParseEntities[LSlot * Q3_ENTITYSTATE_SIZE], Q3_ENTITYSTATE_SIZE, 0);
  end;
  Inc(FParseEntitiesNum, ASnapshot.NumEntities);
  LSnapshot.Valid := True;
  FSnapshots[LSnapshot.MessageNum and Q3_PACKET_MASK] := LSnapshot;
  FSnapshot := LSnapshot;
end;

procedure TQ3ClientState.AddParsedSnapshot(const ASnapshot: TQ3ClientSnapshot; const AEntities: TBytes);
var
  LSnapshot: TQ3ClientSnapshot;
  LIndex, LSlot: Integer;
begin
  LSnapshot := ASnapshot;
  for LIndex := 0 to ASnapshot.NumEntities - 1 do
  begin
    LSlot := (ASnapshot.ParseEntitiesNum + LIndex) and (Q3_MAX_PARSE_ENTITIES - 1);
    if (LIndex + 1) * Q3_ENTITYSTATE_SIZE <= Length(AEntities) then
      Move(AEntities[LIndex * Q3_ENTITYSTATE_SIZE], FParseEntities[LSlot * Q3_ENTITYSTATE_SIZE],
        Q3_ENTITYSTATE_SIZE)
    else
      FillChar(FParseEntities[LSlot * Q3_ENTITYSTATE_SIZE], Q3_ENTITYSTATE_SIZE, 0);
  end;
  // cl.parseEntitiesNum is the one of the parser, which counts the entities of every snapshot it read
  FParseEntitiesNum := ASnapshot.ParseEntitiesNum + ASnapshot.NumEntities;
  LSnapshot.Valid := True;
  FSnapshots[LSnapshot.MessageNum and Q3_PACKET_MASK] := LSnapshot;
  FSnapshot := LSnapshot;
end;

function TQ3ClientState.SnapshotValid: Boolean;
begin
  Result := FSnapshot.Valid;
end;

procedure TQ3ClientState.CurrentSnapshotNumber(out ANumber, AServerTime: Integer);
begin
  ANumber := FSnapshot.MessageNum;
  AServerTime := FSnapshot.ServerTime;
end;

function TQ3ClientState.TryGetSnapshot(ANumber: Integer; out ASnapshot: TQ3HostSnapshot): Boolean;
var
  LSnapshot: ^TQ3ClientSnapshot;
  LCount, LIndex, LSlot: Integer;
begin
  ASnapshot := Default(TQ3HostSnapshot);
  if ANumber > FSnapshot.MessageNum then
    raise EQ3HostException.Create(SSnapshotNotReceived);

  // if the frame has fallen out of the circular buffer, we can't return it
  if FSnapshot.MessageNum - ANumber >= Q3_PACKET_BACKUP then
    Exit(False);

  // if the frame is not valid, we can't return it
  LSnapshot := @FSnapshots[ANumber and Q3_PACKET_MASK];
  if not LSnapshot.Valid then
    Exit(False);

  // if the entities in the frame have fallen out of their circular buffer, we can't return it
  if FParseEntitiesNum - LSnapshot.ParseEntitiesNum >= Q3_MAX_PARSE_ENTITIES then
    Exit(False);

  ASnapshot.SnapFlags := LSnapshot.SnapFlags;
  ASnapshot.ServerCommandSequence := LSnapshot.ServerCommandNum;
  ASnapshot.Ping := LSnapshot.Ping;
  ASnapshot.ServerTime := LSnapshot.ServerTime;
  Move(LSnapshot.AreaMask, ASnapshot.AreaMask, SizeOf(ASnapshot.AreaMask));
  Move(LSnapshot.PlayerState, ASnapshot.PlayerState, SizeOf(ASnapshot.PlayerState));
  LCount := LSnapshot.NumEntities;
  if LCount > Q3_MAX_ENTITIES_IN_SNAPSHOT then
    LCount := Q3_MAX_ENTITIES_IN_SNAPSHOT;
  ASnapshot.NumEntities := LCount;
  SetLength(ASnapshot.Entities, LCount * Q3_ENTITYSTATE_SIZE);
  for LIndex := 0 to LCount - 1 do
  begin
    LSlot := (LSnapshot.ParseEntitiesNum + LIndex) and (Q3_MAX_PARSE_ENTITIES - 1);
    Move(FParseEntities[LSlot * Q3_ENTITYSTATE_SIZE], ASnapshot.Entities[LIndex * Q3_ENTITYSTATE_SIZE],
      Q3_ENTITYSTATE_SIZE);
  end;
  // the C leaves the configstring changes and the server commands of the snapshot alone ("FIXME")
  Result := True;
end;

function TQ3ClientState.AddUserCommand(const ACommand: TQ3HostUserCmd): Integer;
begin
  Inc(FCommandNumber);
  Result := FCommandNumber;
  FCommands[FCommandNumber and Q3_CMD_MASK] := ACommand;
end;

function TQ3ClientState.CurrentCommandNumber: Integer;
begin
  Result := FCommandNumber;
end;

function TQ3ClientState.TryGetUserCmd(ANumber: Integer; out ACommand: TQ3HostUserCmd): Boolean;
begin
  ACommand := Default(TQ3HostUserCmd);
  // cmds[cmdNumber] is the last properly generated command: can't return anything that we haven't created yet
  if ANumber > FCommandNumber then
    raise EQ3HostException.CreateFmt(SUserCmdNotCreated, [ANumber, FCommandNumber]);
  // the usercmd has been overwritten in the wrapping buffer because it is too far out of date
  if ANumber <= FCommandNumber - Q3_CMD_BACKUP then
    Exit(False);
  ACommand := FCommands[ANumber and Q3_CMD_MASK];
  Result := True;
end;

procedure TQ3ClientState.SetUserCmdValue(AValue: Integer; ASensitivity: Single);
begin
  FUserCmdValue := AValue;
  FSensitivity := ASensitivity;
end;

procedure TQ3ClientState.AddReliableCommand(const AText: AnsiString);
begin
  // if we would be losing an old command that hasn't been acknowledged, we must drop the connection
  if FReliableSequence - FReliableAcknowledge > Q3_MAX_RELIABLE_COMMANDS then
    raise EQ3HostException.Create(SClientCommandOverflow);
  Inc(FReliableSequence);
  FReliableCommands[FReliableSequence and (Q3_MAX_RELIABLE_COMMANDS - 1)] :=
    Copy(AText, 1, Q3_MAX_STRING_CHARS - 1);
end;

procedure TQ3ClientState.AcknowledgeReliableCommands(ASequence: Integer);
begin
  FReliableAcknowledge := ASequence;
end;

function TQ3ClientState.ReliableCommand(ASequence: Integer): AnsiString;
begin
  Result := FReliableCommands[ASequence and (Q3_MAX_RELIABLE_COMMANDS - 1)];
end;

function TQ3ClientState.ServerCommandText(ASequence: Integer): AnsiString;
begin
  Result := FServerCommands[ASequence and (Q3_MAX_RELIABLE_COMMANDS - 1)];
end;

function TQ3ClientState.ClientNumber: Integer;
begin
  Result := PInteger(@FSnapshot.PlayerState[140])^;
end;

end.
