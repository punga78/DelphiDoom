{******************************************************************************}
{                                                                              }
{  DDXmi.dll: XMI/CMF to MIDI conversion for DelphiDoom                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDXmi;

uses
  d_delphi in 'Libs\Xmi\Shim\d_delphi.pas',
  xmi_consts in 'XMILIB\xmi_consts.pas',
  xmi_iff in 'XMILIB\xmi_iff.pas',
  xmi_core in 'XMILIB\xmi_core.pas' {XMICore},
  DelphiDoom.Xmi.Intf in 'Libs\Xmi\DelphiDoom.Xmi.Intf.pas',
  DelphiDoom.Xmi.Native in 'Libs\Xmi\DelphiDoom.Xmi.Native.pas',
  DelphiDoom.Xmi.Engine in 'Libs\Xmi\DelphiDoom.Xmi.Engine.pas';

function DDXmiCreate(out AXmi: IXmi): Integer; stdcall;
begin
  AXmi := nil;
  try
    AXmi := TXmiEngine.Create;
    Result := XMI_OK;
  except
    Result := XMI_ERROR_MEMORY;
  end;
end;

exports
  DDXmiCreate;

begin
end.
