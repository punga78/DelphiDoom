{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the console library with the old c_cmds and m_cheat   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Golden;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.GameState.Intf,
  DelphiDoom.Console.Types, DelphiDoom.Console.Intf, DelphiDoom.Console.VariableCommands,
  DelphiDoom.Console.StandardCommands, DelphiDoom.Tests.Console.Fakes;

type
  /// <summary>
  ///   The files *.golden.txt in Tests\Data\Console are the answers of the OLD code (c_cmds,
  ///   Cmd_Get/Set/TypeOf of m_misc, C_ExecCommandFile and C_ExecCommands of c_con, m_cheat) on the
  ///   corpus of the files commands.txt and cheats.txt. The library must give the same text
  /// </summary>
  [TestFixture]
  [Category('console')]
  TTestConsoleGolden = class(TObject)
  private
    FOutput: TFakeOutput;
    FOutputIntf: IConsoleOutput;
    FGame: TFakeGameContext;
    FGameIntf: IGameContext;
    FVariables: TFakeVariableSource;
    FVariablesIntf: IConsoleVariableSource;
    FRegistry: ICommandRegistry;
    FInterpreter: IConsoleInterpreter;
    FRunner: IConsoleScriptRunner;
    FVariableCommands: TConsoleVariableCommands;
    FStandardCommands: TConsoleStandardCommands;
    FDataFolder: string;
    function DataPath(const AFileName: string): string;
    function Show(const AText: string): string;
    function Unescape(const AText: string): string;
    function Keys(const AText: string): string;
    function VarsText: string;
    procedure BuildConsole;
    procedure CompareWithGolden(const AGoldenName: string; const AActual: TStrings);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCommandsGiveTheSameTextAsTheOldCode;
    [Test]
    procedure TestCheatsGiveTheSameKeysAsTheOldCode;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Logging.Intf, DelphiDoom.Console.Factory, DelphiDoom.Console.CheatSequence,
  DelphiDoom.Console.CheatSequenceReader;

{ TTestConsoleGolden }

procedure TTestConsoleGolden.Setup;
begin
  FDataFolder := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Console'));
  BuildConsole;
end;

procedure TTestConsoleGolden.TearDown;
begin
  FStandardCommands.Free;
  FVariableCommands.Free;
  FRunner := nil;
  FInterpreter := nil;
  FRegistry := nil;
  FVariablesIntf := nil;
  FGameIntf := nil;
  FOutputIntf := nil;
end;

function TTestConsoleGolden.DataPath(const AFileName: string): string;
begin
  Result := TPath.Combine(FDataFolder, AFileName);
end;

procedure TTestConsoleGolden.BuildConsole;
var
  LLog: ILog;
  LFileSystem: IConsoleFileSystem;

  procedure Tag(const ANames, ATag: string);
  begin
    FRegistry.Add(ANames,
      procedure(const AParam1, AParam2: string)
      begin
        FOutput.Write(ATag + '<' + AParam1 + '|' + AParam2 + '>' + #13#10);
      end);
  end;

begin
  FOutput := TFakeOutput.Create;
  FOutputIntf := FOutput;
  FGame := TFakeGameContext.Create;
  FGameIntf := FGame;
  FVariables := TFakeVariableSource.Create;
  FVariablesIntf := FVariables;
  FVariables.AddInteger('fraglimit', [camSinglePlayer], 0);
  FVariables.AddInteger('skill', [camSinglePlayer, camNetwork], 2);
  FVariables.AddBoolean('showfps', [camSinglePlayer, camNetwork], False);
  FVariables.AddBoolean('autorun', [camNetwork], True);
  FVariables.AddString('playername', [camSinglePlayer, camNetwork], 'player');
  FVariables.AddString('version', [], 'v1');
  FVariables.AddInteger('screenwidth', [], 640);

  LLog := TFakeLog.Create(FOutput);
  FRegistry := TConsoleFactory.CreateRegistry;
  FInterpreter := TConsoleFactory.CreateInterpreter(FRegistry);
  LFileSystem := TFakeFileSystem.Create(FDataFolder);
  FRunner := TConsoleFactory.CreateScriptRunner(FInterpreter, LFileSystem, FOutputIntf, LLog);

  // the same registrations of the harness that ran the old code
  Tag('echo, say', 'echo');
  Tag('dir, ls', 'dir');
  Tag('multi1 , multi2,multi3', 'multi');
  Tag('  spaced  ', 'edge');
  Tag('', 'edge');
  Tag('a,,b', 'edge');
  Tag(',lead', 'edge');
  Tag('trail,', 'edge');
  Tag('MixedCase', 'edge');

  FVariableCommands := TConsoleFactory.CreateVariableCommands(FRegistry, FVariablesIntf,
    FOutputIntf, LLog, FGameIntf);
  FStandardCommands := TConsoleFactory.CreateStandardCommands(FRegistry, FOutputIntf, FRunner);
  FVariableCommands.Register;
  FStandardCommands.Register;
end;

function TTestConsoleGolden.Show(const AText: string): string;
begin
  Result := StringReplace(AText, #13#10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\r', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\l', [rfReplaceAll]);
  Result := StringReplace(Result, #9, '\t', [rfReplaceAll]);
end;

function TTestConsoleGolden.Unescape(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  LIndex := 1;
  while LIndex <= Length(AText) do
  begin
    if (AText[LIndex] = '\') and (LIndex < Length(AText)) then
    begin
      case AText[LIndex + 1] of
        't': Result := Result + #9;
        's': Result := Result + ' ';
        'r': Result := Result + #13;
        'n': Result := Result + #10;
        '\': Result := Result + '\';
      else
        Result := Result + AText[LIndex] + AText[LIndex + 1];
      end;
      Inc(LIndex, 2);
    end
    else
    begin
      Result := Result + AText[LIndex];
      Inc(LIndex);
    end;
  end;
end;

function TTestConsoleGolden.Keys(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  LIndex := 1;
  while LIndex <= Length(AText) do
  begin
    if (AText[LIndex] = '\') and (LIndex + 3 <= Length(AText)) and (AText[LIndex + 1] = 'x') then
    begin
      Result := Result + Chr(StrToInt('$' + Copy(AText, LIndex + 2, 2)));
      Inc(LIndex, 4);
    end
    else
    begin
      Result := Result + AText[LIndex];
      Inc(LIndex);
    end;
  end;
end;

function TTestConsoleGolden.VarsText: string;

  function Bool(const AName: string): Integer;
  begin
    Result := Ord(FVariablesIntf.Find(AName).GetBoolean);
  end;

begin
  Result := Format('vars: fraglimit=%d skill=%d showfps=%d autorun=%d playername=%s version=%s screenwidth=%d',
    [FVariablesIntf.Find('fraglimit').GetInteger, FVariablesIntf.Find('skill').GetInteger,
     Bool('showfps'), Bool('autorun'), FVariablesIntf.Find('playername').GetString,
     FVariablesIntf.Find('version').GetString, FVariablesIntf.Find('screenwidth').GetInteger]);
end;

procedure TTestConsoleGolden.CompareWithGolden(const AGoldenName: string; const AActual: TStrings);
var
  LExpected: TStringList;
  LIndex: Integer;
begin
  LExpected := TStringList.Create;
  try
    LExpected.LoadFromFile(DataPath(AGoldenName));
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      Assert.IsTrue(LIndex < AActual.Count, Format('%s: the output ends at line %d', [AGoldenName, LIndex + 1]));
      Assert.AreEqual(LExpected[LIndex], AActual[LIndex],
        Format('%s, line %d', [AGoldenName, LIndex + 1]));
    end;
    Assert.AreEqual(LExpected.Count, AActual.Count, AGoldenName + ': number of lines');
  finally
    LExpected.Free;
  end;
end;

procedure TTestConsoleGolden.TestCommandsGiveTheSameTextAsTheOldCode;
var
  LSource: TStringList;
  LResult: TStringList;
  LLine: string;
  LCommand: string;
  LLastVars: string;
  LVars: string;
  LOk: Boolean;
  LIndex: Integer;
begin
  LSource := TStringList.Create;
  LResult := TStringList.Create;
  try
    LSource.LoadFromFile(DataPath('commands.txt'));
    LLastVars := '';
    for LIndex := 0 to LSource.Count - 1 do
    begin
      LLine := LSource[LIndex];
      if (LLine = '') or (LLine[1] = '#') then
        Continue;
      if Pos('@net ', LLine) = 1 then
      begin
        FGame.NetGame := Copy(LLine, 6, 100) = '1';
        LResult.Add(LLine);
        Continue;
      end;
      if (Pos('@text ', LLine) = 1) or (LLine = '@text') then
      begin
        FOutput.Clear;
        FRunner.RunText(Unescape(Copy(LLine, 7, Length(LLine))));
        LResult.Add(LLine);
        LResult.Add(Show(FOutput.Text));
        Continue;
      end;
      LCommand := Unescape(LLine);
      FOutput.Clear;
      LOk := FInterpreter.Execute(LCommand);
      LResult.Add('> ' + LLine);
      LResult.Add(Show(StringReplace(FOutput.Text, UpperCase(ExcludeTrailingPathDelimiter(FDataFolder)),
        '<DIR>', [rfReplaceAll, rfIgnoreCase])));
      LResult.Add('=> ' + BoolToStr(LOk, True));
      LVars := VarsText;
      if LVars <> LLastVars then
      begin
        LResult.Add(LVars);
        LLastVars := LVars;
      end;
    end;
    CompareWithGolden('commands.golden.txt', LResult);
  finally
    LResult.Free;
    LSource.Free;
  end;
end;

procedure TTestConsoleGolden.TestCheatsGiveTheSameKeysAsTheOldCode;
var
  LSource: TStringList;
  LResult: TStringList;
  LNames: TStringList;
  LBytes: TStringList;
  LCheat: TCheatSequence;
  LLine: string;
  LRest: string;
  LName: string;
  LTyped: string;
  LOutput: string;
  LParam: string;
  LParts: TArray<string>;
  LSequence: TArray<Byte>;
  LIndex: Integer;
  LKey: Integer;
  LPosition: Integer;
  LCheats: array of TCheatSequence;
begin
  LSource := TStringList.Create;
  LResult := TStringList.Create;
  LNames := TStringList.Create;
  LBytes := TStringList.Create;
  try
    SetLength(LCheats, 64);
    LSource.LoadFromFile(DataPath('cheats.txt'));
    for LIndex := 0 to LSource.Count - 1 do
    begin
      LLine := LSource[LIndex];
      if (LLine = '') or (LLine[1] = '#') then
        Continue;
      if Pos('seq ', LLine) = 1 then
      begin
        LRest := Copy(LLine, 5, Length(LLine));
        LPosition := Pos(' ', LRest);
        LName := Copy(LRest, 1, LPosition - 1);
        LParts := Copy(LRest, LPosition + 1, Length(LRest)).Split([' '], TStringSplitOptions.ExcludeEmpty);
        SetLength(LSequence, Length(LParts));
        for LKey := 0 to High(LParts) do
          LSequence[LKey] := Byte(StrToInt('$' + LParts[LKey]));
        LCheat := TCheatSequence.Create(TCheatSequenceReader.FromBytes(LSequence));
        LCheats[LNames.Add(LName)] := LCheat;
        LResult.Add(LLine);
        Continue;
      end;
      if (Pos('feed ', LLine) = 1) or (Pos('more ', LLine) = 1) then
      begin
        LRest := Copy(LLine, 6, Length(LLine));
        LPosition := Pos(' ', LRest);
        if LPosition = 0 then
        begin
          LName := LRest;
          LTyped := '';
        end
        else
        begin
          LName := Copy(LRest, 1, LPosition - 1);
          LTyped := Keys(Copy(LRest, LPosition + 1, Length(LRest)));
        end;
        LCheat := LCheats[LNames.IndexOf(LName)];
        if Pos('feed ', LLine) = 1 then
          LCheat.Reset;
        LResult.Add(LLine);
        LOutput := '';
        for LKey := 1 to Length(LTyped) do
          case LCheat.Check(Ord(LTyped[LKey])) of
            csUnknown:
              LOutput := LOutput + Format(' %.2x:U', [Ord(LTyped[LKey])]);
            csPending:
              LOutput := LOutput + Format(' %.2x:P', [Ord(LTyped[LKey])]);
            csAcquired:
              begin
                LParam := '';
                for LPosition := 1 to Length(LCheat.Param) do
                  LParam := LParam + Format('%.2x', [Ord(LCheat.Param[LPosition])]);
                LOutput := LOutput + Format(' %.2x:A[%s]', [Ord(LTyped[LKey]), LParam]);
              end;
          end;
        LResult.Add(Trim(LOutput));
      end;
    end;
    CompareWithGolden('cheats.golden.txt', LResult);
  finally
    for LCheat in LCheats do
      LCheat.Free;
    LBytes.Free;
    LNames.Free;
    LResult.Free;
    LSource.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConsoleGolden);

end.
