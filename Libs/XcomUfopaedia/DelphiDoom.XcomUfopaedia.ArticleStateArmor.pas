{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateArmor of OpenXcom           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateArmor;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomUfopaedia.Intf,
  DelphiDoom.XcomUfopaedia.ArticleState;

type
  /// <summary>An article of an armor: title, the picture of the inventory, a block of statistics and a text</summary>
  TXcomArticleStateArmor = class(TXcomArticleState)
  strict private
    FImage: TXcomWidget;
    FTxtTitle: TXcomText;
    FLstInfo: TXcomTextList;
    FTxtInfo: TXcomText;
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

uses
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomMod.Armor, DelphiDoom.XcomUfopaedia.Types,
  DelphiDoom.XcomUfopaedia.ArticleFormat;

{ TXcomArticleStateArmor }

constructor TXcomArticleStateArmor.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
var
  LArmor: TXcomArmor;
  LLook: TXcomSurface;
  LRows: TArray<TXcomArticleRow>;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  LArmor := Require<TXcomArmor>(Rules.Armors.Find(AArticle.Id), AArticle.Id);
  FTxtTitle := TXcomText.Create(300, 17, 5, 24);
  SetPalette('PAL_BATTLEPEDIA', -1);
  InitLayout;
  Add(FTxtTitle);
  SetButtonColor(BlockOffset(0) + 15);
  FTxtTitle.SetColor(BlockOffset(14) + 15);
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr(AArticle.Title));
  FImage := TXcomWidget.Create(320, 200, 0, 0);
  Add(FImage);
  // the picture of a male soldier of the first look, then the one of the armor alone, then the bare name
  LLook := FindSurface(LArmor.SpriteInventory + 'M0.SPK');
  if not Assigned(LLook) then
    LLook := FindSurface(LArmor.SpriteInventory + '.SPK');
  if not Assigned(LLook) then
    LLook := Host.Resources.GetSurface(LArmor.SpriteInventory);
  LLook.Blit(FImage);
  FLstInfo := TXcomTextList.Create(Host.Options, Host.Clock, 150, 96, 150, 46);
  Add(FLstInfo);
  FLstInfo.SetColor(BlockOffset(14) + 15);
  FLstInfo.SetColumns([125, 25]);
  FLstInfo.SetDot(True);
  FTxtInfo := TXcomText.Create(300, 48, 8, 150);
  Add(FTxtInfo);
  FTxtInfo.SetColor(BlockOffset(14) + 15);
  FTxtInfo.SetWordWrap(True);
  FTxtInfo.SetScrollable(True);
  FTxtInfo.SetText(Tr(AArticle.Text));
  LRows := TXcomArticleFormat.ArmorRows(LArmor);
  AddRows(FLstInfo, LRows);
  ColorValues(FLstInfo, LRows, 0, BlockOffset(15) + 4);
  CenterAllSurfaces;
end;

end.
