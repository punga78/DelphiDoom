{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ACS machine - the scenarios                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Acs.Scenario;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Acs.Machine.Types, DelphiDoom.Tests.Acs.FakeWorld;

type
  TAcsScriptSnapshot = record
    Number: Integer;
    InfoIndex: Integer;
    DelayCount: Integer;
    StackPtr: Integer;
    IpOffset: Integer;
    Side: Integer;
    Removed: Boolean;
    Stack: array[0..ACS_STACK_DEPTH - 1] of Integer;
    Vars: array[0..ACS_SCRIPT_VARIABLE_COUNT - 1] of Integer;
  end;

  /// <summary>Everything that a machine keeps, in a form that the old and the new code share</summary>
  TAcsSnapshot = record
    States: TArray<Integer>;
    WaitValues: TArray<Integer>;
    MapVariables: TAcsMapVariables;
    WorldVariables: TAcsWorldVariables;
    Store: TAcsStore;
    Scripts: TArray<TAcsScriptSnapshot>;
  end;

  /// <summary>
  ///   What a scenario drives: the new machine, or the copy of the old interpreter that the
  ///   parity harness used to make the golden files. A tic runs every script that is not removed, in
  ///   the order they were added
  /// </summary>
  IAcsScenarioTarget = interface
    ['{5B8E2C17-9D40-4F63-A1E8-C07D3F52B946}']
    procedure Load(const ACode: TBytes);
    function Start(ANumber, AMap: Integer; const AArguments: TAcsArguments;
      AActivator, ALine: Pointer; ASide: Integer): Boolean;
    function Suspend(ANumber: Integer): Boolean;
    function Terminate(ANumber: Integer): Boolean;
    procedure CheckStore;
    procedure NewGame;
    procedure TagFinished(ATag: Integer);
    procedure PolyobjectFinished(APolyobject: Integer);
    procedure Tick;
    function Snapshot: TAcsSnapshot;
  end;

  /// <summary>
  ///   Runs a scenario (a text file of commands) on a target and gives the text of what
  ///   happened: every command, its result, what the scripts asked of the world and the state at the
  ///   end. Commands: source NAME (compile a script of Tests\Data\Acs), load, start N MAP A,B,C,D
  ///   [act=I] [line=I] [side=S], suspend N, terminate N, checkstore, newgame, tag N, poly N,
  ///   tick [N], busy SECTOR 0|1, polybusy N 0|1, game MAP TIME SKILL TYPE PLAYERS,
  ///   random A,B,C, dump
  /// </summary>
  TAcsScenarioRunner = class
  strict private
    FWorld: TFakeWorld;
    FTarget: IAcsScenarioTarget;
    FCompile: TFunc<string, TBytes>;
    FOutput: TStringList;
    FCode: TBytes;
    FLoggedLines: Integer;
    procedure FlushTrace;
    procedure Emit(const AText: string);
    procedure DumpState;
    function Value(const AWord: string; const AName: string; ADefault: Integer): Integer;
    procedure Execute(const ACommandLine: string);
    procedure ExecuteStart(const AWords: TArray<string>);
  public
    constructor Create(AWorld: TFakeWorld; const ATarget: IAcsScenarioTarget;
      const ACompile: TFunc<string, TBytes>);
    destructor Destroy; override;
    function Run(const ALines: TStrings): string;
  end;

implementation

{ TAcsScenarioRunner }

constructor TAcsScenarioRunner.Create(AWorld: TFakeWorld; const ATarget: IAcsScenarioTarget;
  const ACompile: TFunc<string, TBytes>);
begin
  inherited Create;
  FWorld := AWorld;
  FTarget := ATarget;
  FCompile := ACompile;
  FOutput := TStringList.Create;
end;

destructor TAcsScenarioRunner.Destroy;
begin
  FOutput.Free;
  inherited Destroy;
end;

procedure TAcsScenarioRunner.Emit(const AText: string);
begin
  FOutput.Add(AText);
end;

procedure TAcsScenarioRunner.FlushTrace;
begin
  while FLoggedLines < FWorld.Trace.Count do
  begin
    Emit('  ' + FWorld.Trace[FLoggedLines]);
    Inc(FLoggedLines);
  end;
end;

procedure TAcsScenarioRunner.DumpState;
var
  LSnapshot: TAcsSnapshot;
  LIndex: Integer;
  LLine: string;
  LEntry: Integer;
  LScript: TAcsScriptSnapshot;
begin
  LSnapshot := FTarget.Snapshot;
  Emit('state');
  for LIndex := 0 to High(LSnapshot.States) do
    Emit(Format('  script[%d] state=%d wait=%d',
      [LIndex, LSnapshot.States[LIndex], LSnapshot.WaitValues[LIndex]]));
  LLine := '  map';
  for LIndex := 0 to ACS_MAP_VARIABLE_COUNT - 1 do
    LLine := LLine + ' ' + IntToStr(LSnapshot.MapVariables[LIndex]);
  Emit(LLine);
  LLine := '  world';
  for LIndex := 0 to ACS_WORLD_VARIABLE_COUNT - 1 do
    LLine := LLine + ' ' + IntToStr(LSnapshot.WorldVariables[LIndex]);
  Emit(LLine);
  for LEntry := 0 to ACS_STORE_SIZE do
    if (LSnapshot.Store[LEntry].Map <> 0) then
      Emit(Format('  store[%d] map=%d script=%d args=%d,%d,%d,%d',
        [LEntry, LSnapshot.Store[LEntry].Map, LSnapshot.Store[LEntry].Script,
        LSnapshot.Store[LEntry].Args[0], LSnapshot.Store[LEntry].Args[1],
        LSnapshot.Store[LEntry].Args[2], LSnapshot.Store[LEntry].Args[3]]));
  for LIndex := 0 to High(LSnapshot.Scripts) do
  begin
    LScript := LSnapshot.Scripts[LIndex];
    LLine := Format('  thinker[%d] number=%d info=%d delay=%d ip=%d side=%d removed=%d stackptr=%d stack=',
      [LIndex, LScript.Number, LScript.InfoIndex, LScript.DelayCount, LScript.IpOffset,
      LScript.Side, Ord(LScript.Removed), LScript.StackPtr]);
    for LEntry := 0 to ACS_STACK_DEPTH - 1 do
      LLine := LLine + IntToStr(LScript.Stack[LEntry]) + ',';
    LLine := LLine + ' vars=';
    for LEntry := 0 to ACS_SCRIPT_VARIABLE_COUNT - 1 do
      LLine := LLine + IntToStr(LScript.Vars[LEntry]) + ',';
    Emit(LLine);
  end;
  for LLine in FWorld.Dump.Split([#10], TStringSplitOptions.ExcludeEmpty) do
    Emit('  ' + LLine);
end;

function TAcsScenarioRunner.Value(const AWord: string; const AName: string;
  ADefault: Integer): Integer;
begin
  if AWord.StartsWith(AName + '=') then
    Result := StrToInt(AWord.Substring(Length(AName) + 1))
  else
    Result := ADefault;
end;

procedure TAcsScenarioRunner.ExecuteStart(const AWords: TArray<string>);
var
  LArguments: TAcsArguments;
  LParts: TArray<string>;
  LIndex: Integer;
  LActivator: Integer;
  LLine: Integer;
  LSide: Integer;
  LActivatorPointer: Pointer;
  LLinePointer: Pointer;
begin
  LParts := AWords[3].Split([',']);
  for LIndex := 0 to ACS_ARGUMENT_COUNT - 1 do
    LArguments[LIndex] := Byte(StrToInt(LParts[LIndex]));
  LActivator := -1;
  LLine := -1;
  LSide := 0;
  for LIndex := 4 to High(AWords) do
  begin
    LActivator := Value(AWords[LIndex], 'act', LActivator);
    LLine := Value(AWords[LIndex], 'line', LLine);
    LSide := Value(AWords[LIndex], 'side', LSide);
  end;
  LActivatorPointer := nil;
  if LActivator >= 0 then
    LActivatorPointer := FWorld.Things[LActivator];
  LLinePointer := nil;
  if LLine >= 0 then
    LLinePointer := FWorld.Lines[LLine];
  Emit('= ' + BoolToStr(FTarget.Start(StrToInt(AWords[1]), StrToInt(AWords[2]), LArguments,
    LActivatorPointer, LLinePointer, LSide), True));
end;

procedure TAcsScenarioRunner.Execute(const ACommandLine: string);
var
  LWords: TArray<string>;
  LCommand: string;
  LIndex: Integer;
  LCount: Integer;
  LValues: TArray<string>;
  LNumbers: TArray<Integer>;
begin
  LWords := ACommandLine.Split([' '], TStringSplitOptions.ExcludeEmpty);
  if Length(LWords) = 0 then
    Exit;
  LCommand := LWords[0];
  if LCommand = 'source' then
    FCode := FCompile(LWords[1])
  else if LCommand = 'load' then
    FTarget.Load(FCode)
  else if LCommand = 'start' then
    ExecuteStart(LWords)
  else if LCommand = 'suspend' then
    Emit('= ' + BoolToStr(FTarget.Suspend(StrToInt(LWords[1])), True))
  else if LCommand = 'terminate' then
    Emit('= ' + BoolToStr(FTarget.Terminate(StrToInt(LWords[1])), True))
  else if LCommand = 'checkstore' then
    FTarget.CheckStore
  else if LCommand = 'newgame' then
    FTarget.NewGame
  else if LCommand = 'tag' then
    FTarget.TagFinished(StrToInt(LWords[1]))
  else if LCommand = 'poly' then
    FTarget.PolyobjectFinished(StrToInt(LWords[1]))
  else if LCommand = 'tick' then
  begin
    LCount := 1;
    if Length(LWords) > 1 then
      LCount := StrToInt(LWords[1]);
    for LIndex := 1 to LCount do
    begin
      FWorld.LevelTime := FWorld.LevelTime + 1;
      FTarget.Tick;
    end;
  end
  else if LCommand = 'busy' then
    FWorld.SetSectorBusy(StrToInt(LWords[1]), LWords[2] = '1')
  else if LCommand = 'polybusy' then
    FWorld.SetPolyobjectBusy(StrToInt(LWords[1]), LWords[2] = '1')
  else if LCommand = 'game' then
  begin
    FWorld.Map := StrToInt(LWords[1]);
    FWorld.LevelTime := StrToInt(LWords[2]);
    FWorld.Skill := StrToInt(LWords[3]);
    FWorld.GameType := StrToInt(LWords[4]);
    FWorld.PlayerCount := StrToInt(LWords[5]);
  end
  else if LCommand = 'random' then
  begin
    LValues := LWords[1].Split([',']);
    SetLength(LNumbers, Length(LValues));
    for LIndex := 0 to High(LValues) do
      LNumbers[LIndex] := StrToInt(LValues[LIndex]);
    FWorld.SetRandomValues(LNumbers);
  end
  else if LCommand = 'dump' then
    DumpState
  else
    raise Exception.CreateFmt('Unknown command of the scenario: %s', [LCommand]);
end;

function TAcsScenarioRunner.Run(const ALines: TStrings): string;
var
  LLine: string;
  LText: string;
begin
  FOutput.Clear;
  FLoggedLines := 0;
  for LLine in ALines do
  begin
    LText := LLine.Trim;
    if (LText = '') or LText.StartsWith('#') then
      Continue;
    Emit('> ' + LText);
    try
      Execute(LText);
    except
      on E: Exception do
        Emit('! ' + E.ClassName);
    end;
    FlushTrace;
  end;
  Emit('end');
  DumpState;
  Result := FOutput.Text;
end;

end.
