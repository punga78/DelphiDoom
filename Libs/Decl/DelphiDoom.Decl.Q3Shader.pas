{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - TDeclQ3Shader, the declaration "shader"     }
{                                                                              }
{  The reading of one shader of renderer\tr_shader.c of Quake III Arena (id    }
{  Software, GPL v2 or later): FindShaderInShaderText (the name), ParseShader  }
{  and FinishShader (R_FindShader, the data only). Based on the Quake III      }
{  Arena GPL Source Code (id Software).                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader;

interface

uses
  System.SysUtils, DelphiDoom.Decl.Base, DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Intf;

type
  /// <summary>
  ///   A shader of a <c>.shader</c> file. The text is the whole declaration, "name { ... }" (a default text
  ///   has no name). A text with an error is not replaced by the default one: like the original, the data that
  ///   were read stay and <c>IsDefaultShader</c> is true.
  /// </summary>
  TDeclQ3Shader = class(TDecl, IDeclQ3Shader)
  strict private
    FData: TQ3ShaderData;
    FOptions: TQ3ShaderOptions;
  public
    constructor Create(const AOptions: TQ3ShaderOptions);
    function GetData: TQ3ShaderData;
    function GetStageCount: Integer;
    function GetStage(const AIndex: Integer): TQ3ShaderStage;
    function IsDefaultShader: Boolean;
    function IsExplicitlyDefined: Boolean;
    /// <summary>
    ///   No text for the name: the shader R_FindShader makes from an image with that name, for
    ///   <c>LIGHTMAP_NONE</c> (one stage, the image, lighting at the vertexes). The image is not looked for.
    /// </summary>
    function SetDefaultText: Boolean; override;
    /// <summary>An empty shader: it has no stage and the parse says it is not defined</summary>
    function DefaultDefinition: AnsiString; override;
    function Parse(const AText: AnsiString): Boolean; override;
    procedure FreeData; override;
    function Size: NativeInt; override;
  end;

implementation

uses
  DelphiDoom.Decl.Q3Shader.Context, DelphiDoom.Decl.Q3Shader.Tokenizer, DelphiDoom.Decl.Q3Shader.Parser,
  DelphiDoom.Decl.Q3Shader.Finisher;

const
  SDroppedFrame = 'ERROR: %s';

{ TDeclQ3Shader }

constructor TDeclQ3Shader.Create(const AOptions: TQ3ShaderOptions);
begin
  inherited Create;
  FOptions := AOptions;
end;

function TDeclQ3Shader.GetData: TQ3ShaderData;
begin
  Result := FData;
end;

function TDeclQ3Shader.GetStageCount: Integer;
begin
  Result := FData.NumUnfoggedPasses;
end;

function TDeclQ3Shader.GetStage(const AIndex: Integer): TQ3ShaderStage;
begin
  if (AIndex < 0) or (AIndex >= FData.NumUnfoggedPasses) then
    raise ERangeError.CreateFmt('Shader stage %d out of range', [AIndex]);
  Result := FData.Stages[AIndex];
end;

function TDeclQ3Shader.IsDefaultShader: Boolean;
begin
  Result := FData.DefaultShader;
end;

function TDeclQ3Shader.IsExplicitlyDefined: Boolean;
begin
  Result := FData.ExplicitlyDefined;
end;

function TDeclQ3Shader.SetDefaultText: Boolean;
var
  LImageName: AnsiString;
  LIndex: Integer;
  LHasExtension: Boolean;
begin
  // COM_DefaultExtension(fileName, ".tga"): added if there is no '.' after the last '/'
  LImageName := GetName;
  LHasExtension := False;
  for LIndex := Length(LImageName) downto 1 do
  begin
    if LImageName[LIndex] = '.' then
    begin
      LHasExtension := True;
      Break;
    end;
    if LImageName[LIndex] = '/' then
      Break;
  end;
  if not LHasExtension then
    LImageName := LImageName + '.tga';
  SetText(AnsiString(Format('%s'#10'{'#10'{'#10'map "%s"'#10'rgbGen lightingDiffuse'#10'}'#10'}'#10,
    [string(GetName), string(LImageName)])));
  Result := True;
end;

function TDeclQ3Shader.DefaultDefinition: AnsiString;
begin
  Result := '{ }';
end;

function TDeclQ3Shader.Parse(const AText: AnsiString): Boolean;
var
  LContext: TQ3ShaderContext;
  LTokenizer: TQ3ShaderTokenizer;
  LProbe: AnsiString;
  LParsed, LDropped: Boolean;
begin
  LContext := TQ3ShaderContext.Create(GetName, GetLog, FOptions);
  try
    // FindShaderInShaderText leaves the text after the name: the first word is the name, unless the text
    // is a default one that starts with the brace
    LTokenizer := TQ3ShaderTokenizer.Create(AText);
    try
      LProbe := LTokenizer.ParseExt(True);
    finally
      LTokenizer.Free;
    end;
    LTokenizer := TQ3ShaderTokenizer.Create(AText);
    try
      if (LProbe = '') or (LProbe[1] <> '{') then
        LTokenizer.ParseExt(True);
      LDropped := False;
      try
        LParsed := TQ3ShaderParser.ParseShader(LContext, LTokenizer);
      except
        on E: EDeclQ3ShaderException do
        begin
          LContext.Warn(SDroppedFrame, [E.Message]);
          LParsed := False;
          LDropped := True;
        end;
      end;
    finally
      LTokenizer.Free;
    end;
    // had errors, so use default shader
    if not LParsed then
      LContext.Data.DefaultShader := True;
    if not LDropped then
      TQ3ShaderFinisher.FinishShader(LContext);
    FData := LContext.Data^;
  finally
    LContext.Free;
  end;
  Result := LParsed;
end;

procedure TDeclQ3Shader.FreeData;
begin
  FData := Default(TQ3ShaderData);
end;

function TDeclQ3Shader.Size: NativeInt;
begin
  Result := SizeOf(TDeclQ3Shader) + SizeOf(TQ3ShaderData);
end;

end.
