{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - walking the elements of a node        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.NodeIteration;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf;

type
  /// <summary>
  ///   for (YAML::const_iterator i = node.begin(); i != node.end(); ++i) { ... *i ... } as the save classes write it
  ///   to read a list
  /// </summary>
  TXcomNodeIteration = class
  public
    /// <summary>
    ///   The elements of a sequence; nothing for a scalar or a null node. A map is walked with a sequence loop:
    ///   its first element is a node that is not valid, and using it raises EYamlInvalidNode (an empty map has
    ///   no element)
    /// </summary>
    class function Elements(const ANode: IYamlNode): TArray<IYamlNode>; static;
  end;

implementation

{ TXcomNodeIteration }

class function TXcomNodeIteration.Elements(const ANode: IYamlNode): TArray<IYamlNode>;
begin
  if ANode.IsMap and (ANode.Size > 0) then
    raise EYamlInvalidNode.Create(TYamlMark.NullMark, YamlInvalidNodeMessage(''));
  if ANode.IsSequence then
    Result := ANode.Items
  else
    Result := nil;
end;

end.
