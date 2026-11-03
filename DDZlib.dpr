{******************************************************************************}
{                                                                              }
{  DDZlib.dll: zlib for DelphiDoom                                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDZlib;

uses
  DelphiDoom.Zlib.Intf in 'Libs\Zlib\DelphiDoom.Zlib.Intf.pas',
  DelphiDoom.Zlib.Native in 'Libs\Zlib\DelphiDoom.Zlib.Native.pas',
  DelphiDoom.Zlib.Inflater in 'Libs\Zlib\DelphiDoom.Zlib.Inflater.pas',
  DelphiDoom.Zlib.Deflater in 'Libs\Zlib\DelphiDoom.Zlib.Deflater.pas',
  DelphiDoom.Zlib.Engine in 'Libs\Zlib\DelphiDoom.Zlib.Engine.pas';

function DDZlibCreate(out AZlib: IZlib): Integer; stdcall;
begin
  AZlib := nil;
  try
    AZlib := TZlibEngine.Create;
    Result := ZLIB_OK;
  except
    Result := ZLIB_MEM_ERROR;
  end;
end;

exports
  DDZlibCreate;

begin
end.
