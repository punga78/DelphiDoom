{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - the single pass of the vertex light mode    }
{                                                                              }
{  Port of VertexLightingCollapse of renderer\tr_shader.c. Based on the        }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.VertexLightCollapse;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Decl.Q3Shader.Types;

type
  /// <summary>
  ///   With vertex lighting on an opaque shader is drawn with a single pass: the stage whose bundle ranks best
  ///   (a lightmap loses 100 points; a texture generation other than texture, a texture modifier and a colour
  ///   generation other than identity cost less) takes the first place with the vertex or diffuse lighting
  ///   colour; a shader that is not opaque keeps its first pass, without a lightmap. The other stages are cleared.
  /// </summary>
  TQ3ShaderVertexLightCollapse = class sealed
  public
    class procedure Apply(var AData: TQ3ShaderData); static;
  end;

implementation

const
  /// <summary>The rank that no stage can have: the first stage ranked wins (bestImageRank)</summary>
  WORST_RANK = -999999;

{ TQ3ShaderVertexLightCollapse }

class procedure TQ3ShaderVertexLightCollapse.Apply(var AData: TQ3ShaderData);
var
  LStage, LBest, LRank, LBestRank: Integer;
begin
  // if we aren't opaque, just use the first pass
  if AData.Sort = SS_OPAQUE then
  begin
    // pick the best texture for the single pass
    LBest := 0;
    LBestRank := WORST_RANK;
    for LStage := 0 to Q3_MAX_SHADER_STAGES - 1 do
    begin
      if not AData.Stages[LStage].Active then
        Break;
      LRank := 0;
      if AData.Stages[LStage].Bundle.IsLightmap then
        Dec(LRank, 100);
      if AData.Stages[LStage].Bundle.TcGen <> tgTexture then
        Dec(LRank, 5);
      if AData.Stages[LStage].Bundle.NumTexMods <> 0 then
        Dec(LRank, 5);
      if (AData.Stages[LStage].RgbGen <> cgIdentity) and (AData.Stages[LStage].RgbGen <> cgIdentityLighting) then
        Dec(LRank, 3);
      if LRank > LBestRank then
      begin
        LBestRank := LRank;
        LBest := LStage;
      end;
    end;

    AData.Stages[0].Bundle := AData.Stages[LBest].Bundle;
    AData.Stages[0].StateBits := (AData.Stages[0].StateBits and Cardinal(not (GLS_DSTBLEND_BITS or GLS_SRCBLEND_BITS))) or
      GLS_DEPTHMASK_TRUE;
    if AData.LightmapIndex = -1 then
      AData.Stages[0].RgbGen := cgLightingDiffuse
    else
      AData.Stages[0].RgbGen := cgExactVertex;
    AData.Stages[0].AlphaGen := agSkip;
  end
  else
  begin
    // don't use a lightmap (tesla coils)
    if AData.Stages[0].Bundle.IsLightmap then
      AData.Stages[0] := AData.Stages[1];

    // if we were in a cross-fade cgen, hack it to normal
    if (AData.Stages[0].RgbGen = cgOneMinusEntity) or (AData.Stages[1].RgbGen = cgOneMinusEntity) then
      AData.Stages[0].RgbGen := cgIdentityLighting;
    if ((AData.Stages[0].RgbGen = cgWaveform) and (AData.Stages[0].RgbWave.Func = gfSawtooth)) and
      ((AData.Stages[1].RgbGen = cgWaveform) and (AData.Stages[1].RgbWave.Func = gfInverseSawtooth)) then
      AData.Stages[0].RgbGen := cgIdentityLighting;
    if ((AData.Stages[0].RgbGen = cgWaveform) and (AData.Stages[0].RgbWave.Func = gfInverseSawtooth)) and
      ((AData.Stages[1].RgbGen = cgWaveform) and (AData.Stages[1].RgbWave.Func = gfSawtooth)) then
      AData.Stages[0].RgbGen := cgIdentityLighting;
  end;

  for LStage := 1 to Q3_MAX_SHADER_STAGES - 1 do
  begin
    if not AData.Stages[LStage].Active then
      Break;
    AData.Stages[LStage] := Default(TQ3ShaderStage);
  end;
end;

end.
