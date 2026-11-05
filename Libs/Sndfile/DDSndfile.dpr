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
  scanf_c in '..\..\C_LIB\scanf_c.pas',
  scanf in '..\..\C_LIB\scanf.pas',
  c_lib in '..\..\C_LIB\c_lib.pas',
  DelphiDoom.Ogg.Types in '..\Ogg\DelphiDoom.Ogg.Types.pas',
  DelphiDoom.Ogg.Memory in '..\Ogg\DelphiDoom.Ogg.Memory.pas',
  DelphiDoom.Ogg.Crc in '..\Ogg\DelphiDoom.Ogg.Crc.pas',
  DelphiDoom.Ogg.BitPacker in '..\Ogg\DelphiDoom.Ogg.BitPacker.pas',
  DelphiDoom.Ogg.PageReader in '..\Ogg\DelphiDoom.Ogg.PageReader.pas',
  DelphiDoom.Ogg.Stream in '..\Ogg\DelphiDoom.Ogg.Stream.pas',
  DelphiDoom.Ogg.Sync in '..\Ogg\DelphiDoom.Ogg.Sync.pas',
  libogg in 'Native\libogg.pas',
  libvorbis in 'Native\libvorbis.pas',
  libflac in 'Native\libflac.pas',
  DelphiDoom.Sndfile.Intf in 'DelphiDoom.Sndfile.Intf.pas',
  DelphiDoom.Sndfile.Native in 'DelphiDoom.Sndfile.Native.pas',
  DelphiDoom.Sndfile.SoundFile in 'DelphiDoom.Sndfile.SoundFile.pas',
  DelphiDoom.Sndfile.Engine in 'DelphiDoom.Sndfile.Engine.pas';

function DDSndfileCreate(out ASndfile: ISndfile): Integer; stdcall;
begin
  ASndfile := nil;
  try
    ASndfile := TSndfileEngine.Create;
    Result := SNDFILE_OK;
  except
    Result := SNDFILE_ERR_OUT_OF_MEMORY;
  end;
end;

exports
  DDSndfileCreate;

begin
end.
