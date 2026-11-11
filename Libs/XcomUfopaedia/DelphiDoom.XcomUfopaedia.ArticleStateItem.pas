{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleStateItem of OpenXcom            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleStateItem;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomUfopaedia.Intf, DelphiDoom.XcomUfopaedia.ArticleState;

type
  /// <summary>
  ///   An article of an item: title, the picture of the item in the hand, the table of the shots of a firearm, a
  ///   text and a column with the damage of the item or of its three first kinds of ammunition
  /// </summary>
  TXcomArticleStateItem = class(TXcomArticleState)
  strict private
    FImage: TXcomWidget;
    FTxtTitle: TXcomText;
    FTxtInfo: TXcomText;
    FLstInfo: TXcomTextList;
    FTxtShotType: TXcomText;
    FTxtAccuracy: TXcomText;
    FTxtTuCost: TXcomText;
    FTxtDamage: TXcomText;
    FTxtAmmo: TXcomText;
    FTxtAmmoType: array[0..2] of TXcomText;
    FTxtAmmoDamage: array[0..2] of TXcomText;
    FImageAmmo: array[0..2] of TXcomWidget;
    /// <summary>RuleItem::drawHandSprite: the big sprite of the item in the middle of a hand of 2 x 3 slots</summary>
    procedure DrawHandSprite(AItem: TXcomRuleItem; ATarget: TXcomWidget);
    procedure AddDamageTitle;
    procedure AddShotTable(AItem: TXcomRuleItem);
  public
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); override;
  end;

implementation

uses
  System.Math, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUfopaedia.Types, DelphiDoom.XcomUfopaedia.ArticleFormat;

const
  // RuleInventory: the hand is 2 x 3 slots of 16 pixels
  HAND_WIDTH = 2;
  HAND_HEIGHT = 3;
  SLOT_SIZE = 16;

{ TXcomArticleStateItem }

constructor TXcomArticleStateItem.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
var
  LItem, LAmmoRule: TXcomRuleItem;
  LAmmoArticle: TXcomArticleDefinition;
  LAmmo: TArray<string>;
  LIndex: Integer;
begin
  inherited Create(AHost, ANavigator, ACatalog, AArticle);
  LItem := Require<TXcomRuleItem>(Rules.Items.Find(AArticle.Id), AArticle.Id);
  FTxtTitle := TXcomText.Create(148, 32, 5, 24);
  SetPalette('PAL_BATTLEPEDIA', -1);
  InitLayout;
  Add(FTxtTitle);
  Host.Resources.GetSurface('BACK08.SCR').Blit(Background);
  SetButtonColor(BlockOffset(9));
  FTxtTitle.SetColor(BlockOffset(14) + 15);
  FTxtTitle.SetBig;
  FTxtTitle.SetWordWrap(True);
  FTxtTitle.SetText(Tr(AArticle.Title));
  FImage := TXcomWidget.Create(32, 48, 157, 5);
  Add(FImage);
  DrawHandSprite(LItem, FImage);
  LAmmo := LItem.CompatibleAmmo;
  if LItem.BattleType = TXcomRuleItem.BT_FIREARM then
  begin
    AddShotTable(LItem);
    // the text is under the table, narrower when the three rows of ammunition reach down to it
    FTxtInfo := TXcomText.Create(IfThen(Length(LAmmo) < 3, 300, 180), 56, 8, 138);
  end
  else
    // the text is larger and starts on top
    FTxtInfo := TXcomText.Create(300, 125, 8, 67);
  Add(FTxtInfo);
  FTxtInfo.SetColor(BlockOffset(14) + 15);
  FTxtInfo.SetWordWrap(True);
  FTxtInfo.SetScrollable(True);
  FTxtInfo.SetText(Tr(AArticle.Text));
  for LIndex := 0 to 2 do
  begin
    FTxtAmmoType[LIndex] := TXcomText.Create(82, 16, 194, 20 + LIndex * 49);
    Add(FTxtAmmoType[LIndex]);
    FTxtAmmoType[LIndex].SetColor(BlockOffset(14) + 15);
    FTxtAmmoType[LIndex].SetAlign(haCenter);
    FTxtAmmoType[LIndex].SetVerticalAlign(vaMiddle);
    FTxtAmmoType[LIndex].SetWordWrap(True);
    FTxtAmmoDamage[LIndex] := TXcomText.Create(82, 17, 194, 40 + LIndex * 49);
    Add(FTxtAmmoDamage[LIndex]);
    FTxtAmmoDamage[LIndex].SetColor(BlockOffset(2));
    FTxtAmmoDamage[LIndex].SetAlign(haCenter);
    FTxtAmmoDamage[LIndex].SetBig;
    FImageAmmo[LIndex] := TXcomWidget.Create(32, 48, 280, 16 + LIndex * 49);
    Add(FImageAmmo[LIndex]);
  end;
  case LItem.BattleType of
    TXcomRuleItem.BT_FIREARM:
      begin
        AddDamageTitle;
        FTxtAmmo := TXcomText.Create(50, 10, 268, 7);
        Add(FTxtAmmo);
        FTxtAmmo.SetColor(BlockOffset(14) + 15);
        FTxtAmmo.SetAlign(haCenter);
        FTxtAmmo.SetText(Tr('STR_AMMO'));
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
              DrawHandSprite(LAmmoRule, FImageAmmo[LIndex]);
            end;
          end;
      end;
    TXcomRuleItem.BT_AMMO, TXcomRuleItem.BT_GRENADE, TXcomRuleItem.BT_PROXIMITYGRENADE, TXcomRuleItem.BT_MELEE:
      begin
        AddDamageTitle;
        FTxtAmmoType[0].SetText(Tr(TXcomArticleFormat.DamageTypeText(LItem.DamageType)));
        FTxtAmmoDamage[0].SetText(TXcomArticleFormat.PowerText(LItem));
      end;
  end;
  CenterAllSurfaces;
