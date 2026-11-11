{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - ComboBox of OpenXcom                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.ComboBox;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.UiSounds.Intf, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.ComboBoxLink,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomUi.Window;

type
  /// <summary>
  ///   A button that opens a list of options in a popup window: the list is modal while it is open. It owns its
  ///   button, arrow, window and list. As IXcomComboBoxLink it is not reference counted (the list points to it)
  /// </summary>
  TXcomComboBox = class(TXcomInteractiveSurface, IXcomComboBoxLink)
  strict private
    const
      HORIZONTAL_MARGIN = 2;
      VERTICAL_MARGIN = 3;
      MAX_ITEMS = 10;
      BUTTON_WIDTH = 14;
      TEXT_HEIGHT = 8;
    var
      FButton: TXcomTextButton;
      FArrow: TXcomSurface;
      FWindow: TXcomWindow;
      FList: TXcomTextList;
      FChange: TXcomActionHandler;
      FSel: Integer;
      FState: TXcomState;
      FLang: TXcomLanguage;
      FColor: Byte;
      FToggled: Boolean;
      FPopupAboveButton: Boolean;
    class function PopupWindowY(AButtonHeight, AButtonY, APopupHeight: Integer; APopupAbove: Boolean): Integer; static;
    procedure DrawArrow;
    procedure SetDropdown(AOptions: Integer);
  protected
    procedure SetX(AValue: Integer); override;
    procedure SetY(AValue: Integer); override;
    function QueryInterface(const AIID: TGUID; out AObj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    constructor Create(AState: TXcomState; AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0;
      APopupAboveButton: Boolean = False);
    destructor Destroy; override;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    procedure InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage); override;
    /// <summary>The button of the combo box makes the sound of a button</summary>
    procedure SetUiSounds(const ASounds: IXcomUiSounds); override;
    /// <summary>The picture of the window of the list (not owned)</summary>
    procedure SetBackground(ABackground: TXcomSurface);
    procedure SetColor(AColor: Byte); override;
    function GetColor: Byte; override;
    procedure SetHighContrast(AContrast: Boolean); override;
    procedure SetArrowColor(AColor: Byte);
    function GetSelected: Integer;
    /// <summary>ComboBox::getHoveredListIdx: the row under the mouse in the open list, else the selected one</summary>
    function GetHoveredListIdx: Integer;
    procedure SetText(const AText: string);
    procedure SetSelected(ASelected: Integer);
    procedure SetOptions(const AOptions: array of string; ATranslate: Boolean = False);
    procedure Blit(ATarget: TXcomSurface); override;
    procedure Think; override;
    procedure Handle(AAction: TXcomAction); override;
    /// <summary>ComboBox::toggle: opens or closes the list; AFirst is the call of the constructor (no change event)</summary>
    procedure Toggle(AFirst: Boolean = False);
    procedure ToggleList;
    procedure OnChange(const AHandler: TXcomActionHandler);
    procedure OnListMouseIn(const AHandler: TXcomActionHandler);
    procedure OnListMouseOut(const AHandler: TXcomActionHandler);
    procedure OnListMouseOver(const AHandler: TXcomActionHandler);
    property List: TXcomTextList read FList;
    property PopupWindow: TXcomWindow read FWindow;
    property Button: TXcomTextButton read FButton;
  end;

implementation

class function TXcomComboBox.PopupWindowY(AButtonHeight, AButtonY, APopupHeight: Integer;
  APopupAbove: Boolean): Integer;
begin
  if APopupAbove then
    // used when the popup list does not fit below the button: it is shown above
    Result := AButtonY - APopupHeight
  else
    Result := AButtonY + AButtonHeight;
end;

constructor TXcomComboBox.Create(AState: TXcomState; AWidth, AHeight, AX, AY: Integer; APopupAboveButton: Boolean);
var
  LPopupHeight: Integer;
  LPopupY: Integer;
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FState := AState;
  FPopupAboveButton := APopupAboveButton;
  FButton := TXcomTextButton.Create(AWidth, AHeight, AX, AY);
  FButton.SetComboToggle(
    procedure
    begin
      Toggle(False);
    end);
  FArrow := TXcomSurface.Create(11, 8, AX + AWidth - BUTTON_WIDTH, AY + 4);
  LPopupHeight := MAX_ITEMS * TEXT_HEIGHT + VERTICAL_MARGIN * 2;
  LPopupY := PopupWindowY(AHeight, AY, LPopupHeight, APopupAboveButton);
  FWindow := TXcomWindow.Create(AState, AWidth, LPopupHeight, AX, LPopupY);
  FWindow.SetThinBorder;
  FList := TXcomTextList.Create(AState.Host.Options, AState.Host.Clock, AWidth - HORIZONTAL_MARGIN * 2 - BUTTON_WIDTH + 1,
    LPopupHeight - (VERTICAL_MARGIN * 2 + 2), AX + HORIZONTAL_MARGIN, LPopupY + VERTICAL_MARGIN);
  FList.SetComboBox(Self);
  FList.SetColumns([FList.Width]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetAlign(haCenter);
  FList.SetScrolling(True, 0);
  Toggle(True);
end;

destructor TXcomComboBox.Destroy;
begin
  // the list points to this combo box, and the modal state to the list: the state forgets it first
  FList.SetComboBox(nil);
  FList.Free;
  FWindow.Free;
  FArrow.Free;
  FButton.Free;
  inherited Destroy;
end;

function TXcomComboBox.QueryInterface(const AIID: TGUID; out AObj): HResult;
begin
  if GetInterface(AIID, AObj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TXcomComboBox._AddRef: Integer;
begin
  Result := -1;
end;

function TXcomComboBox._Release: Integer;
begin
  Result := -1;
end;

procedure TXcomComboBox.SetX(AValue: Integer);
begin
  inherited SetX(AValue);
  FButton.X := AValue;
  FArrow.X := AValue + Width - BUTTON_WIDTH;
  FWindow.X := AValue;
  FList.X := AValue + HORIZONTAL_MARGIN;
end;

procedure TXcomComboBox.SetY(AValue: Integer);
var
  LPopupY: Integer;
begin
  inherited SetY(AValue);
  FButton.Y := AValue;
  FArrow.Y := AValue + 4;
  LPopupY := PopupWindowY(Height, AValue, FWindow.Height, FPopupAboveButton);
  FWindow.Y := LPopupY;
  FList.Y := LPopupY + VERTICAL_MARGIN;
end;

procedure TXcomComboBox.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
var
  LColors: TArray<TXcomColor>;
begin
  inherited SetPalette(AColors, AFirst, ACount);
  FButton.SetPalette(AColors, AFirst, ACount);
  if ACount > 0 then
  begin
    SetLength(LColors, ACount);
    Move(AColors^, LColors[0], ACount * SizeOf(TXcomColor));
    FArrow.SetColors(LColors, AFirst);
  end;
  FWindow.SetPalette(AColors, AFirst, ACount);
  FList.SetPalette(AColors, AFirst, ACount);
end;

procedure TXcomComboBox.SetUiSounds(const ASounds: IXcomUiSounds);
begin
  FButton.SetUiSounds(ASounds);
end;

procedure TXcomComboBox.InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage);
begin
  FLang := ALanguage;
  FButton.InitText(ABig, ASmall, ALanguage);
  FList.InitText(ABig, ASmall, ALanguage);
end;

procedure TXcomComboBox.SetBackground(ABackground: TXcomSurface);
begin
  FWindow.SetBackground(ABackground);
end;

procedure TXcomComboBox.SetColor(AColor: Byte);
begin
  FColor := AColor;
  DrawArrow;
  FButton.SetColor(FColor);
  FWindow.SetColor(FColor);
  FList.SetColor(FColor);
end;

function TXcomComboBox.GetColor: Byte;
begin
  Result := FColor;
end;

procedure TXcomComboBox.DrawArrow;
var
  LColor: Integer;
  LX: Integer;
  LY: Integer;
  LW: Integer;
begin
  FArrow.Clear;
  LColor := FColor + 1;
  if LColor = 256 then
    Inc(LColor);
  LX := 1;
  LY := 2;
  LW := 9;
  while LW > 1 do
  begin
    FArrow.DrawRect(TXcomRect.Make(LX, LY, LW, 1), Byte(LColor + 2));
    Inc(LX);
    Inc(LY);
    Dec(LW, 2);
  end;
  FArrow.DrawRect(TXcomRect.Make(LX, LY, LW, 1), Byte(LColor + 2));
  LX := 2;
  LY := 2;
  LW := 7;
  while LW > 1 do
  begin
    FArrow.DrawRect(TXcomRect.Make(LX, LY, LW, 1), Byte(LColor));
    Inc(LX);
    Inc(LY);
    Dec(LW, 2);
  end;
  FArrow.DrawRect(TXcomRect.Make(LX, LY, LW, 1), Byte(LColor));
end;

procedure TXcomComboBox.SetHighContrast(AContrast: Boolean);
begin
  FButton.SetHighContrast(AContrast);
  FWindow.SetHighContrast(AContrast);
  FList.SetHighContrast(AContrast);
end;

procedure TXcomComboBox.SetArrowColor(AColor: Byte);
begin
  FList.SetArrowColor(AColor);
end;

function TXcomComboBox.GetSelected: Integer;
begin
  Result := FSel;
end;

function TXcomComboBox.GetHoveredListIdx: Integer;
begin
  Result := -1;
  if FList.Visible then
    Result := FList.GetSelectedRow;
  if Result = -1 then
    Result := FSel;
end;

procedure TXcomComboBox.SetText(const AText: string);
begin
  FButton.SetText(AText);
end;

procedure TXcomComboBox.SetSelected(ASelected: Integer);
begin
  FSel := ASelected;
  if (FSel >= 0) and (FSel < FList.GetTexts) then
    FButton.SetText(FList.GetCellText(FSel, 0));
end;

procedure TXcomComboBox.SetDropdown(AOptions: Integer);
var
  LItems: Integer;
  LHeight: Integer;
  LDY: Integer;
  LPopupHeight: Integer;
  LPopupY: Integer;
begin
  LItems := Min(AOptions, MAX_ITEMS);
  LHeight := FButton.GetFont.Height + FButton.GetFont.Spacing;
  LDY := (FState.Host.Options.BaseYResolution - 200) div 2;
  while FWindow.Y + LItems * LHeight + VERTICAL_MARGIN * 2 > 200 + LDY do
    Dec(LItems);
  LPopupHeight := LItems * LHeight + VERTICAL_MARGIN * 2;
  LPopupY := PopupWindowY(Height, Y, LPopupHeight, FPopupAboveButton);
  FWindow.Y := LPopupY;
  FWindow.SetHeight(LPopupHeight);
  FList.Y := LPopupY + VERTICAL_MARGIN;
  FList.SetHeight(LItems * LHeight);
end;

procedure TXcomComboBox.SetOptions(const AOptions: array of string; ATranslate: Boolean);
var
  LOption: string;
begin
  SetDropdown(Length(AOptions));
  FList.ClearList;
  for LOption in AOptions do
  begin
    if ATranslate then
      FList.AddRow([FLang.GetString(LOption).Text])
    else
      FList.AddRow([LOption]);
  end;
  SetSelected(FSel);
end;

procedure TXcomComboBox.Blit(ATarget: TXcomSurface);
begin
  inherited Blit(ATarget);
  FList.Invalidate;
  if Visible and not Hidden then
  begin
    FButton.Blit(ATarget);
    FArrow.Blit(ATarget);
    FWindow.Blit(ATarget);
    FList.Blit(ATarget);
  end;
end;

procedure TXcomComboBox.Handle(AAction: TXcomAction);
var
  LTopY: Integer;
begin
  FButton.Handle(AAction);
  FList.Handle(AAction);
  inherited Handle(AAction);
  LTopY := Min(Y, FWindow.Y);
  if FWindow.Visible and (AAction.Details^.Kind = ekMouseDown) and
    ((AAction.AbsoluteXMouse < X) or (AAction.AbsoluteXMouse >= X + Width) or (AAction.AbsoluteYMouse < LTopY) or
    (AAction.AbsoluteYMouse >= LTopY + Height + FWindow.Height)) then
    Toggle;
  if FToggled then
  begin
    if Assigned(FChange) then
      FChange(AAction);
    FToggled := False;
  end;
end;

procedure TXcomComboBox.Think;
begin
  FButton.Think;
  FWindow.Think;
  FList.Think;
  inherited Think;
end;

procedure TXcomComboBox.Toggle(AFirst: Boolean);
begin
  FWindow.Visible := not FWindow.Visible;
  FList.Visible := not FList.Visible;
  if FWindow.Visible then
    FState.SetModal(Self)
  else
    FState.SetModal(nil);
  if (not AFirst) and (not FWindow.Visible) then
    FToggled := True;
  if FList.Visible then
  begin
    // _sel is a size_t in the C++: -1 (nothing selected) is a huge number and the list scrolls to the end
    if FSel < 0 then
      FList.ScrollTo(MaxInt)
    else if FSel < FList.GetVisibleRows div 2 then
      FList.ScrollTo(0)
    else
      FList.ScrollTo(FSel - FList.GetVisibleRows div 2);
  end;
end;

procedure TXcomComboBox.ToggleList;
begin
  Toggle(False);
end;

procedure TXcomComboBox.OnChange(const AHandler: TXcomActionHandler);
begin
  FChange := AHandler;
end;

procedure TXcomComboBox.OnListMouseIn(const AHandler: TXcomActionHandler);
begin
  FList.OnMouseIn(AHandler);
end;

procedure TXcomComboBox.OnListMouseOut(const AHandler: TXcomActionHandler);
begin
  FList.OnMouseOut(AHandler);
end;

procedure TXcomComboBox.OnListMouseOver(const AHandler: TXcomActionHandler);
begin
  FList.OnMouseOver(AHandler);
end;

end.
