{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the transport on UDP sockets (Winsock)            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.WinsockTransport;

interface

uses
  System.SysUtils, Winapi.Winsock, DelphiDoom.Net.Types, DelphiDoom.Net.Intf;

type
  /// <summary>
  ///   UDP on Winsock, as the old i_net: one socket bound to the local port that only receives
  ///   (without blocking) and another one that only sends. A datagram is attributed to a node
  ///   by the IP address of the sender, not by its port (as the old code did). A packet longer than
  ///   MaxPacketSize and a connection reset reported by Windows are not errors: they are lost datagrams
  /// </summary>
  TWinsockNetTransport = class(TInterfacedObject, INetTransport)
  private
    FReceiveSocket: TSocket;
    FSendSocket: TSocket;
    FPeers: array of TSockAddrIn;
    FMaxPacketSize: Integer;
    FStarted: Boolean;
    function ResolveHost(const AAddress: TNetNodeAddress): u_long;
    procedure CloseSockets;
  public
    /// <summary>
    ///   ALocalPort 0 lets Windows choose it (see LocalPort). APeers are the nodes 1..n; node 0, this
    ///   computer, has no address
    /// </summary>
    constructor Create(ALocalPort: Word; const APeers: TArray<TNetNodeAddress>;
      AMaxPacketSize: Integer = 1500);
    destructor Destroy; override;
    /// <summary>The port that receives (the one chosen by Windows if it was 0)</summary>
    function LocalPort: Word;
    /// <summary>Changes where a node is (1..NodeCount - 1)</summary>
    procedure SetPeerAddress(ANode: Integer; const AAddress: TNetNodeAddress);
    function NodeCount: Integer;
    procedure Send(ANode: Integer; const AData: TBytes);
    function Receive(out ANode: Integer; out AData: TBytes): Boolean;
  end;

implementation

const
  SStartupFailed = 'Could not initialize Windows Sockets, WSAStartup result = %d';
  SSocketFailed = 'UDPsocket(): Can''t create socket: result = %d';
  SBindFailed = 'BindToLocalPort(): Failed.';
  SSendFailed = 'PacketSend(): sendto() failed.';
  SReceiveFailed = 'PacketGet(): Network error.';
  SNoHost = 'gethostbyname(): couldn''t find %s';
  SBadNode = 'Net node %d does not exist (%d nodes).';
  SBadSize = 'The packet size of the transport must be greater than zero.';

{ TWinsockNetTransport }

constructor TWinsockNetTransport.Create(ALocalPort: Word; const APeers: TArray<TNetNodeAddress>;
  AMaxPacketSize: Integer);
var
  LData: TWSAData;
  LError: Integer;
  LAddress: TSockAddrIn;
  LNonBlocking: Integer;
  LIndex: Integer;
begin
  inherited Create;
  if AMaxPacketSize < 1 then
    raise ENetException.Create(SBadSize);
  FMaxPacketSize := AMaxPacketSize;
  FReceiveSocket := INVALID_SOCKET;
  FSendSocket := INVALID_SOCKET;

  LError := WSAStartup($0101, LData);
  if LError <> 0 then
    raise ENetException.CreateFmt(SStartupFailed, [LError]);
  FStarted := True;

  try
    SetLength(FPeers, Length(APeers) + 1);
    FillChar(FPeers[0], SizeOf(TSockAddrIn), 0);
    for LIndex := 0 to High(APeers) do
      SetPeerAddress(LIndex + 1, APeers[LIndex]);

    FReceiveSocket := socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if FReceiveSocket = INVALID_SOCKET then
      raise ENetException.CreateFmt(SSocketFailed, [Integer(FReceiveSocket)]);
    FillChar(LAddress, SizeOf(LAddress), 0);
    LAddress.sin_family := AF_INET;
    LAddress.sin_addr.s_addr := INADDR_ANY;
    LAddress.sin_port := htons(ALocalPort);
    if bind(FReceiveSocket, LAddress, SizeOf(LAddress)) = -1 then
      raise ENetException.Create(SBindFailed);
    LNonBlocking := 1;
    ioctlsocket(FReceiveSocket, FIONBIO, LNonBlocking);

    FSendSocket := socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if FSendSocket = INVALID_SOCKET then
      raise ENetException.CreateFmt(SSocketFailed, [Integer(FSendSocket)]);
  except
    CloseSockets;
    raise;
  end;
end;

destructor TWinsockNetTransport.Destroy;
begin
  CloseSockets;
  inherited Destroy;
end;

procedure TWinsockNetTransport.CloseSockets;
begin
  if FReceiveSocket <> INVALID_SOCKET then
    closesocket(FReceiveSocket);
  FReceiveSocket := INVALID_SOCKET;
  if FSendSocket <> INVALID_SOCKET then
    closesocket(FSendSocket);
  FSendSocket := INVALID_SOCKET;
  if FStarted then
    WSACleanup;
  FStarted := False;
end;

function TWinsockNetTransport.ResolveHost(const AAddress: TNetNodeAddress): u_long;
var
  LHostEntry: PHostEnt;
begin
  if AAddress.IsLiteral then
    Result := inet_addr(PAnsiChar(AnsiString(AAddress.Host)))
  else
  begin
    LHostEntry := gethostbyname(PAnsiChar(AnsiString(AAddress.Host)));
    if LHostEntry = nil then
      raise ENetException.CreateFmt(SNoHost, [AAddress.Host]);
    Result := u_long(PInteger(LHostEntry.h_addr_list^)^);
  end;
end;

procedure TWinsockNetTransport.SetPeerAddress(ANode: Integer; const AAddress: TNetNodeAddress);
begin
  if (ANode < 1) or (ANode >= Length(FPeers)) then
    raise ENetException.CreateFmt(SBadNode, [ANode, Length(FPeers)]);
  FillChar(FPeers[ANode], SizeOf(TSockAddrIn), 0);
  FPeers[ANode].sin_family := AF_INET;
  FPeers[ANode].sin_addr.s_addr := ResolveHost(AAddress);
  FPeers[ANode].sin_port := htons(AAddress.Port);
end;

function TWinsockNetTransport.LocalPort: Word;
var
  LAddress: TSockAddrIn;
  LLength: Integer;
begin
  LLength := SizeOf(LAddress);
  FillChar(LAddress, SizeOf(LAddress), 0);
  if getsockname(FReceiveSocket, LAddress, LLength) = SOCKET_ERROR then
    Exit(0);
  Result := ntohs(LAddress.sin_port);
end;

function TWinsockNetTransport.NodeCount: Integer;
begin
  Result := Length(FPeers);
end;

procedure TWinsockNetTransport.Send(ANode: Integer; const AData: TBytes);
var
  LResult: Integer;
begin
  if (ANode < 1) or (ANode >= Length(FPeers)) then
    raise ENetException.CreateFmt(SBadNode, [ANode, Length(FPeers)]);
  if Length(AData) = 0 then
    Exit;
  LResult := sendto(FSendSocket, AData[0], Length(AData), 0, FPeers[ANode], SizeOf(FPeers[ANode]));
  if LResult = SOCKET_ERROR then
    raise ENetException.Create(SSendFailed);
end;

function TWinsockNetTransport.Receive(out ANode: Integer; out AData: TBytes): Boolean;
var
  LBuffer: TBytes;
  LFrom: TSockAddrIn;
  LFromLength: Integer;
  LCount: Integer;
  LError: Integer;
  LIndex: Integer;
begin
  Result := False;
  ANode := -1;
  SetLength(LBuffer, FMaxPacketSize);
  LFromLength := SizeOf(LFrom);
  FillChar(LFrom, SizeOf(LFrom), 0);
  LCount := recvfrom(FReceiveSocket, LBuffer[0], FMaxPacketSize, 0, LFrom, LFromLength);
  if LCount = SOCKET_ERROR then
  begin
    LError := WSAGetLastError;
    if (LError <> WSAEWOULDBLOCK) and (LError <> WSAECONNRESET) and (LError <> WSAEMSGSIZE) then
      raise ENetException.Create(SReceiveFailed);
    Exit;
  end;

  // find remote node number
  for LIndex := 0 to High(FPeers) do
    if LFrom.sin_addr.s_addr = FPeers[LIndex].sin_addr.s_addr then
    begin
      ANode := LIndex;
      Break;
    end;
  if ANode < 0 then
    Exit; // packet is not from one of the players (new game broadcast)

  SetLength(AData, LCount);
  if LCount > 0 then
    Move(LBuffer[0], AData[0], LCount);
  Result := True;
end;

end.
