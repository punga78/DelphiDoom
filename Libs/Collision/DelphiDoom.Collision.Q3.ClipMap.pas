{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  the clip map                                                                }
{                                                                              }
{  Port of clipMap_t of cm_local.h and CM_ClipHandleToModel of cm_load.c from  }
{  the Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005  }
{  Id Software, Inc. This unit is derived from the Quake III Arena source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 2 or (at your option) any later version.                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.ClipMap;

interface

uses
  System.SysUtils, DelphiDoom.MapFile.Bsp.Types, DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.Intf;

type
  /// <summary>
  ///   The data of one map as the collision functions use it: the global <c>cm</c> of the
  ///   original, and the box model of CM_InitBoxHull, as an object. The arrays are filled by
  ///   TQ3ClipMapLoader and do not change in length afterwards; the classes of the model work
  ///   on them directly (the trace is the hot path of a game), so the fields are public.
  ///   Planes, brush sides, brushes and leaf brushes have the entries of the box hull after
  ///   the ones of the map; the leaf brushes and leaf surfaces of the brush models follow.
  /// </summary>
  TQ3ClipMap = class
  public
    Name: AnsiString;
    Shaders: TArray<TBspShader>;
    NumShaders: Integer;
    BrushSides: TArray<TQ3BrushSide>;
    NumBrushSides: Integer;
    Planes: TArray<TQ3Plane>;
    NumPlanes: Integer;
    Nodes: TArray<TQ3Node>;
    NumNodes: Integer;
    Leafs: TArray<TQ3Leaf>;
    NumLeafs: Integer;
    LeafBrushes: TArray<Integer>;
    NumLeafBrushes: Integer;
    LeafSurfaces: TArray<Integer>;
    NumLeafSurfaces: Integer;
    Models: TArray<TQ3Model>;
    NumSubModels: Integer;
    Brushes: TArray<TQ3Brush>;
    NumBrushes: Integer;
    NumClusters: Integer;
    ClusterBytes: Integer;
    Visibility: TBytes;
    /// <summary>if False the visibility is a single cluster of ones</summary>
    Vised: Boolean;
    NumEntityChars: Integer;
    EntityString: AnsiString;
    NumAreas: Integer;
    Areas: TArray<TQ3Area>;
    /// <summary>NumAreas * NumAreas reference counts</summary>
    AreaPortals: TArray<Integer>;
    NumSurfaces: Integer;
    /// <summary>one entry per surface; Present is False for the ones that are not patches</summary>
    Patches: TArray<TQ3Patch>;
    /// <summary>the collision geometry of the patches (nil: the patch does not collide)</summary>
    PatchCollides: TArray<IQ3PatchCollide>;
    FloodValid: Integer;
    /// <summary>incremented on each trace</summary>
    CheckCount: Integer;
    /// <summary>box_model of cm_load.c</summary>
    BoxModel: TQ3Model;
    /// <summary>the number of the first plane, brush side, brush of the box hull (CM_InitBoxHull)</summary>
    BoxBrush: Integer;
    /// <summary>cm_noAreas and cm_noCurves</summary>
    NoAreas: Boolean;
    NoCurves: Boolean;
    /// <summary>c_pointcontents, c_traces, c_brush_traces, c_patch_traces</summary>
    PointContentsCount: Integer;
    TraceCount: Integer;
    BrushTraceCount: Integer;
    PatchTraceCount: Integer;
    /// <summary>
    ///   CM_ClipHandleToModel. Like the original, 254 (the capsule handle) is not a model: it
    ///   raises the error unless the map has that many inline models
    /// </summary>
    function ClipHandleToModel(const AHandle: Integer): PQ3Model;
  end;

implementation

resourcestring
  SBadHandle = 'CM_ClipHandleToModel: bad handle %d';
  SBadHandleRange = 'CM_ClipHandleToModel: bad handle %d < %d < %d';

function TQ3ClipMap.ClipHandleToModel(const AHandle: Integer): PQ3Model;
begin
  if AHandle < 0 then
    raise EQ3CollisionException.CreateFmt(SBadHandle, [AHandle]);
  if AHandle < NumSubModels then
    Exit(@Models[AHandle]);
  if AHandle = Q3_BOX_MODEL_HANDLE then
    Exit(@BoxModel);
  if AHandle < Q3_MAX_SUBMODELS then
    raise EQ3CollisionException.CreateFmt(SBadHandleRange, [NumSubModels, AHandle, Q3_MAX_SUBMODELS]);
  raise EQ3CollisionException.CreateFmt(SBadHandle, [AHandle + Q3_MAX_SUBMODELS]);
end;

end.
