{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the net library - the fakes                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Clock.Intf, DelphiDoom.GameState.Intf,
  DelphiDoom.Net.Types, DelphiDoom.Net.Intf;

type
  TFakeNetTransport = class;

  /// <summary>A datagram that went through the fake network</summary>
  TFakeDatagram = record
    FromMachine: Integer;
    ToMachine: Integer;
    Data: TBytes;
  end;

  /// <summary>
  ///   The wire between computers (machines 0..n - 1). Faults are asked per link (from, to) and apply to
  ///   the next datagrams of that link: nothing is random, nothing depends on time
  /// </summary>
  TFakeNetwork = class
  private
    FEndpoints: TDictionary<Integer, TFakeNetTransport>;
    FDrop: TDictionary<Integer, Integer>;
    FDuplicate: TDictionary<Integer, Integer>;
    FCorrupt: TDictionary<Integer, Integer>;
    FReorder: TDictionary<Integer, Integer>;
    FHeld: TDictionary<Integer, TBytes>;
    FSent: TList<TFakeDatagram>;
    function Key(AFrom, ATo: Integer): Integer;
    function Take(ADictionary: TDictionary<Integer, Integer>; AKey: Integer): Boolean;
    procedure Put(AFrom, ATo: Integer; const AData: TBytes);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Attach(AMachine: Integer; AEndpoint: TFakeNetTransport);
    /// <summary>What a machine sends: faults first, then the delivery</summary>
    procedure Transmit(AFrom, ATo: Integer; const AData: TBytes);
    /// <summary>Delivers a datagram as it is, without faults and without recording it as sent</summary>
    procedure Inject(AFrom, ATo: Integer; const AData: TBytes);
    procedure DropNext(AFrom, ATo, ACount: Integer);
    procedure DuplicateNext(AFrom, ATo: Integer);
    /// <summary>The next datagram changes one byte of its commands: the checksum will fail</summary>
    procedure CorruptNext(AFrom, ATo: Integer);
    /// <summary>The next datagram is delivered after the one that follows it</summary>
    procedure ReorderNext(AFrom, ATo: Integer);
    /// <summary>Everything that was sent, in order (lost datagrams included)</summary>
    property Sent: TList<TFakeDatagram> read FSent;
  end;

  /// <summary>One computer on the fake network: node 0 is itself, node k is APeers[k - 1]</summary>
  TFakeNetTransport = class(TInterfacedObject, INetTransport)
  private
    FNetwork: TFakeNetwork;
    FMachine: Integer;
    FPeers: TArray<Integer>;
    FInbox: TQueue<TFakeDatagram>;
  public
    constructor Create(ANetwork: TFakeNetwork; AMachine: Integer; const APeers: TArray<Integer>);
    destructor Destroy; override;
    procedure Deliver(const ADatagram: TFakeDatagram);
    function NodeCount: Integer;
    procedure Send(ANode: Integer; const AData: TBytes);
    function Receive(out ANode: Integer; out AData: TBytes): Boolean;
    function PendingCount: Integer;
  end;

  /// <summary>A clock that only moves when the test says so</summary>
  TFakeClock = class(TInterfacedObject, IClock)
  public
    Tics: Integer;
    WaitCalls: Integer;
    function Seconds: Double;
    function Steps(ARate: Integer): Integer;
    function ScaledSteps(ARate, AScale: Integer): Integer;
    procedure Sleep(AMilliseconds: Integer);
    procedure Wait(AMilliseconds: Integer);
  end;

  TFakeGameContext = class(TInterfacedObject, IGameContext)
  public
    NetGame: Boolean;
    DemoPlayback: Boolean;
    DemoRecording: Boolean;
    Developer: Boolean;
    CurrentGameTic: Integer;
    constructor Create;
    function IsDeveloperMode: Boolean;
    function IsNetGame: Boolean;
    function IsDemoRecording: Boolean;
    function IsDemoPlayback: Boolean;
    function IsPaused: Boolean;
    function GameTic: Integer;
  end;

  /// <summary>
  ///   The commands it makes are CommandSize bytes: byte 0 is the player, byte 1 the low byte of the tic,
  ///   byte 2 the high byte; the rest is a counter of the commands made
  /// </summary>
  TFakeLocalInput = class(TInterfacedObject, INetLocalInput)
  public
    CommandSize: Integer;
    Player: Integer;
    Finished: Boolean;
    PollCalls: Integer;
    BuiltTics: TList<Integer>;
    constructor Create(ACommandSize, APlayer: Integer);
    destructor Destroy; override;
    procedure PollInput;
    function IsGameFinished: Boolean;
    function BuildTicCmd(ATic: Integer): TBytes;
  end;

  TFakePlayers = class(TInterfacedObject, INetPlayers)
  public
    InGame: array[0..7] of Boolean;
    Left: TList<Integer>;
    constructor Create;
    destructor Destroy; override;
    function IsPlayerInGame(APlayer: Integer): Boolean;
    procedure PlayerLeft(APlayer: Integer);
  end;

  TFakeTrace = class(TInterfacedObject, INetTrace)
  public
    Text: string;
    procedure Trace(const AText: string);
  end;

  /// <summary>Calls a procedure at every check, and ends the wait after a number of checks</summary>
  TFakeAbortCheck = class(TInterfacedObject, INetAbortCheck)
  public
    OnCheck: TProc;
    Checks: Integer;
    MaxChecks: Integer;
    procedure Check;
  end;

implementation

{ TFakeNetwork }

constructor TFakeNetwork.Create;
begin
  inherited Create;
  FEndpoints := TDictionary<Integer, TFakeNetTransport>.Create;
  FDrop := TDictionary<Integer, Integer>.Create;
  FDuplicate := TDictionary<Integer, Integer>.Create;
  FCorrupt := TDictionary<Integer, Integer>.Create;
  FReorder := TDictionary<Integer, Integer>.Create;
  FHeld := TDictionary<Integer, TBytes>.Create;
  FSent := TList<TFakeDatagram>.Create;
end;

destructor TFakeNetwork.Destroy;
begin
  FSent.Free;
  FHeld.Free;
  FReorder.Free;
  FCorrupt.Free;
  FDuplicate.Free;
  FDrop.Free;
  FEndpoints.Free;
  inherited Destroy;
end;

function TFakeNetwork.Key(AFrom, ATo: Integer): Integer;
begin
  Result := AFrom * 100 + ATo;
end;

function TFakeNetwork.Take(ADictionary: TDictionary<Integer, Integer>; AKey: Integer): Boolean;
var
  LCount: Integer;
begin
  Result := ADictionary.TryGetValue(AKey, LCount) and (LCount > 0);
  if Result then
    ADictionary[AKey] := LCount - 1;
end;

procedure TFakeNetwork.Attach(AMachine: Integer; AEndpoint: TFakeNetTransport);
begin
  FEndpoints.AddOrSetValue(AMachine, AEndpoint);
end;

procedure TFakeNetwork.Put(AFrom, ATo: Integer; const AData: TBytes);
var
  LDatagram: TFakeDatagram;
  LEndpoint: TFakeNetTransport;
begin
  LDatagram.FromMachine := AFrom;
  LDatagram.ToMachine := ATo;
  LDatagram.Data := Copy(AData);
  if FEndpoints.TryGetValue(ATo, LEndpoint) then
    LEndpoint.Deliver(LDatagram);
end;

procedure TFakeNetwork.Transmit(AFrom, ATo: Integer; const AData: TBytes);
var
  LDatagram: TFakeDatagram;
  LKey: Integer;
  LData: TBytes;
  LHeld: TBytes;
begin
  LDatagram.FromMachine := AFrom;
  LDatagram.ToMachine := ATo;
  LDatagram.Data := Copy(AData);
  FSent.Add(LDatagram);

  LKey := Key(AFrom, ATo);
  if Take(FDrop, LKey) then
    Exit;
  LData := Copy(AData);
  if Take(FCorrupt, LKey) and (Length(LData) > NET_PACKET_HEADER_SIZE) then
    LData[NET_PACKET_HEADER_SIZE] := LData[NET_PACKET_HEADER_SIZE] xor $FF;
  if Take(FReorder, LKey) then
  begin
    FHeld.AddOrSetValue(LKey, LData);
    Exit;
  end;
  Put(AFrom, ATo, LData);
  if Take(FDuplicate, LKey) then
    Put(AFrom, ATo, LData);
  if FHeld.TryGetValue(LKey, LHeld) then
  begin
    FHeld.Remove(LKey);
    Put(AFrom, ATo, LHeld);
  end;
end;

procedure TFakeNetwork.Inject(AFrom, ATo: Integer; const AData: TBytes);
begin
  Put(AFrom, ATo, AData);
end;

procedure TFakeNetwork.DropNext(AFrom, ATo, ACount: Integer);
begin
  FDrop.AddOrSetValue(Key(AFrom, ATo), ACount);
end;

procedure TFakeNetwork.DuplicateNext(AFrom, ATo: Integer);
begin
  FDuplicate.AddOrSetValue(Key(AFrom, ATo), 1);
end;

procedure TFakeNetwork.CorruptNext(AFrom, ATo: Integer);
begin
  FCorrupt.AddOrSetValue(Key(AFrom, ATo), 1);
end;

procedure TFakeNetwork.ReorderNext(AFrom, ATo: Integer);
begin
  FReorder.AddOrSetValue(Key(AFrom, ATo), 1);
end;

{ TFakeNetTransport }

constructor TFakeNetTransport.Create(ANetwork: TFakeNetwork; AMachine: Integer;
  const APeers: TArray<Integer>);
begin
  inherited Create;
  FNetwork := ANetwork;
  FMachine := AMachine;
  FPeers := APeers;
  FInbox := TQueue<TFakeDatagram>.Create;
  FNetwork.Attach(AMachine, Self);
end;

destructor TFakeNetTransport.Destroy;
begin
  FInbox.Free;
  inherited Destroy;
end;

procedure TFakeNetTransport.Deliver(const ADatagram: TFakeDatagram);
begin
  FInbox.Enqueue(ADatagram);
end;

function TFakeNetTransport.NodeCount: Integer;
begin
  Result := Length(FPeers) + 1;
end;

procedure TFakeNetTransport.Send(ANode: Integer; const AData: TBytes);
begin
  if (ANode < 1) or (ANode > Length(FPeers)) then
    raise ENetException.Create('fake transport: bad node');
  FNetwork.Transmit(FMachine, FPeers[ANode - 1], AData);
end;

function TFakeNetTransport.Receive(out ANode: Integer; out AData: TBytes): Boolean;
var
  LDatagram: TFakeDatagram;
  LIndex: Integer;
begin
  Result := False;
  ANode := -1;
  while FInbox.Count > 0 do
  begin
    LDatagram := FInbox.Dequeue;
    for LIndex := 0 to High(FPeers) do
      if FPeers[LIndex] = LDatagram.FromMachine then
      begin
        ANode := LIndex + 1;
        AData := LDatagram.Data;
        Exit(True);
      end;
    // not from a node of the game: it is lost
  end;
end;

function TFakeNetTransport.PendingCount: Integer;
begin
  Result := FInbox.Count;
end;

{ TFakeClock }

function TFakeClock.Seconds: Double;
begin
  Result := Tics / 35;
end;

function TFakeClock.Steps(ARate: Integer): Integer;
begin
  Result := Tics;
end;

function TFakeClock.ScaledSteps(ARate, AScale: Integer): Integer;
begin
  Result := Tics * AScale;
end;

procedure TFakeClock.Sleep(AMilliseconds: Integer);
begin
end;

procedure TFakeClock.Wait(AMilliseconds: Integer);
begin
  Inc(WaitCalls);
end;

{ TFakeGameContext }

constructor TFakeGameContext.Create;
begin
  inherited Create;
  NetGame := True;
end;

function TFakeGameContext.IsDeveloperMode: Boolean;
begin
  Result := Developer;
end;

function TFakeGameContext.IsNetGame: Boolean;
begin
  Result := NetGame;
end;

function TFakeGameContext.IsDemoRecording: Boolean;
begin
  Result := DemoRecording;
end;

function TFakeGameContext.IsDemoPlayback: Boolean;
begin
  Result := DemoPlayback;
end;

function TFakeGameContext.IsPaused: Boolean;
begin
  Result := False;
end;

function TFakeGameContext.GameTic: Integer;
begin
  Result := CurrentGameTic;
end;

{ TFakeLocalInput }

constructor TFakeLocalInput.Create(ACommandSize, APlayer: Integer);
begin
  inherited Create;
  CommandSize := ACommandSize;
  Player := APlayer;
  BuiltTics := TList<Integer>.Create;
end;

destructor TFakeLocalInput.Destroy;
begin
  BuiltTics.Free;
  inherited Destroy;
end;

procedure TFakeLocalInput.PollInput;
begin
  Inc(PollCalls);
end;

function TFakeLocalInput.IsGameFinished: Boolean;
begin
  Result := Finished;
end;

function TFakeLocalInput.BuildTicCmd(ATic: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, CommandSize);
  for LIndex := 0 to CommandSize - 1 do
    Result[LIndex] := Byte(BuiltTics.Count + LIndex);
  Result[0] := Byte(Player);
  Result[1] := Byte(ATic and $FF);
  Result[2] := Byte((ATic shr 8) and $FF);
  BuiltTics.Add(ATic);
end;

{ TFakePlayers }

constructor TFakePlayers.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  Left := TList<Integer>.Create;
  for LIndex := 0 to High(InGame) do
    InGame[LIndex] := True;
end;

destructor TFakePlayers.Destroy;
begin
  Left.Free;
  inherited Destroy;
end;

function TFakePlayers.IsPlayerInGame(APlayer: Integer): Boolean;
begin
  Result := InGame[APlayer];
end;

procedure TFakePlayers.PlayerLeft(APlayer: Integer);
begin
  InGame[APlayer] := False;
  Left.Add(APlayer);
end;

{ TFakeTrace }

procedure TFakeTrace.Trace(const AText: string);
begin
  Text := Text + AText;
end;

{ TFakeAbortCheck }

procedure TFakeAbortCheck.Check;
begin
  Inc(Checks);
  if Assigned(OnCheck) then
    OnCheck();
  if (MaxChecks > 0) and (Checks >= MaxChecks) then
    raise ENetException.Create('wait aborted');
end;

end.
