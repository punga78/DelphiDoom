{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateCraftWeapon of OpenXcom     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateCraftWeapon;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextList,
  DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.ArticleState;

type
  /// <summary>An article of a craft weapon: a full screen picture, a title, a big list of statistics and a text</summary>
  TXcomArticleStateCraftWeapon = class(TXcomArticleState)
  strict private
    FTxtTitle: TXcomText;
    FTxtInfo: TXcomText;
    FLstInfo: TXcomTextList;
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleCraftWeapon, DelphiDoom.XcomBasescape.Funding, DelphiDoom.XcomUfopaedia.ArticleFormat;

{ TXcomArticleStateCraftWeapon }

constructor TXcomArticleStateCraftWeapon.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
var
  LWeapon: TXcomRuleCraftWeapon;
  LRow: Integer;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  LWeapon := Require<TXcomRuleCraftWeapon>(Rules.CraftWeapons.Find(AArticle.Id), AArticle.Id);
  FTxtTitle := TXcomText.Create(200, 32, 5, 24);
  SetPalette('PAL_BATTLEPEDIA', -1);
  InitLayout;
  Add(FTxtTitle);
  Host.Resources.GetSurface(AArticle.ImageId).Blit(Background);
  SetButtonColor(BlockOffset(1));
  FTxtTitle.SetColor(BlockOffset(14) + 15);
  FTxtTitle.SetBig;
  FTxtTitle.SetWordWrap(True);
  FTxtTitle.SetText(Tr(AArticle.Title));
  FTxtInfo := TXcomText.Create(310, 32, 5, 160);
  Add(FTxtInfo);
  FTxtInfo.SetColor(BlockOffset(14) + 15);
  FTxtInfo.SetWordWrap(True);
  FTxtInfo.SetScrollable(True);
  FTxtInfo.SetText(Tr(AArticle.Text));
  FLstInfo := TXcomTextList.Create(Host.Options, Host.Clock, 250, 111, 5, 80);
  Add(FLstInfo);
  FLstInfo.SetColor(BlockOffset(14) + 15);
  FLstInfo.SetColumns([180, 70]);
  FLstInfo.SetDot(True);
  FLstInfo.SetBig;
  FLstInfo.AddRow([Tr('STR_DAMAGE').Text, TXcomFunding.FormatNumber(LWeapon.Damage, '')]);
  FLstInfo.AddRow([Tr('STR_RANGE').Text, Tr('STR_KILOMETERS').Arg(LWeapon.Range).Text]);
  FLstInfo.AddRow([Tr('STR_ACCURACY').Text, TXcomArticleFormat.FormatPercentage(LWeapon.Accuracy)]);
  FLstInfo.AddRow([Tr('STR_RE_LOAD_TIME').Text, Tr('STR_SECONDS').Arg(LWeapon.StandardReload).Text]);
  FLstInfo.AddRow([Tr('STR_ROUNDS').Text, TXcomFunding.FormatNumber(LWeapon.AmmoMax, '')]);
  for LRow := 0 to 4 do
    FLstInfo.SetCellColor(LRow, 1, BlockOffset(15) + 4);
  CenterAllSurfaces;
end;

end.
