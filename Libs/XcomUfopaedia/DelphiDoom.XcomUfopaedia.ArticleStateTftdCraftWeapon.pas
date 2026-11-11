{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateTFTDCraftWeapon of OpenXcom }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateTftdCraftWeapon;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomMod.ArticleDefinition,
  DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.ArticleStateTftd;

type
  /// <summary>A TFTD article of a craft weapon: damage, range, accuracy and reload time under a shorter text</summary>
  TXcomArticleStateTftdCraftWeapon = class(TXcomArticleStateTftd)
  strict private
    FLstInfo: TXcomTextList;
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleCraftWeapon, DelphiDoom.XcomBasescape.Funding, DelphiDoom.XcomUfopaedia.ArticleFormat;

{ TXcomArticleStateTftdCraftWeapon }

constructor TXcomArticleStateTftdCraftWeapon.Create(AHost: TXcomStateHost;
  const ANavigator: IXcomUfopaediaNavigator; const ACatalog: IXcomUfopaediaCatalog;
  AArticle: TXcomArticleDefinition);
var
  LWeapon: TXcomRuleCraftWeapon;
  LRow: Integer;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  TxtInfo.SetHeight(88);
  LWeapon := Require<TXcomRuleCraftWeapon>(Rules.CraftWeapons.Find(AArticle.Id), AArticle.Id);
  FLstInfo := TXcomTextList.Create(Host.Options, Host.Clock, 150, 50, 168, 126);
  Add(FLstInfo);
  FLstInfo.SetColor(TextColor);
  // wider than the original on purpose (the Finnish texts)
  FLstInfo.SetColumns([100, 68]);
  FLstInfo.SetDot(True);
  FLstInfo.AddRow([Tr('STR_DAMAGE').Text, TXcomFunding.FormatNumber(LWeapon.Damage, '')]);
  FLstInfo.AddRow([Tr('STR_RANGE').Text, Tr('STR_KILOMETERS').Arg(LWeapon.Range).Text]);
  FLstInfo.AddRow([Tr('STR_ACCURACY').Text, TXcomArticleFormat.FormatPercentage(LWeapon.Accuracy)]);
  FLstInfo.AddRow([Tr('STR_RE_LOAD_TIME').Text, Tr('STR_SECONDS').Arg(LWeapon.StandardReload).Text]);
  for LRow := 0 to 3 do
    FLstInfo.SetCellColor(LRow, 1, ValueColor);
  CenterAllSurfaces;
end;

end.
