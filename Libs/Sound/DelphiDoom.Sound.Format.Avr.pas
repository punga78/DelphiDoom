{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - AVR (Audio Visual Research) files               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Avr;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   AVR files: a 128 byte header starting with "2BIT", then mono or stereo
  ///   samples of 8 bit (signed or not) or 16 bit (signed), big endian
  /// </summary>
  TAvrFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader;

const
  HEADER_SIZE = 128;

{ TAvrFormat }

function TAvrFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LMono, LResolution, LSign: SmallInt;
  LSampleRate: Cardinal;
  LLayout: TSoundPcmLayout;
  LDataLength: Int64;
begin
  ASamples := nil;
  LReader := TSoundByteReader.Create(ASource);
  LReader.BigEndian := True;
  if (Length(ASource) < 12) or (LReader.ReadMarker <> TSoundByteReader.MarkerOf('2BIT')) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  // The 8 characters of the name
  LReader.Skip(8);
  LMono := SmallInt(LReader.ReadUInt16);
  LResolution := SmallInt(LReader.ReadUInt16);
  LSign := SmallInt(LReader.ReadUInt16);
  // Loop and MIDI note
  LReader.Skip(4);
  LSampleRate := LReader.ReadUInt32;

  FillChar(LLayout, SizeOf(LLayout), 0);
  LLayout.Channels := (LMono and 1) + 1;
  case (Integer(LResolution) shl 16) + (LSign and 1) of
    (8 shl 16) + 0:
      begin
        LLayout.Encoding := SNDFILE_FORMAT_PCM_U8;
        LLayout.BytesPerSample := 1;
      end;
    (8 shl 16) + 1:
      begin
        LLayout.Encoding := SNDFILE_FORMAT_PCM_S8;
        LLayout.BytesPerSample := 1;
      end;
    (16 shl 16) + 1:
      begin
        LLayout.Encoding := SNDFILE_FORMAT_PCM_16;
        LLayout.BytesPerSample := 2;
      end;
  else
    Exit(SNDFILE_ERR_MALFORMED_FILE);
  end;
  LLayout.SampleRate := Integer(LSampleRate);
  LLayout.Format := SNDFILE_FORMAT_AVR or LLayout.Encoding;

  // The frame count in the header is ignored: the data is the rest of the file
  if Length(ASource) > HEADER_SIZE then
    LDataLength := Length(ASource) - HEADER_SIZE
  else
    LDataLength := 0;
  Result := TSoundPcmReader.Read(ASource, LLayout, HEADER_SIZE, LDataLength,
    Length(ASource), True, ASamples);
end;

end.
