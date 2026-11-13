{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - the body of a shader                        }
{                                                                              }
{  Port of ParseShader, ParseSkyParms, ParseSort and the keywords at the top   }
{  level of a shader (renderer\tr_shader.c of Quake III Arena, id Software,    }
{  GPL v2 or later). Based on the Quake III Arena GPL Source Code (id          }
{  Software).                                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Parser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Context,
  DelphiDoom.Decl.Q3Shader.Tokenizer;

type
  /// <summary>The text of a shader after its name, from the "{" to the matching "}"</summary>
  TQ3ShaderParser = class sealed
  strict private
    class procedure ParseSkyParms(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer); static;
    class procedure ParseSort(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer); static;
    class procedure ParseSun(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer); static;
    class procedure ParseCull(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer); static;
    class function ParseFogParms(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer): Boolean; static;
    class function WordAt(const AWord: AnsiString; const AKeyword: AnsiString): Boolean; static; inline;
  public
    /// <summary>
    ///   ParseShader: false with a warning if the shader has an error or no stage (the data keep what was read).
    ///   A ninth stage is an error here (the original writes after its array of eight).
    ///   Raises <c>EDeclQ3ShaderException</c> for the errors that drop the frame in the original.
    /// </summary>
    class function ParseShader(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer): Boolean; static;
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Decl.Q3Shader.Names,
  DelphiDoom.Decl.Q3Shader.ValueParser, DelphiDoom.Decl.Q3Shader.StageParser,
  DelphiDoom.Decl.Q3Shader.DeformParser;

const
  SSkyParmsMissing = '''skyParms'' missing parameter in shader ''%s''';
  SSkyFaceSuffixes: array[0..5] of AnsiString = ('rt', 'bk', 'lf', 'ft', 'up', 'dn');
  M_PI = 3.14159265358979323846;

{ TQ3ShaderParser }

class function TQ3ShaderParser.WordAt(const AWord, AKeyword: AnsiString): Boolean;
begin
  Result := TIdStrings.Icmp(AWord, AKeyword) = 0;
end;

class procedure TQ3ShaderParser.ParseSkyParms(const AContext: TQ3ShaderContext;
  const ATokenizer: TQ3ShaderTokenizer);
var
  LToken: AnsiString;
  LIndex: Integer;
begin
  // outerbox
  LToken := ATokenizer.ParseExt(False);
  if LToken = '' then
  begin
    AContext.Warn(SSkyParmsMissing, [AContext.Data.Name]);
    Exit;
  end;
  if LToken <> '-' then
    for LIndex := 0 to 5 do
      AContext.Data.Sky.OuterBox[LIndex] := LToken + '_' + SSkyFaceSuffixes[LIndex] + '.tga';
  // cloudheight
  LToken := ATokenizer.ParseExt(False);
  if LToken = '' then
  begin
    AContext.Warn(SSkyParmsMissing, [AContext.Data.Name]);
    Exit;
  end;
  AContext.Data.Sky.CloudHeight := TIdCNumbers.Atof(LToken);
  if AContext.Data.Sky.CloudHeight = 0 then
    AContext.Data.Sky.CloudHeight := 512;
  // innerbox
  LToken := ATokenizer.ParseExt(False);
  if LToken = '' then
  begin
    AContext.Warn(SSkyParmsMissing, [AContext.Data.Name]);
    Exit;
  end;
  if LToken <> '-' then
    for LIndex := 0 to 5 do
      AContext.Data.Sky.InnerBox[LIndex] := LToken + '_' + SSkyFaceSuffixes[LIndex] + '.tga';
  AContext.Data.IsSky := True;
end;

class procedure TQ3ShaderParser.ParseSort(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer);
var
  LToken: AnsiString;
begin
  LToken := ATokenizer.ParseExt(False);
  if LToken = '' then
  begin
    AContext.Warn('missing sort parameter in shader ''%s''', [AContext.Data.Name]);
    Exit;
  end;
  if WordAt(LToken, 'portal') then
    AContext.Data.Sort := SS_PORTAL
  else if WordAt(LToken, 'sky') then
    AContext.Data.Sort := SS_ENVIRONMENT
  else if WordAt(LToken, 'opaque') then
    AContext.Data.Sort := SS_OPAQUE
  else if WordAt(LToken, 'decal') then
    AContext.Data.Sort := SS_DECAL
  else if WordAt(LToken, 'seeThrough') then
    AContext.Data.Sort := SS_SEE_THROUGH
  else if WordAt(LToken, 'banner') then
    AContext.Data.Sort := SS_BANNER
  else if WordAt(LToken, 'additive') then
    AContext.Data.Sort := SS_BLEND1
  else if WordAt(LToken, 'nearest') then
    AContext.Data.Sort := SS_NEAREST
  else if WordAt(LToken, 'underwater') then
    AContext.Data.Sort := SS_UNDERWATER
  else
    AContext.Data.Sort := TIdCNumbers.Atof(LToken);
end;

// q3map_sun: the original keeps the result in tr.sunLight and tr.sunDirection
class procedure TQ3ShaderParser.ParseSun(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer);
var
  LToken: AnsiString;
  LLength, LInverse, LAngleA, LAngleB: Single;
  LIndex: Integer;
  LData: PQ3ShaderData;
begin
  LData := AContext.Data;
  LData.HasSun := True;
  for LIndex := 0 to 2 do
  begin
    LToken := ATokenizer.ParseExt(False);
    LData.SunLight[LIndex] := TIdCNumbers.Atof(LToken);
  end;
  // VectorNormalize
  LLength := LData.SunLight[0] * LData.SunLight[0] + LData.SunLight[1] * LData.SunLight[1] +
    LData.SunLight[2] * LData.SunLight[2];
  LLength := Sqrt(Double(LLength));
  if LLength <> 0 then
  begin
    LInverse := 1 / LLength;
    LData.SunLight[0] := LData.SunLight[0] * LInverse;
    LData.SunLight[1] := LData.SunLight[1] * LInverse;
    LData.SunLight[2] := LData.SunLight[2] * LInverse;
  end;
  // VectorScale by the intensity
  LToken := ATokenizer.ParseExt(False);
  LInverse := TIdCNumbers.Atof(LToken);
  LData.SunLight[0] := LData.SunLight[0] * LInverse;
  LData.SunLight[1] := LData.SunLight[1] * LInverse;
  LData.SunLight[2] := LData.SunLight[2] * LInverse;
  LToken := ATokenizer.ParseExt(False);
  LAngleA := TIdCNumbers.Atof(LToken);
  LAngleA := Single(Single(LAngleA / 180) * M_PI);
  LToken := ATokenizer.ParseExt(False);
  LAngleB := TIdCNumbers.Atof(LToken);
  LAngleB := Single(Single(LAngleB / 180) * M_PI);
  LData.SunDirection[0] := Single(Cos(Double(LAngleA)) * Cos(Double(LAngleB)));
  LData.SunDirection[1] := Single(Sin(Double(LAngleA)) * Cos(Double(LAngleB)));
  LData.SunDirection[2] := Single(Sin(Double(LAngleB)));
end;

class procedure TQ3ShaderParser.ParseCull(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer);
var
  LToken: AnsiString;
begin
  LToken := ATokenizer.ParseExt(False);
  if LToken = '' then
  begin
    AContext.Warn('missing cull parms in shader ''%s''', [AContext.Data.Name]);
    Exit;
  end;
  if WordAt(LToken, 'none') or WordAt(LToken, 'twosided') or WordAt(LToken, 'disable') then
    AContext.Data.CullType := ctTwoSided
  else if WordAt(LToken, 'back') or WordAt(LToken, 'backside') or WordAt(LToken, 'backsided') then
    AContext.Data.CullType := ctBackSided
  else
    AContext.Warn('invalid cull parm ''%s'' in shader ''%s''', [LToken, AContext.Data.Name]);
end;

// false is the "return qfalse" of the keyword: a vector that is not right ends the shader
class function TQ3ShaderParser.ParseFogParms(const AContext: TQ3ShaderContext;
  const ATokenizer: TQ3ShaderTokenizer): Boolean;
var
  LToken: AnsiString;
begin
  if not TQ3ShaderValueParser.ParseVector(AContext, ATokenizer, 3, AContext.Data.FogParms.Color) then
    Exit(False);
  LToken := ATokenizer.ParseExt(False);
  if LToken = '' then
  begin
    AContext.Warn('missing parm for ''fogParms'' keyword in shader ''%s''', [AContext.Data.Name]);
    Exit(True);
  end;
  AContext.Data.FogParms.DepthForOpaque := TIdCNumbers.Atof(LToken);
  // skip any old gradient directions
  ATokenizer.SkipRestOfLine;
  Result := True;
end;

class function TQ3ShaderParser.ParseShader(const AContext: TQ3ShaderContext;
  const ATokenizer: TQ3ShaderTokenizer): Boolean;
var
  LToken: AnsiString;
  LStageCount: Integer;
  LName: AnsiString;
  LData: PQ3ShaderData;
begin
  LData := AContext.Data;
  LName := LData.Name;
  LStageCount := 0;
  LToken := ATokenizer.ParseExt(True);
  if (LToken = '') or (LToken[1] <> '{') then
  begin
    AContext.Warn('expecting ''{'', found ''%s'' instead in shader ''%s''', [LToken, LName]);
    Exit(False);
  end;
  while True do
  begin
    LToken := ATokenizer.ParseExt(True);
    if LToken = '' then
    begin
      AContext.Warn('no concluding ''}'' in shader %s', [LName]);
      Exit(False);
    end;
    // end of shader definition
    if LToken[1] = '}' then
      Break
    // stage definition
    else if LToken[1] = '{' then
    begin
      if LStageCount = Q3_MAX_SHADER_STAGES then
      begin
        AContext.Warn('too many stages in shader ''%s''', [LName]);
        Exit(False);
      end;
      if not TQ3ShaderStageParser.ParseStage(AContext, ATokenizer, @LData.Stages[LStageCount]) then
        Exit(False);
      LData.Stages[LStageCount].Active := True;
      Inc(LStageCount);
    end
    // skip stuff that only the QuakeEdRadient needs
    else if TIdStrings.Icmpn(LToken, 'qer', 3) = 0 then
      ATokenizer.SkipRestOfLine
    else if WordAt(LToken, 'q3map_sun') then
      ParseSun(AContext, ATokenizer)
    else if WordAt(LToken, 'deformVertexes') then
      TQ3ShaderDeformParser.ParseDeform(AContext, ATokenizer)
    else if WordAt(LToken, 'tesssize') then
      ATokenizer.SkipRestOfLine
    else if WordAt(LToken, 'clampTime') then
    begin
      LToken := ATokenizer.ParseExt(False);
      if LToken <> '' then
        LData.ClampTime := TIdCNumbers.Atof(LToken);
    end
    // skip stuff that only the q3map needs
    else if TIdStrings.Icmpn(LToken, 'q3map', 5) = 0 then
      ATokenizer.SkipRestOfLine
    // skip stuff that only q3map or the server needs
    else if WordAt(LToken, 'surfaceParm') then
      TQ3ShaderNames.ApplySurfaceParm(AContext, ATokenizer.ParseExt(False))
    else if WordAt(LToken, 'nomipmaps') then
    begin
      LData.NoMipMaps := True;
      LData.NoPicMip := True;
    end
    else if WordAt(LToken, 'nopicmip') then
      LData.NoPicMip := True
    else if WordAt(LToken, 'polygonOffset') then
      LData.PolygonOffset := True
    else if WordAt(LToken, 'entityMergable') then
      LData.EntityMergable := True
    else if WordAt(LToken, 'fogParms') then
    begin
      if not ParseFogParms(AContext, ATokenizer) then
        Exit(False);
    end
    else if WordAt(LToken, 'portal') then
      LData.Sort := SS_PORTAL
    else if WordAt(LToken, 'skyparms') then
      ParseSkyParms(AContext, ATokenizer)
    // light <value> determines flaring in q3map, not needed here
    else if WordAt(LToken, 'light') then
      ATokenizer.ParseExt(False)
    else if WordAt(LToken, 'cull') then
      ParseCull(AContext, ATokenizer)
    else if WordAt(LToken, 'sort') then
      ParseSort(AContext, ATokenizer)
    else
    begin
      AContext.Warn('unknown general shader parameter ''%s'' in ''%s''', [LToken, LName]);
      Exit(False);
    end;
  end;

  // ignore shaders that don't have any stages, unless it is a sky or fog
  if (LStageCount = 0) and (not LData.IsSky) and ((LData.ContentFlags and CONTENTS_FOG) = 0) then
    Exit(False);
  LData.ExplicitlyDefined := True;
  Result := True;
end;

end.
