{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: visibility        }
{                                                                              }
{  Port of R_LoadVisibility (tr_bsp.c). Based on the Quake III Arena GPL       }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.VisibilityLoader;

interface

uses
  System.SysUtils, DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MapFile.Bsp.RenderTypes;

type
  /// <summary>
  ///   R_LoadVisibility. The "novis" row is allocated first, for the clusters of the tree
  ///   (R_LoadNodesAndLeafs), rounded up to 64 bytes and filled with 255. A lump with something
  ///   in it gives the cluster count and the row size of its two integers, and the rest of the
  ///   bytes as the rows; the result is byte for byte what TBspFile.Visibility holds, which is
  ///   also what the collision model keeps (CMod_LoadVisibility), so a renderer that has the
  ///   collision model can share its rows (the externalVisData of the original). An empty
  ///   lump keeps the cluster count of the tree and has no rows (the collision model makes
  ///   32-byte rows of 255 instead: another length, not the same data).
  /// </summary>
  TBspVisibilityLoader = class(TInterfacedObject, IBspVisibilityLoader)
  public
    function Load(const ALump: TBytes; const ATreeClusters: Integer): TBspVisibility;
  end;

implementation

uses
  DelphiDoom.MapFile.Bsp.Types;

const
  /// <summary>The two integers in front of the rows</summary>
  VIS_HEADER = 8;
  /// <summary>Clusters the "novis" row can have: far more than any map</summary>
  MAX_CLUSTERS = 1 shl 28;

resourcestring
  SVisTooShort = 'R_LoadVisibility: the visibility lump has %d bytes, the header needs 8';
  SVisTooManyClusters = 'R_LoadVisibility: %d clusters';

{ TBspVisibilityLoader }

function TBspVisibilityLoader.Load(const ALump: TBytes; const ATreeClusters: Integer): TBspVisibility;
var
  LLength, LIndex: Integer;
begin
  if (ATreeClusters < 0) or (ATreeClusters > MAX_CLUSTERS) then
    raise EBspFileException.CreateFmt(SVisTooManyClusters, [ATreeClusters]);
  Result.NumClusters := ATreeClusters;
  Result.ClusterBytes := 0;
  Result.Vis := nil;
  LLength := (ATreeClusters + 63) and not 63;
  SetLength(Result.Novis, LLength);
  for LIndex := 0 to LLength - 1 do
    Result.Novis[LIndex] := 255;

  if Length(ALump) = 0 then
    Exit;
  if Length(ALump) < VIS_HEADER then
    raise EBspFileException.CreateFmt(SVisTooShort, [Length(ALump)]);
  Move(ALump[0], Result.NumClusters, 4);
  Move(ALump[4], Result.ClusterBytes, 4);
  SetLength(Result.Vis, Length(ALump) - VIS_HEADER);
  if Length(Result.Vis) > 0 then
    Move(ALump[VIS_HEADER], Result.Vis[0], Length(Result.Vis));
end;

end.
