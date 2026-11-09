{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - BattlescapeButton of OpenXcom           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.BattlescapeButton;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Palette, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.InteractiveSurface;

type
  TXcomBattlescapeButton = class;

  /// <summary>The variable that a group of battlescape buttons shares (the BattlescapeButton ** of the C++)</summary>
  TXcomBattlescapeButtonGroup = class
  public
    Selected: TXcomBattlescapeButton;
  end;

  /// <summary>When the picture of the button is shown in its pressed form (InversionType)</summary>
  TXcomInversionType = (itNone, itToggle, itClick);

  /// <summary>
  ///   A button of the battlescape toolbar: it has a second picture, made by InitSurfaces from the first, that is
  ///   drawn while the button is pressed (a color table in the TFTD mode, a palette inversion in the other)
  /// </summary>
  TXcomBattlescapeButton = class(TXcomInteractiveSurface)
  strict private
    FColor: Byte;
    FGroup: TXcomBattlescapeButtonGroup;
    FInverted: Boolean;
    FToggleMode: TXcomInversionType;
    FAltSurface: TXcomSurface;
  protected
    procedure SetX(AValue: Integer); override;
    procedure SetY(AValue: Integer); override;
    procedure MousePress(AAction: TXcomAction); override;
    procedure MouseRelease(AAction: TXcomAction); override;
  public
    destructor Destroy; override;
    procedure SetColor(AColor: Byte); override;
    function GetColor: Byte; override;
    procedure SetGroup(AGroup: TXcomBattlescapeButtonGroup);
    procedure Toggle(APress: Boolean);
    procedure AllowToggleInversion;
    procedure AllowClickInversion;
    /// <summary>Makes the second picture from the current one: call it when the picture is ready</summary>
    procedure InitSurfaces;
    procedure Blit(ATarget: TXcomSurface); override;
    property Inverted: Boolean read FInverted;
  end;

implementation

const
  TFTD_COLOR_FROM: array[0..10] of Integer = (1, 2, 3, 4, 7, 8, 31, 47, 153, 156, 159);
  TFTD_COLOR_TO: array[0..10] of Integer = (2, 3, 4, 5, 11, 10, 2, 2, 96, 9, 97);

destructor TXcomBattlescapeButton.Destroy;
begin
  FAltSurface.Free;
  inherited Destroy;
end;

procedure TXcomBattlescapeButton.SetColor(AColor: Byte);
begin
  FColor := AColor;
end;

function TXcomBattlescapeButton.GetColor: Byte;
begin
  Result := FColor;
end;

procedure TXcomBattlescapeButton.SetGroup(AGroup: TXcomBattlescapeButtonGroup);
begin
  FGroup := AGroup;
  if Assigned(FGroup) and (FGroup.Selected = Self) then
    FInverted := True;
end;

procedure TXcomBattlescapeButton.MousePress(AAction: TXcomAction);
begin
  if Assigned(FGroup) then
  begin
    if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    begin
      if Assigned(FGroup.Selected) then
        FGroup.Selected.Toggle(False);
      FGroup.Selected := Self;
      FInverted := True;
    end;
  end
  else if (TftdMode or (FToggleMode = itClick)) and (not FInverted) and IsButtonPressed and
    IsButtonHandled(AAction.Details^.Button) then
    FInverted := True;
  inherited MousePress(AAction);
end;

procedure TXcomBattlescapeButton.MouseRelease(AAction: TXcomAction);
begin
  if FInverted and IsButtonHandled(AAction.Details^.Button) then
    FInverted := False;
  inherited MouseRelease(AAction);
end;

procedure TXcomBattlescapeButton.Toggle(APress: Boolean);
begin
  if TftdMode or (FToggleMode = itToggle) or FInverted then
    FInverted := APress;
end;

procedure TXcomBattlescapeButton.AllowToggleInversion;
begin
  FToggleMode := itToggle;
end;

procedure TXcomBattlescapeButton.AllowClickInversion;
begin
  FToggleMode := itClick;
end;

procedure TXcomBattlescapeButton.InitSurfaces;
var
  LX: Integer;
  LY: Integer;
  LPixel: Integer;
  LIndex: Integer;
  LPalette: TXcomPalette;
begin
  FAltSurface.Free;
  FAltSurface := TXcomSurface.Create(Width, Height, X, Y);
  LPalette := Palette;
  FAltSurface.SetColors(LPalette.Colors, 0);
  LX := 0;
  LY := 0;
  if TftdMode then
  begin
    // a color lookup table instead of the inversion of the palette
    while (LX < Width) and (LY < Height) do
    begin
      LPixel := GetPixel(LX, LY);
      for LIndex := 0 to High(TFTD_COLOR_FROM) do
        if LPixel = TFTD_COLOR_FROM[LIndex] then
        begin
          LPixel := TFTD_COLOR_TO[LIndex];
          Break;
        end;
      FAltSurface.SetPixelIterative(LX, LY, Byte(LPixel));
    end;
  end
  else
  begin
    while (LX < Width) and (LY < Height) do
    begin
      LPixel := GetPixel(LX, LY);
      if LPixel > 0 then
        FAltSurface.SetPixelIterative(LX, LY, Byte(LPixel + 2 * (FColor + 3 - LPixel)))
      else
        FAltSurface.SetPixelIterative(LX, LY, 0);
    end;
  end;
end;

procedure TXcomBattlescapeButton.Blit(ATarget: TXcomSurface);
begin
  if FInverted and Assigned(FAltSurface) then
    FAltSurface.Blit(ATarget)
  else
    inherited Blit(ATarget);
end;

procedure TXcomBattlescapeButton.SetX(AValue: Integer);
begin
  inherited SetX(AValue);
  if Assigned(FAltSurface) then
    FAltSurface.X := AValue;
end;

procedure TXcomBattlescapeButton.SetY(AValue: Integer);
begin
  inherited SetY(AValue);
  if Assigned(FAltSurface) then
    FAltSurface.Y := AValue;
end;

end.
