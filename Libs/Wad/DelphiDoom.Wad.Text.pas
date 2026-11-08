{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - the text of a lump                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Text;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The bytes of a lump read as text (scripts, MAPINFO, DECORATE...): one character per
  ///   byte, a #0 becomes a space. It is what W_TextLumpNum of the engine always did
  /// </summary>
  TWadLumpText = class
  public
    /// <summary>AByteCount characters; a null pointer or a count of 0 or less gives an empty string</summary>
    class function FromBuffer(const ABuffer: Pointer; AByteCount: Integer): string; overload; static;
    /// <summary>One character for every byte of ABytes</summary>
    class function FromBuffer(const ABytes: TBytes): string; overload; static;
  end;

implementation

{ TWadLumpText }

class function TWadLumpText.FromBuffer(const ABuffer: Pointer; AByteCount: Integer): string;
var
  LIndex: Integer;
  LByte: Byte;
begin
  Result := '';
  if (not Assigned(ABuffer)) or (AByteCount <= 0) then
    Exit;
  SetLength(Result, AByteCount);
  for LIndex := 0 to AByteCount - 1 do
  begin
    LByte := PByte(ABuffer)[LIndex];
    if LByte <> 0 then
      Result[LIndex + 1] := Char(LByte)
    else
      Result[LIndex + 1] := ' ';
  end;
end;

class function TWadLumpText.FromBuffer(const ABytes: TBytes): string;
begin
  if Length(ABytes) = 0 then
    Result := ''
  else
    Result := FromBuffer(@ABytes[0], Length(ABytes));
end;

end.
