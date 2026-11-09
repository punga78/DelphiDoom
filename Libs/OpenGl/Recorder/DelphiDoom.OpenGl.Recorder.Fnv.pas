{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL call recorder - FNV-1a, 64 bit                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.OpenGl.Recorder.Fnv;

// The multiplication of the hash wraps on purpose.
{$Q-}
{$R-}

interface

type
  /// <summary>The 64 bit FNV-1a hash used for the sums of the stream of calls</summary>
  TGlFnv = record
  public
    const
      OFFSET_BASIS: UInt64 = $CBF29CE484222325;
      PRIME: UInt64 = $00000100000001B3;
    /// <summary>The hash of no bytes</summary>
    class function Start: UInt64; static;
    /// <summary>Adds ASize bytes at AData to the hash</summary>
    class function UpdateBuffer(const AHash: UInt64; const AData: Pointer; const ASize: NativeInt): UInt64; static;
    /// <summary>Adds the characters of the text, one byte each (the text is ASCII)</summary>
    class function UpdateText(const AHash: UInt64; const AText: string): UInt64; static;
    /// <summary>The hash as 16 lowercase hexadecimal digits</summary>
    class function ToHex(const AHash: UInt64): string; static;
  end;

implementation

uses
  System.SysUtils;

{ TGlFnv }

class function TGlFnv.Start: UInt64;
begin
  Result := OFFSET_BASIS;
end;

class function TGlFnv.UpdateBuffer(const AHash: UInt64; const AData: Pointer; const ASize: NativeInt): UInt64;
var
  LByte: PByte;
  LIndex: NativeInt;
begin
  Result := AHash;
  LByte := PByte(AData);
  for LIndex := 0 to ASize - 1 do
  begin
    Result := (Result xor LByte^) * PRIME;
    Inc(LByte);
  end;
end;

class function TGlFnv.UpdateText(const AHash: UInt64; const AText: string): UInt64;
var
  LIndex: Integer;
begin
  Result := AHash;
  for LIndex := 1 to Length(AText) do
    Result := (Result xor (Ord(AText[LIndex]) and $FF)) * PRIME;
end;

class function TGlFnv.ToHex(const AHash: UInt64): string;
begin
  Result := LowerCase(IntToHex(AHash, 16));
end;

end.
