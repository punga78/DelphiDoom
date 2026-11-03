{******************************************************************************}
{                                                                              }
{  DelphiDoom: mp3 - minimal stand-in for Base\i_system.pas                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit i_system;

// The units of MP3LIB call I_Error, I_Warning and I_Sleep. In the engine
// I_Error ends the program; inside the DLL it must not, so here it raises an
// exception that the decoder turns into an error code.

interface

procedure I_Error(const error: string);

procedure I_Warning(const warning: string);

procedure I_Sleep(const msecs: Integer);

implementation

uses
  System.SysUtils, Winapi.Windows;

procedure I_Error(const error: string);
begin
  raise Exception.Create(error);
end;

procedure I_Warning(const warning: string);
begin
  OutputDebugString(PChar(warning));
end;

procedure I_Sleep(const msecs: Integer);
begin
  Sleep(msecs);
end;

end.
