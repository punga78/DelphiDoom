{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the CRC-32 checksum                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Crc32;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The CRC-32 (the one of zip and PNG) of the old m_crc32, on a buffer or a series of
  ///   buffers. It does not read files or lumps: who has the bytes gives them.
  /// </summary>
  TCrc32 = class
  private
    FState: Cardinal;
    function GetValue: Cardinal;
  public
    constructor Create;
    procedure Reset;
    procedure Update(const ABuffer; const ASize: Integer);
    /// <summary>The checksum of the bytes given so far</summary>
    property Value: Cardinal read GetValue;
    /// <summary>The checksum of a buffer</summary>
    class function Calculate(const ABuffer; const ASize: Integer): Cardinal; static;
    /// <summary>The checksum as 8 hexadecimal digits in lower case, as the old GetCRC32 gave it</summary>
    class function ToHex(const AValue: Cardinal): string; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.TableCrc32;

{ TCrc32 }

constructor TCrc32.Create;
begin
  inherited Create;
  Reset;
end;

procedure TCrc32.Reset;
begin
  FState := $FFFFFFFF;
end;

procedure TCrc32.Update(const ABuffer; const ASize: Integer);
var
  LBytes: PByte;
  LIndex: Integer;
begin
  LBytes := @ABuffer;
  for LIndex := 0 to ASize - 1 do
  begin
    FState := CRC32_TABLE[Byte(FState xor Cardinal(LBytes^))] xor ((FState shr 8) and $00FFFFFF);
    Inc(LBytes);
  end;
end;

function TCrc32.GetValue: Cardinal;
begin
  Result := not FState;
end;

class function TCrc32.Calculate(const ABuffer; const ASize: Integer): Cardinal;
var
  LCrc: TCrc32;
begin
  LCrc := TCrc32.Create;
  try
    LCrc.Update(ABuffer, ASize);
    Result := LCrc.Value;
  finally
    LCrc.Free;
  end;
end;

class function TCrc32.ToHex(const AValue: Cardinal): string;
begin
  Result := LowerCase(IntToHex(AValue, 8));
end;

end.
