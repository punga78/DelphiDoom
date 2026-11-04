{******************************************************************************}
{                                                                              }
{  DDGlbsp.dll: the glbsp node builder for DelphiDoom                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDGlbsp;

uses
  DelphiDoom.Glbsp.Intf in 'DelphiDoom.Glbsp.Intf.pas',
  DelphiDoom.Glbsp.Executable in 'DelphiDoom.Glbsp.Executable.pas',
  DelphiDoom.Glbsp.Runner in 'DelphiDoom.Glbsp.Runner.pas',
  DelphiDoom.Glbsp.Engine in 'DelphiDoom.Glbsp.Engine.pas';

function DDGlbspCreate(out AGlbsp: IGlbsp): Integer; stdcall;
begin
  AGlbsp := nil;
  try
    AGlbsp := TGlbspEngine.Create;
    Result := GLBSP_OK;
  except
    Result := GLBSP_ERR_INTERNAL;
  end;
end;

exports
  DDGlbspCreate;

begin
end.
