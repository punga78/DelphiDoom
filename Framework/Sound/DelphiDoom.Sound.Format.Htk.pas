{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - HTK waveform files                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Htk;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   HTK waveform files: a 12 byte header (sample count, sample period and
  ///   the kind) followed by mono 16 bit samples, big endian. libsndfile
  ///   recognises them by the header agreeing with the length of the file
  /// </summary>
  THtkFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader;

const
  HEADER_SIZE = 12;
  KIND_WAVEFORM = $20000;
  DEFAULT_SAMPLE_RATE = 16000;

{ THtkFormat }

function THtkFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LSampleCount, LSamplePeriod, LKind: Cardinal;
  LLayout: TSoundPcmLayout;
begin
  ASamples := nil;
  LReader := TSoundByteReader.Create(ASource);
  LReader.BigEndian := True;
  if Length(ASource) < HEADER_SIZE then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  LSampleCount := LReader.ReadUInt32;
  LSamplePeriod := LReader.ReadUInt32;
  LKind := LReader.ReadUInt32;
  // The only thing there is to recognise it by
  if (LKind <> KIND_WAVEFORM) or
     (2 * Int64(LSampleCount) + HEADER_SIZE <> Length(ASource)) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  FillChar(LLayout, SizeOf(LLayout), 0);
  LLayout.Encoding := SNDFILE_FORMAT_PCM_16;
  LLayout.BytesPerSample := 2;
  LLayout.Channels := 1;
  LLayout.Format := SNDFILE_FORMAT_HTK or SNDFILE_FORMAT_PCM_16;
  if (LSamplePeriod > 0) and (Int64(LSamplePeriod) <= High(Integer)) then
    LLayout.SampleRate := 10000000 div Integer(LSamplePeriod)
  else
    LLayout.SampleRate := DEFAULT_SAMPLE_RATE;

  Result := TSoundPcmReader.Read(ASource, LLayout, HEADER_SIZE,
    Length(ASource) - HEADER_SIZE, Length(ASource), True, ASamples);
end;

end.
