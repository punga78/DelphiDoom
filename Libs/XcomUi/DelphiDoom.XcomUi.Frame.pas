{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - Frame of OpenXcom                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.Frame;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomEngine.Widget;

type
  /// <summary>A rectangle with a shaded border of a given thickness and a filled inside</summary>
  TXcomFrame = class(TXcomWidget)
  strict private
    FColor: Byte;
    FBackground: Byte;
    FThickness: Integer;
    FContrast: Boolean;
  public
    constructor Create(AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0);
    procedure SetColor(AColor: Byte); override;
    procedure SetBorderColor(AColor: Byte); override;
    function GetColor: Byte; override;
    procedure SetSecondaryColor(ABackground: Byte); override;
    function GetSecondaryColor: Byte;
    procedure SetHighContrast(AContrast: Boolean); override;
    procedure SetThickness(AThickness: Integer);
    procedure Draw; override;
  end;

implementation

constructor TXcomFrame.Create(AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FThickness := 5;
end;

procedure TXcomFrame.SetColor(AColor: Byte);
begin
  FColor := AColor;
  Redraw := True;
end;

procedure TXcomFrame.SetBorderColor(AColor: Byte);
begin
  SetColor(AColor);
end;

function TXcomFrame.GetColor: Byte;
begin
  Result := FColor;
end;

procedure TXcomFrame.SetSecondaryColor(ABackground: Byte);
begin
  FBackground := ABackground;
  Redraw := True;
end;

function TXcomFrame.GetSecondaryColor: Byte;
begin
  Result := FBackground;
end;

procedure TXcomFrame.SetHighContrast(AContrast: Boolean);
begin
  FContrast := AContrast;
  Redraw := True;
end;

procedure TXcomFrame.SetThickness(AThickness: Integer);
begin
  FThickness := AThickness;
  Redraw := True;
end;

procedure TXcomFrame.Draw;
var
  LX: Integer;
  LY: Integer;
  LW: Integer;
  LH: Integer;
  LMultiplier: Integer;
  LColor: Integer;
  LDarkest: Byte;
  LIndex: Integer;
begin
  inherited Draw;
  LX := 0;
  LY := 0;
  LW := Width;
  LH := Height;
  LMultiplier := 1;
  if FContrast then
    LMultiplier := 2;
  LColor := FColor + ((1 + FThickness) * LMultiplier) div 2;
  // Palette::blockOffset(color / 16) + 15
  LDarkest := Byte((FColor div 16) * 16 + 15);
  for LIndex := 0 to FThickness - 1 do
  begin
    if (FThickness > 5) and ((LIndex = 0) or (LIndex = FThickness - 1)) then
      DrawRect(TXcomRect.Make(LX, LY, LW, LH), LDarkest)
    else
      DrawRect(TXcomRect.Make(LX, LY, LW, LH), Byte(LColor));
    if LIndex < FThickness div 2 then
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
  DrawRect(TXcomRect.Make(LX, LY, LW, LH), FBackground);
end;

end.
