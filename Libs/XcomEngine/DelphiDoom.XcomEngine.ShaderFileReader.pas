{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - reader of the OpenGL shader files          }
{  Port of the first half of OpenGL::set_shader of OpenXcom (Engine\OpenGL.cpp):}
{  the document of the file, without OpenGL                                     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.ShaderFileReader;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Shader.Types;

type
  /// <summary>
  ///   Reads a .OpenGL.shader file: a YAML document with "language" (it must be there), "linear" (false when it is
  ///   missing), "fragment" and "vertex" (the GLSL programs, empty when missing). The files of OpenXcom still have
  ///   their old XML header, as YAML comments. A text that is not such a document is a line of the log and false,
  ///   as the exception of yaml-cpp in the C++; a language that is not GLSL is a line of the log and a source that
  ///   has nothing to compile
  /// </summary>
  TXcomShaderFileReader = class
  strict private
    FParser: IYamlParser;
    FLog: IXcomLog;
    procedure Log(const AMessage: string);
    class function TextOf(const ADocument: IYamlNode; const AKey: TYamlText): RawByteString; static;
  public
    /// <param name="ALog">Where the problems of a file go; nil for nowhere</param>
    constructor Create(const AParser: IYamlParser; const ALog: IXcomLog = nil);
    /// <param name="AName">The name of the file, for the log</param>
    function TryRead(const AName: string; const ABytes: TBytes; out ASource: TXcomShaderSource): Boolean;
  end;

implementation

const
  SLogError = 'ERROR';
  SGlsl = 'GLSL';
  SNoLanguage = '%s: the shader file has no "language"';
  SBadFile = '%s: %s';
  SUnexpectedLanguage = 'Unexpected shader language "%s"';

constructor TXcomShaderFileReader.Create(const AParser: IYamlParser; const ALog: IXcomLog);
begin
  inherited Create;
  if not Assigned(AParser) then
    raise EArgumentNilException.Create('AParser');
  FParser := AParser;
  FLog := ALog;
end;

procedure TXcomShaderFileReader.Log(const AMessage: string);
begin
  if Assigned(FLog) then
    FLog.Write(SLogError, AMessage);
end;

class function TXcomShaderFileReader.TextOf(const ADocument: IYamlNode; const AKey: TYamlText): RawByteString;
var
  LNode: IYamlNode;
begin
  // as<std::string>(""): empty when the key is missing or is not a scalar
  Result := '';
  LNode := ADocument.Find(AKey);
  if (LNode <> nil) and LNode.IsDefined and LNode.IsScalar then
    Result := LNode.AsString;
end;

function TXcomShaderFileReader.TryRead(const AName: string; const ABytes: TBytes;
  out ASource: TXcomShaderSource): Boolean;
var
  LDocument: IYamlNode;
  LNode: IYamlNode;
begin
  ASource := Default(TXcomShaderSource);
  Result := False;
  try
    LDocument := FParser.Load(ABytes);
    if (LDocument = nil) or not LDocument.IsMap then
    begin
      Log(Format(SNoLanguage, [AName]));
      Exit;
    end;
    LNode := LDocument.Find(TYamlText('language'));
    if (LNode = nil) or (not LNode.IsDefined) or not LNode.IsScalar then
    begin
      Log(Format(SNoLanguage, [AName]));
      Exit;
    end;
    ASource.Language := YamlTextToString(LNode.AsString);
    ASource.IsGlsl := ASource.Language = SGlsl;
    // some shaders want the linear filter on the texture and some do not
    LNode := LDocument.Find(TYamlText('linear'));
    if (LNode <> nil) and LNode.IsDefined and LNode.IsScalar then
      ASource.Linear := LNode.AsBoolean(False);
    if ASource.IsGlsl then
    begin
      ASource.Fragment := TextOf(LDocument, 'fragment');
      ASource.Vertex := TextOf(LDocument, 'vertex');
    end
    else
      Log(Format(SUnexpectedLanguage, [ASource.Language]));
    Result := True;
  except
    on E: EYamlException do
    begin
      ASource := Default(TXcomShaderSource);
      Log(Format(SBadFile, [AName, E.Message]));
    end;
  end;
end;

end.
