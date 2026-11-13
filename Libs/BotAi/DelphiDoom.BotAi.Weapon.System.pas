{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWeaponSystem, the weapon AI of the bots            }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): the states and the  }
{  functions of code\botlib\be_ai_weap.c (BotSetupWeaponAI,                    }
{  BotShutdownWeaponAI, BotAllocWeaponState, BotFreeWeaponState,               }
{  BotResetWeaponState, BotLoadWeaponWeights, BotGetWeaponInfo,                }
{  BotChooseBestFightWeapon, WeaponWeightIndex). Based on the Quake III Arena  }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weapon.System;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.LibVars.Intf, DelphiDoom.BotAi.Weight.Intf,
  DelphiDoom.BotAi.Weight.Evaluator, DelphiDoom.BotAi.Weight.Config, DelphiDoom.BotAi.Weapon.Types, DelphiDoom.BotAi.Weapon.Config,
  DelphiDoom.BotAi.Weapon.Definitions, DelphiDoom.BotAi.Weapon.ConfigLoader, DelphiDoom.BotAi.Weapon.State,
  DelphiDoom.BotAi.Weapon.Intf;

type
  /// <summary>
  ///   The globals <c>weaponconfig</c> and <c>botweaponstates[MAX_CLIENTS + 1]</c> are fields. Differences from
  ///   the original (it would read outside its memory): without a configuration, or with the weapon number
  ///   equal to the size of the table, <c>GetWeaponInfo</c> prints "weapon number out of range".
  /// </summary>
  TBotWeaponSystem = class(TInterfacedObject, IBotWeaponSystem)
  strict private
    FImport: IBotImport;
    FLibVars: IBotLibVarStore;
    FWeights: IBotWeightCache;
    FDefinitions: TBotWeaponDefinitions;
    FLoader: TBotWeaponConfigLoader;
    FEvaluator: TBotFuzzyEvaluator;
    FConfig: TBotWeaponConfig;
    FStates: array[1..64] of TBotWeaponState;
    function StateFromHandle(const AHandle: Integer): TBotWeaponState;
    function ValidWeaponNumber(const AWeapon: Integer): Boolean;
    procedure FreeWeaponWeights(const AHandle: Integer);
    function WeaponWeightIndex(const AWeights: TBotWeightConfig): TArray<Integer>;
  public
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource; const ALibVars: IBotLibVarStore;
      const AWeights: IBotWeightCache);
    destructor Destroy; override;
    function Setup: Integer;
    procedure Shutdown;
    function AllocWeaponState: Integer;
    procedure FreeWeaponState(const AHandle: Integer);
    procedure ResetWeaponState(const AHandle: Integer);
    function LoadWeaponWeights(const AHandle: Integer; const AFileName: AnsiString): Integer;
    function GetWeaponInfo(const AHandle, AWeapon: Integer; out AInfo: TBotWeaponInfo): Boolean;
    function ChooseBestFightWeapon(const AHandle: Integer; const AInventory: TArray<Integer>): Integer;
    function Config: TBotWeaponConfig;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Text.CFormat;

{ TBotWeaponSystem }

constructor TBotWeaponSystem.Create(const AImport: IBotImport; const AFiles: IBotFileSource;
  const ALibVars: IBotLibVarStore; const AWeights: IBotWeightCache);
begin
  inherited Create;
  FImport := AImport;
  FLibVars := ALibVars;
  FWeights := AWeights;
  FDefinitions := TBotWeaponDefinitions.Create;
  FLoader := TBotWeaponConfigLoader.Create(AImport, AFiles, ALibVars, FDefinitions);
  // FuzzyWeight does not use the generator
  FEvaluator := TBotFuzzyEvaluator.Create(nil);
end;

destructor TBotWeaponSystem.Destroy;
var
  LHandle: Integer;
begin
  for LHandle := Low(FStates) to High(FStates) do
    FreeAndNil(FStates[LHandle]);
  FEvaluator.Free;
  FLoader.Free;
  FDefinitions.Free;
  FConfig.Free;
  inherited Destroy;
end;

function TBotWeaponSystem.Config: TBotWeaponConfig;
begin
  Result := FConfig;
end;

