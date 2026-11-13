{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - deformVertexes                              }
{                                                                              }
{  Port of ParseDeform of renderer\tr_shader.c of Quake III Arena (id          }
{  Software, GPL v2 or later). Based on the Quake III Arena GPL Source Code    }
{  (id Software).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.DeformParser;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Context, DelphiDoom.Decl.Q3Shader.Tokenizer;

type
  /// <summary>The words after <c>deformVertexes</c></summary>
  TQ3ShaderDeformParser = class sealed
  strict private
    class function ReadNumber(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer;
      const AMessage: string; var AValue: Single): Boolean; static;
  public
    /// <summary>
    ///   ParseDeform: warnings only, no error. The deform is counted before its words are read, so a line
    ///   cut short leaves a deform of type none; the fourth one in a shader is a warning and is dropped.
    /// </summary>
    class procedure ParseDeform(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer); static;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Decl.Q3Shader.ValueParser;

const
  SMissingDeformParm = 'missing deformVertexes parm in shader ''%s''';
  SMissingBulgeParm = 'missing deformVertexes bulge parm in shader ''%s''';

{ TQ3ShaderDeformParser }

class function TQ3ShaderDeformParser.ReadNumber(const AContext: TQ3ShaderContext;
  const ATokenizer: TQ3ShaderTokenizer; const AMessage: string; var AValue: Single): Boolean;
var
  LToken: AnsiString;
begin
  LToken := ATokenizer.ParseExt(False);
  if LToken = '' then
  begin
    AContext.Warn(AMessage, [AContext.Data.Name]);
    Exit(False);
  end;
  AValue := TIdCNumbers.Atof(LToken);
  Result := True;
end;

class procedure TQ3ShaderDeformParser.ParseDeform(const AContext: TQ3ShaderContext;
  const ATokenizer: TQ3ShaderTokenizer);
var
  LToken: AnsiString;
  LDeform: ^TQ3DeformStage;
  LNumber, LIndex: Integer;
  LValue: Double;
begin
  LToken := ATokenizer.ParseExt(False);
  if LToken = '' then
  begin
    AContext.Warn(SMissingDeformParm, [AContext.Data.Name]);
    Exit;
  end;
  if AContext.Data.NumDeforms = Q3_MAX_SHADER_DEFORMS then
  begin
    AContext.Warn('MAX_SHADER_DEFORMS in ''%s''', [AContext.Data.Name]);
    Exit;
  end;
  LDeform := @AContext.Data.Deforms[AContext.Data.NumDeforms];
  Inc(AContext.Data.NumDeforms);

  if TIdStrings.Icmp(LToken, 'projectionShadow') = 0 then
  begin
    LDeform.Deformation := dfProjectionShadow;
    Exit;
  end;
  if TIdStrings.Icmp(LToken, 'autosprite') = 0 then
  begin
    LDeform.Deformation := dfAutoSprite;
    Exit;
  end;
  if TIdStrings.Icmp(LToken, 'autosprite2') = 0 then
  begin
    LDeform.Deformation := dfAutoSprite2;
    Exit;
  end;
  if TIdStrings.Icmpn(LToken, 'text', 4) = 0 then
  begin
    // token[4] - '0'; a word that is just "text" has a zero there
    if Length(LToken) >= 5 then
      LNumber := Ord(LToken[5]) - Ord('0')
    else
      LNumber := -Ord('0');
    if (LNumber < 0) or (LNumber > 7) then
      LNumber := 0;
    LDeform.Deformation := TQ3Deform(Ord(dfText0) + LNumber);
    Exit;
  end;
  if TIdStrings.Icmp(LToken, 'bulge') = 0 then
  begin
    if not ReadNumber(AContext, ATokenizer, SMissingBulgeParm, LDeform.BulgeWidth) then
      Exit;
    if not ReadNumber(AContext, ATokenizer, SMissingBulgeParm, LDeform.BulgeHeight) then
      Exit;
    if not ReadNumber(AContext, ATokenizer, SMissingBulgeParm, LDeform.BulgeSpeed) then
      Exit;
    LDeform.Deformation := dfBulge;
    Exit;
  end;
  if TIdStrings.Icmp(LToken, 'wave') = 0 then
  begin
    LToken := ATokenizer.ParseExt(False);
    if LToken = '' then
    begin
      AContext.Warn(SMissingDeformParm, [AContext.Data.Name]);
      Exit;
    end;
    LValue := TIdCNumbers.Atof(LToken);
    if LValue <> 0 then
      LDeform.DeformationSpread := 1.0 / TIdCNumbers.Atof(LToken)
    else
    begin
      LDeform.DeformationSpread := 100.0;
      AContext.Warn('illegal div value of 0 in deformVertexes command for shader ''%s''', [AContext.Data.Name]);
    end;
    TQ3ShaderValueParser.ParseWaveForm(AContext, ATokenizer, LDeform.DeformationWave);
    LDeform.Deformation := dfWave;
    Exit;
  end;
  if TIdStrings.Icmp(LToken, 'normal') = 0 then
  begin
    if not ReadNumber(AContext, ATokenizer, SMissingDeformParm, LDeform.DeformationWave.Amplitude) then
      Exit;
    if not ReadNumber(AContext, ATokenizer, SMissingDeformParm, LDeform.DeformationWave.Frequency) then
      Exit;
    LDeform.Deformation := dfNormals;
    Exit;
  end;
  if TIdStrings.Icmp(LToken, 'move') = 0 then
  begin
    for LIndex := 0 to 2 do
      if not ReadNumber(AContext, ATokenizer, SMissingDeformParm, LDeform.MoveVector[LIndex]) then
        Exit;
    TQ3ShaderValueParser.ParseWaveForm(AContext, ATokenizer, LDeform.DeformationWave);
    LDeform.Deformation := dfMove;
    Exit;
  end;
  AContext.Warn('unknown deformVertexes subtype ''%s'' found in shader ''%s''', [LToken, AContext.Data.Name]);
end;

end.
