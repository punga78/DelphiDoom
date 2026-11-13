{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - writing the tree of an .aas file             }
{                                                                              }
{  Port of the sections nodes, portals and clusters of idAASFileLocal::Write   }
{  (AASFile.cpp), Doom 3 GPL Source Code.                                      }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.TreeWriter;

interface

uses
  DelphiDoom.MapFile.TextWriter, DelphiDoom.MapFile.Aas.AasFile;

type
  /// <summary>Writes "nodes", "portals" and "clusters"</summary>
  TAasTreeWriter = class
  public
    class procedure WriteNodes(const AOutput: TMapTextWriter; const AFile: TAasFile); static;
    /// <summary><c>MaxAreaTravelTime</c> is not written: the routing computes it after the load</summary>
    class procedure WritePortals(const AOutput: TMapTextWriter; const AFile: TAasFile); static;
    /// <summary>The order of the file is numAreas, numReachableAreas, firstPortal, numPortals</summary>
    class procedure WriteClusters(const AOutput: TMapTextWriter; const AFile: TAasFile); static;
  end;

implementation

uses
  DelphiDoom.MapFile.Aas.Types;

procedure BeginSection(const AOutput: TMapTextWriter; const AName: AnsiString; const ACount: Integer);
begin
  AOutput.Add(AName + ' ');
  AOutput.AddInteger(ACount);
  AOutput.Add(' {'#10);
end;

procedure AddLine(const AOutput: TMapTextWriter; const AIndex: Integer; const AValues: array of Integer);
var
  LPosition: Integer;
begin
  AOutput.Add(#9);
  AOutput.AddInteger(AIndex);
  AOutput.Add(' (');
  for LPosition := 0 to High(AValues) do
  begin
    AOutput.Add(' ');
    AOutput.AddInteger(AValues[LPosition]);
  end;
  AOutput.Add(' )'#10);
end;

{ TAasTreeWriter }

class procedure TAasTreeWriter.WriteNodes(const AOutput: TMapTextWriter; const AFile: TAasFile);
var
  LIndex: Integer;
begin
  BeginSection(AOutput, 'nodes', AFile.NumNodes);
  for LIndex := 0 to AFile.NumNodes - 1 do
    AddLine(AOutput, LIndex, [AFile.Nodes[LIndex].PlaneNum, AFile.Nodes[LIndex].Children[0],
      AFile.Nodes[LIndex].Children[1]]);
  AOutput.Add('}'#10);
end;

class procedure TAasTreeWriter.WritePortals(const AOutput: TMapTextWriter; const AFile: TAasFile);
var
  LIndex: Integer;
  LPortal: TAasPortal;
begin
  BeginSection(AOutput, 'portals', AFile.NumPortals);
  for LIndex := 0 to AFile.NumPortals - 1 do
  begin
    LPortal := AFile.Portals[LIndex];
    AddLine(AOutput, LIndex, [LPortal.AreaNum, LPortal.Clusters[0], LPortal.Clusters[1],
      LPortal.ClusterAreaNum[0], LPortal.ClusterAreaNum[1]]);
  end;
  AOutput.Add('}'#10);
end;

class procedure TAasTreeWriter.WriteClusters(const AOutput: TMapTextWriter; const AFile: TAasFile);
var
  LIndex: Integer;
begin
  BeginSection(AOutput, 'clusters', AFile.NumClusters);
  for LIndex := 0 to AFile.NumClusters - 1 do
    AddLine(AOutput, LIndex, [AFile.Clusters[LIndex].NumAreas, AFile.Clusters[LIndex].NumReachableAreas,
      AFile.Clusters[LIndex].FirstPortal, AFile.Clusters[LIndex].NumPortals]);
  AOutput.Add('}'#10);
end;

end.
