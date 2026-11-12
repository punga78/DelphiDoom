{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - TextEdit of OpenXcom                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.TextEdit;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.WidgetInk;

type
  /// <summary>TextEditConstraint: what can be typed</summary>
  TXcomTextEditConstraint = (tecNone, tecNumericPositive, tecNumeric);

  /// <summary>
  ///   A text box for a line of text: it takes the focus with a click, shows a blinking caret and edits the text
  ///   with the keyboard (or, with the keyboard off, with the arrows: up and down pick a letter, right adds it,
  ///   left removes one). The text is a string of 16 bit characters, like the unicode field of SDL 1.2. The key
  ///   repeat of SDL is not set (the device does it, if at all)
  /// </summary>
  TXcomTextEdit = class(TXcomInteractiveSurface)
  strict private
    FText: TXcomText;
    FCaret: TXcomText;
    FValue: string;
    FBlink: Boolean;
    FModal: Boolean;
    FTimer: TXcomTimer;
    FChar: Integer;
    FCaretPos: Integer;
    FConstraint: TXcomTextEditConstraint;
    FChange: TXcomActionHandler;
    FState: TXcomState;
    FInk: TXcomWidgetInk;
    function ExceedsMaxWidth(ACode: Integer): Boolean;
    function IsValidChar(ACode: Integer): Boolean;
    procedure DoBlink;
  protected
    procedure MousePress(AAction: TXcomAction); override;
    procedure KeyboardPress(AAction: TXcomAction); override;
  public
    constructor Create(AState: TXcomState; AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0);
    destructor Destroy; override;
    procedure Handle(AAction: TXcomAction); override;
    procedure SetFocus(AFocus: Boolean); overload; override;
    procedure SetFocus(AFocus, AModal: Boolean); reintroduce; overload;
    procedure SetBig;
    procedure SetSmall;
    procedure InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage); override;
    procedure SetText(const AText: string);
    function GetText: string;
    procedure SetWordWrap(AWrap: Boolean);
    procedure SetInvert(AInvert: Boolean);
    procedure SetHighContrast(AContrast: Boolean); override;
    procedure SetAlign(AAlign: TXcomTextHAlign);
    procedure SetVerticalAlign(AAlign: TXcomTextVAlign);
    procedure SetConstraint(AConstraint: TXcomTextEditConstraint);
    procedure SetColor(AColor: Byte); override;
    function GetColor: Byte; override;
    procedure SetSecondaryColor(AColor: Byte); override;
    function GetSecondaryColor: Byte;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    procedure Think; override;
    procedure Draw; override;
    /// <summary>Surface::blit; on the screen the box also leaves its characters at the resolution of the display (issue 184)</summary>
    procedure Blit(ATarget: TXcomSurface); override;
    procedure OnChange(const AHandler: TXcomActionHandler);
  end;

implementation

constructor TXcomTextEdit.Create(AState: TXcomState; AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FState := AState;
  FBlink := True;
  FModal := True;
  FChar := Ord('A');
  FConstraint := tecNone;
  // not focused at the start, without the effects of SetFocus
  inherited SetFocus(False);
  FText := TXcomText.Create(AWidth, AHeight, 0, 0);
  FTimer := TXcomTimer.Create(AState.Host.Clock, 100);
  FTimer.OnTimerSurface(
    procedure
    begin
      DoBlink;
    end);
  FCaret := TXcomText.Create(16, 17, 0, 0);
  FCaret.SetText('|');
  FInk := TXcomWidgetInk.Create;
end;

destructor TXcomTextEdit.Destroy;
begin
  FInk.Free;
  FText.Free;
  FCaret.Free;
  FTimer.Free;
  // in case it was left focused
  FState.SetModal(nil);
  inherited Destroy;
end;

procedure TXcomTextEdit.Handle(AAction: TXcomAction);
begin
  inherited Handle(AAction);
  if IsFocused and FModal and (AAction.Details^.Kind = ekMouseDown) and
    ((AAction.AbsoluteXMouse < X) or (AAction.AbsoluteXMouse >= X + Width) or (AAction.AbsoluteYMouse < Y) or
    (AAction.AbsoluteYMouse >= Y + Height)) then
    SetFocus(False);
end;

procedure TXcomTextEdit.SetFocus(AFocus: Boolean);
begin
  SetFocus(AFocus, True);
end;

procedure TXcomTextEdit.SetFocus(AFocus, AModal: Boolean);
begin
  FModal := AModal;
  if AFocus <> IsFocused then
  begin
    Redraw := True;
    inherited SetFocus(AFocus);
    if IsFocused then
    begin
      FCaretPos := Length(FValue);
      FBlink := True;
      FTimer.Start;
      if FModal then
        FState.SetModal(Self);
    end
    else
    begin
      FBlink := False;
      FTimer.Stop;
      if FModal then
        FState.SetModal(nil);
    end;
  end;
end;

procedure TXcomTextEdit.SetBig;
begin
  FText.SetBig;
  FCaret.SetBig;
end;

procedure TXcomTextEdit.SetSmall;
begin
  FText.SetSmall;
  FCaret.SetSmall;
end;

procedure TXcomTextEdit.InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage);
begin
  FText.InitText(ABig, ASmall, ALanguage);
  FCaret.InitText(ABig, ASmall, ALanguage);
