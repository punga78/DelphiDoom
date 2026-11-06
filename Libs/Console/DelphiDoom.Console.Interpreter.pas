{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the interpreter of the lines                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Interpreter;

interface

uses
  DelphiDoom.Console.Types, DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   Cuts the line in the name and two parameters and runs the command (old C_ExecuteCmd).
  ///   A name that is not a command is a variable: "name" is "get name", "name value" is
  ///   "set name value". The name goes to the commands "get" and "set" in upper case, as it
  ///   did before
  /// </summary>
  TConsoleInterpreter = class(TInterfacedObject, IConsoleInterpreter)
  private
    FRegistry: ICommandRegistry;
  public
    constructor Create(const ARegistry: ICommandRegistry);
    function Execute(const ALine: string): Boolean; overload;
    function Execute(const AName, AParameters: string): Boolean; overload;
    function Execute(const AName, AParam1, AParam2: string): Boolean; overload;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Console.Text;

const
  GET_COMMAND = 'GET';
  SET_COMMAND = 'SET';
  WORD_SEPARATOR = ' ';

{ TConsoleInterpreter }

constructor TConsoleInterpreter.Create(const ARegistry: ICommandRegistry);
begin
  inherited Create;
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create('ARegistry');
  FRegistry := ARegistry;
end;

function TConsoleInterpreter.Execute(const ALine: string): Boolean;
var
  LName: string;
  LParameters: string;
begin
  TConsoleText.Split(ALine, WORD_SEPARATOR, LName, LParameters);
  Result := Execute(LName, LParameters);
end;

function TConsoleInterpreter.Execute(const AName, AParameters: string): Boolean;
var
  LParam1: string;
  LParam2: string;
begin
  TConsoleText.Split(AParameters, WORD_SEPARATOR, LParam1, LParam2);
  Result := Execute(AName, LParam1, LParam2);
end;

function TConsoleInterpreter.Execute(const AName, AParam1, AParam2: string): Boolean;
var
  LName: string;
  LHandler: TConsoleCommandHandler;
begin
  LName := TConsoleText.UpperCase(AName);
  if FRegistry.Find(LName, LHandler) then
  begin
    LHandler(AParam1, AParam2);
    Exit(True);
  end;

  if (LName <> GET_COMMAND) and (LName <> SET_COMMAND) then
  begin
    if AParam1 = '' then
      Result := Execute(GET_COMMAND, LName)
    else if AParam2 = '' then
      Result := Execute(SET_COMMAND, LName, AParam1)
    else
      Result := False;
  end
  else
    Result := False;
end;

end.
