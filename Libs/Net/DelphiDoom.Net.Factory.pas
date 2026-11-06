{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the factory: the composition root                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Clock.Intf, DelphiDoom.Logging.Intf, DelphiDoom.GameState.Intf,
  DelphiDoom.Net.Types, DelphiDoom.Net.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the net library</summary>
  TNetFactory = class
  public
    /// <summary>The bytes of the packets of a game whose command (ticcmd_t) is ACommandSize bytes</summary>
    class function CreateCodec(ACommandSize: Integer): INetPacketCodec; static;
    /// <summary>UDP on Winsock; APeers are the nodes 1..n (the arguments after -net n)</summary>
    class function CreateWinsockTransport(ALocalPort: Word;
      const APeers: TArray<TNetNodeAddress>): INetTransport; static;
    /// <summary>
    ///   The synchronisation of the commands. The object is also an INetTicPlanner and an
    ///   INetPacketPort: ask for them with "as". ATransport, ALog and ATrace may be nil
    /// </summary>
    class function CreateTicSync(const ASettings: TNetSyncSettings; const ATransport: INetTransport;
      const ACodec: INetPacketCodec; const AClock: IClock; const ALog: ILog;
      const AGame: IGameContext; const AInput: INetLocalInput; const APlayers: INetPlayers;
      const ATrace: INetTrace): INetTicSync; static;
    class function CreateConsistencyTracker(AMaxPlayers, ATicDup: Integer): INetConsistency; static;
    class function CreateStartArbiter(const APort: INetPacketPort; const AAbort: INetAbortCheck;
      ANodeCount, AConsolePlayer: Integer): INetStartArbiter; static;
  end;

implementation

uses
  DelphiDoom.Net.PacketCodec, DelphiDoom.Net.WinsockTransport, DelphiDoom.Net.TicSync,
  DelphiDoom.Net.ConsistencyTracker, DelphiDoom.Net.StartArbiter;

{ TNetFactory }

class function TNetFactory.CreateCodec(ACommandSize: Integer): INetPacketCodec;
begin
  Result := TNetPacketCodec.Create(ACommandSize, NET_BACKUPTICS);
end;

class function TNetFactory.CreateWinsockTransport(ALocalPort: Word;
  const APeers: TArray<TNetNodeAddress>): INetTransport;
begin
  Result := TWinsockNetTransport.Create(ALocalPort, APeers);
end;

class function TNetFactory.CreateTicSync(const ASettings: TNetSyncSettings;
  const ATransport: INetTransport; const ACodec: INetPacketCodec; const AClock: IClock;
  const ALog: ILog; const AGame: IGameContext; const AInput: INetLocalInput;
  const APlayers: INetPlayers; const ATrace: INetTrace): INetTicSync;
begin
  Result := TNetTicSync.Create(ASettings, ATransport, ACodec, AClock, ALog, AGame, AInput, APlayers,
    ATrace);
end;

class function TNetFactory.CreateConsistencyTracker(AMaxPlayers, ATicDup: Integer): INetConsistency;
begin
  Result := TNetConsistencyTracker.Create(AMaxPlayers, ATicDup);
end;

class function TNetFactory.CreateStartArbiter(const APort: INetPacketPort;
  const AAbort: INetAbortCheck; ANodeCount, AConsolePlayer: Integer): INetStartArbiter;
begin
  Result := TNetStartArbiter.Create(APort, AAbort, ANodeCount, AConsolePlayer);
end;

end.