end;

procedure TXcomArticleStateItem.AddDamageTitle;
begin
  FTxtDamage := TXcomText.Create(82, 10, 194, 7);
  Add(FTxtDamage);
  FTxtDamage.SetColor(BlockOffset(14) + 15);
  FTxtDamage.SetAlign(haCenter);
  FTxtDamage.SetText(Tr('STR_DAMAGE_UC'));
end;

procedure TXcomArticleStateItem.AddShotTable(AItem: TXcomRuleItem);
var
  LShots: TArray<TXcomArticleShot>;
  LRow: Integer;
begin
  FTxtShotType := TXcomText.Create(100, 17, 8, 66);
  Add(FTxtShotType);
  FTxtShotType.SetColor(BlockOffset(14) + 15);
  FTxtShotType.SetWordWrap(True);
  FTxtShotType.SetText(Tr('STR_SHOT_TYPE'));
  FTxtAccuracy := TXcomText.Create(50, 17, 104, 66);
  Add(FTxtAccuracy);
  FTxtAccuracy.SetColor(BlockOffset(14) + 15);
  FTxtAccuracy.SetWordWrap(True);
  FTxtAccuracy.SetText(Tr('STR_ACCURACY_UC'));
  FTxtTuCost := TXcomText.Create(60, 17, 158, 66);
  Add(FTxtTuCost);
  FTxtTuCost.SetColor(BlockOffset(14) + 15);
  FTxtTuCost.SetWordWrap(True);
  FTxtTuCost.SetText(Tr('STR_TIME_UNIT_COST'));
  FLstInfo := TXcomTextList.Create(Host.Options, Host.Clock, 204, 55, 8, 82);
  Add(FLstInfo);
  // the color of the percentages; the name of the shot takes the color of the labels
  FLstInfo.SetColor(BlockOffset(15) + 4);
  FLstInfo.SetColumns([100, 52, 52]);
  FLstInfo.SetBig;
  LShots := TXcomArticleFormat.ShotRows(AItem);
  for LRow := 0 to High(LShots) do
  begin
    FLstInfo.AddRow([Tr(LShots[LRow].LabelId).Text, LShots[LRow].Accuracy, LShots[LRow].Cost]);
    FLstInfo.SetCellColor(LRow, 0, BlockOffset(14) + 15);
  end;
end;

procedure TXcomArticleStateItem.DrawHandSprite(AItem: TXcomRuleItem; ATarget: TXcomWidget);
var
  LTexture: TXcomSurfaceSet;
  LFrame: TXcomSurface;
begin
  LTexture := Catalog.Sprites('BIGOBS.PCK');
  // without the sprites of the battlescape the article has no picture
  if not Assigned(LTexture) then
    Exit;
  LFrame := LTexture.GetFrame(AItem.BigSprite);
  if not Assigned(LFrame) then
    Exit;
  LFrame.X := (HAND_WIDTH - AItem.InventoryWidth) * SLOT_SIZE div 2;
  LFrame.Y := (HAND_HEIGHT - AItem.InventoryHeight) * SLOT_SIZE div 2;
  LFrame.Blit(ATarget);
end;

end.
