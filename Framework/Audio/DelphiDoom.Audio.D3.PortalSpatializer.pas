{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - 3D sound of Doom 3, portal spatialization       }
{                                                                              }
{  Port of idSoundEmitterLocal::Spatialize (snd_emitter.cpp) and               }
{  idSoundWorldLocal::ResolveOrigin (snd_world.cpp).                           }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Framework\IdLib\README.md); the repository }
{  as a whole is GPL v2 or later. Copyright (C) 1999-2011 id Software LLC.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.D3.PortalSpatializer;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Audio.D3.Types, DelphiDoom.Audio.D3.Intf;

type
  /// <summary>
  ///   Works out where a sound seems to come from and how far it is. If the emitter is in the listener's area
  ///   it is its own position; otherwise the sound is followed through the portals of the world (at most ten,
  ///   never back into an area already on the way) and the virtual origin is the point of the portal nearest to
  ///   the listener: the distance is the path through the open portals, and a portal that blocks view or air
  ///   adds <c>s_doorDistanceAdd</c>. With no way through the distance stays the largest range of the emitter
  ///   (the sound is not heard). The listener is set with <c>SetListener</c> (<c>PlaceListener</c>); the
  ///   world is optional (nil: no portals, the straight distance). Not thread safe
  /// </summary>
  TD3PortalSpatializer = class
  strict private
    FWorld: ID3PortalWorld;
    FCvars: TD3SoundCvars;
    FListenerQU: TIdVec3;
    FListenerMeters: TIdVec3;
    FListenerArea: Integer;
    FChain: TArray<Integer>;
    procedure ResolveOrigin(ADepth, AArea: Integer; ADistance: Single; const AOrigin: TIdVec3;
      var AEmitter: TD3EmitterSpace);
    function PortalSource(const APortal: TD3ExitPortal; const AOrigin: TIdVec3): TIdVec3;
  public
    constructor Create(const AWorld: ID3PortalWorld; const ACvars: TD3SoundCvars);
    /// <summary>The listener: its origin in Doom units (<c>listenerQU</c>) and its area (<c>listenerArea</c>); the origin in meters is derived</summary>
    procedure SetListener(const AOriginQU: TIdVec3; AArea: Integer);
    /// <summary>idSoundEmitterLocal::Spatialize: fills RealDistance, Distance and SpatializedOrigin of the emitter</summary>
    procedure Spatialize(var AEmitter: TD3EmitterSpace);
    property ListenerQU: TIdVec3 read FListenerQU;
    property ListenerMeters: TIdVec3 read FListenerMeters;
    property ListenerArea: Integer read FListenerArea;
  end;

implementation

{ TD3PortalSpatializer }

constructor TD3PortalSpatializer.Create(const AWorld: ID3PortalWorld; const ACvars: TD3SoundCvars);
begin
  inherited Create;
  FWorld := AWorld;
  FCvars := ACvars;
  FListenerArea := -1;
end;

procedure TD3PortalSpatializer.SetListener(const AOriginQU: TIdVec3; AArea: Integer);
begin
  FListenerQU := AOriginQU;
  FListenerMeters := AOriginQU * D3_DOOM_TO_METERS;
  FListenerArea := AArea;
end;

procedure TD3PortalSpatializer.Spatialize(var AEmitter: TD3EmitterSpace);
var
  LRealOrigin: TIdVec3;
  LLength: TIdVec3;
  LInArea: Integer;
begin
  // where the sound comes from
  LRealOrigin := AEmitter.Origin * D3_DOOM_TO_METERS;
  LLength := FListenerMeters - LRealOrigin;
  AEmitter.RealDistance := LLength.LengthFast;
  if AEmitter.RealDistance >= AEmitter.MaxDistance then
  begin
    // no way to possibly hear it
    AEmitter.Distance := AEmitter.RealDistance;
    Exit;
  end;
  // the virtual origin and distance, which may be from a portal instead of the actual origin
  AEmitter.Distance := AEmitter.MaxDistance * D3_METERS_TO_DOOM;
  if FListenerArea = -1 then
    // the listener is outside the world
    Exit;
  if Assigned(FWorld) then
  begin
    LInArea := FWorld.PointInArea(AEmitter.Origin);
    if LInArea = -1 then
    begin
      if AEmitter.LastValidPortalArea = -1 then
      begin
        // the sound is outside the world
        AEmitter.Distance := AEmitter.RealDistance;
        AEmitter.SpatializedOrigin := AEmitter.Origin;
        Exit;
      end;
      LInArea := AEmitter.LastValidPortalArea;
    end;
    AEmitter.LastValidPortalArea := LInArea;
    if LInArea = FListenerArea then
    begin
      AEmitter.Distance := AEmitter.RealDistance;
      AEmitter.SpatializedOrigin := AEmitter.Origin;
      Exit;
    end;
    SetLength(FChain, 0);
    ResolveOrigin(0, LInArea, 0, AEmitter.Origin, AEmitter);
    AEmitter.Distance := AEmitter.Distance / D3_METERS_TO_DOOM;
  end
  else
  begin
    // no portals available
    AEmitter.Distance := AEmitter.RealDistance;
    AEmitter.SpatializedOrigin := AEmitter.Origin;
  end;
end;

function TD3PortalSpatializer.PortalSource(const APortal: TD3ExitPortal; const AOrigin: TIdVec3): TIdVec3;
var
  LCount: Integer;
  LIndex: Integer;
  LNext: Integer;
  LCenter: TIdVec3;
  LV1, LV2, LNormal: TIdVec3;
  LLength: Single;
  LInverse: Single;
  LPlaneDistance: Single;
  LDirection: TIdVec3;
  LScale: Single;
  LD1, LD2: Single;
  LEdgeDirection: TIdVec3;
  LEdgeNormal: TIdVec3;
  LFromVertex: TIdVec3;
  LD: Single;
  LDivisor: Single;
  LHasPlane: Boolean;
begin
  LCount := Length(APortal.Points);
  LCenter.Zero;
  for LIndex := 0 to LCount - 1 do
    LCenter := LCenter + APortal.Points[LIndex];
  if LCount > 0 then
    LCenter := LCenter * (1.0 / LCount);

  // idWinding::GetPlane (idPlane): the normal from the first two points and the centre, normalized,
  // fixed if it is nearly axial, through the first point
  LHasPlane := LCount >= 3;
  LNormal.Zero;
  LPlaneDistance := 0;
  if LHasPlane then
  begin
    LV1 := APortal.Points[0] - LCenter;
    LV2 := APortal.Points[1] - LCenter;
    LNormal := LV2.Cross(LV1);
    LLength := LNormal.Length;
    if LLength <> 0 then
    begin
      LInverse := 1.0 / LLength;
      LNormal := LNormal * LInverse;
    end;
    LNormal.FixDegenerateNormal;
    LPlaneDistance := -(LNormal * APortal.Points[0]);
  end;

  // idPlane::RayIntersection from the sound towards the listener
  LDirection := FListenerQU - AOrigin;
  LD1 := LNormal * AOrigin + LPlaneDistance;
  LD2 := LNormal * LDirection;
  if (not LHasPlane) or (LD2 = 0) then
  begin
    Result := LCenter;
    Exit;
  end;
  LScale := -(LD1 / LD2);
  Result := AOrigin + LDirection * LScale;
  // if the point is not inside the edges of the portal, slide it in
  for LIndex := 0 to LCount - 1 do
  begin
    LNext := (LIndex + 1) mod LCount;
    LEdgeDirection := APortal.Points[LNext] - APortal.Points[LIndex];
    LEdgeNormal.Cross(LNormal, LEdgeDirection);
    LFromVertex := Result - APortal.Points[LNext];
    LD := LEdgeNormal * LFromVertex;
    if LD > 0 then
    begin
      LDivisor := LEdgeNormal.Normalize;
      LD := LD / LDivisor;
      Result := Result - LEdgeNormal * LD;
    end;
  end;
end;

procedure TD3PortalSpatializer.ResolveOrigin(ADepth, AArea: Integer; ADistance: Single; const AOrigin: TIdVec3;
  var AEmitter: TD3EmitterSpace);
var
  LFullDistance: Single;
  LCount: Integer;
  LIndex: Integer;
  LPortal: TD3ExitPortal;
  LOcclusion: Single;
  LOther: Integer;
  LVisited: Boolean;
  LChainIndex: Integer;
  LSource: TIdVec3;
  LStep: TIdVec3;
  LStepLength: Single;
  LDiff: TIdVec3;
begin
  if ADistance >= AEmitter.Distance then
    // we cannot possibly hear the sound through this chain of portals
    Exit;
  if AArea = FListenerArea then
  begin
    LDiff := AOrigin - FListenerQU;
    LFullDistance := ADistance + LDiff.LengthFast;
    if LFullDistance < AEmitter.Distance then
    begin
      AEmitter.Distance := LFullDistance;
      AEmitter.SpatializedOrigin := AOrigin;
    end;
    Exit;
  end;
  if ADepth = D3_MAX_PORTAL_TRACE_DEPTH then
    // do not spend too much time on big maps
    Exit;
  SetLength(FChain, ADepth + 1);
  FChain[ADepth] := AArea;
  LCount := FWorld.NumPortalsInArea(AArea);
  for LIndex := 0 to LCount - 1 do
  begin
    LPortal := FWorld.GetPortal(AArea, LIndex);
    LOcclusion := 0;
    // air blocking windows block sound like closed doors: the volume is reduced rather than cut
    if (LPortal.BlockingBits and (D3_PS_BLOCK_VIEW or D3_PS_BLOCK_AIR)) <> 0 then
      LOcclusion := FCvars.DoorDistanceAdd;
    // what area are we about to look at
    LOther := LPortal.Areas[0];
    if LPortal.Areas[0] = AArea then
      LOther := LPortal.Areas[1];
    // if this area is already in the chain, do not look into it
    LVisited := False;
    for LChainIndex := 0 to ADepth - 1 do
      if FChain[LChainIndex] = LOther then
      begin
        LVisited := True;
        Break;
      end;
    if LVisited then
      Continue;
    // the point of the portal that serves as the virtual origin
    LSource := PortalSource(LPortal, AOrigin);
    LStep := LSource - AOrigin;
    LStepLength := LStep.LengthFast;
    ResolveOrigin(ADepth + 1, LOther, ADistance + LStepLength + LOcclusion, LSource, AEmitter);
    // the recursion has used the entries above this depth
    SetLength(FChain, ADepth + 1);
  end;
end;

end.
