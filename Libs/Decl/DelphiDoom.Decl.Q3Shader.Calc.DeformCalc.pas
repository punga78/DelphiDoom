{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - vertex deformations           }
{                                                                              }
{  RB_CalcDeformVertexes, RB_CalcDeformNormals, RB_CalcBulgeVertexes,          }
{  RB_CalcMoveVertexes and the dispatch of RB_DeformTessGeometry of            }
{  renderer\tr_shade_calc.c of Quake III Arena (id Software, GPL v2 or         }
{  later). Based on the Quake III Arena GPL Source Code (id Software).         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.DeformCalc;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Calc.Types, DelphiDoom.Decl.Q3Shader.Calc.FuncTables,
  DelphiDoom.Decl.Q3Shader.Calc.WaveEvaluator, DelphiDoom.Decl.Q3Shader.Calc.Noise;

type
  /// <summary>
  ///   The deformations of the vertices of a surface as calculations on the buffers of
  ///   <c>TQ3ShaderTess</c> (positions and normals with four floats per vertex). The time is in the buffers:
  ///   nothing reads a clock.
  /// </summary>
  TQ3DeformCalc = class
  strict private
    FWaves: TQ3WaveEvaluator;
    FTables: TQ3FuncTables;
    FNoise: TQ3Noise;
  public
    /// <summary>The evaluator, the tables and the noise are not owned</summary>
    constructor Create(const AWaves: TQ3WaveEvaluator; const ATables: TQ3FuncTables; const ANoise: TQ3Noise);
    /// <summary>RB_CalcDeformVertexes: <c>deformVertexes wave</c></summary>
    procedure CalcDeformVertexes(const ADeform: TQ3DeformStage; var ATess: TQ3ShaderTess);
    /// <summary>RB_CalcDeformNormals: <c>deformVertexes normal</c> (amplitude and frequency of the wave)</summary>
    procedure CalcDeformNormals(const ADeform: TQ3DeformStage; var ATess: TQ3ShaderTess);
    /// <summary>RB_CalcBulgeVertexes: <c>deformVertexes bulge</c>, on <c>backEnd.refdef.time</c> and the texture set 0</summary>
    procedure CalcBulgeVertexes(const ADeform: TQ3DeformStage; var ATess: TQ3ShaderTess);
    /// <summary>RB_CalcMoveVertexes: <c>deformVertexes move</c></summary>
    procedure CalcMoveVertexes(const ADeform: TQ3DeformStage; var ATess: TQ3ShaderTess);
    /// <summary>
    ///   The <c>switch</c> of RB_DeformTessGeometry for one stage. False for the deformations that need the
    ///   renderer (<c>projectionShadow</c>, <c>autosprite</c>, <c>autosprite2</c>, <c>text0..7</c>: they build
    ///   quads from the view and the entity): nothing is done.
    /// </summary>
    function Apply(const ADeform: TQ3DeformStage; var ATess: TQ3ShaderTess): Boolean;
  end;

implementation

uses
  DelphiDoom.Decl.Q3Shader.Calc.FloatMask;

constructor TQ3DeformCalc.Create(const AWaves: TQ3WaveEvaluator; const ATables: TQ3FuncTables;
  const ANoise: TQ3Noise);
begin
  inherited Create;
  FWaves := AWaves;
  FTables := ATables;
  FNoise := ANoise;
end;

procedure TQ3DeformCalc.CalcDeformVertexes(const ADeform: TQ3DeformStage; var ATess: TQ3ShaderTess);
var
  LIndex, LAxis: Integer;
  LScale, LOffset, LSum: Single;
  LTable: TQ3FuncTable;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireFloats(ATess.Xyz, ATess.NumVertexes, 4, 'xyz');
  TQ3CMath.RequireFloats(ATess.Normal, ATess.NumVertexes, 4, 'normal');
  if ADeform.DeformationWave.Frequency = 0 then
  begin
    LScale := FWaves.EvalWaveForm(ADeform.DeformationWave, ATess.ShaderTime);
    for LIndex := 0 to ATess.NumVertexes - 1 do
      for LAxis := 0 to 2 do
      begin
        LSum := ATess.Normal[LIndex * 4 + LAxis] * LScale;
        ATess.Xyz[LIndex * 4 + LAxis] := ATess.Xyz[LIndex * 4 + LAxis] + LSum;
      end;
  end
  else
  begin
    LTable := FTables.TableFor(ADeform.DeformationWave.Func);
    for LIndex := 0 to ATess.NumVertexes - 1 do
    begin
      // off = ( xyz[0] + xyz[1] + xyz[2] ) * deformationSpread
      LOffset := ATess.Xyz[LIndex * 4] + ATess.Xyz[LIndex * 4 + 1];
      LOffset := LOffset + ATess.Xyz[LIndex * 4 + 2];
      LOffset := LOffset * ADeform.DeformationSpread;
      LOffset := ADeform.DeformationWave.Phase + LOffset;
      LScale := FWaves.WaveValue(LTable, ADeform.DeformationWave.Base, ADeform.DeformationWave.Amplitude,
        LOffset, ADeform.DeformationWave.Frequency, ATess.ShaderTime);
      for LAxis := 0 to 2 do
      begin
        LSum := ATess.Normal[LIndex * 4 + LAxis] * LScale;
        ATess.Xyz[LIndex * 4 + LAxis] := ATess.Xyz[LIndex * 4 + LAxis] + LSum;
      end;
    end;
  end;
end;

procedure TQ3DeformCalc.CalcDeformNormals(const ADeform: TQ3DeformStage; var ATess: TQ3ShaderTess);
const
  Base: array[0..2] of Single = (0, 100, 200);
var
  LIndex, LAxis: Integer;
  LScale, LTime, LX, LY, LZ, LValue: Single;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireFloats(ATess.Xyz, ATess.NumVertexes, 4, 'xyz');
  TQ3CMath.RequireFloats(ATess.Normal, ATess.NumVertexes, 4, 'normal');
  for LIndex := 0 to ATess.NumVertexes - 1 do
  begin
    for LAxis := 0 to 2 do
    begin
      LScale := 0.98;
      LX := ATess.Xyz[LIndex * 4] * LScale;
      if LAxis > 0 then
        LX := Base[LAxis] + LX;
      LY := ATess.Xyz[LIndex * 4 + 1] * LScale;
      LZ := ATess.Xyz[LIndex * 4 + 2] * LScale;
      LTime := ATess.ShaderTime * ADeform.DeformationWave.Frequency;
      LScale := FNoise.Get4f(LX, LY, LZ, LTime);
      LValue := ADeform.DeformationWave.Amplitude * LScale;
      ATess.Normal[LIndex * 4 + LAxis] := ATess.Normal[LIndex * 4 + LAxis] + LValue;
    end;
    TQ3CMath.NormalizeFast(ATess.Normal, LIndex * 4);
  end;
end;

procedure TQ3DeformCalc.CalcBulgeVertexes(const ADeform: TQ3DeformStage; var ATess: TQ3ShaderTess);
var
  LIndex, LAxis, LOffset: Integer;
  LNow, LPi, LTwoPi, LFactor, LPosition, LScale, LTerm: Single;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireFloats(ATess.Xyz, ATess.NumVertexes, 4, 'xyz');
  TQ3CMath.RequireFloats(ATess.Normal, ATess.NumVertexes, 4, 'normal');
  TQ3CMath.RequireFloats(ATess.TexCoords, ATess.NumVertexes, 4, 'texCoords');
  // now = refdef.time * bulgeSpeed * 0.001f
  LNow := ATess.RefDefTime;
  LNow := LNow * ADeform.BulgeSpeed;
  LNow := LNow * 0.001;
  // ( float )( FUNCTABLE_SIZE / ( M_PI * 2 ) ): M_PI is a float constant, the division is float
  LPi := 3.14159265358979323846;
  LTwoPi := LPi * 2;
  LFactor := Q3_FUNCTABLE_SIZE;
  LFactor := LFactor / LTwoPi;
  for LIndex := 0 to ATess.NumVertexes - 1 do
  begin
    LPosition := ATess.TexCoords[LIndex * 4] * ADeform.BulgeWidth;
    LPosition := LPosition + LNow;
    LPosition := LFactor * LPosition;
    LOffset := TQ3CMath.FloatToInt(LPosition);
    LScale := FTables.SinTable[LOffset and Q3_FUNCTABLE_MASK] * ADeform.BulgeHeight;
    for LAxis := 0 to 2 do
    begin
      LTerm := ATess.Normal[LIndex * 4 + LAxis] * LScale;
      ATess.Xyz[LIndex * 4 + LAxis] := ATess.Xyz[LIndex * 4 + LAxis] + LTerm;
    end;
  end;
end;

procedure TQ3DeformCalc.CalcMoveVertexes(const ADeform: TQ3DeformStage; var ATess: TQ3ShaderTess);
var
  LIndex, LAxis: Integer;
  LScale: Single;
  LOffset: array[0..2] of Single;
  LTable: TQ3FuncTable;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireFloats(ATess.Xyz, ATess.NumVertexes, 4, 'xyz');
  LTable := FTables.TableFor(ADeform.DeformationWave.Func);
  LScale := FWaves.WaveValue(LTable, ADeform.DeformationWave.Base, ADeform.DeformationWave.Amplitude,
    ADeform.DeformationWave.Phase, ADeform.DeformationWave.Frequency, ATess.ShaderTime);
  for LAxis := 0 to 2 do
    LOffset[LAxis] := ADeform.MoveVector[LAxis] * LScale;
  for LIndex := 0 to ATess.NumVertexes - 1 do
    for LAxis := 0 to 2 do
      ATess.Xyz[LIndex * 4 + LAxis] := ATess.Xyz[LIndex * 4 + LAxis] + LOffset[LAxis];
end;

function TQ3DeformCalc.Apply(const ADeform: TQ3DeformStage; var ATess: TQ3ShaderTess): Boolean;
begin
  Result := True;
  case ADeform.Deformation of
    dfNone:
      ;
    dfNormals:
      CalcDeformNormals(ADeform, ATess);
    dfWave:
      CalcDeformVertexes(ADeform, ATess);
    dfBulge:
      CalcBulgeVertexes(ADeform, ATess);
    dfMove:
      CalcMoveVertexes(ADeform, ATess);
  else
    Result := False;
  end;
end;

end.
