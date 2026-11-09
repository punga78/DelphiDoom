{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - Load, LoadAll, LoadFile                          }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.Loader;

interface

uses
  System.SysUtils,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.DocumentParser,
  DelphiDoom.Yaml.Node,
  DelphiDoom.Yaml.NodeBuilder;

type
  /// <summary>YAML::Load and the others (parse.cpp)</summary>
  TYamlLoader = class(TInterfacedObject, IYamlParser)
  strict private
    FFiles: IYamlFileSource;
    class function ToBytes(const AText: TYamlText): TBytes; static;
  public
    /// <summary>AFiles is only needed for LoadFile and LoadAllFromFile (nil: they raise EYamlBadFile)</summary>
    constructor Create(const AFiles: IYamlFileSource);
    function Load(const AText: TYamlText): IYamlNode; overload;
    function Load(const ABytes: TBytes): IYamlNode; overload;
    function LoadAll(const AText: TYamlText): TArray<IYamlNode>; overload;
    function LoadAll(const ABytes: TBytes): TArray<IYamlNode>; overload;
    function LoadFile(const AFileName: string): IYamlNode;
    function LoadAllFromFile(const AFileName: string): TArray<IYamlNode>;
  end;

implementation

constructor TYamlLoader.Create(const AFiles: IYamlFileSource);
begin
  inherited Create;
  FFiles := AFiles;
end;

class function TYamlLoader.ToBytes(const AText: TYamlText): TBytes;
begin
  SetLength(Result, Length(AText));
  if Length(AText) > 0 then
    Move(AText[1], Result[0], Length(AText));
end;

function TYamlLoader.Load(const AText: TYamlText): IYamlNode;
begin
  Result := Load(ToBytes(AText));
end;

function TYamlLoader.Load(const ABytes: TBytes): IYamlNode;
var
  LParser: TYamlDocumentParser;
  LBuilder: TYamlNodeBuilder;
  LHandler: IYamlEventHandler;
begin
  LParser := TYamlDocumentParser.Create(ABytes);
  try
    LBuilder := TYamlNodeBuilder.Create;
    LHandler := LBuilder;
    if not LParser.HandleNextDocument(LHandler) then
      Exit(TYamlNode.Create);
    Result := LBuilder.Root;
  finally
    LParser.Free;
  end;
end;

function TYamlLoader.LoadAll(const AText: TYamlText): TArray<IYamlNode>;
begin
  Result := LoadAll(ToBytes(AText));
end;

function TYamlLoader.LoadAll(const ABytes: TBytes): TArray<IYamlNode>;
var
  LParser: TYamlDocumentParser;
  LBuilder: TYamlNodeBuilder;
  LHandler: IYamlEventHandler;
begin
  Result := nil;
  LParser := TYamlDocumentParser.Create(ABytes);
  try
    while True do
    begin
      LBuilder := TYamlNodeBuilder.Create;
      LHandler := LBuilder;
      if not LParser.HandleNextDocument(LHandler) then
        Break;
      if LParser.Stuck then
        raise EYamlEndlessDocumentsException.Create('endless sequence of documents (yaml-cpp: std::bad_alloc)');
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := LBuilder.Root;
    end;
  finally
    LParser.Free;
  end;
end;

function TYamlLoader.LoadFile(const AFileName: string): IYamlNode;
var
  LBytes: TBytes;
begin
  if (not Assigned(FFiles)) or (not FFiles.TryReadAllBytes(AFileName, LBytes)) then
    raise EYamlBadFile.Create(TYamlMark.NullMark, SYamlBadFile + ': ' + YamlStringToText(AFileName));
  Result := Load(LBytes);
end;

function TYamlLoader.LoadAllFromFile(const AFileName: string): TArray<IYamlNode>;
var
  LBytes: TBytes;
begin
  if (not Assigned(FFiles)) or (not FFiles.TryReadAllBytes(AFileName, LBytes)) then
    raise EYamlBadFile.Create(TYamlMark.NullMark, SYamlBadFile + ': ' + YamlStringToText(AFileName));
  Result := LoadAll(LBytes);
end;

end.
