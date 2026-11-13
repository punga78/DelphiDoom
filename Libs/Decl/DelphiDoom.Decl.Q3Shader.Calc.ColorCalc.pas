{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - vertex colors                 }
{                                                                              }
{  RB_CalcWaveColor, RB_CalcWaveAlpha and RB_CalcColorFromEntity,              }
{  RB_CalcColorFromOneMinusEntity, RB_CalcAlphaFromEntity,                     }
{  RB_CalcAlphaFromOneMinusEntity of renderer\tr_shade_calc.c of Quake III     }
{  Arena (id Software, GPL v2 or later). Based on the Quake III Arena GPL      }
{  Source Code (id Software).                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.ColorCalc;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Calc.Types,
  DelphiDoom.Decl.Q3Shader.Calc.WaveEvaluator, DelphiDoom.Decl.Q3Shader.Calc.Noise;

type
  /// <summary>
  ///   The colors a stage takes from a waveform or from the entity. A color buffer is four bytes per vertex
  ///   (<c>color4ub_t</c>: red, green, blue, alpha).
  /// </summary>
  TQ3ColorCalc = class
  strict private
    FWaves: TQ3WaveEvaluator;
    FNoise: TQ3Noise;
  public
    /// <summary>The evaluator and the noise are not owned</summary>
    constructor Create(const AWaves: TQ3WaveEvaluator; const ANoise: TQ3Noise);
    /// <summary>
    ///   RB_CalcWaveColor: the same gray in every vertex, alpha 255. The noise function reads the noise; the
    ///   other ones the table and <c>tr.identityLight</c> (<c>AIdentityLight</c>).
    /// </summary>
    procedure CalcWaveColor(const AWave: TQ3WaveForm; const AShaderTime, AIdentityLight: Single;
      const ANumVertexes: Integer; var AColors: TBytes);
    /// <summary>RB_CalcWaveAlpha: the alpha byte of every vertex, the other bytes are not touched</summary>
    procedure CalcWaveAlpha(const AWave: TQ3WaveForm; const AShaderTime: Single; const ANumVertexes: Integer;
      var AColors: TBytes);
    /// <summary>RB_CalcColorFromEntity: <c>shaderRGBA</c> in every vertex; nothing without an entity</summary>
    class procedure CalcColorFromEntity(const AEntity: TQ3EntityShading; const ANumVertexes: Integer;
      var AColors: TBytes); static;
    /// <summary>
    ///   RB_CalcColorFromOneMinusEntity: 255 minus each byte, alpha included. The original writes
    ///   <c>invModulate[3]</c> of an array of three bytes: the alpha it copies is undefined (the comment says
    ///   the alpha block fixes it); here it is <c>255 - shaderRGBA[3]</c>.
    /// </summary>
    class procedure CalcColorFromOneMinusEntity(const AEntity: TQ3EntityShading; const ANumVertexes: Integer;
      var AColors: TBytes); static;
    /// <summary>RB_CalcAlphaFromEntity</summary>
    class procedure CalcAlphaFromEntity(const AEntity: TQ3EntityShading; const ANumVertexes: Integer;
      var AColors: TBytes); static;
    /// <summary>RB_CalcAlphaFromOneMinusEntity</summary>
    class procedure CalcAlphaFromOneMinusEntity(const AEntity: TQ3EntityShading; const ANumVertexes: Integer;
      var AColors: TBytes); static;
  end;

implementation

uses
  System.Math, DelphiDoom.Decl.Q3Shader.Calc.FloatMask;

constructor TQ3ColorCalc.Create(const AWaves: TQ3WaveEvaluator; const ANoise: TQ3Noise);
begin
  inherited Create;
  FWaves := AWaves;
  FNoise := ANoise;
end;

procedure TQ3ColorCalc.CalcWaveColor(const AWave: TQ3WaveForm; const AShaderTime, AIdentityLight: Single;
  const ANumVertexes: Integer; var AColors: TBytes);
var
  LGlow, LTime, LNoise: Single;
  LValue, LIndex: Integer;
  LByte: Byte;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireBytes(AColors, ANumVertexes);
  if AWave.Func = gfNoise then
  begin
    LTime := AShaderTime + AWave.Phase;
    LTime := LTime * AWave.Frequency;
    LNoise := FNoise.Get4f(0, 0, 0, LTime);
    LNoise := LNoise * AWave.Amplitude;
    LGlow := AWave.Base + LNoise;
  end
  else
  begin
    LGlow := FWaves.EvalWaveForm(AWave, AShaderTime);
    LGlow := LGlow * AIdentityLight;
  end;
  if not IsNan(LGlow) then
  begin
    if LGlow < 0 then
      LGlow := 0
    else if LGlow > 1 then
      LGlow := 1;
  end;
  LGlow := LGlow * 255;
  LValue := TQ3CMath.FloatToInt(LGlow);
  LByte := Byte(LValue and $FF);
  for LIndex := 0 to ANumVertexes - 1 do
  begin
    AColors[LIndex * 4] := LByte;
    AColors[LIndex * 4 + 1] := LByte;
    AColors[LIndex * 4 + 2] := LByte;
    AColors[LIndex * 4 + 3] := 255;
  end;
end;

procedure TQ3ColorCalc.CalcWaveAlpha(const AWave: TQ3WaveForm; const AShaderTime: Single;
  const ANumVertexes: Integer; var AColors: TBytes);
var
  LGlow: Single;
  LByte: Byte;
  LIndex: Integer;
  LMask: IInterface;
begin
  LMask := TQ3FloatMask.Enter;
  TQ3CMath.RequireBytes(AColors, ANumVertexes);
  LGlow := FWaves.EvalWaveFormClamped(AWave, AShaderTime);
  LGlow := 255 * LGlow;
  LByte := Byte(TQ3CMath.FloatToInt(LGlow) and $FF);
  for LIndex := 0 to ANumVertexes - 1 do
    AColors[LIndex * 4 + 3] := LByte;
end;

class procedure TQ3ColorCalc.CalcColorFromEntity(const AEntity: TQ3EntityShading; const ANumVertexes: Integer;
  var AColors: TBytes);
var
  LIndex, LByte: Integer;
begin
  if not AEntity.Present then
    Exit;
  TQ3CMath.RequireBytes(AColors, ANumVertexes);
  for LIndex := 0 to ANumVertexes - 1 do
    for LByte := 0 to 3 do
      AColors[LIndex * 4 + LByte] := AEntity.ShaderRGBA[LByte];
end;

class procedure TQ3ColorCalc.CalcColorFromOneMinusEntity(const AEntity: TQ3EntityShading;
  const ANumVertexes: Integer; var AColors: TBytes);
var
  LIndex, LByte: Integer;
begin
  if not AEntity.Present then
    Exit;
  TQ3CMath.RequireBytes(AColors, ANumVertexes);
  for LIndex := 0 to ANumVertexes - 1 do
    for LByte := 0 to 3 do
      AColors[LIndex * 4 + LByte] := 255 - AEntity.ShaderRGBA[LByte];
end;

class procedure TQ3ColorCalc.CalcAlphaFromEntity(const AEntity: TQ3EntityShading; const ANumVertexes: Integer;
  var AColors: TBytes);
var
  LIndex: Integer;
begin
  if not AEntity.Present then
    Exit;
  TQ3CMath.RequireBytes(AColors, ANumVertexes);
  for LIndex := 0 to ANumVertexes - 1 do
    AColors[LIndex * 4 + 3] := AEntity.ShaderRGBA[3];
end;

class procedure TQ3ColorCalc.CalcAlphaFromOneMinusEntity(const AEntity: TQ3EntityShading;
  const ANumVertexes: Integer; var AColors: TBytes);
var
  LIndex: Integer;
begin
  if not AEntity.Present then
    Exit;
  TQ3CMath.RequireBytes(AColors, ANumVertexes);
  for LIndex := 0 to ANumVertexes - 1 do
    AColors[LIndex * 4 + 3] := 255 - AEntity.ShaderRGBA[3];
end;

end.
