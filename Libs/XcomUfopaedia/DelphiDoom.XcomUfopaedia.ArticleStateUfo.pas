{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateUfo of OpenXcom             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateUfo;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomUfopaedia.Intf,
  DelphiDoom.XcomUfopaedia.ArticleState;

type
  /// <summary>
  ///   An article of a UFO: title, the front view of the UFO as the dogfight shows it, a big list of statistics
  ///   and a text
  /// </summary>
  TXcomArticleStateUfo = class(TXcomArticleState)
  strict private
    FImage: TXcomWidget;
    FTxtTitle: TXcomText;
    FTxtInfo: TXcomText;
    FLstInfo: TXcomTextList;
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

uses
  DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Types,
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomMod.RuleUfo, DelphiDoom.XcomBasescape.Funding,
  DelphiDoom.XcomUfopaedia.Types;

{ TXcomArticleStateUfo }

constructor TXcomArticleStateUfo.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
var
  LUfo: TXcomRuleUfo;
  LDogfight: TXcomRuleInterface;
  LPreview: TXcomInterfaceElement;
  LGraphic: TXcomSurface;
  LCrop: TXcomRect;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  LUfo := Require<TXcomRuleUfo>(Rules.Ufos.Find(AArticle.Id), AArticle.Id);
  FTxtTitle := TXcomText.Create(155, 32, 5, 24);
  SetPalette('PAL_GEOSCAPE', -1);
  InitLayout;
  Add(FTxtTitle);
  Host.Resources.GetSurface('BACK11.SCR').Blit(Background);
  SetButtonColor(BlockOffset(8) + 5);
  FTxtTitle.SetColor(BlockOffset(8) + 5);
  FTxtTitle.SetBig;
  FTxtTitle.SetWordWrap(True);
  FTxtTitle.SetText(Tr(AArticle.Title));
  FImage := TXcomWidget.Create(160, 52, 160, 6);
  Add(FImage);
  LDogfight := Require<TXcomRuleInterface>(Host.Resources.GetInterface('dogfight'), 'dogfight');
  if not LDogfight.TryGetElement('previewMid', LPreview) then
    raise EXcomUfopaediaException.CreateFmt(SXcomUfopaediaNoRule, [AArticle.Id, 'dogfight.previewMid']);
  // the top of the window of the dogfight, then the view of this UFO over it
  LGraphic := Host.Resources.GetSurface('INTERWIN.DAT');
  LGraphic.X := 0;
  LGraphic.Y := 0;
  LCrop := TXcomRect.Make(0, 0, FImage.Width, FImage.Height);
  LGraphic.Crop := LCrop;
  FImage.DrawRect(LCrop, 15);
  LGraphic.Blit(FImage);
  if LUfo.ModSprite = '' then
  begin
    LCrop.Y := LPreview.Y + LPreview.H * LUfo.Sprite;
    LCrop.H := LPreview.H;
    LGraphic.Crop := LCrop;
  end
  else
    LGraphic := Host.Resources.GetSurface(LUfo.ModSprite);
  LGraphic.X := 0;
  LGraphic.Y := 0;
  LGraphic.Blit(FImage);
  FTxtInfo := TXcomText.Create(300, 50, 10, 140);
  Add(FTxtInfo);
  FTxtInfo.SetColor(BlockOffset(8) + 5);
  FTxtInfo.SetWordWrap(True);
  FTxtInfo.SetScrollable(True);
  FTxtInfo.SetText(Tr(AArticle.Text));
  FLstInfo := TXcomTextList.Create(Host.Options, Host.Clock, 310, 64, 10, 68);
  Add(FLstInfo);
  CenterAllSurfaces;
  FLstInfo.SetColor(BlockOffset(8) + 5);
  FLstInfo.SetColumns([200, 110]);
  FLstInfo.SetBig;
  FLstInfo.SetDot(True);
  FLstInfo.AddRow([Tr('STR_DAMAGE_CAPACITY').Text, TXcomFunding.FormatNumber(LUfo.MaxDamage, '')]);
  FLstInfo.AddRow([Tr('STR_WEAPON_POWER').Text, TXcomFunding.FormatNumber(LUfo.WeaponPower, '')]);
  FLstInfo.AddRow([Tr('STR_WEAPON_RANGE').Text, Tr('STR_KILOMETERS').Arg(LUfo.WeaponRange).Text]);
  FLstInfo.AddRow([Tr('STR_MAXIMUM_SPEED').Text,
    Tr('STR_KNOTS').Arg(TXcomFunding.FormatNumber(LUfo.MaxSpeed, '')).Text]);
end;

end.
