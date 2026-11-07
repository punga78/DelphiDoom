{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the automap library - the fingerprint of a series      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.Fingerprint;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   A 64 bit fingerprint (FNV-1a) of a series of numbers: the golden file keeps one for each
  ///   scenario instead of thousands of results. The same unit is used by the temporary harness
  ///   that produced the golden file from the old code, so the two sides count the same way.
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
    procedure AddBoolean(const AValue: Boolean);
    /// <summary>A call that raised an exception instead of giving a result</summary>
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

procedure TFingerprint.AddBoolean(const AValue: Boolean);
begin
  if AValue then
    AddInt64(1)
  else
    AddInt64(0);
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
