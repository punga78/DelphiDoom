{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - Cursor of OpenXcom (the arrow that      }
{  replaces the cursor of the system)                                           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.Cursor;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.InteractiveSurface;

type
  /// <summary>
  ///   The mouse cursor of the game: a small arrow in four shades of a color that follows the mouse. The lines are
  ///   drawn with a Bresenham algorithm: SDL_gfx (lineColor) is not ported, so a pixel of the diagonal can differ
  ///   from the original (see the README of the library)
  /// </summary>
  TXcomCursor = class(TXcomInteractiveSurface)
  strict private
    FColor: Byte;
    procedure DrawLine(AX1, AY1, AX2, AY2: Integer; AColor: Byte);
  public
    constructor Create(AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0);
    /// <summary>Cursor::handle: the position follows the mouse (in the coordinates of the game)</summary>
    procedure Handle(AAction: TXcomAction); override;
    procedure SetColor(AColor: Byte); override;
    function GetColor: Byte; override;
    procedure Draw; override;
  end;

implementation

constructor TXcomCursor.Create(AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
end;

procedure TXcomCursor.Handle(AAction: TXcomAction);
begin
  if AAction.Details^.Kind = ekMouseMotion then
  begin
    X := Floor((AAction.Details^.X - AAction.LeftBlackBand) / AAction.XScale);
    Y := Floor((AAction.Details^.Y - AAction.TopBlackBand) / AAction.YScale);
  end;
end;

procedure TXcomCursor.SetColor(AColor: Byte);
begin
  FColor := AColor;
  Redraw := True;
end;

function TXcomCursor.GetColor: Byte;
begin
  Result := FColor;
end;

procedure TXcomCursor.DrawLine(AX1, AY1, AX2, AY2: Integer; AColor: Byte);
var
  LDeltaX: Integer;
  LDeltaY: Integer;
  LStepX: Integer;
  LStepY: Integer;
  LError: Integer;
  LDoubled: Integer;
begin
  LDeltaX := Abs(AX2 - AX1);
  LDeltaY := -Abs(AY2 - AY1);
  LStepX := Sign(AX2 - AX1);
  if LStepX = 0 then
    LStepX := 1;
  LStepY := Sign(AY2 - AY1);
  if LStepY = 0 then
    LStepY := 1;
  LError := LDeltaX + LDeltaY;
  while True do
  begin
    SetPixel(AX1, AY1, AColor);
    if (AX1 = AX2) and (AY1 = AY2) then
      Break;
    LDoubled := 2 * LError;
    if LDoubled >= LDeltaY then
    begin
      Inc(LError, LDeltaY);
      Inc(AX1, LStepX);
    end;
    if LDoubled <= LDeltaX then
    begin
      Inc(LError, LDeltaX);
      Inc(AY1, LStepY);
    end;
  end;
end;

procedure TXcomCursor.Draw;
var
  LColor: Byte;
  LX1: Integer;
  LY1: Integer;
  LX2: Integer;
  LY2: Integer;
  LIndex: Integer;
begin
  inherited Draw;
  LColor := FColor;
  LX1 := 0;
  LY1 := 0;
  LX2 := Width - 1;
  LY2 := Height - 1;
  for LIndex := 0 to 3 do
  begin
    DrawLine(LX1, LY1, LX1, LY2, LColor);
    DrawLine(LX1, LY1, LX2, Width - 1, LColor);
    Inc(LX1);
    Inc(LY1, 2);
    Dec(LY2);
    Dec(LX2);
    Inc(LColor);
  end;
  Dec(LColor);
  SetPixel(4, 8, LColor);
end;

end.
