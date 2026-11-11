{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - UfopaediaSelectState of OpenXcom (the   }
{  list of the articles of a section)                                           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.SelectState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Window,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList,
  DelphiDoom.XcomMod.ArticleDefinition, DelphiDoom.XcomUfopaedia.Intf;

type
  /// <summary>The available articles of a section, by title; a click opens the article</summary>
  TXcomUfopaediaSelectState = class(TXcomState)
  strict private
    FNavigator: IXcomUfopaediaNavigator;
    FArticles: TArray<TXcomArticleDefinition>;
    FWindow: TXcomWindow;
    FTxtTitle: TXcomText;
    FBtnOk: TXcomTextButton;
    FLstSelection: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure SelectionClick(AAction: TXcomAction);
  public
    /// <param name="ANavigator">Where a click on an article goes (shared, counted)</param>
    /// <param name="AArticles">The articles of the section (Ufopaedia::list; of the rules, not owned)</param>
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const AArticles: TArray<TXcomArticleDefinition>);
    property List: TXcomTextList read FLstSelection;
  end;

implementation

uses
  DelphiDoom.XcomUi.Types;

{ TXcomUfopaediaSelectState }

constructor TXcomUfopaediaSelectState.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const AArticles: TArray<TXcomArticleDefinition>);
var
  LArticle: TXcomArticleDefinition;
begin
  inherited Create(AHost);
  FNavigator := ANavigator;
  FArticles := AArticles;
  // _screen = false: the screen under the window stays visible
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 256, 180, 32, 10, wpNone);
  FTxtTitle := TXcomText.Create(224, 17, 48, 26);
  FBtnOk := TXcomTextButton.Create(224, 16, 48, 166);
  FLstSelection := TXcomTextList.Create(Host.Options, Host.Clock, 224, 104, 40, 50);
  SetInterface('ufopaedia');
  Add(FWindow, 'window', 'ufopaedia');
  Add(FTxtTitle, 'text', 'ufopaedia');
  Add(FBtnOk, 'button2', 'ufopaedia');
  Add(FLstSelection, 'list', 'ufopaedia');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_SELECT_ITEM'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FLstSelection.SetColumns([206]);
  FLstSelection.SetSelectable(True);
  FLstSelection.SetBackground(FWindow);
  FLstSelection.SetMargin(18);
  FLstSelection.SetAlign(haCenter);
  FLstSelection.OnMouseClick(SelectionClick);
  for LArticle in FArticles do
    FLstSelection.AddRow([Tr(LArticle.Title).Text]);
end;

procedure TXcomUfopaediaSelectState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomUfopaediaSelectState.SelectionClick(AAction: TXcomAction);
var
  LRow: Integer;
begin
  LRow := FLstSelection.GetSelectedRow;
  // an empty section still gives the row 0 (the C++ reads past the end of its list)
  if (LRow >= 0) and (LRow < Length(FArticles)) then
    FNavigator.OpenArticle(FArticles[LRow]);
end;

end.
