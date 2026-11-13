{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - types of the "particle" declaration       }
{                                                                              }
{  Port of the particle systems of Doom 3 (id Software, GPL v3):               }
{  framework\DeclParticle.h, DeclParticle.cpp. Copyright (C) 1999-2011 id      }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Particle.Types;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4,
  DelphiDoom.IdLib.Math.Random, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Table;

type
  /// <summary>A problem found while generating particles (a bad custom path type)</summary>
  EDeclParticleException = class(EDeclException);

  /// <summary>prtDistribution_t: the shape the particles are born in</summary>
  TParticleDistribution = (
    /// <summary>( sizeX sizeY sizeZ )</summary>
    Rect,
    /// <summary>( sizeX sizeY sizeZ ringFraction )</summary>
    Cylinder,
    /// <summary>( sizeX sizeY sizeZ ringFraction ): a ring fraction of zero allows the entire sphere</summary>
    Sphere);

  /// <summary>prtDirection_t</summary>
  TParticleDirection = (
    /// <summary>parm0 is the solid cone angle</summary>
    Cone,
    /// <summary>the direction is relative to the offset from the origin, parm0 is an upward bias</summary>
    Outward);

  /// <summary>prtCustomPth_t: the C routines that replace the standard path</summary>
  TParticleCustomPath = (Standard, Helix, Flies, Orbit, Drip);

  /// <summary>prtOrientation_t</summary>
  TParticleOrientation = (
    View,
    /// <summary>angle and aspect are disregarded</summary>
    Aimed,
    X,
    Y,
    Z);

  /// <summary>
  ///   idParticleParm: a value that is either a table read at the age of the particle or a straight line from
  ///   <c>FromValue</c> to <c>ToValue</c>.
  /// </summary>
  TParticleParm = record
    Table: IDeclTable;
    FromValue: Single;
    ToValue: Single;
    /// <summary>The cleared parm of the idParticleParm constructor</summary>
    class function Create: TParticleParm; static;
    /// <summary>idParticleParm::Eval at a fraction 0..1 of the life (the random generator of the original is not used)</summary>
    function Eval(const AFraction: Single): Single;
    /// <summary>
    ///   idParticleParm::Integrate. A table cannot be integrated: the message of the original goes to
    ///   <c>ALog</c> (if any) and the result is 0.
    /// </summary>
    function Integrate(const AFraction: Single; const ALog: IIdLibLog): Single;
  end;

  /// <summary>
  ///   The renderEntity_t fields a particle reads: the axis of the entity and its shader parms (for
  ///   <c>entityColor</c>).
  /// </summary>
  TParticleEntity = record
    Axis: TIdMat3;
    ShaderParms: array[0..11] of Single;
    /// <summary>The entity of <c>GetStageBounds</c>: identity axis, zero parms</summary>
    class function Identity: TParticleEntity; static;
  end;

  /// <summary>The renderView_t field a particle reads: the view axis</summary>
  TParticleView = record
    ViewAxis: TIdMat3;
    class function Identity: TParticleView; static;
  end;

  /// <summary>
  ///   particleGen_t: the state of one particle being generated. <c>Random</c> is consumed while the particle
  ///   is built; <c>OriginalRandom</c> is what it was at the start (aimed particles need it again).
  /// </summary>
  TParticleGen = record
    Entity: TParticleEntity;
    View: TParticleView;
    /// <summary>The particle number in the system</summary>
    Index: Integer;
    /// <summary>0.0 to 1.0</summary>
    Frac: Single;
    Random: TIdRandom;
    /// <summary>Dynamic smoke particles can have individual origins and axis</summary>
    Origin: TIdVec3;
    Axis: TIdMat3;
    /// <summary>In seconds, calculated as fraction * particleLife</summary>
    Age: Single;
    OriginalRandom: TIdRandom;
    /// <summary>Set by <c>ParticleTexCoords</c>, used to make the cross faded version</summary>
    AnimationFrameFrac: Single;
    /// <summary>Identity axes, the origin at zero, nothing else set</summary>
    class function Create(const ARandom: TIdRandom): TParticleGen; static;
  end;

  /// <summary>The part of idDrawVert a particle fills: position, texture coordinates and colour</summary>
  TParticleVertex = record
    Xyz: TIdVec3;
    St: array[0..1] of Single;
    Color: array[0..3] of Byte;
    /// <summary>idDrawVert::Clear</summary>
    procedure Clear;
  end;

  /// <summary>
  ///   idParticleStage: one stage of a particle system, as data. The generation (<c>CreateParticle</c> and the
  ///   others) is in <c>TParticleGenerator</c>.
  /// </summary>
  TParticleStage = record
    /// <summary>The material (a declaration of type DECL_MATERIAL), nil before it is set</summary>
    Material: IDecl;
    /// <summary>Total number of particles, although some may be invisible at a given time</summary>
    TotalParticles: Integer;
    /// <summary>Allows things to oneShot ( 1 cycle ) or run for a set number of cycles on a per stage basis</summary>
    Cycles: Single;
    /// <summary>( particleLife + deadTime ) in msec</summary>
    CycleMsec: Integer;
    /// <summary>0.0 = all come out at first instant, 1.0 = evenly spaced over cycle time</summary>
    SpawnBunching: Single;
    /// <summary>Total seconds of life for each particle</summary>
    ParticleLife: Single;
    /// <summary>Time offset from system start for the first particle to spawn</summary>
    TimeOffset: Single;
    /// <summary>Time after particleLife before respawning</summary>
    DeadTime: Single;
    DistributionType: TParticleDistribution;
    DistributionParms: array[0..3] of Single;
    DirectionType: TParticleDirection;
    DirectionParms: array[0..3] of Single;
    Speed: TParticleParm;
    /// <summary>Can be negative to float up</summary>
    Gravity: Single;
    /// <summary>Apply gravity in world space</summary>
    WorldGravity: Boolean;
    /// <summary>Randomly orient the quad on emission (defaults to true)</summary>
    RandomDistribution: Boolean;
    /// <summary>Force color from render entity (fadeColor is still valid)</summary>
    EntityColor: Boolean;
    /// <summary>Custom path will completely replace the standard path calculations</summary>
    CustomPathType: TParticleCustomPath;
    CustomPathParms: array[0..7] of Single;
    /// <summary>Offset from origin to spawn all particles, also applies to customPath</summary>
    Offset: TIdVec3;
    /// <summary>If &gt; 1, subdivide the texture S axis into frames and crossfade</summary>
    AnimationFrames: Integer;
    /// <summary>Frames per second</summary>
    AnimationRate: Single;
    /// <summary>In degrees, random angle is used if zero (default)</summary>
    InitialAngle: Single;
    /// <summary>Half the particles will have negative rotation speeds</summary>
    RotationSpeed: TParticleParm;
    Orientation: TParticleOrientation;
    OrientationParms: array[0..3] of Single;
    Size: TParticleParm;
    /// <summary>Greater than 1 makes the T axis longer</summary>
    Aspect: TParticleParm;
    Color: TIdVec4;
    /// <summary>Either 0 0 0 0 for additive, or 1 1 1 0 for blended materials</summary>
    FadeColor: TIdVec4;
    /// <summary>In 0.0 to 1.0 range</summary>
    FadeInFraction: Single;
    FadeOutFraction: Single;
    /// <summary>In 0.0 to 1.0 range, causes later index smokes to be more faded</summary>
    FadeIndexFraction: Single;
    /// <summary>For editor use</summary>
    Hidden: Boolean;
    /// <summary>User tweak to fix poorly calculated bounds</summary>
    BoundsExpansion: Single;
    /// <summary>Derived (<c>TParticleStageBounds</c>)</summary>
    Bounds: TGeoBounds;
    /// <summary>The stage of the idParticleStage constructor (everything zero but the random distribution)</summary>
    class function Create: TParticleStage; static;
    /// <summary>
    ///   idParticleStage::Default: the stage a new <c>{ }</c> starts from. <c>AMaterial</c> is the
    ///   <c>_default</c> material (<c>declManager-&gt;FindMaterial</c>).
    /// </summary>
    procedure SetDefault(const AMaterial: IDecl);
    /// <summary>idParticleStage::GetCustomPathName ("standard" for an unknown type)</summary>
    function GetCustomPathName: AnsiString;
    /// <summary>idParticleStage::GetCustomPathDesc</summary>
    function GetCustomPathDesc: AnsiString;
    /// <summary>idParticleStage::NumCustomPathParms</summary>
    function NumCustomPathParms: Integer;
    /// <summary>idParticleStage::SetCustomPathType: standard for a name that is not known</summary>
    procedure SetCustomPathType(const AName: AnsiString);
  end;

