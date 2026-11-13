{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - interfaces of the "particle" declaration  }
{                                                                              }
{  Not derived from Doom 3 code: written for this repository (GPL v2 or        }
{  later). The data and the calculation they describe are those of             }
{  framework\DeclParticle.h of Doom 3.                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Particle.Intf;

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.Decl.Particle.Types;

type
  /// <summary>The data of a particle declaration (idDeclParticle): the stages, the bounds and the depth hack</summary>
  IDeclParticle = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0101}']
    function GetNumStages: Integer;
    /// <summary>A copy of the stage at the index; an <c>EDeclParticleException</c> when out of range</summary>
    function GetStage(const AIndex: Integer): TParticleStage;
    /// <summary>The bounds of all the stages (at least 8 units around the origin)</summary>
    function GetBounds: TGeoBounds;
    function GetDepthHack: Single;
  end;

  /// <summary>Writing a particle declaration back as text (the particle editor of Doom 3)</summary>
  IDeclParticleWriter = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0103}']
    /// <summary>idDeclParticle::RebuildTextSource: the text as the editor writes it; it also becomes the text of the declaration</summary>
    function RebuildTextSource: AnsiString;
    /// <summary>idDeclParticle::Save without a file name: rebuilds the text and replaces it in the source file</summary>
    function Save: Boolean;
  end;

  /// <summary>
  ///   The calculation of the particles of one stage (the methods of idParticleStage that make vertices): where a
  ///   particle is at a time, its quad, its texture coordinates and its colour. It reads the stage and the
  ///   generator state it is given and keeps nothing: a renderer can call it for every particle.
  /// </summary>
  IParticleGenerator = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0102}']
    /// <summary>The quads one particle needs, trails and cross faded animations included</summary>
    function NumQuadsPerParticle(const AStage: TParticleStage): Integer;
    /// <summary>
    ///   Where the particle is: <c>AGen.Frac</c> and <c>AGen.Age</c> are its time, <c>AGen.Random</c> is
    ///   consumed (<c>idParticleStage::ParticleOrigin</c>)
    /// </summary>
    procedure ParticleOrigin(const AStage: TParticleStage; var AGen: TParticleGen; out AOrigin: TIdVec3);
    /// <summary>The four vertices of the quad(s) at <c>AOrigin</c>; returns the number of vertices made</summary>
    function ParticleVerts(const AStage: TParticleStage; var AGen: TParticleGen; const AOrigin: TIdVec3;
      var AVerts: TArray<TParticleVertex>): Integer;
    procedure ParticleTexCoords(const AStage: TParticleStage; var AGen: TParticleGen;
      var AVerts: TArray<TParticleVertex>);
    procedure ParticleColors(const AStage: TParticleStage; const AGen: TParticleGen;
      var AVerts: TArray<TParticleVertex>);
    /// <summary>
    ///   idParticleStage::CreateParticle: 0 if the particle is completely faded out, 4 for a normal quad, 8 for two
    ///   cross faded quads (more with trails). <c>AVerts</c> grows to <c>4 * NumQuadsPerParticle</c> if shorter.
    /// </summary>
    function CreateParticle(const AStage: TParticleStage; var AGen: TParticleGen;
      var AVerts: TArray<TParticleVertex>): Integer;
    /// <summary>
    ///   The bounds of the stage (idDeclParticle::GetStageBounds): the origin of sample particles at every 16 ms of
    ///   their life, grown by the largest size and <c>BoundsExpansion</c>; stored in <c>AStage.Bounds</c>.
    /// </summary>
    procedure CalculateStageBounds(var AStage: TParticleStage);
  end;

implementation

end.
