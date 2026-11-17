{******************************************************************************}
{                                                                              }
{  DelphiDoom: net transport library - two transports joined in memory         }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.LoopbackTransport;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Net.Transport.Intf;

type
  /// <summary>
  ///   Two <c>INetTransport</c> that are the two ends of one wire in memory: what one sends the other receives,
  ///   in order, with no loss (no socket is opened). Each has two nodes: node 0 is itself, node 1 the other end.
  ///   For a server and a client in the same process, and for the tests of anything that speaks to a transport.
  ///   The wire lives as long as one of the ends
  /// </summary>
  TNetLoopbackPair = class sealed
  strict private
    type
      TByteQueue = TQueue<TBytes>;
      /// <summary>The two queues; the ends keep it alive</summary>
      TWire = class(TInterfacedObject)
      strict private
        FQueues: array[0..1] of TByteQueue;
      public
        constructor Create;
        destructor Destroy; override;
        function Queue(ASide: Integer): TByteQueue;
      end;
      TEndpoint = class(TInterfacedObject, INetTransport)
      strict private
        FWire: IInterface;
        FWireObject: TWire;
        FSide: Integer;
      public
        constructor Create(const AWire: TWire; ASide: Integer);
        function NodeCount: Integer;
        procedure Send(ANode: Integer; const AData: TBytes);
        function Receive(out ANode: Integer; out AData: TBytes): Boolean;
      end;
    var
      FLeft: INetTransport;
      FRight: INetTransport;
  public
    constructor Create;
    property Left: INetTransport read FLeft;
    property Right: INetTransport read FRight;
  end;

implementation

uses
  DelphiDoom.Net.Transport.Types;

resourcestring
  SBadNode = 'Loopback transport: node %d is not the other end (only node 1 is)';

{ TNetLoopbackPair.TWire }

constructor TNetLoopbackPair.TWire.Create;
begin
  inherited Create;
  FQueues[0] := TByteQueue.Create;
  FQueues[1] := TByteQueue.Create;
end;

destructor TNetLoopbackPair.TWire.Destroy;
begin
  FQueues[0].Free;
  FQueues[1].Free;
  inherited Destroy;
end;

function TNetLoopbackPair.TWire.Queue(ASide: Integer): TByteQueue;
begin
  Result := FQueues[ASide];
end;

{ TNetLoopbackPair.TEndpoint }

constructor TNetLoopbackPair.TEndpoint.Create(const AWire: TWire; ASide: Integer);
begin
  inherited Create;
  FWire := AWire;
  FWireObject := AWire;
  FSide := ASide;
end;

function TNetLoopbackPair.TEndpoint.NodeCount: Integer;
begin
  Result := 2;
end;

procedure TNetLoopbackPair.TEndpoint.Send(ANode: Integer; const AData: TBytes);
begin
  if ANode <> 1 then
    raise ENetException.CreateFmt(SBadNode, [ANode]);
  FWireObject.Queue(1 - FSide).Enqueue(Copy(AData));
end;

function TNetLoopbackPair.TEndpoint.Receive(out ANode: Integer; out AData: TBytes): Boolean;
begin
  Result := FWireObject.Queue(FSide).Count > 0;
  if Result then
  begin
    ANode := 1;
    AData := FWireObject.Queue(FSide).Dequeue;
  end
  else
  begin
    ANode := 0;
    AData := nil;
  end;
end;

{ TNetLoopbackPair }

constructor TNetLoopbackPair.Create;
var
  LWire: TWire;
begin
  inherited Create;
  LWire := TWire.Create;
  FLeft := TEndpoint.Create(LWire, 0);
  FRight := TEndpoint.Create(LWire, 1);
end;

end.
