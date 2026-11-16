{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the contracts of the application of a map        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Apply.Intf;

interface

uses
  DelphiDoom.Udmf.Apply.Types;

type
  /// <summary>Reads the extra values of a sector and says what the engine has to do with them</summary>
  IUdmfSectorInterpreter = interface
    ['{5B1E2C7A-3D49-4F0B-9A6E-7C41D2A8E0F1}']
    /// <summary>The plane of the ceiling, when the text map gave all four values and c is not 0</summary>
    function TryGetCeilingPlane(const APlanes: TUdmfSectorPlanes; out APlane: TUdmfPlane): Boolean;
    /// <summary>The plane of the floor, when the text map gave all four values and c is not 0</summary>
    function TryGetFloorPlane(const APlanes: TUdmfSectorPlanes; out APlane: TUdmfPlane): Boolean;
    /// <summary>The effects of a sector from its flags UDMF_SF_*</summary>
    function GetEffects(AFlags: Integer): TUdmfSectorEffects;
  end;

  /// <summary>Finds the slopes of a triangular sector from the absolute heights of its vertexes</summary>
  IUdmfTriangleSlopes = interface
    ['{8E3A9D14-62B7-4C5F-B0D8-1F7A3E94C6B2}']
    /// <param name="ACorners">The three vertexes of the sector</param>
    /// <param name="AFloorHeight">The floor height of the sector (fixed point), for the corners without their own</param>
    /// <param name="ACeilingHeight">The ceiling height of the sector (fixed point), for the corners without their own</param>
    function Solve(const ACorners: TUdmfTriangle; AFloorHeight, ACeilingHeight: Integer): TUdmfSurfaceSlopes;
  end;

  /// <summary>Gives the special of a line the number that the engine uses for it</summary>
  IUdmfLineSpecialTranslator = interface
    ['{C4F07B2E-9A18-4D63-8E5B-2A9D6F13B7C0}']
    function Translate(ASpecial: Integer): Integer;
  end;

  /// <summary>The fake contrast of the light of a wall</summary>
  IUdmfFakeContrast = interface
    ['{17D5A8C3-E2B4-4096-A1F7-6B0C9E38D452}']
    /// <returns>-1 for a horizontal wall, 1 for a vertical one, 0 otherwise or when the side asks for none</returns>
    function Calculate(ANoFakeContrast: Boolean; AX1, AY1, AX2, AY2: Integer): Integer;
  end;

  /// <summary>Applies one kind of entity of the converted map to the structures of the engine</summary>
  IUdmfMapPartApplier = interface
    ['{F2A61E9B-45C8-47D0-93B5-D8E70A1C6F34}']
    /// <returns>False when the map has no UDMF data or the counts do not match the ones of the engine</returns>
    function Apply: Boolean;
  end;

implementation

end.
