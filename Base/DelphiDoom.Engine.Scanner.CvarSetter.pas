{******************************************************************************}
{                                                                              }
{  DelphiDoom: the console variables that #CVARFORCE sets                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Scanner.CvarSetter;

interface

uses
  DelphiDoom.Scanner.Preprocessor.Intf;

type
  /// <summary>The defaults of the engine (m_misc) and the evaluation of the console (c_cmds)</summary>
  TEngineCvarSetter = class(TInterfacedObject, ICvarSetter)
  public
    function EvaluateBoolean(const AText: string; ADefault: Boolean): Boolean;
    function TrySetBoolean(const AName: string; AValue: Boolean): Boolean;
    function TrySetInteger(const AName: string; AValue: Integer): Boolean;
    function TrySetString(const AName: string; const AValue: string): Boolean;
  end;

implementation

uses
  c_cmds,
  m_misc;

{ TEngineCvarSetter }

function TEngineCvarSetter.EvaluateBoolean(const AText: string; ADefault: Boolean): Boolean;
begin
  Result := C_BoolEval(AText, ADefault);
end;

function TEngineCvarSetter.TrySetBoolean(const AName: string; AValue: Boolean): Boolean;
begin
  Result := M_ForceDefaultBoolean(AName, AValue);
end;

function TEngineCvarSetter.TrySetInteger(const AName: string; AValue: Integer): Boolean;
begin
  Result := M_ForceDefaultInteger(AName, AValue);
end;

function TEngineCvarSetter.TrySetString(const AName: string; const AValue: string): Boolean;
begin
  Result := M_ForceDefaultString(AName, AValue);
end;

end.
