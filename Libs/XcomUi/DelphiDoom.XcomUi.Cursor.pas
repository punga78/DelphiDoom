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
  System.SysUtils, System.Math, DelphiDoom.XcomSurface.Gfx, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.InteractiveSurface;

type
  /// <summary>
  ///   The mouse cursor of the game: a small arrow in four shades of a color that follows the mouse. The lines are
  ///   drawn with TXcomGfx.DrawLine (lineColor of SDL_gfx)
  /// </summary>
  TXcomCursor = class(TXcomInteractiveSurface)
  strict private
    FColor: Byte;
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
    TXcomGfx.DrawLine(Self, LX1, LY1, LX1, LY2, LColor);
    TXcomGfx.DrawLine(Self, LX1, LY1, LX2, Width - 1, LColor);
    Inc(LX1);
    Inc(LY1, 2);
    Dec(LY2);
    Dec(LX2);
    // a Uint8 of the C++: the color wraps at 255 (a range error with the checks on)
    LColor := Byte(LColor + 1);
  end;
  LColor := Byte(LColor - 1);
  SetPixel(4, 8, LColor);
end;

end.
