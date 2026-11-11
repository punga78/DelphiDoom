{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - Slider of OpenXcom                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.Slider;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.Math, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.Frame, DelphiDoom.XcomUi.TextButton;

type
  /// <summary>A slider: a "-" and a "+" at the ends of a frame, and a button that moves along it between two values</summary>
  TXcomSlider = class(TXcomInteractiveSurface)
  strict private
    FFrame: TXcomFrame;
    FTxtMinus: TXcomText;
    FTxtPlus: TXcomText;
    FButton: TXcomTextButton;
    FPos: Double;
    FMin: Integer;
    FMax: Integer;
    FValue: Integer;
    FPressed: Boolean;
    FChange: TXcomActionHandler;
    FThickness: Integer;
    FTextness: Integer;
    FMinX: Integer;
    FMaxX: Integer;
    FOffsetX: Integer;
    /// <summary>The knob of a value placed with exact integer arithmetic (see SetValue)</summary>
    procedure SetExactPosition;
  protected
    procedure SetX(AValue: Integer); override;
    procedure SetY(AValue: Integer); override;
    procedure MousePress(AAction: TXcomAction); override;
    procedure MouseRelease(AAction: TXcomAction); override;
  public
    constructor Create(AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0);
    destructor Destroy; override;
    procedure InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage); override;
    procedure SetHighContrast(AContrast: Boolean); override;
    procedure SetColor(AColor: Byte); override;
    function GetColor: Byte; override;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    procedure SetRange(AMin, AMax: Integer);
    procedure SetValue(AValue: Integer);
    function GetValue: Integer;
    procedure Blit(ATarget: TXcomSurface); override;
    procedure Handle(AAction: TXcomAction); override;
    procedure OnChange(const AHandler: TXcomActionHandler);
    property Button: TXcomTextButton read FButton;
  end;

implementation

constructor TXcomSlider.Create(AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FMax := 100;
  FThickness := 5;
  FTextness := 8;
  FTxtMinus := TXcomText.Create(FTextness, AHeight - 2, AX - 1, AY);
  FTxtPlus := TXcomText.Create(FTextness, AHeight - 2, AX + AWidth - FTextness, AY);
  FFrame := TXcomFrame.Create(AWidth - FTextness * 2, FThickness, AX + FTextness, AY + (AHeight - FThickness) div 2);
  FButton := TXcomTextButton.Create(10, AHeight, AX, AY);
  FFrame.SetThickness(FThickness);
  FTxtMinus.SetAlign(haCenter);
  FTxtMinus.SetVerticalAlign(vaMiddle);
  FTxtMinus.SetText('-');
  FTxtPlus.SetAlign(haCenter);
  FTxtPlus.SetVerticalAlign(vaMiddle);
  FTxtPlus.SetText('+');
  FMinX := FFrame.X;
  FMaxX := FFrame.X + FFrame.Width - FButton.Width;
  SetValue(Trunc(FPos));
end;

destructor TXcomSlider.Destroy;
begin
  FButton.Free;
  FFrame.Free;
  FTxtPlus.Free;
  FTxtMinus.Free;
  inherited Destroy;
end;

procedure TXcomSlider.SetX(AValue: Integer);
begin
  inherited SetX(AValue);
  FTxtMinus.X := AValue - 1;
  FTxtPlus.X := AValue + Width - FTextness;
  FFrame.X := X + FTextness;
  FMinX := FFrame.X;
  FMaxX := FFrame.X + FFrame.Width - FButton.Width;
  SetValue(FValue);
end;

procedure TXcomSlider.SetY(AValue: Integer);
begin
  inherited SetY(AValue);
  FTxtMinus.Y := AValue;
  FTxtPlus.Y := AValue;
  FFrame.Y := Y + (Height - FThickness) div 2;
  FButton.Y := Y;
end;

procedure TXcomSlider.InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage);
begin
  FTxtMinus.InitText(ABig, ASmall, ALanguage);
  FTxtPlus.InitText(ABig, ASmall, ALanguage);
  FButton.InitText(ABig, ASmall, ALanguage);
end;

procedure TXcomSlider.SetHighContrast(AContrast: Boolean);
begin
  FTxtMinus.SetHighContrast(AContrast);
  FTxtPlus.SetHighContrast(AContrast);
  FFrame.SetHighContrast(AContrast);
  FButton.SetHighContrast(AContrast);
