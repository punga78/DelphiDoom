{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - TextButton of OpenXcom                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.TextButton;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Font, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.InteractiveSurface,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Text;

type
  TXcomTextButton = class;

  /// <summary>
  ///   The variable that a group of buttons shares (the TextButton ** of the C++): the button that is selected. The
  ///   owner of the group (a state) frees it
  /// </summary>
  TXcomButtonGroup = class
  public
    Selected: TXcomTextButton;
  end;

  /// <summary>A button with a text: a border of five shades that is inverted while it is pressed</summary>
  TXcomTextButton = class(TXcomInteractiveSurface)
  strict private
    FColor: Byte;
    FText: TXcomText;
    FGroup: TXcomButtonGroup;
    FContrast: Boolean;
    FGeoscapeButton: Boolean;
    FToggleCombo: TXcomNotify;
  protected
    procedure MousePress(AAction: TXcomAction); override;
    procedure MouseRelease(AAction: TXcomAction); override;
    /// <summary>InteractiveSurface::mousePress, skipping the code of TextButton (what ToggleTextButton does)</summary>
    procedure InteractiveMousePress(AAction: TXcomAction);
  public
    constructor Create(AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0);
    destructor Destroy; override;
    function IsButtonHandled(AButton: Integer = 0): Boolean; override;
    procedure SetColor(AColor: Byte); override;
    function GetColor: Byte; override;
    procedure SetTextColor(AColor: Byte);
    procedure SetBig;
    procedure SetSmall;
    function GetFont: TXcomFont;
    procedure InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage); override;
    procedure SetHighContrast(AContrast: Boolean); override;
    procedure SetText(const AText: string);
    function GetText: string;
    /// <summary>TextButton::setGroup: the button is pressed while it is the selected one of the group</summary>
    procedure SetGroup(AGroup: TXcomButtonGroup);
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    procedure Draw; override;
    /// <summary>
    ///   TextButton::setComboBox: the button opens a combo box; AToggle is what a press calls (nil: not a combo
    ///   box button). The text moves 6 pixels to the left
    /// </summary>
    procedure SetComboToggle(const AToggle: TXcomNotify);
    procedure SetWidth(AWidth: Integer); override;
    procedure SetHeight(AHeight: Integer); override;
    procedure SetGeoscapeButton(AGeoscape: Boolean);
  end;

implementation

constructor TXcomTextButton.Create(AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FText := TXcomText.Create(AWidth, AHeight, 0, 0);
  FText.SetSmall;
  FText.SetAlign(haCenter);
  FText.SetVerticalAlign(vaMiddle);
  FText.SetWordWrap(True);
end;

destructor TXcomTextButton.Destroy;
begin
  FText.Free;
  inherited Destroy;
end;

function TXcomTextButton.IsButtonHandled(AButton: Integer): Boolean;
begin
  if Assigned(FToggleCombo) then
    Result := AButton = XCOM_BUTTON_LEFT
  else
    Result := inherited IsButtonHandled(AButton);
end;

procedure TXcomTextButton.SetColor(AColor: Byte);
begin
  FColor := AColor;
  FText.SetColor(AColor);
  Redraw := True;
end;

function TXcomTextButton.GetColor: Byte;
begin
  Result := FColor;
end;

procedure TXcomTextButton.SetTextColor(AColor: Byte);
begin
  FText.SetColor(AColor);
  Redraw := True;
end;

procedure TXcomTextButton.SetBig;
begin
  FText.SetBig;
  Redraw := True;
end;

procedure TXcomTextButton.SetSmall;
begin
  FText.SetSmall;
  Redraw := True;
end;

function TXcomTextButton.GetFont: TXcomFont;
begin
  Result := FText.GetFont;
end;

procedure TXcomTextButton.InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage);
begin
  FText.InitText(ABig, ASmall, ALanguage);
  Redraw := True;
end;

procedure TXcomTextButton.SetHighContrast(AContrast: Boolean);
begin
  FContrast := AContrast;
  FText.SetHighContrast(AContrast);
  Redraw := True;
end;

