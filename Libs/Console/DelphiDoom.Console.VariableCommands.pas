{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the commands get, set and typeof              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.VariableCommands;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.GameState.Intf, DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   Read, write and type of the variables of the game (old Cmd_Get, Cmd_Set, Cmd_TypeOf).
  ///   What is not a variable may still be a command: "get dir" runs "dir" without parameters
  /// </summary>
  TConsoleVariableCommands = class
  private
    FRegistry: ICommandRegistry;
    FVariables: IConsoleVariableSource;
    FOutput: IConsoleOutput;
    FLog: ILog;
    FGame: IGameContext;
    function CanSet(const AVariable: IConsoleVariable): Boolean;
    function SettableNames: TArray<string>;
    function AllNames: TArray<string>;
    procedure WriteNames(const ANames: TArray<string>; const AIndent: string);
    procedure UnknownCommand;
  public
    constructor Create(const ARegistry: ICommandRegistry; const AVariables: IConsoleVariableSource;
      const AOutput: IConsoleOutput; const ALog: ILog; const AGame: IGameContext);
    procedure GetVariable(const AName: string);
    /// <summary>AValue is the rest of the line: it may have spaces</summary>
    procedure SetVariable(const AName, AValue: string);
    procedure TypeOfVariable(const AName: string);
    /// <summary>Registers "get", "set" and "typeof"</summary>
    procedure Register;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Console.Types, DelphiDoom.Console.Text, DelphiDoom.Console.Numbers,
  DelphiDoom.Console.MaskMatcher;

const
  LINE_BREAK = #13#10;
  UNKNOWN_COMMAND = 'Unknown command' + LINE_BREAK;

{ TConsoleVariableCommands }

constructor TConsoleVariableCommands.Create(const ARegistry: ICommandRegistry;
  const AVariables: IConsoleVariableSource; const AOutput: IConsoleOutput; const ALog: ILog;
  const AGame: IGameContext);
begin
  inherited Create;
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create('ARegistry');
  if not Assigned(AVariables) then
    raise EArgumentNilException.Create('AVariables');
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  FRegistry := ARegistry;
  FVariables := AVariables;
  FOutput := AOutput;
  FLog := ALog;
  FGame := AGame;
end;

function TConsoleVariableCommands.CanSet(const AVariable: IConsoleVariable): Boolean;
begin
  if FGame.IsNetGame then
    Result := camNetwork in AVariable.Access
  else
    Result := camSinglePlayer in AVariable.Access;
end;

function TConsoleVariableCommands.SettableNames: TArray<string>;
var
  LIndex: Integer;
  LCount: Integer;
begin
  SetLength(Result, FVariables.Count);
  LCount := 0;
  for LIndex := 0 to FVariables.Count - 1 do
    if CanSet(FVariables.Item(LIndex)) then
    begin
      Result[LCount] := FVariables.Item(LIndex).Name;
      Inc(LCount);
    end;
  SetLength(Result, LCount);
end;

function TConsoleVariableCommands.AllNames: TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, FVariables.Count);
  for LIndex := 0 to FVariables.Count - 1 do
    Result[LIndex] := FVariables.Item(LIndex).Name;
end;

procedure TConsoleVariableCommands.WriteNames(const ANames: TArray<string>; const AIndent: string);
var
  LName: string;
begin
  for LName in ANames do
    FOutput.Write(AIndent + LName + LINE_BREAK);
end;

procedure TConsoleVariableCommands.UnknownCommand;
begin
  FOutput.Write(UNKNOWN_COMMAND);
end;

procedure TConsoleVariableCommands.GetVariable(const AName: string);
var
  LVariable: IConsoleVariable;
  LHandler: TConsoleCommandHandler;
  LMatch: string;
