{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the extra values of the sectors of a text map          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Udmf.SectorApplier;

interface

uses
  r_defs,
  DelphiDoom.Udmf.Apply.Types,
  DelphiDoom.Udmf.Apply.Intf;

type
  /// <summary>Writes the extra values of the sectors (panning, rotation, planes, flags, slopes of
  /// triangular sectors) in sectors[]</summary>
  TEngineUdmfSectorApplier = class(TInterfacedObject, IUdmfMapPartApplier)
  strict private
    FInterpreter: IUdmfSectorInterpreter;
    FTriangleSlopes: IUdmfTriangleSlopes;
    procedure SetCeilingPlane(const ASector: Psector_t; const APlane: TUdmfPlane);
    procedure SetFloorPlane(const ASector: Psector_t; const APlane: TUdmfPlane);
    procedure ApplySector(const ASectorIndex: Integer);
    procedure ApplyTriangleSlopes(const ASectorIndex: Integer);
  public
    constructor Create(const AInterpreter: IUdmfSectorInterpreter; const ATriangleSlopes: IUdmfTriangleSlopes);
    function Apply: Boolean;
  end;

implementation

uses
  SysUtils,
  d_delphi,
  p_common,
  p_setup,
  p_slopes,
  p_udmf,
  DelphiDoom.Udmf.Apply.TriangleFinder;

{ TEngineUdmfSectorApplier }

constructor TEngineUdmfSectorApplier.Create(const AInterpreter: IUdmfSectorInterpreter;
  const ATriangleSlopes: IUdmfTriangleSlopes);
begin
  inherited Create;
  if not Assigned(AInterpreter) then
    raise EArgumentNilException.Create('AInterpreter');
  if not Assigned(ATriangleSlopes) then
    raise EArgumentNilException.Create('ATriangleSlopes');
  FInterpreter := AInterpreter;
  FTriangleSlopes := ATriangleSlopes;
end;

procedure TEngineUdmfSectorApplier.SetCeilingPlane(const ASector: Psector_t; const APlane: TUdmfPlane);
begin
  ASector.ca := APlane.A;
  ASector.cb := APlane.B;
  ASector.cic := APlane.InverseC;
  ASector.cd := APlane.D;
  ASector.renderflags := ASector.renderflags or SRF_SLOPECEILING;
  P_SlopesAlignPlane(ASector, nil, SRF_SLOPECEILING, false);
  ASector.slopeline := ASector.lines[0];
  ASector.slopeline.renderflags := ASector.slopeline.renderflags or LRF_SLOPED;
end;

procedure TEngineUdmfSectorApplier.SetFloorPlane(const ASector: Psector_t; const APlane: TUdmfPlane);
begin
  ASector.fa := APlane.A;
  ASector.fb := APlane.B;
  ASector.fic := APlane.InverseC;
  ASector.fd := APlane.D;
  ASector.renderflags := ASector.renderflags or SRF_SLOPEFLOOR;
  P_SlopesAlignPlane(ASector, nil, SRF_SLOPEFLOOR, false);
  ASector.slopeline := ASector.lines[0];
  ASector.slopeline.renderflags := ASector.slopeline.renderflags or LRF_SLOPED;
end;

procedure TEngineUdmfSectorApplier.ApplySector(const ASectorIndex: Integer);
var
  LSector: Psector_t;
  LExtra: Pextrasector_t;
  LPlanes: TUdmfSectorPlanes;
  LPlane: TUdmfPlane;
  LEffects: TUdmfSectorEffects;
begin
  LSector := @sectors[ASectorIndex];
  LExtra := @udmfsectors[ASectorIndex];

  {$IFDEF DOOM_OR_STRIFE}
  LSector.floor_xoffs := LExtra.xpanningfloor;
  LSector.floor_yoffs := LExtra.ypanningfloor;
  LSector.ceiling_xoffs := LExtra.xpanningceiling;
  LSector.ceiling_yoffs := LExtra.ypanningceiling;
  {$ENDIF}
  LSector.gravity := LExtra.gravity;
  LSector.floorangle := LExtra.rotationfloor;
  LSector.flooranglex := LExtra.rotationfloorx;
  LSector.floorangley := LExtra.rotationfloory;
  LSector.ceilingangle := LExtra.rotationceiling;
  LSector.ceilinganglex := LExtra.rotationceilingx;
  LSector.ceilingangley := LExtra.rotationceilingy;

  LPlanes.Flags := LExtra.extraflags;
  LPlanes.CeilingA := LExtra.ceilingplane_a;
  LPlanes.CeilingB := LExtra.ceilingplane_b;
  LPlanes.CeilingC := LExtra.ceilingplane_c;
  LPlanes.CeilingD := LExtra.ceilingplane_d;
  LPlanes.FloorA := LExtra.floorplane_a;
  LPlanes.FloorB := LExtra.floorplane_b;
  LPlanes.FloorC := LExtra.floorplane_c;
  LPlanes.FloorD := LExtra.floorplane_d;
  if FInterpreter.TryGetCeilingPlane(LPlanes, LPlane) then
    SetCeilingPlane(LSector, LPlane);
  if FInterpreter.TryGetFloorPlane(LPlanes, LPlane) then
    SetFloorPlane(LSector, LPlane);

  LEffects := FInterpreter.GetEffects(LExtra.extraflags);
  if seRippleCeiling in LEffects then
    LSector.renderflags := LSector.renderflags or SRF_RIPPLE_CEILING;
  if seRippleFloor in LEffects then
    LSector.renderflags := LSector.renderflags or SRF_RIPPLE_FLOOR;
  if seFog in LEffects then
    LSector.renderflags := LSector.renderflags or SRF_FOG;
  if seHidden in LEffects then
    LSector.renderflags := LSector.renderflags or SRF_HIDDEN;
  if seNoJump in LEffects then
    LSector.flags := LSector.flags or SF_NOJUMP;
  if seNoCrouch in LEffects then
    LSector.flags := LSector.flags or SF_NOCROUCH;

  LSector.moreids := LExtra.moreids;
  {$IFNDEF HEXEN}
  LSector.seqType := LExtra.sound;
  {$ENDIF}
  LSector.windthrust := LExtra.windthrust;
  LSector.windangle := LExtra.windangle;
end;

procedure TEngineUdmfSectorApplier.ApplyTriangleSlopes(const ASectorIndex: Integer);
var
  LSector: Psector_t;
  LEndpoints: array[0..5] of Integer;
  LVertexes: TArray<Integer>;
  LTriangle: TUdmfTriangle;
  LSlopes: TUdmfSurfaceSlopes;
  LIndex: Integer;
begin
  LSector := @sectors[ASectorIndex];
  if LSector.linecount <> 3 then
    Exit;

  for LIndex := 0 to 2 do
  begin
    LEndpoints[LIndex * 2] := pDiff(LSector.lines[LIndex].v1, vertexes, SizeOf(vertex_t));
    LEndpoints[LIndex * 2 + 1] := pDiff(LSector.lines[LIndex].v2, vertexes, SizeOf(vertex_t));
  end;
  // not closed, or with vertexes added by the node builder: no extra values
  if not TUdmfTriangleFinder.TryFind(LEndpoints, numudmfvertexes, LVertexes) then
    Exit;

  for LIndex := 0 to 2 do
  begin
    LTriangle[LIndex].X := vertexes[LVertexes[LIndex]].x;
    LTriangle[LIndex].Y := vertexes[LVertexes[LIndex]].y;
    LTriangle[LIndex].ZFloor := udmfvertexes[LVertexes[LIndex]].zfloor;
    LTriangle[LIndex].ZCeiling := udmfvertexes[LVertexes[LIndex]].zceiling;
    LTriangle[LIndex].Flags := udmfvertexes[LVertexes[LIndex]].extraflags;
  end;

  LSlopes := FTriangleSlopes.Solve(LTriangle, LSector.floorheight, LSector.ceilingheight);
  if LSlopes.HasFloor then
    SetFloorPlane(LSector, LSlopes.Floor);
  if LSlopes.HasCeiling then
    SetCeilingPlane(LSector, LSlopes.Ceiling);
end;

function TEngineUdmfSectorApplier.Apply: Boolean;
var
  LIndex: Integer;
begin
  Result := hasudmfdata and (numudmfsectors = numsectors);
  if not Result then
    Exit;

  for LIndex := 0 to numudmfsectors - 1 do
  begin
    ApplySector(LIndex);
    ApplyTriangleSlopes(LIndex);
  end;
end;

end.
