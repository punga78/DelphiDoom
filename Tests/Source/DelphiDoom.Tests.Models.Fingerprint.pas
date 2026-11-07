{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the fingerprint of a series    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Fingerprint;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   A 64 bit fingerprint (FNV-1a) of a series of numbers: the golden files keep one for each
  ///   function instead of thousands of results. The same unit is used by the temporary harness
  ///   that produced the golden files from the old code, so the two sides count the same way.
  /// </summary>
  TFingerprint = class
  private
    FHash: UInt64;
    FCount: Integer;
    procedure AddByte(const AValue: Byte);
  public
    constructor Create;
    procedure AddInt64(const AValue: Int64);
    procedure AddInteger(const AValue: Integer);
    procedure AddCardinal(const AValue: Cardinal);
    /// <summary>The bits of the number</summary>
    procedure AddSingle(const AValue: Single);
    procedure AddDouble(const AValue: Double);
    procedure AddExtended(const AValue: Extended);
    procedure AddBoolean(const AValue: Boolean);
    procedure AddText(const AValue: string);
    /// <summary>A function that raised an exception instead of giving a number</summary>
    procedure AddException;
    function ToHex: string;
    property Count: Integer read FCount;
  end;

implementation

uses
  System.SysUtils;

{ TFingerprint }

constructor TFingerprint.Create;
begin
  inherited Create;
  FHash := $CBF29CE484222325;
end;

procedure TFingerprint.AddByte(const AValue: Byte);
begin
  FHash := (FHash xor AValue) * UInt64($100000001B3);
end;

procedure TFingerprint.AddInt64(const AValue: Int64);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    AddByte(Byte(AValue shr (8 * LIndex)));
  Inc(FCount);
end;

procedure TFingerprint.AddInteger(const AValue: Integer);
begin
  AddInt64(AValue);
end;

procedure TFingerprint.AddCardinal(const AValue: Cardinal);
begin
  AddInt64(AValue);
end;

procedure TFingerprint.AddSingle(const AValue: Single);
var
  LBits: Integer;
begin
  Move(AValue, LBits, SizeOf(LBits));
  AddInt64(LBits);
end;

procedure TFingerprint.AddDouble(const AValue: Double);
var
  LBits: Int64;
begin
  Move(AValue, LBits, SizeOf(LBits));
  AddInt64(LBits);
end;

procedure TFingerprint.AddExtended(const AValue: Extended);
var
  LAsDouble: Double;
  LBits: Int64;
begin
  // the value as a double: the Extended of 64 bit is a Double, and at 32 bit the numbers of
  // these tests (a 32 bit integer over 65536) are the same as a double
  LAsDouble := AValue;
  Move(LAsDouble, LBits, SizeOf(LBits));
  AddInt64(LBits);
end;

procedure TFingerprint.AddBoolean(const AValue: Boolean);
begin
  if AValue then
    AddInt64(1)
  else
    AddInt64(0);
end;

procedure TFingerprint.AddText(const AValue: string);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AValue) do
    AddInt64(Ord(AValue[LIndex]));
  AddInt64(-1);
end;

procedure TFingerprint.AddException;
begin
  AddInt64($4EADBEEF00000001);
end;

function TFingerprint.ToHex: string;
begin
  Result := IntToHex(Int64(FHash), 16) + '/' + IntToStr(FCount);
end;

end.
