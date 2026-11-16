{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - contracts of the BSP of the bots                   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Bsp.Intf;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Move.Types;

type
  /// <summary>
  ///   What be_aas_bspq3.c asks of the game besides PointContents and Trace (IAasBspWorld): the entity string,
  ///   the entity traces, the PVS and the bounds of a model (botimport.BSPEntityData, EntityTrace, inPVS,
  ///   BSPModelMinsMaxsOrigin)
  /// </summary>
  IAasBspModels = interface
    ['{6C4F1B33-2D70-4A96-B1E5-8F03A7D26C16}']
    /// <summary>The entities of the map as text</summary>
    function EntityData: AnsiString;
    /// <summary>A box against the entity only (EntityTrace); fraction 1 if it does not collide</summary>
    function EntityTrace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const AEntNum,
      AContentMask: Integer): TAasBspTrace;
    /// <summary>True if the two points are in the potentially visible set</summary>
    function InPVS(const AFirst, ASecond: TVec3): Boolean;
    /// <summary>The bounds of an inline model (bigger when it is rotated) and its origin (zero)</summary>
    procedure ModelMinsMaxsOrigin(const AModelNum: Integer; const AAngles: TVec3; out AMins, AMaxs, AOrigin: TVec3);
  end;

  /// <summary>The key/value pairs of the entities of the map (bspworld of be_aas_bspq3.c)</summary>
  IAasBspEntities = interface
    ['{6C4F1B33-2D70-4A96-B1E5-8F03A7D26C17}']
    /// <summary>The number of entities plus one: the entity zero does not exist</summary>
    function GetCount: Integer;
    property Count: Integer read GetCount;
    /// <summary>AAS_NextBSPEntity: the next entity, 0 when there are no more</summary>
    function NextEntity(const AEntity: Integer): Integer;
    /// <summary>AAS_BSPEntityInRange: False, with a message, if the entity does not exist</summary>
    function EntityInRange(const AEntity: Integer): Boolean;
    /// <summary>AAS_ValueForBSPEpairKey: the value cut to Size-1 characters; empty if not found</summary>
    function ValueForKey(const AEntity: Integer; const AKey: AnsiString; out AValue: AnsiString;
      const ASize: Integer = 128): Boolean;
    function VectorForKey(const AEntity: Integer; const AKey: AnsiString; out AValue: TVec3): Boolean;
    function FloatForKey(const AEntity: Integer; const AKey: AnsiString; out AValue: Single): Boolean;
    function IntForKey(const AEntity: Integer; const AKey: AnsiString; out AValue: Integer): Boolean;
  end;

implementation

end.
