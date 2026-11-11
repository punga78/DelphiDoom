{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateTFTDVehicle of OpenXcom     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateTftdVehicle;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomMod.ArticleDefinition,
  DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.ArticleStateTftd;

type
  /// <summary>
  ///   A TFTD article of a vehicle: the statistics of the unit and of its armor at the right, the ones of its
  ///   weapon in a second list at the bottom left
  /// </summary>
  TXcomArticleStateTftdVehicle = class(TXcomArticleStateTftd)
  strict private
    FLstStats: TXcomTextList;
    FLstStats2: TXcomTextList;
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleUnit, DelphiDoom.XcomMod.Armor, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomUfopaedia.Types, DelphiDoom.XcomUfopaedia.ArticleFormat;

{ TXcomArticleStateTftdVehicle }

constructor TXcomArticleStateTftdVehicle.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
var
  LUnit: TXcomRuleUnit;
  LArmor: TXcomArmor;
  LItem, LAmmo: TXcomRuleItem;
  LBody, LWeapon: TArray<TXcomArticleRow>;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  TxtInfo.SetHeight(72);
  LUnit := Require<TXcomRuleUnit>(Rules.Units.Find(AArticle.Id), AArticle.Id);
  LArmor := Require<TXcomArmor>(Rules.Armors.Find(LUnit.Armor), LUnit.Armor);
  LItem := Require<TXcomRuleItem>(Rules.Items.Find(AArticle.Id), AArticle.Id);
  FLstStats := TXcomTextList.Create(Host.Options, Host.Clock, 150, 65, 168, 106);
  Add(FLstStats);
  FLstStats.SetColor(TextColor);
  FLstStats.SetColumns([100, 50]);
  FLstStats.SetDot(True);
  FLstStats2 := TXcomTextList.Create(Host.Options, Host.Clock, 195, 33, 25, 166);
  Add(FLstStats2);
  FLstStats2.SetColor(TextColor);
  FLstStats2.SetColumns([65, 130]);
  FLstStats2.SetDot(True);
  LBody := TXcomArticleFormat.VehicleBodyRows(LUnit, LArmor);
  AddRows(FLstStats, LBody);
  LAmmo := nil;
  if Length(LItem.CompatibleAmmo) > 0 then
    LAmmo := Require<TXcomRuleItem>(Rules.Items.Find(LItem.CompatibleAmmo[0]), LItem.CompatibleAmmo[0]);
  LWeapon := TXcomArticleFormat.VehicleWeaponRows(AArticle.Weapon, LItem, LAmmo);
  AddRows(FLstStats2, LWeapon);
  ColorValues(FLstStats, LBody, 0, ValueColor);
  ColorValues(FLstStats2, LWeapon, 0, ValueColor);
  CenterAllSurfaces;
end;

end.
