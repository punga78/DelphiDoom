{******************************************************************************}
{                                                                              }
{  DelphiDoom: declarations - the model of a particle system (idRenderModelPrt) }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_prt.cpp   }
{  (idRenderModelPrt::InstantiateDynamicModel). Copyright (C) 1999-2011 id      }
{  Software LLC, a ZeniMax Media company. This unit is derived from the Doom 3 }
{  GPL source code and is therefore available under the GNU General Public     }
{  License, version 3, with the additional terms of the Doom 3 Source Code     }
{  License (see README.md of Libs\IdLib); the repository as a whole is GPL v2  }
{  or later.                                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Particle.ModelBuilder;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Geometry.Bounds, DelphiDoom.Decl.Particle.Types, DelphiDoom.Decl.Particle.Intf;

const
  /// <summary>SHADERPARM_TIMEOFFSET: seconds added to the age of the system</summary>
  SHADERPARM_PARTICLE_TIMEOFFSET = 4;
  /// <summary>SHADERPARM_DIVERSITY: a number from 0 to 1 that changes the random numbers of the system</summary>
  SHADERPARM_PARTICLE_DIVERSITY = 5;
  /// <summary>SHADERPARM_PARTICLE_STOPTIME: no more particles are born after this time (seconds, 0 is never)</summary>
  SHADERPARM_PARTICLE_STOPTIME = 8;

type
  /// <summary>One surface of the model of a particle system: the quads of one stage</summary>
  TParticleSurface = record
    /// <summary>The number of the stage (the id of the surface)</summary>
    StageNum: Integer;
    /// <summary>The material of the stage, a name</summary>
    MaterialName: AnsiString;
    /// <summary>Four vertexes for every quad that is alive</summary>
    Verts: TArray<TParticleVertex>;
    /// <summary>Six indexes for every quad: 0 2 3 0 3 1 plus 4 for every quad</summary>
    Indexes: TArray<Integer>;
    /// <summary>The bounds of the stage, always (the particles are always drawn)</summary>
    Bounds: TGeoBounds;
  end;

  /// <summary>
  ///   The model of a particle system that has a time (<c>idRenderModelPrt::InstantiateDynamicModel</c>):
  ///   for every stage the particles that are alive at the time of the view are made by the generator
  ///   (<c>CreateParticle</c>) with the random numbers that the cycle of the stage and the diversity of the
  ///   entity give. The time is an argument (the time of the view, in milliseconds); the generator is
  ///   injected. Not ported: the reuse of the model of the last frame (it only saves allocations), the
  ///   declaration lookup (the declaration arrives resolved) and the memory counts.
  /// </summary>
  TParticleModelBuilder = class
  strict private
    FGenerator: IParticleGenerator;
    FSkipParticles: Boolean;
  public
    constructor Create(const AGenerator: IParticleGenerator);
    /// <summary>
    ///   The surfaces at a time: one for each stage that has a material, a cycle and is not hidden, in
    ///   the order of the stages (a stage that is skipped has no surface). Empty with
    ///   <c>SkipParticles</c> (<c>r_skipParticles</c>).
    /// </summary>
    function Instantiate(const ADecl: IDeclParticle; const ATime: Integer; const AEntity: TParticleEntity;
      const AView: TParticleView): TArray<TParticleSurface>;
    /// <summary>r_skipParticles: no particles at all</summary>
    property SkipParticles: Boolean read FSkipParticles write FSkipParticles;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Random;

{ TParticleModelBuilder }

constructor TParticleModelBuilder.Create(const AGenerator: IParticleGenerator);
begin
  inherited Create;
  FGenerator := AGenerator;
end;

function TParticleModelBuilder.Instantiate(const ADecl: IDeclParticle; const ATime: Integer;
  const AEntity: TParticleEntity; const AView: TParticleView): TArray<TParticleSurface>;
var
  LGen: TParticleGen;
  LStage: TParticleStage;
  LSteppingRandom, LSteppingRandom2: TIdRandom;
  LStageNum, LStageAge, LStageCycle, LCount, LNumVerts, LIndex, LBunchOffset, LParticleAge, LParticleCycle: Integer;
  LInCycleTime, LCreated, LItem, LDiversity: Integer;
  LParticle: TArray<TParticleVertex>;
  LSurface: TParticleSurface;
  LAgeSeconds, LFloat: Single;
  LExpression: Extended;
begin
  Result := nil;
  if FSkipParticles then
    Exit;
  LGen := TParticleGen.Create(TIdRandom.Create(0));
  LGen.Entity := AEntity;
  LGen.View := AView;
  LGen.Origin.Zero;
  for LStageNum := 0 to ADecl.GetNumStages - 1 do
  begin
    LStage := ADecl.GetStage(LStageNum);
    if LStage.Material = nil then
      Continue;
    if LStage.CycleMsec = 0 then
      Continue;
    // just for the particle editor
    if LStage.Hidden then
      Continue;
    LExpression := ATime;
    LExpression := LExpression + AEntity.ShaderParms[SHADERPARM_PARTICLE_TIMEOFFSET] * 1000 - LStage.TimeOffset * 1000;
    LStageAge := Trunc(LExpression);
    LStageCycle := LStageAge div LStage.CycleMsec;
    LFloat := AEntity.ShaderParms[SHADERPARM_PARTICLE_DIVERSITY] * ID_MAX_RAND;
    LDiversity := Trunc(LFloat);
    LSteppingRandom := TIdRandom.Create(0);
    LSteppingRandom2 := TIdRandom.Create(0);
    // some particles are in this cycle, some in the previous one
    LSteppingRandom.SetSeed(((LStageCycle shl 10) and ID_MAX_RAND) xor LDiversity);
    LSteppingRandom2.SetSeed((((LStageCycle - 1) shl 10) and ID_MAX_RAND) xor LDiversity);
    LCount := LStage.TotalParticles * FGenerator.NumQuadsPerParticle(LStage);
    LSurface.StageNum := LStageNum;
    LSurface.MaterialName := LStage.Material.GetName;
    SetLength(LSurface.Verts, 4 * LCount);
    LNumVerts := 0;
    for LIndex := 0 to LStage.TotalParticles - 1 do
    begin
      LGen.Index := LIndex;
      // bump the random
      LSteppingRandom.RandomInt;
      LSteppingRandom2.RandomInt;
      // the local age of the particle
      LExpression := LStage.ParticleLife * 1000 * LStage.SpawnBunching * LIndex / LStage.TotalParticles;
      LBunchOffset := Trunc(LExpression);
      LParticleAge := LStageAge - LBunchOffset;
      LParticleCycle := LParticleAge div LStage.CycleMsec;
      // before the particle system spawned
      if LParticleCycle < 0 then
        Continue;
      // a cycled system runs only its cycles
      if (LStage.Cycles <> 0) and (LParticleCycle >= LStage.Cycles) then
        Continue;
      if LParticleCycle = LStageCycle then
        LGen.Random := LSteppingRandom
      else
        LGen.Random := LSteppingRandom2;
      LInCycleTime := LParticleAge - LParticleCycle * LStage.CycleMsec;
      // no more particles after the stop time
      if (AEntity.ShaderParms[SHADERPARM_PARTICLE_STOPTIME] <> 0) and
        (ATime - LInCycleTime >= AEntity.ShaderParms[SHADERPARM_PARTICLE_STOPTIME] * 1000) then
        Continue;
      // particles before or after the age clamp are not drawn
      LAgeSeconds := LStage.ParticleLife * 1000;
      LGen.Frac := LInCycleTime / LAgeSeconds;
      // yet to be spawned
      if LGen.Frac < 0.0 then
        Continue;
      // in the dead time
      if LGen.Frac > 1.0 then
        Continue;
      // the aimed particles need the random again to find where they were
      LGen.OriginalRandom := LGen.Random;
      LGen.Age := LGen.Frac * LStage.ParticleLife;
      // a particle that is faded out or past a kill region makes no vertexes
      LCreated := FGenerator.CreateParticle(LStage, LGen, LParticle);
      for LItem := 0 to LCreated - 1 do
        LSurface.Verts[LNumVerts + LItem] := LParticle[LItem];
      Inc(LNumVerts, LCreated);
    end;
    // the number of vertexes is a multiple of 4: build the indexes
    SetLength(LSurface.Verts, LNumVerts);
    SetLength(LSurface.Indexes, (LNumVerts div 4) * 6);
    LItem := 0;
    LIndex := 0;
    while LIndex < LNumVerts do
    begin
      LSurface.Indexes[LItem + 0] := LIndex;
      LSurface.Indexes[LItem + 1] := LIndex + 2;
      LSurface.Indexes[LItem + 2] := LIndex + 3;
      LSurface.Indexes[LItem + 3] := LIndex;
      LSurface.Indexes[LItem + 4] := LIndex + 3;
      LSurface.Indexes[LItem + 5] := LIndex + 1;
      Inc(LItem, 6);
      Inc(LIndex, 4);
    end;
    LSurface.Bounds := LStage.Bounds;
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := LSurface;
  end;
end;

end.
