{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateBaseFacility of OpenXcom    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateBaseFacility;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomUfopaedia.Intf,
  DelphiDoom.XcomUfopaedia.ArticleState;

type
  /// <summary>An article of a base facility: title, the facility drawn with the sprites of the base, costs and a text</summary>
  TXcomArticleStateBaseFacility = class(TXcomArticleState)
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
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomMod.RuleBaseFacility,
  DelphiDoom.XcomGeoscape.Funding, DelphiDoom.XcomUfopaedia.Types, DelphiDoom.XcomUfopaedia.ArticleFormat;

const
  TILE_SIZE = 32;

{ TXcomArticleStateBaseFacility }

constructor TXcomArticleStateBaseFacility.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
var
  LFacility: TXcomRuleBaseFacility;
  LGraphic: TXcomSurfaceSet;
  LFrame: TXcomSurface;
  LOffset, LX, LY, LPositionX, LPositionY, LNumber: Integer;
  LRows: TArray<TXcomArticleRow>;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  LFacility := Require<TXcomRuleBaseFacility>(Rules.Facilities.Find(AArticle.Id), AArticle.Id);
  FTxtTitle := TXcomText.Create(200, 17, 10, 24);
  SetPalette('PAL_BASESCAPE', -1);
  InitLayout;
  Add(FTxtTitle);
  Host.Resources.GetSurface('BACK09.SCR').Blit(Background);
  SetButtonColor(BlockOffset(4));
  FTxtTitle.SetColor(BlockOffset(13) + 10);
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr(AArticle.Title));
  // the preview: two tiles by two, a facility of one tile in the middle
  FImage := TXcomWidget.Create(TILE_SIZE * 2, TILE_SIZE * 2, 232, 16);
  Add(FImage);
  LGraphic := Require<TXcomSurfaceSet>(Catalog.Sprites('BASEBITS.PCK'), 'BASEBITS.PCK');
  if LFacility.Size = 1 then
    LOffset := TILE_SIZE div 2
  else
    LOffset := 0;
  LNumber := 0;
  LPositionY := LOffset;
  for LY := 0 to LFacility.Size - 1 do
  begin
    LPositionX := LOffset;
    for LX := 0 to LFacility.Size - 1 do
    begin
      LFrame := LGraphic.GetFrame(LFacility.SpriteShape + LNumber);
      LFrame.X := LPositionX;
      LFrame.Y := LPositionY;
      LFrame.Blit(FImage);
      if LFacility.Size = 1 then
      begin
        LFrame := LGraphic.GetFrame(LFacility.SpriteFacility + LNumber);
        LFrame.X := LPositionX;
        LFrame.Y := LPositionY;
        LFrame.Blit(FImage);
      end;
      Inc(LPositionX, TILE_SIZE);
      Inc(LNumber);
    end;
    Inc(LPositionY, TILE_SIZE);
  end;
  FTxtInfo := TXcomText.Create(300, 90, 10, 104);
  Add(FTxtInfo);
  FTxtInfo.SetColor(BlockOffset(13) + 10);
  FTxtInfo.SetWordWrap(True);
  FTxtInfo.SetScrollable(True);
  FTxtInfo.SetText(Tr(AArticle.Text));
  FLstInfo := TXcomTextList.Create(Host.Options, Host.Clock, 200, 42, 10, 42);
  Add(FLstInfo);
  FLstInfo.SetColor(BlockOffset(13) + 10);
  FLstInfo.SetColumns([140, 60]);
  FLstInfo.SetDot(True);
  FLstInfo.AddRow([Tr('STR_CONSTRUCTION_TIME').Text, Tr('STR_DAY', Cardinal(LFacility.BuildTime)).Text]);
  FLstInfo.SetCellColor(0, 1, BlockOffset(13));
  FLstInfo.AddRow([Tr('STR_CONSTRUCTION_COST').Text, TXcomFunding.Format(LFacility.BuildCost)]);
  FLstInfo.SetCellColor(1, 1, BlockOffset(13));
  FLstInfo.AddRow([Tr('STR_MAINTENANCE_COST').Text, TXcomFunding.Format(LFacility.MonthlyCost)]);
  FLstInfo.SetCellColor(2, 1, BlockOffset(13));
  LRows := TXcomArticleFormat.FacilityDefenseRows(LFacility);
  AddRows(FLstInfo, LRows);
  ColorValues(FLstInfo, LRows, 3, BlockOffset(13));
  CenterAllSurfaces;
end;

end.
