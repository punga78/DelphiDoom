{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound decoder - fingerprint of what a sound gives  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sound.Digest;

interface

type
  /// <summary>
  ///   FNV-1a (64 bit) over the numbers and the buffers a test observes; two
  ///   runs that see the same things give the same value
  /// </summary>
  TSoundDigest = record
  private
    FValue: UInt64;
  public
    class function Start: TSoundDigest; static;
    procedure AddInt64(AValue: Int64);
    procedure AddBuffer(ABuffer: Pointer; ASize: Integer);
    property Value: UInt64 read FValue;
  end;

implementation

const
  FNV_OFFSET = UInt64($CBF29CE484222325);
  FNV_PRIME = UInt64($00000100000001B3);

{ TSoundDigest }

class function TSoundDigest.Start: TSoundDigest;
begin
  Result.FValue := FNV_OFFSET;
end;

procedure TSoundDigest.AddBuffer(ABuffer: Pointer; ASize: Integer);
var
  LBytes: PByte;
  LIndex: Integer;
begin
  LBytes := ABuffer;
  for LIndex := 0 to ASize - 1 do
  begin
    FValue := (FValue xor LBytes^) * FNV_PRIME;
    Inc(LBytes);
  end;
end;

procedure TSoundDigest.AddInt64(AValue: Int64);
begin
  AddBuffer(@AValue, SizeOf(AValue));
end;

end.
