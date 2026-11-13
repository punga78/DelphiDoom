{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotCharacterSystem, the characters of the bots        }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): the handles, the    }
{  cache and the loading of code\botlib\be_ai_char.c (BotCharacterFromHandle,  }
{  BotFreeCharacter2, BotFindCachedCharacter, BotLoadCachedCharacter,          }
{  BotLoadCharacterSkill, BotLoadCharacter, CheckCharacteristicIndex,          }
{  Characteristic_*, BotShutdownCharacters). Based on the Quake III Arena GPL  }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Character.System;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Character.Data, DelphiDoom.BotAi.Character.Intf,
  DelphiDoom.BotAi.Character.Loader;

type
  /// <summary>
  ///   botcharacters[MAX_CLIENTS + 1] is a field: the handles, the cache of the characters read from the
  ///   files (a character is found again by file and skill) and the state of nothing else. Defect kept: the
  ///   cached character of a file is changed in place when the default characteristics are copied in.
  /// </summary>
  TBotCharacterSystem = class(TInterfacedObject, IBotCharacterSystem)
  strict private
    FImport: IBotImport;
    FLibVars: IBotLibVars;
    FLoader: TBotCharacterLoader;
    FCharacters: array[1..64] of TBotCharacter;
    function CharacterFromHandle(const AHandle: Integer): TBotCharacter;
    function FreeHandle: Integer;
    procedure FreeCharacter2(const AHandle: Integer);
    function FindCachedCharacter(const AFileName: AnsiString; const ASkill: Single): Integer;
    function LoadCachedCharacter(const AFileName: AnsiString; const ASkill: Single; const AReload: Integer): Integer;
    function LoadCharacterSkill(const AFileName: AnsiString; const ASkill: Single): Integer;
    function InterpolateCharacters(const AFirst, ASecond: Integer; const ADesiredSkill: Single): Integer;
    function CheckCharacteristicIndex(const AHandle, AIndex: Integer): Boolean;
    class function FloatToInteger(const AValue: Single): Integer; static;
  public
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource; const ALibVars: IBotLibVars);
    destructor Destroy; override;
    function LoadCharacter(const AFileName: AnsiString; const ASkill: Single): Integer;
    procedure FreeCharacter(const AHandle: Integer);
    function CharacteristicFloat(const AHandle, AIndex: Integer): Single;
    function CharacteristicBoundedFloat(const AHandle, AIndex: Integer; const AMin, AMax: Single): Single;
    function CharacteristicInteger(const AHandle, AIndex: Integer): Integer;
    function CharacteristicBoundedInteger(const AHandle, AIndex, AMin, AMax: Integer): Integer;
    function CharacteristicString(const AHandle, AIndex, ASize: Integer): AnsiString;
    procedure Shutdown;
    function FindCharacter(const AHandle: Integer): TBotCharacter;
  end;

implementation

uses
  System.Math, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Character.Types, DelphiDoom.BotAi.Character.Interpolator,
  DelphiDoom.BotAi.Text.CFormat;

const
  // "fabs(skill1 - skill2) < 0.01" compares with a double
  SKILL_EPSILON: Double = 0.01;

{ TBotCharacterSystem }

constructor TBotCharacterSystem.Create(const AImport: IBotImport; const AFiles: IBotFileSource;
  const ALibVars: IBotLibVars);
begin
  inherited Create;
  FImport := AImport;
  FLibVars := ALibVars;
  FLoader := TBotCharacterLoader.Create(AImport, AFiles);
end;

destructor TBotCharacterSystem.Destroy;
var
  LHandle: Integer;
begin
  for LHandle := Low(FCharacters) to High(FCharacters) do
    FreeAndNil(FCharacters[LHandle]);
  FLoader.Free;
  inherited Destroy;
end;

function TBotCharacterSystem.FindCharacter(const AHandle: Integer): TBotCharacter;
begin
  if (AHandle < Low(FCharacters)) or (AHandle > High(FCharacters)) then
    Exit(nil);
  Result := FCharacters[AHandle];
