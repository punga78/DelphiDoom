{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - what the client does with the parsed    }
{  messages of the server                                                       }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_parse.c      }
{  (the stores of CL_ParseGamestate, CL_ParseSnapshot and                       }
{  CL_ParseCommandString into cl and clc). Copyright (C) 1999-2005 Id           }
{  Software, Inc. This unit is derived from the Quake III Arena source code     }
{  and is therefore available under the GNU General Public License, version 2   }
{  or (at your option) any later version.                                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.ClientMessageSink;

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.ServerMessage.Intf, DelphiDoom.Q3Host.ClientState;

type
  /// <summary>
  ///   The sink of the parser of the server messages (TQ3ServerMessageParser, parity with cl_parse.c) that fills
  ///   the state of the client the system calls of cgame read (TQ3ClientState): the stores into cl.gameState,
  ///   clc.serverCommands and cl.snapshots. The baselines are kept by the parser (it needs them to undo the
  ///   deltas), so the sink drops them; downloads are not served (no download is ever started)
  /// </summary>
  TQ3ClientMessageSink = class(TInterfacedObject, IQ3ServerMessageSink)
  strict private
    FState: TQ3ClientState;
  public
    /// <summary>The state is not owned: it must live as long as the sink</summary>
    constructor Create(const AState: TQ3ClientState);
    procedure ReliableAcknowledge(AValue: Integer);
    procedure ServerCommand(ASequence: Integer; const AText: AnsiString);
    procedure GamestateBegin(AServerCommandSequence: Integer);
    procedure ConfigString(AIndex: Integer; const AText: AnsiString);
    procedure Baseline(ANumber: Integer; const AState: TQ3EntityState);
    procedure GamestateEnd(AClientNum, AChecksumFeed: Integer);
    procedure Snapshot(const ASnapshot: TQ3Snapshot);
    procedure Download(ABlock, ATotalSize: Integer; const AData: TBytes);
  end;

implementation

uses
  DelphiDoom.Q3Host.Client.Types;

constructor TQ3ClientMessageSink.Create(const AState: TQ3ClientState);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  FState := AState;
end;

procedure TQ3ClientMessageSink.ReliableAcknowledge(AValue: Integer);
begin
  FState.AcknowledgeReliableCommands(AValue);
end;

procedure TQ3ClientMessageSink.ServerCommand(ASequence: Integer; const AText: AnsiString);
begin
  FState.StoreServerCommand(ASequence, AText);
end;

procedure TQ3ClientMessageSink.GamestateBegin(AServerCommandSequence: Integer);
begin
  // wipe local client state, then a gamestate always marks a server command sequence
  FState.ClearState;
  FState.SetServerCommandSequence(AServerCommandSequence);
end;

procedure TQ3ClientMessageSink.ConfigString(AIndex: Integer; const AText: AnsiString);
begin
  FState.GamestateConfigString(AIndex, AText);
end;

procedure TQ3ClientMessageSink.Baseline(ANumber: Integer; const AState: TQ3EntityState);
begin
  // cl.entityBaselines: the parser keeps them
end;

procedure TQ3ClientMessageSink.GamestateEnd(AClientNum, AChecksumFeed: Integer);
begin
  FState.GamestateEnd(AClientNum, AChecksumFeed);
end;

procedure TQ3ClientMessageSink.Snapshot(const ASnapshot: TQ3Snapshot);
var
  LSnapshot: TQ3ClientSnapshot;
  LEntities: TBytes;
begin
  LSnapshot := Default(TQ3ClientSnapshot);
  LSnapshot.Valid := ASnapshot.Valid;
  LSnapshot.SnapFlags := ASnapshot.SnapFlags;
  LSnapshot.ServerTime := ASnapshot.ServerTime;
  LSnapshot.MessageNum := ASnapshot.MessageNum;
  LSnapshot.ServerCommandNum := ASnapshot.ServerCommandNum;
  LSnapshot.Ping := ASnapshot.Ping;
  LSnapshot.NumEntities := ASnapshot.NumEntities;
  LSnapshot.ParseEntitiesNum := ASnapshot.ParseEntitiesNum;
  Move(ASnapshot.AreaMask[0], LSnapshot.AreaMask[0], SizeOf(LSnapshot.AreaMask));
  Move(ASnapshot.PlayerState, LSnapshot.PlayerState[0], SizeOf(LSnapshot.PlayerState));
  SetLength(LEntities, Length(ASnapshot.Entities) * Q3_ENTITYSTATE_SIZE);
  if Length(LEntities) > 0 then
    Move(ASnapshot.Entities[0], LEntities[0], Length(LEntities));
  FState.AddParsedSnapshot(LSnapshot, LEntities);
end;

procedure TQ3ClientMessageSink.Download(ABlock, ATotalSize: Integer; const AData: TBytes);
begin
  // CL_ParseDownload: the client never asks for a file
end;

end.