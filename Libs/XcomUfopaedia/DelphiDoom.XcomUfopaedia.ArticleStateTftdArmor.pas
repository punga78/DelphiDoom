{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateTFTDArmor of OpenXcom       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateTftdArmor;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomMod.ArticleDefinition,
  DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.ArticleStateTftd;

type
  /// <summary>A TFTD article of an armor: the statistics of the armor under a shorter text</summary>
  TXcomArticleStateTftdArmor = class(TXcomArticleStateTftd)
  strict private
    FLstInfo: TXcomTextList;
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

uses
  DelphiDoom.XcomMod.Armor, DelphiDoom.XcomUfopaedia.Types, DelphiDoom.XcomUfopaedia.ArticleFormat;

{ TXcomArticleStateTftdArmor }

constructor TXcomArticleStateTftdArmor.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
var
  LArmor: TXcomArmor;
  LRows: TArray<TXcomArticleRow>;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  TxtInfo.SetHeight(72);
  LArmor := Require<TXcomArmor>(Rules.Armors.Find(AArticle.Id), AArticle.Id);
  FLstInfo := TXcomTextList.Create(Host.Options, Host.Clock, 150, 64, 168, 110);
  Add(FLstInfo);
  FLstInfo.SetColor(TextColor);
  FLstInfo.SetColumns([125, 25]);
  FLstInfo.SetDot(True);
  LRows := TXcomArticleFormat.ArmorRows(LArmor);
  AddRows(FLstInfo, LRows);
  ColorValues(FLstInfo, LRows, 0, ValueColor);
  CenterAllSurfaces;
end;

end.
