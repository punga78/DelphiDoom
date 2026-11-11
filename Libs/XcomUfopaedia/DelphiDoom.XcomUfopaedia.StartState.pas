{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ufopaedia library - UfopaediaStartState of OpenXcom (the    }
{  buttons of the sections)                                                     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUfopaedia.StartState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.ArrowButton, DelphiDoom.XcomUfopaedia.Intf;

type
  /// <summary>
  ///   The screen that the Ufopaedia button of the geoscape opens: a button for each section (at most ten, the
  ///   others by scrolling) that opens the list of its articles
  /// </summary>
  TXcomUfopaediaStartState = class(TXcomState)
  public
    const
      CAT_MIN_BUTTONS = 9;
      CAT_MAX_BUTTONS = 10;
  strict private
    FNavigator: IXcomUfopaediaNavigator;
    FSections: TArray<string>;
    FWindow: TXcomWindow;
    FTxtTitle: TXcomText;
    FBtnOk: TXcomTextButton;
    FBtnSections: TList<TXcomTextButton>;
    FBtnScrollUp: TXcomArrowButton;
    FBtnScrollDown: TXcomArrowButton;
    FTimerScroll: TXcomTimer;
    FOffset: Integer;
    FScroll: Integer;
    procedure OkClick(AAction: TXcomAction);
    procedure SectionClick(AAction: TXcomAction);
    procedure ScrollUpPress(AAction: TXcomAction);
    procedure ScrollUpClick(AAction: TXcomAction);
    procedure ScrollDownPress(AAction: TXcomAction);
    procedure ScrollDownClick(AAction: TXcomAction);
    procedure ScrollRelease(AAction: TXcomAction);
    procedure Scroll;
    procedure UpdateButtons;
  public
    /// <param name="ANavigator">Where the buttons go (shared, counted)</param>
    /// <param name="ASections">The sections in the order of the buttons (Mod::getUfopaediaCategoryList)</param>
    constructor Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
      const ASections: TArray<string>);
    destructor Destroy; override;
    procedure Think; override;
    /// <summary>The first section shown (the scroll position)</summary>
    property Offset: Integer read FOffset;
    /// <summary>How many section buttons the screen has</summary>
    function ButtonCount: Integer;
    /// <summary>The section that a button opens now</summary>
    function ButtonSection(AIndex: Integer): string;
  end;

implementation

uses
  System.Math, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Math;

const
  KEY_GEO_UFOPEDIA_OPTION = 'keyGeoUfopedia';
  SCROLL_INTERVAL = 50;

{ TXcomUfopaediaStartState }

constructor TXcomUfopaediaStartState.Create(AHost: TXcomStateHost; const ANavigator: IXcomUfopaediaNavigator;
  const ASections: TArray<string>);
var
  LY, LButtons, LIndex: Integer;
  LButton: TXcomTextButton;
  LScrollable: Boolean;
