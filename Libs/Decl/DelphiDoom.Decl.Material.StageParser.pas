{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TMaterialStageParser                      }
{                                                                              }
{  Port of the material of Doom 3 (id Software, GPL v3):                       }
{  renderer\Material.cpp (ParseStage, ParseBlend, ParseVertexParm,             }
{  ParseFragmentMap, MultiplyTextureMatrix, ClearStage). Copyright (C)         }
{  1999-2011 id Software LLC, a ZeniMax Media company.                         }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Material.StageParser;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Decl.Intf,
  DelphiDoom.Decl.Material.Types, DelphiDoom.Decl.Material.Intf, DelphiDoom.Decl.Material.Registers,
  DelphiDoom.Decl.Material.ExpressionParser;

type
  /// <summary>The wobble sky registers of a material (<c>texGenRegisters</c>)</summary>
  TMaterialTexgenRegisters = array[0..MAX_TEXGEN_REGISTERS - 1] of Integer;

  /// <summary>
  ///   Reads one stage of a material: the text after the open brace up to the close brace (or, for the
  ///   shorthands <c>diffusemap</c>, <c>bumpmap</c> and <c>specularmap</c>, a text the material builds). The
  ///   images are named, not loaded; a stage that has an error defaults the material.
  /// </summary>
  TMaterialStageParser = class
  strict private
    FRegisters: TMaterialRegisterTable;
    FExpressions: TMaterialExpressionParser;
    FNamer: IMaterialImageNamer;
    FFinder: IDeclFinder;
    FLog: IIdLibLog;
    FMaterialName: AnsiString;
    FOptions: TMaterialOptions;
    procedure Warn(const AMessage: string);
    procedure ClearStage(var AStage: TMaterialStage);
    procedure ParseBlend(const ASource: TIdLexer; var AStage: TMaterialStage);
    procedure ParseVertexParm(const ASource: TIdLexer; var ANewStage: TMaterialNewStage);
    procedure ParseFragmentMap(const ASource: TIdLexer; var ANewStage: TMaterialNewStage);
    procedure MultiplyTextureMatrix(var ATexture: TMaterialTextureStage; const ARegisters: array of Integer);
  public
    constructor Create(const ARegisters: TMaterialRegisterTable; const AExpressions: TMaterialExpressionParser;
      const ANamer: IMaterialImageNamer; const AFinder: IDeclFinder; const ALog: IIdLibLog;
      const AMaterialName: AnsiString; const AOptions: TMaterialOptions);
    /// <summary>
    ///   ParseStage: the open brace has been read. <c>ANumStages</c> is the number of stages so far;
    ///   <c>ACoverage</c> becomes perforated by an <c>alphaTest</c>; <c>ATexgenRegisters</c> is set by
    ///   <c>texGen wobbleSky</c>. False when the stage had an error (the material is defaulted) and must not be
    ///   counted.
    /// </summary>
    function ParseStage(const ASource: TIdLexer; const ADefaultRepeat: TMaterialTextureRepeat;
      const ANumStages: Integer; var ACoverage: TMaterialCoverage; var ATexgenRegisters: TMaterialTexgenRegisters;
      out AStage: TMaterialStage): Boolean;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Material.BlendModes;

const
  // the matrix of a texture: the rows of the 2x3 texture matrix as six registers
  MATRIX_SIZE = 6;

{ TMaterialStageParser }

constructor TMaterialStageParser.Create(const ARegisters: TMaterialRegisterTable;
  const AExpressions: TMaterialExpressionParser; const ANamer: IMaterialImageNamer;
  const AFinder: IDeclFinder; const ALog: IIdLibLog; const AMaterialName: AnsiString;
  const AOptions: TMaterialOptions);
begin
  inherited Create;
  FRegisters := ARegisters;
  FExpressions := AExpressions;
  FNamer := ANamer;
  FFinder := AFinder;
  FLog := ALog;
  FMaterialName := AMaterialName;
  FOptions := AOptions;
end;

procedure TMaterialStageParser.Warn(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AMessage);
end;

procedure TMaterialStageParser.ClearStage(var AStage: TMaterialStage);
var
  LIndex: Integer;
begin
  AStage.DrawStateBits := 0;
  AStage.ConditionRegister := FRegisters.GetConstant(1);
  for LIndex := 0 to 3 do
    AStage.ColorRegisters[LIndex] := FRegisters.GetConstant(1);
end;

