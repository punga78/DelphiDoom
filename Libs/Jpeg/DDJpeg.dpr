{******************************************************************************}
{                                                                              }
{  DDJpeg.dll: JPEG for DelphiDoom                                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDJpeg;

uses
  d_delphi in '..\..\Common\d_delphi.pas',
  jpg_utils in '..\..\JPEGLIB\jpg_utils.pas',
  jpg_comapi in '..\..\JPEGLIB\jpg_comapi.pas',
  jpg_dapimin in '..\..\JPEGLIB\jpg_dapimin.pas',
  jpg_dapistd in '..\..\JPEGLIB\jpg_dapistd.pas',
  jpg_dcoefct in '..\..\JPEGLIB\jpg_dcoefct.pas',
  jpg_dcolor in '..\..\JPEGLIB\jpg_dcolor.pas',
  jpg_dct in '..\..\JPEGLIB\jpg_dct.pas',
  jpg_ddctmgr in '..\..\JPEGLIB\jpg_ddctmgr.pas',
  jpg_deferr in '..\..\JPEGLIB\jpg_deferr.pas',
  jpg_dhuff in '..\..\JPEGLIB\jpg_dhuff.pas',
  jpg_dinput in '..\..\JPEGLIB\jpg_dinput.pas',
  jpg_dmainct in '..\..\JPEGLIB\jpg_dmainct.pas',
  jpg_dmarker in '..\..\JPEGLIB\jpg_dmarker.pas',
  jpg_dmaster in '..\..\JPEGLIB\jpg_dmaster.pas',
  jpg_dmerge in '..\..\JPEGLIB\jpg_dmerge.pas',
  jpg_dphuff in '..\..\JPEGLIB\jpg_dphuff.pas',
  jpg_dpostct in '..\..\JPEGLIB\jpg_dpostct.pas',
  jpg_dsample in '..\..\JPEGLIB\jpg_dsample.pas',
  jpg_error in '..\..\JPEGLIB\jpg_error.pas',
  jpg_idctasm in '..\..\JPEGLIB\jpg_idctasm.pas',
  jpg_idctflt in '..\..\JPEGLIB\jpg_idctflt.pas',
  jpg_idctfst in '..\..\JPEGLIB\jpg_idctfst.pas',
  jpg_IDctRed in '..\..\JPEGLIB\jpg_IDctRed.pas',
  jpg_lib in '..\..\JPEGLIB\jpg_lib.pas',
  jpg_memmgr in '..\..\JPEGLIB\jpg_memmgr.pas',
  jpg_memnobs in '..\..\JPEGLIB\jpg_memnobs.pas',
  jpg_morecfg in '..\..\JPEGLIB\jpg_morecfg.pas',
  jpg_quant1 in '..\..\JPEGLIB\jpg_quant1.pas',
  jpg_quant2 in '..\..\JPEGLIB\jpg_quant2.pas',
  DelphiDoom.Jpeg.Intf in 'DelphiDoom.Jpeg.Intf.pas',
  DelphiDoom.Jpeg.Native in 'DelphiDoom.Jpeg.Native.pas',
  DelphiDoom.Jpeg.Encoder in 'DelphiDoom.Jpeg.Encoder.pas',
  DelphiDoom.Jpeg.Engine in 'DelphiDoom.Jpeg.Engine.pas';

function DDJpegCreate(out AJpeg: IJpeg): Integer; stdcall;
begin
  AJpeg := nil;
  try
    AJpeg := TJpegEngine.Create;
    Result := DDJPEG_OK;
  except
    Result := DDJPEG_ERR_MEMORY;
  end;
end;

exports
  DDJpegCreate;

begin
end.
