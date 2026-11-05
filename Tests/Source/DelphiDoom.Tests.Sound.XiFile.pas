{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound decoder - builds XI files in memory          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sound.XiFile;

interface

uses
  System.SysUtils;

type
  TSoundTestXiFile = class
  public
    /// <summary>
    ///   An instrument of ASampleCount samples whose first has ASizes[0] bytes
    ///   and is 16 bit when ASixteen; AData is what follows the headers
    /// </summary>
    class function Build(ASixteen: Boolean; ASampleCount: Integer;
      const ASizes: array of Integer; const AData: TBytes;
      ASignatureByte: Byte = Ord(':'); ANameEnd: Byte = $1A): TBytes; static;
  end;

implementation

{ TSoundTestXiFile }

class function TSoundTestXiFile.Build(ASixteen: Boolean; ASampleCount: Integer;
  const ASizes: array of Integer; const AData: TBytes; ASignatureByte,
  ANameEnd: Byte): TBytes;
const
  SIGNATURE: AnsiString = 'Extended Instrument:';
var
  LHeader: TBytes;
  LIndex, LOffset, LSize: Integer;
  LCount: Integer;
begin
  LCount := ASampleCount;
  if LCount < 0 then
    LCount := 0;
  SetLength(LHeader, 298 + 40 * LCount);
  for LIndex := 1 to Length(SIGNATURE) do
    LHeader[LIndex - 1] := Ord(SIGNATURE[LIndex]);
  LHeader[19] := ASignatureByte;
  LHeader[20] := Ord(' ');
  for LIndex := 21 to 42 do
    LHeader[LIndex] := Ord('A') + (LIndex mod 20);
  LHeader[43] := ANameEnd;
  LHeader[64] := 2;
  LHeader[65] := 1;
  LHeader[296] := Byte(ASampleCount);
  LHeader[297] := Byte(ASampleCount shr 8);
  for LIndex := 0 to LCount - 1 do
  begin
    LOffset := 298 + 40 * LIndex;
    if LIndex <= High(ASizes) then
      LSize := ASizes[LIndex]
    else
      LSize := 0;
    LHeader[LOffset] := Byte(LSize);
    LHeader[LOffset + 1] := Byte(LSize shr 8);
    LHeader[LOffset + 2] := Byte(LSize shr 16);
    LHeader[LOffset + 3] := Byte(LSize shr 24);
    // volume, fine tune, flags (16 bit is 16), pan, note
    LHeader[LOffset + 12] := 64;
    if ASixteen then
      LHeader[LOffset + 14] := 16;
    LHeader[LOffset + 15] := 128;
  end;
  SetLength(Result, Length(LHeader) + Length(AData));
  Move(LHeader[0], Result[0], Length(LHeader));
  if Length(AData) > 0 then
    Move(AData[0], Result[Length(LHeader)], Length(AData));
end;

end.