const
  /// <summary>The names of the distribution types (ParticleDistributionDesc) and how many parms they write</summary>
  PARTICLE_DISTRIBUTION_NAMES: array[TParticleDistribution] of AnsiString = ('rect', 'cylinder', 'sphere');
  PARTICLE_DISTRIBUTION_PARMS: array[TParticleDistribution] of Integer = (3, 4, 3);
  /// <summary>ParticleDirectionDesc</summary>
  PARTICLE_DIRECTION_NAMES: array[TParticleDirection] of AnsiString = ('cone', 'outward');
  PARTICLE_DIRECTION_PARMS: array[TParticleDirection] of Integer = (1, 1);
  /// <summary>ParticleOrientationDesc</summary>
  PARTICLE_ORIENTATION_NAMES: array[TParticleOrientation] of AnsiString = ('view', 'aimed', 'x', 'y', 'z');
  PARTICLE_ORIENTATION_PARMS: array[TParticleOrientation] of Integer = (0, 2, 0, 0, 0);
  /// <summary>ParticleCustomDesc: the name, the number of parms and what they are</summary>
  PARTICLE_CUSTOM_NAMES: array[TParticleCustomPath] of AnsiString = ('standard', 'helix', 'flies', 'orbit', 'drip');
  PARTICLE_CUSTOM_PARMS: array[TParticleCustomPath] of Integer = (0, 5, 3, 2, 2);
  PARTICLE_CUSTOM_DESCS: array[TParticleCustomPath] of AnsiString = ('Standard',
    'sizeX Y Z radialSpeed axialSpeed', 'radialSpeed axialSpeed size', 'radius speed', 'something something');

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

