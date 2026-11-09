{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - RuleInterface of OpenXcom (the colors and  }
{  positions of the elements of a menu, from the interfaces.rul of a mod)       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.RuleInterface;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf;

const
  /// <summary>INT_MAX: the value of a field that the element does not define</summary>
  XCOM_UNSET = High(Integer);

type
  /// <summary>Element of the C++: the geometry and colors of a part of an interface. XCOM_UNSET when not defined</summary>
  TXcomInterfaceElement = record
    X: Integer;
    Y: Integer;
    W: Integer;
    H: Integer;
    Color: Integer;
    Color2: Integer;
    Border: Integer;
    TftdMode: Boolean;
  end;

  /// <summary>One interface of the ruleset (a type such as mainMenu) with its elements, palette, parent and music</summary>
  TXcomRuleInterface = class
  strict private
    FType: string;
    FPalette: string;
    FParent: string;
    FMusic: string;
    FElements: TDictionary<string, TXcomInterfaceElement>;
    class function ReadPair(const ANode: IYamlNode; out AFirst, ASecond: Integer): Boolean; static;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    /// <summary>RuleInterface::load: the fields that the node has replace the ones already there</summary>
    procedure Load(const ANode: IYamlNode);
    /// <summary>RuleInterface::getElement: false when the interface has no such element</summary>
    function TryGetElement(const AId: string; out AElement: TXcomInterfaceElement): Boolean;
    property InterfaceType: string read FType;
    property Palette: string read FPalette;
    property Parent: string read FParent;
    property Music: string read FMusic;
  end;

implementation

uses
  DelphiDoom.XcomEngine.YamlFields;

constructor TXcomRuleInterface.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FElements := TDictionary<string, TXcomInterfaceElement>.Create;
end;

destructor TXcomRuleInterface.Destroy;
begin
  FElements.Free;
  inherited Destroy;
end;

class function TXcomRuleInterface.ReadPair(const ANode: IYamlNode; out AFirst, ASecond: Integer): Boolean;
var
  LItems: TArray<IYamlNode>;
begin
  Result := False;
  if (not Assigned(ANode)) or (not ANode.IsSequence) then
    Exit;
  LItems := ANode.Items;
  if Length(LItems) <> 2 then
    Exit;
  Result := LItems[0].TryAsInteger(AFirst) and LItems[1].TryAsInteger(ASecond);
end;

procedure TXcomRuleInterface.Load(const ANode: IYamlNode);
var
  LItem: IYamlNode;
  LElement: TXcomInterfaceElement;
  LFirst: Integer;
  LSecond: Integer;
begin
  FPalette := TXcomYamlFields.ReadString(ANode, 'palette', FPalette);
  FParent := TXcomYamlFields.ReadString(ANode, 'parent', FParent);
  FMusic := TXcomYamlFields.ReadString(ANode, 'music', FMusic);
  for LItem in TXcomYamlFields.Sequence(ANode, 'elements') do
  begin
    LElement.W := XCOM_UNSET;
    LElement.H := XCOM_UNSET;
    LElement.X := XCOM_UNSET;
    LElement.Y := XCOM_UNSET;
    if ReadPair(TXcomYamlFields.Field(LItem, 'size'), LFirst, LSecond) then
    begin
      LElement.W := LFirst;
      LElement.H := LSecond;
    end;
    if ReadPair(TXcomYamlFields.Field(LItem, 'pos'), LFirst, LSecond) then
    begin
      LElement.X := LFirst;
      LElement.Y := LSecond;
    end;
    LElement.Color := TXcomYamlFields.ReadInteger(LItem, 'color', XCOM_UNSET);
    LElement.Color2 := TXcomYamlFields.ReadInteger(LItem, 'color2', XCOM_UNSET);
    LElement.Border := TXcomYamlFields.ReadInteger(LItem, 'border', XCOM_UNSET);
    LElement.TftdMode := TXcomYamlFields.ReadBoolean(LItem, 'TFTDMode', False);
    FElements.AddOrSetValue(TXcomYamlFields.ReadString(LItem, 'id', ''), LElement);
  end;
end;

function TXcomRuleInterface.TryGetElement(const AId: string; out AElement: TXcomInterfaceElement): Boolean;
begin
  Result := FElements.TryGetValue(AId, AElement);
end;

end.