begin
  if AName = '' then
  begin
    FOutput.Write('Usage is:' + LINE_BREAK + 'get [name]' + LINE_BREAK);
    FOutput.Write(' Display the current settings of:' + LINE_BREAK);
    WriteNames(AllNames, '  ');
    Exit;
  end;

  if Pos('*', AName) > 0 then
  begin
    for LMatch in TConsoleMaskMatcher.Filter(AllNames, AName) do
      GetVariable(LMatch);
    Exit;
  end;

  LVariable := FVariables.Find(TConsoleText.LowerCase(AName));
  if Assigned(LVariable) then
  begin
    case LVariable.Kind of
      cvkInteger:
        FOutput.Write(Format('%s=%d', [AName, LVariable.GetInteger]) + LINE_BREAK);
      cvkBoolean:
        if LVariable.GetBoolean then
          FOutput.Write(AName + '=ON' + LINE_BREAK)
        else
          FOutput.Write(AName + '=OFF' + LINE_BREAK);
      cvkString:
        FOutput.Write(AName + '=' + LVariable.GetString + LINE_BREAK);
    end;
    Exit;
  end;

  if FRegistry.Find(AName, LHandler) then
  begin
    LHandler('', '');
    Exit;
  end;

  UnknownCommand;
end;

procedure TConsoleVariableCommands.SetVariable(const AName, AValue: string);
var
  LVariable: IConsoleVariable;
  LHandler: TConsoleCommandHandler;
begin
  if AName = '' then
  begin
    FOutput.Write('Usage is:' + LINE_BREAK + 'set [name] [value]' + LINE_BREAK);
    FOutput.Write(' Configures the following settings:' + LINE_BREAK);
    WriteNames(SettableNames, '  ');
    Exit;
  end;

  if Pos('*', AName) > 0 then
  begin
    WriteNames(TConsoleMaskMatcher.Filter(SettableNames, AName), '');
    Exit;
  end;

  if AValue = '' then
  begin
    FOutput.Write('Please give the value to set ' + AName + LINE_BREAK);
    Exit;
  end;

  LVariable := FVariables.Find(TConsoleText.LowerCase(AName));
  if Assigned(LVariable) then
  begin
    if CanSet(LVariable) then
    begin
      case LVariable.Kind of
        cvkInteger:
          LVariable.SetInteger(TConsoleNumbers.ParseInteger(AValue));
        cvkBoolean:
          LVariable.SetBoolean(TConsoleNumbers.EvaluateBoolean(AValue, LVariable.GetBoolean));
        cvkString:
          LVariable.SetString(AValue);
      end;
    end
    else if LVariable.Access = [] then
      FLog.Warning('Can not set readonly variable: ' + AName + LINE_BREAK)
    else if LVariable.Access = [camSinglePlayer] then
      FLog.Warning('Can not set variable: ' + AName + ' during network game' + LINE_BREAK);
    Exit;
  end;

  if FRegistry.Find(AName, LHandler) then
  begin
    LHandler(AValue, '');
    Exit;
  end;

  UnknownCommand;
end;

procedure TConsoleVariableCommands.TypeOfVariable(const AName: string);
var
  LVariable: IConsoleVariable;
  LMatch: string;
begin
  if AName = '' then
  begin
    FOutput.Write('Usage is:' + LINE_BREAK + 'typeof [name]' + LINE_BREAK);
    FOutput.Write(' Display the type of variable.' + LINE_BREAK);
  end;

  if Pos('*', AName) > 0 then
  begin
    for LMatch in TConsoleMaskMatcher.Filter(AllNames, AName) do
      TypeOfVariable(LMatch);
    Exit;
  end;

  LVariable := FVariables.Find(TConsoleText.LowerCase(AName));
  if Assigned(LVariable) then
  begin
    case LVariable.Kind of
      cvkInteger:
        FOutput.Write(AName + ' is integer' + LINE_BREAK);
      cvkBoolean:
        FOutput.Write(AName + ' is boolean' + LINE_BREAK);
      cvkString:
        FOutput.Write(AName + ' is string' + LINE_BREAK);
    end;
    Exit;
  end;

  FOutput.Write('Unknown variable: ' + AName + LINE_BREAK);
end;

procedure TConsoleVariableCommands.Register;
begin
  FRegistry.Add('set',
    procedure(const AParam1, AParam2: string)
    begin
      SetVariable(AParam1, AParam2);
    end);
  FRegistry.Add('get',
    procedure(const AParam1, AParam2: string)
    begin
      GetVariable(AParam1);
    end);
  FRegistry.Add('typeof',
    procedure(const AParam1, AParam2: string)
    begin
      TypeOfVariable(AParam1);
    end);
end;

end.
