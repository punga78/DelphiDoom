{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the palette library - the fakes                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Palette.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf, DelphiDoom.Video.Intf;

type
  /// <summary>The colors the fake matcher was asked for, in order</summary>
  TFakeMatchCall = record
    Red: Byte;
    Green: Byte;
    Blue: Byte;
    Low: Integer;
    High: Integer;
  end;

  /// <summary>Answers always the same index and remembers the questions</summary>
  TFakeColorMatcher = class(TInterfacedObject, IColorMatcher)
  strict private
    FAnswer: Byte;
    FCalls: TList<TFakeMatchCall>;
  public
    constructor Create(AAnswer: Byte);
    destructor Destroy; override;
    function BestColor(ARed, AGreen, ABlue: Byte; const APalette: TBytes;
      ALow, AHigh: Integer): Byte;
    function FindApproximateIndex(const AColors: TArray<Cardinal>; AColor: Cardinal;
      ALow, AHigh: Integer): Integer;
    property Calls: TList<TFakeMatchCall> read FCalls;
  end;

  /// <summary>Writes the sum of the three channels and keeps the gamma it was given</summary>
  TFakePaletteConverter = class(TInterfacedObject, IPaletteConverter)
  strict private
    FGamma: TBytes;
    FCallCount: Integer;
  public
    procedure Convert(ASource: PByte; AGamma: PByte; ADest: PCardinal);
    property Gamma: TBytes read FGamma;
    property CallCount: Integer read FCallCount;
  end;

implementation

{ TFakeColorMatcher }

constructor TFakeColorMatcher.Create(AAnswer: Byte);
begin
  inherited Create;
  FAnswer := AAnswer;
  FCalls := TList<TFakeMatchCall>.Create;
end;

destructor TFakeColorMatcher.Destroy;
begin
  FCalls.Free;
  inherited Destroy;
end;

function TFakeColorMatcher.BestColor(ARed, AGreen, ABlue: Byte; const APalette: TBytes;
  ALow, AHigh: Integer): Byte;
var
  LCall: TFakeMatchCall;
begin
  LCall.Red := ARed;
  LCall.Green := AGreen;
  LCall.Blue := ABlue;
  LCall.Low := ALow;
  LCall.High := AHigh;
  FCalls.Add(LCall);
  Result := FAnswer;
end;

function TFakeColorMatcher.FindApproximateIndex(const AColors: TArray<Cardinal>;
  AColor: Cardinal; ALow, AHigh: Integer): Integer;
begin
  Result := ALow;
end;

{ TFakePaletteConverter }

procedure TFakePaletteConverter.Convert(ASource: PByte; AGamma: PByte; ADest: PCardinal);
var
  LIndex: Integer;
begin
  Inc(FCallCount);
  SetLength(FGamma, 256);
  Move(AGamma^, FGamma[0], 256);
  for LIndex := 0 to PALETTE_COLOR_COUNT - 1 do
  begin
    ADest^ := Cardinal(ASource^);
    Inc(ASource);
    ADest^ := ADest^ + ASource^;
    Inc(ASource);
    ADest^ := ADest^ + ASource^;
    Inc(ASource);
    Inc(ADest);
  end;
end;

end.
