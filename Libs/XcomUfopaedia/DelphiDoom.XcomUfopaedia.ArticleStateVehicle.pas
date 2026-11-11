{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateVehicle of OpenXcom         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateVehicle;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextList,
  DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.ArticleState;

type
  /// <summary>An article of a vehicle: title, the statistics of the unit, of its armor and of its weapon, and a text</summary>
  TXcomArticleStateVehicle = class(TXcomArticleState)
  strict private
    FTxtTitle: TXcomText;
    FTxtInfo: TXcomText;
    FLstStats: TXcomTextList;
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleUnit, DelphiDoom.XcomMod.Armor, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomUfopaedia.ArticleFormat;

{ TXcomArticleStateVehicle }

constructor TXcomArticleStateVehicle.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
var
  LUnit: TXcomRuleUnit;
  LArmor: TXcomArmor;
  LItem, LAmmo: TXcomRuleItem;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  LUnit := Require<TXcomRuleUnit>(Rules.Units.Find(AArticle.Id), AArticle.Id);
  LArmor := Require<TXcomArmor>(Rules.Armors.Find(LUnit.Armor), LUnit.Armor);
  LItem := Require<TXcomRuleItem>(Rules.Items.Find(AArticle.Id), AArticle.Id);
  FTxtTitle := TXcomText.Create(310, 17, 5, 23);
  FTxtInfo := TXcomText.Create(300, 150, 10, 122);
  FLstStats := TXcomTextList.Create(Host.Options, Host.Clock, 300, 89, 10, 48);
  SetPalette('PAL_UFOPAEDIA', -1);
  InitLayout;
  Add(FTxtTitle);
  Add(FTxtInfo);
  Add(FLstStats);
  Host.Resources.GetSurface('BACK10.SCR').Blit(Background);
  SetButtonColor(BlockOffset(5));
  FTxtTitle.SetColor(BlockOffset(15) + 4);
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr(AArticle.Title));
  FTxtInfo.SetColor(BlockOffset(15) - 1);
  FTxtInfo.SetWordWrap(True);
  FTxtInfo.SetScrollable(True);
  FTxtInfo.SetText(Tr(AArticle.Text));
  FLstStats.SetColor(BlockOffset(15) + 4);
  FLstStats.SetColumns([175, 145]);
  FLstStats.SetDot(True);
  AddRows(FLstStats, TXcomArticleFormat.VehicleBodyRows(LUnit, LArmor));
  LAmmo := nil;
  if Length(LItem.CompatibleAmmo) > 0 then
  begin
    LAmmo := Require<TXcomRuleItem>(Rules.Items.Find(LItem.CompatibleAmmo[0]), LItem.CompatibleAmmo[0]);
    // three rows more: the text goes down
    FTxtInfo.Y := 138;
  end;
  AddRows(FLstStats, TXcomArticleFormat.VehicleWeaponRows(AArticle.Weapon, LItem, LAmmo));
  CenterAllSurfaces;
end;

end.
