{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the directives of the worldspawn             }
{                                                                              }
{  Port of the second half of idMapFile::Parse (MapFile.cpp, idlib), Doom 3    }
{  GPL Source Code. Based on the Doom 3 GPL Source Code (id Software).         }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. This      }
{  unit is derived from the Doom 3 GPL source code and is therefore            }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Directives;

interface

uses
  DelphiDoom.MapFile.Map;

type
  /// <summary>
  ///   The keys of the worldspawn that change the whole map: "removeEntities", "overrideMaterial",
  ///   "forceEntityNames" and "moveFuncGroups". The reader applies them after the parse, in this order
  /// </summary>
  TMapDirectives = class
  strict private
    class procedure RemoveEntities(const AMap: TMapFile); static;
    class procedure OverrideMaterial(const AMap: TMapFile); static;
    class procedure ForceEntityNames(const AMap: TMapFile); static;
    class procedure MoveFuncGroups(const AMap: TMapFile); static;
  public
    /// <summary>
    ///   Applies the directives of the first entity; a map without entities is left alone.
    ///   The "removeEntities" values are all read before any entity is removed (the original
    ///   goes on reading the worldspawn after freeing it if it removes itself)
    /// </summary>
    class procedure Apply(const AMap: TMapFile); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Scanner.IdDict, DelphiDoom.MapFile.Types,
  DelphiDoom.MapFile.Entity, DelphiDoom.MapFile.Primitive,
  DelphiDoom.MapFile.Brush, DelphiDoom.MapFile.Patch;

const
  REMOVE_PREFIX: AnsiString = 'removeEntities';

{ TMapDirectives }

class procedure TMapDirectives.Apply(const AMap: TMapFile);
begin
  if AMap.GetNumEntities = 0 then
    Exit;
  RemoveEntities(AMap);
  if AMap.GetNumEntities = 0 then
    Exit;
  OverrideMaterial(AMap);
  ForceEntityNames(AMap);
  MoveFuncGroups(AMap);
end;

class procedure TMapDirectives.RemoveEntities(const AMap: TMapFile);
var
  LWorld: TMapEntity;
  LIndex: Integer;
  LClassNames: TArray<AnsiString>;
  LClassName: AnsiString;
  LKeyValue: TIdKeyValue;
begin
  LWorld := AMap.GetEntity(0);
  LIndex := LWorld.Epairs.MatchPrefix(REMOVE_PREFIX);
  while LIndex >= 0 do
  begin
    if LWorld.Epairs.TryGetKeyVal(LIndex, LKeyValue) then
    begin
      SetLength(LClassNames, Length(LClassNames) + 1);
      LClassNames[High(LClassNames)] := LKeyValue.Value;
    end;
    LIndex := LWorld.Epairs.MatchPrefix(REMOVE_PREFIX, LIndex);
  end;
  for LClassName in LClassNames do
    AMap.RemoveEntities(LClassName);
end;

class procedure TMapDirectives.OverrideMaterial(const AMap: TMapFile);
var
  LMaterial: AnsiString;
  LEntity: TMapEntity;
  LPrimitive: TMapPrimitive;
  LBrush: TMapBrush;
  LEntityIndex, LPrimitiveIndex, LSideIndex: Integer;
begin
  // "overrideMaterial" "material" can be set in the worldspawn to reset all materials
  if not AMap.GetEntity(0).Epairs.GetString('overrideMaterial', '', LMaterial) then
    Exit;
  for LEntityIndex := 0 to AMap.GetNumEntities - 1 do
  begin
    LEntity := AMap.GetEntity(LEntityIndex);
    for LPrimitiveIndex := 0 to LEntity.GetNumPrimitives - 1 do
    begin
      LPrimitive := LEntity.GetPrimitive(LPrimitiveIndex);
      case LPrimitive.PrimitiveType of
        mptBrush:
          begin
            LBrush := TMapBrush(LPrimitive);
            for LSideIndex := 0 to LBrush.GetNumSides - 1 do
              LBrush.GetSide(LSideIndex).Material := LMaterial;
          end;
        mptPatch:
          TMapPatch(LPrimitive).Material := LMaterial;
      end;
    end;
  end;
end;

class procedure TMapDirectives.ForceEntityNames(const AMap: TMapFile);
var
  LIndex: Integer;
  LEntity: TMapEntity;
begin
  // force all entities to have a name key/value pair
  if not AMap.GetEntity(0).Epairs.GetBool('forceEntityNames') then
    Exit;
  for LIndex := 1 to AMap.GetNumEntities - 1 do
  begin
    LEntity := AMap.GetEntity(LIndex);
    if LEntity.Epairs.FindKeyIndex('name') < 0 then
      LEntity.Epairs.SetValue('name', LEntity.Epairs.GetString('classname', 'forcedName') +
        AnsiString(IntToStr(LIndex)));
  end;
end;

class procedure TMapDirectives.MoveFuncGroups(const AMap: TMapFile);
var
  LIndex: Integer;
  LEntity: TMapEntity;
  LWorld: TMapEntity;
begin
  // move the primitives of any func_group entities to the worldspawn
  LWorld := AMap.GetEntity(0);
  if not LWorld.Epairs.GetBool('moveFuncGroups') then
    Exit;
  for LIndex := 1 to AMap.GetNumEntities - 1 do
  begin
    LEntity := AMap.GetEntity(LIndex);
    if TIdStrings.Icmp(LEntity.Epairs.GetString('classname'), 'func_group') = 0 then
      LEntity.MovePrimitivesTo(LWorld);
  end;
end;

end.
