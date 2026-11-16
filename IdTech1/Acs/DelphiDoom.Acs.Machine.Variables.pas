{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS library - the variables of the map and of the world         }
{  Port of the interpreter of Hexen (p_acs.c, Raven Software)                  }
{  Copyright (C) 1995 Raven Software, Corp.                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Machine.Variables;

interface

uses
  DelphiDoom.Acs.Machine.Types;

type
  /// <summary>
  ///   What the scripts share: the variables of the map (they start at zero with the map), the
  ///   variables of the world (they last for the whole game) and the store of the scripts that wait
  ///   for another map
  /// </summary>
  TAcsVariables = class
  strict private
    FMap: TAcsMapVariables;
    FWorld: TAcsWorldVariables;
    FStore: TAcsStore;
  public
    constructor Create;
    property Map: TAcsMapVariables read FMap write FMap;
    property World: TAcsWorldVariables read FWorld write FWorld;
    property Store: TAcsStore read FStore write FStore;
    procedure ClearMap;
    /// <summary>A new game: the variables of the world and the store are empty</summary>
    procedure ClearWorld;
    /// <summary>Where a variable of the map is; nil if the index is wrong</summary>
    function MapSlot(AIndex: Integer): PInteger;
    function WorldSlot(AIndex: Integer): PInteger;
    /// <summary>
    ///   Puts the script in the store. False if it is there already. Raises EAcsMachineException
    ///   if the store is full
    /// </summary>
    function AddToStore(AMap, AScript: Integer; const AArguments: TAcsArguments): Boolean;
    /// <summary>The entry of the store; the list ends with the entry that has the map 0</summary>
    function StoreEntry(AIndex: Integer): PAcsStoreEntry;
  end;

implementation

uses
  System.SysUtils;

{ TAcsVariables }

constructor TAcsVariables.Create;
begin
  inherited Create;
  ClearWorld;
  ClearMap;
end;

procedure TAcsVariables.ClearMap;
begin
  FillChar(FMap, SizeOf(FMap), 0);
end;

procedure TAcsVariables.ClearWorld;
begin
  FillChar(FWorld, SizeOf(FWorld), 0);
  FillChar(FStore, SizeOf(FStore), 0);
end;

function TAcsVariables.MapSlot(AIndex: Integer): PInteger;
begin
  if (AIndex >= 0) and (AIndex < ACS_MAP_VARIABLE_COUNT) then
    Result := @FMap[AIndex]
  else
    Result := nil;
end;

function TAcsVariables.WorldSlot(AIndex: Integer): PInteger;
begin
  if (AIndex >= 0) and (AIndex < ACS_WORLD_VARIABLE_COUNT) then
    Result := @FWorld[AIndex]
  else
    Result := nil;
end;

function TAcsVariables.AddToStore(AMap, AScript: Integer; const AArguments: TAcsArguments): Boolean;
var
  LIndex: Integer;
  LFree: Integer;
begin
  LFree := -1;
  LIndex := 0;
  while FStore[LIndex].Map <> 0 do
  begin
    if (FStore[LIndex].Script = AScript) and (FStore[LIndex].Map = AMap) then
      Exit(False); // no duplicates
    if (LFree = -1) and (FStore[LIndex].Map = -1) then
      LFree := LIndex; // the first free entry
    Inc(LIndex);
  end;
  if LFree = -1 then
  begin
    if LIndex = ACS_STORE_SIZE then
      raise EAcsMachineException.CreateFmt(SAcsStoreFull, [ACS_STORE_SIZE]);
    LFree := LIndex;
    FStore[LFree + 1].Map := 0;
  end;
  FStore[LFree].Map := AMap;
  FStore[LFree].Script := AScript;
  Move(AArguments, FStore[LFree].Args, SizeOf(AArguments));
  Result := True;
end;

function TAcsVariables.StoreEntry(AIndex: Integer): PAcsStoreEntry;
begin
  Result := @FStore[AIndex];
end;

end.
