{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - Window of OpenXcom                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.Window;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types;

type
  /// <summary>
  ///   A window with a border in four shades of a color and a background picture, that can open with an animation
  ///   (the popup): while it opens the other surfaces of the state are hidden. The popup sound is not played
  /// </summary>
  TXcomWindow = class(TXcomWidget)
  strict private
    FDX: Integer;
    FDY: Integer;
    FBackground: TXcomSurface;
    FColor: Byte;
    FPopup: TXcomWindowPopup;
    FPopupStep: Double;
    FTimer: TXcomTimer;
    FState: TXcomState;
    FContrast: Boolean;
    FScreen: Boolean;
    FThinBorder: Boolean;
    procedure DoPopup;
  public
    /// <param name="AState">The state the window belongs to (nil for a window without one); it must be given for a popup</param>
    constructor Create(AState: TXcomState; AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0;
      APopup: TXcomWindowPopup = wpNone);
    destructor Destroy; override;
    /// <summary>Window::setBackground: the surface is not owned</summary>
    procedure SetBackground(ABackground: TXcomSurface);
    procedure SetColor(AColor: Byte); override;
    function GetColor: Byte; override;
    procedure SetHighContrast(AContrast: Boolean); override;
    procedure Think; override;
    procedure Draw; override;
    procedure StateInitialized; override;
    procedure SetDX(ADX: Integer);
    procedure SetDY(ADY: Integer);
    procedure SetThinBorder;
    property PopupStep: Double read FPopupStep;
  end;

implementation

const
  POPUP_SPEED = 0.05;

function Wrap16(AValue: Integer): Integer; inline;
begin
  Result := AValue and $FFFF;
end;

constructor TXcomWindow.Create(AState: TXcomState; AWidth, AHeight, AX, AY: Integer; APopup: TXcomWindowPopup);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FDX := -AX;
  FDY := -AY;
  FPopup := APopup;
  FState := AState;
  FPopupStep := 0.0;
  FTimer := TXcomTimer.Create(AState.Host.Clock, 10);
  FTimer.OnTimerSurface(
    procedure
    begin
      DoPopup;
    end);
  if FPopup = wpNone then
    FPopupStep := 1.0
  else
  begin
    Hidden := True;
    FTimer.Start;
    FScreen := FState.IsScreen;
    if FScreen then
      FState.ToggleScreen;
  end;
end;

destructor TXcomWindow.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

procedure TXcomWindow.SetBackground(ABackground: TXcomSurface);
begin
  FBackground := ABackground;
  Redraw := True;
end;

procedure TXcomWindow.SetColor(AColor: Byte);
begin
  FColor := AColor;
  Redraw := True;
end;

function TXcomWindow.GetColor: Byte;
begin
  Result := FColor;
end;

procedure TXcomWindow.SetHighContrast(AContrast: Boolean);
begin
  FContrast := AContrast;
  Redraw := True;
end;

procedure TXcomWindow.Think;
begin
  if Hidden and (FPopupStep < 1.0) then
  begin
    FState.HideAll;
    Hidden := False;
  end;
  FTimer.Think(False, True);
end;

procedure TXcomWindow.DoPopup;
begin
  // Window::popup: one of the three sounds when the animation starts
  if (FPopupStep = 0.0) and (FState.Host.UiSounds <> nil) then
    FState.Host.UiSounds.PlayWindowPopup;
  if FPopupStep < 1.0 then
    FPopupStep := FPopupStep + POPUP_SPEED
  else
  begin
    if FScreen then
      FState.ToggleScreen;
    FState.ShowAll;
    FPopupStep := 1.0;
    FTimer.Stop;
  end;
  Redraw := True;
end;

procedure TXcomWindow.StateInitialized;
begin
  Redraw := True;
end;

procedure TXcomWindow.Draw;
var
  LX: Integer;
  LY: Integer;
  LW: Integer;
  LH: Integer;
  LMultiplier: Integer;
  LColor: Integer;
  LIndex: Integer;
begin
  inherited Draw;
  if (FPopup = wpHorizontal) or (FPopup = wpBoth) then
  begin
    LX := Trunc((Width - Width * FPopupStep) / 2);
    LW := Trunc(Width * FPopupStep);
  end
  else
  begin
    LX := 0;
    LW := Width;
  end;
  if (FPopup = wpVertical) or (FPopup = wpBoth) then
  begin
    LY := Trunc((Height - Height * FPopupStep) / 2);
    LH := Trunc(Height * FPopupStep);
  end
  else
  begin
    LY := 0;
    LH := Height;
  end;
  LMultiplier := 1;
  if FContrast then
    LMultiplier := 2;
  LColor := FColor + 3 * LMultiplier;
  if FThinBorder then
  begin
    LColor := FColor + 1 * LMultiplier;
    for LIndex := 0 to 4 do
    begin
      DrawRect(TXcomRect.Make(LX, LY, LW, LH), Byte(LColor));
      if LIndex mod 2 = 0 then
      begin
        Inc(LX);
        Inc(LY);
      end;
      LW := Wrap16(LW - 1);
      LH := Wrap16(LH - 1);
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
      end;
    end;
  end
  else
  begin
    for LIndex := 0 to 4 do
    begin
      DrawRect(TXcomRect.Make(LX, LY, LW, LH), Byte(LColor));
      if LIndex < 2 then
        Dec(LColor, 1 * LMultiplier)
      else
        Inc(LColor, 1 * LMultiplier);
      Inc(LX);
      Inc(LY);
      if LW >= 2 then
        Dec(LW, 2)
      else
        LW := 1;
      if LH >= 2 then
        Dec(LH, 2)
      else
        LH := 1;
    end;
  end;
  if FBackground <> nil then
  begin
    FBackground.Crop := TXcomRect.Make(LX - FDX, LY - FDY, LW, LH);
    FBackground.X := LX;
    FBackground.Y := LY;
    FBackground.Blit(Self);
  end;
end;

procedure TXcomWindow.SetDX(ADX: Integer);
begin
  FDX := ADX;
end;

procedure TXcomWindow.SetDY(ADY: Integer);
begin
  FDY := ADY;
end;

procedure TXcomWindow.SetThinBorder;
begin
  FThinBorder := True;
end;

end.