begin
  inherited Create(AHost);
  FNavigator := ANavigator;
  FSections := ASections;
  FBtnSections := TList<TXcomTextButton>.Create;
  // _screen = false: the geoscape stays visible around the window
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 256, 180, 32, 10, wpBoth);
  FTxtTitle := TXcomText.Create(220, 17, 50, 33);
  SetInterface('ufopaedia');
  Add(FWindow, 'window', 'ufopaedia');
  Add(FTxtTitle, 'text', 'ufopaedia');
  FBtnOk := TXcomTextButton.Create(220, 12, 50, 167);
  Add(FBtnOk, 'button1', 'ufopaedia');
  // nine buttons start at 50; a tenth one moves all of them up
  LY := 50;
  LButtons := Min(Length(FSections), CAT_MAX_BUTTONS);
  if LButtons > CAT_MIN_BUTTONS then
    Dec(LY, 13 * (LButtons - CAT_MIN_BUTTONS));
  FBtnScrollUp := TXcomArrowButton.Create(Host.Clock, arBigUp, 13, 14, 270, LY);
  Add(FBtnScrollUp, 'button1', 'ufopaedia');
  FBtnScrollDown := TXcomArrowButton.Create(Host.Clock, arBigDown, 13, 14, 270, 152);
  Add(FBtnScrollDown, 'button1', 'ufopaedia');
  for LIndex := 0 to LButtons - 1 do
  begin
    LButton := TXcomTextButton.Create(220, 12, 50, LY);
    Inc(LY, 13);
    Add(LButton, 'button1', 'ufopaedia');
    LButton.OnMouseClick(SectionClick);
    LButton.OnMousePress(ScrollUpClick, XCOM_BUTTON_WHEELUP);
    LButton.OnMousePress(ScrollDownClick, XCOM_BUTTON_WHEELDOWN);
    FBtnSections.Add(LButton);
  end;
  UpdateButtons;
  if FBtnSections.Count > 0 then
    FTxtTitle.Y := FBtnSections.First.Y - FTxtTitle.Height;
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_UFOPAEDIA'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.GetValue(KEY_GEO_UFOPEDIA_OPTION));
  LScrollable := Length(FSections) > CAT_MAX_BUTTONS;
  FBtnScrollUp.Visible := LScrollable;
  FBtnScrollUp.OnMousePress(ScrollUpPress);
  FBtnScrollUp.OnMouseRelease(ScrollRelease);
  FBtnScrollDown.Visible := LScrollable;
  FBtnScrollDown.OnMousePress(ScrollDownPress);
  FBtnScrollDown.OnMouseRelease(ScrollRelease);
  FTimerScroll := TXcomTimer.Create(Host.Clock, SCROLL_INTERVAL);
  FTimerScroll.OnTimerState(Scroll);
end;

destructor TXcomUfopaediaStartState.Destroy;
begin
  FTimerScroll.Free;
  FBtnSections.Free;
  inherited Destroy;
end;

procedure TXcomUfopaediaStartState.Think;
begin
  inherited Think;
  FTimerScroll.Think(True, False);
end;

function TXcomUfopaediaStartState.ButtonCount: Integer;
begin
  Result := FBtnSections.Count;
end;

function TXcomUfopaediaStartState.ButtonSection(AIndex: Integer): string;
begin
  Result := FSections[FOffset + AIndex];
end;

procedure TXcomUfopaediaStartState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomUfopaediaStartState.SectionClick(AAction: TXcomAction);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FBtnSections.Count - 1 do
    if AAction.Sender = FBtnSections[LIndex] then
    begin
      FNavigator.OpenSection(FSections[FOffset + LIndex]);
      Break;
    end;
end;

procedure TXcomUfopaediaStartState.ScrollUpPress(AAction: TXcomAction);
begin
  FScroll := -1;
  FTimerScroll.Start;
end;

procedure TXcomUfopaediaStartState.ScrollUpClick(AAction: TXcomAction);
begin
  FScroll := -1;
  Scroll;
end;

procedure TXcomUfopaediaStartState.ScrollDownPress(AAction: TXcomAction);
begin
  FScroll := 1;
  FTimerScroll.Start;
end;

procedure TXcomUfopaediaStartState.ScrollDownClick(AAction: TXcomAction);
begin
  FScroll := 1;
  Scroll;
end;

procedure TXcomUfopaediaStartState.ScrollRelease(AAction: TXcomAction);
begin
  FTimerScroll.Stop;
end;

procedure TXcomUfopaediaStartState.Scroll;
begin
  if Length(FSections) > CAT_MAX_BUTTONS then
  begin
    FOffset := TXcomMath.Clamp(FOffset + FScroll, 0, Length(FSections) - CAT_MAX_BUTTONS);
    UpdateButtons;
  end;
end;

procedure TXcomUfopaediaStartState.UpdateButtons;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FBtnSections.Count - 1 do
    FBtnSections[LIndex].SetText(Tr(FSections[FOffset + LIndex]));
end;

end.
