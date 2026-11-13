{******************************************************************************}
{                                                                              }
{  DelphiDoom: test support of the bot AI library - the scenario of the        }
{  parity test of characters, weights, weapons and structures (the commands of }
{  Tools\Verifica\123\botgen.c)                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.AiScenarioRunner;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Random.MsvcRand,
  DelphiDoom.BotAi.LibVars.Table, DelphiDoom.BotAi.Character.Intf, DelphiDoom.BotAi.Weight.Intf,
  DelphiDoom.BotAi.Weight.Config, DelphiDoom.BotAi.Weight.Separator, DelphiDoom.BotAi.Weapon.Intf,
  DelphiDoom.BotAi.Weapon.Types, DelphiDoom.BotAi.Weapon.Config, DelphiDoom.BotAi.Weapon.Definitions, DelphiDoom.BotAi.Struct.Types,
  DelphiDoom.Tests.BotAi.Support;

type
  /// <summary>
  ///   Runs the lines of Tests\Data\BotAi\botscenario.txt on the Delphi classes and writes what the C tool writes:
  ///   the line of the command, then its results; what the library prints and logs in the order it does. The
  ///   floats are written as their bits. The line "skill %d" of BotDumpCharacter (undefined in the C) is not written.
  /// </summary>
  TBotAiScenarioRunner = class
  strict private
    FOutput: TStringList;
    FImport: TFakeBotImport;
    FImportRef: IInterface;
    FLibVars: TBotLibVarTable;
    FLibVarsRef: IInterface;
    FRandom: TBotMsvcRandom;
    FRandomRef: IInterface;
    FFiles: IBotFileSource;
    FCharacters: IBotCharacterSystem;
    FWeights: IBotWeightCache;
    FWeapons: IBotWeaponSystem;
    FDefinitions: TBotWeaponDefinitions;
    FSubDefinition: TBotStructDefinition;
    FTestDefinition: TBotStructDefinition;
    FSlots: array[0..15] of TBotWeightConfig;
    FArgs: TArray<AnsiString>;
    procedure Flush;
    procedure Emit(const ALine: string);
    function Arg(const AIndex: Integer): AnsiString;
    function Num(const AIndex: Integer): Int64;
    function FloatArg(const AIndex: Integer): Single;
    function Inventory(const AFirst: Integer): TArray<Integer>;
    procedure DumpStruct(const ADefinition: TBotStructDefinition; const ABytes: TBytes);
    procedure DumpSeparator(const ASeparator: TBotFuzzySeparator; const ADepth: Integer);
    procedure DumpWeights(const ASlot: Integer);
    procedure DumpCharacter(const AHandle: Integer);
    procedure DumpWeaponInfo(const APrefix: string; const AInfo: TBotWeaponInfo);
    procedure DumpWeaponConfig;
    procedure RunStruct(const AFile: AnsiString);
    procedure Execute(const ALine: AnsiString);
  public
    class function FloatText(const AValue: Single): string; static;
    constructor Create(const AFiles: IBotFileSource);
    destructor Destroy; override;
    /// <summary>Runs every line of the scenario; the output is in <c>Output</c></summary>
    procedure Run(const AScenario: TStrings);
    property Output: TStringList read FOutput;
  end;

implementation

uses
  System.Math, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Character.Factory,
  DelphiDoom.BotAi.Weight.Factory, DelphiDoom.BotAi.Weapon.Factory, DelphiDoom.BotAi.Weight.Evaluator,
  DelphiDoom.BotAi.Weight.Scaler, DelphiDoom.BotAi.Weight.Breeder, DelphiDoom.BotAi.Character.Data,
  DelphiDoom.BotAi.Character.Types, DelphiDoom.BotAi.Struct.Reader, DelphiDoom.BotAi.Struct.Writer,
  DelphiDoom.BotAi.Chat.Source, DelphiDoom.BotAi.Text.CFormat, DelphiDoom.Tests.BotAi.ScenarioRunner;

function Fnv(const ABytes: TBytes): Cardinal;
var
  LIndex: Integer;
begin
  Result := 2166136261;
  for LIndex := 0 to High(ABytes) do
    Result := (Result xor ABytes[LIndex]) * 16777619;
end;

{ TBotAiScenarioRunner }

class function TBotAiScenarioRunner.FloatText(const AValue: Single): string;
var
  LBits: Cardinal;
begin
  LBits := PCardinal(@AValue)^;
  if IsNan(AValue) then
    Result := Format('%.8X(nan)', [LBits])
  else if IsInfinite(AValue) then
    begin
      if AValue > 0 then
        Result := Format('%.8X(inf)', [LBits])
      else
        Result := Format('%.8X(-inf)', [LBits]);
    end
  else
    Result := Format('%.8X(%s)', [LBits, string(TBotCFormat.Fixed6(AValue))]);
end;

constructor TBotAiScenarioRunner.Create(const AFiles: IBotFileSource);
var
  LSubFields: TArray<TBotFieldDefinition>;
  LFields: TArray<TBotFieldDefinition>;
begin
  inherited Create;
  FOutput := TStringList.Create;
  FImport := TFakeBotImport.Create;
  FImportRef := FImport;
  FLibVars := TBotLibVarTable.Create;
  FLibVarsRef := FLibVars;
  FRandom := TBotMsvcRandom.Create(1);
  FRandomRef := FRandom;
  FFiles := AFiles;
  FCharacters := TBotCharacterFactory.CreateCharacterSystem(FImport, AFiles, FLibVars);
  FWeights := TBotWeightFactory.CreateWeightCache(FImport, AFiles, FLibVars);
  FWeapons := TBotWeaponFactory.CreateWeaponSystem(FImport, AFiles, FLibVars, FWeights);
  FDefinitions := TBotWeaponDefinitions.Create;
  // the structure of botgen.c: packed, with every kind of field
  LSubFields := [TBotFieldDefinition.Make('x', 0, FT_INT), TBotFieldDefinition.Make('y', 4, FT_INT)];
  FSubDefinition := TBotStructDefinition.Create(8, LSubFields);
  LFields := [
    TBotFieldDefinition.Make('c', 0, FT_CHAR),
    TBotFieldDefinition.Make('uc', 1, FT_CHAR or FT_UNSIGNED),
    TBotFieldDefinition.Make('i', 2, FT_INT),
    TBotFieldDefinition.Make('ui', 6, FT_INT or FT_UNSIGNED),
    TBotFieldDefinition.Make('f', 10, FT_FLOAT),
    TBotFieldDefinition.Make('bf', 14, FT_FLOAT or FT_BOUNDED),
    TBotFieldDefinition.Make('bi', 18, FT_INT or FT_BOUNDED),
    TBotFieldDefinition.Make('s', 22, FT_STRING),
    TBotFieldDefinition.Make('a', 102, FT_FLOAT or FT_ARRAY, 3),
    TBotFieldDefinition.Make('ia', 114, FT_INT or FT_ARRAY, 3),
    TBotFieldDefinition.Make('sub', 126, FT_STRUCT),
    TBotFieldDefinition.Make('cb', 134, FT_CHAR or FT_BOUNDED)];
  LFields[5].FloatMin := -1.0;
  LFields[5].FloatMax := 2.5;
  LFields[6].FloatMin := -10.0;
  LFields[6].FloatMax := 10.0;
  LFields[10].SubStruct := FSubDefinition;
  LFields[11].FloatMin := -5.0;
  LFields[11].FloatMax := 5.0;
  FTestDefinition := TBotStructDefinition.Create(135, LFields);
end;

destructor TBotAiScenarioRunner.Destroy;
begin
  FTestDefinition.Free;
  FSubDefinition.Free;
  FDefinitions.Free;
  FWeapons := nil;
  FWeights := nil;
  FCharacters := nil;
  FFiles := nil;
  FRandomRef := nil;
  FLibVarsRef := nil;
  FImportRef := nil;
  FOutput.Free;
  inherited Destroy;
end;

procedure TBotAiScenarioRunner.Flush;
var
  LLine: string;
begin
  for LLine in FImport.Lines do
  begin
    // the C tool does not write the skill of BotDumpCharacter (a float printed with %d)
    if not LLine.StartsWith('L|skill ') then
      FOutput.Add(LLine);
  end;
  FImport.Lines.Clear;
end;

procedure TBotAiScenarioRunner.Emit(const ALine: string);
begin
  // what the library printed before comes first
  Flush;
  FOutput.Add(ALine);
end;

function TBotAiScenarioRunner.Arg(const AIndex: Integer): AnsiString;
begin
  if AIndex < Length(FArgs) then
    Result := FArgs[AIndex]
  else
    Result := '';
end;

function TBotAiScenarioRunner.Num(const AIndex: Integer): Int64;
var
  LText: string;
begin
  LText := Trim(string(Arg(AIndex)));
  if LText = '' then
    Exit(0);
  Result := StrToInt64(LText);
end;

function TBotAiScenarioRunner.FloatArg(const AIndex: Integer): Single;
var
  LText: string;
begin
  LText := Trim(string(Arg(AIndex)));
  if LText = '' then
    Exit(0);
  // atof gives a double, which is then converted to a float
  Result := StrToFloat(LText, TFormatSettings.Invariant);
end;

function TBotAiScenarioRunner.Inventory(const AFirst: Integer): TArray<Integer>;
var
  LIndex: Integer;
begin
  // 1024 integers, the rest zero
  SetLength(Result, 1024);
  for LIndex := AFirst to High(FArgs) do
  begin
    if LIndex - AFirst < 1024 then
      Result[LIndex - AFirst] := Integer(Num(LIndex));
  end;
end;

procedure TBotAiScenarioRunner.DumpStruct(const ADefinition: TBotStructDefinition; const ABytes: TBytes);
var
  LText: AnsiString;
  LLine: string;
  LIndex: Integer;
  LCode: Byte;
begin
  LText := TBotStructWriter.WriteStructure(ADefinition, ABytes);
  LLine := '';
  for LIndex := 1 to Length(LText) do
  begin
    LCode := Byte(LText[LIndex]);
    if (LCode < 32) or (LCode > 126) or (LCode = Ord('\')) then
      LLine := LLine + '\x' + IntToHex(LCode, 2)
    else
      LLine := LLine + Char(LCode);
    // the C tool starts a new line after every line feed
    if LCode = 10 then
    begin
      Emit(LLine);
      LLine := '';
    end;
  end;
  if LLine <> '' then
    Emit(LLine);
end;

procedure TBotAiScenarioRunner.DumpSeparator(const ASeparator: TBotFuzzySeparator; const ADepth: Integer);
var
  LCurrent: TBotFuzzySeparator;
begin
  LCurrent := ASeparator;
  while Assigned(LCurrent) do
  begin
    Emit(StringOfChar(' ', ADepth * 2) + Format('idx=%d val=%d type=%d w=%s min=%s max=%s', [LCurrent.Index,
      LCurrent.Value, LCurrent.WeightType, FloatText(LCurrent.Weight), FloatText(LCurrent.MinWeight),
      FloatText(LCurrent.MaxWeight)]));
    if Assigned(LCurrent.Child) then
      DumpSeparator(LCurrent.Child, ADepth + 1);
    LCurrent := LCurrent.Next;
  end;
end;

procedure TBotAiScenarioRunner.DumpWeights(const ASlot: Integer);
var
  LConfig: TBotWeightConfig;
  LIndex: Integer;
begin
  LConfig := FSlots[ASlot];
  if not Assigned(LConfig) then
  begin
    Emit('noweights');
    Exit;
  end;
  Emit(Format('weights n=%d file=%s', [LConfig.Count, EscapeBotText(LConfig.FileName)]));
  for LIndex := 0 to LConfig.Count - 1 do
  begin
    Emit(Format('w%d name=%s', [LIndex, EscapeBotText(LConfig.Names[LIndex])]));
    DumpSeparator(LConfig.FirstSeparator[LIndex], 1);
  end;
end;

procedure TBotAiScenarioRunner.DumpCharacter(const AHandle: Integer);
var
  LCharacter: TBotCharacter;
  LIndex: Integer;
begin
  LCharacter := FCharacters.FindCharacter(AHandle);
  if not Assigned(LCharacter) then
  begin
    Emit('nochar');
    Exit;
  end;
  Emit(Format('char file=%s skill=%s', [EscapeBotText(LCharacter.FileName), FloatText(LCharacter.Skill)]));
  for LIndex := 0 to MAX_CHARACTERISTICS do
  begin
    case LCharacter.Characteristics[LIndex].CharType of
      CT_INTEGER:
        Emit(Format('c%d int %d', [LIndex, LCharacter.Characteristics[LIndex].IntegerValue]));
      CT_FLOAT:
        Emit(Format('c%d float %s', [LIndex, FloatText(LCharacter.Characteristics[LIndex].FloatValue)]));
      CT_STRING:
        Emit(Format('c%d string %s', [LIndex, EscapeBotText(LCharacter.Characteristics[LIndex].StringValue)]));
    end;
  end;
end;

procedure TBotAiScenarioRunner.DumpWeaponInfo(const APrefix: string; const AInfo: TBotWeaponInfo);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, SizeOf(TBotWeaponInfo));
  Move(AInfo, LBytes[0], SizeOf(TBotWeaponInfo));
  Emit(APrefix + Format('weapon valid=%d hash=%.8X', [AInfo.Valid, Fnv(LBytes)]));
  DumpStruct(FDefinitions.Weapon, LBytes);
end;

procedure TBotAiScenarioRunner.DumpWeaponConfig;
var
  LConfig: TBotWeaponConfig;
  LIndex: Integer;
  LBytes: TBytes;
begin
  LConfig := FWeapons.Config;
  if not Assigned(LConfig) then
  begin
    Emit('noweaponconfig');
    Exit;
  end;
  Emit(Format('weaponconfig numweapons=%d numprojectiles=%d sizes=%d,%d', [LConfig.NumWeapons,
    LConfig.NumProjectiles, SizeOf(TBotWeaponInfo), SizeOf(TBotProjectileInfo)]));
  for LIndex := 0 to LConfig.NumProjectiles - 1 do
  begin
    SetLength(LBytes, SizeOf(TBotProjectileInfo));
    Move(LConfig.Projectiles[LIndex], LBytes[0], SizeOf(TBotProjectileInfo));
    Emit(Format('projectile %d hash=%.8X', [LIndex, Fnv(LBytes)]));
    DumpStruct(FDefinitions.Projectile, LBytes);
  end;
  for LIndex := 0 to LConfig.NumWeapons - 1 do
  begin
    if LConfig.Weapons[LIndex].Valid = 0 then
      Continue;
    // the line of the weapon starts with the slot
    DumpWeaponInfo(Format('slot %d ', [LIndex]), LConfig.Weapons[LIndex]);
  end;
end;

procedure TBotAiScenarioRunner.RunStruct(const AFile: AnsiString);
var
  LSource: TBotChatSource;
  LBytes: TBytes;
  LResult: Boolean;
begin
  LSource := TBotChatSource.Open(FImport, FFiles, AFile);
  if not Assigned(LSource) then
  begin
    Emit('struct nosource');
    Exit;
  end;
  SetLength(LBytes, 135);
  try
    LResult := TBotStructReader.ReadStructure(LSource, FTestDefinition, LBytes);
  finally
    LSource.Free;
  end;
  Emit(Format('struct=%d hash=%.8X', [Ord(LResult), Fnv(LBytes)]));
  DumpStruct(FTestDefinition, LBytes);
end;

procedure TBotAiScenarioRunner.Execute(const ALine: AnsiString);
var
  LParts: TArray<string>;
  LCommand: string;
  LIndex: Integer;
  LSlot: Integer;
  LText: AnsiString;
  LSame: Integer;
  LGone: TBotWeightConfig;
  LEvaluator: TBotFuzzyEvaluator;
  LBreeder: TBotWeightBreeder;
  LInfo: TBotWeaponInfo;
begin
  LParts := string(ALine).Split(['|']);
  SetLength(FArgs, Length(LParts) - 1);
  LCommand := Trim(string(TBotScenarioRunner.Unescape(AnsiString(LParts[0]))));
  for LIndex := 1 to High(LParts) do
    FArgs[LIndex - 1] := TBotScenarioRunner.Unescape(AnsiString(LParts[LIndex]));
  // ---- library variables
  if LCommand = 'libset' then
    FLibVars.SetText(Arg(0), Arg(1))
  else if LCommand = 'libget' then
    Emit(Format('libget text=%s value=%s changed=%d', [EscapeBotText(FLibVars.GetString(Arg(0))),
      FloatText(FLibVars.GetValue(Arg(0))), Ord(FLibVars.Changed(Arg(0)))]))
  else if LCommand = 'libval' then
    Emit('libval=' + FloatText(FLibVars.GetValueOrCreate(Arg(0), Arg(1))))
  else if LCommand = 'libstr' then
    Emit('libstr=' + EscapeBotText(FLibVars.GetStringOrCreate(Arg(0), Arg(1))))
  else if LCommand = 'libnotmod' then
    FLibVars.SetNotModified(Arg(0))
  else if LCommand = 'libconv' then
    Emit('libconv=' + FloatText(TBotLibVarTable.StringValue(Arg(0))))
  else if LCommand = 'struct' then
    RunStruct(Arg(0))
  // ---- characters
  else if LCommand = 'char' then
    Emit('char=' + IntToStr(FCharacters.LoadCharacter(Arg(0), FloatArg(1))))
  else if LCommand = 'chardump' then
    DumpCharacter(Integer(Num(0)))
  else if LCommand = 'charfree' then
    FCharacters.FreeCharacter(Integer(Num(0)))
  else if LCommand = 'charshutdown' then
    FCharacters.Shutdown
  else if LCommand = 'cfloat' then
    Emit('cfloat=' + FloatText(FCharacters.CharacteristicFloat(Integer(Num(0)), Integer(Num(1)))))
  else if LCommand = 'cbfloat' then
    Emit('cbfloat=' + FloatText(FCharacters.CharacteristicBoundedFloat(Integer(Num(0)), Integer(Num(1)),
      FloatArg(2), FloatArg(3))))
  else if LCommand = 'cint' then
    Emit('cint=' + IntToStr(FCharacters.CharacteristicInteger(Integer(Num(0)), Integer(Num(1)))))
  else if LCommand = 'cbint' then
    Emit('cbint=' + IntToStr(FCharacters.CharacteristicBoundedInteger(Integer(Num(0)), Integer(Num(1)),
      Integer(Num(2)), Integer(Num(3)))))
  else if LCommand = 'cstr' then
  begin
    LText := FCharacters.CharacteristicString(Integer(Num(0)), Integer(Num(1)), Integer(Num(2)));
    Emit('cstr=' + EscapeBotText(LText));
  end
  // ---- fuzzy weights
  else if LCommand = 'wread' then
  begin
    LSlot := Integer(Num(0));
    FSlots[LSlot] := FWeights.ReadWeightConfig(Arg(1));
    LSame := -1;
    for LIndex := 0 to High(FSlots) do
    begin
      if (LIndex <> LSlot) and Assigned(FSlots[LIndex]) and (FSlots[LIndex] = FSlots[LSlot]) then
      begin
        LSame := LIndex;
        Break;
      end;
    end;
    Emit(Format('wread ok=%d same=%d', [Ord(Assigned(FSlots[LSlot])), LSame]));
  end
  else if LCommand = 'wdump' then
    DumpWeights(Integer(Num(0)))
  else if LCommand = 'wfree' then
  begin
    LSlot := Integer(Num(0));
    LGone := FSlots[LSlot];
    if Assigned(LGone) then
      FWeights.FreeWeightConfig(LGone);
    if FLibVars.GetValue('bot_reloadcharacters') <> 0 then
    begin
      // a freed configuration is not read again
      for LIndex := 0 to High(FSlots) do
      begin
        if FSlots[LIndex] = LGone then
          FSlots[LIndex] := nil;
      end;
    end;
  end
  else if LCommand = 'wshutdown' then
  begin
    FWeights.Shutdown;
    for LIndex := 0 to High(FSlots) do
      FSlots[LIndex] := nil;
  end
  else if LCommand = 'wfind' then
    Emit('wfind=' + IntToStr(FSlots[Integer(Num(0))].FindFuzzyWeight(Arg(1))))
  else if LCommand = 'wfuzzy' then
  begin
    LEvaluator := TBotFuzzyEvaluator.Create(nil);
    try
      Emit('wfuzzy=' + FloatText(LEvaluator.FuzzyWeight(Inventory(2), FSlots[Integer(Num(0))], Integer(Num(1)))));
    finally
      LEvaluator.Free;
    end;
  end
  else if LCommand = 'wundecided' then
  begin
    FRandom.SetSeed(Cardinal(Num(2)));
    LEvaluator := TBotFuzzyEvaluator.Create(FRandom);
    try
      Emit('wundecided=' + FloatText(LEvaluator.FuzzyWeightUndecided(Inventory(3), FSlots[Integer(Num(0))],
        Integer(Num(1)))));
    finally
      LEvaluator.Free;
    end;
  end
  else if LCommand = 'wscale' then
    TBotWeightScaler.ScaleWeight(FSlots[Integer(Num(0))], Arg(1), FloatArg(2))
  else if LCommand = 'wrange' then
    TBotWeightScaler.ScaleBalanceRange(FSlots[Integer(Num(0))], FloatArg(1))
  else if LCommand = 'wevolve' then
  begin
    FRandom.SetSeed(Cardinal(Num(1)));
    LBreeder := TBotWeightBreeder.Create(FImport, FRandom);
    try
      LBreeder.Evolve(FSlots[Integer(Num(0))]);
    finally
      LBreeder.Free;
    end;
  end
  else if LCommand = 'wbreed' then
  begin
    LBreeder := TBotWeightBreeder.Create(FImport, FRandom);
    try
      LBreeder.Interbreed(FSlots[Integer(Num(0))], FSlots[Integer(Num(1))], FSlots[Integer(Num(2))]);
    finally
      LBreeder.Free;
    end;
  end
  // ---- weapons
  else if LCommand = 'wpsetup' then
    Emit('wpsetup=' + IntToStr(FWeapons.Setup))
  else if LCommand = 'wpdump' then
    DumpWeaponConfig
  else if LCommand = 'wpshutdown' then
    FWeapons.Shutdown
  else if LCommand = 'wpalloc' then
    Emit('wpalloc=' + IntToStr(FWeapons.AllocWeaponState))
  else if LCommand = 'wpfree' then
    FWeapons.FreeWeaponState(Integer(Num(0)))
  else if LCommand = 'wpreset' then
    FWeapons.ResetWeaponState(Integer(Num(0)))
  else if LCommand = 'wpweights' then
    Emit('wpweights=' + IntToStr(FWeapons.LoadWeaponWeights(Integer(Num(0)), Arg(1))))
  else if LCommand = 'wpbest' then
    Emit('wpbest=' + IntToStr(FWeapons.ChooseBestFightWeapon(Integer(Num(0)), Inventory(1))))
  else if LCommand = 'wpinfo' then
  begin
    FWeapons.GetWeaponInfo(Integer(Num(0)), Integer(Num(1)), LInfo);
    DumpWeaponInfo('wpinfo ', LInfo);
  end
  else
    Emit('UNKNOWN COMMAND ' + LCommand);
end;

procedure TBotAiScenarioRunner.Run(const AScenario: TStrings);
var
  LLine: string;
  LRaw: string;
begin
  for LRaw in AScenario do
  begin
    LLine := LRaw.TrimRight([#13, #10]);
    if (LLine = '') or (LLine[1] = ';') then
      Continue;
    Emit('> ' + EscapeBotText(AnsiString(LLine)));
    Execute(AnsiString(LLine));
  end;
  Flush;
end;

end.
