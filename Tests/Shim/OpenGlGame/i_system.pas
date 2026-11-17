{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of i_system for the per-game OpenGL scene tests       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Base\i_system.pas in DelphiDoom.Tests.OpenGl.<Game> only: the warnings, the developer warnings and the errors are lines of EventLog; the error also raises.
unit i_system;

interface

uses
  System.SysUtils;

type
  /// <summary>What I_Error does here instead of closing the program</summary>
  EShimFatalError = class(Exception);

procedure I_Error(const error: string); overload;
procedure I_Error(const error: string; const Args: array of const); overload;
procedure I_Warning(const warning: string); overload;
procedure I_Warning(const warning: string; const Args: array of const); overload;
procedure I_DevWarning(const warning: string); overload;
procedure I_DevWarning(const warning: string; const Args: array of const); overload;

implementation

uses
  d_delphi;

procedure I_Error(const error: string);
begin
  ShimEvent('I_Error ' + error);
  raise EShimFatalError.Create(error);
end;

procedure I_Error(const error: string; const Args: array of const);
begin
  I_Error(Format(error, Args));
end;

procedure I_Warning(const warning: string);
begin
  ShimEvent('I_Warning ' + StringReplace(warning, #13#10, '|', [rfReplaceAll]));
end;

procedure I_Warning(const warning: string; const Args: array of const);
begin
  I_Warning(Format(warning, Args));
end;

procedure I_DevWarning(const warning: string);
begin
  ShimEvent('I_DevWarning ' + StringReplace(warning, #13#10, '|', [rfReplaceAll]));
end;

procedure I_DevWarning(const warning: string; const Args: array of const);
begin
  I_DevWarning(Format(warning, Args));
end;

end.