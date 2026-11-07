{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the types of the application of a map            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Apply.Types;

interface

type
  /// <summary>A plane of a slope as the renderer wants it: a, b, 1/c and d of ax + by + cz + d = 0</summary>
  TUdmfPlane = record
    A: Single;
    B: Single;
    InverseC: Single;
    D: Single;
  end;

  /// <summary>What a sector asks of the renderer and of the game besides its planes</summary>
  TUdmfSectorEffect = (
    /// <summary>The ceiling ripples</summary>
    seRippleCeiling,
    /// <summary>The floor ripples</summary>
    seRippleFloor,
    seFog,
    seHidden,
    /// <summary>The players cannot jump in the sector</summary>
    seNoJump,
    /// <summary>The players cannot crouch in the sector</summary>
    seNoCrouch);

  TUdmfSectorEffects = set of TUdmfSectorEffect;

  /// <summary>The planes that the text map gave to a sector (the flags tell which values were written)</summary>
  TUdmfSectorPlanes = record
    /// <summary>The flags UDMF_SF_* of the sector</summary>
    Flags: Integer;
    CeilingA: Single;
    CeilingB: Single;
    CeilingC: Single;
    CeilingD: Single;
    FloorA: Single;
    FloorB: Single;
    FloorC: Single;
    FloorD: Single;
  end;

  /// <summary>A corner of a triangular sector; coordinates and heights in fixed point</summary>
  TUdmfTriangleCorner = record
    X: Integer;
    Y: Integer;
    /// <summary>Absolute floor height, meaningful only with UDMF_VF_ZFLOOR in Flags</summary>
    ZFloor: Integer;
    /// <summary>Absolute ceiling height, meaningful only with UDMF_VF_ZCEILING in Flags</summary>
    ZCeiling: Integer;
    /// <summary>The flags UDMF_VF_* of the vertex</summary>
    Flags: Integer;
  end;

  TUdmfTriangle = array[0..2] of TUdmfTriangleCorner;

  /// <summary>The slopes that the corners of a triangular sector give it</summary>
  TUdmfSurfaceSlopes = record
    HasFloor: Boolean;
    HasCeiling: Boolean;
    Floor: TUdmfPlane;
    Ceiling: TUdmfPlane;
  end;

implementation

end.
