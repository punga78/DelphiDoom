{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - what a Quake III client learns from the server   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_parse.c.     }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.ServerMessage.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Types;

type
  /// <summary>
  ///   Receives the results of parsing the server messages (the places where <c>cl_parse.c</c> stores into
  ///   <c>cl</c> and <c>clc</c>). The parser keeps the state it needs to decode the next message, so a sink
  ///   only has to record or use what it is told
  /// </summary>
  IQ3ServerMessageSink = interface
    ['{4A9E7C12-5B38-4D61-8F0A-2D6C9E1B7F53}']
    /// <summary>The reliable sequence number the server acknowledges (first long of every message)</summary>
    procedure ReliableAcknowledge(AValue: Integer);
    /// <summary>svc_serverCommand: a new command string (one already seen is not repeated)</summary>
    procedure ServerCommand(ASequence: Integer; const AText: AnsiString);
    /// <summary>svc_gamestate starts: the state of the client is cleared</summary>
    procedure GamestateBegin(AServerCommandSequence: Integer);
    /// <summary>svc_configstring inside a gamestate</summary>
    procedure ConfigString(AIndex: Integer; const AText: AnsiString);
    /// <summary>svc_baseline inside a gamestate: the state the entity starts from</summary>
    procedure Baseline(ANumber: Integer; const AState: TQ3EntityState);
    /// <summary>The gamestate is complete</summary>
    procedure GamestateEnd(AClientNum, AChecksumFeed: Integer);
    /// <summary>svc_snapshot: a valid snapshot with its entities (an invalid one is read and dropped)</summary>
    procedure Snapshot(const ASnapshot: TQ3Snapshot);
    /// <summary>svc_download: a block of a file; ATotalSize is the size of the whole file in block 0 and 0 in the others</summary>
    procedure Download(ABlock, ATotalSize: Integer; const AData: TBytes);
  end;

implementation

end.