function TBotWeaponSystem.ValidWeaponNumber(const AWeapon: Integer): Boolean;
begin
  if (not Assigned(FConfig)) or (AWeapon <= 0) or (AWeapon >= FConfig.NumWeapons) then
  begin
    FImport.Print(PRT_ERROR, 'weapon number out of range'#10);
    Exit(False);
  end;
  Result := True;
end;

function TBotWeaponSystem.StateFromHandle(const AHandle: Integer): TBotWeaponState;
begin
  // the messages say "move state" in the original too
  if (AHandle <= 0) or (AHandle > BOT_MAX_CLIENTS) then
  begin
    FImport.Print(PRT_FATAL, 'move state handle ' + TBotCFormat.Int(AHandle) + ' out of range'#10);
    Exit(nil);
  end;
  if not Assigned(FStates[AHandle]) then
  begin
    FImport.Print(PRT_FATAL, 'invalid move state ' + TBotCFormat.Int(AHandle) + #10);
    Exit(nil);
  end;
  Result := FStates[AHandle];
end;

function TBotWeaponSystem.WeaponWeightIndex(const AWeights: TBotWeightConfig): TArray<Integer>;
var
  LIndex: Integer;
begin
  // initialize item weight index
  SetLength(Result, FConfig.NumWeapons);
  for LIndex := 0 to FConfig.NumWeapons - 1 do
    Result[LIndex] := AWeights.FindFuzzyWeight(BotFieldText(FConfig.Weapons[LIndex].Name));
end;

procedure TBotWeaponSystem.FreeWeaponWeights(const AHandle: Integer);
var
  LState: TBotWeaponState;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit;
  if Assigned(LState.WeaponWeights) then
    FWeights.FreeWeightConfig(LState.WeaponWeights);
  // the original leaves the pointers dangling
  LState.WeaponWeights := nil;
  LState.WeaponWeightIndex := nil;
end;

function TBotWeaponSystem.LoadWeaponWeights(const AHandle: Integer; const AFileName: AnsiString): Integer;
var
  LState: TBotWeaponState;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit(BLERR_CANNOTLOADWEAPONWEIGHTS);
  FreeWeaponWeights(AHandle);
  LState.WeaponWeights := FWeights.ReadWeightConfig(AFileName);
  if not Assigned(LState.WeaponWeights) then
  begin
    FImport.Print(PRT_FATAL, 'couldn''t load weapon config ' + AFileName + #10);
    Exit(BLERR_CANNOTLOADWEAPONWEIGHTS);
  end;
  if not Assigned(FConfig) then
    Exit(BLERR_CANNOTLOADWEAPONCONFIG);
  LState.WeaponWeightIndex := WeaponWeightIndex(LState.WeaponWeights);
  Result := BLERR_NOERROR;
end;

function TBotWeaponSystem.GetWeaponInfo(const AHandle, AWeapon: Integer; out AInfo: TBotWeaponInfo): Boolean;
begin
  AInfo := Default(TBotWeaponInfo);
  if not ValidWeaponNumber(AWeapon) then
    Exit(False);
  if not Assigned(StateFromHandle(AHandle)) then
    Exit(False);
  AInfo := FConfig.Weapons[AWeapon];
  Result := True;
end;

function TBotWeaponSystem.ChooseBestFightWeapon(const AHandle: Integer; const AInventory: TArray<Integer>): Integer;
var
  LState: TBotWeaponState;
  LIndex: Integer;
  LWeightIndex: Integer;
  LWeight: Single;
  LBestWeight: Single;
begin
  LState := StateFromHandle(AHandle);
  if not Assigned(LState) then
    Exit(0);
  if not Assigned(FConfig) then
    Exit(0);
  // if the bot has no weapon weight configuration
  if (not Assigned(LState.WeaponWeights)) or (Length(LState.WeaponWeightIndex) < FConfig.NumWeapons) then
    Exit(0);
  LBestWeight := 0;
  Result := 0;
  for LIndex := 0 to FConfig.NumWeapons - 1 do
  begin
    if FConfig.Weapons[LIndex].Valid = 0 then
      Continue;
    LWeightIndex := LState.WeaponWeightIndex[LIndex];
    if LWeightIndex < 0 then
      Continue;
    LWeight := FEvaluator.FuzzyWeight(AInventory, LState.WeaponWeights, LWeightIndex);
    if LWeight > LBestWeight then
    begin
      LBestWeight := LWeight;
      Result := LIndex;
    end;
  end;
end;

procedure TBotWeaponSystem.ResetWeaponState(const AHandle: Integer);
begin
  // the original reads the weights and writes them back: only the check of the handle is left
  StateFromHandle(AHandle);
end;

function TBotWeaponSystem.AllocWeaponState: Integer;
begin
  for Result := Low(FStates) to High(FStates) do
  begin
    if not Assigned(FStates[Result]) then
    begin
      FStates[Result] := TBotWeaponState.Create;
      Exit;
    end;
  end;
  Result := 0;
end;

procedure TBotWeaponSystem.FreeWeaponState(const AHandle: Integer);
begin
  if (AHandle <= 0) or (AHandle > BOT_MAX_CLIENTS) then
  begin
    FImport.Print(PRT_FATAL, 'move state handle ' + TBotCFormat.Int(AHandle) + ' out of range'#10);
    Exit;
  end;
  if not Assigned(FStates[AHandle]) then
  begin
    FImport.Print(PRT_FATAL, 'invalid move state ' + TBotCFormat.Int(AHandle) + #10);
    Exit;
  end;
  FreeWeaponWeights(AHandle);
  FreeAndNil(FStates[AHandle]);
end;

function TBotWeaponSystem.Setup: Integer;
var
  LFileName: AnsiString;
begin
  LFileName := FLibVars.GetStringOrCreate('weaponconfig', 'weapons.c');
  FreeAndNil(FConfig);
  FConfig := FLoader.Load(LFileName);
  if not Assigned(FConfig) then
  begin
    FImport.Print(PRT_FATAL, 'couldn''t load the weapon config'#10);
    Exit(BLERR_CANNOTLOADWEAPONCONFIG);
  end;
  Result := BLERR_NOERROR;
end;

procedure TBotWeaponSystem.Shutdown;
var
  LHandle: Integer;
begin
  FreeAndNil(FConfig);
  for LHandle := Low(FStates) to High(FStates) do
  begin
    if Assigned(FStates[LHandle]) then
      FreeWeaponState(LHandle);
  end;
end;

end.
