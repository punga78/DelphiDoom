{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TMaterialParser                           }
{                                                                              }
{  Port of the material of Doom 3 (id Software, GPL v3):                       }
{  renderer\Material.cpp (idMaterial::Parse, ParseMaterial, ParseSort,         }
{  ParseDeform, ParseDecalInfo, AddImplicitStages, SortInteractionStages,      }
{  CheckForConstantRegisters). Copyright (C) 1999-2011 id Software LLC, a      }
{  ZeniMax Media company.                                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Material.Parser;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Lexer,
  DelphiDoom.Decl.Intf, DelphiDoom.Decl.Material.Types, DelphiDoom.Decl.Material.Intf,
  DelphiDoom.Decl.Material.Data, DelphiDoom.Decl.Material.Registers, DelphiDoom.Decl.Material.ExpressionParser,
  DelphiDoom.Decl.Material.StageParser;

type
  /// <summary>
  ///   Reads the text of a material declaration into a <c>TMaterialData</c>. One instance per parse (the
  ///   registers and the stages it builds are its own, so a parse can run while another is in progress: the
  ///   default definition is parsed when a parse fails). After the text it adds the implicit stages, sorts
  ///   the interaction stages and works out coverage, sort, depth bits, overlays and constant registers.
  /// </summary>
  TMaterialParser = class
  strict private
    FName: AnsiString;
    FLog: IIdLibLog;
    FFinder: IDeclFinder;
    FNamer: IMaterialImageNamer;
    FOptions: TMaterialOptions;
    FData: TMaterialData;
    FRegisters: TMaterialRegisterTable;
    FExpressions: TMaterialExpressionParser;
    FStageParser: TMaterialStageParser;
    FStages: TList<TMaterialStage>;
    FForceOverlays: Boolean;
    procedure Warn(const AMessage: string);
    procedure SetFlag(const AFlag: Integer);
    function TestFlag(const AFlag: Integer): Boolean;
    function NewLexer(const AText: AnsiString; const AName: AnsiString): TIdLexer;
    procedure ParseStageFrom(const ASource: TIdLexer; const ADefaultRepeat: TMaterialTextureRepeat);
    procedure ParseStageShorthand(const ASource: TIdLexer; const AKeyword: AnsiString;
      const ADefaultRepeat: TMaterialTextureRepeat);
    procedure ParseSort(const ASource: TIdLexer);
    procedure ParseDecalInfo(const ASource: TIdLexer);
    procedure ParseDeform(const ASource: TIdLexer);
    procedure ParseMaterial(const ASource: TIdLexer);
    procedure AddImplicitStages;
    procedure SortInteractionStages;
    procedure Finish;
    procedure CheckForConstantRegisters;
  public
    /// <summary>AFinder is the manager (tables and particles), ANamer reads the image programs</summary>
    constructor Create(const AName: AnsiString; const ALog: IIdLibLog; const AFinder: IDeclFinder;
      const ANamer: IMaterialImageNamer; const AOptions: TMaterialOptions);
    /// <summary>
    ///   Parses the text after the first brace into <c>AData</c> (reset first). False if the material has an
    ///   error (the caller makes it the default material); the warnings carry the file and the line.
    /// </summary>
    function Parse(const ASource: TIdLexer; const AData: TMaterialData): Boolean;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Decl.Types, DelphiDoom.Decl.Material.SurfaceParms,
  DelphiDoom.Decl.Material.Evaluator, DelphiDoom.Decl.Material.ImageNames;

const
  IMPLICIT_LEXER_FLAGS = LEXFL_NOFATALERRORS or LEXFL_NOSTRINGCONCAT or LEXFL_NOSTRINGESCAPECHARS
    or LEXFL_ALLOWPATHNAMES;

{ TMaterialParser }

constructor TMaterialParser.Create(const AName: AnsiString; const ALog: IIdLibLog; const AFinder: IDeclFinder;
  const ANamer: IMaterialImageNamer; const AOptions: TMaterialOptions);
begin
  inherited Create;
  FName := AName;
  FLog := ALog;
  FFinder := AFinder;
  FNamer := ANamer;
  FOptions := AOptions;
end;

procedure TMaterialParser.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

procedure TMaterialParser.SetFlag(const AFlag: Integer);
begin
  if AFlag = MF_DEFAULTED then
    FRegisters.MarkDefaulted
  else
    FData.MaterialFlags := FData.MaterialFlags or AFlag;
end;

function TMaterialParser.TestFlag(const AFlag: Integer): Boolean;
begin
  if AFlag = MF_DEFAULTED then
    Result := FRegisters.Defaulted
  else
    Result := (FData.MaterialFlags and AFlag) <> 0;
end;

function TMaterialParser.NewLexer(const AText: AnsiString; const AName: AnsiString): TIdLexer;
begin
  Result := TIdLexer.Create(0, FLog);
  try
    Result.LoadMemory(AText, Length(AText), AName);
    Result.Flags := IMPLICIT_LEXER_FLAGS;
  except
    Result.Free;
    raise;
  end;
end;

procedure TMaterialParser.ParseStageFrom(const ASource: TIdLexer; const ADefaultRepeat: TMaterialTextureRepeat);
var
  LStage: TMaterialStage;
  LTexgen: TMaterialTexgenRegisters;
  LCoverage: TMaterialCoverage;
  LIndex: Integer;
begin
  for LIndex := 0 to MAX_TEXGEN_REGISTERS - 1 do
    LTexgen[LIndex] := FData.TexGenRegisters[LIndex];
  LCoverage := FData.Coverage;
  try
    if FStageParser.ParseStage(ASource, ADefaultRepeat, FStages.Count, LCoverage, LTexgen, LStage) then
      FStages.Add(LStage);
  finally
    FData.Coverage := LCoverage;
    for LIndex := 0 to MAX_TEXGEN_REGISTERS - 1 do
      FData.TexGenRegisters[LIndex] := LTexgen[LIndex];
  end;
end;

// "diffusemap x" is the stage "{ blend diffusemap map x }", read from a text the material builds
procedure TMaterialParser.ParseStageShorthand(const ASource: TIdLexer; const AKeyword: AnsiString;
  const ADefaultRepeat: TMaterialTextureRepeat);
var
  LImage: AnsiString;
  LNewSource: TIdLexer;
begin
  LImage := FNamer.ParsePastImageProgram(ASource);
  LNewSource := NewLexer('blend ' + AKeyword + #10'map ' + LImage + #10'}'#10, AKeyword);
  try
    ParseStageFrom(LNewSource, ADefaultRepeat);
  finally
    LNewSource.Free;
  end;
end;

procedure TMaterialParser.ParseSort(const ASource: TIdLexer);
var
  LToken: TIdToken;
begin
  LToken := TIdToken.Create;
  if not ASource.ReadTokenOnLine(LToken) then
  begin
    ASource.Warning('missing sort parameter', []);
    SetFlag(MF_DEFAULTED);
    Exit;
  end;

  if TIdStrings.Icmp(LToken.Text, 'subview') = 0 then
    FData.Sort := SS_SUBVIEW
  else if TIdStrings.Icmp(LToken.Text, 'opaque') = 0 then
    FData.Sort := SS_OPAQUE
  else if TIdStrings.Icmp(LToken.Text, 'decal') = 0 then
    FData.Sort := SS_DECAL
  else if TIdStrings.Icmp(LToken.Text, 'far') = 0 then
    FData.Sort := SS_FAR
  else if TIdStrings.Icmp(LToken.Text, 'medium') = 0 then
    FData.Sort := SS_MEDIUM
  else if TIdStrings.Icmp(LToken.Text, 'close') = 0 then
    FData.Sort := SS_CLOSE
  else if TIdStrings.Icmp(LToken.Text, 'almostNearest') = 0 then
    FData.Sort := SS_ALMOST_NEAREST
  else if TIdStrings.Icmp(LToken.Text, 'nearest') = 0 then
    FData.Sort := SS_NEAREST
  else if TIdStrings.Icmp(LToken.Text, 'postProcess') = 0 then
    FData.Sort := SS_POST_PROCESS
  else if TIdStrings.Icmp(LToken.Text, 'portalSky') = 0 then
    FData.Sort := SS_PORTAL_SKY
  else
    FData.Sort := TIdCNumbers.Atof(LToken.Text);
end;

procedure TMaterialParser.ParseDecalInfo(const ASource: TIdLexer);
var
  LStart, LFinish: array[0..3] of Single;
  LSeconds: Single;
  LIndex: Integer;
begin
  // a float times a thousand, cut to an integer
  LSeconds := ASource.ParseFloat * 1000;
  FData.DecalInfo.StayTime := Trunc(LSeconds);
  LSeconds := ASource.ParseFloat * 1000;
  FData.DecalInfo.FadeTime := Trunc(LSeconds);
  ASource.Parse1DMatrix(4, LStart);
  ASource.Parse1DMatrix(4, LFinish);
  for LIndex := 0 to 3 do
  begin
    FData.DecalInfo.Start[LIndex] := LStart[LIndex];
    FData.DecalInfo.Finish[LIndex] := LFinish[LIndex];
  end;
end;

procedure TMaterialParser.ParseDeform(const ASource: TIdLexer);
var
  LToken: TIdToken;

  function IsWord(const AWord: AnsiString): Boolean;
  begin
    Result := TIdStrings.Icmp(LToken.Text, AWord) = 0;
  end;

begin
  LToken := TIdToken.Create;
  if not ASource.ExpectAnyToken(LToken) then
    Exit;

  if IsWord('sprite') then
  begin
    FData.Deform := TMaterialDeform.Sprite;
    FData.CullType := TMaterialCullType.TwoSided;
    SetFlag(MF_NOSHADOWS);
    Exit;
  end;
  if IsWord('tube') then
  begin
    FData.Deform := TMaterialDeform.Tube;
    FData.CullType := TMaterialCullType.TwoSided;
    SetFlag(MF_NOSHADOWS);
    Exit;
  end;
  if IsWord('flare') then
  begin
    FData.Deform := TMaterialDeform.Flare;
    FData.CullType := TMaterialCullType.TwoSided;
    FData.DeformRegisters[0] := FExpressions.ParseExpression(ASource);
    SetFlag(MF_NOSHADOWS);
    Exit;
  end;
  if IsWord('expand') then
  begin
    FData.Deform := TMaterialDeform.Expand;
    FData.DeformRegisters[0] := FExpressions.ParseExpression(ASource);
    Exit;
  end;
  if IsWord('move') then
  begin
    FData.Deform := TMaterialDeform.Move;
    FData.DeformRegisters[0] := FExpressions.ParseExpression(ASource);
    Exit;
  end;
  if IsWord('turbulent') then
  begin
    FData.Deform := TMaterialDeform.Turbulent;
    if not ASource.ExpectAnyToken(LToken) then
    begin
      ASource.Warning('deform particle missing particle name', []);
      SetFlag(MF_DEFAULTED);
      Exit;
    end;
    FData.DeformDecl := FFinder.FindType(DECL_TABLE, LToken.Text, True);
    FData.DeformRegisters[0] := FExpressions.ParseExpression(ASource);
    FData.DeformRegisters[1] := FExpressions.ParseExpression(ASource);
    FData.DeformRegisters[2] := FExpressions.ParseExpression(ASource);
    Exit;
  end;
  if IsWord('eyeBall') then
  begin
    FData.Deform := TMaterialDeform.EyeBall;
    Exit;
  end;
  if IsWord('particle') or IsWord('particle2') then
  begin
    if IsWord('particle') then
      FData.Deform := TMaterialDeform.Particle
    else
      FData.Deform := TMaterialDeform.Particle2;
    if not ASource.ExpectAnyToken(LToken) then
    begin
      ASource.Warning('deform particle missing particle name', []);
      SetFlag(MF_DEFAULTED);
      Exit;
    end;
    FData.DeformDecl := FFinder.FindType(DECL_PARTICLE, LToken.Text, True);
    Exit;
  end;
  ASource.Warning('Bad deform type ''%s''', [string(LToken.Text)]);
  SetFlag(MF_DEFAULTED);
end;

procedure TMaterialParser.ParseMaterial(const ASource: TIdLexer);
var
  LToken: TIdToken;
  LDefaultRepeat: TMaterialTextureRepeat;

  function IsWord(const AWord: AnsiString): Boolean;
  begin
    Result := TIdStrings.Icmp(LToken.Text, AWord) = 0;
  end;

begin
  LToken := TIdToken.Create;
  LDefaultRepeat := TMaterialTextureRepeat.Repeated;

  while True do
  begin
    // we have a parse error
    if TestFlag(MF_DEFAULTED) then
      Exit;
    if not ASource.ExpectAnyToken(LToken) then
    begin
      SetFlag(MF_DEFAULTED);
      Exit;
    end;

    // end of material definition
    if LToken.IsText('}') then
      Break
    else if IsWord('qer_editorimage') then
    begin
      ASource.ReadTokenOnLine(LToken);
      FData.EditorImageName := LToken.Text;
      ASource.SkipRestOfLine;
    end
    else if IsWord('description') then
    begin
      ASource.ReadTokenOnLine(LToken);
      FData.Description := LToken.Text;
    end
    // check for the surface / content bit flags
    else if TMaterialSurfaceParms.Apply(LToken.Text, FData.SurfaceFlags, FData.ContentFlags) then
      Continue
    else if IsWord('polygonOffset') then
    begin
      SetFlag(MF_POLYGONOFFSET);
      if not ASource.ReadTokenOnLine(LToken) then
        FData.PolygonOffset := 1
      else
        // explict larger (or negative) offset
        FData.PolygonOffset := LToken.GetFloatValue;
    end
    else if IsWord('noShadows') then
      SetFlag(MF_NOSHADOWS)
    else if IsWord('suppressInSubview') then
      FData.SuppressInSubview := True
    else if IsWord('portalSky') then
      FData.PortalSky := True
    else if IsWord('noSelfShadow') then
      SetFlag(MF_NOSELFSHADOW)
    else if IsWord('noPortalFog') then
      SetFlag(MF_NOPORTALFOG)
    // forceShadows allows nodraw surfaces to cast shadows
    else if IsWord('forceShadows') then
      SetFlag(MF_FORCESHADOWS)
    // overlay / decal suppression
    else if IsWord('noOverlays') then
      FData.AllowOverlays := False
    // moster blood overlay forcing for alpha tested or translucent surfaces
    else if IsWord('forceOverlays') then
      FForceOverlays := True
    else if IsWord('translucent') then
      FData.Coverage := TMaterialCoverage.Translucent
    // global zero clamp
    else if IsWord('zeroclamp') then
      LDefaultRepeat := TMaterialTextureRepeat.ClampToZero
    // global clamp
    else if IsWord('clamp') then
      LDefaultRepeat := TMaterialTextureRepeat.Clamp
    // (the original sets zero clamp here too)
    else if IsWord('alphazeroclamp') then
      LDefaultRepeat := TMaterialTextureRepeat.ClampToZero
    // forceOpaque is used for skies-behind-windows
    else if IsWord('forceOpaque') then
      FData.Coverage := TMaterialCoverage.Opaque
    else if IsWord('twoSided') then
    begin
      FData.CullType := TMaterialCullType.TwoSided;
      // twoSided implies no-shadows, because the shadow volume would be coplanar with the surface
      SetFlag(MF_NOSHADOWS);
    end
    else if IsWord('backSided') then
    begin
      FData.CullType := TMaterialCullType.BackSided;
      // the shadow code doesn't handle this, so just disable shadows
      SetFlag(MF_NOSHADOWS);
    end
    else if IsWord('fogLight') then
      FData.FogLight := True
    else if IsWord('blendLight') then
      FData.BlendLight := True
    else if IsWord('ambientLight') then
      FData.AmbientLight := True
    else if IsWord('mirror') then
    begin
      FData.Sort := SS_SUBVIEW;
      FData.Coverage := TMaterialCoverage.Opaque;
    end
    else if IsWord('noFog') then
      FData.NoFog := True
    else if IsWord('unsmoothedTangents') then
      FData.UnsmoothedTangents := True
    // lightFallofImage <imageprogram>: the third axis of projected light volumes
    else if IsWord('lightFalloffImage') then
      FData.LightFalloffImageName := FNamer.ParsePastImageProgram(ASource)
    // guisurf <guifile> | guisurf entity (the gui is named, not loaded)
    else if IsWord('guisurf') then
    begin
      ASource.ReadTokenOnLine(LToken);
      if IsWord('entity') then
        FData.EntityGui := 1
      else if IsWord('entity2') then
        FData.EntityGui := 2
      else if IsWord('entity3') then
        FData.EntityGui := 3
      else
      begin
        FData.HasGlobalGui := True;
        FData.GuiName := LToken.Text;
      end;
    end
    else if IsWord('sort') then
      ParseSort(ASource)
    // spectrum <integer>
    else if IsWord('spectrum') then
    begin
      ASource.ReadTokenOnLine(LToken);
      FData.Spectrum := TIdCNumbers.Atoi(LToken.Text);
    end
    // deform < sprite | tube | flare >
    else if IsWord('deform') then
      ParseDeform(ASource)
    // decalInfo <staySeconds> <fadeSeconds> ( <start rgb> ) ( <end rgb> )
    else if IsWord('decalInfo') then
      ParseDecalInfo(ASource)
    // renderbump <args...>
    else if IsWord('renderbump') then
      ASource.ParseRestOfLine(FData.RenderBump)
    // diffusemap, specularmap and bumpmap for stage shortcut
    else if IsWord('diffusemap') then
      ParseStageShorthand(ASource, 'diffusemap', LDefaultRepeat)
    else if IsWord('specularmap') then
      ParseStageShorthand(ASource, 'specularmap', LDefaultRepeat)
    else if IsWord('bumpmap') then
      ParseStageShorthand(ASource, 'bumpmap', LDefaultRepeat)
    // DECAL_MACRO for backwards compatibility with the preprocessor macros
    else if IsWord('DECAL_MACRO') then
    begin
      SetFlag(MF_POLYGONOFFSET);
      FData.PolygonOffset := 1;
      // discrete
      FData.SurfaceFlags := FData.SurfaceFlags or SURF_DISCRETE;
      FData.ContentFlags := FData.ContentFlags and not CONTENTS_SOLID;
      // sort decal
      FData.Sort := SS_DECAL;
      SetFlag(MF_NOSHADOWS);
    end
    else if LToken.IsText('{') then
      // create the new stage
      ParseStageFrom(ASource, LDefaultRepeat)
    else
    begin
      Warn(Format('unknown general material parameter ''%s'' in ''%s''', [string(LToken.Text), string(FName)]));
      SetFlag(MF_DEFAULTED);
      Exit;
    end;
  end;

  // add _flat or _white stages if needed
  AddImplicitStages;

  // order the diffuse / bump / specular stages properly
  SortInteractionStages;
end;

procedure TMaterialParser.AddImplicitStages;
var
  LHasDiffuse, LHasSpecular, LHasBump, LHasReflection: Boolean;
  LStage: TMaterialStage;
  LSource: TIdLexer;
begin
  LHasDiffuse := False;
  LHasSpecular := False;
  LHasBump := False;
  LHasReflection := False;

  for LStage in FStages do
  begin
    if LStage.Lighting = TMaterialLighting.Bump then
      LHasBump := True;
    if LStage.Lighting = TMaterialLighting.Diffuse then
      LHasDiffuse := True;
    if LStage.Lighting = TMaterialLighting.Specular then
      LHasSpecular := True;
    if LStage.Texture.Texgen = TMaterialTexgen.ReflectCube then
      LHasReflection := True;
  end;

  // if it doesn't have an interaction at all, don't add anything
  if (not LHasBump) and (not LHasDiffuse) and (not LHasSpecular) then
    Exit;

  if FStages.Count = MAX_SHADER_STAGES then
    Exit;

  if not LHasBump then
  begin
    LSource := NewLexer('blend bumpmap'#10'map _flat'#10'}'#10, 'bumpmap');
    try
      ParseStageFrom(LSource, TMaterialTextureRepeat.Repeated);
    finally
      LSource.Free;
    end;
  end;

  if (not LHasDiffuse) and (not LHasSpecular) and (not LHasReflection) then
  begin
    LSource := NewLexer('blend diffusemap'#10'map _white'#10'}'#10, 'diffusemap');
    try
      ParseStageFrom(LSource, TMaterialTextureRepeat.Repeated);
    finally
      LSource.Free;
    end;
  end;
end;

procedure TMaterialParser.SortInteractionStages;
var
  LStages: TArray<TMaterialStage>;
  LNumStages, LI, LJ, LK, LL: Integer;
  LTemp: TMaterialStage;
begin
  LStages := FStages.ToArray;
  LNumStages := Length(LStages);
  LI := 0;
  while LI < LNumStages do
  begin
    // find the next bump map
    LJ := LI + 1;
    while LJ < LNumStages do
    begin
      if LStages[LJ].Lighting = TMaterialLighting.Bump then
      begin
        // if the very first stage wasn't a bumpmap, this bumpmap is part of the first group
        if LStages[LI].Lighting <> TMaterialLighting.Bump then
        begin
          Inc(LJ);
          Continue;
        end;
        Break;
      end;
      Inc(LJ);
    end;

    // bubble sort everything bump / diffuse / specular
    for LL := 1 to LJ - LI - 1 do
      for LK := LI to LJ - LL - 1 do
        if LStages[LK].Lighting > LStages[LK + 1].Lighting then
        begin
          LTemp := LStages[LK];
          LStages[LK] := LStages[LK + 1];
          LStages[LK + 1] := LTemp;
        end;
    LI := LJ;
  end;
  FStages.Clear;
  FStages.AddRange(LStages);
end;

procedure TMaterialParser.CheckForConstantRegisters;
var
  LEvaluator: TMaterialExpressionEvaluator;
  LInput: TMaterialEvaluationInput;
  LRegisters: TArray<Single>;
begin
  if not FRegisters.RegistersAreConstant then
    Exit;

  // evaluate the registers once, and save them
  LInput := Default(TMaterialEvaluationInput);
  LEvaluator := TMaterialExpressionEvaluator.Create(FFinder);
  try
    LEvaluator.Evaluate(FData.ExpressionRegisters, FData.Ops, LInput, LRegisters);
  finally
    LEvaluator.Free;
  end;
  FData.ConstantRegisters := LRegisters;
end;

procedure TMaterialParser.Finish;
var
  LIndex, LJ: Integer;
  LStage: TMaterialStage;
  LStages: TArray<TMaterialStage>;
  LFirstGen: TMaterialTexgen;
  LDrawn: Boolean;
begin
  LStages := FStages.ToArray;

  // if we need to do anything with normals (lighting or environment mapping) and two sided lighting was asked
  // for, flag shouldCreateBackSides and change culling back to single sided, so we get proper tangent vectors
  // on both sides
  if FData.CullType = TMaterialCullType.TwoSided then
    for LStage in LStages do
      if (LStage.Lighting <> TMaterialLighting.Ambient) or (LStage.Texture.Texgen <> TMaterialTexgen.Explicit) then
      begin
        FData.CullType := TMaterialCullType.FrontSided;
        FData.ShouldCreateBackSides := True;
        Break;
      end;

  // currently a surface can only have one unique texgen for all the stages on old hardware
  LFirstGen := TMaterialTexgen.Explicit;
  for LStage in LStages do
    if LStage.Texture.Texgen <> TMaterialTexgen.Explicit then
    begin
      if LFirstGen = TMaterialTexgen.Explicit then
        LFirstGen := LStage.Texture.Texgen
      else if LFirstGen <> LStage.Texture.Texgen then
      begin
        Warn(Format('material ''%s'' has multiple stages with a texgen', [string(FName)]));
        Break;
      end;
    end;

  // count non-lit stages
  FData.NumAmbientStages := 0;
  for LStage in LStages do
    if LStage.Lighting = TMaterialLighting.Ambient then
      Inc(FData.NumAmbientStages);

  // see if there is a subview stage
  if FData.Sort = SS_SUBVIEW then
    FData.HasSubview := True
  else
  begin
    FData.HasSubview := False;
    for LStage in LStages do
      if LStage.Texture.Dynamic <> TMaterialDynamicImage.Static then
        FData.HasSubview := True;
  end;

  // automatically determine coverage if not explicitly set
  if FData.Coverage = TMaterialCoverage.Bad then
  begin
    // automatically set translucent if we don't have any interaction stages and the first stage is blended and
    // not an alpha test mask or a subview
    if Length(LStages) = 0 then
      // non-visible
      FData.Coverage := TMaterialCoverage.Translucent
    else if Length(LStages) <> FData.NumAmbientStages then
      // we have an interaction draw
      FData.Coverage := TMaterialCoverage.Opaque
    else if ((LStages[0].DrawStateBits and GLS_DSTBLEND_BITS) <> GLS_DSTBLEND_ZERO)
      or ((LStages[0].DrawStateBits and GLS_SRCBLEND_BITS) = GLS_SRCBLEND_DST_COLOR)
      or ((LStages[0].DrawStateBits and GLS_SRCBLEND_BITS) = GLS_SRCBLEND_ONE_MINUS_DST_COLOR)
      or ((LStages[0].DrawStateBits and GLS_SRCBLEND_BITS) = GLS_SRCBLEND_DST_ALPHA)
      or ((LStages[0].DrawStateBits and GLS_SRCBLEND_BITS) = GLS_SRCBLEND_ONE_MINUS_DST_ALPHA) then
      // blended with the destination
      FData.Coverage := TMaterialCoverage.Translucent
    else
      FData.Coverage := TMaterialCoverage.Opaque;
  end;

  // translucent automatically implies noshadows
  if FData.Coverage = TMaterialCoverage.Translucent then
    SetFlag(MF_NOSHADOWS)
  else
    // mark the contents as opaque
    FData.ContentFlags := FData.ContentFlags or CONTENTS_OPAQUE;

  // if we are translucent, draw with an alpha in the editor
  if FData.Coverage = TMaterialCoverage.Translucent then
    FData.EditorAlpha := 0.5
  else
    FData.EditorAlpha := 1.0;

  // the sorts can make reasonable defaults
  if FData.Sort = SS_BAD then
  begin
    if TestFlag(MF_POLYGONOFFSET) then
      FData.Sort := SS_DECAL
    else if FData.Coverage = TMaterialCoverage.Translucent then
      FData.Sort := SS_MEDIUM
    else
      FData.Sort := SS_OPAQUE;
  end;

  // anything that references _currentRender will automatically get sort = SS_POST_PROCESS and
  // coverage = MC_TRANSLUCENT
  LIndex := 0;
  while LIndex < Length(LStages) do
  begin
    if LStages[LIndex].Texture.HasImage and TMaterialImageNames.IsCurrentRender(LStages[LIndex].Texture.Image.Name) then
    begin
      if FData.Sort <> SS_PORTAL_SKY then
      begin
        FData.Sort := SS_POST_PROCESS;
        FData.Coverage := TMaterialCoverage.Translucent;
      end;
      Break;
    end;
    if LStages[LIndex].HasNewStage then
      for LJ := 0 to LStages[LIndex].NewStage.NumFragmentImages - 1 do
        if TMaterialImageNames.IsCurrentRender(LStages[LIndex].NewStage.FragmentImages[LJ].Name) then
        begin
          if FData.Sort <> SS_PORTAL_SKY then
          begin
            FData.Sort := SS_POST_PROCESS;
            FData.Coverage := TMaterialCoverage.Translucent;
          end;
          // the original ends the outer loop here too
          LIndex := Length(LStages);
          Break;
        end;
    Inc(LIndex);
  end;

  // set the drawStateBits depth flags
  for LIndex := 0 to High(LStages) do
  begin
    if FData.Sort = SS_POST_PROCESS then
      // post-process effects fill the depth buffer as they draw, so only the topmost one is rendered
      LStages[LIndex].DrawStateBits := LStages[LIndex].DrawStateBits or GLS_DEPTHFUNC_LESS
    else if (FData.Coverage = TMaterialCoverage.Translucent) or LStages[LIndex].IgnoreAlphaTest then
      // translucent surfaces can extend past the exactly marked depth buffer
      LStages[LIndex].DrawStateBits := LStages[LIndex].DrawStateBits or GLS_DEPTHFUNC_LESS or GLS_DEPTHMASK
    else
      // opaque and perforated surfaces must exactly match the depth buffer, which gets alpha test correct
      LStages[LIndex].DrawStateBits := LStages[LIndex].DrawStateBits or GLS_DEPTHFUNC_EQUAL or GLS_DEPTHMASK;
  end;

  // determine if this surface will accept overlays / decals
  if FForceOverlays then
    // explicitly flaged in material definition
    FData.AllowOverlays := True
  else
  begin
    LDrawn := (Length(LStages) > 0) or (FData.EntityGui <> 0) or FData.HasGlobalGui;
    if not LDrawn then
      FData.AllowOverlays := False;
    if FData.Coverage <> TMaterialCoverage.Opaque then
      FData.AllowOverlays := False;
    if (FData.SurfaceFlags and SURF_NOIMPACT) <> 0 then
      FData.AllowOverlays := False;
  end;

  FData.Stages := LStages;
  FData.Ops := FRegisters.CopyOps;
  FData.ExpressionRegisters := FRegisters.CopyValues;

  // see if the registers are completely constant, and don't need to be evaluated per-surface
  CheckForConstantRegisters;
end;

function TMaterialParser.Parse(const ASource: TIdLexer; const AData: TMaterialData): Boolean;
begin
  FData := AData;
  // reset to the unparsed state
  FData.Reset;
  FRegisters := TMaterialRegisterTable.Create(FName, FLog, FOptions.FixConstantRegisters);
  try
    FExpressions := TMaterialExpressionParser.Create(FRegisters, FFinder, FLog, FName,
      FOptions.FragmentProgramsAvailable);
    try
      FStageParser := TMaterialStageParser.Create(FRegisters, FExpressions, FNamer, FFinder, FLog, FName,
        FOptions);
      try
        FStages := TList<TMaterialStage>.Create;
        try
          ParseMaterial(ASource);
          if FRegisters.Defaulted then
            Exit(False);
          Finish;
          Result := not FRegisters.Defaulted;
        finally
          FStages.Free;
        end;
      finally
        FStageParser.Free;
      end;
    finally
      FExpressions.Free;
    end;
  finally
    FRegisters.Free;
  end;
end;

end.
