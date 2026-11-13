{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - reader of Creative Voice files                    }
{                                                                              }
{  Port of shl/voc.h (mv_read_memory) of war1 (acoto87/war1), MIT License,     }
{  (c) 2026 Alejandro Coto Gutierrez; war1 is under the zlib License (see      }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Audio.VocDecoder;

interface

uses
  System.SysUtils, DelphiDoom.War.Audio.Types;

type
  /// <summary>
  ///   mv_read_memory: block types 1 (8 bit voice), 8 (extended attributes), 9 (unified setup); other blocks
  ///   are skipped. The data of all the sample blocks are joined; the format is the one of the last setup
  /// </summary>
  TWarVocDecoder = class
  public
    /// <summary>False where the original returns 0 (not a VOC, bad checksum, compression, truncated, no data)</summary>
    class function TryDecode(const ASource: TBytes; out ABuffer: TWarPcmBuffer): Boolean; static;
  end;

implementation

const
  HEADER_SIZE = 26;
  SIGNATURE: array[0..19] of Byte = (
    Ord('C'), Ord('r'), Ord('e'), Ord('a'), Ord('t'), Ord('i'), Ord('v'), Ord('e'), 32, Ord('V'), Ord('o'),
    Ord('i'), Ord('c'), Ord('e'), 32, Ord('F'), Ord('i'), Ord('l'), Ord('e'), $1A);

function ReadWord(const ABytes: TBytes; AOffset: Integer): Cardinal; inline;
begin
  Result := Cardinal(ABytes[AOffset]) or (Cardinal(ABytes[AOffset + 1]) shl 8);
end;

function ReadThree(const ABytes: TBytes; AOffset: Integer): Cardinal; inline;
begin
  Result := ReadWord(ABytes, AOffset) or (Cardinal(ABytes[AOffset + 2]) shl 16);
end;

function ReadFour(const ABytes: TBytes; AOffset: Integer): Cardinal; inline;
begin
  Result := ReadWord(ABytes, AOffset) or (ReadWord(ABytes, AOffset + 2) shl 16);
end;

{ TWarVocDecoder }

class function TWarVocDecoder.TryDecode(const ASource: TBytes; out ABuffer: TWarPcmBuffer): Boolean;
var
  LPosition: Integer;
  LRemaining: Int64;
  LBlockType: Byte;
  LBlockLength: Cardinal;
  LData: TBytes;
  LAccumulated: Integer;
  LRate, LBits, LChannels: Cardinal;
  LExtended: Boolean;
  LDataLength: Integer;
  LStart: Integer;
  LIndex: Integer;
  LVersion, LCheck: Word;
  LOffset: Cardinal;
  LDivisor: Byte;
  LCode: Cardinal;

  procedure Append(AStart, ALength: Integer);
  begin
    if ALength > 0 then
    begin
      SetLength(LData, LAccumulated + ALength);
      Move(ASource[AStart], LData[LAccumulated], ALength);
    end;
    Inc(LAccumulated, ALength);
  end;

begin
  Result := False;
  ABuffer := Default(TWarPcmBuffer);
  if Length(ASource) < HEADER_SIZE then
    Exit;
  for LIndex := 0 to High(SIGNATURE) do
    if ASource[LIndex] <> SIGNATURE[LIndex] then
      Exit;
  LOffset := ReadWord(ASource, 20);
  LVersion := Word(ReadWord(ASource, 22));
  LCheck := Word(ReadWord(ASource, 24));
  if Word(Word(not LVersion) + $1234) <> LCheck then
    Exit;
  if LOffset >= Cardinal(Length(ASource)) then
    Exit;
  LPosition := Integer(LOffset);
  LRemaining := Length(ASource) - LPosition;
  LAccumulated := 0;
  // defaults of a Sound Blaster
  LRate := 11025;
  LBits := 8;
  LChannels := 1;
  LExtended := False;
  while LRemaining > 0 do
  begin
    LBlockType := ASource[LPosition];
    Inc(LPosition);
    Dec(LRemaining);
    if LBlockType = 0 then
      Break;
    if LRemaining < 3 then
      Exit;
    LBlockLength := ReadThree(ASource, LPosition);
    Inc(LPosition, 3);
    Dec(LRemaining, 3);
    if LRemaining < LBlockLength then
      Exit;
    case LBlockType of
      $01:
        begin
          if LBlockLength < 2 then
            Exit;
          LDivisor := ASource[LPosition];
          if ASource[LPosition + 1] <> 0 then
            Exit; // ADPCM is not supported
          if not LExtended then
          begin
            LRate := 1000000 div (256 - Cardinal(LDivisor));
            LBits := 8;
            LChannels := 1;
          end;
          LExtended := False;
          Append(LPosition + 2, Integer(LBlockLength) - 2);
        end;
      $08:
        begin
          if LBlockLength < 4 then
            Exit;
          LCode := ReadWord(ASource, LPosition);
          if ASource[LPosition + 2] <> 0 then
            Exit;
          if ASource[LPosition + 3] = 1 then
            LChannels := 2
          else
            LChannels := 1;
          LBits := 8;
          LRate := 256000000 div (65536 - LCode);
          if LChannels = 2 then
            LRate := LRate div 2;
          LExtended := True;
        end;
      $09:
        begin
          if LBlockLength < 12 then
            Exit;
          LStart := ReadWord(ASource, LPosition + 6);
          if (LStart <> 0) and (LStart <> 4) then
            Exit; // only raw PCM
          LRate := ReadFour(ASource, LPosition);
          LBits := ASource[LPosition + 4];
          LChannels := ASource[LPosition + 5];
          Append(LPosition + 12, Integer(LBlockLength) - 12);
        end;
    end;
    Inc(LPosition, Integer(LBlockLength));
    Dec(LRemaining, LBlockLength);
  end;
  LDataLength := LAccumulated;
  if LDataLength = 0 then
    Exit;
  ABuffer.Channels := LChannels;
  ABuffer.SampleRate := LRate;
  ABuffer.BitsPerSample := LBits;
  ABuffer.Data := LData;
  Result := True;
end;

end.
