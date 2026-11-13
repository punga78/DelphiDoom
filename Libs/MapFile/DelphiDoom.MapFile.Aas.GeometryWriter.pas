{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing the geometry of an .aas file         }
{                                                                              }
{  Port of the sections planes, vertices, edges, edgeIndex, faces and          }
{  faceIndex of idAASFileLocal::Write (AASFile.cpp), Doom 3 GPL Source Code.   }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.GeometryWriter;

interface

uses
  DelphiDoom.MapFile.TextWriter, DelphiDoom.MapFile.Aas.AasFile;

type
  /// <summary>
  ///   Writes the sections "name N {" with one line "\tI ( values )" per element. A plane is
  ///   written with the distance, not with <c>d</c>
  /// </summary>
  TAasGeometryWriter = class
  strict private
    class procedure BeginSection(const AOutput: TMapTextWriter; const AName: AnsiString;
      const ACount: Integer); static;
    class procedure BeginLine(const AOutput: TMapTextWriter; const AIndex: Integer); static;
    class procedure EndSection(const AOutput: TMapTextWriter); static;
  public
    class procedure WritePlanes(const AOutput: TMapTextWriter; const AFile: TAasFile); static;
    class procedure WriteVertices(const AOutput: TMapTextWriter; const AFile: TAasFile); static;
    class procedure WriteEdges(const AOutput: TMapTextWriter; const AFile: TAasFile); static;
    class procedure WriteFaces(const AOutput: TMapTextWriter; const AFile: TAasFile); static;
    /// <summary>One of edgeIndex, faceIndex and portalIndex: a list of integers</summary>
    class procedure WriteIndex(const AOutput: TMapTextWriter; const AName: AnsiString;
      const AIndex: TArray<Integer>); static;
  end;

implementation

uses
  System.SysUtils;

{ TAasGeometryWriter }

class procedure TAasGeometryWriter.BeginSection(const AOutput: TMapTextWriter; const AName: AnsiString;
  const ACount: Integer);
begin
  AOutput.Add(AName + ' ');
  AOutput.AddInteger(ACount);
  AOutput.Add(' {'#10);
end;

class procedure TAasGeometryWriter.BeginLine(const AOutput: TMapTextWriter; const AIndex: Integer);
begin
  AOutput.Add(#9);
  AOutput.AddInteger(AIndex);
  AOutput.Add(' ( ');
end;

class procedure TAasGeometryWriter.EndSection(const AOutput: TMapTextWriter);
begin
  AOutput.Add('}'#10);
end;

class procedure TAasGeometryWriter.WritePlanes(const AOutput: TMapTextWriter; const AFile: TAasFile);
var
  LIndex: Integer;
begin
  BeginSection(AOutput, 'planes', AFile.NumPlanes);
  for LIndex := 0 to AFile.NumPlanes - 1 do
  begin
    BeginLine(AOutput, LIndex);
    AOutput.AddFloat(AFile.Planes[LIndex].A);
    AOutput.Add(' ');
    AOutput.AddFloat(AFile.Planes[LIndex].B);
    AOutput.Add(' ');
    AOutput.AddFloat(AFile.Planes[LIndex].C);
    AOutput.Add(' ');
    AOutput.AddFloat(AFile.Planes[LIndex].Dist);
    AOutput.Add(' )'#10);
  end;
  EndSection(AOutput);
end;

class procedure TAasGeometryWriter.WriteVertices(const AOutput: TMapTextWriter; const AFile: TAasFile);
var
  LIndex: Integer;
begin
  BeginSection(AOutput, 'vertices', AFile.NumVertices);
  for LIndex := 0 to AFile.NumVertices - 1 do
  begin
    BeginLine(AOutput, LIndex);
    AOutput.AddFloat(AFile.Vertices[LIndex].X);
    AOutput.Add(' ');
    AOutput.AddFloat(AFile.Vertices[LIndex].Y);
    AOutput.Add(' ');
    AOutput.AddFloat(AFile.Vertices[LIndex].Z);
    AOutput.Add(' )'#10);
  end;
  EndSection(AOutput);
end;

class procedure TAasGeometryWriter.WriteEdges(const AOutput: TMapTextWriter; const AFile: TAasFile);
var
  LIndex: Integer;
begin
  BeginSection(AOutput, 'edges', AFile.NumEdges);
  for LIndex := 0 to AFile.NumEdges - 1 do
  begin
    BeginLine(AOutput, LIndex);
    AOutput.AddInteger(AFile.Edges[LIndex].VertexNum[0]);
    AOutput.Add(' ');
    AOutput.AddInteger(AFile.Edges[LIndex].VertexNum[1]);
    AOutput.Add(' )'#10);
  end;
  EndSection(AOutput);
end;

class procedure TAasGeometryWriter.WriteFaces(const AOutput: TMapTextWriter; const AFile: TAasFile);
var
  LIndex: Integer;
begin
  BeginSection(AOutput, 'faces', AFile.NumFaces);
  for LIndex := 0 to AFile.NumFaces - 1 do
  begin
    BeginLine(AOutput, LIndex);
    // the order of the file is not the order of the record: planeNum flags areas[0] areas[1]
    // firstEdge numEdges
    AOutput.AddInteger(AFile.Faces[LIndex].PlaneNum);
    AOutput.Add(' ');
    AOutput.AddInteger(AFile.Faces[LIndex].Flags);
    AOutput.Add(' ');
    AOutput.AddInteger(AFile.Faces[LIndex].Areas[0]);
    AOutput.Add(' ');
    AOutput.AddInteger(AFile.Faces[LIndex].Areas[1]);
    AOutput.Add(' ');
    AOutput.AddInteger(AFile.Faces[LIndex].FirstEdge);
    AOutput.Add(' ');
    AOutput.AddInteger(AFile.Faces[LIndex].NumEdges);
    AOutput.Add(' )'#10);
  end;
  EndSection(AOutput);
end;

class procedure TAasGeometryWriter.WriteIndex(const AOutput: TMapTextWriter; const AName: AnsiString;
  const AIndex: TArray<Integer>);
var
  LIndex: Integer;
begin
  BeginSection(AOutput, AName, Length(AIndex));
  for LIndex := 0 to Length(AIndex) - 1 do
  begin
    BeginLine(AOutput, LIndex);
    AOutput.AddInteger(AIndex[LIndex]);
    AOutput.Add(' )'#10);
  end;
  EndSection(AOutput);
end;

end.
