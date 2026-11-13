{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - parser of the server messages of Quake III        }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_parse.c      }
{  (CL_ParseServerMessage, CL_ParseGamestate, CL_ParseSnapshot,                }
{  CL_ParsePacketEntities, CL_DeltaEntity, CL_ParseCommandString,              }
{  CL_ParseDownload). Copyright (C) 1999-2005 id Software, Inc.                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.ServerMessageParser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf,
  DelphiDoom.Net.Q3.Message, DelphiDoom.Net.Q3.EntityStateCodec, DelphiDoom.Net.Q3.PlayerStateCodec,
  DelphiDoom.Net.Q3.ServerMessage.Intf;

type
  /// <summary>
  ///   Parser of the messages a server sends a client (the live ones and the ones stored in a demo): serverinfo
  ///   commands, gamestate (configstrings and baselines) and snapshots delta-compressed against the previous
  ///   ones. It owns the state that <c>cl_parse.c</c> keeps in <c>cl</c> and <c>clc</c> to undo the deltas: the
  ///   baselines, the ring of entity states and the last 32 snapshots; what it decodes goes to the sink.
  ///   The codecs and the sink are not owned. Not ported (they belong to a running client): the ping of a
  ///   snapshot, the pure server checks and file system of a download, the cvars the gamestate sets,
  ///   <c>cl_shownet</c>
  /// </summary>
  TQ3ServerMessageParser = class
  strict private
    FCoder: IQ3HuffmanCoder;
    FEntityCodec: TQ3EntityStateCodec;
    FPlayerCodec: TQ3PlayerStateCodec;
    FSink: IQ3ServerMessageSink;
    FLog: ILog;
    FBaselines: array[0..Q3_MAX_GENTITIES - 1] of TQ3EntityState;
    FParseEntities: array[0..Q3_MAX_PARSE_ENTITIES - 1] of TQ3EntityState;
    FSnapshots: array[0..Q3_PACKET_BACKUP - 1] of TQ3Snapshot;
    FCurrentSnapshot: TQ3Snapshot;
    FParseEntitiesNum: Integer;
    FServerCommandSequence: Integer;
    FServerMessageSequence: Integer;
    FGameStateChars: Integer;
    FClientNum: Integer;
    FChecksumFeed: Integer;
    FReliableAcknowledge: Integer;
    FSnapshotCount: Integer;
    procedure Report(const AText: string);
    procedure RaiseServerError(const AText: string);
    procedure CheckNotPastEnd(AMessage: TQ3Message);
    function ParseEntity(AIndex: Integer): PQ3EntityState;
    procedure DeltaEntity(AMessage: TQ3Message; var AFrame: TQ3Snapshot; ANumber: Integer;
      AOld: PQ3EntityState; AUnchanged: Boolean);
    function OldFrameEntity(const AOldFrame: TQ3Snapshot; AIndex: Integer;
      out AOldNumber: Integer): PQ3EntityState;
    procedure ParsePacketEntities(AMessage: TQ3Message; AOldFrame: PQ3Snapshot; var ANewFrame: TQ3Snapshot);
    procedure ParseSnapshot(AMessage: TQ3Message);
    procedure ParseGamestate(AMessage: TQ3Message);
    procedure ParseCommandString(AMessage: TQ3Message);
    procedure ParseDownload(AMessage: TQ3Message);
    function CopyEntities(const ASnapshot: TQ3Snapshot): TArray<TQ3EntityState>;
  public
    /// <summary>The codecs and the sink are required (EArgumentNilException); ALog gets the messages that Com_Printf prints (nil = silence)</summary>
    constructor Create(const ACoder: IQ3HuffmanCoder; AEntityCodec: TQ3EntityStateCodec;
      APlayerCodec: TQ3PlayerStateCodec; const ASink: IQ3ServerMessageSink; const ALog: ILog = nil);
    /// <summary>CL_ClearState (the part of it that the parser uses): baselines, entities and snapshots are forgotten</summary>
    procedure ClearState;
    /// <summary>
    ///   CL_ParseServerMessage: parses one message (the bytes of a demo message or of a received datagram
    ///   after the netchan header). <c>AServerMessageSequence</c> is <c>clc.serverMessageSequence</c>, the number
    ///   of the message, which the snapshots take as their own. A malformed message is an
    ///   <c>EQ3ServerMessageException</c>
    /// </summary>
    procedure ParseMessage(const AData: TBytes; ALength, AServerMessageSequence: Integer);

    /// <summary>clc.serverCommandSequence: the last server command seen</summary>
    property ServerCommandSequence: Integer read FServerCommandSequence;
    /// <summary>cl.parseEntitiesNum: the entity states stored so far in the ring (it only grows)</summary>
    property ParseEntitiesNum: Integer read FParseEntitiesNum;
    property ClientNum: Integer read FClientNum;
    property ChecksumFeed: Integer read FChecksumFeed;
    property ReliableAcknowledge: Integer read FReliableAcknowledge;
    /// <summary>The characters of the configstrings of the last gamestate, with the leading NUL (cl.gameState.dataCount; 0 before the first gamestate)</summary>
    property GameStateChars: Integer read FGameStateChars;
    /// <summary>How many valid snapshots were parsed</summary>
    property SnapshotCount: Integer read FSnapshotCount;
    /// <summary>cl.snap: the last valid snapshot (its Entities are not filled)</summary>
    property CurrentSnapshot: TQ3Snapshot read FCurrentSnapshot;
  end;

implementation

const
  OLD_NUMBER_NONE = 99999;

{ TQ3ServerMessageParser }

constructor TQ3ServerMessageParser.Create(const ACoder: IQ3HuffmanCoder; AEntityCodec: TQ3EntityStateCodec;
  APlayerCodec: TQ3PlayerStateCodec; const ASink: IQ3ServerMessageSink; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ACoder) then
    raise EArgumentNilException.Create('ACoder');
  if not Assigned(AEntityCodec) then
    raise EArgumentNilException.Create('AEntityCodec');
  if not Assigned(APlayerCodec) then
    raise EArgumentNilException.Create('APlayerCodec');
  if not Assigned(ASink) then
    raise EArgumentNilException.Create('ASink');
  FCoder := ACoder;
  FEntityCodec := AEntityCodec;
  FPlayerCodec := APlayerCodec;
  FSink := ASink;
  FLog := ALog;
  ClearState;
end;

procedure TQ3ServerMessageParser.Report(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Info(AText);
end;

procedure TQ3ServerMessageParser.RaiseServerError(const AText: string);
begin
  raise EQ3ServerMessageException.Create(AText);
end;

procedure TQ3ServerMessageParser.CheckNotPastEnd(AMessage: TQ3Message);
begin
  if AMessage.ReadCount > AMessage.CurSize then
    RaiseServerError(SQ3ServerReadPastEnd);
end;

procedure TQ3ServerMessageParser.ClearState;
begin
  FillChar(FBaselines, SizeOf(FBaselines), 0);
  FillChar(FParseEntities, SizeOf(FParseEntities), 0);
  Finalize(FSnapshots);
  FillChar(FSnapshots, SizeOf(FSnapshots), 0);
  Finalize(FCurrentSnapshot);
  FillChar(FCurrentSnapshot, SizeOf(FCurrentSnapshot), 0);
  FParseEntitiesNum := 0;
  FGameStateChars := 0;
end;

function TQ3ServerMessageParser.ParseEntity(AIndex: Integer): PQ3EntityState;
begin
  Result := @FParseEntities[AIndex and (Q3_MAX_PARSE_ENTITIES - 1)];
end;

function TQ3ServerMessageParser.CopyEntities(const ASnapshot: TQ3Snapshot): TArray<TQ3EntityState>;
var
  LIndex: Integer;
begin
  SetLength(Result, ASnapshot.NumEntities);
  for LIndex := 0 to ASnapshot.NumEntities - 1 do
    Result[LIndex] := ParseEntity(ASnapshot.ParseEntitiesNum + LIndex)^;
end;

procedure TQ3ServerMessageParser.DeltaEntity(AMessage: TQ3Message; var AFrame: TQ3Snapshot; ANumber: Integer;
  AOld: PQ3EntityState; AUnchanged: Boolean);
var
  LState: PQ3EntityState;
begin
  // the parsed state goes in the ring so that it can be the source of a later delta
  LState := ParseEntity(FParseEntitiesNum);
  if AUnchanged then
    LState^ := AOld^
  else
    FEntityCodec.ReadDelta(AMessage, AOld, LState, ANumber);
  if LState^.Number = Q3_MAX_GENTITIES - 1 then
    Exit; // the entity was delta removed
  Inc(FParseEntitiesNum);
  Inc(AFrame.NumEntities);
end;

function TQ3ServerMessageParser.OldFrameEntity(const AOldFrame: TQ3Snapshot; AIndex: Integer;
  out AOldNumber: Integer): PQ3EntityState;
begin
  if AIndex >= AOldFrame.NumEntities then
  begin
    AOldNumber := OLD_NUMBER_NONE;
    Result := nil;
  end
  else
  begin
    Result := ParseEntity(AOldFrame.ParseEntitiesNum + AIndex);
    AOldNumber := Result^.Number;
  end;
end;

procedure TQ3ServerMessageParser.ParsePacketEntities(AMessage: TQ3Message; AOldFrame: PQ3Snapshot;
  var ANewFrame: TQ3Snapshot);
var
  LNewNumber: Integer;
  LOldState: PQ3EntityState;
  LOldIndex: Integer;
  LOldNumber: Integer;
begin
  ANewFrame.ParseEntitiesNum := FParseEntitiesNum;
  ANewFrame.NumEntities := 0;

  // delta from the entities present in the old frame
  LOldIndex := 0;
  LOldState := nil;
  if Assigned(AOldFrame) then
    LOldState := OldFrameEntity(AOldFrame^, LOldIndex, LOldNumber)
  else
    LOldNumber := OLD_NUMBER_NONE;

  while True do
  begin
    LNewNumber := AMessage.ReadBits(Q3_GENTITYNUM_BITS);
    if LNewNumber = Q3_MAX_GENTITIES - 1 then
      Break;
    if AMessage.ReadCount > AMessage.CurSize then
      RaiseServerError(SQ3ServerPacketEntitiesEnd);

    while LOldNumber < LNewNumber do
    begin
      // one or more entities of the old packet are unchanged
      DeltaEntity(AMessage, ANewFrame, LOldNumber, LOldState, True);
      Inc(LOldIndex);
      LOldState := OldFrameEntity(AOldFrame^, LOldIndex, LOldNumber);
    end;
    if LOldNumber = LNewNumber then
    begin
      // delta from the previous state
      DeltaEntity(AMessage, ANewFrame, LNewNumber, LOldState, False);
      Inc(LOldIndex);
      LOldState := OldFrameEntity(AOldFrame^, LOldIndex, LOldNumber);
      Continue;
    end;
    if LOldNumber > LNewNumber then
      // delta from the baseline
      DeltaEntity(AMessage, ANewFrame, LNewNumber, @FBaselines[LNewNumber], False);
  end;

  // any remaining entities of the old frame are copied over
  while LOldNumber <> OLD_NUMBER_NONE do
  begin
    DeltaEntity(AMessage, ANewFrame, LOldNumber, LOldState, True);
    Inc(LOldIndex);
    LOldState := OldFrameEntity(AOldFrame^, LOldIndex, LOldNumber);
  end;
end;

procedure TQ3ServerMessageParser.ParseSnapshot(AMessage: TQ3Message);
var
  LNew: TQ3Snapshot;
  LOld: PQ3Snapshot;
  LDeltaNum: Integer;
  LLength: Integer;
  LAreaMask: TBytes;
  LOldMessageNum: Integer;
begin
  // read into a temporary snapshot: it is kept only if it is valid
  Finalize(LNew);
  FillChar(LNew, SizeOf(LNew), 0);
  LNew.ServerCommandNum := FServerCommandSequence;
  LNew.ServerTime := AMessage.ReadLong;
  LNew.MessageNum := FServerMessageSequence;
  LDeltaNum := AMessage.ReadByte;
  if LDeltaNum = 0 then
    LNew.DeltaNum := -1
  else
    LNew.DeltaNum := LNew.MessageNum - LDeltaNum;
  LNew.SnapFlags := AMessage.ReadByte;

  // a frame delta-compressed from data that is gone is read to the end and then not used
  LOld := nil;
  if LNew.DeltaNum <= 0 then
    LNew.Valid := True // uncompressed frame
  else
  begin
    LOld := @FSnapshots[LNew.DeltaNum and (Q3_PACKET_BACKUP - 1)];
    if not LOld^.Valid then
      Report(SQ3ServerDeltaInvalidFrame)
    else if LOld^.MessageNum <> LNew.DeltaNum then
      Report(SQ3ServerDeltaFrameTooOld)
    else if FParseEntitiesNum - LOld^.ParseEntitiesNum > Q3_MAX_PARSE_ENTITIES - 128 then
      Report(SQ3ServerDeltaEntitiesTooOld)
    else
      LNew.Valid := True; // valid delta parse
  end;

  // the area mask
  LLength := AMessage.ReadByte;
  if (LLength < 0) or (LLength > Q3_MAX_MAP_AREA_BYTES) then
    RaiseServerError(Format(SQ3ServerAreaMaskLength, [LLength]));
  SetLength(LAreaMask, Q3_MAX_MAP_AREA_BYTES);
  AMessage.ReadData(LAreaMask, LLength);
  Move(LAreaMask[0], LNew.AreaMask[0], Q3_MAX_MAP_AREA_BYTES);

  // the player state and the entities
  if Assigned(LOld) then
    FPlayerCodec.ReadDelta(AMessage, @LOld^.PlayerState, @LNew.PlayerState)
  else
    FPlayerCodec.ReadDelta(AMessage, nil, @LNew.PlayerState);
  ParsePacketEntities(AMessage, LOld, LNew);

  // dumped now that it has been read properly
  if not LNew.Valid then
    Exit;

  // a dropped packet must not look like something valid to delta from when the buffer wraps
  LOldMessageNum := FCurrentSnapshot.MessageNum + 1;
  if LNew.MessageNum - LOldMessageNum >= Q3_PACKET_BACKUP then
    LOldMessageNum := LNew.MessageNum - (Q3_PACKET_BACKUP - 1);
  while LOldMessageNum < LNew.MessageNum do
  begin
    FSnapshots[LOldMessageNum and (Q3_PACKET_BACKUP - 1)].Valid := False;
    Inc(LOldMessageNum);
  end;

  FCurrentSnapshot := LNew;
  FSnapshots[LNew.MessageNum and (Q3_PACKET_BACKUP - 1)] := LNew;
  Inc(FSnapshotCount);
  LNew.Entities := CopyEntities(LNew);
  FSink.Snapshot(LNew);
end;

procedure TQ3ServerMessageParser.ParseGamestate(AMessage: TQ3Message);
var
  LCommand: Integer;
  LIndex: Integer;
  LText: AnsiString;
  LNumber: Integer;
  LNull: TQ3EntityState;
begin
  ClearState;
  FGameStateChars := 1; // leave a 0 at the beginning for uninitialized configstrings
  // a gamestate always marks a server command sequence
  FServerCommandSequence := AMessage.ReadLong;
  FSink.GamestateBegin(FServerCommandSequence);
  while True do
  begin
    LCommand := AMessage.ReadByte;
    if LCommand = Q3_SVC_EOF then
      Break;
    if LCommand = Q3_SVC_CONFIGSTRING then
    begin
      LIndex := AMessage.ReadShort;
      if (LIndex < 0) or (LIndex >= Q3_MAX_CONFIGSTRINGS) then
        RaiseServerError(SQ3ServerConfigStringRange);
      LText := AMessage.ReadBigString;
      if Length(LText) + 1 + FGameStateChars > Q3_MAX_GAMESTATE_CHARS then
        RaiseServerError(SQ3ServerGamestateChars);
      Inc(FGameStateChars, Length(LText) + 1);
      FSink.ConfigString(LIndex, LText);
    end
    else if LCommand = Q3_SVC_BASELINE then
    begin
      LNumber := AMessage.ReadBits(Q3_GENTITYNUM_BITS);
      if (LNumber < 0) or (LNumber >= Q3_MAX_GENTITIES) then
        RaiseServerError(Format(SQ3ServerBaselineRange, [LNumber]));
      FillChar(LNull, SizeOf(LNull), 0);
      FEntityCodec.ReadDelta(AMessage, @LNull, @FBaselines[LNumber], LNumber);
      FSink.Baseline(LNumber, FBaselines[LNumber]);
    end
    else
      RaiseServerError(SQ3ServerBadGamestateCommand);
  end;
  FClientNum := AMessage.ReadLong;
  FChecksumFeed := AMessage.ReadLong;
  FSink.GamestateEnd(FClientNum, FChecksumFeed);
end;

procedure TQ3ServerMessageParser.ParseCommandString(AMessage: TQ3Message);
var
  LSequence: Integer;
  LText: AnsiString;
begin
  LSequence := AMessage.ReadLong;
  LText := AMessage.ReadString;
  // already stored
  if FServerCommandSequence >= LSequence then
    Exit;
  FServerCommandSequence := LSequence;
  FSink.ServerCommand(LSequence, LText);
end;

procedure TQ3ServerMessageParser.ParseDownload(AMessage: TQ3Message);
var
  LBlock: Integer;
  LTotal: Integer;
  LSize: Integer;
  LData: TBytes;
begin
  LTotal := 0;
  LBlock := AMessage.ReadShort;
  if LBlock = 0 then
  begin
    // block zero is special, it has the size of the file (or the reason of a refusal)
    LTotal := AMessage.ReadLong;
    if LTotal < 0 then
      RaiseServerError(Format(SQ3ServerDownloadFailed, [string(AMessage.ReadString)]));
  end;
  LSize := AMessage.ReadShort;
  if LSize > 0 then
  begin
    SetLength(LData, LSize);
    AMessage.ReadData(LData, LSize);
  end;
  FSink.Download(LBlock, LTotal, LData);
end;

procedure TQ3ServerMessageParser.ParseMessage(const AData: TBytes; ALength, AServerMessageSequence: Integer);
var
  LMessage: TQ3Message;
  LCommand: Integer;
begin
  FServerMessageSequence := AServerMessageSequence;
  LMessage := TQ3Message.Create(FCoder, FLog);
  try
    LMessage.Init(AData, ALength);
    LMessage.CurSize := ALength;
    LMessage.Bitstream;
    FReliableAcknowledge := LMessage.ReadLong;
    FSink.ReliableAcknowledge(FReliableAcknowledge);
    while True do
    begin
      CheckNotPastEnd(LMessage);
      LCommand := LMessage.ReadByte;
      if LCommand = Q3_SVC_EOF then
        Break;
      case LCommand of
        Q3_SVC_NOP:
          ;
        Q3_SVC_SERVERCOMMAND:
          ParseCommandString(LMessage);
        Q3_SVC_GAMESTATE:
          ParseGamestate(LMessage);
        Q3_SVC_SNAPSHOT:
          ParseSnapshot(LMessage);
        Q3_SVC_DOWNLOAD:
          ParseDownload(LMessage);
      else
        RaiseServerError(SQ3ServerIllegibleMessage);
      end;
    end;
  finally
    LMessage.Free;
  end;
end;

end.
