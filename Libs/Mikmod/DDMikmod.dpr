{******************************************************************************}
{                                                                              }
{  DDMikmod.dll: MikMod (module music) for DelphiDoom                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDMikmod;

uses
  DirectX in '..\..\Common\DirectX.pas',
  BTMemoryModule in '..\..\Base\BTMemoryModule.pas',
  mikmod in '..\..\Base\mikmod.pas',
  DelphiDoom.Mikmod.Intf in 'DelphiDoom.Mikmod.Intf.pas',
  DelphiDoom.Mikmod.Player in 'DelphiDoom.Mikmod.Player.pas',
  DelphiDoom.Mikmod.Engine in 'DelphiDoom.Mikmod.Engine.pas';

function DDMikmodCreate(out AMikMod: IMikMod): Integer; stdcall;
begin
  AMikMod := nil;
  try
    AMikMod := TMikModEngine.Create;
    Result := MIKMOD_OK;
  except
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

exports
  DDMikmodCreate;

begin
end.
