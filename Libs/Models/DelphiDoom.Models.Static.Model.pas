{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: the model                    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model.cpp       }
{  (idRenderModelStatic: AddSurface, bounds). Copyright (C) 1999-2011 id       }
{  Software LLC, a ZeniMax Media company. This unit is derived from the Doom 3 }
{  GPL source code and is therefore available under the GNU General Public     }
{  License, version 3, with the additional terms of the Doom 3 Source Code     }
{  License (see README.md of Libs\IdLib); the repository as a whole is GPL v2  }
{  or later.                                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Model;

interface

uses
  System.SysUtils,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Intf;

type
  /// <summary>
  ///   The model that the converters fill: <c>AddSurface</c> gives the id, <c>SetGeometry</c> sets
  ///   or merges the triangles of a surface, <c>Finish</c> computes the bounds. After <c>Finish</c>
  ///   it is read only.
  /// </summary>
  TStaticModel = class(TInterfacedObject, IStaticModel)
  strict private
    FName: string;
    FSurfaces: TArray<TStaticSurface>;
    FBounds: TGeoBounds;
    FWarnings: TArray<string>;
    function GetName: string;
    function GetNumSurfaces: Integer;
    function GetSurface(const AIndex: Integer): TStaticSurface;
    function GetBounds: TGeoBounds;
    function GetWarnings: TArray<string>;
  public
    constructor Create(const AName: string);
    /// <summary>idRenderModelStatic::AddSurface: the new surface gets the next id; returns its index</summary>
    function AddSurface(const AMaterialName: AnsiString): Integer;
    /// <summary>The material name of a surface (the converters look for equal materials to merge)</summary>
    function MaterialName(const AIndex: Integer): AnsiString;
    /// <summary>The first geometry of a surface is kept, the next ones are merged after it (R_MergeTriangles)</summary>
    procedure AddGeometry(const AIndex: Integer; const ATriangles: TStaticTriangles);
    procedure AddWarning(const AText: string);
    /// <summary>Computes the box of the surfaces that have geometry</summary>
    procedure Finish;
    function TotalVerts: Integer;
    function TotalIndexes: Integer;
    /// <summary>The surfaces added so far (the same as IStaticModel.NumSurfaces, usable on the class)</summary>
    property NumSurfaces: Integer read GetNumSurfaces;
  end;

implementation

{ TStaticModel }

constructor TStaticModel.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FBounds := TGeoBounds.Cleared;
end;

function TStaticModel.AddSurface(const AMaterialName: AnsiString): Integer;
begin
  Result := Length(FSurfaces);
  SetLength(FSurfaces, Result + 1);
  FSurfaces[Result].Id := Result;
  FSurfaces[Result].MaterialName := AMaterialName;
  FSurfaces[Result].HasGeometry := False;
end;

function TStaticModel.MaterialName(const AIndex: Integer): AnsiString;
begin
  Result := FSurfaces[AIndex].MaterialName;
end;

procedure TStaticModel.AddGeometry(const AIndex: Integer; const ATriangles: TStaticTriangles);
begin
  if FSurfaces[AIndex].HasGeometry then
    FSurfaces[AIndex].Triangles := TStaticTriangles.Merge(FSurfaces[AIndex].Triangles, ATriangles)
  else
  begin
    FSurfaces[AIndex].Triangles := ATriangles;
    FSurfaces[AIndex].HasGeometry := True;
  end;
end;

procedure TStaticModel.AddWarning(const AText: string);
begin
  SetLength(FWarnings, Length(FWarnings) + 1);
  FWarnings[High(FWarnings)] := AText;
end;

procedure TStaticModel.Finish;
var
  LIndex: Integer;
begin
  FBounds := TGeoBounds.Cleared;
  for LIndex := 0 to High(FSurfaces) do
    if FSurfaces[LIndex].HasGeometry then
      FBounds.AddBounds(FSurfaces[LIndex].Triangles.CalcBounds);
end;

function TStaticModel.GetName: string;
begin
  Result := FName;
end;

function TStaticModel.GetNumSurfaces: Integer;
begin
  Result := Length(FSurfaces);
end;

function TStaticModel.GetSurface(const AIndex: Integer): TStaticSurface;
begin
  if (AIndex < 0) or (AIndex > High(FSurfaces)) then
    raise EArgumentOutOfRangeException.CreateFmt('Surface %d does not exist (%d surfaces)',
      [AIndex, Length(FSurfaces)]);
  Result := FSurfaces[AIndex];
end;

function TStaticModel.GetBounds: TGeoBounds;
begin
  Result := FBounds;
end;

function TStaticModel.GetWarnings: TArray<string>;
begin
  Result := FWarnings;
end;

function TStaticModel.TotalVerts: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to High(FSurfaces) do
    Inc(Result, FSurfaces[LIndex].Triangles.NumVerts);
end;

function TStaticModel.TotalIndexes: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to High(FSurfaces) do
    Inc(Result, FSurfaces[LIndex].Triangles.NumIndexes);
end;

end.
