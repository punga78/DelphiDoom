{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateTFTDUso of OpenXcom         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateTftdUso;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomMod.ArticleDefinition,
  DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.ArticleStateTftd;

type
  /// <summary>A TFTD article of an alien submarine: damage capacity, weapon power and range, and speed</summary>
  TXcomArticleStateTftdUso = class(TXcomArticleStateTftd)
  strict private
    FLstInfo: TXcomTextList;
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleUfo, DelphiDoom.XcomGeoscape.Funding;

{ TXcomArticleStateTftdUso }

constructor TXcomArticleStateTftdUso.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
var
  LUfo: TXcomRuleUfo;
  LRow: Integer;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  TxtInfo.SetHeight(112);
  LUfo := Require<TXcomRuleUfo>(Rules.Ufos.Find(AArticle.Id), AArticle.Id);
  FLstInfo := TXcomTextList.Create(Host.Options, Host.Clock, 150, 50, 168, 142);
  Add(FLstInfo);
  FLstInfo.SetColor(TextColor);
  FLstInfo.SetColumns([95, 55]);
  FLstInfo.SetDot(True);
  FLstInfo.AddRow([Tr('STR_DAMAGE_CAPACITY').Text, TXcomFunding.FormatNumber(LUfo.MaxDamage, '')]);
  FLstInfo.AddRow([Tr('STR_WEAPON_POWER').Text, TXcomFunding.FormatNumber(LUfo.WeaponPower, '')]);
  FLstInfo.AddRow([Tr('STR_WEAPON_RANGE').Text, Tr('STR_KILOMETERS').Arg(LUfo.WeaponRange).Text]);
  FLstInfo.AddRow([Tr('STR_MAXIMUM_SPEED').Text,
    Tr('STR_KNOTS').Arg(TXcomFunding.FormatNumber(LUfo.MaxSpeed, '')).Text]);
  for LRow := 0 to 3 do
    FLstInfo.SetCellColor(LRow, 1, ValueColor);
  CenterAllSurfaces;
end;

end.
