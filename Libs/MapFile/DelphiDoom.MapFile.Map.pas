{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the contents of a .map file                  }
{                                                                              }
{  Port of idMapFile (MapFile.h, MapFile.cpp, idlib), Doom 3 GPL Source Code.  }
{  The reading and the writing are in TMapFileReader and TMapFileWriter.       }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Map;

interface

uses
  System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Types,
  DelphiDoom.MapFile.Entity;

type
  /// <summary>
  ///   The entities of a map in file order (the first is the worldspawn). No validation is
  ///   done: duplicate planes or empty brushes are kept. It owns its entities
  /// </summary>
  TMapFile = class
  strict private
    FVersion: Single;
    FFileTime: Int64;
    FGeometryCrc: Cardinal;
    FEntities: TObjectList<TMapEntity>;
    FName: AnsiString;
    FHasPrimitiveData: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function GetNumEntities: Integer;
    function GetEntity(const AIndex: Integer): TMapEntity;
    /// <summary>Adds an entity, which the map owns from now on, and returns its index (AddEntity)</summary>
    function AddEntity(const AEntity: TMapEntity): Integer;
    /// <summary>The first entity whose "name" is the given one (without regard to case), nil if none</summary>
    function FindEntity(const AName: AnsiString): TMapEntity;
    /// <summary>Removes and frees the entity (not found: nothing happens)</summary>
    procedure RemoveEntity(const AEntity: TMapEntity);
    /// <summary>Removes the entities whose "classname" is the given one (without regard to case)</summary>
    procedure RemoveEntities(const AClassName: AnsiString);
    procedure RemoveAllEntities;
    procedure RemovePrimitiveData;
    /// <summary>The exclusive or of the checksums of the entities; the reader stores it after the parse (SetGeometryCRC)</summary>
    procedure UpdateGeometryCrc;
    /// <summary>
    ///   True if the file changed on disk after the reading (NeedsReload). The original looks up
    ///   the name without extension, which is never a file: a map read from disk always asks to
    ///   be reloaded unless the file system finds that name
    /// </summary>
    function NeedsReload(const AFileSystem: IIdLibFileSystem): Boolean;
    /// <summary>The version of the "Version" line, <c>OLD_MAP_VERSION</c> if the file has none</summary>
    property Version: Single read FVersion write FVersion;
    property FileTime: Int64 read FFileTime write FFileTime;
    /// <summary>The checksum of the geometry: texture coordinates and key/value pairs do not count</summary>
    property GeometryCrc: Cardinal read FGeometryCrc;
    /// <summary>The name without file extension</summary>
    property Name: AnsiString read FName write FName;
    property HasPrimitiveData: Boolean read FHasPrimitiveData write FHasPrimitiveData;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

{ TMapFile }

constructor TMapFile.Create;
begin
  inherited Create;
  FVersion := CURRENT_MAP_VERSION;
  FEntities := TObjectList<TMapEntity>.Create(True);
end;

destructor TMapFile.Destroy;
begin
  FEntities.Free;
  inherited Destroy;
end;

function TMapFile.GetNumEntities: Integer;
begin
  Result := FEntities.Count;
end;

function TMapFile.GetEntity(const AIndex: Integer): TMapEntity;
begin
  Result := FEntities[AIndex];
end;

function TMapFile.AddEntity(const AEntity: TMapEntity): Integer;
begin
  Result := FEntities.Add(AEntity);
end;

function TMapFile.FindEntity(const AName: AnsiString): TMapEntity;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FEntities.Count - 1 do
  begin
    if TIdStrings.Icmp(FEntities[LIndex].Epairs.GetString('name'), AName) = 0 then
      Exit(FEntities[LIndex]);
  end;
  Result := nil;
end;

procedure TMapFile.RemoveEntity(const AEntity: TMapEntity);
begin
  FEntities.Remove(AEntity);
end;

procedure TMapFile.RemoveEntities(const AClassName: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := FEntities.Count - 1 downto 0 do
  begin
    if TIdStrings.Icmp(FEntities[LIndex].Epairs.GetString('classname'), AClassName) = 0 then
      FEntities.Delete(LIndex);
  end;
end;

procedure TMapFile.RemoveAllEntities;
begin
  FEntities.Clear;
  FHasPrimitiveData := False;
end;

procedure TMapFile.RemovePrimitiveData;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FEntities.Count - 1 do
    FEntities[LIndex].RemovePrimitiveData;
  FHasPrimitiveData := False;
end;

procedure TMapFile.UpdateGeometryCrc;
var
  LIndex: Integer;
begin
  FGeometryCrc := 0;
  for LIndex := 0 to FEntities.Count - 1 do
    FGeometryCrc := FGeometryCrc xor FEntities[LIndex].GetGeometryCrc;
end;

function TMapFile.NeedsReload(const AFileSystem: IIdLibFileSystem): Boolean;
var
  LFile: TIdLibFileData;
begin
  Result := True;
  if (Length(FName) > 0) and Assigned(AFileSystem) then
  begin
    if AFileSystem.TryReadFile(FName, False, LFile) and (Length(LFile.Data) > 0) then
      Result := LFile.Timestamp > FFileTime;
  end;
end;

end.
