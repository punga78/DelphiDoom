{******************************************************************************}
{                                                                              }
{  DelphiDoom: scenario player of the Quake III profile of the console         }
{                                                                              }
{  Runs a scenario (Tests\Data\Console\Q3\*.scn) on the Delphi classes and     }
{  writes the lines that Tools\Verifica\113q3\driver.c writes for the real     }
{  cmd.c and cvar.c of Quake III.                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Q3.Scenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Console.Q3.Types,
  DelphiDoom.Console.Q3.CVar, DelphiDoom.Console.Q3.Intf, DelphiDoom.Console.Q3.Factory,
  DelphiDoom.Tests.Console.Q3.Fakes;

type
  TQ3ScenarioPlayer = class
  strict private
    FLog: TFakeQ3Log;
    FLogIntf: IQ3ConsoleLog;
    FFiles: TFakeQ3Files;
    FFilesIntf: IQ3FileSystem;
    FConsole: TQ3Console;
    FOutput: TStringList;
    FVmCvars: array[0..15] of TQ3VmCvar;
    class function Escape(const AText: AnsiString): string; static;
    class function Unescape(const AText: string): AnsiString; static;
    class function FloatBits(AValue: Single): Cardinal; static;
    procedure Probe;
    procedure ListArguments(const APrefix: string);
    procedure Flush;
    procedure PrintCVar(AVar: TQ3CVar);
    procedure PrintVm(const APrefix: string; const AVm: TQ3VmCvar);
    procedure RunOperation(const AFields: TArray<AnsiString>);
  public
    /// <summary>The lines of the scenario file, as the driver writes them (the caller frees the list)</summary>
    function Run(const AFileName: string): TStringList;
  end;

implementation

{ TQ3ScenarioPlayer }

class function TQ3ScenarioPlayer.Escape(const AText: AnsiString): string;
var
  LIndex: Integer;
  LByte: Byte;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
  begin
    LByte := Ord(AText[LIndex]);
    if LByte = 10 then
      Result := Result + '\n'
    else if LByte = Ord('\') then
      Result := Result + '\\'
    else if (LByte < 32) or (LByte > 126) then
      Result := Result + '\x' + IntToHex(LByte, 2)
    else
      Result := Result + Chr(LByte);
  end;
end;

class function TQ3ScenarioPlayer.Unescape(const AText: string): AnsiString;
var
  LIndex: Integer;
  LChar: Char;
begin
  Result := '';
  LIndex := 1;
  while LIndex <= Length(AText) do
  begin
    LChar := AText[LIndex];
    if (LChar = '\') and (LIndex < Length(AText)) then
    begin
      Inc(LIndex);
      case AText[LIndex] of
        'n': Result := Result + #10;
        't': Result := Result + #9;
        'r': Result := Result + #13;
        'x':
          if LIndex + 2 <= Length(AText) then
          begin
            Result := Result + AnsiChar(StrToInt('$' + Copy(AText, LIndex + 1, 2)));
            Inc(LIndex, 2);
          end
          else
            Result := Result + 'x';
      else
        Result := Result + AnsiChar(AText[LIndex]);
      end;
    end
    else
      Result := Result + AnsiChar(LChar);
    Inc(LIndex);
  end;
end;

class function TQ3ScenarioPlayer.FloatBits(AValue: Single): Cardinal;
begin
  Result := PCardinal(@AValue)^;
end;

procedure TQ3ScenarioPlayer.Flush;
var
  LText: string;
begin
  LText := FLog.TakePrinted;
  if LText <> '' then
    FOutput.Add('P: ' + Escape(AnsiString(LText)));
  LText := FLog.TakeDeveloper;
  if LText <> '' then
    FOutput.Add('D: ' + Escape(AnsiString(LText)));
end;

procedure TQ3ScenarioPlayer.ListArguments(const APrefix: string);
var
  LText: AnsiString;
  LIndex: Integer;
begin
  LText := AnsiString(IntToStr(FConsole.Arguments.Count));
  for LIndex := 0 to FConsole.Arguments.Count - 1 do
    LText := LText + '|' + FConsole.Arguments.Argv(LIndex);
  FOutput.Add(APrefix + Escape(LText));
end;

procedure TQ3ScenarioPlayer.Probe;
begin
  ListArguments('A: ');
  FOutput.Add('R: ' + Escape(FConsole.Arguments.Args));
  FOutput.Add('C: ' + Escape(FConsole.Arguments.Cmd));
end;

procedure TQ3ScenarioPlayer.PrintCVar(AVar: TQ3CVar);
var
  LLatched: AnsiString;
  LText: AnsiString;
begin
  if not Assigned(AVar) then
  begin
    FOutput.Add('G: <none>');
    Exit;
  end;
  if AVar.HasLatched then
    LLatched := AVar.LatchedString
  else
    LLatched := '~';
  LText := AVar.Name + '|' + AVar.StringValue + '|' + AVar.ResetString + '|' + LLatched + '|' +
    AnsiString(IntToStr(AVar.Flags)) + '|' + AnsiString(IntToStr(Ord(AVar.Modified))) + '|' +
    AnsiString(IntToStr(AVar.ModificationCount)) + '|' + AnsiString(IntToHex(FloatBits(AVar.Value), 8)) + '|' +
    AnsiString(IntToStr(AVar.IntegerValue));
  FOutput.Add('G: ' + Escape(LText));
end;

procedure TQ3ScenarioPlayer.PrintVm(const APrefix: string; const AVm: TQ3VmCvar);
begin
  FOutput.Add(APrefix + Escape(AnsiString(Format('%d|%d|%s|%d|', [AVm.Handle, AVm.ModificationCount,
    IntToHex(FloatBits(AVm.Value), 8), AVm.IntegerValue])) + AVm.StringValue));
end;

procedure TQ3ScenarioPlayer.RunOperation(const AFields: TArray<AnsiString>);
var
  LOperation: string;
  LVar: TQ3CVar;
  LSlot: Integer;
  LText: AnsiString;
begin
  LOperation := string(AFields[0]);
  if LOperation = 'init' then
    FConsole.Init
  else if LOperation = 'addcmd' then
  begin
    if AFields[2] = 'probe' then
      FConsole.Commands.AddCommand(AFields[1], Probe)
    else
      FConsole.Commands.AddCommand(AFields[1], nil);
  end
  else if LOperation = 'rmcmd' then
    FConsole.Commands.RemoveCommand(AFields[1])
  else if LOperation = 'cmd' then
    FConsole.Commands.ExecuteString(AFields[1])
  else if LOperation = 'now' then
    FConsole.Buffer.ExecuteText(qeNow, AFields[1])
  else if LOperation = 'append' then
    FConsole.Buffer.ExecuteText(qeAppend, AFields[1])
  else if LOperation = 'insert' then
    FConsole.Buffer.ExecuteText(qeInsert, AFields[1])
  else if LOperation = 'run' then
    FConsole.Buffer.Execute
  else if LOperation = 'pending' then
  begin
    FOutput.Add('B: ' + Escape(FConsole.Buffer.Pending));
    FOutput.Add('W: ' + IntToStr(FConsole.Buffer.Wait));
  end
  else if LOperation = 'tok' then
  begin
    FConsole.Arguments.Tokenize(AFields[1]);
    ListArguments('T: ');
    FOutput.Add('R: ' + Escape(FConsole.Arguments.Args));
    FOutput.Add('F: ' + Escape(FConsole.Arguments.ArgsFrom(1)));
    FOutput.Add('C: ' + Escape(FConsole.Arguments.Cmd));
    FOutput.Add('O: [' + string(FConsole.Arguments.Argv(99)) + ']');
  end
  else if LOperation = 'file' then
    FFiles.AddFile(AFields[1], AFields[2])
  else if LOperation = 'get' then
    PrintCVar(FConsole.CVars.Get(AFields[1], AFields[2], StrToInt(string(AFields[3]))))
  else if LOperation = 'set' then
  begin
    FConsole.CVars.SetValueText(AFields[1], AFields[2]);
    PrintCVar(FConsole.CVars.Find(AFields[1]));
  end
  else if LOperation = 'setl' then
  begin
    FConsole.CVars.SetLatched(AFields[1], AFields[2]);
    PrintCVar(FConsole.CVars.Find(AFields[1]));
  end
  else if LOperation = 'set2' then
  begin
    FConsole.CVars.Set2(AFields[1], AFields[2], StrToInt(string(AFields[3])) <> 0);
    PrintCVar(FConsole.CVars.Find(AFields[1]));
  end
  else if LOperation = 'setv' then
  begin
    FConsole.CVars.SetNumber(AFields[1], Single(TIdCNumbers.Atof(AFields[2])));
    PrintCVar(FConsole.CVars.Find(AFields[1]));
  end
  else if LOperation = 'reset' then
  begin
    FConsole.CVars.Reset(AFields[1]);
    PrintCVar(FConsole.CVars.Find(AFields[1]));
  end
  else if LOperation = 'cheat' then
    FConsole.CVars.SetCheatState
  else if LOperation = 'clearmod' then
    FConsole.CVars.ModifiedFlags := 0
  else if LOperation = 'val' then
  begin
    LText := AnsiString(IntToHex(FloatBits(FConsole.CVars.VariableValue(AFields[1])), 8) + '|' +
      IntToStr(FConsole.CVars.VariableIntegerValue(AFields[1])) + '|') + FConsole.CVars.VariableString(AFields[1]);
    FOutput.Add('V: ' + Escape(LText));
  end
  else if LOperation = 'vbuf' then
    FOutput.Add('V: ' + Escape(FConsole.CVars.VariableStringBuffer(AFields[1], StrToInt(string(AFields[2])))))
  else if LOperation = 'dump' then
  begin
    for LVar in FConsole.CVars.Variables do
      PrintCVar(LVar);
    FOutput.Add(Format('M: %d N: %d', [FConsole.CVars.ModifiedFlags, FConsole.CVars.IndexCount]));
  end
  else if LOperation = 'write' then
    FOutput.Add('F: ' + Escape(FConsole.CVars.WriteVariables))
  else if LOperation = 'info' then
    FOutput.Add('I: ' + Escape(FConsole.CVars.InfoString(StrToInt(string(AFields[1])))))
  else if LOperation = 'infobig' then
    FOutput.Add('I: ' + Escape(FConsole.CVars.InfoStringBig(StrToInt(string(AFields[1])))))
  else if LOperation = 'vmreg' then
  begin
    LSlot := StrToInt(string(AFields[1]));
    FConsole.CVars.Register(FVmCvars[LSlot], AFields[2], AFields[3], StrToInt(string(AFields[4])));
    PrintVm('Y: ', FVmCvars[LSlot]);
  end
  else if LOperation = 'vmupd' then
  begin
    LSlot := StrToInt(string(AFields[1]));
    FConsole.CVars.Update(FVmCvars[LSlot]);
    PrintVm('Y: ', FVmCvars[LSlot]);
  end
  else
    raise Exception.CreateFmt('Unknown operation %s', [LOperation]);
end;

function TQ3ScenarioPlayer.Run(const AFileName: string): TStringList;
var
  LLines: TStringList;
  LLine: string;
  LRaw: string;
  LParts: TArray<string>;
  LFields: TArray<AnsiString>;
  LIndex: Integer;
  LShown: string;
begin
  Result := TStringList.Create;
  FOutput := Result;
  FLog := TFakeQ3Log.Create;
  FLogIntf := FLog;
  FFiles := TFakeQ3Files.Create;
  FFilesIntf := FFiles;
  FConsole := TQ3Console.Create(FLogIntf, FFilesIntf, TFakeQ3Unhandled.Create(FLogIntf),
    TFakeQ3InfoWriter.Create(FLogIntf));
  LLines := TStringList.Create;
  try
    // the bytes of the file are the characters, one to one
    LLines.LoadFromFile(AFileName, TEncoding.ANSI);
    for LLine in LLines do
    begin
      LRaw := LLine;
      if (LRaw = '') or (LRaw[1] = '#') then
        Continue;
      LShown := StringReplace(LRaw, #9, '\t', [rfReplaceAll]);
      Result.Add('> ' + LShown);
      LParts := LRaw.Split([#9]);
      SetLength(LFields, 8);
      for LIndex := 0 to 7 do
        if LIndex < Length(LParts) then
          LFields[LIndex] := Unescape(LParts[LIndex])
        else
          LFields[LIndex] := '';
      RunOperation(LFields);
      Flush;
    end;
  finally
    LLines.Free;
    FConsole.Free;
    FConsole := nil;
    FFilesIntf := nil;
    FLogIntf := nil;
  end;
end;

end.
