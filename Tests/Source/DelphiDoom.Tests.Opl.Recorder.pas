{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OPL library - a chip that records its writes        }
{                                                                              }
{  Derived from fmopl.c (MAME 0.37a fork for OpenXcom, LGPL 2.1 or later) and   }
{  OpenXcom (GPL v3 or later): see Libs\Opl\README.md                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Opl.Recorder;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Opl.Intf;

type
  /// <summary>
  ///   An IOplChip that forwards to a real chip and keeps what is written to it: a list of (port, value) pairs and an
  ///   FNV-1a 64 bit hash of them (chip number, port and value as bytes, the hash the C harness makes)
  /// </summary>
  TOplRecorderChip = class(TInterfacedObject, IOplChip)
  strict private
    FChip: IOplChip;
    FNumber: Integer;
    FHash: PUInt64;
    FWrites: TList<TPair<Integer, Integer>>;
    procedure Feed(AByte: Integer);
  public
    /// <param name="AHash">The hash that all the chips of a test feed (owned by the caller)</param>
    constructor Create(const AChip: IOplChip; ANumber: Integer; AHash: PUInt64);
    destructor Destroy; override;
    procedure Reset;
    function Write(APort: Integer; AValue: Integer): Integer;
    procedure WriteRegister(ARegister: Byte; AValue: Byte);
    function Read(APort: Integer): Byte;
    function TimerOver(ATimer: Integer): Integer;
    procedure GenerateSamples(const ABuffer: TArray<SmallInt>; ACount: Integer); overload;
    procedure GenerateSamples(const ABuffer: TArray<SmallInt>; AOffset, ALength, AStripe: Integer;
      AVolume: Single); overload;
    procedure SetListener(const AListener: IOplChipListener; ATimerChannelOffset, AIrqParam, AUpdateParam: Integer);
    function GetLegacyLfoCache: Boolean;
    procedure SetLegacyLfoCache(AValue: Boolean);
    property Writes: TList<TPair<Integer, Integer>> read FWrites;
  end;

implementation

{$Q-}
{$R-}

{ TOplRecorderChip }

constructor TOplRecorderChip.Create(const AChip: IOplChip; ANumber: Integer; AHash: PUInt64);
begin
  inherited Create;
  FChip := AChip;
  FNumber := ANumber;
  FHash := AHash;
  FWrites := TList<TPair<Integer, Integer>>.Create;
end;

destructor TOplRecorderChip.Destroy;
begin
  FWrites.Free;
  inherited Destroy;
end;

procedure TOplRecorderChip.Feed(AByte: Integer);
begin
  if Assigned(FHash) then
  begin
    FHash^ := FHash^ xor UInt64(AByte and $FF);
    FHash^ := FHash^ * UInt64($100000001B3);
  end;
end;

procedure TOplRecorderChip.Reset;
begin
  FChip.Reset;
end;

function TOplRecorderChip.Write(APort: Integer; AValue: Integer): Integer;
begin
  Feed(FNumber);
  Feed(APort and 1);
  Feed(AValue);
  FWrites.Add(TPair<Integer, Integer>.Create(APort and 1, AValue));
  Result := FChip.Write(APort, AValue);
end;

procedure TOplRecorderChip.WriteRegister(ARegister: Byte; AValue: Byte);
begin
  Write(0, ARegister);
  Write(1, AValue);
end;

function TOplRecorderChip.Read(APort: Integer): Byte;
begin
  Result := FChip.Read(APort);
end;

function TOplRecorderChip.TimerOver(ATimer: Integer): Integer;
begin
  Result := FChip.TimerOver(ATimer);
end;

procedure TOplRecorderChip.GenerateSamples(const ABuffer: TArray<SmallInt>; ACount: Integer);
begin
  FChip.GenerateSamples(ABuffer, ACount);
end;

procedure TOplRecorderChip.GenerateSamples(const ABuffer: TArray<SmallInt>; AOffset, ALength, AStripe: Integer;
  AVolume: Single);
begin
  FChip.GenerateSamples(ABuffer, AOffset, ALength, AStripe, AVolume);
end;

procedure TOplRecorderChip.SetListener(const AListener: IOplChipListener; ATimerChannelOffset, AIrqParam,
  AUpdateParam: Integer);
begin
  FChip.SetListener(AListener, ATimerChannelOffset, AIrqParam, AUpdateParam);
end;

function TOplRecorderChip.GetLegacyLfoCache: Boolean;
begin
  Result := FChip.LegacyLfoCache;
end;

procedure TOplRecorderChip.SetLegacyLfoCache(AValue: Boolean);
begin
  FChip.LegacyLfoCache := AValue;
end;

end.
