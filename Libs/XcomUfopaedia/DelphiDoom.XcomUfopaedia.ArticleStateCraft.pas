{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateCraft of OpenXcom           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateCraft;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text, DelphiDoom.XcomMod.ArticleDefinition,
  DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.ArticleState;

type
  /// <summary>An article of a craft: a full screen picture, a title, a text and the statistics where the article says</summary>
  TXcomArticleStateCraft = class(TXcomArticleState)
  strict private
    FTxtTitle: TXcomText;
    FTxtInfo: TXcomText;
    FTxtStats: TXcomText;
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleCraft;

{ TXcomArticleStateCraft }

constructor TXcomArticleStateCraft.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
var
  LCraft: TXcomRuleCraft;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  LCraft := Require<TXcomRuleCraft>(Rules.Crafts.Find(AArticle.Id), AArticle.Id);
  FTxtTitle := TXcomText.Create(210, 32, 5, 24);
  SetPalette('PAL_UFOPAEDIA', -1);
  InitLayout;
  Add(FTxtTitle);
  Host.Resources.GetSurface(AArticle.ImageId).Blit(Background);
  SetButtonColor(BlockOffset(15) - 1);
  FTxtTitle.SetColor(BlockOffset(14) + 15);
  FTxtTitle.SetBig;
  FTxtTitle.SetWordWrap(True);
  FTxtTitle.SetText(Tr(AArticle.Title));
  FTxtInfo := TXcomText.Create(AArticle.RectText.Width, AArticle.RectText.Height, AArticle.RectText.X,
    AArticle.RectText.Y);
  Add(FTxtInfo);
  FTxtInfo.SetColor(BlockOffset(14) + 15);
  FTxtInfo.SetWordWrap(True);
  FTxtInfo.SetScrollable(True);
  FTxtInfo.SetText(Tr(AArticle.Text));
  FTxtStats := TXcomText.Create(AArticle.RectStats.Width, AArticle.RectStats.Height, AArticle.RectStats.X,
    AArticle.RectStats.Y);
  Add(FTxtStats);
  FTxtStats.SetColor(BlockOffset(14) + 15);
  FTxtStats.SetSecondaryColor(BlockOffset(15) + 4);
  FTxtStats.SetText(CraftStatsText(LCraft));
  CenterAllSurfaces;
end;

end.
