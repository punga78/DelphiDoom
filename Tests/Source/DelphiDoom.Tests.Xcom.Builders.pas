{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - small helpers                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.Builders;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Image;

type
  TXcomTestBuilders = class
  public
    /// <summary>An array of bytes from the values</summary>
    class function Bytes(const AValues: array of Byte): TBytes; static;
    /// <summary>The pixels of an image as a text, "00 01 FF", to compare them in a test</summary>
    class function Pixels(const AImage: TXcomImage): string; static;
    /// <summary>A little endian 32 bit number as 4 bytes at the end of ABytes</summary>
    class procedure AddCardinal(var ABytes: TBytes; AValue: Cardinal); static;
    class procedure AddByte(var ABytes: TBytes; AValue: Byte); static;
    /// <summary>ACount bytes of zero (SetLength does not clear a new array)</summary>
    class function Zeros(ACount: Integer): TBytes; static;
  end;

implementation

{ TXcomTestBuilders }

class function TXcomTestBuilders.Bytes(const AValues: array of Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AValues));
  for LIndex := 0 to High(AValues) do
    Result[LIndex] := AValues[LIndex];
end;

class function TXcomTestBuilders.Pixels(const AImage: TXcomImage): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(AImage.Pixels) do
  begin
    if LIndex > 0 then
      Result := Result + ' ';
    Result := Result + IntToHex(AImage.Pixels[LIndex], 2);
  end;
end;

class function TXcomTestBuilders.Zeros(ACount: Integer): TBytes;
begin
  SetLength(Result, ACount);
  if ACount > 0 then
    FillChar(Result[0], ACount, 0);
end;

class procedure TXcomTestBuilders.AddByte(var ABytes: TBytes; AValue: Byte);
begin
  SetLength(ABytes, Length(ABytes) + 1);
  ABytes[High(ABytes)] := AValue;
end;

class procedure TXcomTestBuilders.AddCardinal(var ABytes: TBytes; AValue: Cardinal);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    AddByte(ABytes, Byte(AValue shr (8 * LIndex)));
end;

end.