end;

procedure TXcomTextEdit.SetText(const AText: string);
begin
  FValue := AText;
  FCaretPos := Length(FValue);
  Redraw := True;
end;

function TXcomTextEdit.GetText: string;
begin
  Result := FValue;
end;

procedure TXcomTextEdit.SetWordWrap(AWrap: Boolean);
begin
  FText.SetWordWrap(AWrap);
end;

procedure TXcomTextEdit.SetInvert(AInvert: Boolean);
begin
  FText.SetInvert(AInvert);
  FCaret.SetInvert(AInvert);
end;

procedure TXcomTextEdit.SetHighContrast(AContrast: Boolean);
begin
  FText.SetHighContrast(AContrast);
  FCaret.SetHighContrast(AContrast);
end;

procedure TXcomTextEdit.SetAlign(AAlign: TXcomTextHAlign);
begin
  FText.SetAlign(AAlign);
end;

procedure TXcomTextEdit.SetVerticalAlign(AAlign: TXcomTextVAlign);
begin
  FText.SetVerticalAlign(AAlign);
end;

procedure TXcomTextEdit.SetConstraint(AConstraint: TXcomTextEditConstraint);
begin
  FConstraint := AConstraint;
end;

procedure TXcomTextEdit.SetColor(AColor: Byte);
begin
  FText.SetColor(AColor);
  FCaret.SetColor(AColor);
end;

function TXcomTextEdit.GetColor: Byte;
begin
  Result := FText.GetColor;
end;

procedure TXcomTextEdit.SetSecondaryColor(AColor: Byte);
begin
  FText.SetSecondaryColor(AColor);
end;

function TXcomTextEdit.GetSecondaryColor: Byte;
begin
  Result := FText.GetSecondaryColor;
end;

procedure TXcomTextEdit.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
begin
  inherited SetPalette(AColors, AFirst, ACount);
  FText.SetPalette(AColors, AFirst, ACount);
  FCaret.SetPalette(AColors, AFirst, ACount);
end;

procedure TXcomTextEdit.Think;
begin
  FTimer.Think(False, True);
end;

procedure TXcomTextEdit.DoBlink;
begin
  FBlink := not FBlink;
  Redraw := True;
end;

procedure TXcomTextEdit.Draw;
var
  LNewValue: string;
  LX: Integer;
  LY: Integer;
  LIndex: Integer;
begin
  inherited Draw;
  LNewValue := FValue;
  if FState.Host.Options.KeyboardMode = kmOff then
  begin
    if IsFocused and FBlink then
      LNewValue := LNewValue + Char(FChar);
  end;
  FText.SetText(LNewValue);
  Clear;
  FText.Blit(Self);
  FInk.Reset(Width, Height, FText.DetailScale);
  FInk.Add(FText.Ink, FText.X, FText.Y, FText.Width, FText.Height);
  if FState.Host.Options.KeyboardMode = kmOn then
  begin
    if IsFocused and FBlink then
    begin
      LX := 0;
      case FText.GetAlign of
        haLeft:
          LX := 0;
        haCenter:
          LX := (FText.Width - FText.GetTextWidth) div 2;
        haRight:
          LX := FText.Width - FText.GetTextWidth;
      end;
      for LIndex := 1 to FCaretPos do
        Inc(LX, FText.GetFont.GetCharSize(Ord(FValue[LIndex])).W);
      FCaret.X := LX;
      LY := 0;
      case FText.GetVerticalAlign of
        vaTop:
          LY := 0;
        vaMiddle:
          LY := Ceil((Height - FText.GetTextHeight) / 2.0);
        vaBottom:
          LY := Height - FText.GetTextHeight;
      end;
      FCaret.Y := LY;
      FCaret.Blit(Self);
      FInk.Add(FCaret.Ink, FCaret.X, FCaret.Y, FCaret.Width, FCaret.Height);
    end;
  end;
end;

function TXcomTextEdit.ExceedsMaxWidth(ACode: Integer): Boolean;
var
  LWidth: Integer;
  LIndex: Integer;
  LText: string;
begin
  LWidth := 0;
  LText := FValue + Char(ACode);
  for LIndex := 1 to Length(LText) do
    Inc(LWidth, FText.GetFont.GetCharSize(Ord(LText[LIndex])).W);
  Result := LWidth > Width;
