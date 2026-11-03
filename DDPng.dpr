{******************************************************************************}
{                                                                              }
{  DDPng.dll: PNG for DelphiDoom                                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDPng;

// The DLL has no zlib of its own: it uses the IZlib that DDPngCreate receives
// (from DDZlib.dll or from an engine linked in the caller), so only the
// contract of zlib (DelphiDoom.Zlib.Intf) is part of it.

uses
  DelphiDoom.Zlib.Intf in 'Libs\Zlib\DelphiDoom.Zlib.Intf.pas',
  DelphiDoom.Png.Intf in 'Libs\Png\DelphiDoom.Png.Intf.pas',
  DelphiDoom.Png.Crc in 'Libs\Png\DelphiDoom.Png.Crc.pas',
  DelphiDoom.Png.ByteOrder in 'Libs\Png\DelphiDoom.Png.ByteOrder.pas',
  DelphiDoom.Png.Predictor in 'Libs\Png\DelphiDoom.Png.Predictor.pas',
  DelphiDoom.Png.Header in 'Libs\Png\DelphiDoom.Png.Header.pas',
  DelphiDoom.Png.Adam7 in 'Libs\Png\DelphiDoom.Png.Adam7.pas',
  DelphiDoom.Png.ChunkReader in 'Libs\Png\DelphiDoom.Png.ChunkReader.pas',
  DelphiDoom.Png.ChunkWriter in 'Libs\Png\DelphiDoom.Png.ChunkWriter.pas',
  DelphiDoom.Png.Metadata in 'Libs\Png\DelphiDoom.Png.Metadata.pas',
  DelphiDoom.Png.IdatStream in 'Libs\Png\DelphiDoom.Png.IdatStream.pas',
  DelphiDoom.Png.Unfilter in 'Libs\Png\DelphiDoom.Png.Unfilter.pas',
  DelphiDoom.Png.PixelConverter in 'Libs\Png\DelphiDoom.Png.PixelConverter.pas',
  DelphiDoom.Png.Decoder in 'Libs\Png\DelphiDoom.Png.Decoder.pas',
  DelphiDoom.Png.Filter in 'Libs\Png\DelphiDoom.Png.Filter.pas',
  DelphiDoom.Png.PixelPacker in 'Libs\Png\DelphiDoom.Png.PixelPacker.pas',
  DelphiDoom.Png.Encoder in 'Libs\Png\DelphiDoom.Png.Encoder.pas',
  DelphiDoom.Png.Engine in 'Libs\Png\DelphiDoom.Png.Engine.pas';

function DDPngCreate(AZlib: IZlib; out APng: IPng): Integer; stdcall;
begin
  APng := nil;
  if not Assigned(AZlib) then
    Exit(DDPNG_ERR_INVALID_ARGUMENT);
  try
    APng := TPngEngine.Create(AZlib);
    Result := DDPNG_OK;
  except
    Result := DDPNG_ERR_MEMORY;
  end;
end;

exports
  DDPngCreate;

begin
end.