end;

procedure TXcomSlider.SetColor(AColor: Byte);
begin
  FTxtMinus.SetColor(AColor);
  FTxtPlus.SetColor(AColor);
  FFrame.SetColor(AColor);
  FButton.SetColor(AColor);
end;

function TXcomSlider.GetColor: Byte;
begin
  Result := FButton.GetColor;
end;

procedure TXcomSlider.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
begin
  inherited SetPalette(AColors, AFirst, ACount);
  FTxtMinus.SetPalette(AColors, AFirst, ACount);
  FTxtPlus.SetPalette(AColors, AFirst, ACount);
  FFrame.SetPalette(AColors, AFirst, ACount);
  FButton.SetPalette(AColors, AFirst, ACount);
end;

procedure TXcomSlider.Handle(AAction: TXcomAction);
var
  LButtonX: Double;
  LPos: Double;
begin
  inherited Handle(AAction);
  if FPressed and ((AAction.Details^.Kind = ekMouseMotion) or (AAction.Details^.Kind = ekMouseDown)) then
  begin
    LButtonX := TXcomMath.Clamp(Trunc(AAction.AbsoluteXMouse) + FOffsetX, FMinX, FMaxX);
    if FMaxX = FMinX then
      LPos := 0.0
    else
      LPos := (LButtonX - FMinX) / (FMaxX - FMinX);
    SetValue(FMin + TXcomMath.RoundToInt((FMax - FMin) * LPos));
    if Assigned(FChange) then
      FChange(AAction);
  end;
end;

procedure TXcomSlider.SetRange(AMin, AMax: Integer);
begin
  FMin := AMin;
  FMax := AMax;
  SetValue(FValue);
end;

procedure TXcomSlider.SetValue(AValue: Integer);
var
  LPos: Double;
begin
  if FMin < FMax then
    FValue := TXcomMath.Clamp(AValue, FMin, FMax)
  else
    FValue := TXcomMath.Clamp(AValue, FMax, FMin);
  if FMax = FMin then
    LPos := 0.0
  else
    LPos := (FValue - FMin) / (FMax - FMin);
  FPos := LPos;
  SetExactPosition;
end;

procedure TXcomSlider.SetExactPosition;
var
  LNumerator: Int64;
  LDenominator: Int64;
  LOffset: Int64;
begin
  if FMax = FMin then
  begin
    FButton.X := FMinX;
    Exit;
  end;
  // floor(minX + (maxX - minX) * (value - min) / (max - min)) with no rounding error: the real program computes it in
  // the extended precision of the x87, where 78 * 2/3 is exactly 52, while a double gives 51.99999999999999
  LNumerator := Int64(FMaxX - FMinX) * (FValue - FMin);
  LDenominator := FMax - FMin;
  if LDenominator < 0 then
  begin
    LNumerator := -LNumerator;
    LDenominator := -LDenominator;
  end;
  LOffset := LNumerator div LDenominator;
  if (LNumerator mod LDenominator) < 0 then
    Dec(LOffset);
  FButton.X := FMinX + Integer(LOffset);
end;

function TXcomSlider.GetValue: Integer;
begin
  Result := FValue;
end;

procedure TXcomSlider.Blit(ATarget: TXcomSurface);
begin
  inherited Blit(ATarget);
  if Visible and not Hidden then
  begin
    FTxtMinus.Blit(ATarget);
    FTxtPlus.Blit(ATarget);
    FFrame.Blit(ATarget);
    FButton.Blit(ATarget);
  end;
end;

procedure TXcomSlider.MousePress(AAction: TXcomAction);
var
  LCursorX: Integer;
begin
  inherited MousePress(AAction);
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    FPressed := True;
    LCursorX := Trunc(AAction.AbsoluteXMouse);
    if (LCursorX >= FButton.X) and (LCursorX < FButton.X + FButton.Width) then
      FOffsetX := FButton.X - LCursorX
    else
      FOffsetX := -FButton.Width div 2;
  end;
end;

procedure TXcomSlider.MouseRelease(AAction: TXcomAction);
begin
  inherited MouseRelease(AAction);
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    FPressed := False;
    FOffsetX := 0;
  end;
end;

procedure TXcomSlider.OnChange(const AHandler: TXcomActionHandler);
begin
  FChange := AHandler;
end;

end.
