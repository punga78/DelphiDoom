{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of i_system for the rule tests}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for the real i_system in DelphiDoom.Tests.Rules only: I_Error, raised as an exception so that a test sees the error.
{$I Doom32.inc}
unit i_system;

interface

uses
  SysUtils;

procedure I_Error(const error: string; const Args: array of const); overload;

procedure I_Error(const error: string); overload;

procedure I_DevError(const error: string; const Args: array of const); overload;

procedure I_DevError(const error: string); overload;

procedure I_Warning(const error: string; const Args: array of const); overload;

procedure I_Warning(const error: string); overload;

procedure I_DevWarning(const error: string; const Args: array of const); overload;

procedure I_DevWarning(const error: string); overload;

implementation

procedure I_Error(const error: string; const Args: array of const);
begin
  raise Exception.CreateFmt('I_Error ' + error, Args);
end;

procedure I_Error(const error: string);
begin
  raise Exception.Create('I_Error ' + error);
end;

procedure I_DevError(const error: string; const Args: array of const);
begin
  raise Exception.CreateFmt('I_DevError ' + error, Args);
end;

procedure I_DevError(const error: string);
begin
  raise Exception.Create('I_DevError ' + error);
end;

procedure I_Warning(const error: string; const Args: array of const);
begin
  raise Exception.CreateFmt('I_Warning ' + error, Args);
end;

procedure I_Warning(const error: string);
begin
  raise Exception.Create('I_Warning ' + error);
end;

procedure I_DevWarning(const error: string; const Args: array of const);
begin
  raise Exception.CreateFmt('I_DevWarning ' + error, Args);
end;

procedure I_DevWarning(const error: string);
begin
  raise Exception.Create('I_DevWarning ' + error);
end;

end.
