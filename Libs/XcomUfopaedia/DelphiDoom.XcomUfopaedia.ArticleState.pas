{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - ArticleState of OpenXcom (the base of   }
{  the articles: background and the OK, previous and next buttons)              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.ArticleState;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomMod.RuleCraft,
  DelphiDoom.XcomUfopaedia.Types, DelphiDoom.XcomUfopaedia.Intf;

type
  /// <summary>
  ///   The base of every article. It cannot be shown alone: the derived classes add their elements and call
  ///   InitLayout. The navigator and the catalog are shared with the other screens of the Ufopaedia
  /// </summary>
  TXcomArticleState = class abstract(TXcomState)
  strict private
    FId: string;
    FNavigator: IXcomUfopaediaNavigator;
    FCatalog: IXcomUfopaediaCatalog;
    FBackground: TXcomWidget;
    FBtnOk: TXcomTextButton;
    FBtnPrev: TXcomTextButton;
    FBtnNext: TXcomTextButton;
    procedure OkClick(AAction: TXcomAction);
    procedure PrevClick(AAction: TXcomAction);
    procedure NextClick(AAction: TXcomAction);
  protected
    /// <summary>ArticleState::initLayout: adds the background and the buttons and gives them texts and handlers</summary>
    procedure InitLayout;
    /// <summary>Palette::blockOffset: the first color of a block of 16</summary>
    class function BlockOffset(ABlock: Integer): Byte; static;
    /// <summary>The color of the three buttons</summary>
    procedure SetButtonColor(AColor: Byte);
    /// <summary>The rule that the article describes: a missing one is an error (Mod::getX(id, true))</summary>
    function Require<T: class>(ARule: T; const ARuleId: string): T;
    /// <summary>Mod::getSurface(name, false): nil when the picture does not exist</summary>
    function FindSurface(const AName: string): TXcomSurface;
    /// <summary>The seven lines of the statistics of a craft (the same in the UFO and in the TFTD article)</summary>
    function CraftStatsText(ACraft: TXcomRuleCraft): string;
    /// <summary>Adds rows of label and value to a list, translating the labels and the values that are ids</summary>
    procedure AddRows(AList: TXcomTextList; const ARows: TArray<TXcomArticleRow>);
    /// <summary>Gives the color to the second cell of every row of a list that has two cells</summary>
    procedure ColorValues(AList: TXcomTextList; const ARows: TArray<TXcomArticleRow>; AFirstRow: Integer;
      AColor: Byte);
    function Rules: TXcomRuleset;
    property Catalog: IXcomUfopaediaCatalog read FCatalog;
    property Background: TXcomWidget read FBackground;
    property BtnOk: TXcomTextButton read FBtnOk;
    property BtnPrev: TXcomTextButton read FBtnPrev;
    property BtnNext: TXcomTextButton read FBtnNext;
  public
    /// <param name="ANavigator">Where the buttons go (shared, counted)</param>
    /// <param name="ACatalog">The rules and the available articles (shared, counted)</param>
    /// <param name="AArticle">The article (of the rules, not owned)</param>
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition); virtual;
    /// <summary>ArticleState::getId</summary>
    property Id: string read FId;
  end;

  TXcomArticleStateClass = class of TXcomArticleState;

implementation

uses
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomBasescape.Funding;

const
  KEY_GEO_LEFT_OPTION = 'keyGeoLeft';
  KEY_GEO_RIGHT_OPTION = 'keyGeoRight';

{ TXcomArticleState }

constructor TXcomArticleState.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ACatalog: IXcomUfopaediaCatalog; AArticle: TXcomArticleDefinition);
begin
  inherited Create(AHost);
  FNavigator := ANavigator;
  FCatalog := ACatalog;
  FId := AArticle.Id;
  FBackground := TXcomWidget.Create(320, 200, 0, 0);
  FBtnOk := TXcomTextButton.Create(30, 14, 5, 5);
  FBtnPrev := TXcomTextButton.Create(30, 14, 40, 5);
  FBtnNext := TXcomTextButton.Create(30, 14, 75, 5);