end;

function TBotCharacterSystem.CharacterFromHandle(const AHandle: Integer): TBotCharacter;
begin
  if (AHandle <= 0) or (AHandle > BOT_MAX_CLIENTS) then
  begin
    FImport.Print(PRT_FATAL, 'character handle ' + TBotCFormat.Int(AHandle) + ' out of range'#10);
    Exit(nil);
  end;
  if not Assigned(FCharacters[AHandle]) then
  begin
    FImport.Print(PRT_FATAL, 'invalid character ' + TBotCFormat.Int(AHandle) + #10);
    Exit(nil);
  end;
  Result := FCharacters[AHandle];
end;

function TBotCharacterSystem.FreeHandle: Integer;
begin
  // find a free spot for a character: BOT_MAX_CLIENTS + 1 if there is none
  for Result := Low(FCharacters) to High(FCharacters) do
  begin
    if not Assigned(FCharacters[Result]) then
      Exit;
  end;
  Result := BOT_MAX_CLIENTS + 1;
end;

procedure TBotCharacterSystem.FreeCharacter2(const AHandle: Integer);
begin
  if (AHandle <= 0) or (AHandle > BOT_MAX_CLIENTS) then
  begin
    FImport.Print(PRT_FATAL, 'character handle ' + TBotCFormat.Int(AHandle) + ' out of range'#10);
    Exit;
  end;
  if not Assigned(FCharacters[AHandle]) then
  begin
    FImport.Print(PRT_FATAL, 'invalid character ' + TBotCFormat.Int(AHandle) + #10);
    Exit;
  end;
  FreeAndNil(FCharacters[AHandle]);
end;

procedure TBotCharacterSystem.FreeCharacter(const AHandle: Integer);
begin
  if FLibVars.GetValue('bot_reloadcharacters') = 0 then
    Exit;
  FreeCharacter2(AHandle);
end;

function TBotCharacterSystem.FindCachedCharacter(const AFileName: AnsiString; const ASkill: Single): Integer;
var
  LHandle: Integer;
  LDifference: Single;
begin
  for LHandle := Low(FCharacters) to High(FCharacters) do
  begin
    if not Assigned(FCharacters[LHandle]) then
      Continue;
    if FCharacters[LHandle].FileName <> AFileName then
      Continue;
    if ASkill < 0 then
      Exit(LHandle);
    LDifference := FCharacters[LHandle].Skill - ASkill;
    if Abs(Double(LDifference)) < SKILL_EPSILON then
      Exit(LHandle);
  end;
  Result := 0;
end;

function TBotCharacterSystem.LoadCachedCharacter(const AFileName: AnsiString; const ASkill: Single;
  const AReload: Integer): Integer;
var
  LHandle: Integer;
  LCachedHandle: Integer;
  LIntSkill: Integer;
  LCharacter: TBotCharacter;
begin
  // find a free spot for a character
  LHandle := FreeHandle;
  if LHandle > BOT_MAX_CLIENTS then
    Exit(0);
  // try to load a cached character with the given skill
  if AReload = 0 then
  begin
    LCachedHandle := FindCachedCharacter(AFileName, ASkill);
    if LCachedHandle <> 0 then
    begin
      FImport.Print(PRT_MESSAGE, 'loaded cached skill ' + TBotCFormat.Fixed6(ASkill) + ' from ' + AFileName + #10);
      Exit(LCachedHandle);
    end;
  end;
  LIntSkill := Trunc(Double(ASkill) + 0.5);
  // try to load the character with the given skill
  LCharacter := FLoader.Load(AFileName, LIntSkill);
  if Assigned(LCharacter) then
  begin
    FCharacters[LHandle] := LCharacter;
    FImport.Print(PRT_MESSAGE, 'loaded skill ' + TBotCFormat.Int(LIntSkill) + ' from ' + AFileName + #10);
    Exit(LHandle);
  end;
  FImport.Print(PRT_WARNING, 'couldn''t find skill ' + TBotCFormat.Int(LIntSkill) + ' in ' + AFileName + #10);
  if AReload = 0 then
  begin
    // try to load a cached default character with the given skill
    LCachedHandle := FindCachedCharacter(DEFAULT_CHARACTER, ASkill);
    if LCachedHandle <> 0 then
    begin
      FImport.Print(PRT_MESSAGE, 'loaded cached default skill ' + TBotCFormat.Int(LIntSkill) + ' from ' + AFileName + #10);
      Exit(LCachedHandle);
    end;
  end;
  // try to load the default character with the given skill
  LCharacter := FLoader.Load(DEFAULT_CHARACTER, LIntSkill);
  if Assigned(LCharacter) then
  begin
    FCharacters[LHandle] := LCharacter;
    FImport.Print(PRT_MESSAGE, 'loaded default skill ' + TBotCFormat.Int(LIntSkill) + ' from ' + AFileName + #10);
    Exit(LHandle);
  end;
  if AReload = 0 then
  begin
    // try to load a cached character with any skill
    LCachedHandle := FindCachedCharacter(AFileName, -1);
    if LCachedHandle <> 0 then
    begin
      FImport.Print(PRT_MESSAGE, 'loaded cached skill ' + TBotCFormat.Fixed6(FCharacters[LCachedHandle].Skill) +
        ' from ' + AFileName + #10);
      Exit(LCachedHandle);
    end;
  end;
  // try to load a character with any skill
  LCharacter := FLoader.Load(AFileName, -1);
  if Assigned(LCharacter) then
  begin
    FCharacters[LHandle] := LCharacter;
    FImport.Print(PRT_MESSAGE, 'loaded skill ' + TBotCFormat.Fixed6(LCharacter.Skill) + ' from ' + AFileName + #10);
    Exit(LHandle);
  end;
  if AReload = 0 then
  begin
    // try to load a cached character with any skill
    LCachedHandle := FindCachedCharacter(DEFAULT_CHARACTER, -1);
    if LCachedHandle <> 0 then
    begin
      FImport.Print(PRT_MESSAGE, 'loaded cached default skill ' + TBotCFormat.Fixed6(FCharacters[LCachedHandle].Skill) +
        ' from ' + AFileName + #10);
      Exit(LCachedHandle);
    end;
  end;
  // try to load a character with any skill
  LCharacter := FLoader.Load(DEFAULT_CHARACTER, -1);
  if Assigned(LCharacter) then
  begin
    FCharacters[LHandle] := LCharacter;
    FImport.Print(PRT_MESSAGE, 'loaded default skill ' + TBotCFormat.Fixed6(LCharacter.Skill) + ' from ' + AFileName + #10);
    Exit(LHandle);
  end;
  FImport.Print(PRT_WARNING, 'couldn''t load any skill from ' + AFileName + #10);
  // couldn't load any character
  Result := 0;
end;

function TBotCharacterSystem.LoadCharacterSkill(const AFileName: AnsiString; const ASkill: Single): Integer;
var
  LDefault: Integer;
begin
  LDefault := LoadCachedCharacter(DEFAULT_CHARACTER, ASkill, 0);
  Result := LoadCachedCharacter(AFileName, ASkill, FloatToInteger(FLibVars.GetValue('bot_reloadcharacters')));
  if (LDefault <> 0) and (Result <> 0) then
    FCharacters[Result].ApplyDefaults(FCharacters[LDefault]);
end;

function TBotCharacterSystem.InterpolateCharacters(const AFirst, ASecond: Integer; const ADesiredSkill: Single): Integer;
var
  LFirst: TBotCharacter;
  LSecond: TBotCharacter;
begin
  LFirst := CharacterFromHandle(AFirst);
  LSecond := CharacterFromHandle(ASecond);
  if (not Assigned(LFirst)) or (not Assigned(LSecond)) then
    Exit(0);
  // find a free spot for a character
  Result := FreeHandle;
  if Result > BOT_MAX_CLIENTS then
    Exit(0);
  FCharacters[Result] := TBotCharacterInterpolator.Interpolate(LFirst, LSecond, ADesiredSkill);
end;

function TBotCharacterSystem.LoadCharacter(const AFileName: AnsiString; const ASkill: Single): Integer;
var
  LSkill: Single;
  LFirstSkill: Integer;
  LSecondSkill: Integer;
begin
  // make sure the skill is in the valid range
  LSkill := ASkill;
  if LSkill < 1.0 then
    LSkill := 1.0
  else if LSkill > 5.0 then
    LSkill := 5.0;
  // skill 1, 4 and 5 should be available in the character files
  if (LSkill = 1.0) or (LSkill = 4.0) or (LSkill = 5.0) then
    Exit(LoadCharacterSkill(AFileName, LSkill));
  // check if there's a cached skill
  Result := FindCachedCharacter(AFileName, LSkill);
  if Result <> 0 then
  begin
    FImport.Print(PRT_MESSAGE, 'loaded cached skill ' + TBotCFormat.Fixed6(LSkill) + ' from ' + AFileName + #10);
    Exit;
  end;
  if LSkill < 4.0 then
  begin
    // load skill 1 and 4
    LFirstSkill := LoadCharacterSkill(AFileName, 1);
    if LFirstSkill = 0 then
      Exit(0);
    LSecondSkill := LoadCharacterSkill(AFileName, 4);
    if LSecondSkill = 0 then
      Exit(LFirstSkill);
  end
  else
  begin
    // load skill 4 and 5
    LFirstSkill := LoadCharacterSkill(AFileName, 4);
    if LFirstSkill = 0 then
      Exit(0);
    LSecondSkill := LoadCharacterSkill(AFileName, 5);
    if LSecondSkill = 0 then
      Exit(LFirstSkill);
  end;
  // interpolate between the two skills
  Result := InterpolateCharacters(LFirstSkill, LSecondSkill, LSkill);
  if Result = 0 then
    Exit(0);
  // write the character to the log file
  FCharacters[Result].Dump(FImport);
end;

function TBotCharacterSystem.CheckCharacteristicIndex(const AHandle, AIndex: Integer): Boolean;
var
  LCharacter: TBotCharacter;
begin
  LCharacter := CharacterFromHandle(AHandle);
  if not Assigned(LCharacter) then
    Exit(False);
  if (AIndex < 0) or (AIndex >= MAX_CHARACTERISTICS) then
  begin
    FImport.Print(PRT_ERROR, 'characteristic ' + TBotCFormat.Int(AIndex) + ' does not exist'#10);
    Exit(False);
  end;
  if LCharacter.Characteristics[AIndex].CharType = 0 then
  begin
    FImport.Print(PRT_ERROR, 'characteristic ' + TBotCFormat.Int(AIndex) + ' is not initialized'#10);
    Exit(False);
  end;
  Result := True;
end;

class function TBotCharacterSystem.FloatToInteger(const AValue: Single): Integer;
begin
  // (int) of a float that does not fit is 0x80000000 on x86
  if IsNan(AValue) or (AValue >= 2147483648.0) or (AValue < -2147483648.0) then
    Exit(Low(Integer));
  Result := Trunc(AValue);
end;

function TBotCharacterSystem.CharacteristicFloat(const AHandle, AIndex: Integer): Single;
var
  LCharacter: TBotCharacter;
begin
  LCharacter := CharacterFromHandle(AHandle);
  if not Assigned(LCharacter) then
    Exit(0);
  // check if the index is in range
  if not CheckCharacteristicIndex(AHandle, AIndex) then
    Exit(0);
  // an integer will be converted to a float
  if LCharacter.Characteristics[AIndex].CharType = CT_INTEGER then
    Exit(LCharacter.Characteristics[AIndex].IntegerValue);
  // floats are just returned
  if LCharacter.Characteristics[AIndex].CharType = CT_FLOAT then
    Exit(LCharacter.Characteristics[AIndex].FloatValue);
  // cannot convert a string pointer to a float
  FImport.Print(PRT_ERROR, 'characteristic ' + TBotCFormat.Int(AIndex) + ' is not a float'#10);
  Result := 0;
end;

function TBotCharacterSystem.CharacteristicBoundedFloat(const AHandle, AIndex: Integer; const AMin, AMax: Single): Single;
var
  LCharacter: TBotCharacter;
begin
  LCharacter := CharacterFromHandle(AHandle);
  if not Assigned(LCharacter) then
    Exit(0);
  if AMin > AMax then
  begin
    FImport.Print(PRT_ERROR, 'cannot bound characteristic ' + TBotCFormat.Int(AIndex) + ' between ' +
      TBotCFormat.Fixed6(AMin) + ' and ' + TBotCFormat.Fixed6(AMax) + #10);
    Exit(0);
  end;
  Result := CharacteristicFloat(AHandle, AIndex);
  if IsNan(Result) then
    Exit;
  if Result < AMin then
    Exit(AMin);
  if Result > AMax then
    Exit(AMax);
end;

function TBotCharacterSystem.CharacteristicInteger(const AHandle, AIndex: Integer): Integer;
var
  LCharacter: TBotCharacter;
begin
  LCharacter := CharacterFromHandle(AHandle);
  if not Assigned(LCharacter) then
    Exit(0);
  // check if the index is in range
  if not CheckCharacteristicIndex(AHandle, AIndex) then
    Exit(0);
  // an integer will just be returned
  if LCharacter.Characteristics[AIndex].CharType = CT_INTEGER then
    Exit(LCharacter.Characteristics[AIndex].IntegerValue);
  // floats are casted to integers
  if LCharacter.Characteristics[AIndex].CharType = CT_FLOAT then
    Exit(FloatToInteger(LCharacter.Characteristics[AIndex].FloatValue));
  FImport.Print(PRT_ERROR, 'characteristic ' + TBotCFormat.Int(AIndex) + ' is not a integer'#10);
  Result := 0;
end;

function TBotCharacterSystem.CharacteristicBoundedInteger(const AHandle, AIndex, AMin, AMax: Integer): Integer;
var
  LCharacter: TBotCharacter;
begin
  LCharacter := CharacterFromHandle(AHandle);
  if not Assigned(LCharacter) then
    Exit(0);
  if AMin > AMax then
  begin
    FImport.Print(PRT_ERROR, 'cannot bound characteristic ' + TBotCFormat.Int(AIndex) + ' between ' +
      TBotCFormat.Int(AMin) + ' and ' + TBotCFormat.Int(AMax) + #10);
    Exit(0);
  end;
  Result := CharacteristicInteger(AHandle, AIndex);
  if Result < AMin then
    Exit(AMin);
  if Result > AMax then
    Exit(AMax);
end;

function TBotCharacterSystem.CharacteristicString(const AHandle, AIndex, ASize: Integer): AnsiString;
var
  LCharacter: TBotCharacter;
begin
  Result := '';
  LCharacter := CharacterFromHandle(AHandle);
  if not Assigned(LCharacter) then
    Exit;
  // check if the index is in range
  if not CheckCharacteristicIndex(AHandle, AIndex) then
    Exit;
  if LCharacter.Characteristics[AIndex].CharType = CT_STRING then
  begin
    if ASize <= 0 then
      Exit;
    Result := Copy(LCharacter.Characteristics[AIndex].StringValue, 1, ASize - 1);
    Exit;
  end;
  FImport.Print(PRT_ERROR, 'characteristic ' + TBotCFormat.Int(AIndex) + ' is not a string'#10);
end;

procedure TBotCharacterSystem.Shutdown;
var
  LHandle: Integer;
begin
  for LHandle := Low(FCharacters) to High(FCharacters) do
  begin
    if Assigned(FCharacters[LHandle]) then
      FreeCharacter2(LHandle);
  end;
end;

end.
