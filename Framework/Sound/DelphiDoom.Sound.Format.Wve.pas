{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Psion Palmtop A-law files (WVE)                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Wve;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   Psion WVE files: "ALawSoundFile**", a 32 byte header, then mono A-law
  ///   at 8000 Hz
  /// </summary>
  TWveFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader;

const
  DATA_OFFSET = $20;
  SAMPLE_RATE = 8000;

{ TWveFormat }

function TWveFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LLayout: TSoundPcmLayout;
  LDataLength: Int64;
begin
  ASamples := nil;
  LReader := TSoundByteReader.Create(ASource);
  if (Length(ASource) < 12) or (LReader.ReadMarker <> TSoundByteReader.MarkerOf('ALaw')) or
     (LReader.ReadMarker <> TSoundByteReader.MarkerOf('Soun')) or
     (LReader.ReadMarker <> TSoundByteReader.MarkerOf('dFil')) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);
  // The last marker is "e**" and a zero
  if LReader.ReadMarker <> TSoundByteReader.MarkerOf('e**'#0) then
    Exit(SNDFILE_ERR_MALFORMED_FILE);

  // The rest of the header says nothing libsndfile relies on
  FillChar(LLayout, SizeOf(LLayout), 0);
  LLayout.Encoding := SNDFILE_FORMAT_ALAW;
  LLayout.BytesPerSample := 1;
  LLayout.Channels := 1;
  LLayout.SampleRate := SAMPLE_RATE;
  LLayout.Format := SNDFILE_FORMAT_WVE or SNDFILE_FORMAT_ALAW;

  if Length(ASource) > DATA_OFFSET then
    LDataLength := Length(ASource) - DATA_OFFSET
  else
    LDataLength := 0;
  Result := TSoundPcmReader.Read(ASource, LLayout, DATA_OFFSET, LDataLength,
    Length(ASource), True, ASamples);
end;

end.
