{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  contracts                                                                   }
{                                                                              }
{  Port of cm_public.h of the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types;

type
  /// <summary>
  ///   The collision geometry of one patch (patchCollide_t of cm_patch.c). The first slice of
  ///   the port does not have one: the model accepts any implementation, and a patch without
  ///   it does not collide (see the README).
  /// </summary>
  IQ3PatchCollide = interface
    ['{4B7A1E92-6C30-4D85-A9F1-53E8D2C07B46}']
    /// <summary>CM_TraceThroughPatchCollide: lowers AWork.Trace.Fraction if the trace hits the patch</summary>
    procedure TraceThrough(var AWork: TQ3TraceWork);
    /// <summary>CM_PositionTestInPatchCollide</summary>
    function PositionTest(const AWork: TQ3TraceWork): Boolean;
  end;

  /// <summary>CM_GeneratePatchCollide: the collision geometry of a grid of control points</summary>
  IQ3PatchCollideBuilder = interface
    ['{9D2C5F08-1A73-4E64-B8D0-7C41A6E93F25}']
    function Generate(const AWidth, AHeight: Integer; const APoints: TArray<TQ3Vec3>): IQ3PatchCollide;
  end;

  /// <summary>
  ///   The collision model of one Quake III map (the public functions of cm_public.h with the
  ///   state of clipMap_t in the object instead of globals). A model handle is the index of an
  ///   inline model (0 = the world, 1 and over = the brush models of the map), or
  ///   Q3_BOX_MODEL_HANDLE for the box of TempBoxModel. Errors that the original reports with
  ///   ERR_DROP raise EQ3CollisionException.
  /// </summary>
  IQ3CollisionModel = interface
    ['{E1B94A37-5D82-4C16-93A0-2F7D8B6C0E54}']
    function GetNumClusters: Integer;
    function GetNumInlineModels: Integer;
    function GetNumAreas: Integer;
    function GetEntityString: AnsiString;
    function GetNoAreas: Boolean;
    procedure SetNoAreas(const AValue: Boolean);
    function GetNoCurves: Boolean;
    procedure SetNoCurves(const AValue: Boolean);
    function GetTraceCount: Integer;
    function GetBrushTraceCount: Integer;
    function GetPatchTraceCount: Integer;
    function GetPointContentsCount: Integer;

    /// <summary>CM_InlineModel</summary>
    function InlineModel(const AIndex: Integer): Integer;
    /// <summary>CM_TempBoxModel: the handle of the box (Q3_BOX_MODEL_HANDLE, or the capsule handle)</summary>
    function TempBoxModel(const AMins, AMaxs: TQ3Vec3; const ACapsule: Boolean): Integer;
    /// <summary>CM_ModelBounds</summary>
    procedure ModelBounds(const AModel: Integer; out AMins, AMaxs: TQ3Vec3);

    /// <summary>CM_PointLeafnum: 0 if the map is not loaded</summary>
    function PointLeafnum(const APoint: TQ3Vec3): Integer;
    /// <summary>CM_PointContents: an ORed contents mask (AModel 0 = the world tree)</summary>
    function PointContents(const APoint: TQ3Vec3; const AModel: Integer): Integer;
    /// <summary>CM_TransformedPointContents</summary>
    function TransformedPointContents(const APoint: TQ3Vec3; const AModel: Integer;
      const AOrigin, AAngles: TQ3Vec3): Integer;
    /// <summary>
    ///   CM_BoxLeafnums: the leaves a box touches, at most AMaxCount of them (the list is as long
    ///   as the count); ALastLeaf is the last leaf that is not solid, also after an overflow
    /// </summary>
    function BoxLeafnums(const AMins, AMaxs: TQ3Vec3; const AMaxCount: Integer; out ALeafs: TArray<Integer>;
      out ALastLeaf: Integer): Integer;
    /// <summary>CM_BoxBrushes: the numbers of the brushes whose bounds touch the box</summary>
    function BoxBrushes(const AMins, AMaxs: TQ3Vec3; const AMaxCount: Integer): TArray<Integer>;

    /// <summary>CM_BoxTrace</summary>
    function BoxTrace(const AStart, AEnd, AMins, AMaxs: TQ3Vec3; const AModel, ABrushMask: Integer;
      const ACapsule: Boolean): TQ3Trace;
    /// <summary>CM_TransformedBoxTrace</summary>
    function TransformedBoxTrace(const AStart, AEnd, AMins, AMaxs: TQ3Vec3; const AModel, ABrushMask: Integer;
      const AOrigin, AAngles: TQ3Vec3; const ACapsule: Boolean): TQ3Trace;

    /// <summary>CM_LeafCluster</summary>
    function LeafCluster(const ALeaf: Integer): Integer;
    /// <summary>CM_LeafArea</summary>
    function LeafArea(const ALeaf: Integer): Integer;
    /// <summary>CM_ClusterPVS: the row of a cluster (all the first row for a cluster that is not valid or a map without visibility)</summary>
    function ClusterPVS(const ACluster: Integer): TBytes;

    /// <summary>CM_AdjustAreaPortalState</summary>
    procedure AdjustAreaPortalState(const AArea1, AArea2: Integer; const AOpen: Boolean);
    /// <summary>CM_AreasConnected</summary>
    function AreasConnected(const AArea1, AArea2: Integer): Boolean;
    /// <summary>
    ///   CM_WriteAreaBits: ORs the areas of the flood of AArea into ABuffer (at least
    ///   (NumAreas + 7) div 8 bytes long) and returns that number of bytes
    /// </summary>
    function WriteAreaBits(var ABuffer: TBytes; const AArea: Integer): Integer;

    property NumClusters: Integer read GetNumClusters;
    property NumInlineModels: Integer read GetNumInlineModels;
    property NumAreas: Integer read GetNumAreas;
    property EntityString: AnsiString read GetEntityString;
    /// <summary>The cvar cm_noAreas: every area is connected</summary>
    property NoAreas: Boolean read GetNoAreas write SetNoAreas;
    /// <summary>The cvar cm_noCurves: the patches are not tested</summary>
    property NoCurves: Boolean read GetNoCurves write SetNoCurves;
    /// <summary>c_traces, c_brush_traces, c_patch_traces, c_pointcontents</summary>
    property TraceCount: Integer read GetTraceCount;
    property BrushTraceCount: Integer read GetBrushTraceCount;
    property PatchTraceCount: Integer read GetPatchTraceCount;
    property PointContentsCount: Integer read GetPointContentsCount;
  end;

implementation

end.