procedure TMaterialStageParser.ParseBlend(const ASource: TIdLexer; var AStage: TMaterialStage);
var
  LToken: TIdToken;
  LSourceBlend, LDestinationBlend: Integer;
begin
  LToken := TIdToken.Create;
  if not ASource.ReadToken(LToken) then
    Exit;

  // blending combinations
  if TIdStrings.Icmp(LToken.Text, 'blend') = 0 then
  begin
    AStage.DrawStateBits := GLS_SRCBLEND_SRC_ALPHA or GLS_DSTBLEND_ONE_MINUS_SRC_ALPHA;
    Exit;
  end;
  if TIdStrings.Icmp(LToken.Text, 'add') = 0 then
  begin
    AStage.DrawStateBits := GLS_SRCBLEND_ONE or GLS_DSTBLEND_ONE;
    Exit;
  end;
  if (TIdStrings.Icmp(LToken.Text, 'filter') = 0) or (TIdStrings.Icmp(LToken.Text, 'modulate') = 0) then
  begin
    AStage.DrawStateBits := GLS_SRCBLEND_DST_COLOR or GLS_DSTBLEND_ZERO;
    Exit;
  end;
  if TIdStrings.Icmp(LToken.Text, 'none') = 0 then
  begin
    // none is used when defining an alpha mask that doesn't draw
    AStage.DrawStateBits := GLS_SRCBLEND_ZERO or GLS_DSTBLEND_ONE;
    Exit;
  end;
  if TIdStrings.Icmp(LToken.Text, 'bumpmap') = 0 then
  begin
    AStage.Lighting := TMaterialLighting.Bump;
    Exit;
  end;
  if TIdStrings.Icmp(LToken.Text, 'diffusemap') = 0 then
  begin
    AStage.Lighting := TMaterialLighting.Diffuse;
    Exit;
  end;
  if TIdStrings.Icmp(LToken.Text, 'specularmap') = 0 then
  begin
    AStage.Lighting := TMaterialLighting.Specular;
    Exit;
  end;

  if not TMaterialBlendModes.TryGetSource(LToken.Text, LSourceBlend) then
  begin
    Warn(Format('unknown blend mode ''%s'' in material ''%s''', [string(LToken.Text), string(FMaterialName)]));
    FRegisters.MarkDefaulted;
  end;

  FExpressions.MatchToken(ASource, ',');
  if not ASource.ReadToken(LToken) then
    Exit;
  if not TMaterialBlendModes.TryGetDestination(LToken.Text, LDestinationBlend) then
  begin
    Warn(Format('unknown blend mode ''%s'' in material ''%s''', [string(LToken.Text), string(FMaterialName)]));
    FRegisters.MarkDefaulted;
  end;

  AStage.DrawStateBits := LSourceBlend or LDestinationBlend;
end;

procedure TMaterialStageParser.ParseVertexParm(const ASource: TIdLexer; var ANewStage: TMaterialNewStage);
var
  LToken: TIdToken;
  LParm, LIndex: Integer;
