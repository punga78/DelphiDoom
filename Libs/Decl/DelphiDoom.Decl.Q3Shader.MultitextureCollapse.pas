{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - two stages joined into a multitexture one   }
{                                                                              }
{  Port of CollapseMultitexture of renderer\tr_shader.c. Based on the Quake    }
{  III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id         }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.MultitextureCollapse;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Decl.Q3Shader.Types;

type
  /// <summary>
  ///   Attempts to combine the first two stages into a single multitexture stage: the blend modes must be one
  ///   of the pairs of the table of the original (modulate, add), everything else of the state, the colour and
  ///   alpha generation must be the same, and waveforms must have identical parameters. The second image goes
  ///   in the second bundle (the lightmap always in the second one: the stages swap), the blend bits of the
  ///   table replace those of the first stage and the later stages move down one place.
  /// </summary>
  TQ3ShaderMultitextureCollapse = class sealed
  public
    /// <summary>CollapseMultitexture: True if the stages were joined</summary>
    class function Apply(var AData: TQ3ShaderData; const AOptions: TQ3ShaderOptions): Boolean; static;
  end;

implementation

type
  /// <summary>collapse_t</summary>
  TCollapseRule = record
    BlendA: Cardinal;
    BlendB: Cardinal;
    Env: TQ3MultitextureEnv;
    Blend: Cardinal;
  end;

const
  // the rows of collapse[] (the GL_DECAL row of the original is under #if 0)
  COLLAPSE_COUNT = 8;
  FILTER = GLS_DSTBLEND_ZERO or GLS_SRCBLEND_DST_COLOR;
  MODULATE_BLEND = GLS_DSTBLEND_SRC_COLOR or GLS_SRCBLEND_ZERO;
  ADD_BLEND = GLS_DSTBLEND_ONE or GLS_SRCBLEND_ONE;
  COLLAPSE: array[0..COLLAPSE_COUNT - 1] of TCollapseRule = (
    (BlendA: 0; BlendB: MODULATE_BLEND; Env: meModulate; Blend: 0),
    (BlendA: 0; BlendB: FILTER; Env: meModulate; Blend: 0),
    (BlendA: FILTER; BlendB: FILTER; Env: meModulate; Blend: FILTER),
    (BlendA: MODULATE_BLEND; BlendB: FILTER; Env: meModulate; Blend: FILTER),
    (BlendA: FILTER; BlendB: MODULATE_BLEND; Env: meModulate; Blend: FILTER),
    (BlendA: MODULATE_BLEND; BlendB: MODULATE_BLEND; Env: meModulate; Blend: FILTER),
    (BlendA: 0; BlendB: ADD_BLEND; Env: meAdd; Blend: 0),
    (BlendA: ADD_BLEND; BlendB: ADD_BLEND; Env: meAdd; Blend: ADD_BLEND));

/// <summary>memcmp of two waveForm_t: the float bits, so that -0 and 0 differ and a NaN equals itself</summary>
function SameWave(const ALeft, ARight: TQ3WaveForm): Boolean;
begin
  Result := (ALeft.Func = ARight.Func) and (PCardinal(@ALeft.Base)^ = PCardinal(@ARight.Base)^) and
    (PCardinal(@ALeft.Amplitude)^ = PCardinal(@ARight.Amplitude)^) and
    (PCardinal(@ALeft.Phase)^ = PCardinal(@ARight.Phase)^) and
    (PCardinal(@ALeft.Frequency)^ = PCardinal(@ARight.Frequency)^);
end;

{ TQ3ShaderMultitextureCollapse }

class function TQ3ShaderMultitextureCollapse.Apply(var AData: TQ3ShaderData;
  const AOptions: TQ3ShaderOptions): Boolean;
var
  LBits, LBlendA, LBlendB: Cardinal;
  LRule, LIndex: Integer;
  LTemp: TQ3TextureBundle;
begin
  Result := False;
  if not AOptions.MultitextureAvailable then
    Exit;

  // make sure both stages are active
  if (not AData.Stages[0].Active) or (not AData.Stages[1].Active) then
    Exit;

  // make sure that both stages have identical state other than blend modes
  LBits := Cardinal(not (GLS_DSTBLEND_BITS or GLS_SRCBLEND_BITS or GLS_DEPTHMASK_TRUE));
  if (AData.Stages[0].StateBits and LBits) <> (AData.Stages[1].StateBits and LBits) then
    Exit;

  LBlendA := AData.Stages[0].StateBits and (GLS_DSTBLEND_BITS or GLS_SRCBLEND_BITS);
  LBlendB := AData.Stages[1].StateBits and (GLS_DSTBLEND_BITS or GLS_SRCBLEND_BITS);

  // search for a valid multitexture blend function
  LRule := -1;
  for LIndex := 0 to COLLAPSE_COUNT - 1 do
    if (LBlendA = COLLAPSE[LIndex].BlendA) and (LBlendB = COLLAPSE[LIndex].BlendB) then
    begin
      LRule := LIndex;
      Break;
    end;
  // nothing found
  if LRule < 0 then
    Exit;

  // GL_ADD is a separate extension
  if (COLLAPSE[LRule].Env = meAdd) and (not AOptions.TextureEnvAddAvailable) then
    Exit;

  // make sure waveforms have identical parameters
  if (AData.Stages[0].RgbGen <> AData.Stages[1].RgbGen) or (AData.Stages[0].AlphaGen <> AData.Stages[1].AlphaGen) then
    Exit;

  // an add collapse can only have identity colors
  if (COLLAPSE[LRule].Env = meAdd) and (AData.Stages[0].RgbGen <> cgIdentity) then
    Exit;

  if AData.Stages[0].RgbGen = cgWaveform then
    if not SameWave(AData.Stages[0].RgbWave, AData.Stages[1].RgbWave) then
      Exit;
  // the original compares the alpha generation with CGEN_WAVEFORM (8, a colour generation): for an alpha
  // generation that is AGEN_PORTAL, and the alpha waveform of an AGEN_WAVEFORM stage is never compared
  if Ord(AData.Stages[0].AlphaGen) = Ord(cgWaveform) then
    if not SameWave(AData.Stages[0].AlphaWave, AData.Stages[1].AlphaWave) then
      Exit;

  // make sure that lightmaps are in bundle 1 for 3dfx
  if AData.Stages[0].Bundle.IsLightmap then
  begin
    LTemp := AData.Stages[0].Bundle;
    AData.Stages[0].Bundle := AData.Stages[1].Bundle;
    AData.Stages[0].Bundle2 := LTemp;
  end
  else
    AData.Stages[0].Bundle2 := AData.Stages[1].Bundle;

  // set the new blend state bits
  AData.MultitextureEnv := COLLAPSE[LRule].Env;
  AData.Stages[0].StateBits := (AData.Stages[0].StateBits and Cardinal(not (GLS_DSTBLEND_BITS or GLS_SRCBLEND_BITS))) or
    COLLAPSE[LRule].Blend;

  // move down subsequent shaders
  for LIndex := 1 to Q3_MAX_SHADER_STAGES - 2 do
    AData.Stages[LIndex] := AData.Stages[LIndex + 1];
  AData.Stages[Q3_MAX_SHADER_STAGES - 1] := Default(TQ3ShaderStage);

  Result := True;
end;

end.
