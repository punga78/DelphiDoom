{******************************************************************************}
{                                                                              }
{  DDSndfile.dll: libsndfile for DelphiDoom                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDSndfile;

uses
  DelphiDoom.Ogg.Types in '..\Ogg\DelphiDoom.Ogg.Types.pas',
  DelphiDoom.Ogg.Memory in '..\Ogg\DelphiDoom.Ogg.Memory.pas',
  DelphiDoom.Ogg.Crc in '..\Ogg\DelphiDoom.Ogg.Crc.pas',
  DelphiDoom.Ogg.BitPacker in '..\Ogg\DelphiDoom.Ogg.BitPacker.pas',
  DelphiDoom.Ogg.PageReader in '..\Ogg\DelphiDoom.Ogg.PageReader.pas',
  DelphiDoom.Ogg.Stream in '..\Ogg\DelphiDoom.Ogg.Stream.pas',
  DelphiDoom.Ogg.Sync in '..\Ogg\DelphiDoom.Ogg.Sync.pas',
  DelphiDoom.Sndfile.Intf in 'DelphiDoom.Sndfile.Intf.pas',
  DelphiDoom.Sound.Samples in '..\Sound\DelphiDoom.Sound.Samples.pas',
  DelphiDoom.Sound.Convert in '..\Sound\DelphiDoom.Sound.Convert.pas',
  DelphiDoom.Sound.Companding in '..\Sound\DelphiDoom.Sound.Companding.pas',
  DelphiDoom.Sound.ByteReader in '..\Sound\DelphiDoom.Sound.ByteReader.pas',
  DelphiDoom.Sound.PcmReader in '..\Sound\DelphiDoom.Sound.PcmReader.pas',
  DelphiDoom.Sound.SoundFile in '..\Sound\DelphiDoom.Sound.SoundFile.pas',
  DelphiDoom.Sound.Format in '..\Sound\DelphiDoom.Sound.Format.pas',
  DelphiDoom.Sound.Format.Wav in '..\Sound\DelphiDoom.Sound.Format.Wav.pas',
  DelphiDoom.Sound.Format.Aiff in '..\Sound\DelphiDoom.Sound.Format.Aiff.pas',
  DelphiDoom.Sound.Format.Au in '..\Sound\DelphiDoom.Sound.Format.Au.pas',
  DelphiDoom.Sound.Format.Voc in '..\Sound\DelphiDoom.Sound.Format.Voc.pas',
  DelphiDoom.Sound.Format.Avr in '..\Sound\DelphiDoom.Sound.Format.Avr.pas',
  DelphiDoom.Sound.WavLike.Fmt in '..\Sound\DelphiDoom.Sound.WavLike.Fmt.pas',
  DelphiDoom.Sound.Format.W64 in '..\Sound\DelphiDoom.Sound.Format.W64.pas',
  DelphiDoom.Sound.Format.Rf64 in '..\Sound\DelphiDoom.Sound.Format.Rf64.pas',
  DelphiDoom.Sound.Format.Caf in '..\Sound\DelphiDoom.Sound.Format.Caf.pas',
  DelphiDoom.Sound.Format.Svx in '..\Sound\DelphiDoom.Sound.Format.Svx.pas',
  DelphiDoom.Sound.Format.Ircam in '..\Sound\DelphiDoom.Sound.Format.Ircam.pas',
  DelphiDoom.Sound.Format.Mat4 in '..\Sound\DelphiDoom.Sound.Format.Mat4.pas',
  DelphiDoom.Sound.Format.Mat5 in '..\Sound\DelphiDoom.Sound.Format.Mat5.pas',
  DelphiDoom.Sound.Format.Wve in '..\Sound\DelphiDoom.Sound.Format.Wve.pas',
  DelphiDoom.Sound.Format.Mpc2k in '..\Sound\DelphiDoom.Sound.Format.Mpc2k.pas',
  DelphiDoom.Sound.CodecSamples in '..\Sound\DelphiDoom.Sound.CodecSamples.pas',
  DelphiDoom.Sound.Codec.MsAdpcm in '..\Sound\DelphiDoom.Sound.Codec.MsAdpcm.pas',
  DelphiDoom.Sound.Codec.ImaAdpcm in '..\Sound\DelphiDoom.Sound.Codec.ImaAdpcm.pas',
  DelphiDoom.Sound.Codec.Gsm610 in '..\Sound\DelphiDoom.Sound.Codec.Gsm610.pas',
  DelphiDoom.Sound.Codec.G72x in '..\Sound\DelphiDoom.Sound.Codec.G72x.pas',
  DelphiDoom.Sound.Codec.Dwvw in '..\Sound\DelphiDoom.Sound.Codec.Dwvw.pas',
  DelphiDoom.Sound.Codec.Flac in '..\Sound\DelphiDoom.Sound.Codec.Flac.pas',
  DelphiDoom.Sound.Format.Flac in '..\Sound\DelphiDoom.Sound.Format.Flac.pas',
  DelphiDoom.Sound.Vorbis.Types in '..\Sound\DelphiDoom.Sound.Vorbis.Types.pas',
  DelphiDoom.Sound.Vorbis.WindowTables in '..\Sound\DelphiDoom.Sound.Vorbis.WindowTables.pas',
  DelphiDoom.Sound.Vorbis.Mdct in '..\Sound\DelphiDoom.Sound.Vorbis.Mdct.pas',
  DelphiDoom.Sound.Vorbis.Codebook in '..\Sound\DelphiDoom.Sound.Vorbis.Codebook.pas',
  DelphiDoom.Sound.Vorbis.Floor1 in '..\Sound\DelphiDoom.Sound.Vorbis.Floor1.pas',
  DelphiDoom.Sound.Vorbis.Residue in '..\Sound\DelphiDoom.Sound.Vorbis.Residue.pas',
  DelphiDoom.Sound.Vorbis.Mapping in '..\Sound\DelphiDoom.Sound.Vorbis.Mapping.pas',
  DelphiDoom.Sound.Vorbis.Info in '..\Sound\DelphiDoom.Sound.Vorbis.Info.pas',
  DelphiDoom.Sound.Vorbis.Dsp in '..\Sound\DelphiDoom.Sound.Vorbis.Dsp.pas',
  DelphiDoom.Sound.Vorbis.Length in '..\Sound\DelphiDoom.Sound.Vorbis.Length.pas',
  DelphiDoom.Sound.Codec.Vorbis in '..\Sound\DelphiDoom.Sound.Codec.Vorbis.pas',
  DelphiDoom.Sound.Format.Ogg in '..\Sound\DelphiDoom.Sound.Format.Ogg.pas',
  DelphiDoom.Sound.Format.Paf in '..\Sound\DelphiDoom.Sound.Format.Paf.pas',
  DelphiDoom.Sound.Format.Sds in '..\Sound\DelphiDoom.Sound.Format.Sds.pas',
  DelphiDoom.Sound.Format.Xi in '..\Sound\DelphiDoom.Sound.Format.Xi.pas',
  DelphiDoom.Sound.Format.Htk in '..\Sound\DelphiDoom.Sound.Format.Htk.pas',
  DelphiDoom.Sound.Engine in '..\Sound\DelphiDoom.Sound.Engine.pas',
  DelphiDoom.Sound.Factory in '..\Sound\DelphiDoom.Sound.Factory.pas';

function DDSndfileCreate(out ASndfile: ISndfile): Integer; stdcall;
begin
  ASndfile := nil;
  try
    ASndfile := TSoundFactory.CreateEngine;
    Result := SNDFILE_OK;
  except
    Result := SNDFILE_ERR_OUT_OF_MEMORY;
  end;
end;

exports
  DDSndfileCreate;

begin
end.