begin
  LToken := TIdToken.Create;
  ASource.ReadTokenOnLine(LToken);
  LParm := LToken.GetIntValue;
  if (not TIdStrings.IsNumeric(LToken.Text)) or (LParm < 0) or (LParm >= MAX_VERTEX_PARMS) then
  begin
    Warn('bad vertexParm number'#10);
    FRegisters.MarkDefaulted;
    Exit;
  end;
  if LParm >= ANewStage.NumVertexParms then
    ANewStage.NumVertexParms := LParm + 1;

  ANewStage.VertexParms[LParm][0] := FExpressions.ParseExpression(ASource);

  ASource.ReadTokenOnLine(LToken);
  if (LToken.Text = '') or (TIdStrings.Icmp(LToken.Text, ',') <> 0) then
  begin
    for LIndex := 1 to 3 do
      ANewStage.VertexParms[LParm][LIndex] := ANewStage.VertexParms[LParm][0];
    Exit;
  end;

  ANewStage.VertexParms[LParm][1] := FExpressions.ParseExpression(ASource);

  ASource.ReadTokenOnLine(LToken);
  if (LToken.Text = '') or (TIdStrings.Icmp(LToken.Text, ',') <> 0) then
  begin
    ANewStage.VertexParms[LParm][2] := FRegisters.GetConstant(0);
    ANewStage.VertexParms[LParm][3] := FRegisters.GetConstant(1);
    Exit;
  end;

  ANewStage.VertexParms[LParm][2] := FExpressions.ParseExpression(ASource);

  ASource.ReadTokenOnLine(LToken);
  if (LToken.Text = '') or (TIdStrings.Icmp(LToken.Text, ',') <> 0) then
  begin
    ANewStage.VertexParms[LParm][3] := FRegisters.GetConstant(1);
    Exit;
  end;

  ANewStage.VertexParms[LParm][3] := FExpressions.ParseExpression(ASource);
end;

procedure TMaterialStageParser.ParseFragmentMap(const ASource: TIdLexer; var ANewStage: TMaterialNewStage);
var
  LToken: TIdToken;
  LUnit: Integer;
  LImage: TMaterialImageReference;
begin
  LImage := Default(TMaterialImageReference);
  LImage.Filter := TMaterialTextureFilter.Default;
  LImage.RepeatMode := TMaterialTextureRepeat.Repeated;
  LImage.Depth := TMaterialTextureDepth.Default;
  LImage.AllowPicmip := True;
  LImage.CubeMap := TMaterialCubeMap.Flat2D;

  LToken := TIdToken.Create;
  ASource.ReadTokenOnLine(LToken);
  LUnit := LToken.GetIntValue;
  if (not TIdStrings.IsNumeric(LToken.Text)) or (LUnit < 0) or (LUnit >= MAX_FRAGMENT_IMAGES) then
  begin
    Warn('bad fragmentMap number'#10);
    FRegisters.MarkDefaulted;
    Exit;
  end;

  // unit 1 is the normal map.. make sure it gets flagged as the proper depth
  if LUnit = 1 then
    LImage.Depth := TMaterialTextureDepth.Bump;

  if LUnit >= ANewStage.NumFragmentImages then
    ANewStage.NumFragmentImages := LUnit + 1;

  while True do
  begin
    ASource.ReadTokenOnLine(LToken);

    if TIdStrings.Icmp(LToken.Text, 'cubeMap') = 0 then
      LImage.CubeMap := TMaterialCubeMap.Native
    else if TIdStrings.Icmp(LToken.Text, 'cameraCubeMap') = 0 then
      LImage.CubeMap := TMaterialCubeMap.Camera
    else if TIdStrings.Icmp(LToken.Text, 'nearest') = 0 then
      LImage.Filter := TMaterialTextureFilter.Nearest
    else if TIdStrings.Icmp(LToken.Text, 'linear') = 0 then
      LImage.Filter := TMaterialTextureFilter.Linear
    else if TIdStrings.Icmp(LToken.Text, 'clamp') = 0 then
      LImage.RepeatMode := TMaterialTextureRepeat.Clamp
    else if TIdStrings.Icmp(LToken.Text, 'noclamp') = 0 then
      LImage.RepeatMode := TMaterialTextureRepeat.Repeated
    else if TIdStrings.Icmp(LToken.Text, 'zeroclamp') = 0 then
      LImage.RepeatMode := TMaterialTextureRepeat.ClampToZero
    else if TIdStrings.Icmp(LToken.Text, 'alphazeroclamp') = 0 then
      LImage.RepeatMode := TMaterialTextureRepeat.ClampToZeroAlpha
    else if TIdStrings.Icmp(LToken.Text, 'forceHighQuality') = 0 then
      LImage.Depth := TMaterialTextureDepth.HighQuality
    else if (TIdStrings.Icmp(LToken.Text, 'uncompressed') = 0) or (TIdStrings.Icmp(LToken.Text, 'highquality') = 0) then
    begin
      if not FOptions.IgnoreHighQuality then
        LImage.Depth := TMaterialTextureDepth.HighQuality;
    end
    else if TIdStrings.Icmp(LToken.Text, 'nopicmip') = 0 then
      LImage.AllowPicmip := False
    else
    begin
      // assume anything else is the image name
      ASource.UnreadToken(LToken);
      Break;
    end;
  end;
  LImage.Name := FNamer.ParsePastImageProgram(ASource);
  ANewStage.FragmentImages[LUnit] := LImage;
end;

procedure TMaterialStageParser.MultiplyTextureMatrix(var ATexture: TMaterialTextureStage;
  const ARegisters: array of Integer);
var
  LOld: TMaterialTextureMatrix;
  LNew: TMaterialTextureMatrix;
  LRow, LColumn, LFirst, LSecond: Integer;

  function Mul(const AA, AB: Integer): Integer;
  begin
    Result := FRegisters.EmitOp(AA, AB, TMaterialOpType.Multiply);
  end;

  function Sum(const AA, AB: Integer): Integer;
  begin
    Result := FRegisters.EmitOp(AA, AB, TMaterialOpType.Add);
  end;

  function R(const ARow, AColumn: Integer): Integer;
  begin
    Result := ARegisters[ARow * 3 + AColumn];
  end;

begin
  if not ATexture.HasMatrix then
  begin
    ATexture.HasMatrix := True;
    for LRow := 0 to 1 do
      for LColumn := 0 to 2 do
        ATexture.Matrix[LRow][LColumn] := R(LRow, LColumn);
    Exit;
  end;

  LOld := ATexture.Matrix;

  // multiply the two matrices; the operations are emitted in the order of the original (row 0 then row 1,
  // column 0, 1, 2, and for each its inner operations left to right)
  for LRow := 0 to 1 do
    for LColumn := 0 to 2 do
    begin
      LFirst := Mul(LOld[LRow][0], R(0, LColumn));
      LSecond := Mul(LOld[LRow][1], R(1, LColumn));
      LNew[LRow][LColumn] := Sum(LFirst, LSecond);
      if LColumn = 2 then
        LNew[LRow][LColumn] := Sum(LNew[LRow][LColumn], LOld[LRow][2]);
    end;
  ATexture.Matrix := LNew;
end;

function TMaterialStageParser.ParseStage(const ASource: TIdLexer; const ADefaultRepeat: TMaterialTextureRepeat;
  const ANumStages: Integer; var ACoverage: TMaterialCoverage; var ATexgenRegisters: TMaterialTexgenRegisters;
  out AStage: TMaterialStage): Boolean;
var
  LToken: TIdToken;
  LFilter: TMaterialTextureFilter;
  LRepeat: TMaterialTextureRepeat;
  LDepth: TMaterialTextureDepth;
  LCubeMap: TMaterialCubeMap;
  LAllowPicmip: Boolean;
  LImageName: AnsiString;
  LA, LB, LSin, LCos: Integer;
  LLoop: Boolean;
  LTable: IDecl;
  LMatrix: array[0..MATRIX_SIZE - 1] of Integer;
  LHalf, LTemp, LTemp2: Integer;

  function C(const AValue: Single): Integer;
  begin
    Result := FRegisters.GetConstant(AValue);
  end;

  function E(const AA, AB: Integer; const AOpType: TMaterialOpType): Integer;
  begin
    Result := FRegisters.EmitOp(AA, AB, AOpType);
  end;

  function IsWord(const AWord: AnsiString): Boolean;
  begin
    Result := TIdStrings.Icmp(LToken.Text, AWord) = 0;
  end;

begin
  AStage := Default(TMaterialStage);
  Result := False;

  if ANumStages >= MAX_SHADER_STAGES then
  begin
    FRegisters.MarkDefaulted;
    Warn(Format('material ''%s'' exceeded %d stages', [string(FMaterialName), MAX_SHADER_STAGES]));
    // the original goes on writing past the end of its stage array; the material is defaulted anyway
    Exit;
  end;

  LFilter := TMaterialTextureFilter.Default;
  LRepeat := ADefaultRepeat;
  LDepth := TMaterialTextureDepth.Default;
  LAllowPicmip := True;
  LCubeMap := TMaterialCubeMap.Flat2D;
  LImageName := '';
  LToken := TIdToken.Create;

  ClearStage(AStage);

  while True do
  begin
    // we have a parse error
    if FRegisters.Defaulted then
      Exit;
    if not ASource.ExpectAnyToken(LToken) then
    begin
      FRegisters.MarkDefaulted;
      Exit;
    end;

    // the close brace for the entire material ends the draw block
    if LToken.IsText('}') then
      Break;

    // stage naming in the material editor
    if IsWord('name') then
    begin
      ASource.SkipRestOfLine;
      Continue;
    end;

    // image options
    if IsWord('blend') then
    begin
      ParseBlend(ASource, AStage);
      Continue;
    end;

    if IsWord('map') then
    begin
      LImageName := FNamer.ParsePastImageProgram(ASource);
      Continue;
    end;

    if IsWord('remoteRenderMap') then
    begin
      AStage.Texture.Dynamic := TMaterialDynamicImage.RemoteRender;
      AStage.Texture.Width := ASource.ParseInt;
      AStage.Texture.Height := ASource.ParseInt;
      Continue;
    end;

    if IsWord('mirrorRenderMap') then
    begin
      AStage.Texture.Dynamic := TMaterialDynamicImage.MirrorRender;
      AStage.Texture.Width := ASource.ParseInt;
      AStage.Texture.Height := ASource.ParseInt;
      AStage.Texture.Texgen := TMaterialTexgen.Screen;
      Continue;
    end;

    if IsWord('xrayRenderMap') then
    begin
      AStage.Texture.Dynamic := TMaterialDynamicImage.XRayRender;
      AStage.Texture.Width := ASource.ParseInt;
      AStage.Texture.Height := ASource.ParseInt;
      AStage.Texture.Texgen := TMaterialTexgen.Screen;
      Continue;
    end;
    if IsWord('screen') then
    begin
      AStage.Texture.Texgen := TMaterialTexgen.Screen;
      Continue;
    end;
    if IsWord('screen2') then
    begin
      AStage.Texture.Texgen := TMaterialTexgen.Screen2;
      Continue;
    end;
    if IsWord('glassWarp') then
    begin
      AStage.Texture.Texgen := TMaterialTexgen.GlassWarp;
      Continue;
    end;

    if IsWord('videomap') then
    begin
      // note that videomaps will always be in clamp mode, so texture
      // coordinates had better be in the 0 to 1 range
      if not ASource.ReadToken(LToken) then
      begin
        Warn(Format('missing parameter for ''videoMap'' keyword in material ''%s''', [string(FMaterialName)]));
        Continue;
      end;
      LLoop := False;
      if TIdStrings.Icmp(LToken.Text, 'loop') = 0 then
      begin
        LLoop := True;
        if not ASource.ReadToken(LToken) then
        begin
          Warn(Format('missing parameter for ''videoMap'' keyword in material ''%s''', [string(FMaterialName)]));
          Continue;
        end;
      end;
      AStage.Texture.HasCinematic := True;
      AStage.Texture.IsSoundMap := False;
      AStage.Texture.CinematicName := LToken.Text;
      AStage.Texture.CinematicLoop := LLoop;
      Continue;
    end;

    if IsWord('soundmap') then
    begin
      if not ASource.ReadToken(LToken) then
      begin
        Warn(Format('missing parameter for ''soundmap'' keyword in material ''%s''', [string(FMaterialName)]));
        Continue;
      end;
      AStage.Texture.HasCinematic := True;
      AStage.Texture.IsSoundMap := True;
      AStage.Texture.CinematicName := LToken.Text;
      AStage.Texture.CinematicLoop := True;
      Continue;
    end;

    if IsWord('cubeMap') then
    begin
      LImageName := FNamer.ParsePastImageProgram(ASource);
      LCubeMap := TMaterialCubeMap.Native;
      Continue;
    end;

    if IsWord('cameraCubeMap') then
    begin
      LImageName := FNamer.ParsePastImageProgram(ASource);
      LCubeMap := TMaterialCubeMap.Camera;
      Continue;
    end;

    if IsWord('ignoreAlphaTest') then
    begin
      AStage.IgnoreAlphaTest := True;
      Continue;
    end;
    if IsWord('nearest') then
    begin
      LFilter := TMaterialTextureFilter.Nearest;
      Continue;
    end;
    if IsWord('linear') then
    begin
      LFilter := TMaterialTextureFilter.Linear;
      Continue;
    end;
    if IsWord('clamp') then
    begin
      LRepeat := TMaterialTextureRepeat.Clamp;
      Continue;
    end;
    if IsWord('noclamp') then
    begin
      LRepeat := TMaterialTextureRepeat.Repeated;
      Continue;
    end;
    if IsWord('zeroclamp') then
    begin
      LRepeat := TMaterialTextureRepeat.ClampToZero;
      Continue;
    end;
    if IsWord('alphazeroclamp') then
    begin
      LRepeat := TMaterialTextureRepeat.ClampToZeroAlpha;
      Continue;
    end;
    if IsWord('uncompressed') or IsWord('highquality') then
    begin
      if not FOptions.IgnoreHighQuality then
        LDepth := TMaterialTextureDepth.HighQuality;
      Continue;
    end;
    if IsWord('forceHighQuality') then
    begin
      LDepth := TMaterialTextureDepth.HighQuality;
      Continue;
    end;
    if IsWord('nopicmip') then
    begin
      LAllowPicmip := False;
      Continue;
    end;
    if IsWord('vertexColor') then
    begin
      AStage.VertexColor := TMaterialVertexColor.Modulate;
      Continue;
    end;
    if IsWord('inverseVertexColor') then
    begin
      AStage.VertexColor := TMaterialVertexColor.InverseModulate;
      Continue;
    end;

    // privatePolygonOffset
    if IsWord('privatePolygonOffset') then
    begin
      if not ASource.ReadTokenOnLine(LToken) then
      begin
        AStage.PrivatePolygonOffset := 1;
        Continue;
      end;
      // explict larger (or negative) offset
      ASource.UnreadToken(LToken);
      AStage.PrivatePolygonOffset := ASource.ParseFloat;
      Continue;
    end;

    // texture coordinate generation
    if IsWord('texGen') then
    begin
      ASource.ExpectAnyToken(LToken);
      if IsWord('normal') then
        AStage.Texture.Texgen := TMaterialTexgen.DiffuseCube
      else if IsWord('reflect') then
        AStage.Texture.Texgen := TMaterialTexgen.ReflectCube
      else if IsWord('skybox') then
        AStage.Texture.Texgen := TMaterialTexgen.SkyboxCube
      else if IsWord('wobbleSky') then
      begin
        AStage.Texture.Texgen := TMaterialTexgen.WobbleSkyCube;
        // each in its own statement: the order of the reads is the order of the text
        ATexgenRegisters[0] := FExpressions.ParseExpression(ASource);
        ATexgenRegisters[1] := FExpressions.ParseExpression(ASource);
        ATexgenRegisters[2] := FExpressions.ParseExpression(ASource);
      end
      else
      begin
        Warn(Format('bad texGen ''%s'' in material %s', [string(LToken.Text), string(FMaterialName)]));
        FRegisters.MarkDefaulted;
      end;
      Continue;
    end;
    if IsWord('scroll') or IsWord('translate') then
    begin
      LA := FExpressions.ParseExpression(ASource);
      FExpressions.MatchToken(ASource, ',');
      LB := FExpressions.ParseExpression(ASource);
      LMatrix[0] := C(1);
      LMatrix[1] := C(0);
      LMatrix[2] := LA;
      LMatrix[3] := C(0);
      LMatrix[4] := C(1);
      LMatrix[5] := LB;
      MultiplyTextureMatrix(AStage.Texture, LMatrix);
      Continue;
    end;
    if IsWord('scale') then
    begin
      LA := FExpressions.ParseExpression(ASource);
      FExpressions.MatchToken(ASource, ',');
      LB := FExpressions.ParseExpression(ASource);
      // this just scales without a centering
      LMatrix[0] := LA;
      LMatrix[1] := C(0);
      LMatrix[2] := C(0);
      LMatrix[3] := C(0);
      LMatrix[4] := LB;
      LMatrix[5] := C(0);
      MultiplyTextureMatrix(AStage.Texture, LMatrix);
      Continue;
    end;
    if IsWord('centerScale') then
    begin
      LA := FExpressions.ParseExpression(ASource);
      FExpressions.MatchToken(ASource, ',');
      LB := FExpressions.ParseExpression(ASource);
      // this subtracts 0.5, then scales, then adds 0.5
      LMatrix[0] := LA;
      LMatrix[1] := C(0);
      LHalf := C(0.5);
      LTemp := E(C(0.5), LA, TMaterialOpType.Multiply);
      LMatrix[2] := E(LHalf, LTemp, TMaterialOpType.Subtract);
      LMatrix[3] := C(0);
      LMatrix[4] := LB;
      LHalf := C(0.5);
      LTemp := E(C(0.5), LB, TMaterialOpType.Multiply);
      LMatrix[5] := E(LHalf, LTemp, TMaterialOpType.Subtract);
      MultiplyTextureMatrix(AStage.Texture, LMatrix);
      Continue;
    end;
    if IsWord('shear') then
    begin
      LA := FExpressions.ParseExpression(ASource);
      FExpressions.MatchToken(ASource, ',');
      LB := FExpressions.ParseExpression(ASource);
      // this subtracts 0.5, then shears, then adds 0.5
      LMatrix[0] := C(1);
      LMatrix[1] := LA;
      LHalf := C(-0.5);
      LMatrix[2] := E(LHalf, LA, TMaterialOpType.Multiply);
      LMatrix[3] := LB;
      LMatrix[4] := C(1);
      LHalf := C(-0.5);
      LMatrix[5] := E(LHalf, LB, TMaterialOpType.Multiply);
      MultiplyTextureMatrix(AStage.Texture, LMatrix);
      Continue;
    end;
    if IsWord('rotate') then
    begin
      // in cycles
      LA := FExpressions.ParseExpression(ASource);

      LTable := FFinder.FindType(DECL_TABLE, 'sinTable', False);
      if not Assigned(LTable) then
      begin
        Warn('no sinTable for rotate defined');
        FRegisters.MarkDefaulted;
        Exit;
      end;
      LSin := E(LTable.GetIndex, LA, TMaterialOpType.Table);

      LTable := FFinder.FindType(DECL_TABLE, 'cosTable', False);
      if not Assigned(LTable) then
      begin
        Warn('no cosTable for rotate defined');
        FRegisters.MarkDefaulted;
        Exit;
      end;
      LCos := E(LTable.GetIndex, LA, TMaterialOpType.Table);

      // this subtracts 0.5, then rotates, then adds 0.5; the registers of the matrix are made in the order
      // of the original (m00, m01, m02, m10, m11, m12)
      // (every call is a statement of its own: the order of the arguments of a call is not defined in Delphi)
      LMatrix[0] := LCos;
      LHalf := C(0);
      LMatrix[1] := E(LHalf, LSin, TMaterialOpType.Subtract);
      LHalf := C(-0.5);
      LTemp := E(LHalf, LCos, TMaterialOpType.Multiply);
      LHalf := C(0.5);
      LTemp2 := E(LHalf, LSin, TMaterialOpType.Multiply);
      LTemp := E(LTemp, LTemp2, TMaterialOpType.Add);
      LHalf := C(0.5);
      LMatrix[2] := E(LTemp, LHalf, TMaterialOpType.Add);
      LMatrix[3] := LSin;
      LMatrix[4] := LCos;
      LHalf := C(-0.5);
      LTemp := E(LHalf, LSin, TMaterialOpType.Multiply);
      LHalf := C(-0.5);
      LTemp2 := E(LHalf, LCos, TMaterialOpType.Multiply);
      LTemp := E(LTemp, LTemp2, TMaterialOpType.Add);
      LHalf := C(0.5);
      LMatrix[5] := E(LTemp, LHalf, TMaterialOpType.Add);
      MultiplyTextureMatrix(AStage.Texture, LMatrix);
      Continue;
    end;

    // color mask options
    if IsWord('maskRed') then
    begin
      AStage.DrawStateBits := AStage.DrawStateBits or GLS_REDMASK;
      Continue;
    end;
    if IsWord('maskGreen') then
    begin
      AStage.DrawStateBits := AStage.DrawStateBits or GLS_GREENMASK;
      Continue;
    end;
    if IsWord('maskBlue') then
    begin
      AStage.DrawStateBits := AStage.DrawStateBits or GLS_BLUEMASK;
      Continue;
    end;
    if IsWord('maskAlpha') then
    begin
      AStage.DrawStateBits := AStage.DrawStateBits or GLS_ALPHAMASK;
      Continue;
    end;
    if IsWord('maskColor') then
    begin
      AStage.DrawStateBits := AStage.DrawStateBits or GLS_COLORMASK;
      Continue;
    end;
    if IsWord('maskDepth') then
    begin
      AStage.DrawStateBits := AStage.DrawStateBits or GLS_DEPTHMASK;
      Continue;
    end;
    if IsWord('alphaTest') then
    begin
      AStage.HasAlphaTest := True;
      AStage.AlphaTestRegister := FExpressions.ParseExpression(ASource);
      ACoverage := TMaterialCoverage.Perforated;
      Continue;
    end;

    // shorthand for 2D modulated
    if IsWord('colored') then
    begin
      AStage.ColorRegisters[0] := EXP_REG_PARM0;
      AStage.ColorRegisters[1] := EXP_REG_PARM1;
      AStage.ColorRegisters[2] := EXP_REG_PARM2;
      AStage.ColorRegisters[3] := EXP_REG_PARM3;
      FRegisters.RegistersAreConstant := False;
      Continue;
    end;

    if IsWord('color') then
    begin
      AStage.ColorRegisters[0] := FExpressions.ParseExpression(ASource);
      FExpressions.MatchToken(ASource, ',');
      AStage.ColorRegisters[1] := FExpressions.ParseExpression(ASource);
      FExpressions.MatchToken(ASource, ',');
      AStage.ColorRegisters[2] := FExpressions.ParseExpression(ASource);
      FExpressions.MatchToken(ASource, ',');
      AStage.ColorRegisters[3] := FExpressions.ParseExpression(ASource);
      Continue;
    end;
    if IsWord('red') then
    begin
      AStage.ColorRegisters[0] := FExpressions.ParseExpression(ASource);
      Continue;
    end;
    if IsWord('green') then
    begin
      AStage.ColorRegisters[1] := FExpressions.ParseExpression(ASource);
      Continue;
    end;
    if IsWord('blue') then
    begin
      AStage.ColorRegisters[2] := FExpressions.ParseExpression(ASource);
      Continue;
    end;
    if IsWord('alpha') then
    begin
      AStage.ColorRegisters[3] := FExpressions.ParseExpression(ASource);
      Continue;
    end;
    if IsWord('rgb') then
    begin
      LA := FExpressions.ParseExpression(ASource);
      AStage.ColorRegisters[0] := LA;
      AStage.ColorRegisters[1] := LA;
      AStage.ColorRegisters[2] := LA;
      Continue;
    end;
    if IsWord('rgba') then
    begin
      LA := FExpressions.ParseExpression(ASource);
      AStage.ColorRegisters[0] := LA;
      AStage.ColorRegisters[1] := LA;
      AStage.ColorRegisters[2] := LA;
      AStage.ColorRegisters[3] := LA;
      Continue;
    end;

    if IsWord('if') then
    begin
      AStage.ConditionRegister := FExpressions.ParseExpression(ASource);
      Continue;
    end;
    if IsWord('program') then
    begin
      if ASource.ReadTokenOnLine(LToken) then
      begin
        AStage.NewStage.VertexProgram := LToken.Text;
        AStage.NewStage.FragmentProgram := LToken.Text;
      end;
      Continue;
    end;
    if IsWord('fragmentProgram') then
    begin
      if ASource.ReadTokenOnLine(LToken) then
        AStage.NewStage.FragmentProgram := LToken.Text;
      Continue;
    end;
    if IsWord('vertexProgram') then
    begin
      if ASource.ReadTokenOnLine(LToken) then
        AStage.NewStage.VertexProgram := LToken.Text;
      Continue;
    end;
    if IsWord('megaTexture') then
    begin
      if ASource.ReadTokenOnLine(LToken) then
      begin
        // the mega file is not opened here: it is named
        AStage.NewStage.MegaTexture := LToken.Text;
        AStage.NewStage.VertexProgram := 'megaTexture.vfp';
        AStage.NewStage.FragmentProgram := 'megaTexture.vfp';
        Continue;
      end;
      // the original falls through to the "unknown token" error when the file name is missing
    end;

    if IsWord('vertexParm') then
    begin
      ParseVertexParm(ASource, AStage.NewStage);
      Continue;
    end;

    if IsWord('fragmentMap') then
    begin
      ParseFragmentMap(ASource, AStage.NewStage);
      Continue;
    end;

    Warn(Format('unknown token ''%s'' in material ''%s''', [string(LToken.Text), string(FMaterialName)]));
    FRegisters.MarkDefaulted;
    Exit;
  end;

  // if we are using newStage, keep it
  AStage.HasNewStage := (AStage.NewStage.FragmentProgram <> '') or (AStage.NewStage.VertexProgram <> '');
  if not AStage.HasNewStage then
    AStage.NewStage := Default(TMaterialNewStage);

  // select a compressed depth based on what the stage is
  if LDepth = TMaterialTextureDepth.Default then
    case AStage.Lighting of
      TMaterialLighting.Bump:
        LDepth := TMaterialTextureDepth.Bump;
      TMaterialLighting.Diffuse:
        LDepth := TMaterialTextureDepth.Diffuse;
      TMaterialLighting.Specular:
        LDepth := TMaterialTextureDepth.Specular;
    end;

  // the image with all the parms we parsed
  AStage.Texture.Image.Filter := LFilter;
  AStage.Texture.Image.RepeatMode := LRepeat;
  AStage.Texture.Image.Depth := LDepth;
  AStage.Texture.Image.AllowPicmip := LAllowPicmip;
  AStage.Texture.Image.CubeMap := LCubeMap;
  if LImageName <> '' then
  begin
    AStage.Texture.HasImage := True;
    AStage.Texture.Image.Name := LImageName;
  end
  else if (not AStage.Texture.HasCinematic) and (AStage.Texture.Dynamic = TMaterialDynamicImage.Static)
    and (not AStage.HasNewStage) then
  begin
    Warn(Format('material ''%s'' had stage with no image', [string(FMaterialName)]));
    AStage.Texture.HasImage := True;
    AStage.Texture.Image.Name := '_default';
  end;

  // successfully parsed a stage
  Result := True;
end;

end.
