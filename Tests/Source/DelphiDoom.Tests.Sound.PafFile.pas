{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound decoder - builds PARIS files in memory       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sound.PafFile;

interface

uses
  System.SysUtils;

type
  TSoundTestPafFile = class
  public
    /// <summary>
    ///   AFormat is 0 for 16 bit, 1 for 24 bit, 2 for 8 bit. The numbers of the
    ///   header and the samples are little endian or big endian as ALittle says
    /// </summary>
    class function Build(ALittle: Boolean; AFormat, AChannels, ASampleRate: Integer;
      const AData: TBytes; AVersion: Integer = 0): TBytes; static;
  end;

implementation

{ TSoundTestPafFile }

class function TSoundTestPafFile.Build(ALittle: Boolean; AFormat, AChannels,
  ASampleRate: Integer; const AData: TBytes; AVersion: Integer): TBytes;
const
  HEADER_LENGTH = 2048;
var
  LFields: array[0..5] of Cardinal;
  LIndex: Integer;
  LMarker: AnsiString;
begin
  SetLength(Result, HEADER_LENGTH + Length(AData));
  if ALittle then
    LMarker := 'fap '
  else
    LMarker := ' paf';
  for LIndex := 1 to 4 do
    Result[LIndex - 1] := Ord(LMarker[LIndex]);

  LFields[0] := Cardinal(AVersion);
  LFields[1] := Ord(ALittle);
  LFields[2] := Cardinal(ASampleRate);
  LFields[3] := Cardinal(AFormat);
  LFields[4] := Cardinal(AChannels);
  LFields[5] := 0;
  for LIndex := 0 to 5 do
    if ALittle then
    begin
      Result[4 + LIndex * 4] := Byte(LFields[LIndex]);
      Result[5 + LIndex * 4] := Byte(LFields[LIndex] shr 8);
      Result[6 + LIndex * 4] := Byte(LFields[LIndex] shr 16);
      Result[7 + LIndex * 4] := Byte(LFields[LIndex] shr 24);
    end
    else
    begin
      Result[7 + LIndex * 4] := Byte(LFields[LIndex]);
      Result[6 + LIndex * 4] := Byte(LFields[LIndex] shr 8);
      Result[5 + LIndex * 4] := Byte(LFields[LIndex] shr 16);
      Result[4 + LIndex * 4] := Byte(LFields[LIndex] shr 24);
    end;
  if Length(AData) > 0 then
    Move(AData[0], Result[HEADER_LENGTH], Length(AData));
end;

end.
