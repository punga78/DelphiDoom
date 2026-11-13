{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - texture coordinates           }
{                                                                              }
{  RB_CalcStretchTexCoords, RB_CalcTurbulentTexCoords, RB_CalcScaleTexCoords,  }
{  RB_CalcScrollTexCoords, RB_CalcTransformTexCoords, RB_CalcRotateTexCoords,  }
{  RB_CalcEnvironmentTexCoords of renderer\tr_shade_calc.c and the             }
{  texture coordinate part of ComputeTexCoords of renderer\tr_shade.c of       }
{  Quake III Arena (id Software, GPL v2 or later). Based on the Quake III      }
{  Arena GPL Source Code (id Software).                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.TexCoordCalc;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Calc.Types, DelphiDoom.Decl.Q3Shader.Calc.FuncTables,
  DelphiDoom.Decl.Q3Shader.Calc.WaveEvaluator;

type
  /// <summary>
  ///   The texture coordinates of a stage bundle at a time. A coordinate buffer (<c>st</c>) is two floats per
  ///   vertex. Every function works on the buffer it is given, as the original works on
  ///   <c>tess.svars.texcoords[b]</c>.
  /// </summary>
  TQ3TexCoordCalc = class
  strict private
    FWaves: TQ3WaveEvaluator;
    FTables: TQ3FuncTables;
  public
    /// <summary>The evaluator and the tables are not owned</summary>
    constructor Create(const AWaves: TQ3WaveEvaluator; const ATables: TQ3FuncTables);
    /// <summary>RB_CalcStretchTexCoords</summary>
    procedure CalcStretch(const AWave: TQ3WaveForm; const AShaderTime: Single; const ANumVertexes: Integer;
      var ATexCoords: TArray<Single>);
    /// <summary>RB_CalcTurbulentTexCoords: the position of the vertex (<c>AXyz</c>, four floats per vertex)</summary>
    procedure CalcTurbulent(const AWave: TQ3WaveForm; const AShaderTime: Single; const ANumVertexes: Integer;
      const AXyz: TArray<Single>; var ATexCoords: TArray<Single>);
    /// <summary>RB_CalcScaleTexCoords</summary>
    class procedure CalcScale(const AScaleS, AScaleT: Single; const ANumVertexes: Integer;
      var ATexCoords: TArray<Single>); static;
    /// <summary>RB_CalcScrollTexCoords</summary>
    class procedure CalcScroll(const ASpeedS, ASpeedT, AShaderTime: Single; const ANumVertexes: Integer;
      var ATexCoords: TArray<Single>); static;
    /// <summary>RB_CalcTransformTexCoords</summary>
    class procedure CalcTransform(const AMod: TQ3TexMod; const ANumVertexes: Integer;
      var ATexCoords: TArray<Single>); static;
    /// <summary>RB_CalcRotateTexCoords</summary>
    procedure CalcRotate(const ADegreesPerSecond, AShaderTime: Single; const ANumVertexes: Integer;
      var ATexCoords: TArray<Single>);
    /// <summary>RB_CalcEnvironmentTexCoords</summary>
    class procedure CalcEnvironment(const ATess: TQ3ShaderTess; var ATexCoords: TArray<Single>); static;
    /// <summary>
    ///   The texture coordinate half of ComputeTexCoords for one bundle: <c>tcGen</c>, then each <c>tcMod</c>
    ///   in order (a <c>tmNone</c> ends the list). <c>tgBad</c> leaves the buffer as it is and applies no
    ///   <c>tcMod</c>. <c>tgFog</c> needs the fog volume of the world, which is not ported:
    ///   <c>EDeclQ3ShaderCalcException</c>, like an <c>entity</c> modifier without an entity.
    /// </summary>
    procedure Compute(const ABundle: TQ3TextureBundle; const ATess: TQ3ShaderTess;
      var ATexCoords: TArray<Single>);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Decl.Q3Shader.Calc.FloatMask;

const
  SFogNotPorted = 'tcGen fog needs the fog volumes of the world';
  SNoEntity = 'tcMod entity needs an entity';

constructor TQ3TexCoordCalc.Create(const AWaves: TQ3WaveEvaluator; const ATables: TQ3FuncTables);
begin
  inherited Create;
  FWaves := AWaves;
  FTables := ATables;
end;

procedure TQ3TexCoordCalc.CalcStretch(const AWave: TQ3WaveForm; const AShaderTime: Single;
  const ANumVertexes: Integer; var ATexCoords: TArray<Single>);
var
  LInverse, LHalf: Single;
  LMod: TQ3TexMod;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  LInverse := FWaves.EvalWaveForm(AWave, AShaderTime);
  LInverse := 1.0 / LInverse;
  LHalf := 0.5 * LInverse;
  FillChar(LMod, SizeOf(LMod), 0);
  LMod.Matrix[0][0] := LInverse;
  LMod.Matrix[1][0] := 0;
  LMod.Translate[0] := 0.5 - LHalf;
  LMod.Matrix[0][1] := 0;
  LMod.Matrix[1][1] := LInverse;
  LMod.Translate[1] := 0.5 - LHalf;
  CalcTransform(LMod, ANumVertexes, ATexCoords);
end;

procedure TQ3TexCoordCalc.CalcTurbulent(const AWave: TQ3WaveForm; const AShaderTime: Single;
  const ANumVertexes: Integer; const AXyz: TArray<Single>; var ATexCoords: TArray<Single>);
var
  LIndex, LTable: Integer;
  LNow, LS, LT, LSum, LTerm: Single;
  LPosition: Double;
  LSin: TQ3FuncTable;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireFloats(AXyz, ANumVertexes, 4, 'xyz');
  TQ3CMath.RequireFloats(ATexCoords, ANumVertexes, 2, 'texcoords');
  LSin := FTables.SinTable;
  LNow := AShaderTime * AWave.Frequency;
  LNow := AWave.Phase + LNow;
  for LIndex := 0 to ANumVertexes - 1 do
  begin
    LS := ATexCoords[LIndex * 2];
    LT := ATexCoords[LIndex * 2 + 1];
    // ( ( xyz[0] + xyz[2] ) * 1.0/128 * 0.125 + now ) * FUNCTABLE_SIZE: the constants are doubles
    LSum := AXyz[LIndex * 4] + AXyz[LIndex * 4 + 2];
    LPosition := Double(LSum) * 1.0 / 128 * 0.125 + Double(LNow);
    LPosition := LPosition * Q3_FUNCTABLE_SIZE;
    LTable := TQ3CMath.FloatToInt(LPosition) and Q3_FUNCTABLE_MASK;
    LTerm := LSin[LTable] * AWave.Amplitude;
    ATexCoords[LIndex * 2] := LS + LTerm;
    LPosition := Double(AXyz[LIndex * 4 + 1]) * 1.0 / 128 * 0.125 + Double(LNow);
    LPosition := LPosition * Q3_FUNCTABLE_SIZE;
    LTable := TQ3CMath.FloatToInt(LPosition) and Q3_FUNCTABLE_MASK;
    LTerm := LSin[LTable] * AWave.Amplitude;
    ATexCoords[LIndex * 2 + 1] := LT + LTerm;
  end;
end;

class procedure TQ3TexCoordCalc.CalcScale(const AScaleS, AScaleT: Single; const ANumVertexes: Integer;
  var ATexCoords: TArray<Single>);
var
  LIndex: Integer;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireFloats(ATexCoords, ANumVertexes, 2, 'texcoords');
  for LIndex := 0 to ANumVertexes - 1 do
  begin
    ATexCoords[LIndex * 2] := ATexCoords[LIndex * 2] * AScaleS;
    ATexCoords[LIndex * 2 + 1] := ATexCoords[LIndex * 2 + 1] * AScaleT;
  end;
end;

class procedure TQ3TexCoordCalc.CalcScroll(const ASpeedS, ASpeedT, AShaderTime: Single;
  const ANumVertexes: Integer; var ATexCoords: TArray<Single>);
var
  LIndex: Integer;
  LScrollS, LScrollT: Single;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireFloats(ATexCoords, ANumVertexes, 2, 'texcoords');
  LScrollS := ASpeedS * AShaderTime;
  LScrollT := ASpeedT * AShaderTime;
  // clamp so coordinates don't continuously get larger: float - floor( float ) is a double expression
  LScrollS := Double(LScrollS) - TQ3CMath.FloorValue(LScrollS);
  LScrollT := Double(LScrollT) - TQ3CMath.FloorValue(LScrollT);
  for LIndex := 0 to ANumVertexes - 1 do
  begin
    ATexCoords[LIndex * 2] := ATexCoords[LIndex * 2] + LScrollS;
    ATexCoords[LIndex * 2 + 1] := ATexCoords[LIndex * 2 + 1] + LScrollT;
  end;
end;

class procedure TQ3TexCoordCalc.CalcTransform(const AMod: TQ3TexMod; const ANumVertexes: Integer;
  var ATexCoords: TArray<Single>);
var
  LIndex: Integer;
  LS, LT, LFirst, LSecond, LResult: Single;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireFloats(ATexCoords, ANumVertexes, 2, 'texcoords');
  for LIndex := 0 to ANumVertexes - 1 do
  begin
    LS := ATexCoords[LIndex * 2];
    LT := ATexCoords[LIndex * 2 + 1];
    // s * m[0][0] + t * m[1][0] + translate[0]
    LFirst := LS * AMod.Matrix[0][0];
    LSecond := LT * AMod.Matrix[1][0];
    LResult := LFirst + LSecond;
    ATexCoords[LIndex * 2] := LResult + AMod.Translate[0];
    LFirst := LS * AMod.Matrix[0][1];
    LSecond := LT * AMod.Matrix[1][1];
    LResult := LFirst + LSecond;
    ATexCoords[LIndex * 2 + 1] := LResult + AMod.Translate[1];
  end;
end;

procedure TQ3TexCoordCalc.CalcRotate(const ADegreesPerSecond, AShaderTime: Single; const ANumVertexes: Integer;
  var ATexCoords: TArray<Single>);
var
  LDegrees, LFactor, LScaled, LSinValue, LCosValue: Single;
  LIndex: Integer;
  LMod: TQ3TexMod;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  LDegrees := -ADegreesPerSecond;
  LDegrees := LDegrees * AShaderTime;
  // FUNCTABLE_SIZE / 360.0f is an int divided by a float
  LFactor := Q3_FUNCTABLE_SIZE;
  LFactor := LFactor / 360.0;
  LScaled := LDegrees * LFactor;
  LIndex := TQ3CMath.FloatToInt(LScaled);
  LSinValue := FTables.SinTable[LIndex and Q3_FUNCTABLE_MASK];
  LCosValue := FTables.SinTable[(LIndex + Q3_FUNCTABLE_SIZE div 4) and Q3_FUNCTABLE_MASK];
  FillChar(LMod, SizeOf(LMod), 0);
  LMod.Matrix[0][0] := LCosValue;
  LMod.Matrix[1][0] := -LSinValue;
  // 0.5 - 0.5 * cosValue + 0.5 * sinValue: the 0.5 are doubles
  LMod.Translate[0] := 0.5 - 0.5 * Double(LCosValue) + 0.5 * Double(LSinValue);
  LMod.Matrix[0][1] := LSinValue;
  LMod.Matrix[1][1] := LCosValue;
  LMod.Translate[1] := 0.5 - 0.5 * Double(LSinValue) - 0.5 * Double(LCosValue);
  CalcTransform(LMod, ANumVertexes, ATexCoords);
end;

class procedure TQ3TexCoordCalc.CalcEnvironment(const ATess: TQ3ShaderTess; var ATexCoords: TArray<Single>);
var
  LIndex, LAxis: Integer;
  LViewer, LReflected: array[0..2] of Single;
  LViewerBuffer: TArray<Single>;
  LDot, LNormalTerm: Single;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireFloats(ATess.Xyz, ATess.NumVertexes, 4, 'xyz');
  TQ3CMath.RequireFloats(ATess.Normal, ATess.NumVertexes, 4, 'normal');
  TQ3CMath.RequireFloats(ATexCoords, ATess.NumVertexes, 2, 'texcoords');
  SetLength(LViewerBuffer, 3);
  for LIndex := 0 to ATess.NumVertexes - 1 do
  begin
    for LAxis := 0 to 2 do
      LViewerBuffer[LAxis] := ATess.ViewOrigin[LAxis] - ATess.Xyz[LIndex * 4 + LAxis];
    TQ3CMath.NormalizeFast(LViewerBuffer, 0);
    for LAxis := 0 to 2 do
      LViewer[LAxis] := LViewerBuffer[LAxis];
    // d = DotProduct( normal, viewer )
    LDot := ATess.Normal[LIndex * 4] * LViewer[0];
    LNormalTerm := ATess.Normal[LIndex * 4 + 1] * LViewer[1];
    LDot := LDot + LNormalTerm;
    LNormalTerm := ATess.Normal[LIndex * 4 + 2] * LViewer[2];
    LDot := LDot + LNormalTerm;
    // normal[0]*2*d - viewer[0]
    for LAxis := 0 to 2 do
    begin
      LNormalTerm := ATess.Normal[LIndex * 4 + LAxis] * 2;
      LNormalTerm := LNormalTerm * LDot;
      LReflected[LAxis] := LNormalTerm - LViewer[LAxis];
    end;
    ATexCoords[LIndex * 2] := 0.5 + Double(LReflected[1]) * 0.5;
    ATexCoords[LIndex * 2 + 1] := 0.5 - Double(LReflected[2]) * 0.5;
  end;
end;

procedure TQ3TexCoordCalc.Compute(const ABundle: TQ3TextureBundle; const ATess: TQ3ShaderTess;
  var ATexCoords: TArray<Single>);
var
  LIndex, LModIndex: Integer;
  LSum, LTerm: Single;
  LMod: TQ3TexMod;
begin
  TQ3CMath.RequireFloats(ATexCoords, ATess.NumVertexes, 2, 'texcoords');
  case ABundle.TcGen of
    tgIdentity:
      for LIndex := 0 to ATess.NumVertexes * 2 - 1 do
        ATexCoords[LIndex] := 0;
    tgTexture:
      begin
        TQ3CMath.RequireFloats(ATess.TexCoords, ATess.NumVertexes, 4, 'texCoords');
        for LIndex := 0 to ATess.NumVertexes - 1 do
        begin
          ATexCoords[LIndex * 2] := ATess.TexCoords[LIndex * 4];
          ATexCoords[LIndex * 2 + 1] := ATess.TexCoords[LIndex * 4 + 1];
        end;
      end;
    tgLightmap:
      begin
        TQ3CMath.RequireFloats(ATess.TexCoords, ATess.NumVertexes, 4, 'texCoords');
        for LIndex := 0 to ATess.NumVertexes - 1 do
        begin
          ATexCoords[LIndex * 2] := ATess.TexCoords[LIndex * 4 + 2];
          ATexCoords[LIndex * 2 + 1] := ATess.TexCoords[LIndex * 4 + 3];
        end;
      end;
    tgVector:
      begin
        TQ3CMath.RequireFloats(ATess.Xyz, ATess.NumVertexes, 4, 'xyz');
        for LIndex := 0 to ATess.NumVertexes - 1 do
          for LModIndex := 0 to 1 do
          begin
            // DotProduct( xyz, tcGenVectors[i] )
            LSum := ATess.Xyz[LIndex * 4] * ABundle.TcGenVectors[LModIndex][0];
            LTerm := ATess.Xyz[LIndex * 4 + 1] * ABundle.TcGenVectors[LModIndex][1];
            LSum := LSum + LTerm;
            LTerm := ATess.Xyz[LIndex * 4 + 2] * ABundle.TcGenVectors[LModIndex][2];
            ATexCoords[LIndex * 2 + LModIndex] := LSum + LTerm;
          end;
      end;
    tgFog:
      raise EDeclQ3ShaderCalcException.Create(SFogNotPorted);
    tgEnvironmentMapped:
      CalcEnvironment(ATess, ATexCoords);
  else
    // TCGEN_BAD
    Exit;
  end;
  for LModIndex := 0 to ABundle.NumTexMods - 1 do
  begin
    LMod := ABundle.TexMods[LModIndex];
    case LMod.ModType of
      tmNone:
        Break;
      tmTurbulent:
        CalcTurbulent(LMod.Wave, ATess.ShaderTime, ATess.NumVertexes, ATess.Xyz, ATexCoords);
      tmEntityTranslate:
        begin
          if not ATess.Entity.Present then
            raise EDeclQ3ShaderCalcException.Create(SNoEntity);
          CalcScroll(ATess.Entity.ShaderTexCoord[0], ATess.Entity.ShaderTexCoord[1], ATess.ShaderTime,
            ATess.NumVertexes, ATexCoords);
        end;
      tmScroll:
        CalcScroll(LMod.Scroll[0], LMod.Scroll[1], ATess.ShaderTime, ATess.NumVertexes, ATexCoords);
      tmScale:
        CalcScale(LMod.Scale[0], LMod.Scale[1], ATess.NumVertexes, ATexCoords);
      tmStretch:
        CalcStretch(LMod.Wave, ATess.ShaderTime, ATess.NumVertexes, ATexCoords);
      tmTransform:
        CalcTransform(LMod, ATess.NumVertexes, ATexCoords);
      tmRotate:
        CalcRotate(LMod.RotateSpeed, ATess.ShaderTime, ATess.NumVertexes, ATexCoords);
    end;
  end;
end;

end.
