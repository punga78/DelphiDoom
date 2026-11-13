{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - the set of calculations       }
{                                                                              }
{  The composition root of the calculations of renderer\tr_shade_calc.c of     }
{  Quake III Arena (id Software, GPL v2 or later): the tables, the noise and   }
{  the classes that read them. Based on the Quake III Arena GPL Source Code    }
{  (id Software).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.Kit;

interface

uses
  DelphiDoom.Decl.Q3Shader.Calc.FuncTables, DelphiDoom.Decl.Q3Shader.Calc.Noise,
  DelphiDoom.Decl.Q3Shader.Calc.WaveEvaluator, DelphiDoom.Decl.Q3Shader.Calc.ColorCalc,
  DelphiDoom.Decl.Q3Shader.Calc.TexCoordCalc, DelphiDoom.Decl.Q3Shader.Calc.DeformCalc;

type
  /// <summary>
  ///   The calculations of the shader time functions, made and wired together: it owns the function tables and
  ///   the noise (the <c>tr.sinTable</c> ... and <c>s_noise_table</c> of the original) and the classes that
  ///   use them. Two kits share nothing.
  /// </summary>
  TQ3ShaderCalc = class
  strict private
    FTables: TQ3FuncTables;
    FNoise: TQ3Noise;
    FWaves: TQ3WaveEvaluator;
    FColors: TQ3ColorCalc;
    FTexCoords: TQ3TexCoordCalc;
    FDeforms: TQ3DeformCalc;
  public
    constructor Create;
    destructor Destroy; override;
    property Tables: TQ3FuncTables read FTables;
    property Noise: TQ3Noise read FNoise;
    property Waves: TQ3WaveEvaluator read FWaves;
    property Colors: TQ3ColorCalc read FColors;
    property TexCoords: TQ3TexCoordCalc read FTexCoords;
    property Deforms: TQ3DeformCalc read FDeforms;
  end;

implementation

constructor TQ3ShaderCalc.Create;
begin
  inherited Create;
  FTables := TQ3FuncTables.Create;
  FNoise := TQ3Noise.Create;
  FWaves := TQ3WaveEvaluator.Create(FTables);
  FColors := TQ3ColorCalc.Create(FWaves, FNoise);
  FTexCoords := TQ3TexCoordCalc.Create(FWaves, FTables);
  FDeforms := TQ3DeformCalc.Create(FWaves, FTables, FNoise);
end;

destructor TQ3ShaderCalc.Destroy;
begin
  FDeforms.Free;
  FTexCoords.Free;
  FColors.Free;
  FWaves.Free;
  FNoise.Free;
  FTables.Free;
  inherited Destroy;
end;

end.
