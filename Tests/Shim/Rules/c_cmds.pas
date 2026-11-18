{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of c_cmds for the rule tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real c_cmds in DelphiDoom.Tests.Rules only: the call that p_inter makes to run a console command (the real unit is the console).
{$I Doom32.inc}
unit c_cmds;

interface

procedure C_ExecuteCmd(const cmd: string);

implementation

procedure C_ExecuteCmd(const cmd: string);
begin
end;

end.