{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - the finishing of a shader (the data)        }
{                                                                              }
{  Port of the part of FinishShader of renderer\tr_shader.c that decides data: }
{  sort order, default texture coordinate generation, fog color adjustment,    }
{  stages without image, detail stages, the number of passes. Quake III Arena  }
{  (id Software, GPL v2 or later). Based on the Quake III Arena GPL Source     }
{  Code (id Software).                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Finisher;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Context;

type
  /// <summary>
  ///   FinishShader without what is the renderer's: the <c>VertexLightingCollapse</c> (cvar <c>r_vertexLight</c>),
  ///   <c>CollapseMultitexture</c> (needs the multitexture extension of the video card), the stage iterator
  ///   function, <c>GeneratePermanentShader</c> without the fog pass (the tables of the renderer, the sorted
  ///   list), the lightmap index of the surface
  /// </summary>
  TQ3ShaderFinisher = class sealed
  public
    class procedure FinishShader(const AContext: TQ3ShaderContext); static;
  end;

implementation

{ TQ3ShaderFinisher }

class procedure TQ3ShaderFinisher.FinishShader(const AContext: TQ3ShaderContext);
var
  LData: PQ3ShaderData;
  LStage: Integer;
  LIndex: Integer;
  LStageData: PQ3ShaderStage;
  LBlendSrcBits, LBlendDstBits: Cardinal;
begin
  LData := AContext.Data;

  // set sky stuff appropriate
  if LData.IsSky then
    LData.Sort := SS_ENVIRONMENT;
  // set polygon offset
  if LData.PolygonOffset and (LData.Sort = 0) then
    LData.Sort := SS_DECAL;

  // set appropriate stage information; the index stays after the loop (it is the number of passes)
  LStage := 0;
  while LStage < Q3_MAX_SHADER_STAGES do
  begin
    LStageData := @LData.Stages[LStage];
    if not LStageData.Active then
      Break;

    // check for a missing texture
    if LStageData.Bundle.ImageNames[0] = '' then
    begin
      AContext.Warn('Shader %s has a stage with no image', [LData.Name]);
      LStageData.Active := False;
      Inc(LStage);
      Continue;
    end;

    // ditch this stage if it's detail and detail textures are disabled. The original moves the next stages
    // down by one and then clears the stage after the one it is on (not the last one): kept
    if LStageData.IsDetail and (not AContext.Options.DetailTextures) then
    begin
      if LStage < Q3_MAX_SHADER_STAGES - 1 then
      begin
        for LIndex := LStage to Q3_MAX_SHADER_STAGES - 2 do
          LData.Stages[LIndex] := LData.Stages[LIndex + 1];
        LData.Stages[LStage + 1] := Default(TQ3ShaderStage);
      end;
      Inc(LStage);
      Continue;
    end;

    // default texture coordinate generation
    if LStageData.Bundle.IsLightmap then
    begin
      if LStageData.Bundle.TcGen = tgBad then
        LStageData.Bundle.TcGen := tgLightmap;
    end
    else
    begin
      if LStageData.Bundle.TcGen = tgBad then
        LStageData.Bundle.TcGen := tgTexture;
    end;

    // determine sort order and fog color adjustment
    if ((LStageData.StateBits and (GLS_SRCBLEND_BITS or GLS_DSTBLEND_BITS)) <> 0) and
      ((LData.Stages[0].StateBits and (GLS_SRCBLEND_BITS or GLS_DSTBLEND_BITS)) <> 0) then
    begin
      LBlendSrcBits := LStageData.StateBits and GLS_SRCBLEND_BITS;
      LBlendDstBits := LStageData.StateBits and GLS_DSTBLEND_BITS;
      // modulate, additive
      if ((LBlendSrcBits = GLS_SRCBLEND_ONE) and (LBlendDstBits = GLS_DSTBLEND_ONE)) or
        ((LBlendSrcBits = GLS_SRCBLEND_ZERO) and (LBlendDstBits = GLS_DSTBLEND_ONE_MINUS_SRC_COLOR)) then
        LStageData.AdjustColorsForFog := acModulateRgb
      // strict blend
      else if (LBlendSrcBits = GLS_SRCBLEND_SRC_ALPHA) and (LBlendDstBits = GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA) then
        LStageData.AdjustColorsForFog := acModulateAlpha
      // premultiplied alpha
      else if (LBlendSrcBits = GLS_SRCBLEND_ONE) and (LBlendDstBits = GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA) then
        LStageData.AdjustColorsForFog := acModulateRgba;
      // don't screw with sort order if this is a portal or environment
      if LData.Sort = 0 then
      begin
        // see through item, like a grill or grate
        if (LStageData.StateBits and GLS_DEPTHMASK_TRUE) <> 0 then
          LData.Sort := SS_SEE_THROUGH
        else
          LData.Sort := SS_BLEND0;
      end;
    end;
    Inc(LStage);
  end;

  // there are times when you will need to manually apply a sort to
  // opaque alpha tested shaders that have later blend passes
  if LData.Sort = 0 then
    LData.Sort := SS_OPAQUE;

  // compute number of passes
  LData.NumUnfoggedPasses := LStage;
  // fogonly shaders don't have any normal passes
  if LStage = 0 then
    LData.Sort := SS_FOG;

  // GeneratePermanentShader: the fog pass follows from the final sort
  if LData.Sort <= SS_OPAQUE then
    LData.FogPass := fpEqual
  else if (LData.ContentFlags and CONTENTS_FOG) <> 0 then
    LData.FogPass := fpLE;
end;

end.
