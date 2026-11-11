{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateTFTDCraft of OpenXcom       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateTftdCraft;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text, DelphiDoom.XcomMod.ArticleDefinition,
  DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.ArticleStateTftd;

type
  /// <summary>A TFTD article of a craft: the seven lines of its statistics under a shorter text</summary>
  TXcomArticleStateTftdCraft = class(TXcomArticleStateTftd)
  strict private
    FTxtStats: TXcomText;
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleCraft;

{ TXcomArticleStateTftdCraft }

constructor TXcomArticleStateTftdCraft.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
var
  LCraft: TXcomRuleCraft;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  TxtInfo.SetHeight(80);
  LCraft := Require<TXcomRuleCraft>(Rules.Crafts.Find(AArticle.Id), AArticle.Id);
  FTxtStats := TXcomText.Create(131, 56, 187, 116);
  Add(FTxtStats);
  FTxtStats.SetColor(TextColor);
  FTxtStats.SetSecondaryColor(ValueColor);
  FTxtStats.SetText(CraftStatsText(LCraft));
  CenterAllSurfaces;
end;

end.
