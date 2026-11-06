{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the contracts                                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Net.Types;

type
  /// <summary>
  ///   Datagrams between the computers of the game. Nodes are numbered as the engine does: node 0 is
  ///   this computer (never sent to), the others are in the order of the command line
  /// </summary>
  INetTransport = interface
    ['{4B8E21D6-7A53-4C09-9E1F-3D6A0C85B724}']
    /// <summary>Computers of the game, this one included</summary>
    function NodeCount: Integer;
    /// <summary>One datagram to a node (1..NodeCount - 1); a failure is an ENetException</summary>
    procedure Send(ANode: Integer; const AData: TBytes);
    /// <summary>
    ///   The next datagram, if there is one, and the node that sent it. A datagram from somebody that
    ///   is not a node of the game is not a datagram: the answer is false
    /// </summary>
    function Receive(out ANode: Integer; out AData: TBytes): Boolean;
  end;

  /// <summary>The bytes of a packet: the same that the engine always put on the wire</summary>
  INetPacketCodec = interface
    ['{91C3D7F0-5E28-4A6B-8D14-0F7B2E9A3C61}']
    /// <summary>Bytes of one command (sizeof(ticcmd_t) of the game that is running)</summary>
    function CommandSize: Integer;
    /// <summary>Most tics in a packet</summary>
    function MaxTics: Integer;
    /// <summary>Bytes of a packet with that many tics</summary>
    function PacketSize(ANumTics: Integer): Integer;
    /// <summary>
    ///   The bytes; the checksum is computed, AControl (NCMD_* flags) is added and the result is
    ///   written back into APacket.Checksum
    /// </summary>
    function Encode(var APacket: TNetPacket; AControl: LongWord): TBytes;
    function Decode(const AData: TBytes; out APacket: TNetPacket): TNetDecodeStatus;
  end;

  /// <summary>How the game gives the commands of the local player</summary>
  INetLocalInput = interface
    ['{2F6A94B1-C038-4D75-A1E9-6B8D5C70E342}']
    /// <summary>I_StartTic and D_ProcessEvents: read the devices and handle the events</summary>
    procedure PollInput;
    /// <summary>The program is quitting: stop everything</summary>
    function IsGameFinished: Boolean;
    /// <summary>The command of the local player for a tic (G_BuildTiccmd): CommandSize bytes</summary>
    function BuildTicCmd(ATic: Integer): TBytes;
  end;

  /// <summary>The players, which the engine owns (playeringame[])</summary>
  INetPlayers = interface
    ['{7D1E8C25-0B94-4F63-B7A2-E49C3F158D06}']
    function IsPlayerInGame(APlayer: Integer): Boolean;
    /// <summary>
    ///   A player left the game: the engine clears playeringame, shows "Player N left the game" and
    ///   closes the demo that it records
    /// </summary>
    procedure PlayerLeft(APlayer: Integer);
  end;

  /// <summary>A place for the trace of the packets (the debug file of the engine); optional</summary>
  INetTrace = interface
    ['{E5A07B93-4C16-4D2E-8F58-1A93D6B2C047}']
    /// <summary>The text is complete, with its line break</summary>
    procedure Trace(const AText: string);
  end;

  /// <summary>Called all the time while the game waits for the others at the start: it may end the wait</summary>
  INetAbortCheck = interface
    ['{0A4C6E18-D597-4B3F-92A0-7E1B58F3C6D9}']
    /// <summary>Raises an exception to abort the wait (the engine: D_CheckAbort)</summary>
    procedure Check;
  end;

  /// <summary>Packets in and out, as the old HSendPacket and HGetPacket</summary>
  INetPacketPort = interface
    ['{B3D92F07-61E4-4A58-8C1B-5F0A7E34D281}']
    /// <summary>
    ///   To a node; node 0 is this computer and gets the packet back, one packet at a time. A packet
    ///   to another node is sent only in a net game that is not a demo
    /// </summary>
    procedure SendPacket(ANode: Integer; var APacket: TNetPacket; AControl: LongWord);
    /// <summary>The next good packet; packets of the wrong length or checksum are lost here</summary>
    function TryReceivePacket(out APacket: TNetPacket; out ANode: Integer): Boolean;
  end;

  /// <summary>Exchange of the commands of the players (NetUpdate and what NetUpdate keeps)</summary>
  INetTicSync = interface
    ['{58F1A3C9-E207-4B64-9D8E-2C6B0A71F395}']
    /// <summary>Builds the commands of the local player for the new tics, sends the packets, reads the ones that came</summary>
    procedure NetUpdate;
    /// <summary>Tells the other nodes that this computer leaves the game</summary>
    procedure QuitNetGame;
    /// <summary>The command of a player for a tic of the net (tic div ticdup): CommandSize bytes</summary>
    function NetCommand(APlayer, ATic: Integer): TBytes;
    procedure SetNetCommand(APlayer, ATic: Integer; const ACommand: TBytes);
    /// <summary>Single tic mode: reads the devices and stores the command of the local player at MakeTic</summary>
    procedure BuildSingleTic;
    /// <summary>Single tic mode: the tic is done</summary>
    procedure EndSingleTic;
    function NetTic(ANode: Integer): Integer;
    function IsNodeInGame(ANode: Integer): Boolean;
    function GetMakeTic: Integer;
    function GetSingleTics: Boolean;
    procedure SetSingleTics(AValue: Boolean);
    /// <summary>The tic that has not had its command made yet</summary>
    property MakeTic: Integer read GetMakeTic;
    /// <summary>Each update is synchronous and does not send (singletics of the engine)</summary>
    property SingleTics: Boolean read GetSingleTics write SetSingleTics;
  end;

  /// <summary>How many tics the game can run (the decisions of D_RunMultipleTicks)</summary>
  INetTicPlanner = interface
    ['{C60B5E84-2A9D-4F17-B3E0-8D4F1A7C9253}']
    /// <summary>Starts a pass of the loop; the answer is the real tics from the last pass</summary>
    function BeginRun: Integer;
    /// <summary>How many tics to run; it also adapts the speed of the computers that are not the key player</summary>
    function PlanTics(ARealTics: Integer): Integer;
    /// <summary>The wait is too long (and it is not a demo): the menu must have a turn</summary>
    function MustYield: Boolean;
    /// <summary>
    ///   All the nodes have the commands for ACounts tics. A node that is behind the game is an
    ///   ENetException
    /// </summary>
    function TicsReady(ACounts: Integer): Boolean;
    /// <summary>The game tic must not be ahead of the node that is the slowest: an ENetException if it is</summary>
    procedure VerifyCanRunTic;
    /// <summary>Lowest number of tics of the nodes that are in the game</summary>
    function LowTic: Integer;
    function GetEnterTime: Integer;
    /// <summary>Time in tics at the beginning of the pass (I_GetTime)</summary>
    property EnterTime: Integer read GetEnterTime;
  end;

  /// <summary>The consistency check of the commands of the players (the part of G_Ticker that keeps the values)</summary>
  INetConsistency = interface
    ['{19E7B4D2-8F30-4C5A-A6D1-3B92C0E8F574}']
    /// <summary>Value to put in the command of the local player for a tic (maketic)</summary>
    function Expected(APlayer, ATic: Integer): SmallInt;
    /// <summary>
    ///   A command was received for a tic of the game: it must carry the value that was stored for
    ///   it (after BACKUPTICS tics); then the local value is stored for the next time
    /// </summary>
    procedure Verify(APlayer, AGameTic: Integer; AReceived: SmallInt; ALocalValue: Integer);
  end;

  /// <summary>The arbitration of the start of a net game</summary>
  INetStartArbiter = interface
    ['{83A2C6F9-D154-4E07-B58B-0C1E7A93F6D2}']
    /// <summary>
    ///   The key player (console player 0) sends AInfo until all the others answered and returns it. The
    ///   others wait for the setup of the key player and return it. Version mismatch: ENetVersionMismatchException
    /// </summary>
    function Arbitrate(const AInfo: TNetSetupInfo): TNetSetupInfo;
  end;

implementation

end.
