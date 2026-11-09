{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - the elements of a screen (RuleInterface)  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleInterface;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>Element: the rectangle and the three colors of a part of a screen; MaxInt means not set</summary>
  TXcomInterfaceElement = record
    X: Integer;
    Y: Integer;
    W: Integer;
    H: Integer;
    Color: Integer;
    Color2: Integer;
    Border: Integer;
    /// <summary>Defines the inversion behaviour</summary>
    TFTDMode: Boolean;
  end;

  /// <summary>The palette, parent, music and elements of a screen of the interface (RuleInterface)</summary>
  TXcomRuleInterface = class
  strict private
    FType: string;
    FPalette: string;
    FParent: string;
    FMusic: string;
    FElements: TXcomStringMap<TXcomInterfaceElement>;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    /// <summary>Loads from a node; an element with an id that exists replaces it</summary>
    procedure Load(const ANode: IYamlNode);
    property InterfaceType: string read FType;
    property Palette: string read FPalette;
    property Parent: string read FParent;
    property Music: string read FMusic;
    property Elements: TXcomStringMap<TXcomInterfaceElement> read FElements;
  end;

implementation

{ TXcomRuleInterface }

constructor TXcomRuleInterface.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FElements := TXcomStringMap<TXcomInterfaceElement>.Create;
end;

destructor TXcomRuleInterface.Destroy;
begin
  FElements.Free;
  inherited Destroy;
end;

procedure TXcomRuleInterface.Load(const ANode: IYamlNode);
var
  LItem, LField: IYamlNode;
  LElement: TXcomInterfaceElement;
begin
  FPalette := TXcomNodeReader.ReadString(ANode, 'palette', FPalette);
  FParent := TXcomNodeReader.ReadString(ANode, 'parent', FParent);
  FMusic := TXcomNodeReader.ReadString(ANode, 'music', FMusic);
  for LItem in TXcomNodeReader.Field(ANode, 'elements').Items do
  begin
    LElement := Default(TXcomInterfaceElement);
    LField := TXcomNodeReader.Field(LItem, 'size');
    if LField.IsDefined then
      TXcomNodeReader.RequireIntPair(LField, LElement.W, LElement.H)
    else
    begin
      LElement.W := MaxInt;
      LElement.H := MaxInt;
    end;
    LField := TXcomNodeReader.Field(LItem, 'pos');
    if LField.IsDefined then
      TXcomNodeReader.RequireIntPair(LField, LElement.X, LElement.Y)
    else
    begin
      LElement.X := MaxInt;
      LElement.Y := MaxInt;
    end;
    LElement.Color := TXcomNodeReader.ReadInteger(LItem, 'color', MaxInt);
    LElement.Color2 := TXcomNodeReader.ReadInteger(LItem, 'color2', MaxInt);
    LElement.Border := TXcomNodeReader.ReadInteger(LItem, 'border', MaxInt);
    LElement.TFTDMode := TXcomNodeReader.ReadBoolean(LItem, 'TFTDMode', False);
    FElements.SetValue(TXcomNodeReader.ReadString(LItem, 'id', ''), LElement);
  end;
end;

end.
