{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - an article of the Ufopaedia               }
{  (ArticleDefinition and its subclasses)                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.ArticleDefinition;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>ArticleDefinitionRect: a rectangle of an article</summary>
  TXcomArticleRect = record
    X: Integer;
    Y: Integer;
    Width: Integer;
    Height: Integer;
  end;

  /// <summary>
  ///   An article of the Ufopaedia. The C++ has a class for each kind (craft, craft weapon, vehicle, item, armor,
  ///   base facility, text with image, text, UFO and the TFTD ones); here one class holds the fields of all the
  ///   kinds and Load reads the ones that the kind has. The kind is the number of UfopaediaTypeId
  /// </summary>
  TXcomArticleDefinition = class
  public
    const
      UFOPAEDIA_TYPE_UNKNOWN = 0;
      UFOPAEDIA_TYPE_CRAFT = 1;
      UFOPAEDIA_TYPE_CRAFT_WEAPON = 2;
      UFOPAEDIA_TYPE_VEHICLE = 3;
      UFOPAEDIA_TYPE_ITEM = 4;
      UFOPAEDIA_TYPE_ARMOR = 5;
      UFOPAEDIA_TYPE_BASE_FACILITY = 6;
      UFOPAEDIA_TYPE_TEXTIMAGE = 7;
      UFOPAEDIA_TYPE_TEXT = 8;
      UFOPAEDIA_TYPE_UFO = 9;
      UFOPAEDIA_TYPE_TFTD = 10;
      UFOPAEDIA_TYPE_TFTD_USO = 17;
  strict private
    FKind: Integer;
    FIsTftd: Boolean;
    FListOrder: Integer;
    FId: string;
    FTitle: string;
    FSection: string;
    FRequires: TArray<string>;
    FImageId: string;
    FText: string;
    FTextWidth: Integer;
    FWeapon: string;
    FRectStats: TXcomArticleRect;
    FRectText: TXcomArticleRect;
    class function ReadRect(const ANode: IYamlNode; const AKey: string; const ADefault: TXcomArticleRect)
      : TXcomArticleRect; static;
  public
    /// <param name="AKind">The kind of article: a UFOPAEDIA_TYPE_ number (the class of the C++)</param>
    constructor Create(AKind: Integer);
    /// <summary>
    ///   Whether the C++ has a class for a type_id (UFOPAEDIA_TYPE_CRAFT to UFOPAEDIA_TYPE_TFTD_USO but not
    ///   UNKNOWN: the others make no article)
    /// </summary>
    class function IsKnownKind(AKind: Integer): Boolean; static;
    /// <summary>Loads the article: the fields of its kind; AListOrder is the default of listOrder</summary>
    procedure Load(const ANode: IYamlNode; AListOrder: Integer);
    property Kind: Integer read FKind;
    property ListOrder: Integer read FListOrder;
    property Id: string read FId;
    property Title: string read FTitle;
    property Section: string read FSection;
    property Requirements: TArray<string> read FRequires;
    property ImageId: string read FImageId;
    property Text: string read FText;
    property TextWidth: Integer read FTextWidth;
    property Weapon: string read FWeapon;
    property RectStats: TXcomArticleRect read FRectStats;
    property RectText: TXcomArticleRect read FRectText;
  end;

implementation

{ TXcomArticleDefinition }

constructor TXcomArticleDefinition.Create(AKind: Integer);
begin
  inherited Create;
  // the C++ makes an ArticleDefinitionTFTD (kind TFTD, then taken from the node) for the kinds 10 to 17
  FIsTftd := AKind >= UFOPAEDIA_TYPE_TFTD;
  if FIsTftd then
    FKind := UFOPAEDIA_TYPE_TFTD
  else
    FKind := AKind;
end;

class function TXcomArticleDefinition.IsKnownKind(AKind: Integer): Boolean;
begin
  Result := (AKind >= UFOPAEDIA_TYPE_CRAFT) and (AKind <= UFOPAEDIA_TYPE_TFTD_USO);
end;

class function TXcomArticleDefinition.ReadRect(const ANode: IYamlNode; const AKey: string;
  const ADefault: TXcomArticleRect): TXcomArticleRect;
var
  LField: IYamlNode;
begin
  LField := TXcomNodeReader.Field(ANode, AKey);
  if not LField.IsDefined or not LField.IsMap then
    Exit(ADefault);
  // decoded into the rectangle that is there: a missing field keeps its value
  Result := ADefault;
  Result.X := TXcomNodeReader.ReadInteger(LField, 'x', Result.X);
  Result.Y := TXcomNodeReader.ReadInteger(LField, 'y', Result.Y);
  Result.Width := TXcomNodeReader.ReadInteger(LField, 'width', Result.Width);
  Result.Height := TXcomNodeReader.ReadInteger(LField, 'height', Result.Height);
end;

procedure TXcomArticleDefinition.Load(const ANode: IYamlNode; AListOrder: Integer);
begin
  FId := TXcomNodeReader.ReadString(ANode, 'id', FId);
  FTitle := FId;
  FSection := TXcomNodeReader.ReadString(ANode, 'section', FSection);
  FRequires := TXcomNodeReader.ReadStrings(ANode, 'requires', FRequires);
  FTitle := TXcomNodeReader.ReadString(ANode, 'title', FTitle);
  FListOrder := TXcomNodeReader.ReadInteger(ANode, 'listOrder', FListOrder);
  if FListOrder = 0 then
    FListOrder := AListOrder;
  if FIsTftd then
  begin
    // the TFTD articles take their kind from the node
    FKind := TXcomNodeReader.ReadInteger(ANode, 'type_id', FKind);
    FImageId := TXcomNodeReader.ReadString(ANode, 'image_id', FImageId);
    FText := TXcomNodeReader.ReadString(ANode, 'text', FText);
    // 95% of these do not define it: the default is 157
    FTextWidth := TXcomNodeReader.ReadInteger(ANode, 'text_width', 157);
    FWeapon := TXcomNodeReader.ReadString(ANode, 'weapon', FWeapon);
    Exit;
  end;
  case FKind of
    UFOPAEDIA_TYPE_CRAFT:
      begin
        FImageId := TXcomNodeReader.ReadString(ANode, 'image_id', FImageId);
        FRectStats := ReadRect(ANode, 'rect_stats', FRectStats);
        FRectText := ReadRect(ANode, 'rect_text', FRectText);
        FText := TXcomNodeReader.ReadString(ANode, 'text', FText);
      end;
    UFOPAEDIA_TYPE_CRAFT_WEAPON:
      begin
        FImageId := TXcomNodeReader.ReadString(ANode, 'image_id', FImageId);
        FText := TXcomNodeReader.ReadString(ANode, 'text', FText);
      end;
    UFOPAEDIA_TYPE_TEXTIMAGE:
      begin
        FImageId := TXcomNodeReader.ReadString(ANode, 'image_id', FImageId);
        FText := TXcomNodeReader.ReadString(ANode, 'text', FText);
        FTextWidth := TXcomNodeReader.ReadInteger(ANode, 'text_width', FTextWidth);
      end;
    UFOPAEDIA_TYPE_VEHICLE:
      begin
        FWeapon := TXcomNodeReader.ReadString(ANode, 'weapon', FWeapon);
        FText := TXcomNodeReader.ReadString(ANode, 'text', FText);
      end;
  else
    // item, armor, base facility, text and UFO: only the text
    FText := TXcomNodeReader.ReadString(ANode, 'text', FText);
  end;
end;

end.
