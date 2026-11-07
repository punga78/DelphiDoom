{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the extra values of a sector                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Apply.SectorInterpreter;

interface

uses
  DelphiDoom.Udmf.Apply.Types, DelphiDoom.Udmf.Apply.Intf;

type
  /// <summary>Planes and effects of a sector from its flags</summary>
  TUdmfSectorInterpreter = class(TInterfacedObject, IUdmfSectorInterpreter)
  public
    function TryGetCeilingPlane(const APlanes: TUdmfSectorPlanes; out APlane: TUdmfPlane): Boolean;
    function TryGetFloorPlane(const APlanes: TUdmfSectorPlanes; out APlane: TUdmfPlane): Boolean;
    function GetEffects(AFlags: Integer): TUdmfSectorEffects;
  end;

implementation

uses
  DelphiDoom.Udmf.Types;

const
  UDMF_SF_CEILINGPLANE = UDMF_SF_CEILINGPLANE_A or UDMF_SF_CEILINGPLANE_B or
    UDMF_SF_CEILINGPLANE_C or UDMF_SF_CEILINGPLANE_D;
  UDMF_SF_FLOORPLANE = UDMF_SF_FLOORPLANE_A or UDMF_SF_FLOORPLANE_B or
    UDMF_SF_FLOORPLANE_C or UDMF_SF_FLOORPLANE_D;

{ TUdmfSectorInterpreter }

function TUdmfSectorInterpreter.TryGetCeilingPlane(const APlanes: TUdmfSectorPlanes;
  out APlane: TUdmfPlane): Boolean;
begin
  FillChar(APlane, SizeOf(APlane), 0);
  Result := (APlanes.Flags and UDMF_SF_CEILINGPLANE = UDMF_SF_CEILINGPLANE) and
    (APlanes.CeilingC <> 0.0);
  if not Result then
    Exit;
  APlane.A := APlanes.CeilingA;
  APlane.B := APlanes.CeilingB;
  APlane.InverseC := 1 / APlanes.CeilingC;
  APlane.D := APlanes.CeilingD;
end;

function TUdmfSectorInterpreter.TryGetFloorPlane(const APlanes: TUdmfSectorPlanes;
  out APlane: TUdmfPlane): Boolean;
begin
  FillChar(APlane, SizeOf(APlane), 0);
  Result := (APlanes.Flags and UDMF_SF_FLOORPLANE = UDMF_SF_FLOORPLANE) and
    (APlanes.FloorC <> 0.0);
  if not Result then
    Exit;
  APlane.A := APlanes.FloorA;
  APlane.B := APlanes.FloorB;
  APlane.InverseC := 1 / APlanes.FloorC;
  APlane.D := APlanes.FloorD;
end;

function TUdmfSectorInterpreter.GetEffects(AFlags: Integer): TUdmfSectorEffects;
begin
  Result := [];
  if AFlags and UDMF_SF_RIPPLECEILING <> 0 then
    Include(Result, seRippleCeiling);
  if AFlags and UDMF_SF_RIPPLEFLOOR <> 0 then
    Include(Result, seRippleFloor);
  if AFlags and UDMF_SF_FOG <> 0 then
    Include(Result, seFog);
  if AFlags and UDMF_SF_HIDDEN <> 0 then
    Include(Result, seHidden);
  if AFlags and UDMF_SF_NOJUMP <> 0 then
    Include(Result, seNoJump);
  if AFlags and UDMF_SF_NOCROUCH <> 0 then
    Include(Result, seNoCrouch);
end;

end.
