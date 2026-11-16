{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the arbitration of the start of a game            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.StartArbiter;

interface

uses
  System.SysUtils, DelphiDoom.Net.Types, DelphiDoom.Net.Intf;

type
  /// <summary>
  ///   The wait of D_ArbitrateNetStart: the key player (console player 0) sends the settings of the
  ///   game to every node until all of them answered; the others wait for the settings. The
  ///   answer of a node is its first game packet, as in the old code
  /// </summary>
  TNetStartArbiter = class(TInterfacedObject, INetStartArbiter)
  private
    FPort: INetPacketPort;
    FAbort: INetAbortCheck;
    FNodeCount: Integer;
    FConsolePlayer: Integer;
    function Listen: TNetSetupInfo;
    procedure Broadcast(const AInfo: TNetSetupInfo);
  public
    /// <summary>AAbort is asked at every turn of the wait: it ends the wait with an exception</summary>
    constructor Create(const APort: INetPacketPort; const AAbort: INetAbortCheck;
      ANodeCount, AConsolePlayer: Integer);
    function Arbitrate(const AInfo: TNetSetupInfo): TNetSetupInfo;
  end;

implementation

const
  /// <summary>Packets read after each round of setup packets</summary>
  ANSWERS_PER_ROUND = 10;
  SDifferentVersions = 'Different versions cannot play a net game!';

{ TNetStartArbiter }

constructor TNetStartArbiter.Create(const APort: INetPacketPort; const AAbort: INetAbortCheck;
  ANodeCount, AConsolePlayer: Integer);
begin
  inherited Create;
  FPort := APort;
  FAbort := AAbort;
  FNodeCount := ANodeCount;
  FConsolePlayer := AConsolePlayer;
end;

function TNetStartArbiter.Arbitrate(const AInfo: TNetSetupInfo): TNetSetupInfo;
begin
  if FConsolePlayer <> 0 then
  begin
    Result := Listen;
    if Result.EngineVersion <> AInfo.EngineVersion then
      raise ENetVersionMismatchException.Create(SDifferentVersions);
  end
  else
  begin
    Broadcast(AInfo);
    Result := AInfo;
  end;
end;

function TNetStartArbiter.Listen: TNetSetupInfo;
var
  LPacket: TNetPacket;
  LNode: Integer;
begin
  // listen for setup info from key player
  while True do
  begin
    FAbort.Check;
    if not FPort.TryReceivePacket(LPacket, LNode) then
      Continue;
    if LPacket.IsSetup then
      Exit(TNetSetupInfo.FromPacket(LPacket));
  end;
end;

procedure TNetStartArbiter.Broadcast(const AInfo: TNetSetupInfo);
var
  LGotInfo: array[0..NET_MAX_NODES - 1] of Boolean;
  LPacket: TNetPacket;
  LNode: Integer;
  LIndex: Integer;
  LBudget: Integer;
begin
  for LIndex := 0 to NET_MAX_NODES - 1 do
    LGotInfo[LIndex] := False;
  // key player, send the setup info
  repeat
    FAbort.Check;
    for LIndex := 0 to FNodeCount - 1 do
    begin
      LPacket := AInfo.ToPacket;
      FPort.SendPacket(LIndex, LPacket, NCMD_SETUP);
    end;

    LBudget := ANSWERS_PER_ROUND;
    while (LBudget > 0) and FPort.TryReceivePacket(LPacket, LNode) do
    begin
      if (LPacket.Player and $7F) < NET_MAX_NODES then
        LGotInfo[LPacket.Player and $7F] := True;
      Dec(LBudget);
    end;

    LIndex := 1;
    while LIndex < FNodeCount do
    begin
      if not LGotInfo[LIndex] then
        Break;
      Inc(LIndex);
    end;
  until LIndex >= FNodeCount;
end;

end.
