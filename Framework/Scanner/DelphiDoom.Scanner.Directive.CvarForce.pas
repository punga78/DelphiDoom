{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - #CVARFORCE                                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.Directive.CvarForce;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Scanner.Preprocessor.Intf;

type
  /// <summary>
  ///   "#CVARFORCE name value": forces a console variable. The value is tried as a boolean,
  ///   then as an integer, then as a text
  /// </summary>
  TCvarForceDirective = class(TInterfacedObject, IScriptDirective)
  private
    FSetter: ICvarSetter;
    FLog: ILog;
    procedure Warn(const AMessage: string);
  public
    constructor Create(const ASetter: ICvarSetter; const ALog: ILog);
    function Execute(const AUpperLine: string): Boolean;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

{ TCvarForceDirective }

constructor TCvarForceDirective.Create(const ASetter: ICvarSetter; const ALog: ILog);
begin
  inherited Create;
  FSetter := ASetter;
  FLog := ALog;
end;

procedure TCvarForceDirective.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

function TCvarForceDirective.Execute(const AUpperLine: string): Boolean;
var
  LKeyword: string;
  LRest: string;
  LName: string;
  LValue: string;
begin
  Result := AUpperLine.StartsWith('#CVARFORCE ');
  if not Result then
    Exit;
  TScannerStrings.SplitAtFirst(AUpperLine, LKeyword, LRest);
  if LRest = '' then
  begin
    Warn('SC_Preprocess(): No cvar specified after the #CVARFORCE directive'#13#10);
    Exit;
  end;
  TScannerStrings.SplitAtFirst(LRest, LName, LValue);
  if LValue = '' then
  begin
    Warn(Format('SC_Preprocess(): Can not set cvar "%s", no value specified'#13#10, [LName]));
    Exit;
  end;
  if not FSetter.TrySetBoolean(LName, FSetter.EvaluateBoolean(LValue, True)) then
    if not FSetter.TrySetInteger(LName, TScannerStrings.ToInteger(LValue)) then
      if not FSetter.TrySetString(LName, LValue) then
        Warn(Format('SC_Preprocess(): Can not set cvar "%s" to "%s"'#13#10, [LName, LValue]));
end;

end.
