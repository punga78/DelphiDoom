{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound decoder - builds SDS files in memory         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sound.SdsFile;

interface

uses
  System.SysUtils;

type
  TSoundTestSdsFile = class
  public
    /// <summary>
    ///   A header of AFrames samples of ABitWidth bits and ABlocks packets of
    ///   127 bytes; the audio bytes of the packets are seven bit numbers made
    ///   from ASeed. APeriod is the sample period in nanoseconds
    /// </summary>
    class function Build(ABitWidth, APeriod, AFrames, ABlocks: Integer;
      ASeed: Cardinal): TBytes; static;
  end;

implementation

function Encode3Bytes(AValue: Cardinal): Cardinal;
begin
  Result := (AValue and $7F) or ((AValue shl 1) and $7F00) or ((AValue shl 2) and $7F0000);
end;

{ TSoundTestSdsFile }

class function TSoundTestSdsFile.Build(ABitWidth, APeriod, AFrames,
  ABlocks: Integer; ASeed: Cardinal): TBytes;
const
  HEADER_SIZE = 21;
  BLOCK_SIZE = 127;
var
  LValue: Cardinal;
  LBlock, LIndex, LOffset, LChecksum: Integer;
  LSeed: Cardinal;

  procedure Put3(AOffset: Integer; AValue: Cardinal);
  begin
    Result[AOffset] := Byte(AValue);
    Result[AOffset + 1] := Byte(AValue shr 8);
    Result[AOffset + 2] := Byte(AValue shr 16);
  end;

begin
  SetLength(Result, HEADER_SIZE + ABlocks * BLOCK_SIZE);
  Result[0] := $F0;
  Result[1] := $7E;
  Result[2] := 0;
  Result[3] := 1;
  Result[4] := 5;
  Result[5] := 0;
  Result[6] := Byte(ABitWidth);
  Put3(7, Encode3Bytes(APeriod));
  LValue := Encode3Bytes(AFrames);
  Put3(10, LValue);
  Put3(13, 0);
  Put3(16, 0);
  Result[19] := 0;
  Result[20] := $F7;

  LSeed := ASeed;
  for LBlock := 0 to ABlocks - 1 do
  begin
    LOffset := HEADER_SIZE + LBlock * BLOCK_SIZE;
    Result[LOffset] := $F0;
    Result[LOffset + 1] := $7E;
    Result[LOffset + 2] := 0;
    Result[LOffset + 3] := Byte(LBlock + 1);
    Result[LOffset + 4] := Byte(LBlock and $7F);
    for LIndex := 5 to 124 do
    begin
      LSeed := LSeed * 1664525 + 1013904223;
      Result[LOffset + LIndex] := Byte((LSeed shr 16) and $7F);
    end;
    LChecksum := Result[LOffset + 1];
    for LIndex := 2 to BLOCK_SIZE - 3 do
      LChecksum := LChecksum xor Result[LOffset + LIndex];
    Result[LOffset + 125] := Byte(LChecksum and $7F);
    Result[LOffset + 126] := $F7;
  end;
end;

end.
