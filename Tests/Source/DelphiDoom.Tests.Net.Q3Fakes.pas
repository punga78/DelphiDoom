{******************************************************************************}
{                                                                              }
{  DelphiDoom: fakes for the tests of the network of Quake III                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.Q3Fakes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Logging.Intf, DelphiDoom.Net.Q3.Types,
  DelphiDoom.Net.Q3.Intf, DelphiDoom.Net.Q3.ServerMessage.Intf;

type
  /// <summary>A datagram that went through the fake transport</summary>
  TFakeQ3Packet = record
    Source: TQ3NetSource;
    Address: TQ3NetAddress;
    Data: TBytes;
  end;

  /// <summary>An in memory transport: keeps every datagram that is sent</summary>
  TFakeQ3Transport = class(TInterfacedObject, IQ3NetTransport)
  strict private
    FPackets: TList<TFakeQ3Packet>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SendPacket(ASource: TQ3NetSource; const AAddress: TQ3NetAddress; const AData: TBytes);
    procedure AddPacket(ASource: TQ3NetSource; const AData: TBytes);
    property Packets: TList<TFakeQ3Packet> read FPackets;
  end;

  /// <summary>A log that keeps what it is told</summary>
  TFakeQ3Log = class(TInterfacedObject, ILog)
  strict private
    FText: string;
    FInfos: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    procedure Clear;
    /// <summary>The warnings, one after the other without separators</summary>
    property Text: string read FText;
    property Infos: TStringList read FInfos;
  end;

  /// <summary>
  ///   A sink that keeps what the client of Quake III would keep (<c>cl.gameState</c>, <c>cl.entityBaselines</c>,
  ///   <c>cl.snap</c>, <c>clc.serverCommands</c>) and a text line for every event
  /// </summary>
  TFakeQ3ServerSink = class(TInterfacedObject, IQ3ServerMessageSink)
  strict private
    FEvents: TStringList;
    FCommands: array[0..63] of AnsiString;
    FConfigStrings: TDictionary<Integer, AnsiString>;
    FBaselines: array[0..Q3_MAX_GENTITIES - 1] of TQ3EntityState;
    FSnapshot: TQ3Snapshot;
    FDownloadBytes: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ReliableAcknowledge(AValue: Integer);
    procedure ServerCommand(ASequence: Integer; const AText: AnsiString);
    procedure GamestateBegin(AServerCommandSequence: Integer);
    procedure ConfigString(AIndex: Integer; const AText: AnsiString);
    procedure Baseline(ANumber: Integer; const AState: TQ3EntityState);
    procedure GamestateEnd(AClientNum, AChecksumFeed: Integer);
    procedure Snapshot(const ASnapshot: TQ3Snapshot);
    procedure Download(ABlock, ATotalSize: Integer; const AData: TBytes);
    function CommandAt(ASequence: Integer): AnsiString;
    function BaselineAt(ANumber: Integer): TQ3EntityState;
    property Events: TStringList read FEvents;
    property ConfigStrings: TDictionary<Integer, AnsiString> read FConfigStrings;
    property LastSnapshot: TQ3Snapshot read FSnapshot;
    property DownloadBytes: Integer read FDownloadBytes;
  end;

implementation

{ TFakeQ3ServerSink }

constructor TFakeQ3ServerSink.Create;
begin
  inherited Create;
  FEvents := TStringList.Create;
  FConfigStrings := TDictionary<Integer, AnsiString>.Create;
end;

destructor TFakeQ3ServerSink.Destroy;
begin
  FConfigStrings.Free;
  FEvents.Free;
  inherited Destroy;
end;

procedure TFakeQ3ServerSink.ReliableAcknowledge(AValue: Integer);
begin
  FEvents.Add('ack ' + IntToStr(AValue));
end;

procedure TFakeQ3ServerSink.ServerCommand(ASequence: Integer; const AText: AnsiString);
begin
  FCommands[ASequence and 63] := AText;
  FEvents.Add('command ' + IntToStr(ASequence) + ' ' + string(AText));
end;

procedure TFakeQ3ServerSink.GamestateBegin(AServerCommandSequence: Integer);
begin
  FConfigStrings.Clear;
  FillChar(FBaselines, SizeOf(FBaselines), 0);
  Finalize(FSnapshot);
  FillChar(FSnapshot, SizeOf(FSnapshot), 0);
  FEvents.Add('gamestate ' + IntToStr(AServerCommandSequence));
end;

procedure TFakeQ3ServerSink.ConfigString(AIndex: Integer; const AText: AnsiString);
begin
  FConfigStrings.AddOrSetValue(AIndex, AText);
  FEvents.Add('configstring ' + IntToStr(AIndex));
end;

procedure TFakeQ3ServerSink.Baseline(ANumber: Integer; const AState: TQ3EntityState);
begin
  FBaselines[ANumber] := AState;
  FEvents.Add('baseline ' + IntToStr(ANumber));
end;

procedure TFakeQ3ServerSink.GamestateEnd(AClientNum, AChecksumFeed: Integer);
begin
  FEvents.Add('gamestate end ' + IntToStr(AClientNum) + ' ' + IntToStr(AChecksumFeed));
end;

procedure TFakeQ3ServerSink.Snapshot(const ASnapshot: TQ3Snapshot);
begin
  FSnapshot := ASnapshot;
  FEvents.Add('snapshot ' + IntToStr(ASnapshot.MessageNum) + ' ' + IntToStr(Length(ASnapshot.Entities)));
end;

procedure TFakeQ3ServerSink.Download(ABlock, ATotalSize: Integer; const AData: TBytes);
begin
  Inc(FDownloadBytes, Length(AData));
  FEvents.Add('download ' + IntToStr(ABlock) + ' ' + IntToStr(ATotalSize) + ' ' + IntToStr(Length(AData)));
end;

function TFakeQ3ServerSink.CommandAt(ASequence: Integer): AnsiString;
begin
  Result := FCommands[ASequence and 63];
end;

function TFakeQ3ServerSink.BaselineAt(ANumber: Integer): TQ3EntityState;
begin
  Result := FBaselines[ANumber];
end;

{ TFakeQ3Transport }

constructor TFakeQ3Transport.Create;
begin
  inherited Create;
  FPackets := TList<TFakeQ3Packet>.Create;
end;

destructor TFakeQ3Transport.Destroy;
begin
  FPackets.Free;
  inherited Destroy;
end;

procedure TFakeQ3Transport.SendPacket(ASource: TQ3NetSource; const AAddress: TQ3NetAddress; const AData: TBytes);
var
  LPacket: TFakeQ3Packet;
begin
  LPacket.Source := ASource;
  LPacket.Address := AAddress;
  LPacket.Data := Copy(AData);
  FPackets.Add(LPacket);
end;

procedure TFakeQ3Transport.AddPacket(ASource: TQ3NetSource; const AData: TBytes);
var
  LPacket: TFakeQ3Packet;
begin
  FillChar(LPacket.Address, SizeOf(LPacket.Address), 0);
  LPacket.Source := ASource;
  LPacket.Data := AData;
  FPackets.Add(LPacket);
end;

{ TFakeQ3Log }

constructor TFakeQ3Log.Create;
begin
  inherited Create;
  FInfos := TStringList.Create;
end;

destructor TFakeQ3Log.Destroy;
begin
  FInfos.Free;
  inherited Destroy;
end;

procedure TFakeQ3Log.Info(const AText: string);
begin
  FInfos.Add(AText);
end;

procedure TFakeQ3Log.Warning(const AText: string);
begin
  FText := FText + AText;
end;

procedure TFakeQ3Log.DevWarning(const AText: string);
begin
  FText := FText + AText;
end;

procedure TFakeQ3Log.Error(const AText: string);
begin
  FText := FText + AText;
end;

procedure TFakeQ3Log.Clear;
begin
  FText := '';
  FInfos.Clear;
end;

end.
