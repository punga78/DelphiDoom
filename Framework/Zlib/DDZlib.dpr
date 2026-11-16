{******************************************************************************}
{                                                                              }
{  DDZlib.dll: zlib for DelphiDoom                                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDZlib;

// the 64-bit library is DD<Name>64.dll, so that it never overwrites or gets confused with the 32-bit one
{$IFDEF CPUX64}
{$LIBSUFFIX '64'}
{$ENDIF}

uses
  DelphiDoom.Zlib.Intf in 'DelphiDoom.Zlib.Intf.pas',
  DelphiDoom.Zlib.Inflater in 'DelphiDoom.Zlib.Inflater.pas',
  DelphiDoom.Zlib.Deflater in 'DelphiDoom.Zlib.Deflater.pas',
  DelphiDoom.Zlib.Engine in 'DelphiDoom.Zlib.Engine.pas';

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
