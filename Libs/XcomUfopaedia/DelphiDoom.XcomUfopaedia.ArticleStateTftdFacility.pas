{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateTFTDFacility of OpenXcom    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateTftdFacility;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomMod.ArticleDefinition,
  DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.ArticleStateTftd;

type
  /// <summary>
  ///   A TFTD article of a base facility: construction time and costs at the bottom, with the defense rows above
  ///   them (and the list moved up) when the facility defends the base
  /// </summary>
  TXcomArticleStateTftdFacility = class(TXcomArticleStateTftd)
  strict private
    FLstInfo: TXcomTextList;
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomGeoscape.Funding, DelphiDoom.XcomUfopaedia.Types,
  DelphiDoom.XcomUfopaedia.ArticleFormat;

{ TXcomArticleStateTftdFacility }

constructor TXcomArticleStateTftdFacility.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
var
  LFacility: TXcomRuleBaseFacility;
  LDefense: TArray<TXcomArticleRow>;
  LRow: Integer;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  TxtInfo.SetHeight(112);
  LFacility := Require<TXcomRuleBaseFacility>(Rules.Facilities.Find(AArticle.Id), AArticle.Id);
  FLstInfo := TXcomTextList.Create(Host.Options, Host.Clock, 150, 50, 168, 150);
  Add(FLstInfo);
  FLstInfo.SetColor(TextColor);
  FLstInfo.SetColumns([104, 46]);
  FLstInfo.SetDot(True);
  LDefense := TXcomArticleFormat.FacilityDefenseRows(LFacility);
  if Length(LDefense) > 0 then
  begin
    // two rows more: the list goes up and the text gets shorter
    FLstInfo.Y := FLstInfo.Y - 16;
    TxtInfo.SetHeight(TxtInfo.Height - 16);
    AddRows(FLstInfo, LDefense);
  end;
  FLstInfo.AddRow([Tr('STR_CONSTRUCTION_TIME').Text, Tr('STR_DAY', Cardinal(LFacility.BuildTime)).Text]);
  FLstInfo.AddRow([Tr('STR_CONSTRUCTION_COST').Text, TXcomFunding.Format(LFacility.BuildCost)]);
  FLstInfo.AddRow([Tr('STR_MAINTENANCE_COST').Text, TXcomFunding.Format(LFacility.MonthlyCost)]);
  for LRow := 0 to Length(LDefense) + 2 do
    FLstInfo.SetCellColor(LRow, 1, ValueColor);
  CenterAllSurfaces;
end;

end.
