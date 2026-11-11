{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the actor functions of PS_GAME                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The 115 functions of the actors of psi_game.pas (Actor, TActor, the         }
{  GetActor* and SetActor*, the flags, the sounds, SpawnActor*, RemoveActor,   }
{  CheckActorSight...) and the lists of actors (Actors.All*): a function that  }
{  reads or writes a number of an actor, a text or a related actor is one      }
{  small object for each field (the same method with a different Self), the    }
{  others are methods of the class. The mobjs are touched only through        }
{  IScriptActorSource.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Actors;

interface

uses
  System.Generics.Collections,
  DelphiDoom.ScriptHost.Actors.Intf,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Players.Intf,
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>The actor functions of the unit PS_GAME (called with the object as Self)</summary>
  TScriptActors = class(TInterfacedObject, IScriptActors, IScriptFunctionSection)
  strict private
    FSource: IScriptActorSource;
    FContext: IScriptActorContext;
    FPlayers: IScriptPlayers;
    FGame: TScriptGame;
    FBindings: TObjectList<TObject>;
    FNumberGetters: array[TScriptActorField] of TObject;
    FNumberSetters: array[TScriptActorField] of TObject;
    FTextGetters: array[TScriptActorText] of TObject;
    FTextSetters: array[TScriptActorText] of TObject;
    FRelationGetters: array[TScriptActorRelation] of TObject;
    FRelationSetters: array[TScriptActorRelation] of TObject;
    procedure AddNumberGetter(const ATable: IScriptFunctionTable; const ADeclaration: string;
      const AField: TScriptActorField);
    procedure AddNumberSetter(const ATable: IScriptFunctionTable; const ADeclaration: string;
      const AField: TScriptActorField);
    procedure AddTextGetter(const ATable: IScriptFunctionTable; const ADeclaration: string;
      const AField: TScriptActorText);
    procedure AddTextSetter(const ATable: IScriptFunctionTable; const ADeclaration: string;
      const AField: TScriptActorText);
    procedure AddRelationGetter(const ATable: IScriptFunctionTable; const ADeclaration: string;
      const ARelation: TScriptActorRelation);
    procedure AddRelationSetter(const ATable: IScriptFunctionTable; const ADeclaration: string;
      const ARelation: TScriptActorRelation);
    function Collect(const ASelection: TScriptActorSelection; const AArgument: Integer): TArray<Cardinal>;
  public
    /// <exception cref="EArgumentNilException">If the source, the context or the players are nil</exception>
    constructor Create(const ASource: IScriptActorSource; const AContext: IScriptActorContext;
      const APlayers: IScriptPlayers; const AGame: TScriptGame);
    destructor Destroy; override;
    procedure Describe(const ATable: IScriptFunctionTable);
    /// <summary>The key of the actor that the script runs for, SCRIPT_INVALID_ID if there is none</summary>
    function Actor: Cardinal;
    /// <summary>The key of the actor behind a key (0 is the current actor), SCRIPT_INVALID_ID if there is none</summary>
    function TActor(const AKey: Cardinal): Cardinal;
    function GetNumber(const AKey: Cardinal; const AField: TScriptActorField): Integer;
    procedure SetNumber(const AKey: Cardinal; const AField: TScriptActorField; const AValue: Integer);
    function GetText(const AKey: Cardinal; const AField: TScriptActorText): string;
    procedure SetText(const AKey: Cardinal; const AField: TScriptActorText; const AValue: string);
    function GetRelation(const AKey: Cardinal; const ARelation: TScriptActorRelation): Cardinal;
    procedure SetRelation(const AKey: Cardinal; const ARelation: TScriptActorRelation;
      const ATargetKey: Cardinal);
    function GetActorCustomParam(const AKey: Cardinal; const AName: string): Integer;
    procedure SetActorCustomParam(const AKey: Cardinal; const AName: string; const AValue: Integer);
    procedure SetActorDefaultDropItem(const AKey: Cardinal);
    function CheckActorFlag(const AKey: Cardinal; const AFlag: Cardinal): Boolean;
    procedure SetActorFlag(const AKey: Cardinal; const AFlag: Cardinal);
    procedure UnSetActorFlag(const AKey: Cardinal; const AFlag: Cardinal);
    procedure SetActorPosition(const AKey: Cardinal; const AX, AY, AZ: Integer);
    function GetActorDistanceXY(const AKey1, AKey2: Cardinal): Integer;
    function GetActorDistanceXYZ(const AKey1, AKey2: Cardinal): Integer;
    /// <summary>The number of the player that the actor is, SCRIPT_INVALID_ID if it is none</summary>
    function GetActorPlayer(const AKey: Cardinal): Integer;
    /// <summary>The actor of a player: it is registered among the actor functions</summary>
    function GetPlayerActor(const APlayer: Integer): Cardinal;
    procedure SetActorState(const AKey: Cardinal; const AState: Integer);
    function IsValidActor(const AKey: Cardinal): Boolean;
    procedure ActorPlaySound(const AKey: Cardinal; const AName: string);
    procedure PlaySound(const AName: string);
    function SpawnActorType(const AX, AY, AZ: Integer; const AType: Integer): Cardinal;
    function SpawnActorEditorNumber(const AX, AY, AZ: Integer; const ANumber: Integer): Cardinal;
    function SpawnActorName(const AX, AY, AZ: Integer; const AName: string): Cardinal;
    procedure RemoveActor(const AKey: Cardinal);
    /// <summary>
    ///   Whether the first actor sees the second one. The old code checked the first actor twice and
    ///   gave a second one that is not there to the engine, which crashed: now it gives false
    /// </summary>
    function CheckActorSight(const AKey1, AKey2: Cardinal): Boolean;
    function ActorTypeFromEditorNumber(const ANumber: Integer): Integer;
    function ActorTypeFromName(const AName: string): Integer;
    function AllActors: TArray<Cardinal>;
    function AllMonstersAlive: TArray<Cardinal>;
    function AllMonstersDead: TArray<Cardinal>;
    function AllMonsters: TArray<Cardinal>;
    function AllMissiles: TArray<Cardinal>;
    function AllAtSector(const ASector: Integer): TArray<Cardinal>;
    function AllAtSectorTag(const ATag: Integer): TArray<Cardinal>;
    function AllEditorNumber(const ANumber: Integer): TArray<Cardinal>;
    function AllType(const AType: Integer): TArray<Cardinal>;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.ScriptHost.Actors.KeyList,
  DelphiDoom.ScriptHost.World.Intf;

const
  /// <summary>What a function gives for an actor that is not there (the ones that are not here give 0)</summary>
  SCRIPT_ACTOR_NOT_FOUND: array[TScriptActorField] of Integer = (
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,    // acfX .. acfHealth
    0, 0, 0, 0, 0, 0,                   // acfMass .. acfSpecial
    0, 0, 0, 0, 0, 0, 0, 0,             // acfArg1 .. acfFriction
    0, 0, 0, 0, 0, 0,                   // acfPainChance .. acfSplashGroup
    0,                                  // acfCustomDropItem
    0,                                  // acfSpawnHealth
    0,                                  // acfSector
    SCRIPT_INVALID_ID,                  // acfMobjType
    SCRIPT_INVALID_ID,                  // acfEditorNumber
    SCRIPT_INVALID_ID                   // acfState
  );

type
  /// <summary>The function of a field that is a number: the field is the one of the object that is called</summary>
  TScriptActorNumberBinding = class(TObject)
  strict private
    FOwner: TScriptActors;
    FField: TScriptActorField;
  public
    constructor Create(const AOwner: TScriptActors; const AField: TScriptActorField);
    function Get(const AKey: Cardinal): Integer;
    procedure Put(const AKey: Cardinal; const AValue: Integer);
  end;

  /// <summary>The function of a field that is a text</summary>
  TScriptActorTextBinding = class(TObject)
  strict private
    FOwner: TScriptActors;
    FField: TScriptActorText;
  public
    constructor Create(const AOwner: TScriptActors; const AField: TScriptActorText);
    function Get(const AKey: Cardinal): string;
    procedure Put(const AKey: Cardinal; const AValue: string);
  end;

  /// <summary>The function of the target, the tracer or the master</summary>
  TScriptActorRelationBinding = class(TObject)
  strict private
    FOwner: TScriptActors;
    FRelation: TScriptActorRelation;
  public
    constructor Create(const AOwner: TScriptActors; const ARelation: TScriptActorRelation);
    function Get(const AKey: Cardinal): Cardinal;
    procedure Put(const AKey: Cardinal; const ATargetKey: Cardinal);
  end;

{ TScriptActorNumberBinding }

constructor TScriptActorNumberBinding.Create(const AOwner: TScriptActors;
  const AField: TScriptActorField);
begin
  inherited Create;
  FOwner := AOwner;
  FField := AField;
end;

function TScriptActorNumberBinding.Get(const AKey: Cardinal): Integer;
begin
  Result := FOwner.GetNumber(AKey, FField);
end;

procedure TScriptActorNumberBinding.Put(const AKey: Cardinal; const AValue: Integer);
begin
  FOwner.SetNumber(AKey, FField, AValue);
end;

{ TScriptActorTextBinding }

constructor TScriptActorTextBinding.Create(const AOwner: TScriptActors;
  const AField: TScriptActorText);
begin
  inherited Create;
  FOwner := AOwner;
  FField := AField;
end;

function TScriptActorTextBinding.Get(const AKey: Cardinal): string;
begin
  Result := FOwner.GetText(AKey, FField);
end;

procedure TScriptActorTextBinding.Put(const AKey: Cardinal; const AValue: string);
begin
  FOwner.SetText(AKey, FField, AValue);
end;

{ TScriptActorRelationBinding }

constructor TScriptActorRelationBinding.Create(const AOwner: TScriptActors;
  const ARelation: TScriptActorRelation);
begin
  inherited Create;
  FOwner := AOwner;
  FRelation := ARelation;
end;

function TScriptActorRelationBinding.Get(const AKey: Cardinal): Cardinal;
begin
  Result := FOwner.GetRelation(AKey, FRelation);
end;

procedure TScriptActorRelationBinding.Put(const AKey: Cardinal; const ATargetKey: Cardinal);
begin
  FOwner.SetRelation(AKey, FRelation, ATargetKey);
end;

{ TScriptActors }

constructor TScriptActors.Create(const ASource: IScriptActorSource;
  const AContext: IScriptActorContext; const APlayers: IScriptPlayers; const AGame: TScriptGame);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  if not Assigned(AContext) then
    raise EArgumentNilException.Create('AContext');
  if not Assigned(APlayers) then
    raise EArgumentNilException.Create('APlayers');
  FSource := ASource;
  FContext := AContext;
  FPlayers := APlayers;
  FGame := AGame;
  FBindings := TObjectList<TObject>.Create(True);
end;

destructor TScriptActors.Destroy;
begin
  FBindings.Free;
  inherited Destroy;
end;

// the object of a field lives as long as this one: the interpreters keep their Self, and Describe
// can be asked again

procedure TScriptActors.AddNumberGetter(const ATable: IScriptFunctionTable;
  const ADeclaration: string; const AField: TScriptActorField);
begin
  if not Assigned(FNumberGetters[AField]) then
  begin
    FNumberGetters[AField] := TScriptActorNumberBinding.Create(Self, AField);
    FBindings.Add(FNumberGetters[AField]);
  end;
  ATable.AddMethod(ADeclaration, FNumberGetters[AField], @TScriptActorNumberBinding.Get);
end;

procedure TScriptActors.AddNumberSetter(const ATable: IScriptFunctionTable;
  const ADeclaration: string; const AField: TScriptActorField);
begin
  if not Assigned(FNumberSetters[AField]) then
  begin
    FNumberSetters[AField] := TScriptActorNumberBinding.Create(Self, AField);
    FBindings.Add(FNumberSetters[AField]);
  end;
  ATable.AddMethod(ADeclaration, FNumberSetters[AField], @TScriptActorNumberBinding.Put);
end;

procedure TScriptActors.AddTextGetter(const ATable: IScriptFunctionTable;
  const ADeclaration: string; const AField: TScriptActorText);
begin
  if not Assigned(FTextGetters[AField]) then
  begin
    FTextGetters[AField] := TScriptActorTextBinding.Create(Self, AField);
    FBindings.Add(FTextGetters[AField]);
  end;
  ATable.AddMethod(ADeclaration, FTextGetters[AField], @TScriptActorTextBinding.Get);
end;

procedure TScriptActors.AddTextSetter(const ATable: IScriptFunctionTable;
  const ADeclaration: string; const AField: TScriptActorText);
begin
  if not Assigned(FTextSetters[AField]) then
  begin
    FTextSetters[AField] := TScriptActorTextBinding.Create(Self, AField);
    FBindings.Add(FTextSetters[AField]);
  end;
  ATable.AddMethod(ADeclaration, FTextSetters[AField], @TScriptActorTextBinding.Put);
end;

procedure TScriptActors.AddRelationGetter(const ATable: IScriptFunctionTable;
  const ADeclaration: string; const ARelation: TScriptActorRelation);
begin
  if not Assigned(FRelationGetters[ARelation]) then
  begin
    FRelationGetters[ARelation] := TScriptActorRelationBinding.Create(Self, ARelation);
    FBindings.Add(FRelationGetters[ARelation]);
  end;
  ATable.AddMethod(ADeclaration, FRelationGetters[ARelation], @TScriptActorRelationBinding.Get);
end;

procedure TScriptActors.AddRelationSetter(const ATable: IScriptFunctionTable;
  const ADeclaration: string; const ARelation: TScriptActorRelation);
begin
  if not Assigned(FRelationSetters[ARelation]) then
  begin
    FRelationSetters[ARelation] := TScriptActorRelationBinding.Create(Self, ARelation);
    FBindings.Add(FRelationSetters[ARelation]);
  end;
  ATable.AddMethod(ADeclaration, FRelationSetters[ARelation], @TScriptActorRelationBinding.Put);
end;

procedure TScriptActors.Describe(const ATable: IScriptFunctionTable);
begin
  // --------------------------- Actors ----------------------------------------
  ATable.AddMethod(
    'function Actor: LongWord;', Self,
    @TScriptActors.Actor);
  ATable.AddMethodWithCustomResult(
    'procedure TActor(const key: LongWord);', '!TActor',
    'function TActor(const key: LongWord): !TActor;', Self, @TScriptActors.TActor);
  AddRelationGetter(ATable,
    'function GetActorTarget(const key: LongWord): LongWord;', acrTarget);
  AddRelationSetter(ATable,
    'procedure SetActorTarget(const key: LongWord; const targ: LongWord);', acrTarget);
  AddRelationGetter(ATable,
    'function GetActorTracer(const key: LongWord): LongWord;', acrTracer);
  AddRelationSetter(ATable,
    'procedure SetActorTracer(const key: LongWord; const targ: LongWord);', acrTracer);
  AddRelationGetter(ATable,
    'function GetActorMaster(const key: LongWord): LongWord;', acrMaster);
  AddRelationSetter(ATable,
    'procedure SetActorMaster(const key: LongWord; const targ: LongWord);', acrMaster);
  AddNumberGetter(ATable,
    'function GetActorX(const key: LongWord): fixed_t;', acfX);
  AddNumberSetter(ATable,
    'procedure SetActorX(const key: LongWord; const x: fixed_t);', acfX);
  AddNumberGetter(ATable,
    'function GetActorY(const key: LongWord): fixed_t;', acfY);
  AddNumberSetter(ATable,
    'procedure SetActorY(const key: LongWord; const y: fixed_t);', acfY);
  AddNumberGetter(ATable,
    'function GetActorZ(const key: LongWord): fixed_t;', acfZ);
  AddNumberSetter(ATable,
    'procedure SetActorZ(const key: LongWord; const z: fixed_t);', acfZ);
  ATable.AddMethod(
    'procedure SetActorPosition(const key: LongWord; const x, y, z: fixed_t);', Self,
    @TScriptActors.SetActorPosition);
  AddNumberGetter(ATable,
    'function GetActorMOMX(const key: LongWord): fixed_t;', acfMomX);
  AddNumberSetter(ATable,
    'procedure SetActorMOMX(const key: LongWord; const x: fixed_t);', acfMomX);
  AddNumberGetter(ATable,
    'function GetActorMOMY(const key: LongWord): fixed_t;', acfMomY);
  AddNumberSetter(ATable,
    'procedure SetActorMOMY(const key: LongWord; const y: fixed_t);', acfMomY);
  AddNumberGetter(ATable,
    'function GetActorMOMZ(const key: LongWord): fixed_t;', acfMomZ);
  AddNumberSetter(ATable,
    'procedure SetActorMOMZ(const key: LongWord; const z: fixed_t);', acfMomZ);
  AddNumberGetter(ATable,
    'function GetActorFloorZ(const key: LongWord): fixed_t;', acfFloorZ);
  AddNumberSetter(ATable,
    'procedure SetActorFloorZ(const key: LongWord; const z: fixed_t);', acfFloorZ);
  AddNumberGetter(ATable,
    'function GetActorCeilingZ(const key: LongWord): fixed_t;', acfCeilingZ);
  AddNumberSetter(ATable,
    'procedure SetActorCeilingZ(const key: LongWord; const z: fixed_t);', acfCeilingZ);
  AddNumberGetter(ATable,
    'function GetActorSpeed(const key: LongWord): fixed_t;', acfSpeed);
  AddNumberSetter(ATable,
    'procedure SetActorSpeed(const key: LongWord; const speed: fixed_t);', acfSpeed);
  AddNumberGetter(ATable,
    'function GetActorAngle(const key: LongWord): angle_t;', acfAngle);
  AddNumberSetter(ATable,
    'procedure SetActorAngle(const key: LongWord; const angle: angle_t);', acfAngle);
  AddNumberGetter(ATable,
    'function GetActorSector(const key: LongWord): integer;', acfSector);
  AddNumberGetter(ATable,
    'function GetActorHealth(const key: LongWord): integer;', acfHealth);
  AddNumberSetter(ATable,
    'procedure SetActorHealth(const key: LongWord; const h: integer);', acfHealth);
  AddNumberGetter(ATable,
    'function GetActorSpawnHealth(const key: LongWord): integer;', acfSpawnHealth);
  AddNumberGetter(ATable,
    'function GetActorMass(const key: LongWord): integer;', acfMass);
  AddNumberSetter(ATable,
    'procedure SetActorMass(const key: LongWord; const m: Integer);', acfMass);
  AddNumberGetter(ATable,
    'function GetActorHeight(const key: LongWord): fixed_t;', acfHeight);
  AddNumberSetter(ATable,
    'procedure SetActorHeight(const key: LongWord; const h: fixed_t);', acfHeight);
  AddNumberGetter(ATable,
    'function GetActorCustomDropItem(const key: LongWord): integer;', acfCustomDropItem);
  AddNumberSetter(ATable,
    'procedure SetActorCustomDropItem(const key: LongWord; const value: integer);', acfCustomDropItem);
  ATable.AddMethod(
    'procedure SetActorDefaultDropItem(const key: LongWord);', Self,
    @TScriptActors.SetActorDefaultDropItem);
  AddNumberGetter(ATable,
    'function GetActorPushFactor(const key: LongWord): integer;', acfPushFactor);
  AddNumberSetter(ATable,
    'procedure SetActorPushFactor(const key: LongWord; const value: integer);', acfPushFactor);
  AddNumberGetter(ATable,
    'function GetActorScale(const key: LongWord): integer;', acfScale);
  AddNumberSetter(ATable,
    'procedure SetActorScale(const key: LongWord; const value: integer);', acfScale);
  AddNumberGetter(ATable,
    'function GetActorGravity(const key: LongWord): integer;', acfGravity);
  AddNumberSetter(ATable,
    'procedure SetActorGravity(const key: LongWord; const value: integer);', acfGravity);
  AddNumberGetter(ATable,
    'function GetActorSpecial(const key: LongWord): Integer;', acfSpecial);
  AddNumberSetter(ATable,
    'procedure SetActorSpecial(const key: LongWord; const value: Integer);', acfSpecial);
  AddNumberGetter(ATable,
    'function GetActorArg1(const key: LongWord): integer;', acfArg1);
  AddNumberSetter(ATable,
    'procedure SetActorArg1(const key: LongWord; const value: integer);', acfArg1);
  AddNumberGetter(ATable,
    'function GetActorArg2(const key: LongWord): integer;', acfArg2);
  AddNumberSetter(ATable,
    'procedure SetActorArg2(const key: LongWord; const value: integer);', acfArg2);
  AddNumberGetter(ATable,
    'function GetActorArg3(const key: LongWord): integer;', acfArg3);
  AddNumberSetter(ATable,
    'procedure SetActorArg3(const key: LongWord; const value: integer);', acfArg3);
  AddNumberGetter(ATable,
    'function GetActorArg4(const key: LongWord): integer;', acfArg4);
  AddNumberSetter(ATable,
    'procedure SetActorArg4(const key: LongWord; const value: integer);', acfArg4);
  AddNumberGetter(ATable,
    'function GetActorArg5(const key: LongWord): integer;', acfArg5);
  AddNumberSetter(ATable,
    'procedure SetActorArg5(const key: LongWord; const value: integer);', acfArg5);
  AddNumberGetter(ATable,
    'function GetActorWeaveIndexXY(const key: LongWord): Integer;);', acfWeaveIndexXY);
  AddNumberSetter(ATable,
    'procedure SetActorWeaveIndexXY(const key: LongWord; const value: Integer);', acfWeaveIndexXY);
  AddNumberGetter(ATable,
    'function GetActorWeaveIndexZ(const key: LongWord): Integer;);', acfWeaveIndexZ);
  AddNumberSetter(ATable,
    'procedure SetActorWeaveIndexZ(const key: LongWord; const value: Integer);', acfWeaveIndexXY);
  AddNumberGetter(ATable,
    'function GetActorFriction(const key: LongWord): Integer;);', acfFriction);
  AddNumberSetter(ATable,
    'procedure SetActorFriction(const key: LongWord; const value: Integer););', acfFriction);
  AddNumberGetter(ATable,
    'function GetActorPainChance(const key: LongWord): Integer;);', acfPainChance);
  AddNumberSetter(ATable,
    'procedure SetActorPainChance(const key: LongWord; const value: Integer);', acfPainChance);
  AddNumberGetter(ATable,
    'function GetActorSpriteDX(const key: LongWord): Integer;);', acfSpriteDX);
  AddNumberSetter(ATable,
    'procedure SetActorSpriteDX(const key: LongWord; const value: Integer);', acfSpriteDX);
  AddNumberGetter(ATable,
    'function GetActorSpriteDY(const key: LongWord): Integer;);', acfSpriteDY);
  AddNumberSetter(ATable,
    'procedure SetActorSpriteDY(const key: LongWord; const value: Integer);', acfSpriteDY);
  ATable.AddMethod(
    'function GetActorCustomParam(const key: LongWord; const parm: string): integer;', Self,
    @TScriptActors.GetActorCustomParam);
  ATable.AddMethod(
    'procedure SetActorCustomParam(const key: LongWord; const parm: string; const value: integer);', Self,
    @TScriptActors.SetActorCustomParam);
  ATable.AddMethod(
    'function CheckActorFlag(const key: LongWord; const flag: LongWord): boolean;', Self,
    @TScriptActors.CheckActorFlag);
  ATable.AddMethod(
    'procedure SetActorFlag(const key: LongWord; const flag: LongWord);', Self,
    @TScriptActors.SetActorFlag);
  ATable.AddMethod(
    'procedure UnSetActorFlag(const key: LongWord; const flag: LongWord);', Self,
    @TScriptActors.UnSetActorFlag);
  AddNumberGetter(ATable,
    'function GetActorInfightingGroup(const key: LongWord): Integer;', acfInfightingGroup);
  AddNumberSetter(ATable,
    'procedure SetActorInfightingGroup(const key: LongWord; const value: Integer);', acfInfightingGroup);
  AddNumberGetter(ATable,
    'function GetActorProjectileGroup(const key: LongWord): Integer;', acfProjectileGroup);
  AddNumberSetter(ATable,
    'procedure SetActorProjectileGroup(const key: LongWord; const value: Integer);', acfProjectileGroup);
  AddNumberGetter(ATable,
    'function GetActorSplashGroup(const key: LongWord): Integer;', acfSplashGroup);
  AddNumberSetter(ATable,
    'procedure SetActorSplashGroup(const key: LongWord; const value: Integer);', acfSplashGroup);
  AddTextGetter(ATable,
    'function GetActorTranslation(const key: LongWord): string;', actTranslation);
  AddTextSetter(ATable,
    'procedure SetActorTranslation(const key: LongWord; const value: string);', actTranslation);
  AddTextGetter(ATable,
    'function GetActorBloodColor(const key: LongWord): string;', actBloodColor);
  AddTextSetter(ATable,
    'procedure SetActorBloodColor(const key: LongWord; const value: string);', actBloodColor);
  AddTextGetter(ATable,
    'function GetActorRipSound(const key: LongWord): string;', actMeleeSound);
  AddTextGetter(ATable,
    'function GetActorName(const key: LongWord): string;', actName);
  if FGame = sgStrife then
    AddTextGetter(ATable,
      'function GetActorName2(const key: LongWord): string;', actName2);
  ATable.AddMethod(
    'function GetActorDistanceXY(const key1, key2: LongWord): fixed_t;', Self,
    @TScriptActors.GetActorDistanceXY);
  ATable.AddMethod(
    'function GetActorDistanceXYZ(const key1, key2: LongWord): fixed_t;', Self,
    @TScriptActors.GetActorDistanceXYZ);
  AddNumberGetter(ATable,
    'function GetActorMobjType(const key: LongWord): integer;', acfMobjType);
  AddNumberGetter(ATable,
    'function GetActorEditorNumber(const key: LongWord): integer;', acfEditorNumber);
  AddNumberGetter(ATable,
    'function GetActorState(const key: LongWord): integer;', acfState);
  ATable.AddMethod(
    'procedure SetActorState(const key: LongWord; const value: Integer);', Self,
    @TScriptActors.SetActorState);
  ATable.AddMethod(
    'function IsValidActor(const key: LongWord): boolean;', Self,
    @TScriptActors.IsValidActor);
  ATable.AddMethod(
    'procedure ActorPlaySound(const key: LongWord; const snd: string);', Self,
    @TScriptActors.ActorPlaySound);
  ATable.AddMethod(
    'procedure PlaySound(const snd: string);', Self,
    @TScriptActors.PlaySound);
  ATable.AddMethod(
    'function GetActorPlayer(const key: LongWord): integer;', Self,
    @TScriptActors.GetActorPlayer);
  ATable.AddMethod(
    'function GetPlayerActor(const plnum: integer): LongWord;', Self,
    @TScriptActors.GetPlayerActor);
  ATable.AddMethod(
    'function SpawnActorType(x, y, z: fixed_t; const typ: integer): LongWord;', Self,
    @TScriptActors.SpawnActorType);
  ATable.AddMethod(
    'function SpawnActorEditorNumber(x, y, z: fixed_t; const ednum: integer): LongWord;', Self,
    @TScriptActors.SpawnActorEditorNumber);
  ATable.AddMethod(
    'function SpawnActorName(x, y, z: fixed_t; const name: string): LongWord;', Self,
    @TScriptActors.SpawnActorName);
  ATable.AddMethod(
    'procedure RemoveActor(const key: LongWord);', Self,
    @TScriptActors.RemoveActor);
  ATable.AddMethod(
    'function CheckActorSight(const actor1, actor2: LongWord): boolean;', Self,
    @TScriptActors.CheckActorSight);
  ATable.AddMethod(
    'function ActorTypeFromEditorNumber(const ednum: integer): integer;', Self,
    @TScriptActors.ActorTypeFromEditorNumber);
  ATable.AddMethod(
    'function ActorTypeFromName(const name: string): integer;', Self,
    @TScriptActors.ActorTypeFromName);
  AddTextGetter(ATable,
    'function GetActorSeeSound(const key: LongWord): string;', actSeeSound);
  AddTextGetter(ATable,
    'function GetActorAttackSound(const key: LongWord): string;', actAttackSound);
  AddTextGetter(ATable,
    'function GetActorPainSound(const key: LongWord): string;', actPainSound);
  AddTextGetter(ATable,
    'function GetActorDeathSound(const key: LongWord): string;', actDeathSound);
  AddTextGetter(ATable,
    'function GetActorActiveSound(const key: LongWord): string;', actActiveSound);
  AddTextGetter(ATable,
    'function GetActorCustomSound1(const key: LongWord): string;', actCustomSound1);
  AddTextGetter(ATable,
    'function GetActorCustomSound2(const key: LongWord): string;', actCustomSound2);
  AddTextGetter(ATable,
    'function GetActorCustomSound3(const key: LongWord): string;', actCustomSound3);
  AddTextGetter(ATable,
    'function GetActorMeleeSound(const key: LongWord): string;', actMeleeSound);
end;

function TScriptActors.Actor: Cardinal;
begin
  Result := FContext.CurrentKey;
end;

function TScriptActors.TActor(const AKey: Cardinal): Cardinal;
begin
  Result := FSource.KeyOf(AKey);
end;

function TScriptActors.GetNumber(const AKey: Cardinal; const AField: TScriptActorField): Integer;
begin
  Result := FSource.GetNumber(AKey, AField, SCRIPT_ACTOR_NOT_FOUND[AField]);
end;

procedure TScriptActors.SetNumber(const AKey: Cardinal; const AField: TScriptActorField;
  const AValue: Integer);
begin
  FSource.SetNumber(AKey, AField, AValue);
end;

function TScriptActors.GetText(const AKey: Cardinal; const AField: TScriptActorText): string;
begin
  Result := FSource.GetText(AKey, AField);
end;

procedure TScriptActors.SetText(const AKey: Cardinal; const AField: TScriptActorText;
  const AValue: string);
begin
  FSource.SetText(AKey, AField, AValue);
end;

function TScriptActors.GetRelation(const AKey: Cardinal;
  const ARelation: TScriptActorRelation): Cardinal;
begin
  Result := FSource.RelatedKey(AKey, ARelation);
end;

procedure TScriptActors.SetRelation(const AKey: Cardinal; const ARelation: TScriptActorRelation;
  const ATargetKey: Cardinal);
begin
  FSource.SetRelated(AKey, ARelation, ATargetKey);
end;

function TScriptActors.GetActorCustomParam(const AKey: Cardinal; const AName: string): Integer;
begin
  Result := FSource.CustomParam(AKey, AName);
end;

procedure TScriptActors.SetActorCustomParam(const AKey: Cardinal; const AName: string;
  const AValue: Integer);
begin
  FSource.SetCustomParam(AKey, AName, AValue);
end;

procedure TScriptActors.SetActorDefaultDropItem(const AKey: Cardinal);
begin
  FSource.SetDefaultDropItem(AKey);
end;

function TScriptActors.CheckActorFlag(const AKey: Cardinal; const AFlag: Cardinal): Boolean;
begin
  Result := FSource.CheckFlag(AKey, AFlag);
end;

procedure TScriptActors.SetActorFlag(const AKey: Cardinal; const AFlag: Cardinal);
begin
  FSource.SetFlag(AKey, AFlag, True);
end;

procedure TScriptActors.UnSetActorFlag(const AKey: Cardinal; const AFlag: Cardinal);
begin
  FSource.SetFlag(AKey, AFlag, False);
end;

procedure TScriptActors.SetActorPosition(const AKey: Cardinal; const AX, AY, AZ: Integer);
begin
  FSource.SetPosition(AKey, AX, AY, AZ);
end;

function TScriptActors.GetActorDistanceXY(const AKey1, AKey2: Cardinal): Integer;
begin
  Result := FSource.Distance(AKey1, AKey2, False);
end;

function TScriptActors.GetActorDistanceXYZ(const AKey1, AKey2: Cardinal): Integer;
begin
  Result := FSource.Distance(AKey1, AKey2, True);
end;

function TScriptActors.GetActorPlayer(const AKey: Cardinal): Integer;
begin
  Result := FSource.PlayerNumber(AKey);
  if Result < 0 then
    Result := SCRIPT_INVALID_ID;
end;

function TScriptActors.GetPlayerActor(const APlayer: Integer): Cardinal;
begin
  Result := FPlayers.GetPlayerActor(APlayer);
end;

procedure TScriptActors.SetActorState(const AKey: Cardinal; const AState: Integer);
begin
  if (AState < 0) or (AState >= FSource.StateCount) then
    Exit;
  FSource.SetState(AKey, AState);
end;

function TScriptActors.IsValidActor(const AKey: Cardinal): Boolean;
begin
  Result := FSource.Exists(AKey);
end;

procedure TScriptActors.ActorPlaySound(const AKey: Cardinal; const AName: string);
begin
  FSource.PlayActorSound(AKey, AName);
end;

procedure TScriptActors.PlaySound(const AName: string);
begin
  FSource.PlayGlobalSound(AName);
end;

function TScriptActors.SpawnActorType(const AX, AY, AZ: Integer; const AType: Integer): Cardinal;
begin
  if (AType >= 0) and (AType < FSource.MobjTypeCount) then
    Result := FSource.Spawn(AX, AY, AZ, AType)
  else
    Result := SCRIPT_INVALID_ID;
end;

function TScriptActors.SpawnActorEditorNumber(const AX, AY, AZ: Integer;
  const ANumber: Integer): Cardinal;
begin
  Result := SpawnActorType(AX, AY, AZ, FSource.MobjTypeFromEditorNumber(ANumber));
end;

function TScriptActors.SpawnActorName(const AX, AY, AZ: Integer; const AName: string): Cardinal;
begin
  Result := SpawnActorType(AX, AY, AZ, FSource.MobjTypeFromName(AName));
end;

procedure TScriptActors.RemoveActor(const AKey: Cardinal);
begin
  FSource.Remove(AKey);
end;

function TScriptActors.CheckActorSight(const AKey1, AKey2: Cardinal): Boolean;
begin
  Result := FSource.Exists(AKey1) and FSource.Exists(AKey2) and FSource.CheckSight(AKey1, AKey2);
end;

function TScriptActors.ActorTypeFromEditorNumber(const ANumber: Integer): Integer;
begin
  Result := FSource.MobjTypeFromEditorNumber(ANumber);
end;

function TScriptActors.ActorTypeFromName(const AName: string): Integer;
begin
  Result := FSource.MobjTypeFromName(AName);
end;

function TScriptActors.Collect(const ASelection: TScriptActorSelection;
  const AArgument: Integer): TArray<Cardinal>;
var
  LKeys: TScriptActorKeyList;
begin
  LKeys := TScriptActorKeyList.Create;
  try
    FSource.Collect(ASelection, AArgument, LKeys);
    Result := LKeys.ToArray;
  finally
    LKeys.Free;
  end;
end;

function TScriptActors.AllActors: TArray<Cardinal>;
begin
  Result := Collect(acsAll, 0);
end;

function TScriptActors.AllMonstersAlive: TArray<Cardinal>;
begin
  Result := Collect(acsMonstersAlive, 0);
end;

function TScriptActors.AllMonstersDead: TArray<Cardinal>;
begin
  Result := Collect(acsMonstersDead, 0);
end;

function TScriptActors.AllMonsters: TArray<Cardinal>;
begin
  Result := Collect(acsMonsters, 0);
end;

function TScriptActors.AllMissiles: TArray<Cardinal>;
begin
  Result := Collect(acsMissiles, 0);
end;

function TScriptActors.AllAtSector(const ASector: Integer): TArray<Cardinal>;
begin
  Result := Collect(acsSector, ASector);
end;

function TScriptActors.AllAtSectorTag(const ATag: Integer): TArray<Cardinal>;
begin
  Result := Collect(acsSectorTag, ATag);
end;

function TScriptActors.AllEditorNumber(const ANumber: Integer): TArray<Cardinal>;
begin
  Result := Collect(acsEditorNumber, ANumber);
end;

function TScriptActors.AllType(const AType: Integer): TArray<Cardinal>;
begin
  Result := Collect(acsType, AType);
end;

end.
