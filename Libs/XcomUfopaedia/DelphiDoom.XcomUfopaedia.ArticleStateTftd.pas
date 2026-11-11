{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateTFTD of OpenXcom (the base  }
{  of the TFTD articles: picture, title and text)                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateTftd;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text, DelphiDoom.XcomMod.ArticleDefinition,
  DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.ArticleState;

type
  /// <summary>
  ///   Every TFTD article has a title, a block of text and a background picture, with the buttons at the bottom
  ///   right. The plain article (type 10) is this class; the other kinds derive from it and add their statistics
  /// </summary>
  TXcomArticleStateTftd = class(TXcomArticleState)
  strict private
    FTxtTitle: TXcomText;
    FTxtInfo: TXcomText;
  protected
    /// <summary>Palette::blockOffset(0)+2: the color of the texts of the TFTD articles</summary>
    class function TextColor: Byte; static;
    /// <summary>Palette::blockOffset(15)+4: the color of the values of the statistics</summary>
    class function ValueColor: Byte; static;
    property TxtTitle: TXcomText read FTxtTitle;
    property TxtInfo: TXcomText read FTxtInfo;
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

uses
  DelphiDoom.XcomUi.Types;

{ TXcomArticleStateTftd }

constructor TXcomArticleStateTftd.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  SetPalette('PAL_BASESCAPE', -1);
  BtnOk.X := 227;
  BtnOk.Y := 179;
  BtnOk.SetHeight(10);
  BtnOk.SetWidth(23);
  BtnPrev.X := 254;
  BtnPrev.Y := 179;
  BtnPrev.SetHeight(10);
  BtnPrev.SetWidth(23);
  BtnNext.X := 281;
  BtnNext.Y := 179;
  BtnNext.SetHeight(10);
  BtnNext.SetWidth(23);
  SetButtonColor(TextColor);
  InitLayout;
  Host.Resources.GetSurface('BACK08.SCR').Blit(Background);
  Host.Resources.GetSurface(AArticle.ImageId).Blit(Background);
  FTxtInfo := TXcomText.Create(AArticle.TextWidth, 136, 320 - AArticle.TextWidth, 34);
  FTxtTitle := TXcomText.Create(284, 16, 36, 14);
  Add(FTxtTitle);
  Add(FTxtInfo);
  FTxtTitle.SetColor(TextColor);
  FTxtTitle.SetBig;
  FTxtTitle.SetWordWrap(True);
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr(AArticle.Title));
  FTxtInfo.SetColor(TextColor);
  FTxtInfo.SetWordWrap(True);
  FTxtInfo.SetScrollable(True);
  FTxtInfo.SetText(Tr(AArticle.Text));
  // the other kinds add surfaces and center when they are done; the plain article is done here
  if AArticle.Kind = TXcomArticleDefinition.UFOPAEDIA_TYPE_TFTD then
    CenterAllSurfaces;
end;

class function TXcomArticleStateTftd.TextColor: Byte;
begin
  Result := BlockOffset(0) + 2;
end;

class function TXcomArticleStateTftd.ValueColor: Byte;
begin
  Result := BlockOffset(15) + 4;
end;

end.
