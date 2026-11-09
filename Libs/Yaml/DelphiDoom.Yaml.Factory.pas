{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - the factory (the only place that knows classes)  }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.Factory;

interface

uses
  System.SysUtils,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf;

type
  /// <summary>Creates the objects of the library</summary>
  TYamlFactory = class
  public
    /// <summary>A loader; AFiles is used by LoadFile and LoadAllFromFile (nil: they fail with EYamlBadFile)</summary>
    class function CreateParser(const AFiles: IYamlFileSource = nil): IYamlParser; static;
    /// <summary>A loader that reads the files of the disk</summary>
    class function CreateDiskParser: IYamlParser; static;
    class function CreateEmitter: IYamlEmitter; static;
    /// <summary>Node(): a null node that is not stored anywhere</summary>
    class function CreateNode: IYamlNode; overload; static;
    /// <summary>Node(NodeType::value)</summary>
    class function CreateNode(AType: TYamlNodeType): IYamlNode; overload; static;
    /// <summary>Node(string)</summary>
    class function CreateScalar(const AText: TYamlText): IYamlNode; static;
    /// <summary>YAML::Clone: a deep copy (the nodes shared inside the tree are shared in the copy)</summary>
    class function Clone(const ANode: IYamlNode): IYamlNode; static;
    /// <summary>YAML::Dump: the node as YAML text</summary>
    class function Dump(const ANode: IYamlNode): TYamlText; static;
  end;

implementation

uses
  DelphiDoom.Yaml.Node,
  DelphiDoom.Yaml.NodeBuilder,
  DelphiDoom.Yaml.NodeEvents,
  DelphiDoom.Yaml.Loader,
  DelphiDoom.Yaml.Emitter,
  DelphiDoom.Yaml.DiskFileSource;

class function TYamlFactory.CreateParser(const AFiles: IYamlFileSource): IYamlParser;
begin
  Result := TYamlLoader.Create(AFiles);
end;

class function TYamlFactory.CreateDiskParser: IYamlParser;
begin
  Result := TYamlLoader.Create(TYamlDiskFileSource.Create);
end;

class function TYamlFactory.CreateEmitter: IYamlEmitter;
begin
  Result := TYamlEmitter.Create;
end;

class function TYamlFactory.CreateNode: IYamlNode;
begin
  Result := TYamlNode.Create;
end;

class function TYamlFactory.CreateNode(AType: TYamlNodeType): IYamlNode;
begin
  Result := TYamlNode.Create(AType);
end;

class function TYamlFactory.CreateScalar(const AText: TYamlText): IYamlNode;
begin
  Result := TYamlNode.CreateScalar(AText);
end;

class function TYamlFactory.Clone(const ANode: IYamlNode): IYamlNode;
var
  LEvents: TYamlNodeEvents;
  LBuilder: TYamlNodeBuilder;
  LHandler: IYamlEventHandler;
begin
  LBuilder := TYamlNodeBuilder.Create;
  LHandler := LBuilder;
  LEvents := TYamlNodeEvents.Create(ANode);
  try
    LEvents.Emit(LHandler);
  finally
    LEvents.Free;
  end;
  Result := LBuilder.Root;
end;

class function TYamlFactory.Dump(const ANode: IYamlNode): TYamlText;
var
  LEmitter: IYamlEmitter;
begin
  LEmitter := CreateEmitter;
  LEmitter.WriteNode(ANode);
  Result := LEmitter.Text;
end;

end.
