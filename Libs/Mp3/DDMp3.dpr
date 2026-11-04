{******************************************************************************}
{                                                                              }
{  DDMp3.dll: MP3 (MPEG layer III) decoder for DelphiDoom                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDMp3;

// d_delphi and i_system are the stand-ins of Libs\Mp3\Shim, not the units of
// the engine. The player units of the old player of the engine (mp3_MPEGPlayer, mp3_Player,
// mp3_Args, mp3_OBuffer_MCI, mp3_OBuffer_Wave) and the layer I and II units
// (mp3_SubBand*, mp3_ScaleFac) are not part of the DLL.

uses
  d_delphi in 'Shim\d_delphi.pas',
  i_system in 'Shim\i_system.pas',
  mp3_Shared in '..Decoder\mp3_Shared.pas',
  mp3_CRC in '..Decoder\mp3_CRC.pas',
  mp3_BitReserve in '..Decoder\mp3_BitReserve.pas',
  mp3_BitStream in '..Decoder\mp3_BitStream.pas',
  mp3_Header in '..Decoder\mp3_Header.pas',
  mp3_OBuffer in '..Decoder\mp3_OBuffer.pas',
  mp3_SynthFilter in '..Decoder\mp3_SynthFilter.pas',
  mp3_L3Type in '..Decoder\mp3_L3Type.pas',
  mp3_L3Tables in '..Decoder\mp3_L3Tables.pas',
  mp3_Huffman in '..Decoder\mp3_Huffman.pas',
  mp3_InvMDT in '..Decoder\mp3_InvMDT.pas',
  mp3_Layer3 in '..Decoder\mp3_Layer3.pas',
  DelphiDoom.Mp3.Intf in 'DelphiDoom.Mp3.Intf.pas',
  DelphiDoom.Mp3.Stream in 'DelphiDoom.Mp3.Stream.pas',
  DelphiDoom.Mp3.FrameLocator in 'DelphiDoom.Mp3.FrameLocator.pas',
  DelphiDoom.Mp3.PcmBuffer in 'DelphiDoom.Mp3.PcmBuffer.pas',
  DelphiDoom.Mp3.Native in 'DelphiDoom.Mp3.Native.pas',
  DelphiDoom.Mp3.Decoder in 'DelphiDoom.Mp3.Decoder.pas',
  DelphiDoom.Mp3.Engine in 'DelphiDoom.Mp3.Engine.pas';

function DDMp3Create(out AMp3: IMp3): Integer; stdcall;
begin
  AMp3 := nil;
  try
    AMp3 := TMp3Engine.Create;
    Result := MP3_OK;
  except
    Result := MP3_ERROR_MEMORY;
  end;
end;

exports
  DDMp3Create;

begin
end.
