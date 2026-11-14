{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptEntityTable                }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): the uses of              }
{  gameLocal.entities in game\script\Script_Interpreter.h and                  }
{  Script_Thread.cpp. Copyright (C) 1999-2011 id Software LLC, a ZeniMax       }
{  Media company.                                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.Entities;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.Defs, DelphiDoom.DoomScript.EventTarget,
  DelphiDoom.DoomScript.ScriptProgram, DelphiDoom.DoomScript.ScriptObject;

type
  /// <summary>
  ///   The entities of the host as the script sees them (<c>gameLocal.entities</c>): a handle from 0 to
  ///   DS_MAX_GENTITIES - 1, the object that receives the events of the entity (owned by the host), its
  ///   name and its script object (owned by the table). A script holds an entity as its handle plus one;
  ///   zero is no entity.
  /// </summary>
  TDoomScriptEntityTable = class
  strict private
    FProgram: TDoomScriptProgram;
    FTargets: array[0..DS_MAX_GENTITIES - 1] of TDoomScriptEventTarget;
    FNames: array[0..DS_MAX_GENTITIES - 1] of AnsiString;
    FObjects: array[0..DS_MAX_GENTITIES - 1] of TDoomScriptObject;
    FSpawnIds: array[0..DS_MAX_GENTITIES - 1] of Integer;
    FSpawnCount: Integer;
    procedure CheckNumber(const ANumber: Integer);
  public
    constructor Create(const AProgram: TDoomScriptProgram);
    destructor Destroy; override;
    /// <summary>Registers an entity of the host; raises EDoomScriptError if the handle is taken or bad</summary>
    procedure Add(const ANumber: Integer; const ATarget: TDoomScriptEventTarget; const AName: AnsiString);
    /// <summary>Removes an entity and frees its script object; nothing if the handle is free</summary>
    procedure Remove(const ANumber: Integer);
    function Exists(const ANumber: Integer): Boolean;
    /// <summary>The target of an entity handle; nil if there is none</summary>
    function TargetOf(const ANumber: Integer): TDoomScriptEventTarget;
    function NameOf(const ANumber: Integer): AnsiString;
    /// <summary>Changes the name of an entity (the host does the matching <c>SetEntity</c> of the program)</summary>
    procedure Rename(const ANumber: Integer; const AName: AnsiString);
    /// <summary>
    ///   gameLocal.spawnIds: the serial number the entity got when it was added (INITIAL_SPAWN_COUNT, 3, for the
    ///   first one); -1 for a handle that was never used. It stays after the entity is removed.
    /// </summary>
    function SpawnIdOf(const ANumber: Integer): Integer;
    /// <summary>
    ///   idEntityPtr::operator=: the spawn id and the handle of an entity in one integer, what a queued event and a
    ///   save game hold; 0 for no entity
    /// </summary>
    function EntityPtr(const ANumber: Integer): Integer;
    /// <summary>
    ///   idEntityPtr::GetEntity: the handle of the entity of a value of <c>EntityPtr</c>, -1 if that entity was
    ///   removed (even if another one took its handle)
    /// </summary>
    function ResolveEntityPtr(const AValue: Integer): Integer;
    /// <summary>The script object of an entity (with or without data); nil if there is no entity</summary>
    function ObjectOf(const ANumber: Integer): TDoomScriptObject;
    /// <summary>The handle of a target, -1 if it is not an entity</summary>
    function NumberOf(const ATarget: TDoomScriptEventTarget): Integer;
    /// <summary>idInterpreter::GetEntity: the target of a script value (handle plus one); nil if none</summary>
    function GetEntity(const AScriptNumber: Integer): TDoomScriptEventTarget; inline;
    /// <summary>idInterpreter::GetScriptObject: the object of a script value, only if it has data</summary>
    function GetScriptObject(const AScriptNumber: Integer): TDoomScriptObject; inline;
    /// <summary>
    ///   Frees the script objects whose type is not among the first <c>ATypeCount</c> types of the
    ///   program: called before the program frees its types, so that no object keeps a freed type
    /// </summary>
    procedure ReleaseObjects(const ATypeCount: Integer);
    /// <summary>gameLocal.spawnCount: the spawn id of the next entity (a host that restores a game sets it)</summary>
    property SpawnCount: Integer read FSpawnCount write FSpawnCount;
  end;

implementation

const
  SBadNumber = 'TDoomScriptEntityTable: entity number %d out of range';
  STaken = 'TDoomScriptEntityTable: entity number %d is already in use';
  SNoTarget = 'TDoomScriptEntityTable: an entity needs a target';
  INITIAL_SPAWN_COUNT = 3;
  ENTITY_NUMBER_BITS = 12;

constructor TDoomScriptEntityTable.Create(const AProgram: TDoomScriptProgram);
begin
  inherited Create;
  FProgram := AProgram;
  FillChar(FSpawnIds, SizeOf(FSpawnIds), $FF);
  FSpawnCount := INITIAL_SPAWN_COUNT;
end;

destructor TDoomScriptEntityTable.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to DS_MAX_GENTITIES - 1 do
    FObjects[LIndex].Free;
  inherited;
end;

procedure TDoomScriptEntityTable.CheckNumber(const ANumber: Integer);
begin
  if (ANumber < 0) or (ANumber >= DS_MAX_GENTITIES) then
    raise EDoomScriptError.CreateFmt(SBadNumber, [ANumber]);
end;

procedure TDoomScriptEntityTable.Add(const ANumber: Integer; const ATarget: TDoomScriptEventTarget;
  const AName: AnsiString);
begin
  CheckNumber(ANumber);
  if not Assigned(ATarget) then
    raise EDoomScriptError.Create(SNoTarget);
  if Assigned(FTargets[ANumber]) then
    raise EDoomScriptError.CreateFmt(STaken, [ANumber]);
  FTargets[ANumber] := ATarget;
  FNames[ANumber] := AName;
  FObjects[ANumber] := TDoomScriptObject.Create(FProgram);
  FSpawnIds[ANumber] := FSpawnCount;
  Inc(FSpawnCount);
end;

procedure TDoomScriptEntityTable.Remove(const ANumber: Integer);
begin
  CheckNumber(ANumber);
  FTargets[ANumber] := nil;
  FNames[ANumber] := '';
  FreeAndNil(FObjects[ANumber]);
end;

function TDoomScriptEntityTable.Exists(const ANumber: Integer): Boolean;
begin
  Result := (ANumber >= 0) and (ANumber < DS_MAX_GENTITIES) and Assigned(FTargets[ANumber]);
end;

function TDoomScriptEntityTable.TargetOf(const ANumber: Integer): TDoomScriptEventTarget;
begin
  if (ANumber >= 0) and (ANumber < DS_MAX_GENTITIES) then
    Result := FTargets[ANumber]
  else
    Result := nil;
end;

function TDoomScriptEntityTable.NameOf(const ANumber: Integer): AnsiString;
begin
  if (ANumber >= 0) and (ANumber < DS_MAX_GENTITIES) then
    Result := FNames[ANumber]
  else
    Result := '';
end;

procedure TDoomScriptEntityTable.Rename(const ANumber: Integer; const AName: AnsiString);
begin
  CheckNumber(ANumber);
  if Assigned(FTargets[ANumber]) then
    FNames[ANumber] := AName;
end;

function TDoomScriptEntityTable.SpawnIdOf(const ANumber: Integer): Integer;
begin
  if (ANumber >= 0) and (ANumber < DS_MAX_GENTITIES) then
    Result := FSpawnIds[ANumber]
  else
    Result := -1;
end;

function TDoomScriptEntityTable.EntityPtr(const ANumber: Integer): Integer;
begin
  if Exists(ANumber) then
    Result := (FSpawnIds[ANumber] shl ENTITY_NUMBER_BITS) or ANumber
  else
    Result := 0;
end;

function TDoomScriptEntityTable.ResolveEntityPtr(const AValue: Integer): Integer;
var
  LNumber: Integer;
begin
  LNumber := AValue and (DS_MAX_GENTITIES - 1);
  // a negative value never matches a spawn id (the shift of the original is arithmetic)
  if Assigned(FTargets[LNumber]) and (AValue >= 0) and (FSpawnIds[LNumber] = AValue shr ENTITY_NUMBER_BITS) then
    Result := LNumber
  else
    Result := -1;
end;

function TDoomScriptEntityTable.ObjectOf(const ANumber: Integer): TDoomScriptObject;
begin
  if (ANumber >= 0) and (ANumber < DS_MAX_GENTITIES) then
    Result := FObjects[ANumber]
  else
    Result := nil;
end;

function TDoomScriptEntityTable.NumberOf(const ATarget: TDoomScriptEventTarget): Integer;
var
  LIndex: Integer;
begin
  if Assigned(ATarget) then
    for LIndex := 0 to DS_MAX_GENTITIES - 1 do
      if FTargets[LIndex] = ATarget then
        Exit(LIndex);
  Result := -1;
end;

function TDoomScriptEntityTable.GetEntity(const AScriptNumber: Integer): TDoomScriptEventTarget;
begin
  if (AScriptNumber > 0) and (AScriptNumber <= DS_MAX_GENTITIES) then
    Result := FTargets[AScriptNumber - 1]
  else
    Result := nil;
end;

function TDoomScriptEntityTable.GetScriptObject(const AScriptNumber: Integer): TDoomScriptObject;
begin
  Result := nil;
  if (AScriptNumber > 0) and (AScriptNumber <= DS_MAX_GENTITIES) then
  begin
    Result := FObjects[AScriptNumber - 1];
    if Assigned(Result) and not Result.HasData then
      Result := nil;
  end;
end;

procedure TDoomScriptEntityTable.ReleaseObjects(const ATypeCount: Integer);
var
  LIndex: Integer;
  LTypeIndex: Integer;
  LKeep: Boolean;
begin
  for LIndex := 0 to DS_MAX_GENTITIES - 1 do
    if Assigned(FObjects[LIndex]) and FObjects[LIndex].HasObject then
    begin
      LKeep := False;
      for LTypeIndex := 0 to ATypeCount - 1 do
        if FProgram.GetTypeByIndex(LTypeIndex) = FObjects[LIndex].GetTypeDef then
        begin
          LKeep := True;
          Break;
        end;
      if not LKeep then
        FObjects[LIndex].FreeObject;
    end;
end;

end.
