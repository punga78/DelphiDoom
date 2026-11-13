{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - reading the lists of shapes of an .aas file  }
{                                                                              }
{  Port of ParsePlanes, ParseVertices, ParseEdges, ParseIndex and ParseFaces   }
{  of idAASFileLocal (AASFile.cpp), Doom 3 GPL Source Code.                    }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.GeometryReader;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Aas.Types;

type
  /// <summary>
  ///   Reads what follows "planes", "vertices", "edges", "edgeIndex", "faces", "faceIndex" and
  ///   "portalIndex". A plane is "(a b c d)" with d the distance (idPlane::SetDist): the
  ///   <c>D</c> of the TGeoPlane that comes out is -d, as in the original
  /// </summary>
  TAasGeometryReader = class
  public
    class function ReadPlanes(const ALexer: TIdLexer): TArray<TGeoPlane>; static;
    class function ReadVertices(const ALexer: TIdLexer): TArray<TGeoVec3>; static;
    class function ReadEdges(const ALexer: TIdLexer): TArray<TAasEdge>; static;
    /// <summary>An index section: one integer in parentheses on each line</summary>
    class function ReadIndex(const ALexer: TIdLexer; const AWhat: string): TArray<Integer>; static;
    class function ReadFaces(const ALexer: TIdLexer): TArray<TAasFace>; static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.MapFile.Aas.Parse;

{ TAasGeometryReader }

class function TAasGeometryReader.ReadPlanes(const ALexer: TIdLexer): TArray<TGeoPlane>;
var
  LCount, LIndex: Integer;
  LList: TList<TGeoPlane>;
  LValues: array[0..3] of Single;
  LPlane: TGeoPlane;
begin
  LCount := TAasParse.BeginSection(ALexer, 'planes');
  LList := TList<TGeoPlane>.Create;
  try
    for LIndex := 0 to LCount - 1 do
    begin
      ALexer.ParseInt;
      ALexer.Parse1DMatrix(4, LValues);
      LPlane := TGeoPlane.Make(TGeoVec3.Make(LValues[0], LValues[1], LValues[2]), LValues[3]);
      LList.Add(LPlane);
    end;
    TAasParse.EndSection(ALexer);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

class function TAasGeometryReader.ReadVertices(const ALexer: TIdLexer): TArray<TGeoVec3>;
var
  LCount, LIndex: Integer;
  LList: TList<TGeoVec3>;
  LValues: array[0..2] of Single;
begin
  LCount := TAasParse.BeginSection(ALexer, 'vertices');
  LList := TList<TGeoVec3>.Create;
  try
    for LIndex := 0 to LCount - 1 do
    begin
      ALexer.ParseInt;
      ALexer.Parse1DMatrix(3, LValues);
      LList.Add(TGeoVec3.Make(LValues[0], LValues[1], LValues[2]));
    end;
    TAasParse.EndSection(ALexer);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

class function TAasGeometryReader.ReadEdges(const ALexer: TIdLexer): TArray<TAasEdge>;
var
  LCount, LIndex: Integer;
  LList: TList<TAasEdge>;
  LEdge: TAasEdge;
begin
  LCount := TAasParse.BeginSection(ALexer, 'edges');
  LList := TList<TAasEdge>.Create;
  try
    for LIndex := 0 to LCount - 1 do
    begin
      TAasParse.BeginElement(ALexer);
      LEdge.VertexNum[0] := ALexer.ParseInt;
      LEdge.VertexNum[1] := ALexer.ParseInt;
      TAasParse.EndElement(ALexer);
      LList.Add(LEdge);
    end;
    TAasParse.EndSection(ALexer);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

class function TAasGeometryReader.ReadIndex(const ALexer: TIdLexer; const AWhat: string): TArray<Integer>;
var
  LCount, LIndex: Integer;
  LList: TList<Integer>;
begin
  LCount := TAasParse.BeginSection(ALexer, AWhat);
  LList := TList<Integer>.Create;
  try
    for LIndex := 0 to LCount - 1 do
    begin
      TAasParse.BeginElement(ALexer);
      LList.Add(ALexer.ParseInt);
      TAasParse.EndElement(ALexer);
    end;
    TAasParse.EndSection(ALexer);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

class function TAasGeometryReader.ReadFaces(const ALexer: TIdLexer): TArray<TAasFace>;
var
  LCount, LIndex: Integer;
  LList: TList<TAasFace>;
  LFace: TAasFace;
begin
  LCount := TAasParse.BeginSection(ALexer, 'faces');
  LList := TList<TAasFace>.Create;
  try
    for LIndex := 0 to LCount - 1 do
    begin
      TAasParse.BeginElement(ALexer);
      LFace.PlaneNum := Word(ALexer.ParseInt);
      LFace.Flags := Word(ALexer.ParseInt);
      LFace.Areas[0] := SmallInt(ALexer.ParseInt);
      LFace.Areas[1] := SmallInt(ALexer.ParseInt);
      LFace.FirstEdge := ALexer.ParseInt;
      LFace.NumEdges := ALexer.ParseInt;
      TAasParse.EndElement(ALexer);
      LList.Add(LFace);
    end;
    TAasParse.EndSection(ALexer);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

end.
