{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateTFTDItem of OpenXcom        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateTftdItem;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextList,
  DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomUfopaedia.Intf,
  DelphiDoom.XcomUfopaedia.ArticleStateTftd;

type
  /// <summary>
  ///   A TFTD article of an item: the table of the shots of a firearm at the bottom left and the damage of the
  ///   item, or of its three first kinds of ammunition, at the bottom right
  /// </summary>
  TXcomArticleStateTftdItem = class(TXcomArticleStateTftd)
  strict private
    FLstInfo: TXcomTextList;
    FTxtShotType: TXcomText;
    FTxtAccuracy: TXcomText;
    FTxtTuCost: TXcomText;
    FTxtAmmoType: array[0..2] of TXcomText;
    FTxtAmmoDamage: array[0..2] of TXcomText;
    procedure AddShotTable(AItem: TXcomRuleItem);
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

uses
  System.Math, DelphiDoom.XcomUfopaedia.Types, DelphiDoom.XcomUfopaedia.ArticleFormat;

{ TXcomArticleStateTftdItem }

constructor TXcomArticleStateTftdItem.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
var
  LItem, LAmmoRule: TXcomRuleItem;
  LAmmoArticle: TXcomArticleDefinition;
  LAmmo: TArray<string>;
  LIndex: Integer;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  LItem := Require<TXcomRuleItem>(Rules.Items.Find(AArticle.Id), AArticle.Id);
  LAmmo := LItem.CompatibleAmmo;
  if LItem.BattleType = TXcomRuleItem.BT_FIREARM then
    AddShotTable(LItem);
  for LIndex := 0 to 2 do
  begin
    FTxtAmmoType[LIndex] := TXcomText.Create(120, 9, 168, 144 + LIndex * 10);
    Add(FTxtAmmoType[LIndex]);
    FTxtAmmoType[LIndex].SetColor(TextColor);
    FTxtAmmoType[LIndex].SetWordWrap(True);
    FTxtAmmoDamage[LIndex] := TXcomText.Create(20, 9, 300, 144 + LIndex * 10);
    Add(FTxtAmmoDamage[LIndex]);
    FTxtAmmoDamage[LIndex].SetColor(BlockOffset(3) + 6);
  end;
  case LItem.BattleType of
    TXcomRuleItem.BT_FIREARM:
      if Length(LAmmo) = 0 then
      begin
        FTxtAmmoType[0].SetText(Tr(TXcomArticleFormat.DamageTypeText(LItem.DamageType)));
        FTxtAmmoDamage[0].SetText(TXcomArticleFormat.PowerText(LItem));
      end
      else
        for LIndex := 0 to Min(Length(LAmmo), 3) - 1 do
        begin
          LAmmoArticle := Require<TXcomArticleDefinition>(Rules.Articles.Find(LAmmo[LIndex]), LAmmo[LIndex]);
          if Catalog.IsArticleAvailable(LAmmoArticle) then
          begin
            LAmmoRule := Require<TXcomRuleItem>(Rules.Items.Find(LAmmo[LIndex]), LAmmo[LIndex]);
            FTxtAmmoType[LIndex].SetText(Tr(TXcomArticleFormat.DamageTypeText(LAmmoRule.DamageType)));
            FTxtAmmoDamage[LIndex].SetText(TXcomArticleFormat.PowerText(LAmmoRule));
          end;
        end;
    TXcomRuleItem.BT_AMMO, TXcomRuleItem.BT_GRENADE, TXcomRuleItem.BT_PROXIMITYGRENADE, TXcomRuleItem.BT_MELEE:
      begin
        FTxtAmmoType[0].SetText(Tr(TXcomArticleFormat.DamageTypeText(LItem.DamageType)));
        // here the C++ does not write the pellets
        FTxtAmmoDamage[0].SetText(TXcomArticleFormat.PowerText(LItem, False));
      end;
  end;
  if FTxtAmmoType[0].GetText <> '' then
    TxtInfo.SetHeight(112);
  CenterAllSurfaces;
end;

procedure TXcomArticleStateTftdItem.AddShotTable(AItem: TXcomRuleItem);
var
  LShots: TArray<TXcomArticleShot>;
  LRow: Integer;
begin
  FTxtShotType := TXcomText.Create(53, 17, 8, 157);
  Add(FTxtShotType);
  FTxtShotType.SetColor(TextColor);
  FTxtShotType.SetWordWrap(True);
  FTxtShotType.SetText(Tr('STR_SHOT_TYPE'));
  FTxtAccuracy := TXcomText.Create(57, 17, 61, 157);
  Add(FTxtAccuracy);
  FTxtAccuracy.SetColor(TextColor);
  FTxtAccuracy.SetWordWrap(True);
  FTxtAccuracy.SetText(Tr('STR_ACCURACY_UC'));
  FTxtTuCost := TXcomText.Create(56, 17, 118, 157);
  Add(FTxtTuCost);
  FTxtTuCost.SetColor(TextColor);
  FTxtTuCost.SetWordWrap(True);
  FTxtTuCost.SetText(Tr('STR_TIME_UNIT_COST'));
  FLstInfo := TXcomTextList.Create(Host.Options, Host.Clock, 140, 55, 8, 170);
  Add(FLstInfo);
  // the color of the percentages; the name of the shot takes the color of the texts
  FLstInfo.SetColor(ValueColor);
  FLstInfo.SetColumns([70, 40, 30]);
  LShots := TXcomArticleFormat.ShotRows(AItem);
  for LRow := 0 to High(LShots) do
  begin
    FLstInfo.AddRow([Tr(LShots[LRow].LabelId).Text, LShots[LRow].Accuracy, LShots[LRow].Cost]);
    FLstInfo.SetCellColor(LRow, 0, TextColor);
  end;
end;

end.