procedure TXcomTextButton.SetText(const AText: string);
begin
  FText.SetText(AText);
  Redraw := True;
end;

function TXcomTextButton.GetText: string;
begin
  Result := FText.GetText;
end;

procedure TXcomTextButton.SetGroup(AGroup: TXcomButtonGroup);
begin
  FGroup := AGroup;
  Redraw := True;
end;

procedure TXcomTextButton.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
begin
  inherited SetPalette(AColors, AFirst, ACount);
  FText.SetPalette(AColors, AFirst, ACount);
end;

procedure TXcomTextButton.Draw;
var
  LX: Integer;
  LY: Integer;
  LW: Integer;
  LH: Integer;
  LMultiplier: Integer;
  LColor: Integer;
  LIndex: Integer;
  LPressed: Boolean;
begin
  inherited Draw;
  LMultiplier := 1;
  if FContrast then
    LMultiplier := 2;
  LColor := FColor + 1 * LMultiplier;
  LX := 0;
  LY := 0;
  LW := Width;
  LH := Height;
  for LIndex := 0 to 4 do
  begin
    DrawRect(TXcomRect.Make(LX, LY, LW, LH), Byte(LColor));
    if LIndex mod 2 = 0 then
    begin
      Inc(LX);
      Inc(LY);
    end;
    LW := (LW - 1) and $FFFF;
    LH := (LH - 1) and $FFFF;
    case LIndex of
      0:
        begin
          LColor := FColor + 5 * LMultiplier;
          SetPixel(LW, 0, Byte(LColor));
        end;
      1:
        LColor := FColor + 2 * LMultiplier;
      2:
        begin
          LColor := FColor + 4 * LMultiplier;
          SetPixel(LW + 1, 1, Byte(LColor));
        end;
      3:
        LColor := FColor + 3 * LMultiplier;
      4:
        if FGeoscapeButton then
        begin
          SetPixel(0, 0, FColor);
          SetPixel(1, 1, FColor);
        end;
    end;
  end;
  if FGroup = nil then
    LPressed := IsButtonPressed
  else
    LPressed := FGroup.Selected = Self;
  if LPressed then
  begin
    if FGeoscapeButton then
      Invert(Byte(FColor + 2 * LMultiplier))
    else
      Invert(Byte(FColor + 3 * LMultiplier));
  end;
  FText.SetInvert(LPressed);
  FText.Blit(Self);
end;

procedure TXcomTextButton.MousePress(AAction: TXcomAction);
var
  LOld: TXcomTextButton;
begin
  if (AAction.Details^.Button = XCOM_BUTTON_LEFT) and (FGroup <> nil) then
  begin
    LOld := FGroup.Selected;
    FGroup.Selected := Self;
    if LOld <> nil then
      LOld.Draw;
    Draw;
  end;
  if IsButtonHandled(AAction.Details^.Button) then
  begin
    if Assigned(FToggleCombo) then
      FToggleCombo();
    Draw;
  end;
  inherited MousePress(AAction);
end;

procedure TXcomTextButton.InteractiveMousePress(AAction: TXcomAction);
begin
  inherited MousePress(AAction);
end;

procedure TXcomTextButton.MouseRelease(AAction: TXcomAction);
begin
  if IsButtonHandled(AAction.Details^.Button) then
    Draw;
  inherited MouseRelease(AAction);
end;

procedure TXcomTextButton.SetComboToggle(const AToggle: TXcomNotify);
begin
  FToggleCombo := AToggle;
  if Assigned(AToggle) then
    FText.X := -6
  else
    FText.X := 0;
end;

procedure TXcomTextButton.SetWidth(AWidth: Integer);
begin
  inherited SetWidth(AWidth);
  FText.SetWidth(AWidth);
end;

procedure TXcomTextButton.SetHeight(AHeight: Integer);
begin
  inherited SetHeight(AHeight);
  FText.SetHeight(AHeight);
end;

procedure TXcomTextButton.SetGeoscapeButton(AGeoscape: Boolean);
begin
  FGeoscapeButton := AGeoscape;
end;

end.
