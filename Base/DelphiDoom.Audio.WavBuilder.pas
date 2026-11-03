{******************************************************************************}
{                                                                              }
{  DelphiDoom: builds a WAV file from 16 bit samples                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.WavBuilder;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Wraps interleaved 16 bit PCM samples in the 44 bytes header of a
  ///   canonical WAV file, the format the sound loaders of the engine read
  /// </summary>
  TWavBuilder = class
  public
    class function Build(const ASamples: TArray<SmallInt>; AChannels,
      ASampleRate: Integer): TBytes; static;
  end;

const
  WAV_HEADER_SIZE = 44;

implementation

type
  TWavHeader = packed record
    RiffTag: array[0..3] of AnsiChar;
    RiffSize: Cardinal;
    WaveTag: array[0..3] of AnsiChar;
    FormatTag: array[0..3] of AnsiChar;
    FormatSize: Cardinal;
    AudioFormat: Word;
    Channels: Word;
    SampleRate: Cardinal;
    ByteRate: Cardinal;
    BlockAlign: Word;
    BitsPerSample: Word;
    DataTag: array[0..3] of AnsiChar;
    DataSize: Cardinal;
  end;

const
  PCM_FORMAT = 1;
  BITS_PER_SAMPLE = 16;

{ TWavBuilder }

class function TWavBuilder.Build(const ASamples: TArray<SmallInt>; AChannels,
  ASampleRate: Integer): TBytes;
var
  LHeader: TWavHeader;
  LDataSize: Cardinal;
begin
  if (AChannels < 1) or (AChannels > High(Word)) or (ASampleRate < 1) then
    raise EArgumentException.Create('Invalid channels or sample rate');

  LDataSize := Cardinal(Length(ASamples)) * SizeOf(SmallInt);

  FillChar(LHeader, SizeOf(LHeader), 0);
  LHeader.RiffTag := 'RIFF';
  LHeader.RiffSize := SizeOf(LHeader) - 8 + LDataSize;
  LHeader.WaveTag := 'WAVE';
  LHeader.FormatTag := 'fmt ';
  LHeader.FormatSize := 16;
  LHeader.AudioFormat := PCM_FORMAT;
  LHeader.Channels := AChannels;
  LHeader.SampleRate := ASampleRate;
  LHeader.BlockAlign := AChannels * (BITS_PER_SAMPLE div 8);
  LHeader.ByteRate := Cardinal(ASampleRate) * LHeader.BlockAlign;
  LHeader.BitsPerSample := BITS_PER_SAMPLE;
  LHeader.DataTag := 'data';
  LHeader.DataSize := LDataSize;

  SetLength(Result, SizeOf(LHeader) + LDataSize);
  Move(LHeader, Result[0], SizeOf(LHeader));
  if LDataSize > 0 then
    Move(ASamples[0], Result[SizeOf(LHeader)], LDataSize);
end;

end.
