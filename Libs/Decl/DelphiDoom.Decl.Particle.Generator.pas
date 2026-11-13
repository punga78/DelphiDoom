{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TParticleGenerator, the particles of a    }
{  stage over time                                                             }
{                                                                              }
{  Port of the particle systems of Doom 3 (id Software, GPL v3):               }
{  framework\DeclParticle.cpp (idParticleStage::ParticleOrigin, ParticleVerts, }
{  ParticleTexCoords, ParticleColors, CreateParticle, NumQuadsPerParticle and  }
{  idDeclParticle::GetStageBounds). Copyright (C) 1999-2011 id Software LLC,   }
{  a ZeniMax Media company.                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Particle.Generator;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Random,
  DelphiDoom.MathCore.Float.Mat3,
  DelphiDoom.Decl.Particle.Types, DelphiDoom.Decl.Particle.Intf;

type
  /// <summary>
  ///   The calculation of idParticleStage as a class without state. The log (if any) receives the message of
  ///   <c>idParticleParm::Integrate</c> for a table. Everything stays in <c>Single</c>, step by step, as the C++ rounds
  ///   to <c>float</c> at each operation; the origin of an <c>orbit</c> path starts at zero where the original reads an
  ///   uninitialised <c>origin[2]</c>.
  /// </summary>
  TParticleGenerator = class(TInterfacedObject, IParticleGenerator)
  strict private
    FLog: IIdLibLog;
    function RandomOrOne(var ARandom: TIdRandom; const ARandomized: Boolean): Single;
    class function RowVectorTimesMatrix(const AVector: TIdVec3; const AMatrix: TIdMat3): TIdVec3; static;
    procedure StandardOrigin(const AStage: TParticleStage; var AGen: TParticleGen; var AOrigin: TIdVec3);
    procedure CustomOrigin(const AStage: TParticleStage; var AGen: TParticleGen; var AOrigin: TIdVec3);
    function AimedVerts(const AStage: TParticleStage; var AGen: TParticleGen; const AOrigin: TIdVec3;
      var AVerts: TArray<TParticleVertex>): Integer;
  public
    constructor Create(const ALog: IIdLibLog = nil);
    function NumQuadsPerParticle(const AStage: TParticleStage): Integer;
    procedure ParticleOrigin(const AStage: TParticleStage; var AGen: TParticleGen; out AOrigin: TIdVec3);
    function ParticleVerts(const AStage: TParticleStage; var AGen: TParticleGen; const AOrigin: TIdVec3;
      var AVerts: TArray<TParticleVertex>): Integer;
    procedure ParticleTexCoords(const AStage: TParticleStage; var AGen: TParticleGen;
      var AVerts: TArray<TParticleVertex>);
    procedure ParticleColors(const AStage: TParticleStage; const AGen: TParticleGen;
      var AVerts: TArray<TParticleVertex>);
    function CreateParticle(const AStage: TParticleStage; var AGen: TParticleGen;
      var AVerts: TArray<TParticleVertex>): Integer;
    procedure CalculateStageBounds(var AStage: TParticleStage);
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Math.Math, DelphiDoom.MathCore.Float.GeometryAdapter,
  DelphiDoom.Geometry.Bounds;

const
  MS_TO_SEC: Single = 0.001;

{ TParticleGenerator }

constructor TParticleGenerator.Create(const ALog: IIdLibLog);
begin
  inherited Create;
  FLog := ALog;
end;

function TParticleGenerator.RandomOrOne(var ARandom: TIdRandom; const ARandomized: Boolean): Single;
begin
  if ARandomized then
    Result := ARandom.CRandomFloat
  else
    Result := 1.0;
end;

// idVec3 &operator*=( idVec3 &vec, const idMat3 &mat ): the vector as a row, which is the transpose of
// mat * vec (the operator* of the same two types).
class function TParticleGenerator.RowVectorTimesMatrix(const AVector: TIdVec3; const AMatrix: TIdMat3): TIdVec3;
begin
  Result.X := AMatrix.Rows[0].X * AVector.X + AMatrix.Rows[1].X * AVector.Y + AMatrix.Rows[2].X * AVector.Z;
  Result.Y := AMatrix.Rows[0].Y * AVector.X + AMatrix.Rows[1].Y * AVector.Y + AMatrix.Rows[2].Y * AVector.Z;
  Result.Z := AMatrix.Rows[0].Z * AVector.X + AMatrix.Rows[1].Z * AVector.Y + AMatrix.Rows[2].Z * AVector.Z;
end;

function TParticleGenerator.NumQuadsPerParticle(const AStage: TParticleStage): Integer;
var
  LTrails: Integer;
begin
  Result := 1;
  if AStage.Orientation = TParticleOrientation.Aimed then
  begin
    LTrails := TIdMath.Ftoi(AStage.OrientationParms[0]);
    // each trail stage will add an extra quad
    Result := Result * (1 + LTrails);
  end;
  // if we are doing strip-animation, we need to double the number and cross fade them
  if AStage.AnimationFrames > 1 then
    Result := Result * 2;
end;

procedure TParticleGenerator.StandardOrigin(const AStage: TParticleStage; var AGen: TParticleGen;
  var AOrigin: TIdVec3);
var
  LRadiusSqr, LAngle1, LAngle2, LF, LInvF, LNewRadius, LRescale, LSin1, LCos1, LSin2, LCos2, LRoot, LSpeed: Single;
  LDir: TIdVec3;
begin
  // find initial origin distribution
  case AStage.DistributionType of
    TParticleDistribution.Rect:
      begin
        AOrigin.X := RandomOrOne(AGen.Random, AStage.RandomDistribution) * AStage.DistributionParms[0];
        AOrigin.Y := RandomOrOne(AGen.Random, AStage.RandomDistribution) * AStage.DistributionParms[1];
        AOrigin.Z := RandomOrOne(AGen.Random, AStage.RandomDistribution) * AStage.DistributionParms[2];
      end;
    TParticleDistribution.Cylinder:
      begin
        LAngle1 := RandomOrOne(AGen.Random, AStage.RandomDistribution) * ID_TWO_PI;
        TIdMath.SinCos16(LAngle1, LSin1, LCos1);
        AOrigin.X := LSin1;
        AOrigin.Y := LCos1;
        AOrigin.Z := RandomOrOne(AGen.Random, AStage.RandomDistribution);
        // reproject points that are inside the ringFraction to the outer band
        if AStage.DistributionParms[3] > 0.0 then
        begin
          LRadiusSqr := AOrigin.X * AOrigin.X + AOrigin.Y * AOrigin.Y;
          if LRadiusSqr < AStage.DistributionParms[3] * AStage.DistributionParms[3] then
          begin
            // if we are inside the inner reject zone, rescale to put it out into the good zone
            LRoot := System.Sqrt(LRadiusSqr);
            LF := LRoot / AStage.DistributionParms[3];
            LInvF := 1.0 / LF;
            LNewRadius := AStage.DistributionParms[3] + LF * (1.0 - AStage.DistributionParms[3]);
            LRescale := LInvF * LNewRadius;
            AOrigin.X := AOrigin.X * LRescale;
            AOrigin.Y := AOrigin.Y * LRescale;
          end;
        end;
        AOrigin.X := AOrigin.X * AStage.DistributionParms[0];
        AOrigin.Y := AOrigin.Y * AStage.DistributionParms[1];
        AOrigin.Z := AOrigin.Z * AStage.DistributionParms[2];
      end;
    TParticleDistribution.Sphere:
      begin
        // iterating with rejection is the only way to get an even distribution over a sphere
        if AStage.RandomDistribution then
        begin
          repeat
            AOrigin.X := AGen.Random.CRandomFloat;
            AOrigin.Y := AGen.Random.CRandomFloat;
            AOrigin.Z := AGen.Random.CRandomFloat;
            LRadiusSqr := AOrigin.X * AOrigin.X + AOrigin.Y * AOrigin.Y + AOrigin.Z * AOrigin.Z;
          until not (LRadiusSqr > 1.0);
        end
        else
        begin
          AOrigin.SetValues(1.0, 1.0, 1.0);
          LRadiusSqr := 3.0;
        end;
        if AStage.DistributionParms[3] > 0.0 then
        begin
          // we could iterate until we got something that also satisfied ringFraction, but for narrow rings
          // that could be a lot of work, so reproject inside points instead
          if LRadiusSqr < AStage.DistributionParms[3] * AStage.DistributionParms[3] then
          begin
            LRoot := System.Sqrt(LRadiusSqr);
            LF := LRoot / AStage.DistributionParms[3];
            LInvF := 1.0 / LF;
            LNewRadius := AStage.DistributionParms[3] + LF * (1.0 - AStage.DistributionParms[3]);
            LRescale := LInvF * LNewRadius;
            AOrigin.X := AOrigin.X * LRescale;
            AOrigin.Y := AOrigin.Y * LRescale;
            AOrigin.Z := AOrigin.Z * LRescale;
          end;
        end;
        AOrigin.X := AOrigin.X * AStage.DistributionParms[0];
        AOrigin.Y := AOrigin.Y * AStage.DistributionParms[1];
        AOrigin.Z := AOrigin.Z * AStage.DistributionParms[2];
      end;
  end;

  // offset will effect all particle origin types: add this before the velocity and gravity additions
  AOrigin := AOrigin + AStage.Offset;

  // add the velocity over time
  case AStage.DirectionType of
    TParticleDirection.Cone:
      begin
        // angle is the full angle, so 360 degrees is any spherical direction
        LAngle1 := AGen.Random.CRandomFloat * AStage.DirectionParms[0] * ID_DEG2RAD;
        LAngle2 := AGen.Random.CRandomFloat * ID_PI;
        TIdMath.SinCos16(LAngle1, LSin1, LCos1);
        TIdMath.SinCos16(LAngle2, LSin2, LCos2);
        LDir.X := LSin1 * LCos2;
        LDir.Y := LSin1 * LSin2;
        LDir.Z := LCos1;
      end;
    TParticleDirection.Outward:
      begin
        LDir := AOrigin;
        LDir.Normalize;
        LDir.Z := LDir.Z + AStage.DirectionParms[0];
      end;
  end;

  // add speed
  LSpeed := AStage.Speed.Integrate(AGen.Frac, FLog);
  AOrigin := AOrigin + LDir * LSpeed * AStage.ParticleLife;
end;

procedure TParticleGenerator.CustomOrigin(const AStage: TParticleStage; var AGen: TParticleGen;
  var AOrigin: TIdVec3);
var
  LAngle1, LAngle2, LSpeed1, LSpeed2, LSin1, LCos1, LSin2, LCos2: Single;
begin
  // custom paths completely override both the origin and velocity calculations, but still use the
  // standard gravity
  case AStage.CustomPathType of
    TParticleCustomPath.Helix:
      begin
        // ( sizeX sizeY sizeZ radialSpeed axialSpeed )
        LSpeed1 := AGen.Random.CRandomFloat;
        LSpeed2 := AGen.Random.CRandomFloat;
        LAngle1 := AGen.Random.RandomFloat * ID_TWO_PI + AStage.CustomPathParms[3] * LSpeed1 * AGen.Age;
        TIdMath.SinCos16(LAngle1, LSin1, LCos1);
        AOrigin.X := LCos1 * AStage.CustomPathParms[0];
        AOrigin.Y := LSin1 * AStage.CustomPathParms[1];
        AOrigin.Z := AGen.Random.RandomFloat * AStage.CustomPathParms[2] +
          AStage.CustomPathParms[4] * LSpeed2 * AGen.Age;
      end;
    TParticleCustomPath.Flies:
      begin
        // ( radialSpeed axialSpeed size )
        LSpeed1 := TIdMath.ClampFloat(0.4, 1.0, AGen.Random.CRandomFloat);
        // speed2 of the original is never used, but its random number is drawn
        AGen.Random.CRandomFloat;
        LAngle1 := AGen.Random.RandomFloat * ID_PI * 2 + AStage.CustomPathParms[0] * LSpeed1 * AGen.Age;
        LAngle2 := AGen.Random.RandomFloat * ID_PI * 2 + AStage.CustomPathParms[1] * LSpeed1 * AGen.Age;
        TIdMath.SinCos16(LAngle1, LSin1, LCos1);
        TIdMath.SinCos16(LAngle2, LSin2, LCos2);
        AOrigin.X := LCos1 * LCos2;
        AOrigin.Y := LSin1 * LCos2;
        AOrigin.Z := -LSin2;
        AOrigin := AOrigin * AStage.CustomPathParms[2];
      end;
    TParticleCustomPath.Orbit:
      begin
        // ( radius speed axis )
        LAngle1 := AGen.Random.RandomFloat * ID_TWO_PI + AStage.CustomPathParms[1] * AGen.Age;
        TIdMath.SinCos16(LAngle1, LSin1, LCos1);
        AOrigin.X := LCos1 * AStage.CustomPathParms[0];
        AOrigin.Y := LSin1 * AStage.CustomPathParms[0];
        AOrigin.ProjectSelfOntoSphere(AStage.CustomPathParms[0]);
      end;
    TParticleCustomPath.Drip:
      begin
        // ( speed )
        AOrigin.X := 0.0;
        AOrigin.Y := 0.0;
        AOrigin.Z := -(AGen.Age * AStage.CustomPathParms[0]);
      end;
  else
    raise EDeclParticleException.Create('idParticleStage::ParticleOrigin: bad customPathType');
  end;
  AOrigin := AOrigin + AStage.Offset;
end;

procedure TParticleGenerator.ParticleOrigin(const AStage: TParticleStage; var AGen: TParticleGen;
  out AOrigin: TIdVec3);
var
  LGravity: TIdVec3;
  LAgeSquared: Single;
begin
  AOrigin.Zero;
  if AStage.CustomPathType = TParticleCustomPath.Standard then
    StandardOrigin(AStage, AGen, AOrigin)
  else
    CustomOrigin(AStage, AGen, AOrigin);

  // adjust for the per-particle smoke offset
  AOrigin := RowVectorTimesMatrix(AOrigin, AGen.Axis);
  AOrigin := AOrigin + AGen.Origin;

  // add gravity after adjusting for axis
  if AStage.WorldGravity then
  begin
    LGravity.SetValues(0.0, 0.0, -AStage.Gravity);
    LGravity := RowVectorTimesMatrix(LGravity, AGen.Entity.Axis.Transpose);
    AOrigin := AOrigin + LGravity * AGen.Age * AGen.Age;
  end
  else
  begin
    LAgeSquared := AStage.Gravity * AGen.Age * AGen.Age;
    AOrigin.Z := AOrigin.Z - LAgeSquared;
  end;
end;

function TParticleGenerator.AimedVerts(const AStage: TParticleStage; var AGen: TParticleGen;
  const AOrigin: TIdVec3; var AVerts: TArray<TParticleVertex>): Integer;
var
  LCurrentRandom: TIdRandom;
  LCurrentAge, LCurrentFrac, LTrailTime, LHeight, LT, LSize: Single;
  LStepOrigin, LStepLeft, LOldOrigin, LUp, LLeft, LForwardDir: TIdVec3;
  LNumTrails, LIndex, LBase: Integer;
begin
  LSize := AStage.Size.Eval(AGen.Frac);
  // reset the values to an earlier time to get a previous origin
  LCurrentRandom := AGen.Random;
  LCurrentAge := AGen.Age;
  LCurrentFrac := AGen.Frac;
  LStepOrigin := AOrigin;
  LStepLeft.Zero;
  LNumTrails := TIdMath.Ftoi(AStage.OrientationParms[0]);
  LTrailTime := AStage.OrientationParms[1];
  if LTrailTime = 0 then
    LTrailTime := 0.5;

  LHeight := 1.0 / (1 + LNumTrails);
  LT := 0;

  for LIndex := 0 to LNumTrails do
  begin
    AGen.Random := AGen.OriginalRandom;
    AGen.Age := LCurrentAge - (LIndex + 1) * LTrailTime / (LNumTrails + 1); // time to back up
    AGen.Frac := AGen.Age / AStage.ParticleLife;

    ParticleOrigin(AStage, AGen, LOldOrigin);

    LUp := LStepOrigin - LOldOrigin; // along the direction of travel

    AGen.Entity.Axis.ProjectVector(AGen.View.ViewAxis.Rows[0], LForwardDir);

    LUp := LUp - (LUp * LForwardDir) * LForwardDir;

    LUp.Normalize;

    LLeft := LUp.Cross(LForwardDir);
    LLeft := LLeft * LSize;

    LBase := LIndex * 4;
    if LIndex > 0 then
    begin
      // verts_p[k] = verts[k]: the first quad, as the previous iterations left it
      AVerts[LBase] := AVerts[0];
      AVerts[LBase + 1] := AVerts[1];
      AVerts[LBase + 2] := AVerts[2];
      AVerts[LBase + 3] := AVerts[3];
    end;

    if LIndex = 0 then
    begin
      AVerts[LBase].Xyz := LStepOrigin - LLeft;
      AVerts[LBase + 1].Xyz := LStepOrigin + LLeft;
    end
    else
    begin
      AVerts[LBase].Xyz := LStepOrigin - LStepLeft;
      AVerts[LBase + 1].Xyz := LStepOrigin + LStepLeft;
    end;
    AVerts[LBase + 2].Xyz := LOldOrigin - LLeft;
    AVerts[LBase + 3].Xyz := LOldOrigin + LLeft;

    // modify texcoords (the s of the first quad is the one of the texcoords of the stage)
    AVerts[LBase].St[1] := LT;
    AVerts[LBase + 1].St[1] := LT;
    AVerts[LBase + 2].St[1] := LT + LHeight;
    AVerts[LBase + 3].St[1] := LT + LHeight;

    LT := LT + LHeight;

    LStepOrigin := LOldOrigin;
    LStepLeft := LLeft;
  end;

  AGen.Random := LCurrentRandom;
  AGen.Age := LCurrentAge;
  AGen.Frac := LCurrentFrac;

  Result := 4 * (LNumTrails + 1);
end;

function TParticleGenerator.ParticleVerts(const AStage: TParticleStage; var AGen: TParticleGen;
  const AOrigin: TIdVec3; var AVerts: TArray<TParticleVertex>): Integer;
var
  LSize, LAspect, LWidth, LHeight, LAngle, LAngleMove, LCos, LSin: Single;
  LLeft, LUp, LEntityLeft, LEntityUp: TIdVec3;
begin
  LSize := AStage.Size.Eval(AGen.Frac);
  LAspect := AStage.Aspect.Eval(AGen.Frac);

  LWidth := LSize;
  LHeight := LSize * LAspect;

  if AStage.Orientation = TParticleOrientation.Aimed then
    Exit(AimedVerts(AStage, AGen, AOrigin, AVerts));

  // constant rotation
  if AStage.InitialAngle <> 0 then
    LAngle := AStage.InitialAngle
  else
    LAngle := 360 * AGen.Random.RandomFloat;

  LAngleMove := AStage.RotationSpeed.Integrate(AGen.Frac, FLog) * AStage.ParticleLife;
  // have half the particles rotate each way
  if (AGen.Index and 1) <> 0 then
    LAngle := LAngle + LAngleMove
  else
    LAngle := LAngle - LAngleMove;

  LAngle := LAngle / 180 * ID_PI;
  LCos := TIdMath.Cos16(LAngle);
  LSin := TIdMath.Sin16(LAngle);

  case AStage.Orientation of
    TParticleOrientation.Z:
      begin
        // oriented in entity space
        LLeft.SetValues(LSin, LCos, 0);
        LUp.SetValues(LCos, -LSin, 0);
      end;
    TParticleOrientation.X:
      begin
        LLeft.SetValues(0, LCos, LSin);
        LUp.SetValues(0, -LSin, LCos);
      end;
    TParticleOrientation.Y:
      begin
        LLeft.SetValues(LCos, 0, LSin);
        LUp.SetValues(-LSin, 0, LCos);
      end;
  else
    // oriented in viewer space
    AGen.Entity.Axis.ProjectVector(AGen.View.ViewAxis.Rows[1], LEntityLeft);
    AGen.Entity.Axis.ProjectVector(AGen.View.ViewAxis.Rows[2], LEntityUp);
    LLeft := LEntityLeft * LCos + LEntityUp * LSin;
    LUp := LEntityUp * LCos - LEntityLeft * LSin;
  end;

  LLeft := LLeft * LWidth;
  LUp := LUp * LHeight;

  AVerts[0].Xyz := AOrigin - LLeft + LUp;
  AVerts[1].Xyz := AOrigin + LLeft + LUp;
  AVerts[2].Xyz := AOrigin - LLeft - LUp;
  AVerts[3].Xyz := AOrigin + LLeft - LUp;

  Result := 4;
end;

procedure TParticleGenerator.ParticleTexCoords(const AStage: TParticleStage; var AGen: TParticleGen;
  var AVerts: TArray<TParticleVertex>);
var
  LS, LWidth, LT, LHeight, LFloatFrame: Single;
  LIntFrame: Integer;
begin
  if AStage.AnimationFrames > 1 then
  begin
    LWidth := 1.0 / AStage.AnimationFrames;
    if AStage.AnimationRate <> 0 then
      // explicit, cycling animation
      LFloatFrame := AGen.Age * AStage.AnimationRate
    else
      // single animation cycle over the life of the particle
      LFloatFrame := AGen.Frac * AStage.AnimationFrames;
    LIntFrame := Trunc(LFloatFrame);
    AGen.AnimationFrameFrac := LFloatFrame - LIntFrame;
    LS := LWidth * LIntFrame;
  end
  else
  begin
    LS := 0.0;
    LWidth := 1.0;
  end;

  LT := 0.0;
  LHeight := 1.0;

  AVerts[0].St[0] := LS;
  AVerts[0].St[1] := LT;

  AVerts[1].St[0] := LS + LWidth;
  AVerts[1].St[1] := LT;

  AVerts[2].St[0] := LS;
  AVerts[2].St[1] := LT + LHeight;

  AVerts[3].St[0] := LS + LWidth;
  AVerts[3].St[1] := LT + LHeight;
end;

procedure TParticleGenerator.ParticleColors(const AStage: TParticleStage; const AGen: TParticleGen;
  var AVerts: TArray<TParticleVertex>);
var
  LFadeFraction, LIndexFrac, LColor, LSource, LMix: Single;
  LColors, LFades: array[0..3] of Single;
  LIndex, LIntColor: Integer;
begin
  LFadeFraction := 1.0;

  // most particles fade in at the beginning and fade out at the end
  if AGen.Frac < AStage.FadeInFraction then
    LFadeFraction := LFadeFraction * (AGen.Frac / AStage.FadeInFraction);
  if 1.0 - AGen.Frac < AStage.FadeOutFraction then
    LFadeFraction := LFadeFraction * ((1.0 - AGen.Frac) / AStage.FadeOutFraction);

  // individual gun smoke particles get more and more faded as the cycle goes on (note that totalParticles
  // won't be correct for a surface-particle deform)
  if AStage.FadeIndexFraction <> 0 then
  begin
    LIndexFrac := (AStage.TotalParticles - AGen.Index) / Single(AStage.TotalParticles);
    if LIndexFrac < AStage.FadeIndexFraction then
      LFadeFraction := LFadeFraction * (LIndexFrac / AStage.FadeIndexFraction);
  end;

  LColors[0] := AStage.Color.X;
  LColors[1] := AStage.Color.Y;
  LColors[2] := AStage.Color.Z;
  LColors[3] := AStage.Color.W;
  LFades[0] := AStage.FadeColor.X;
  LFades[1] := AStage.FadeColor.Y;
  LFades[2] := AStage.FadeColor.Z;
  LFades[3] := AStage.FadeColor.W;

  for LIndex := 0 to 3 do
  begin
    if AStage.EntityColor then
      LSource := AGen.Entity.ShaderParms[LIndex]
    else
      LSource := LColors[LIndex];
    LColor := LSource * LFadeFraction;
    LMix := LFades[LIndex] * (1.0 - LFadeFraction);
    LColor := LColor + LMix;
    LColor := LColor * 255.0;
    LIntColor := TIdMath.FtoiFast(LColor);
    if LIntColor < 0 then
      LIntColor := 0
    else if LIntColor > 255 then
      LIntColor := 255;
    AVerts[0].Color[LIndex] := LIntColor;
    AVerts[1].Color[LIndex] := LIntColor;
    AVerts[2].Color[LIndex] := LIntColor;
    AVerts[3].Color[LIndex] := LIntColor;
  end;
end;

function TParticleGenerator.CreateParticle(const AStage: TParticleStage; var AGen: TParticleGen;
  var AVerts: TArray<TParticleVertex>): Integer;
var
  LOrigin: TIdVec3;
  LNumVerts, LIndex, LChannel, LQuadVerts: Integer;
  LWidth, LFrac, LInverseFrac, LScaled: Single;
begin
  LQuadVerts := 4 * NumQuadsPerParticle(AStage);
  if Length(AVerts) < LQuadVerts then
    SetLength(AVerts, LQuadVerts);

  AVerts[0].Clear;
  AVerts[1].Clear;
  AVerts[2].Clear;
  AVerts[3].Clear;

  ParticleColors(AStage, AGen, AVerts);

  // if we are completely faded out, kill the particle
  if (AVerts[0].Color[0] = 0) and (AVerts[0].Color[1] = 0) and (AVerts[0].Color[2] = 0) and
    (AVerts[0].Color[3] = 0) then
    Exit(0);

  ParticleOrigin(AStage, AGen, LOrigin);

  ParticleTexCoords(AStage, AGen, AVerts);

  LNumVerts := ParticleVerts(AStage, AGen, LOrigin, AVerts);

  if AStage.AnimationFrames <= 1 then
    Exit(LNumVerts);

  // if we are doing strip-animation, we need to double the quad and cross fade it
  LWidth := 1.0 / AStage.AnimationFrames;
  LFrac := AGen.AnimationFrameFrac;
  LInverseFrac := 1.0 - LFrac;
  for LIndex := 0 to LNumVerts - 1 do
  begin
    AVerts[LNumVerts + LIndex] := AVerts[LIndex];

    AVerts[LNumVerts + LIndex].St[0] := AVerts[LNumVerts + LIndex].St[0] + LWidth;

    // verts[].color[i] *= frac: a byte multiplied by a float and truncated back
    for LChannel := 0 to 3 do
    begin
      LScaled := AVerts[LNumVerts + LIndex].Color[LChannel] * LFrac;
      AVerts[LNumVerts + LIndex].Color[LChannel] := Trunc(LScaled);
    end;
    for LChannel := 0 to 3 do
    begin
      LScaled := AVerts[LIndex].Color[LChannel] * LInverseFrac;
      AVerts[LIndex].Color[LChannel] := Trunc(LScaled);
    end;
  end;

  Result := LNumVerts * 2;
end;

procedure TParticleGenerator.CalculateStageBounds(var AStage: TParticleStage);
var
  LGen: TParticleGen;
  LRandom: TIdRandom;
  LOrigin: TIdVec3;
  LMaxMsec, LInCycleTime: Integer;
  LLifeMsec, LSizeValue, LAspectValue, LMaxSize, LFraction: Single;
begin
  AStage.Bounds.Clear;

  // this isn't absolutely guaranteed, but it should be close
  LRandom := TIdRandom.Create(0);
  LGen := TParticleGen.Create(LRandom);

  // The original repeats this 1000 times, each time from the same random generator (steppingRandom is never
  // advanced), so every pass gives the same points: one pass gives the same bounds.
  LGen.Random := LRandom;
  LGen.OriginalRandom := LRandom;

  LLifeMsec := AStage.ParticleLife * 1000;
  LMaxMsec := Trunc(LLifeMsec);
  LInCycleTime := 0;
  while LInCycleTime < LMaxMsec do
  begin
    // make sure we get the very last tic, which may make up an extreme edge
    if LInCycleTime + 16 > LMaxMsec then
      LInCycleTime := LMaxMsec - 1;

    LGen.Frac := LInCycleTime / LLifeMsec;
    LGen.Age := LInCycleTime * MS_TO_SEC;

    ParticleOrigin(AStage, LGen, LOrigin);
    AStage.Bounds.AddPoint(TIdGeometryAdapter.ToGeo(LOrigin));
    Inc(LInCycleTime, 16);
  end;

  // find the max size
  LMaxSize := 0;
  LFraction := 0;
  while LFraction <= 1.0 do
  begin
    LSizeValue := AStage.Size.Eval(LFraction);
    LAspectValue := AStage.Aspect.Eval(LFraction);
    if LAspectValue > 1 then
      LSizeValue := LSizeValue * LAspectValue;
    if LSizeValue > LMaxSize then
      LMaxSize := LSizeValue;
    LFraction := LFraction + 1.0 / 64;
  end;

  LMaxSize := LMaxSize + 8; // just for good measure
  // users can specify a per-stage bounds expansion to handle odd cases
  AStage.Bounds.ExpandSelf(LMaxSize + AStage.BoundsExpansion);
end;

end.
