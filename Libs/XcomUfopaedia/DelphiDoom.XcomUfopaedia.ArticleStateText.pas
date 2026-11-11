{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateText of OpenXcom            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateText;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text, DelphiDoom.XcomMod.ArticleDefinition,
  DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.ArticleState;

type
  /// <summary>An article with a title and a text on the standard background</summary>
  TXcomArticleStateText = class(TXcomArticleState)
  strict private
    FTxtTitle: TXcomText;
    FTxtInfo: TXcomText;
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

{ TXcomArticleStateText }

constructor TXcomArticleStateText.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  FTxtTitle := TXcomText.Create(296, 17, 5, 23);
  FTxtInfo := TXcomText.Create(296, 150, 10, 48);
  SetPalette('PAL_UFOPAEDIA', -1);
  InitLayout;
  Add(FTxtTitle);
  Add(FTxtInfo);
  CenterAllSurfaces;
  Host.Resources.GetSurface('BACK10.SCR').Blit(Background);
  SetButtonColor(BlockOffset(5));
  FTxtTitle.SetColor(BlockOffset(15) + 4);
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr(AArticle.Title));
  FTxtInfo.SetColor(BlockOffset(15) - 1);
  FTxtInfo.SetWordWrap(True);
  FTxtInfo.SetScrollable(True);
  FTxtInfo.SetText(Tr(AArticle.Text));
end;

end.
