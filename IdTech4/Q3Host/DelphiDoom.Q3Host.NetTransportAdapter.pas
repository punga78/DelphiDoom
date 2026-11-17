{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the netchan on an INetTransport        }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.NetTransportAdapter;

interface

uses
  System.SysUtils, DelphiDoom.Net.Transport.Intf, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf;

type
  /// <summary>
  ///   The numbering of the nodes of an <c>INetTransport</c> as addresses of the netchan: node n is the address
  ///   127.0.0.n with port n (type NA_LOOPBACK when the transport is a wire in memory), so an address goes back to
  ///   its node
  /// </summary>
  TQ3NodeAddresses = class sealed
  public
    class function FromNode(ANode: Integer; ALoopback: Boolean): TQ3NetAddress; static;
    class function ToNode(const AAddress: TQ3NetAddress): Integer; static;
  end;

  /// <summary>
  ///   NET_SendPacket of the netchan: the datagram goes to the node of the address on the transport. The receiving
  ///   side is the caller of the transport (it hands the datagram to the netchan)
  /// </summary>
  TQ3NetTransportAdapter = class(TInterfacedObject, IQ3NetTransport)
  strict private
    FTransport: INetTransport;
  public
    constructor Create(const ATransport: INetTransport);
    procedure SendPacket(ASource: TQ3NetSource; const AAddress: TQ3NetAddress; const AData: TBytes);
  end;

implementation

class function TQ3NodeAddresses.FromNode(ANode: Integer; ALoopback: Boolean): TQ3NetAddress;
begin
  Result := Default(TQ3NetAddress);
  if ALoopback then
    Result.AddressType := Ord(natLoopback)
  else
    Result.AddressType := Ord(natIp);
  Result.Ip[0] := 127;
  Result.Ip[3] := Byte(ANode);
  Result.Port := Word(ANode);
end;

class function TQ3NodeAddresses.ToNode(const AAddress: TQ3NetAddress): Integer;
begin
  Result := AAddress.Port;
end;

constructor TQ3NetTransportAdapter.Create(const ATransport: INetTransport);
begin
  inherited Create;
  FTransport := ATransport;
end;

procedure TQ3NetTransportAdapter.SendPacket(ASource: TQ3NetSource; const AAddress: TQ3NetAddress;
  const AData: TBytes);
begin
  FTransport.Send(TQ3NodeAddresses.ToNode(AAddress), AData);
end;

end.
