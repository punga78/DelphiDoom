{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - an entity                                    }
{                                                                              }
{  Port of idMapEntity (MapFile.h, MapFile.cpp, idlib), Doom 3 GPL Source      }
{  Code. Based on the Doom 3 GPL Source Code (id Software). Copyright (C)      }
{  1999-2011 id Software LLC, a ZeniMax Media company. This unit is derived    }
{  from the Doom 3 GPL source code and is therefore available under the GNU    }
{  General Public License, version 3, with the additional terms of the Doom 3  }
{  Source Code License (see README.md of Libs\IdLib); the repository as a      }
{  whole is GPL v2 or later.                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Entity;

interface

uses
  System.Generics.Collections, DelphiDoom.Scanner.IdDict, DelphiDoom.MapFile.Primitive;

type
  /// <summary>
  ///   The key/value pairs of an entity and its brushes and patches, in file order. It owns
  ///   its dictionary and its primitives
  /// </summary>
  TMapEntity = class
  strict private
    FEpairs: TIdDict;
    FPrimitives: TObjectList<TMapPrimitive>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds a primitive; the entity owns it from now on (AddPrimitive)</summary>
    procedure AddPrimitive(const APrimitive: TMapPrimitive);
    function GetNumPrimitives: Integer;
    function GetPrimitive(const AIndex: Integer): TMapPrimitive;
    /// <summary>The exclusive or of the checksums of the primitives (idMapEntity::GetGeometryCRC)</summary>
    function GetGeometryCrc: Cardinal;
    /// <summary>Frees the brushes and patches and keeps the key/value pairs</summary>
    procedure RemovePrimitiveData;
    /// <summary>
    ///   Moves all the primitives to the end of the other entity, which owns them from now on
    ///   (<c>entities[0]->primitives.Append( mapEnt->primitives ); mapEnt->primitives.Clear()</c>)
    /// </summary>
    procedure MovePrimitivesTo(const ATarget: TMapEntity);
    property Epairs: TIdDict read FEpairs;
  end;

implementation

{ TMapEntity }

constructor TMapEntity.Create;
begin
  inherited Create;
  FEpairs := TIdDict.Create;
  FPrimitives := TObjectList<TMapPrimitive>.Create(True);
end;

destructor TMapEntity.Destroy;
begin
  FPrimitives.Free;
  FEpairs.Free;
  inherited Destroy;
end;

procedure TMapEntity.AddPrimitive(const APrimitive: TMapPrimitive);
begin
  FPrimitives.Add(APrimitive);
end;

function TMapEntity.GetNumPrimitives: Integer;
begin
  Result := FPrimitives.Count;
end;

function TMapEntity.GetPrimitive(const AIndex: Integer): TMapPrimitive;
begin
  Result := FPrimitives[AIndex];
end;

function TMapEntity.GetGeometryCrc: Cardinal;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to FPrimitives.Count - 1 do
    Result := Result xor FPrimitives[LIndex].GetGeometryCrc;
end;

procedure TMapEntity.RemovePrimitiveData;
begin
  FPrimitives.Clear;
end;

procedure TMapEntity.MovePrimitivesTo(const ATarget: TMapEntity);
begin
  ATarget.FPrimitives.AddRange(FPrimitives);
  // the target owns the objects now: clear this list without freeing them
  FPrimitives.OwnsObjects := False;
  try
    FPrimitives.Clear;
  finally
    FPrimitives.OwnsObjects := True;
  end;
end;

end.
