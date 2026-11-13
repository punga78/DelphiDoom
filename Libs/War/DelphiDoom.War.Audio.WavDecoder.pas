{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - reader of WAV files                               }
{                                                                              }
{  Port of shl/wav.h (mw_read_memory) of war1 (acoto87/war1), MIT License,     }
{  (c) 2026 Alejandro Coto Gutierrez; war1 is under the zlib License (see      }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Audio.WavDecoder;

interface

uses
  System.SysUtils, DelphiDoom.War.Audio.Types;

type
  /// <summary>
  ///   mw_read_memory: a 44 byte canonical header (RIFF, WAVE, "fmt ") whose format fields are taken from fixed
  ///   offsets, then the chunks are skipped from the end of the "fmt " chunk until "data". The format is not
  ///   checked (any audio_format is taken as PCM)
  /// </summary>
  TWarWavDecoder = class
  public
    /// <summary>False where the original returns 0</summary>
    class function TryDecode(const ASource: TBytes; out ABuffer: TWarPcmBuffer): Boolean; static;
  end;

implementation

const
  HEADER_SIZE = 44;

function ReadWord(const ABytes: TBytes; AOffset: Int64): Cardinal; inline;
begin
  Result := Cardinal(ABytes[AOffset]) or (Cardinal(ABytes[AOffset + 1]) shl 8);
end;

function ReadFour(const ABytes: TBytes; AOffset: Int64): Cardinal; inline;
begin
  Result := ReadWord(ABytes, AOffset) or (ReadWord(ABytes, AOffset + 2) shl 16);
end;

function HasMarker(const ABytes: TBytes; AOffset: Integer; const AMarker: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 1 to 4 do
    if ABytes[AOffset + LIndex - 1] <> Ord(AMarker[LIndex]) then
      Exit(False);
end;

{ TWarWavDecoder }

class function TWarWavDecoder.TryDecode(const ASource: TBytes; out ABuffer: TWarPcmBuffer): Boolean;
var
  LSize: Int64;
  LPointer: Int64;
  LDataSize: Cardinal;
begin
  Result := False;
  ABuffer := Default(TWarPcmBuffer);
  LSize := Length(ASource);
  if LSize < HEADER_SIZE then
    Exit;
  if not (HasMarker(ASource, 0, 'RIFF') and HasMarker(ASource, 8, 'WAVE') and HasMarker(ASource, 12, 'fmt ')) then
    Exit;
  // the chunks are searched from the end of the "fmt " chunk (pointer arithmetic of the original, here in 64 bits)
  LPointer := 20 + Int64(ReadFour(ASource, 16));
  while LPointer + 8 <= LSize do
  begin
    if HasMarker(ASource, Integer(LPointer), 'data') then
      Break;
    LPointer := LPointer + 8 + Int64(ReadFour(ASource, LPointer + 4));
  end;
  if LPointer + 8 > LSize then
    Exit;
  LDataSize := ReadFour(ASource, LPointer + 4);
  LPointer := LPointer + 8;
  if LPointer + LDataSize > LSize then
    Exit;
  ABuffer.Channels := ReadWord(ASource, 22);
  ABuffer.SampleRate := ReadFour(ASource, 24);
  ABuffer.BitsPerSample := ReadWord(ASource, 34);
  SetLength(ABuffer.Data, LDataSize);
  if LDataSize > 0 then
    Move(ASource[LPointer], ABuffer.Data[0], LDataSize);
  Result := True;
end;

end.
