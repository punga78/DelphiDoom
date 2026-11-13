{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - reading nodes, portals and clusters of .aas  }
{                                                                              }
{  Port of ParseNodes, ParsePortals and ParseClusters of idAASFileLocal        }
{  (AASFile.cpp), Doom 3 GPL Source Code.                                      }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.TreeReader;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.MapFile.Aas.Types;

type
  /// <summary>
  ///   Reads what follows "nodes" (planeNum, child 0, child 1), "portals" (area, the two
  ///   clusters, the number of the portal area in each cluster) and "clusters" (areas,
  ///   reachable areas, first portal, portals)
  /// </summary>
  TAasTreeReader = class
  public
    class function ReadNodes(const ALexer: TIdLexer): TArray<TAasNode>; static;
    class function ReadPortals(const ALexer: TIdLexer): TArray<TAasPortal>; static;
    class function ReadClusters(const ALexer: TIdLexer): TArray<TAasCluster>; static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.MapFile.Aas.Parse;

{ TAasTreeReader }

class function TAasTreeReader.ReadNodes(const ALexer: TIdLexer): TArray<TAasNode>;
var
  LCount, LIndex: Integer;
  LList: TList<TAasNode>;
  LNode: TAasNode;
begin
  LCount := TAasParse.BeginSection(ALexer, 'nodes');
  LList := TList<TAasNode>.Create;
  try
    for LIndex := 0 to LCount - 1 do
    begin
      TAasParse.BeginElement(ALexer);
      LNode.PlaneNum := Word(ALexer.ParseInt);
      LNode.Children[0] := ALexer.ParseInt;
      LNode.Children[1] := ALexer.ParseInt;
      TAasParse.EndElement(ALexer);
      LList.Add(LNode);
    end;
    TAasParse.EndSection(ALexer);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

class function TAasTreeReader.ReadPortals(const ALexer: TIdLexer): TArray<TAasPortal>;
var
  LCount, LIndex: Integer;
  LList: TList<TAasPortal>;
  LPortal: TAasPortal;
begin
  LCount := TAasParse.BeginSection(ALexer, 'portals');
  LList := TList<TAasPortal>.Create;
  try
    for LIndex := 0 to LCount - 1 do
    begin
      TAasParse.BeginElement(ALexer);
      LPortal.AreaNum := SmallInt(ALexer.ParseInt);
      LPortal.Clusters[0] := SmallInt(ALexer.ParseInt);
      LPortal.Clusters[1] := SmallInt(ALexer.ParseInt);
      LPortal.ClusterAreaNum[0] := SmallInt(ALexer.ParseInt);
      LPortal.ClusterAreaNum[1] := SmallInt(ALexer.ParseInt);
      LPortal.MaxAreaTravelTime := 0;
      TAasParse.EndElement(ALexer);
      LList.Add(LPortal);
    end;
    TAasParse.EndSection(ALexer);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

class function TAasTreeReader.ReadClusters(const ALexer: TIdLexer): TArray<TAasCluster>;
var
  LCount, LIndex: Integer;
  LList: TList<TAasCluster>;
  LCluster: TAasCluster;
begin
  LCount := TAasParse.BeginSection(ALexer, 'clusters');
  LList := TList<TAasCluster>.Create;
  try
    for LIndex := 0 to LCount - 1 do
    begin
      TAasParse.BeginElement(ALexer);
      LCluster.NumAreas := ALexer.ParseInt;
      LCluster.NumReachableAreas := ALexer.ParseInt;
      LCluster.FirstPortal := ALexer.ParseInt;
      LCluster.NumPortals := ALexer.ParseInt;
      TAasParse.EndElement(ALexer);
      LList.Add(LCluster);
    end;
    TAasParse.EndSection(ALexer);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

end.
