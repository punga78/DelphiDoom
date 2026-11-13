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
  DelphiDoom.Net.Q3.Intf;

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

implementation

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
