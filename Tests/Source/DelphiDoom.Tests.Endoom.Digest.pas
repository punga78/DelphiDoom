{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the endoom library - fingerprint of a picture           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Endoom.Digest;

{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

uses
  System.SysUtils;

type
  /// <summary>FNV-1a on 64 bits: a short value for a picture (the same code writes and checks the golden files)</summary>
  TEndoomDigest = class
  public
    class function OfBytes(const AValue: TBytes): string; static;
    class function OfCardinals(const AValue: TArray<Cardinal>): string; static;
  end;

implementation

{ TEndoomDigest }

class function TEndoomDigest.OfBytes(const AValue: TBytes): string;
var
  LHash: UInt64;
  LIndex: Integer;
begin
  LHash := UInt64($CBF29CE484222325);
  for LIndex := 0 to High(AValue) do
    LHash := (LHash xor AValue[LIndex]) * UInt64($100000001B3);
  Result := Format('%s:%d', [IntToHex(LHash, 16), Length(AValue)]);
end;

class function TEndoomDigest.OfCardinals(const AValue: TArray<Cardinal>): string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, Length(AValue) * SizeOf(Cardinal));
  if Length(AValue) > 0 then
    Move(AValue[0], LBytes[0], Length(LBytes));
  Result := OfBytes(LBytes);
end;

end.
