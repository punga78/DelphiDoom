{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture definitions library - names of 8 characters             }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TextureDefs.Names;

interface

uses
  System.SysUtils;

type
  /// <summary>The names of the lumps: bytes, not text. Upper case is ASCII only, like the old toupper</summary>
  TTextureDefsNames = class
  public
    /// <summary>
    ///   Up to 8 bytes from AOffset, to the first byte that is 0, upper case. The bytes are
    ///   characters of 8 bits: they are not decoded
    /// </summary>
    class function Decode(const ABuffer: TBytes; AOffset: Integer): string; static;
    class function UpperAscii(const AText: string): string; static;
    /// <summary>Cuts the characters that are not above the space, at both ends (the old strtrim)</summary>
    class function Trim(const AText: string): string; static;
  end;

implementation

{ TTextureDefsNames }

class function TTextureDefsNames.Decode(const ABuffer: TBytes; AOffset: Integer): string;
var
  LIndex: Integer;
  LByte: Byte;
begin
  Result := '';
  for LIndex := 0 to 7 do
  begin
    LByte := ABuffer[AOffset + LIndex];
    if LByte = 0 then
      Break;
    if (LByte >= Ord('a')) and (LByte <= Ord('z')) then
      Dec(LByte, Ord('a') - Ord('A'));
    Result := Result + Char(LByte);
  end;
end;

class function TTextureDefsNames.UpperAscii(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := AText;
  for LIndex := 1 to Length(Result) do
    if (Result[LIndex] >= 'a') and (Result[LIndex] <= 'z') then
      Result[LIndex] := Char(Ord(Result[LIndex]) - (Ord('a') - Ord('A')));
end;

class function TTextureDefsNames.Trim(const AText: string): string;
var
  LFirst: Integer;
  LLast: Integer;
begin
  LFirst := 1;
  LLast := Length(AText);
  while (LFirst <= LLast) and (AText[LFirst] <= ' ') do
    Inc(LFirst);
  while (LLast >= LFirst) and (AText[LLast] <= ' ') do
    Dec(LLast);
  Result := Copy(AText, LFirst, LLast - LFirst + 1);
end;

end.
