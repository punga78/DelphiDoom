{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of i_system for the OpenGL vsync unit                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\i_system.pas in DelphiDoom.Tests.OpenGl only: the warnings are collected
// in a list the test reads instead of going to the log.
unit i_system;

interface

uses
  System.Classes;

var
  WarningLog: TStringList;

procedure I_Warning(const warning: string); overload;

implementation

procedure I_Warning(const warning: string);
begin
  if Assigned(WarningLog) then
    WarningLog.Add(warning);
end;

end.
