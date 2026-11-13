{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - waveforms                     }
{                                                                              }
{  WAVEVALUE, EvalWaveForm and EvalWaveFormClamped of renderer\                }
{  tr_shade_calc.c of Quake III Arena (id Software, GPL v2 or later). Based    }
{  on the Quake III Arena GPL Source Code (id Software).                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.WaveEvaluator;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Calc.Types, DelphiDoom.Decl.Q3Shader.Calc.FuncTables;

type
  /// <summary>
  ///   The value of a waveform at a time. The time is an argument (the original reads
  ///   <c>tess.shaderTime</c>); every operation is rounded to a float, as the SSE code of the original.
  /// </summary>
  TQ3WaveEvaluator = class
  strict private
    FTables: TQ3FuncTables;
  public
    /// <summary>The tables are not owned: the caller keeps them alive</summary>
    constructor Create(const ATables: TQ3FuncTables);
    /// <summary>
    ///   WAVEVALUE: <c>base + table[ myftol( ( phase + shaderTime * freq ) * FUNCTABLE_SIZE ) &amp; MASK ] * amp</c>.
    ///   It does not mask the FPU exceptions (it is called for every vertex): the caller holds a
    ///   <c>TQ3FloatMask</c>, as <c>EvalWaveForm</c> and the deformations do.
    /// </summary>
    function WaveValue(const ATable: TQ3FuncTable; const ABase, AAmplitude, APhase, AFrequency,
      AShaderTime: Single): Single;
    /// <summary>
    ///   EvalWaveForm: raises <c>EDeclQ3ShaderCalcException</c> for a function without a table (none, noise)
    /// </summary>
    function EvalWaveForm(const AWave: TQ3WaveForm; const AShaderTime: Single): Single;
    /// <summary>EvalWaveFormClamped: the same, limited to 0..1</summary>
    function EvalWaveFormClamped(const AWave: TQ3WaveForm; const AShaderTime: Single): Single;
    property Tables: TQ3FuncTables read FTables;
  end;

implementation

uses
  System.Math, DelphiDoom.Decl.Q3Shader.Calc.FloatMask;

constructor TQ3WaveEvaluator.Create(const ATables: TQ3FuncTables);
begin
  inherited Create;
  FTables := ATables;
end;

function TQ3WaveEvaluator.WaveValue(const ATable: TQ3FuncTable; const ABase, AAmplitude, APhase, AFrequency,
  AShaderTime: Single): Single;
var
  LPosition, LValue: Single;
begin
  LPosition := AShaderTime * AFrequency;
  LPosition := APhase + LPosition;
  LPosition := LPosition * Q3_FUNCTABLE_SIZE;
  LValue := ATable[TQ3CMath.FloatToInt(LPosition) and Q3_FUNCTABLE_MASK];
  LValue := LValue * AAmplitude;
  Result := ABase + LValue;
end;

function TQ3WaveEvaluator.EvalWaveForm(const AWave: TQ3WaveForm; const AShaderTime: Single): Single;
var
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  Result := WaveValue(FTables.TableFor(AWave.Func), AWave.Base, AWave.Amplitude, AWave.Phase, AWave.Frequency,
    AShaderTime);
end;

function TQ3WaveEvaluator.EvalWaveFormClamped(const AWave: TQ3WaveForm; const AShaderTime: Single): Single;
var
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  Result := EvalWaveForm(AWave, AShaderTime);
  if IsNan(Result) then
    Exit;
  if Result < 0 then
    Result := 0
  else if Result > 1 then
    Result := 1;
end;

end.