end;

class function TXcomArticleState.BlockOffset(ABlock: Integer): Byte;
begin
  Result := Byte(ABlock * 16);
end;

function TXcomArticleState.Rules: TXcomRuleset;
begin
  Result := FCatalog.Rules;
end;

procedure TXcomArticleState.InitLayout;
begin
  Add(FBackground);
  Add(FBtnOk);
  Add(FBtnPrev);
  Add(FBtnNext);
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnPrev.SetText('<<');
  FBtnPrev.OnMouseClick(PrevClick);
  FBtnPrev.OnKeyboardPress(PrevClick, Host.Options.GetValue(KEY_GEO_LEFT_OPTION));
  FBtnNext.SetText('>>');
  FBtnNext.OnMouseClick(NextClick);
  FBtnNext.OnKeyboardPress(NextClick, Host.Options.GetValue(KEY_GEO_RIGHT_OPTION));
end;

procedure TXcomArticleState.SetButtonColor(AColor: Byte);
begin
  FBtnOk.SetColor(AColor);
  FBtnPrev.SetColor(AColor);
  FBtnNext.SetColor(AColor);
end;

function TXcomArticleState.Require<T>(ARule: T; const ARuleId: string): T;
begin
  if not Assigned(ARule) then
    raise EXcomUfopaediaException.CreateFmt(SXcomUfopaediaNoRule, [FId, ARuleId]);
  Result := ARule;
end;

function TXcomArticleState.FindSurface(const AName: string): TXcomSurface;
begin
  // the resources have no question "is this picture there": a missing one is their exception
  try
    Result := Host.Resources.GetSurface(AName);
  except
    on EXcomEngineException do
      Result := nil;
  end;
end;

function TXcomArticleState.CraftStatsText(ACraft: TXcomRuleCraft): string;
begin
  Result := Tr('STR_MAXIMUM_SPEED_UC').Arg(TXcomFunding.FormatNumber(ACraft.MaxSpeed, '')).Text + #10 +
    Tr('STR_ACCELERATION').Arg(ACraft.Acceleration).Text + #10 +
    Tr('STR_FUEL_CAPACITY').Arg(TXcomFunding.FormatNumber(ACraft.MaxFuel, '')).Text + #10 +
    Tr('STR_WEAPON_PODS').Arg(ACraft.Weapons).Text + #10 +
    Tr('STR_DAMAGE_CAPACITY_UC').Arg(TXcomFunding.FormatNumber(ACraft.MaxDamage, '')).Text + #10 +
    Tr('STR_CARGO_SPACE').Arg(ACraft.Soldiers).Text + #10 +
    Tr('STR_HWP_CAPACITY').Arg(ACraft.Vehicles).Text;
end;

procedure TXcomArticleState.AddRows(AList: TXcomTextList; const ARows: TArray<TXcomArticleRow>);
var
  LRow: TXcomArticleRow;
begin
  for LRow in ARows do
    if LRow.Blank then
      AList.AddRow([])
    else if LRow.ValueIsId then
      AList.AddRow([Tr(LRow.LabelId).Text, Tr(LRow.Value).Text])
    else
      AList.AddRow([Tr(LRow.LabelId).Text, LRow.Value]);
end;

procedure TXcomArticleState.ColorValues(AList: TXcomTextList; const ARows: TArray<TXcomArticleRow>;
  AFirstRow: Integer; AColor: Byte);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(ARows) do
    if not ARows[LIndex].Blank then
      AList.SetCellColor(AFirstRow + LIndex, 1, AColor);
end;

procedure TXcomArticleState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomArticleState.PrevClick(AAction: TXcomAction);
begin
  FNavigator.Prev;
end;

procedure TXcomArticleState.NextClick(AAction: TXcomAction);
begin
  FNavigator.Next;
end;

end.
