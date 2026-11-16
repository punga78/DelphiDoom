{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - the environment variables of Windows              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.WindowsEnvironment;

interface

uses
  DelphiDoom.Iwad.Intf;

type
  /// <summary>The environment of the process</summary>
  TIwadWindowsEnvironment = class(TInterfacedObject, IIwadEnvironment)
  public
    function GetValue(const AName: string): string;
  end;

implementation

uses
  System.SysUtils;

{ TIwadWindowsEnvironment }

function TIwadWindowsEnvironment.GetValue(const AName: string): string;
begin
  Result := Trim(GetEnvironmentVariable(AName));
end;

end.
