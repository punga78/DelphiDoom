{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - shared types and constants                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Tics kept for every player and for the local commands (BACKUPTICS of the engine)</summary>
  NET_BACKUPTICS = 12;
  /// <summary>Most computers in a game (MAXNETNODES of the engine)</summary>
  NET_MAX_NODES = 8;
  /// <summary>Bytes of a packet before the commands: checksum, 4 bytes, flags</summary>
  NET_PACKET_HEADER_SIZE = 12;
  /// <summary>Port of the engine when -port is not given (IPPORT_USERRESERVED + $1d)</summary>
  NET_DEFAULT_PORT = 5000 + $1D;
  /// <summary>The low byte of tic numbers is the only one that travels</summary>
  NET_TIC_WRAP = 256;
  /// <summary>Packets that are ignored after a retransmit request was accepted (CRESENDCOUNT)</summary>
  NET_RESEND_COUNT = 10;
  /// <summary>Tics that the loop of the game may wait for the network before giving the menu a chance</summary>
  NET_YIELD_TICS = 10;

  /// <summary>High bit of the checksum word: the sender leaves the game</summary>
  NCMD_EXIT = LongWord($80000000);
  /// <summary>The sender asks to send again the tics from RetransmitFrom</summary>
  NCMD_RETRANSMIT = LongWord($40000000);
  /// <summary>Packet of the start of the game: it carries the settings of the game</summary>
  NCMD_SETUP = LongWord($20000000);
  /// <summary>Kill the game</summary>
  NCMD_KILL = LongWord($10000000);
  /// <summary>The bits of the checksum word that are the checksum</summary>
  NCMD_CHECKSUM = LongWord($0FFFFFFF);

  /// <summary>Bit flag of the player byte: the sender is a drone (never set by the engine)</summary>
  NET_PLAYER_DRONE = $80;

type
  /// <summary>Every failure of the net library; the engine turns it into I_Error</summary>
  ENetException = class(Exception);

  /// <summary>The other computer runs another version of the engine</summary>
  ENetVersionMismatchException = class(ENetException);

  /// <summary>A player's commands do not carry the consistency value that this computer expects</summary>
  ENetConsistencyException = class(ENetException);

  /// <summary>What happened when the bytes of a datagram were read as a packet</summary>
  TNetDecodeStatus = (ndsOk, ndsBadLength, ndsBadChecksum);

  /// <summary>
  ///   A packet (doomdata_t): the first word has the checksum in its low 28 bits and the NCMD_* flags
  ///   in the high 4. The commands are opaque: NumTics blocks of the command size of the game
  /// </summary>
  TNetPacket = record
    Checksum: LongWord;
    /// <summary>Low byte of the first tic to send again, only valid with NCMD_RETRANSMIT</summary>
    RetransmitFrom: Byte;
    /// <summary>Low byte of the first tic of the packet</summary>
    StartTic: Byte;
    /// <summary>Console player of the sender (NET_PLAYER_DRONE is a flag)</summary>
    Player: Byte;
    NumTics: Byte;
    Flags: LongWord;
    /// <summary>NumTics commands one after the other</summary>
    Commands: TBytes;
    function IsExit: Boolean;
    function IsRetransmit: Boolean;
    function IsSetup: Boolean;
    function IsKill: Boolean;
  end;

  /// <summary>Where another computer is: a name or a dotted address, and a port</summary>
  TNetNodeAddress = record
    Host: string;
    /// <summary>True: Host is a dotted address (written ".1.2.3.4" in the arguments), no name lookup</summary>
    IsLiteral: Boolean;
    Port: Word;
  end;

  /// <summary>What every computer of the game must agree on, sent by the key player in the start packets</summary>
  TNetSetupInfo = record
    /// <summary>Version of the engine: another version cannot play</summary>
    EngineVersion: Byte;
    /// <summary>0..15</summary>
    Skill: Byte;
    /// <summary>0..3</summary>
    Deathmatch: Byte;
    NoMonsters: Boolean;
    Respawn: Boolean;
    /// <summary>Map; in the games with episodes also the episode (see PackMap)</summary>
    MapByte: Byte;
    /// <summary>Bit flags of the options of the engine (jumps, random monsters ...)</summary>
    Flags: LongWord;
    function ToPacket: TNetPacket;
    class function FromPacket(const APacket: TNetPacket): TNetSetupInfo; static;
    /// <summary>Episode * 64 + map, as the games with episodes send it</summary>
    class function PackMap(AEpisode, AMap: Integer): Byte; static;
    class function UnpackEpisode(AMapByte: Byte): Integer; static;
    class function UnpackMap(AMapByte: Byte): Integer; static;
  end;

  /// <summary>What the net library needs to know of the game that starts</summary>
  TNetSyncSettings = record
    /// <summary>Computers, this one included as node 0</summary>
    NodeCount: Integer;
    /// <summary>Players of the game (MAXPLAYERS of the engine at most)</summary>
    MaxPlayers: Integer;
    ConsolePlayer: Integer;
    /// <summary>1 = no duplication, 2..9 = every command is used for more tics</summary>
    TicDup: Integer;
    /// <summary>1 = a backup tic goes in every packet</summary>
    ExtraTics: Integer;
    /// <summary>Tics in a second (TICRATE)</summary>
    TicRate: Integer;
    class function Make(ANodeCount, AMaxPlayers, AConsolePlayer: Integer): TNetSyncSettings; static;
  end;

implementation

{ TNetPacket }

function TNetPacket.IsExit: Boolean;
begin
  Result := (Checksum and NCMD_EXIT) <> 0;
end;

function TNetPacket.IsRetransmit: Boolean;
begin
  Result := (Checksum and NCMD_RETRANSMIT) <> 0;
end;

function TNetPacket.IsSetup: Boolean;
begin
  Result := (Checksum and NCMD_SETUP) <> 0;
end;

function TNetPacket.IsKill: Boolean;
begin
  Result := (Checksum and NCMD_KILL) <> 0;
end;

{ TNetSetupInfo }

function TNetSetupInfo.ToPacket: TNetPacket;
var
  LValue: Integer;
begin
  Result := Default(TNetPacket);
  LValue := Skill;
  if Deathmatch <> 0 then
    LValue := LValue or (Deathmatch shl 6);
  if NoMonsters then
    LValue := LValue or $20;
  if Respawn then
    LValue := LValue or $10;
  Result.RetransmitFrom := Byte(LValue and $FF);
  Result.StartTic := MapByte;
  Result.Player := EngineVersion;
  Result.NumTics := 0;
  Result.Flags := Flags;
end;

class function TNetSetupInfo.FromPacket(const APacket: TNetPacket): TNetSetupInfo;
begin
  Result := Default(TNetSetupInfo);
  Result.EngineVersion := APacket.Player;
  Result.Skill := APacket.RetransmitFrom and 15;
  Result.Deathmatch := (APacket.RetransmitFrom and $C0) shr 6;
  Result.NoMonsters := (APacket.RetransmitFrom and $20) <> 0;
  Result.Respawn := (APacket.RetransmitFrom and $10) <> 0;
  Result.MapByte := APacket.StartTic;
  Result.Flags := APacket.Flags;
end;

class function TNetSetupInfo.PackMap(AEpisode, AMap: Integer): Byte;
begin
  Result := Byte((AEpisode * 64 + AMap) and $FF);
end;

class function TNetSetupInfo.UnpackEpisode(AMapByte: Byte): Integer;
begin
  Result := AMapByte shr 6;
end;

class function TNetSetupInfo.UnpackMap(AMapByte: Byte): Integer;
begin
  Result := AMapByte and $3F;
end;

{ TNetSyncSettings }

class function TNetSyncSettings.Make(ANodeCount, AMaxPlayers, AConsolePlayer: Integer): TNetSyncSettings;
begin
  Result.NodeCount := ANodeCount;
  Result.MaxPlayers := AMaxPlayers;
  Result.ConsolePlayer := AConsolePlayer;
  Result.TicDup := 1;
  Result.ExtraTics := 0;
  Result.TicRate := 35;
end;

end.
