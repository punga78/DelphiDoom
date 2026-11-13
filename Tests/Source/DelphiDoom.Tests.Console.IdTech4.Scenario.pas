{******************************************************************************}
{                                                                              }
{  DelphiDoom: player of the scenarios of the idTech 4 console                 }
{                                                                              }
{  Plays a scenario file (Tests\Data\Console\IdTech4\*.scn, see README.md      }
{  there) on the Delphi classes and gives the same lines as the harness of     }
{  the real C++ code gives.                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.IdTech4.Scenario;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.IdLib.Text.CmdArgs, DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CmdSystem.Completions,
  DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.Console.IdTech4.Factory, DelphiDoom.Tests.Console.IdTech4.Fakes;

type
  /// <summary>Writes what is printed and warned into the lines of the player ("P: text", "W: text")</summary>
  TScenarioLog = class(TInterfacedObject, IIdLibLog)
  strict private
    FOutput: TStrings;
  public
    constructor Create(const AOutput: TStrings);
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
  end;

  TIdTech4ScenarioPlayer = class
  strict private
    FOutput: TStringList;
    FLog: IIdLibLog;
    FSession: TFakeSession;
    FSessionIntf: IConsoleSession;
    FFiles: TFakeIdFileSystem;
    FFilesIntf: IIdLibFileSystem;
    FConsole: TIdTech4Console;
    FCompletions: TObjectList<TCmdCompletions>;
    procedure Probe(const AArgs: TIdCmdArgs);
    procedure PrintCompletion(const AText: AnsiString);
    procedure PrintVariable(const AName: AnsiString);
    function Unescape(const AText: string): string;
    procedure Play(const AFields: TArray<string>);
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Plays the file and gives the lines of the output (the caller owns the list)</summary>
    function Run(const AFileName: string): TStringList;
  end;

implementation

uses
  DelphiDoom.Console.CVar.Types, DelphiDoom.Console.CVar.Variable, DelphiDoom.Console.CVar.Intf,
  DelphiDoom.Scanner.IdDict, DelphiDoom.Scanner.IdCNumbers;

function BitsOf(const AValue: Single): string;
var
  LBits: Cardinal;
begin
  Move(AValue, LBits, SizeOf(LBits));
  Result := LowerCase(IntToHex(LBits, 8));
end;

function Esc(const AText: AnsiString): string;
begin
  Result := TFakeIdLog.Escape(string(AText));
end;

{ TScenarioLog }

constructor TScenarioLog.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

procedure TScenarioLog.Printf(const AMessage: string);
begin
  FOutput.Add('P: ' + TFakeIdLog.Escape(AMessage));
end;

procedure TScenarioLog.Warning(const AMessage: string);
begin
  FOutput.Add('W: ' + TFakeIdLog.Escape(AMessage));
end;

{ TIdTech4ScenarioPlayer }

constructor TIdTech4ScenarioPlayer.Create;
begin
  inherited Create;
  FOutput := TStringList.Create;
  FLog := TScenarioLog.Create(FOutput);
  FSession := TFakeSession.Create;
  FSessionIntf := FSession;
  FFiles := TFakeIdFileSystem.Create;
  FFilesIntf := FFiles;
  FCompletions := TObjectList<TCmdCompletions>.Create(True);
  FConsole := TIdTech4Console.Create(FLog, FSessionIntf, FFilesIntf);
  FConsole.Init;
end;

destructor TIdTech4ScenarioPlayer.Destroy;
begin
  FConsole.Free;
  FCompletions.Free;
  FFilesIntf := nil;
  FSessionIntf := nil;
  FLog := nil;
  FOutput.Free;
  inherited Destroy;
end;

procedure TIdTech4ScenarioPlayer.Probe(const AArgs: TIdCmdArgs);
var
  LIndex: Integer;
  LLine: string;
begin
  LLine := 'A: ' + IntToStr(AArgs.Argc);
  for LIndex := 0 to AArgs.Argc - 1 do
    LLine := LLine + '|' + Esc(AArgs.Argv(LIndex));
  FOutput.Add(LLine);
end;

procedure TIdTech4ScenarioPlayer.PrintCompletion(const AText: AnsiString);
begin
  FOutput.Add('K: ' + Esc(AText));
end;

procedure TIdTech4ScenarioPlayer.PrintVariable(const AName: AnsiString);
var
  LVariable: TCVar;
begin
  LVariable := FConsole.CVars.Find(AName);
  if LVariable = nil then
  begin
    FOutput.Add('G: ' + Esc(AName) + ' none');
    Exit;
  end;
  FOutput.Add('G: ' + Esc(LVariable.Name) + '|' + Esc(LVariable.GetString) + '|' + IntToStr(LVariable.GetInteger) + '|' +
    BitsOf(LVariable.GetFloat) + '|' + IntToStr(LVariable.Flags) + '|' + BitsOf(LVariable.ValueMin) + '|' +
    BitsOf(LVariable.ValueMax) + '|' + Esc(LVariable.Description));
end;

function TIdTech4ScenarioPlayer.Unescape(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  LIndex := 1;
  while LIndex <= Length(AText) do
  begin
    if (AText[LIndex] = '\') and (LIndex < Length(AText)) then
    begin
      Inc(LIndex);
      case AText[LIndex] of
        'n': Result := Result + #10;
        'r': Result := Result + #13;
        't': Result := Result + #9;
        '0': Result := Result + #0;
      else
        Result := Result + AText[LIndex];
      end;
    end
    else
      Result := Result + AText[LIndex];
    Inc(LIndex);
  end;
end;

procedure TIdTech4ScenarioPlayer.Play(const AFields: TArray<string>);
var
  LOp: string;
  LFlags: Integer;
  LCompletions: TCmdCompletions;
  LVariable: TCVar;
  LStrings: TArray<AnsiString>;
  LParts: TArray<string>;
  LText: string;
  LArgs: TIdCmdArgs;
  LDict: TIdDict;
  LIndex: Integer;
  LKeyValue: TIdKeyValue;
  LLines: TArray<string>;

  function Field(const AIndex: Integer): string;
  begin
    if AIndex < Length(AFields) then
      Result := AFields[AIndex]
    else
      Result := '';
  end;

  function Number(const AIndex: Integer): Integer;
  begin
    Result := TIdCNumbers.Atoi(AnsiString(Field(AIndex)));
  end;

  function Real(const AIndex: Integer): Single;
  begin
    Result := TIdCNumbers.Atof(AnsiString(Field(AIndex)));
  end;

begin
  LOp := Field(0);
  if LOp = 'reg' then
    FConsole.CVars.Register(TCVarDefinition.Create(AnsiString(Field(1)), AnsiString(Field(2)), Number(3),
      AnsiString(Field(4))))
  else if LOp = 'regr' then
    FConsole.CVars.Register(TCVarDefinition.Create(AnsiString(Field(1)), AnsiString(Field(2)), Number(3),
      AnsiString(Field(4)), Real(5), Real(6)))
  else if LOp = 'regs' then
  begin
    LParts := Field(5).Split(['|']);
    SetLength(LStrings, Length(LParts));
    for LIndex := 0 to High(LParts) do
      LStrings[LIndex] := AnsiString(LParts[LIndex]);
    FConsole.CVars.Register(TCVarDefinition.Create(AnsiString(Field(1)), AnsiString(Field(2)), Number(3),
      AnsiString(Field(4)), LStrings));
  end
  else if LOp = 'cmd' then
    FConsole.Buffer.BufferCommandText(ceNow, AnsiString(Field(1)))
  else if LOp = 'append' then
    FConsole.Buffer.BufferCommandText(ceAppend, AnsiString(Field(1)))
  else if LOp = 'insert' then
    FConsole.Buffer.BufferCommandText(ceInsert, AnsiString(Field(1)))
  else if LOp = 'run' then
    FConsole.Buffer.ExecuteCommandBuffer
  else if LOp = 'get' then
    PrintVariable(AnsiString(Field(1)))
  else if LOp = 'setcvar' then
  begin
    LFlags := Number(4);
    if Field(1) = 's' then
      FConsole.CVars.SetCVarString(AnsiString(Field(2)), AnsiString(Field(3)), LFlags)
    else if Field(1) = 'b' then
      FConsole.CVars.SetCVarBool(AnsiString(Field(2)), Field(3) = '1', LFlags)
    else if Field(1) = 'i' then
      FConsole.CVars.SetCVarInteger(AnsiString(Field(2)), Number(3), LFlags)
    else if Field(1) = 'f' then
      FConsole.CVars.SetCVarFloat(AnsiString(Field(2)), Real(3), LFlags);
  end
  else if LOp = 'setv' then
  begin
    LVariable := FConsole.CVars.Find(AnsiString(Field(2)));
    if LVariable = nil then
      FOutput.Add('G: ' + Field(2) + ' none')
    else if Field(1) = 's' then
      LVariable.SetString(AnsiString(Field(3)))
    else if Field(1) = 'b' then
      LVariable.SetBool(Field(3) = '1')
    else if Field(1) = 'i' then
      LVariable.SetInteger(Number(3))
    else if Field(1) = 'f' then
      LVariable.SetFloat(Real(3));
  end
  else if LOp = 'getv' then
  begin
    LVariable := FConsole.CVars.Find(AnsiString(Field(1)));
    if LVariable = nil then
      FOutput.Add('V: |0|0')
    else
      FOutput.Add('V: ' + Esc(LVariable.GetString) + '|' + IntToStr(LVariable.GetInteger) + '|' +
        IntToStr(Ord(LVariable.GetBool)));
  end
  else if LOp = 'mp' then
    FSession.Multiplayer := Field(1) = '1'
  else if LOp = 'client' then
    FSession.ClientActive := Field(1) = '1'
  else if LOp = 'file' then
    FFiles.AddFile(Field(1), AnsiString(Field(2)))
  else if LOp = 'cmdlist' then
    FConsole.Commands.CommandCompletion(PrintCompletion)
  else if LOp = 'varlist' then
    FConsole.CVars.CommandCompletion(PrintCompletion)
  else if LOp = 'argc' then
    FConsole.Commands.ArgCompletion(AnsiString(Field(1)), PrintCompletion)
  else if LOp = 'vargc' then
    FConsole.CVars.ArgCompletion(AnsiString(Field(1)), PrintCompletion)
  else if LOp = 'modified' then
    FOutput.Add('M: ' + IntToStr(FConsole.CVars.GetModifiedFlags))
  else if LOp = 'setmod' then
    FConsole.CVars.SetModifiedFlags(Number(1))
  else if LOp = 'clearmod' then
    FConsole.CVars.ClearModifiedFlags(Number(1))
  else if LOp = 'resetflagged' then
    FConsole.CVars.ResetFlaggedVariables(Number(1))
  else if LOp = 'rmcompl' then
    FConsole.CVars.RemoveFlaggedAutoCompletion(Number(1))
  else if LOp = 'write' then
  begin
    LText := string(FConsole.CVars.WriteFlaggedVariables(Number(1), AnsiString(Field(2))));
    // one Printf of the file for each variable, each ended by a line feed
    LLines := LText.Split([#10]);
    for LIndex := 0 to High(LLines) - 1 do
      FOutput.Add('F: ' + TFakeIdLog.Escape(LLines[LIndex] + #10));
  end
  else if LOp = 'dict' then
  begin
    LDict := FConsole.CVars.MoveCVarsToDict(Number(1));
    for LIndex := 0 to LDict.GetNumKeyVals - 1 do
      if LDict.TryGetKeyVal(LIndex, LKeyValue) then
        FOutput.Add('D: ' + Esc(LKeyValue.Key) + '=' + Esc(LKeyValue.Value));
  end
  else if LOp = 'fromdict' then
  begin
    LDict := TIdDict.Create;
    try
      for LText in Field(1).Split([';']) do
        LDict.SetValue(AnsiString(Copy(LText, 1, Pos('=', LText) - 1)), AnsiString(Copy(LText, Pos('=', LText) + 1, MaxInt)));
      FConsole.CVars.SetCVarsFromDict(LDict);
    finally
      LDict.Free;
    end;
  end
  else if LOp = 'addcmd' then
  begin
    LFlags := Number(2);
    if Field(3) = 'probe' then
      FConsole.Commands.AddCommand(AnsiString(Field(1)), Probe, LFlags, 'probe command')
    else if Field(3) = 'nofunc' then
      FConsole.Commands.AddCommand(AnsiString(Field(1)), nil, LFlags, 'no function')
    else if Field(3) = 'compbool' then
    begin
      LCompletions := TCmdCompletions.Create;
      FCompletions.Add(LCompletions);
      FConsole.Commands.AddCommand(AnsiString(Field(1)), Probe, LFlags, 'bool completion', LCompletions.CompleteBoolean);
    end
    else if Field(3) = 'comp3' then
    begin
      LCompletions := TCmdCompletions.Create(1, 3);
      FCompletions.Add(LCompletions);
      FConsole.Commands.AddCommand(AnsiString(Field(1)), Probe, LFlags, 'int completion', LCompletions.CompleteInteger);
    end;
  end
  else if LOp = 'rmcmd' then
    FConsole.Commands.RemoveCommand(AnsiString(Field(1)))
  else if LOp = 'rmflagged' then
    FConsole.Commands.RemoveFlaggedCommands(Number(1))
  else if LOp = 'setup' then
  begin
    LArgs := TIdCmdArgs.Create;
    try
      LArgs.TokenizeString(AnsiString(Field(1)), False);
      FConsole.Buffer.SetupReloadEngine(LArgs);
    finally
      LArgs.Free;
    end;
  end
  else if LOp = 'post' then
    FOutput.Add('R: ' + IntToStr(Ord(FConsole.Buffer.PostReloadEngine)))
  else if LOp = 'tokenized' then
  begin
    LArgs := TIdCmdArgs.Create;
    try
      LArgs.TokenizeString(AnsiString(Field(1)), False);
      FConsole.Buffer.BufferCommandArgs(ceAppend, LArgs);
    finally
      LArgs.Free;
    end;
  end
  else
    FOutput.Add('? ' + LOp);
end;

function TIdTech4ScenarioPlayer.Run(const AFileName: string): TStringList;
var
  LLines: TStringList;
  LLine: string;
  LFields: TArray<string>;
  LIndex: Integer;
begin
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(AFileName);
    for LLine in LLines do
    begin
      if (LLine = '') or (LLine[1] = '#') then
        Continue;
      FOutput.Add('> ' + TFakeIdLog.Escape(LLine));
      LFields := LLine.Split([#9]);
      for LIndex := 1 to High(LFields) do
        LFields[LIndex] := Unescape(LFields[LIndex]);
      Play(LFields);
    end;
  finally
    LLines.Free;
  end;
  Result := TStringList.Create;
  Result.Assign(FOutput);
end;

end.
