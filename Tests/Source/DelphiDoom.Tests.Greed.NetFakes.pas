{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests - greed library: a net in memory for the net game          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.NetFakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Net.Transport.Intf;

type
  TFakeGreedNet = class;

  /// <summary>
  ///   One computer of the fake net: the INetTransport of Libs\Net that a TGreedNetSession is given. Node 0 is
  ///   this computer, the nodes 1 .. count - 1 are the others in the order of their numbers
  /// </summary>
  TFakeGreedNetEndpoint = class(TInterfacedObject, INetTransport)
  strict private
    FNet: TFakeGreedNet;
    FIndex: Integer;
  public
    constructor Create(ANet: TFakeGreedNet; AIndex: Integer);
    function NodeCount: Integer;
    procedure Send(ANode: Integer; const AData: TBytes);
    function Receive(out ANode: Integer; out AData: TBytes): Boolean;
  end;

  TFakeGreedDatagram = record
    Source: Integer;
    Target: Integer;
    Data: TBytes;
  end;

  /// <summary>
  ///   A net of some computers in memory: a datagram that is sent is in the queue of who it is for at once, in
  ///   order, unless the test says otherwise: LoseNext drops the next ones, HoldBack keeps them aside until
  ///   Release delivers them (in the order they were sent or the other way round: packets out of order). Nothing
  ///   depends on time. The net must outlive its endpoints
  /// </summary>
  TFakeGreedNet = class
  strict private
    FCount: Integer;
    FQueues: TObjectList<TQueue<TFakeGreedDatagram>>;
    FHeld: TList<TFakeGreedDatagram>;
    FSent: TList<TFakeGreedDatagram>;
    FLoseNext: Integer;
    FHoldBack: Boolean;
    FLost: Integer;
    procedure Deliver(const ADatagram: TFakeGreedDatagram);
  public
    constructor Create(ACount: Integer);
    destructor Destroy; override;
    /// <summary>The transport of the computer AIndex (0 .. count - 1)</summary>
    function Endpoint(AIndex: Integer): INetTransport;
    /// <summary>A datagram from ASource for ATarget, as if it had been sent</summary>
    procedure Inject(ASource, ATarget: Integer; const AData: TBytes);
    /// <summary>The next ACount datagrams that are sent get lost</summary>
    procedure LoseNext(ACount: Integer);
    /// <summary>The datagrams that were held back are delivered; AReversed: the last one first</summary>
    procedure Release(AReversed: Boolean);
    /// <summary>What the computer AIndex sent since the last call (one entry for each target)</summary>
    function TakeSent(AIndex: Integer): TArray<TBytes>;
    /// <summary>Datagrams waiting to be read by the computer AIndex</summary>
    function Pending(AIndex: Integer): Integer;
    procedure Push(ASource, ATarget: Integer; const AData: TBytes);
    function Pop(ATarget: Integer; out ADatagram: TFakeGreedDatagram): Boolean;
    property Count: Integer read FCount;
    /// <summary>While true the datagrams that are sent wait for Release</summary>
    property HoldBack: Boolean read FHoldBack write FHoldBack;
    property Lost: Integer read FLost;
  end;

implementation

{ TFakeGreedNetEndpoint }

constructor TFakeGreedNetEndpoint.Create(ANet: TFakeGreedNet; AIndex: Integer);
begin
  inherited Create;
  FNet := ANet;
  FIndex := AIndex;
end;

function TFakeGreedNetEndpoint.NodeCount: Integer;
begin
  Result := FNet.Count;
end;

procedure TFakeGreedNetEndpoint.Send(ANode: Integer; const AData: TBytes);
var
  LTarget: Integer;
begin
  if (ANode < 1) or (ANode >= FNet.Count) then
    raise EArgumentOutOfRangeException.Create('ANode');
  // the nodes 1 .. are the other computers in order, this one left out
  LTarget := ANode - 1;
  if LTarget >= FIndex then
    Inc(LTarget);
  FNet.Push(FIndex, LTarget, Copy(AData));
end;

function TFakeGreedNetEndpoint.Receive(out ANode: Integer; out AData: TBytes): Boolean;
var
  LDatagram: TFakeGreedDatagram;
begin
  ANode := -1;
  AData := nil;
  Result := FNet.Pop(FIndex, LDatagram);
  if not Result then
    Exit;
  AData := LDatagram.Data;
  if LDatagram.Source < FIndex then
    ANode := LDatagram.Source + 1
  else
    ANode := LDatagram.Source;
end;

{ TFakeGreedNet }

constructor TFakeGreedNet.Create(ACount: Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  FCount := ACount;
  FQueues := TObjectList<TQueue<TFakeGreedDatagram>>.Create(True);
  for LIndex := 0 to ACount - 1 do
    FQueues.Add(TQueue<TFakeGreedDatagram>.Create);
  FHeld := TList<TFakeGreedDatagram>.Create;
  FSent := TList<TFakeGreedDatagram>.Create;
end;

destructor TFakeGreedNet.Destroy;
begin
  FSent.Free;
  FHeld.Free;
  FQueues.Free;
  inherited Destroy;
end;

function TFakeGreedNet.Endpoint(AIndex: Integer): INetTransport;
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EArgumentOutOfRangeException.Create('AIndex');
  Result := TFakeGreedNetEndpoint.Create(Self, AIndex);
end;

procedure TFakeGreedNet.Deliver(const ADatagram: TFakeGreedDatagram);
begin
  FQueues[ADatagram.Target].Enqueue(ADatagram);
end;

procedure TFakeGreedNet.Push(ASource, ATarget: Integer; const AData: TBytes);
var
  LDatagram: TFakeGreedDatagram;
begin
  LDatagram.Source := ASource;
  LDatagram.Target := ATarget;
  LDatagram.Data := AData;
  FSent.Add(LDatagram);
  if FLoseNext > 0 then
  begin
    Dec(FLoseNext);
    Inc(FLost);
  end
  else if FHoldBack then
    FHeld.Add(LDatagram)
  else
    Deliver(LDatagram);
end;

function TFakeGreedNet.Pop(ATarget: Integer; out ADatagram: TFakeGreedDatagram): Boolean;
begin
  Result := FQueues[ATarget].Count > 0;
  if Result then
    ADatagram := FQueues[ATarget].Dequeue;
end;

procedure TFakeGreedNet.Inject(ASource, ATarget: Integer; const AData: TBytes);
var
  LDatagram: TFakeGreedDatagram;
begin
  LDatagram.Source := ASource;
  LDatagram.Target := ATarget;
  LDatagram.Data := Copy(AData);
  Deliver(LDatagram);
end;

procedure TFakeGreedNet.LoseNext(ACount: Integer);
begin
  FLoseNext := ACount;
end;

procedure TFakeGreedNet.Release(AReversed: Boolean);
var
  LIndex: Integer;
begin
  if AReversed then
    for LIndex := FHeld.Count - 1 downto 0 do
      Deliver(FHeld[LIndex])
  else
    for LIndex := 0 to FHeld.Count - 1 do
      Deliver(FHeld[LIndex]);
  FHeld.Clear;
end;

function TFakeGreedNet.TakeSent(AIndex: Integer): TArray<TBytes>;
var
  LIndex, LCount: Integer;
begin
  LCount := 0;
  SetLength(Result, FSent.Count);
  for LIndex := 0 to FSent.Count - 1 do
    if FSent[LIndex].Source = AIndex then
    begin
      Result[LCount] := FSent[LIndex].Data;
      Inc(LCount);
    end;
  SetLength(Result, LCount);
  for LIndex := FSent.Count - 1 downto 0 do
    if FSent[LIndex].Source = AIndex then
      FSent.Delete(LIndex);
end;

function TFakeGreedNet.Pending(AIndex: Integer): Integer;
begin
  Result := FQueues[AIndex].Count;
end;

end.
