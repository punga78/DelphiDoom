{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - a stage                                     }
{                                                                              }
{  Port of ParseStage of renderer\tr_shader.c of Quake III Arena (id           }
{  Software, GPL v2 or later). Based on the Quake III Arena GPL Source Code    }
{  (id Software). The images are named, not loaded.                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.StageParser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Context,
  DelphiDoom.Decl.Q3Shader.Tokenizer;

type
  /// <summary>The body of a stage, from after its "{" to its "}"</summary>
  TQ3ShaderStageParser = class sealed
  strict private
    class function SameWord(const AWord, AKeyword: AnsiString): Boolean; static; inline;
  public
    /// <summary>
    ///   ParseStage: false with a warning if the stage has an error (the stage keeps what was read). The
    ///   stage is made active before the first word, as in the original.
    /// </summary>
    class function ParseStage(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer;
      const AStage: PQ3ShaderStage): Boolean; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Decl.Q3Shader.Names,
  DelphiDoom.Decl.Q3Shader.ValueParser, DelphiDoom.Decl.Q3Shader.TexModParser;

const
  SNoMatchingBrace = 'no matching ''}'' found';
  SMissingMapParameter = 'missing parameter for ''%s'' keyword in shader ''%s''';
  SUnknownParameter = 'unknown parameter ''%s'' in shader ''%s''';

{ TQ3ShaderStageParser }

class function TQ3ShaderStageParser.SameWord(const AWord, AKeyword: AnsiString): Boolean;
begin
  Result := TIdStrings.Icmp(AWord, AKeyword) = 0;
end;

class function TQ3ShaderStageParser.ParseStage(const AContext: TQ3ShaderContext;
  const ATokenizer: TQ3ShaderTokenizer; const AStage: PQ3ShaderStage): Boolean;
var
  LToken, LBuffer: AnsiString;
  LDepthMaskBits, LBlendSrcBits, LBlendDstBits, LAlphaTestBits, LDepthFuncBits: Cardinal;
  LDepthMaskExplicit: Boolean;
  LColor: array[0..2] of Single;
  LName: AnsiString;
  LNumber: Integer;
  LImageIndex: Integer;

  // the word after a keyword; an empty one is the warning of the keyword and the end of the stage
  function ParameterOrFail(const AKeyword: AnsiString; out AParameter: AnsiString): Boolean;
  begin
    AParameter := ATokenizer.ParseExt(False);
    Result := AParameter <> '';
    if not Result then
      AContext.Warn(SMissingMapParameter, [AKeyword, LName]);
  end;

begin
  LName := AContext.Data.Name;
  LDepthMaskBits := GLS_DEPTHMASK_TRUE;
  LBlendSrcBits := 0;
  LBlendDstBits := 0;
  LAlphaTestBits := 0;
  LDepthFuncBits := 0;
  LDepthMaskExplicit := False;
  AStage.Active := True;
  while True do
  begin
    LToken := ATokenizer.ParseExt(True);
    if LToken = '' then
    begin
      AContext.Warn(SNoMatchingBrace, []);
      Exit(False);
    end;
    if LToken[1] = '}' then
      Break
    else if SameWord(LToken, 'map') then
    begin
      if not ParameterOrFail('map', LToken) then
        Exit(False);
      if SameWord(LToken, '$whiteimage') then
      begin
        AStage.Bundle.ImageNames[0] := '$whiteimage';
        Continue;
      end
      else if SameWord(LToken, '$lightmap') then
      begin
        AStage.Bundle.IsLightmap := True;
        AStage.Bundle.ImageNames[0] := '$lightmap';
        Continue;
      end
      else
        AStage.Bundle.ImageNames[0] := LToken;
    end
    else if SameWord(LToken, 'clampmap') then
    begin
      if not ParameterOrFail('clampmap', LToken) then
        Exit(False);
      AStage.Bundle.ImageNames[0] := LToken;
    end
    else if SameWord(LToken, 'animMap') then
    begin
      // the original writes "animMmap" in this message
      if not ParameterOrFail('animMmap', LToken) then
        Exit(False);
      AStage.Bundle.ImageAnimationSpeed := TIdCNumbers.Atof(LToken);
      // up to MAX_IMAGE_ANIMATIONS images; the others are read and dropped
      while True do
      begin
        LToken := ATokenizer.ParseExt(False);
        if LToken = '' then
          Break;
        LImageIndex := AStage.Bundle.NumImageAnimations;
        if LImageIndex < Q3_MAX_IMAGE_ANIMATIONS then
        begin
          AStage.Bundle.ImageNames[LImageIndex] := LToken;
          Inc(AStage.Bundle.NumImageAnimations);
        end;
      end;
    end
    else if SameWord(LToken, 'videoMap') then
    begin
      // the original writes "videoMmap" in this message
      if not ParameterOrFail('videoMmap', LToken) then
        Exit(False);
      AStage.Bundle.IsVideoMap := True;
      AStage.Bundle.VideoMapName := LToken;
      AStage.Bundle.ImageNames[0] := '$scratch';
    end
    else if SameWord(LToken, 'alphaFunc') then
    begin
      if not ParameterOrFail('alphaFunc', LToken) then
        Exit(False);
      LAlphaTestBits := TQ3ShaderNames.AlphaFunc(AContext, LToken);
    end
    else if SameWord(LToken, 'depthfunc') then
    begin
      if not ParameterOrFail('depthfunc', LToken) then
        Exit(False);
      if SameWord(LToken, 'lequal') then
        LDepthFuncBits := 0
      else if SameWord(LToken, 'equal') then
        LDepthFuncBits := GLS_DEPTHFUNC_EQUAL
      else
      begin
        AContext.Warn('unknown depthfunc ''%s'' in shader ''%s''', [LToken, LName]);
        Continue;
      end;
    end
    else if SameWord(LToken, 'detail') then
      AStage.IsDetail := True
    else if SameWord(LToken, 'blendfunc') then
    begin
      LToken := ATokenizer.ParseExt(False);
      if LToken = '' then
      begin
        AContext.Warn('missing parm for blendFunc in shader ''%s''', [LName]);
        Continue;
      end;
      // check for "simple" blends first
      if SameWord(LToken, 'add') then
      begin
        LBlendSrcBits := GLS_SRCBLEND_ONE;
        LBlendDstBits := GLS_DSTBLEND_ONE;
      end
      else if SameWord(LToken, 'filter') then
      begin
        LBlendSrcBits := GLS_SRCBLEND_DST_COLOR;
        LBlendDstBits := GLS_DSTBLEND_ZERO;
      end
      else if SameWord(LToken, 'blend') then
      begin
        LBlendSrcBits := GLS_SRCBLEND_SRC_ALPHA;
        LBlendDstBits := GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA;
      end
      else
      begin
        // complex double blends
        LBlendSrcBits := TQ3ShaderNames.SourceBlendMode(AContext, LToken);
        LToken := ATokenizer.ParseExt(False);
        if LToken = '' then
        begin
          AContext.Warn('missing parm for blendFunc in shader ''%s''', [LName]);
          Continue;
        end;
        LBlendDstBits := TQ3ShaderNames.DestinationBlendMode(AContext, LToken);
      end;
      // clear depth mask for blended surfaces
      if not LDepthMaskExplicit then
        LDepthMaskBits := 0;
    end
    else if SameWord(LToken, 'rgbGen') then
    begin
      LToken := ATokenizer.ParseExt(False);
      if LToken = '' then
      begin
        AContext.Warn('missing parameters for rgbGen in shader ''%s''', [LName]);
        Continue;
      end;
      if SameWord(LToken, 'wave') then
      begin
        TQ3ShaderValueParser.ParseWaveForm(AContext, ATokenizer, AStage.RgbWave);
        AStage.RgbGen := cgWaveform;
      end
      else if SameWord(LToken, 'const') then
      begin
        // the original leaves the color uninitialized if the vector is wrong: here it is zero
        LColor[0] := 0;
        LColor[1] := 0;
        LColor[2] := 0;
        TQ3ShaderValueParser.ParseVector(AContext, ATokenizer, 3, LColor);
        AStage.ConstantColor[0] := TQ3ShaderContext.FloatToByte(Single(255 * LColor[0]));
        AStage.ConstantColor[1] := TQ3ShaderContext.FloatToByte(Single(255 * LColor[1]));
        AStage.ConstantColor[2] := TQ3ShaderContext.FloatToByte(Single(255 * LColor[2]));
        AStage.RgbGen := cgConst;
      end
      else if SameWord(LToken, 'identity') then
        AStage.RgbGen := cgIdentity
      else if SameWord(LToken, 'identityLighting') then
        AStage.RgbGen := cgIdentityLighting
      else if SameWord(LToken, 'entity') then
        AStage.RgbGen := cgEntity
      else if SameWord(LToken, 'oneMinusEntity') then
        AStage.RgbGen := cgOneMinusEntity
      else if SameWord(LToken, 'vertex') then
      begin
        AStage.RgbGen := cgVertex;
        if AStage.AlphaGen = agIdentity then
          AStage.AlphaGen := agVertex;
      end
      else if SameWord(LToken, 'exactVertex') then
        AStage.RgbGen := cgExactVertex
      else if SameWord(LToken, 'lightingDiffuse') then
        AStage.RgbGen := cgLightingDiffuse
      else if SameWord(LToken, 'oneMinusVertex') then
        AStage.RgbGen := cgOneMinusVertex
      else
      begin
        AContext.Warn('unknown rgbGen parameter ''%s'' in shader ''%s''', [LToken, LName]);
        Continue;
      end;
    end
    else if SameWord(LToken, 'alphaGen') then
    begin
      LToken := ATokenizer.ParseExt(False);
      if LToken = '' then
      begin
        AContext.Warn('missing parameters for alphaGen in shader ''%s''', [LName]);
        Continue;
      end;
      if SameWord(LToken, 'wave') then
      begin
        TQ3ShaderValueParser.ParseWaveForm(AContext, ATokenizer, AStage.AlphaWave);
        AStage.AlphaGen := agWaveform;
      end
      else if SameWord(LToken, 'const') then
      begin
        LToken := ATokenizer.ParseExt(False);
        AStage.ConstantColor[3] := TQ3ShaderContext.FloatToByte(255 * TIdCNumbers.Atof(LToken));
        AStage.AlphaGen := agConst;
      end
      else if SameWord(LToken, 'identity') then
        AStage.AlphaGen := agIdentity
      else if SameWord(LToken, 'entity') then
        AStage.AlphaGen := agEntity
      else if SameWord(LToken, 'oneMinusEntity') then
        AStage.AlphaGen := agOneMinusEntity
      else if SameWord(LToken, 'vertex') then
        AStage.AlphaGen := agVertex
      else if SameWord(LToken, 'lightingSpecular') then
        AStage.AlphaGen := agLightingSpecular
      else if SameWord(LToken, 'oneMinusVertex') then
        AStage.AlphaGen := agOneMinusVertex
      else if SameWord(LToken, 'portal') then
      begin
        AStage.AlphaGen := agPortal;
        LToken := ATokenizer.ParseExt(False);
        if LToken = '' then
        begin
          AContext.Data.PortalRange := 256;
          AContext.Warn('missing range parameter for alphaGen portal in shader ''%s'', defaulting to 256', [LName]);
        end
        else
          AContext.Data.PortalRange := TIdCNumbers.Atof(LToken);
      end
      else
      begin
        AContext.Warn('unknown alphaGen parameter ''%s'' in shader ''%s''', [LToken, LName]);
        Continue;
      end;
    end
    else if SameWord(LToken, 'texgen') or SameWord(LToken, 'tcGen') then
    begin
      LToken := ATokenizer.ParseExt(False);
      if LToken = '' then
      begin
        AContext.Warn('missing texgen parm in shader ''%s''', [LName]);
        Continue;
      end;
      if SameWord(LToken, 'environment') then
        AStage.Bundle.TcGen := tgEnvironmentMapped
      else if SameWord(LToken, 'lightmap') then
        AStage.Bundle.TcGen := tgLightmap
      else if SameWord(LToken, 'texture') or SameWord(LToken, 'base') then
        AStage.Bundle.TcGen := tgTexture
      else if SameWord(LToken, 'vector') then
      begin
        TQ3ShaderValueParser.ParseVector(AContext, ATokenizer, 3, AStage.Bundle.TcGenVectors[0]);
        TQ3ShaderValueParser.ParseVector(AContext, ATokenizer, 3, AStage.Bundle.TcGenVectors[1]);
        AStage.Bundle.TcGen := tgVector;
      end
      else
        AContext.Warn('unknown texgen parm in shader ''%s''', [LName]);
    end
    else if SameWord(LToken, 'tcMod') then
    begin
      // the words of the line are joined and read again by ParseTexMod
      LBuffer := '';
      while True do
      begin
        LToken := ATokenizer.ParseExt(False);
        if LToken = '' then
          Break;
        LBuffer := LBuffer + LToken + ' ';
      end;
      TQ3ShaderTexModParser.ParseTexMod(AContext, AStage, LBuffer);
      Continue;
    end
    else if SameWord(LToken, 'depthwrite') then
    begin
      LDepthMaskBits := GLS_DEPTHMASK_TRUE;
      LDepthMaskExplicit := True;
      Continue;
    end
    else
    begin
      AContext.Warn(SUnknownParameter, [LToken, LName]);
      Exit(False);
    end;
  end;

  // if cgen isn't explicitly specified, use either identity or identitylighting
  if AStage.RgbGen = cgBad then
  begin
    if (LBlendSrcBits = 0) or (LBlendSrcBits = GLS_SRCBLEND_ONE) or (LBlendSrcBits = GLS_SRCBLEND_SRC_ALPHA) then
      AStage.RgbGen := cgIdentityLighting
    else
      AStage.RgbGen := cgIdentity;
  end;

  // implicitly assume that a GL_ONE GL_ZERO blend mask disables blending
  if (LBlendSrcBits = GLS_SRCBLEND_ONE) and (LBlendDstBits = GLS_DSTBLEND_ZERO) then
  begin
    LBlendDstBits := 0;
    LBlendSrcBits := 0;
    LDepthMaskBits := GLS_DEPTHMASK_TRUE;
  end;

  // decide which agens we can skip. The original compares alphaGen with CGEN_IDENTITY (2), which is
  // AGEN_ENTITY in the alpha enumeration: kept, the data are the same as the original's
  LNumber := Ord(cgIdentity);
  if Ord(AStage.AlphaGen) = LNumber then
  begin
    if (AStage.RgbGen = cgIdentity) or (AStage.RgbGen = cgLightingDiffuse) then
      AStage.AlphaGen := agSkip;
  end;

  // compute state bits
  AStage.StateBits := LDepthMaskBits or LBlendSrcBits or LBlendDstBits or LAlphaTestBits or LDepthFuncBits;
  Result := True;
end;

end.