{ TParticleParm }

class function TParticleParm.Create: TParticleParm;
begin
  Result.Table := nil;
  Result.FromValue := 0.0;
  Result.ToValue := 0.0;
end;

function TParticleParm.Eval(const AFraction: Single): Single;
var
  LDelta: Single;
  LStep: Single;
begin
  if Assigned(Table) then
    Exit(Table.TableLookup(AFraction));
  LDelta := ToValue - FromValue;
  LStep := AFraction * LDelta;
  Result := FromValue + LStep;
end;

function TParticleParm.Integrate(const AFraction: Single; const ALog: IIdLibLog): Single;
var
  LHalf: Single;
  LInner: Single;
begin
  if Assigned(Table) then
  begin
    if Assigned(ALog) then
      ALog.Printf('idParticleParm::Integrate: can''t integrate tables'#10);
    Exit(0.0);
  end;
  LHalf := AFraction * (ToValue - FromValue) * 0.5;
  LInner := FromValue + LHalf;
  Result := LInner * AFraction;
end;

{ TParticleEntity }

class function TParticleEntity.Identity: TParticleEntity;
var
  LIndex: Integer;
begin
  Result.Axis := TIdMat3.Identity;
  for LIndex := 0 to High(Result.ShaderParms) do
    Result.ShaderParms[LIndex] := 0.0;
end;

{ TParticleView }

class function TParticleView.Identity: TParticleView;
begin
  Result.ViewAxis := TIdMat3.Identity;
end;

{ TParticleGen }

class function TParticleGen.Create(const ARandom: TIdRandom): TParticleGen;
begin
  Result.Entity := TParticleEntity.Identity;
  Result.View := TParticleView.Identity;
  Result.Index := 0;
  Result.Frac := 0.0;
  Result.Random := ARandom;
  Result.Origin.Zero;
  Result.Axis := TIdMat3.Identity;
  Result.Age := 0.0;
  Result.OriginalRandom := ARandom;
  Result.AnimationFrameFrac := 0.0;
end;

{ TParticleVertex }

procedure TParticleVertex.Clear;
begin
  Xyz.Zero;
  St[0] := 0.0;
  St[1] := 0.0;
  Color[0] := 0;
  Color[1] := 0;
  Color[2] := 0;
  Color[3] := 0;
end;

{ TParticleStage }

class function TParticleStage.Create: TParticleStage;
var
  LIndex: Integer;
begin
  Result.Material := nil;
  Result.TotalParticles := 0;
  Result.Cycles := 0.0;
  Result.CycleMsec := 0;
  Result.SpawnBunching := 0.0;
  Result.ParticleLife := 0.0;
  Result.TimeOffset := 0.0;
  Result.DeadTime := 0.0;
  Result.DistributionType := TParticleDistribution.Rect;
  Result.DirectionType := TParticleDirection.Cone;
  Result.Speed := TParticleParm.Create;
  Result.Gravity := 0.0;
  Result.WorldGravity := False;
  Result.CustomPathType := TParticleCustomPath.Standard;
  Result.Offset.Zero;
  Result.AnimationFrames := 0;
  Result.AnimationRate := 0.0;
  Result.RandomDistribution := True;
  Result.EntityColor := False;
  Result.InitialAngle := 0.0;
  Result.RotationSpeed := TParticleParm.Create;
  Result.Orientation := TParticleOrientation.View;
  Result.Size := TParticleParm.Create;
  Result.Aspect := TParticleParm.Create;
  Result.Color.Zero;
  Result.FadeColor.Zero;
  Result.FadeInFraction := 0.0;
  Result.FadeOutFraction := 0.0;
  Result.FadeIndexFraction := 0.0;
  Result.Hidden := False;
  Result.BoundsExpansion := 0.0;
  Result.Bounds.Clear;
  for LIndex := 0 to 3 do
  begin
    Result.DistributionParms[LIndex] := 0.0;
    Result.DirectionParms[LIndex] := 0.0;
    Result.OrientationParms[LIndex] := 0.0;
  end;
  for LIndex := 0 to 7 do
    Result.CustomPathParms[LIndex] := 0.0;
end;

procedure TParticleStage.SetDefault(const AMaterial: IDecl);
var
  LIndex: Integer;
  LCycle: Single;
begin
  Material := AMaterial;
  TotalParticles := 100;
  SpawnBunching := 1.0;
  ParticleLife := 1.5;
  TimeOffset := 0.0;
  DeadTime := 0.0;
  DistributionType := TParticleDistribution.Rect;
  DistributionParms[0] := 8.0;
  DistributionParms[1] := 8.0;
  DistributionParms[2] := 8.0;
  DistributionParms[3] := 0.0;
  DirectionType := TParticleDirection.Cone;
  DirectionParms[0] := 90.0;
  DirectionParms[1] := 0.0;
  DirectionParms[2] := 0.0;
  DirectionParms[3] := 0.0;
  Orientation := TParticleOrientation.View;
  for LIndex := 0 to 3 do
    OrientationParms[LIndex] := 0.0;
  Speed.FromValue := 150.0;
  Speed.ToValue := 150.0;
  Speed.Table := nil;
  Gravity := 1.0;
  WorldGravity := False;
  CustomPathType := TParticleCustomPath.Standard;
  for LIndex := 0 to 7 do
    CustomPathParms[LIndex] := 0.0;
  Offset.Zero;
  AnimationFrames := 0;
  AnimationRate := 0.0;
  InitialAngle := 0.0;
  RotationSpeed.FromValue := 0.0;
  RotationSpeed.ToValue := 0.0;
  RotationSpeed.Table := nil;
  Size.FromValue := 4.0;
  Size.ToValue := 4.0;
  Size.Table := nil;
  Aspect.FromValue := 1.0;
  Aspect.ToValue := 1.0;
  Aspect.Table := nil;
  Color.SetValues(1.0, 1.0, 1.0, 1.0);
  FadeColor.SetValues(0.0, 0.0, 0.0, 0.0);
  FadeInFraction := 0.1;
  FadeOutFraction := 0.25;
  FadeIndexFraction := 0.0;
  BoundsExpansion := 0.0;
  RandomDistribution := True;
  EntityColor := False;
  LCycle := (ParticleLife + DeadTime) * 1000;
  CycleMsec := Trunc(LCycle);
end;

function TParticleStage.GetCustomPathName: AnsiString;
begin
  Result := PARTICLE_CUSTOM_NAMES[CustomPathType];
end;

function TParticleStage.GetCustomPathDesc: AnsiString;
begin
  Result := PARTICLE_CUSTOM_DESCS[CustomPathType];
end;

function TParticleStage.NumCustomPathParms: Integer;
begin
  Result := PARTICLE_CUSTOM_PARMS[CustomPathType];
end;

procedure TParticleStage.SetCustomPathType(const AName: AnsiString);
var
  LPath: TParticleCustomPath;
begin
  CustomPathType := TParticleCustomPath.Standard;
  for LPath := Low(TParticleCustomPath) to High(TParticleCustomPath) do
    if TIdStrings.Icmp(AName, PARTICLE_CUSTOM_NAMES[LPath]) = 0 then
    begin
      CustomPathType := LPath;
      Break;
    end;
end;

end.