end;

function TXcomTextEdit.IsValidChar(ACode: Integer): Boolean;
begin
  case FConstraint of
    tecNumericPositive:
      Result := (ACode >= Ord('0')) and (ACode <= Ord('9'));
    tecNumeric:
      // a sign only at the first position and only once; figures anywhere
      if FCaretPos > 0 then
        Result := (ACode >= Ord('0')) and (ACode <= Ord('9'))
      else
        Result := (((ACode >= Ord('0')) and (ACode <= Ord('9'))) or (ACode = Ord('+')) or (ACode = Ord('-'))) and
          ((FValue = '') or ((FValue[1] <> '+') and (FValue[1] <> '-')));
    tecNone:
      Result := ((ACode >= Ord(' ')) and (ACode <= Ord('~'))) or (ACode >= 160);
  else
    Result := False;
  end;
end;

procedure TXcomTextEdit.MousePress(AAction: TXcomAction);
var
  LMouseX: Double;
  LScaleX: Double;
  LWidth: Double;
  LCount: Integer;
  LIndex: Integer;
  LCharWidth: Integer;
begin
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    if not IsFocused then
      SetFocus(True)
    else
    begin
      LMouseX := AAction.RelativeXMouse;
      LScaleX := AAction.XScale;
      LWidth := 0;
      LCount := 0;
      for LIndex := 1 to Length(FValue) do
      begin
        if LMouseX <= LWidth then
          Break;
        LCharWidth := FText.GetFont.GetCharSize(Ord(FValue[LIndex])).W;
        LWidth := LWidth + LCharWidth / 2 * LScaleX;
        if LMouseX <= LWidth then
          Break;
        Inc(LCount);
        LWidth := LWidth + LCharWidth / 2 * LScaleX;
      end;
      FCaretPos := LCount;
    end;
  end;
  inherited MousePress(AAction);
end;

procedure TXcomTextEdit.KeyboardPress(AAction: TXcomAction);
var
  LKey: Integer;
  LCode: Integer;
begin
  LKey := AAction.Details^.Key;
  if FState.Host.Options.KeyboardMode = kmOff then
  begin
    case LKey of
      XCOM_KEY_UP:
        begin
          Inc(FChar);
          if FChar > Ord('~') then
            FChar := Ord(' ');
        end;
      XCOM_KEY_DOWN:
        begin
          Dec(FChar);
          if FChar < Ord(' ') then
            FChar := Ord('~');
        end;
      XCOM_KEY_LEFT:
        if FValue <> '' then
          SetLength(FValue, Length(FValue) - 1);
      XCOM_KEY_RIGHT:
        if not ExceedsMaxWidth(FChar) then
          FValue := FValue + Char(FChar);
    end;
  end
  else if FState.Host.Options.KeyboardMode = kmOn then
  begin
    case LKey of
      XCOM_KEY_LEFT:
        if FCaretPos > 0 then
          Dec(FCaretPos);
      XCOM_KEY_RIGHT:
        if FCaretPos < Length(FValue) then
          Inc(FCaretPos);
      XCOM_KEY_HOME:
        FCaretPos := 0;
      XCOM_KEY_END:
        FCaretPos := Length(FValue);
      XCOM_KEY_BACKSPACE:
        if FCaretPos > 0 then
        begin
          Delete(FValue, FCaretPos, 1);
          Dec(FCaretPos);
        end;
      XCOM_KEY_DELETE:
        if FCaretPos < Length(FValue) then
          Delete(FValue, FCaretPos + 1, 1);
      XCOM_KEY_RETURN, XCOM_KEY_KP_ENTER:
        if FValue <> '' then
          SetFocus(False);
    else
      LCode := Integer(AAction.Details^.Character);
      if IsValidChar(LCode) and not ExceedsMaxWidth(LCode) then
      begin
        Insert(Char(LCode), FValue, FCaretPos + 1);
        Inc(FCaretPos);
      end;
    end;
  end;
  Redraw := True;
  if Assigned(FChange) then
    FChange(AAction);
  inherited KeyboardPress(AAction);
end;

procedure TXcomTextEdit.Blit(ATarget: TXcomSurface);
begin
  if Visible and not Hidden then
  begin
    // the window changed size after the box was drawn
    if FText.DetailScale <> FInk.Scale then
      Redraw := True;
    if Redraw then
      Draw;
    if FInk.BeginLayer(ATarget, X, Y) then
    begin
      inherited Blit(ATarget);
      FInk.EndLayer(ATarget);
      Exit;
    end;
  end;
  inherited Blit(ATarget);
end;

procedure TXcomTextEdit.OnChange(const AHandler: TXcomActionHandler);
begin
  FChange := AHandler;
end;

end.
