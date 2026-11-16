{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - Akai MPC2000 sample files                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Format.Mpc2k;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples,
  DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   MPC2000 files: a 42 byte header that starts with the bytes 1 and 4,
  ///   then 16 bit little endian PCM, mono or stereo
  /// </summary>
  TMpc2kFormat = class(TInterfacedObject, ISoundFormat)
  public
    function Decode(const ASource: TBytes; out ASamples: TSoundSamples): Integer;
  end;

implementation

uses
  DelphiDoom.Sound.ByteReader, DelphiDoom.Sound.PcmReader;

const
  HEADER_LENGTH = 42;
  HEADER_NAME_LENGTH = 17;

{ TMpc2kFormat }

function TMpc2kFormat.Decode(const ASource: TBytes;
  out ASamples: TSoundSamples): Integer;
var
  LReader: TSoundByteReader;
  LStereo: Byte;
  LSampleRate: Word;
  LLayout: TSoundPcmLayout;
  LDataLength: Int64;
begin
  ASamples := nil;
  if (Length(ASource) < 12) or (ASource[0] <> 1) or (ASource[1] <> 4) then
    Exit(SNDFILE_ERR_UNRECOGNISED_FORMAT);

  LReader := TSoundByteReader.Create(ASource);
  // The two marker bytes, the name, then the level, the tune and the channels
  LReader.Position := 2 + HEADER_NAME_LENGTH + 2;
  LStereo := LReader.ReadByte;
  // Start, loop end, frames and loop length, the loop mode and the beats
  LReader.Skip(16 + 2);
  LSampleRate := LReader.ReadUInt16;

  FillChar(LLayout, SizeOf(LLayout), 0);
  LLayout.Encoding := SNDFILE_FORMAT_PCM_16;
  LLayout.BytesPerSample := 2;
  if LStereo <> 0 then
    LLayout.Channels := 2
  else
    LLayout.Channels := 1;
  LLayout.SampleRate := LSampleRate;
  LLayout.Format := SNDFILE_FORMAT_MPC2K or SNDFILE_FORMAT_PCM_16;

  if Length(ASource) > HEADER_LENGTH then
    LDataLength := Length(ASource) - HEADER_LENGTH
  else
    LDataLength := 0;
  Result := TSoundPcmReader.Read(ASource, LLayout, HEADER_LENGTH, LDataLength,
    Length(ASource), False, ASamples);
end;

end.
