{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TXcomShaderFileReader (the .OpenGL.shader files)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.ShaderFileReader;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Yaml.Factory, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Shader.Types, DelphiDoom.XcomEngine.ShaderFileReader;

type
  TShaderLog = class(TInterfacedObject, IXcomLog)
  strict private
    FLines: TStrings;
  public
    constructor Create(ALines: TStrings);
    procedure Write(const ALevel, AMessage: string);
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomShaderFileReader = class
  strict private
    FLines: TStringList;
    FReader: TXcomShaderFileReader;
    function Read(const AText: string; out ASource: TXcomShaderSource): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereFragmentVertexELinear;
    [Test]
    procedure DovrebbeLeggereIlFileConLIntestazioneXmlCommentata;
    [Test]
    procedure DovrebbeDareLinearFalsoEProgrammiVuotiSeMancano;
    [Test]
    procedure DovrebbeTenereLeRigheDelProgrammaComeSonoScritte;
    [Test]
    procedure DovrebbeDareFalsoSeMancaLanguage;
    [Test]
    procedure DovrebbeDareFalsoSeVuoto;
    [Test]
    procedure DovrebbeDareFalsoEAvvisareSeNonEYaml;
    [Test]
    procedure DovrebbeAvvisareSeIlLinguaggioNonEGlsl;
    [Test]
    procedure NonDovrebbeAvvisareSeIlFileEBuono;
    [Test]
    procedure DovrebbeFunzionareSenzaLog;
    [Test]
    procedure DovrebbeRifiutareIlParserNil;
  end;

implementation

{ TShaderLog }

constructor TShaderLog.Create(ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
end;

procedure TShaderLog.Write(const ALevel, AMessage: string);
begin
  FLines.Add(ALevel + ':' + AMessage);
end;

{ TTestXcomShaderFileReader }

procedure TTestXcomShaderFileReader.Setup;
begin
  FLines := TStringList.Create;
  FReader := TXcomShaderFileReader.Create(TYamlFactory.CreateParser, TShaderLog.Create(FLines));
end;

procedure TTestXcomShaderFileReader.TearDown;
begin
  FReader.Free;
  FLines.Free;
end;

function TTestXcomShaderFileReader.Read(const AText: string; out ASource: TXcomShaderSource): Boolean;
begin
  Result := FReader.TryRead('Shaders/test.opengl.shader', TEncoding.UTF8.GetBytes(AText), ASource);
end;

procedure TTestXcomShaderFileReader.DovrebbeLeggereFragmentVertexELinear;
var
  LSource: TXcomShaderSource;
begin
  Assert.IsTrue(Read(
    'language: "GLSL"'#10 +
    'vertex: |'#10 +
    '    void main() {'#10 +
    '      gl_Position = ftransform();'#10 +
    '    }'#10 +
    'linear: true'#10 +
    'fragment: |'#10 +
    '    uniform sampler2D rubyTexture;'#10 +
    '    void main(void) { gl_FragColor = texture2D(rubyTexture, gl_TexCoord[0].xy); }'#10, LSource));
  Assert.IsTrue(LSource.IsGlsl);
  Assert.AreEqual('GLSL', LSource.Language);
  Assert.IsTrue(LSource.Linear);
  Assert.AreEqual('void main() {'#10'  gl_Position = ftransform();'#10'}'#10, string(LSource.Vertex));
  Assert.AreEqual('uniform sampler2D rubyTexture;'#10 +
    'void main(void) { gl_FragColor = texture2D(rubyTexture, gl_TexCoord[0].xy); }'#10, string(LSource.Fragment));
end;

procedure TTestXcomShaderFileReader.DovrebbeLeggereIlFileConLIntestazioneXmlCommentata;
var
  LSource: TXcomShaderSource;
begin
  // Raw.OpenGL.shader of OpenXcom: the XML of bsnes is left as a comment above the YAML
  Assert.IsTrue(Read(
    '#<!--'#13#10 +
    '#    Blank shader to allow Vsync without changing anything.'#13#10 +
    '#-->'#13#10 +
    'language: GLSL'#13#10 +
    'linear: false'#13#10 +
    'fragment: |'#13#10 +
    '        uniform sampler2D rubyTexture;'#13#10 +
    #13#10 +
    '        void main(void)'#13#10 +
    '        {'#13#10 +
    '                gl_FragColor = texture2D(rubyTexture, gl_TexCoord[0].xy);'#13#10 +
    '        }'#13#10, LSource));
  Assert.IsTrue(LSource.IsGlsl);
  Assert.IsFalse(LSource.Linear);
  Assert.AreEqual('', string(LSource.Vertex));
  Assert.IsTrue(Pos('uniform sampler2D rubyTexture;', string(LSource.Fragment)) = 1, string(LSource.Fragment));
  Assert.IsTrue(Pos('        gl_FragColor = texture2D', string(LSource.Fragment)) > 0, 'the inner indentation stays');
  Assert.AreEqual(0, FLines.Count);
end;

procedure TTestXcomShaderFileReader.DovrebbeDareLinearFalsoEProgrammiVuotiSeMancano;
var
  LSource: TXcomShaderSource;
begin
  Assert.IsTrue(Read('language: GLSL'#10, LSource));
  Assert.IsTrue(LSource.IsGlsl);
  Assert.IsFalse(LSource.Linear);
  Assert.AreEqual('', string(LSource.Fragment));
  Assert.AreEqual('', string(LSource.Vertex));
end;

procedure TTestXcomShaderFileReader.DovrebbeTenereLeRigheDelProgrammaComeSonoScritte;
var
  LSource: TXcomShaderSource;
begin
  // a "#version" line is a line of the program, not a comment of the document
  Assert.IsTrue(Read('language: GLSL'#10'vertex: |'#10'  #version 110'#10'  void main() {}'#10, LSource));
  Assert.AreEqual('#version 110'#10'void main() {}'#10, string(LSource.Vertex));
end;

procedure TTestXcomShaderFileReader.DovrebbeDareFalsoSeMancaLanguage;
var
  LSource: TXcomShaderSource;
begin
  Assert.IsFalse(Read('linear: true'#10'fragment: |'#10'  void main() {}'#10, LSource));
  Assert.AreEqual('', string(LSource.Fragment));
  Assert.AreEqual('ERROR:Shaders/test.opengl.shader: the shader file has no "language"', FLines.Text.Trim);
end;

procedure TTestXcomShaderFileReader.DovrebbeDareFalsoSeVuoto;
var
  LSource: TXcomShaderSource;
begin
  Assert.IsFalse(Read('', LSource));
  Assert.AreEqual(1, FLines.Count);
end;

procedure TTestXcomShaderFileReader.DovrebbeDareFalsoEAvvisareSeNonEYaml;
var
  LSource: TXcomShaderSource;
begin
  // the old format of bsnes: an XML document is not the document the reader wants
  Assert.IsFalse(Read('<?xml version="1.0"?>'#10'<shader language="GLSL">'#10'<fragment><![CDATA[ void main() {} ]]>' +
    '</fragment>'#10'</shader>'#10, LSource));
  Assert.IsFalse(LSource.IsGlsl);
  Assert.AreEqual(1, FLines.Count);
  Assert.IsTrue(FLines[0].StartsWith('ERROR:Shaders/test.opengl.shader'), FLines[0]);
end;

procedure TTestXcomShaderFileReader.DovrebbeAvvisareSeIlLinguaggioNonEGlsl;
var
  LSource: TXcomShaderSource;
begin
  // OpenGL::set_shader goes on with a program that has nothing in it
  Assert.IsTrue(Read('language: HLSL'#10'linear: true'#10'fragment: |'#10'  float4 main() {}'#10, LSource));
  Assert.IsFalse(LSource.IsGlsl);
  Assert.AreEqual('HLSL', LSource.Language);
  Assert.IsTrue(LSource.Linear);
  Assert.AreEqual('', string(LSource.Fragment));
  Assert.AreEqual('ERROR:Unexpected shader language "HLSL"', FLines.Text.Trim);
end;

procedure TTestXcomShaderFileReader.NonDovrebbeAvvisareSeIlFileEBuono;
var
  LSource: TXcomShaderSource;
begin
  Assert.IsTrue(Read('language: GLSL'#10'fragment: |'#10'  void main() {}'#10, LSource));
  Assert.AreEqual(0, FLines.Count);
end;

procedure TTestXcomShaderFileReader.DovrebbeFunzionareSenzaLog;
var
  LReader: TXcomShaderFileReader;
  LSource: TXcomShaderSource;
begin
  LReader := TXcomShaderFileReader.Create(TYamlFactory.CreateParser);
  try
    Assert.IsFalse(LReader.TryRead('x', TEncoding.UTF8.GetBytes('linear: true'), LSource));
  finally
    LReader.Free;
  end;
end;

procedure TTestXcomShaderFileReader.DovrebbeRifiutareIlParserNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomShaderFileReader.Create(nil);
    end, EArgumentNilException);
end;

end.
