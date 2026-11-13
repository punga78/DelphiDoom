{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - a minimal PNG writer for looking at  }
{  the decoded images (the RGBA pixels as they are, no filter)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.PngWriter;

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>Writes an 8 bit RGBA image to a PNG file; only the tests use it, to look at what was decoded</summary>
  TWarPngWriter = class
  strict private
    class procedure WriteChunk(AStream: TStream; const AType: AnsiString; const AData: TBytes); static;
    class function BigEndian(AValue: Cardinal): TBytes; static;
  public
    class procedure Save(const APath: string; AWidth, AHeight: Integer; const ARgba: TBytes); static;
  end;

implementation

uses
  System.ZLib, DelphiDoom.MathCore.Crc32;

{ TWarPngWriter }

class function TWarPngWriter.BigEndian(AValue: Cardinal): TBytes;
begin
  Result := TBytes.Create(Byte(AValue shr 24), Byte(AValue shr 16), Byte(AValue shr 8), Byte(AValue));
end;

class procedure TWarPngWriter.WriteChunk(AStream: TStream; const AType: AnsiString; const AData: TBytes);
var
  LCrc: TCrc32;
  LLength: TBytes;
  LTypeBytes: TBytes;
  LCrcBytes: TBytes;
  LIndex: Integer;
begin
  LLength := BigEndian(Length(AData));
  AStream.WriteBuffer(LLength[0], 4);
  SetLength(LTypeBytes, 4);
  for LIndex := 0 to 3 do
    LTypeBytes[LIndex] := Byte(AType[LIndex + 1]);
  AStream.WriteBuffer(LTypeBytes[0], 4);
  LCrc := TCrc32.Create;
  try
    LCrc.Update(LTypeBytes[0], 4);
    if Length(AData) > 0 then
    begin
      AStream.WriteBuffer(AData[0], Length(AData));
      LCrc.Update(AData[0], Length(AData));
    end;
    LCrcBytes := BigEndian(LCrc.Value);
  finally
    LCrc.Free;
  end;
  AStream.WriteBuffer(LCrcBytes[0], 4);
end;

class procedure TWarPngWriter.Save(const APath: string; AWidth, AHeight: Integer; const ARgba: TBytes);
const
  SIGNATURE: array[0..7] of Byte = (137, 80, 78, 71, 13, 10, 26, 10);
var
  LStream: TFileStream;
  LHeader: TBytes;
  LRaw: TBytes;
  LRow: Integer;
  LPacked: Pointer;
  LPackedSize: Integer;
  LData: TBytes;
begin
  // every row starts with the filter byte 0
  SetLength(LRaw, AHeight * (1 + AWidth * 4));
  for LRow := 0 to AHeight - 1 do
    Move(ARgba[LRow * AWidth * 4], LRaw[LRow * (1 + AWidth * 4) + 1], AWidth * 4);
  ZCompress(@LRaw[0], Length(LRaw), LPacked, LPackedSize);
  try
    SetLength(LData, LPackedSize);
    Move(LPacked^, LData[0], LPackedSize);
  finally
    FreeMem(LPacked);
  end;
  LHeader := BigEndian(AWidth) + BigEndian(AHeight) + TBytes.Create(8, 6, 0, 0, 0);
  LStream := TFileStream.Create(APath, fmCreate);
  try
    LStream.WriteBuffer(SIGNATURE[0], 8);
    WriteChunk(LStream, 'IHDR', LHeader);
    WriteChunk(LStream, 'IDAT', LData);
    WriteChunk(LStream, 'IEND', nil);
  finally
    LStream.Free;
  end;
end;

end.
