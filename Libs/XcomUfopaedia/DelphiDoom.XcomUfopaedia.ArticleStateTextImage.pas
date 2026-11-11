{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateTextImage of OpenXcom       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateTextImage;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text, DelphiDoom.XcomMod.ArticleDefinition,
  DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.ArticleState;

type
  /// <summary>An article with a full screen picture, and a title and a text in a column over it</summary>
  TXcomArticleStateTextImage = class(TXcomArticleState)
  strict private
    FTxtTitle: TXcomText;
    FTxtInfo: TXcomText;
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

{ TXcomArticleStateTextImage }

constructor TXcomArticleStateTextImage.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
var
  LTextHeight: Integer;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  FTxtTitle := TXcomText.Create(AArticle.TextWidth, 48, 5, 22);
  SetPalette('PAL_UFOPAEDIA', -1);
  InitLayout;
  Add(FTxtTitle);
  Host.Resources.GetSurface(AArticle.ImageId).Blit(Background);
  SetButtonColor(BlockOffset(5) + 3);
  FTxtTitle.SetColor(BlockOffset(15) + 4);
  FTxtTitle.SetBig;
  FTxtTitle.SetWordWrap(True);
  FTxtTitle.SetText(Tr(AArticle.Title));
  // the text starts under the title, which is as tall as its lines after the word wrap
  LTextHeight := FTxtTitle.GetTextHeight;
  FTxtInfo := TXcomText.Create(AArticle.TextWidth, 176 - LTextHeight, 5, 23 + LTextHeight);
  Add(FTxtInfo);
  FTxtInfo.SetColor(BlockOffset(15) - 1);
  FTxtInfo.SetWordWrap(True);
  FTxtInfo.SetScrollable(True);
  FTxtInfo.SetText(Tr(AArticle.Text));
  CenterAllSurfaces;
end;

end.
