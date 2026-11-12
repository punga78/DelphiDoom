{******************************************************************************}
{                                                                              }
{  DelphiDoom: common code of the test suites - the FNV-1a fingerprint          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Shared.Fnv;

// the fingerprint is a product that wraps around: no overflow checks
{$Q-}
{$R-}

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   FNV-1a at 32 and 64 bit, the fingerprint the golden files of the suites are written with (the harnesses of
  ///   the original programs compute the same): xor with the byte, then multiply by the prime
  /// </summary>
  TTestFnv = class
  public
    const
      OFFSET_32 = Cardinal($811C9DC5);
      PRIME_32 = Cardinal(16777619);
      OFFSET_64 = UInt64($CBF29CE484222325);
      PRIME_64 = UInt64($100000001B3);
    /// <summary>Adds ASize bytes to a 32 bit fingerprint that was started with OFFSET_32</summary>
    class procedure Mix32(var AHash: Cardinal; AData: Pointer; ASize: Integer); static;
    class function Hash32(AData: Pointer; ASize: Integer): Cardinal; overload; static;
    class function Hash32(const ABytes: TBytes): Cardinal; overload; static;
    /// <summary>Adds ASize bytes to a 64 bit fingerprint that was started with OFFSET_64</summary>
    class procedure Mix64(var AHash: UInt64; AData: Pointer; ASize: Integer); static;
    class function Hash64(AData: Pointer; ASize: Integer): UInt64; overload; static;
    class function Hash64(const ABytes: TBytes): UInt64; overload; static;
    /// <summary>The fingerprint of the first ACount bytes</summary>
    class function Hash64(const ABytes: TBytes; ACount: Integer): UInt64; overload; static;
  end;

implementation

class procedure TTestFnv.Mix32(var AHash: Cardinal; AData: Pointer; ASize: Integer);
var
  LByte: PByte;
  LIndex: Integer;
begin
  LByte := AData;
  for LIndex := 0 to ASize - 1 do
  begin
    AHash := (AHash xor LByte^) * PRIME_32;
    Inc(LByte);
  end;
end;

class function TTestFnv.Hash32(AData: Pointer; ASize: Integer): Cardinal;
begin
  Result := OFFSET_32;
  Mix32(Result, AData, ASize);
end;

class function TTestFnv.Hash32(const ABytes: TBytes): Cardinal;
begin
  Result := Hash32(Pointer(ABytes), Length(ABytes));
end;

class procedure TTestFnv.Mix64(var AHash: UInt64; AData: Pointer; ASize: Integer);
var
  LByte: PByte;
  LIndex: Integer;
begin
  LByte := AData;
  for LIndex := 0 to ASize - 1 do
  begin
    AHash := (AHash xor UInt64(LByte^)) * PRIME_64;
    Inc(LByte);
  end;
end;

class function TTestFnv.Hash64(AData: Pointer; ASize: Integer): UInt64;
begin
  Result := OFFSET_64;
  Mix64(Result, AData, ASize);
end;

class function TTestFnv.Hash64(const ABytes: TBytes): UInt64;
begin
  Result := Hash64(Pointer(ABytes), Length(ABytes));
end;

class function TTestFnv.Hash64(const ABytes: TBytes; ACount: Integer): UInt64;
begin
  Result := Hash64(Pointer(ABytes), ACount);
end;

end.
