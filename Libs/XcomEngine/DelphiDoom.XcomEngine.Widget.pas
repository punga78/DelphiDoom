{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the surface that a state manages          }
{  (the virtual part of Surface of OpenXcom: think, palette, colors, text)     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Widget;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Font,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Language;

type
  /// <summary>
  ///   A TXcomSurface that a state can add and manage: the virtual operations of Surface that the interface
  ///   classes override (think, set the palette, the colors and the fonts). The base class does nothing for the
  ///   colors and the text, as the C++ ones ("empty by design")
  /// </summary>
  TXcomWidget = class(TXcomSurface)
  strict private
    FTooltip: string;
  public
    /// <summary>Surface::think: what the surface updates every game cycle (timers)</summary>
    procedure Think; virtual;
    /// <summary>Surface::initText: gives the fonts and the language the text of the surface uses</summary>
    procedure InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage); virtual;
    /// <summary>Surface::setPalette: replaces ACount colors from AFirst (SDL_SetColors)</summary>
    /// <param name="AColors">The first color of the run to copy (not the one at AFirst), as SDL_SetColors takes it</param>
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); virtual;
    /// <summary>The main color of the widget (0 for the ones that have none)</summary>
    function GetColor: Byte; virtual;
    /// <summary>
    ///   What State::init does to a window (invalidate): a widget that must be drawn again every time its state
    ///   comes back to the front overrides this
    /// </summary>
    procedure StateInitialized; virtual;
    /// <summary>The game calls this once for every frame it draws (FpsCounter::addFrame)</summary>
    procedure FrameAdded; virtual;
    /// <summary>What State::redrawText does: the widgets that draw text draw again</summary>
    procedure RedrawText; virtual;
    procedure SetColor(AColor: Byte); virtual;
    procedure SetSecondaryColor(AColor: Byte); virtual;
    procedure SetBorderColor(AColor: Byte); virtual;
    procedure SetHighContrast(AContrast: Boolean); virtual;
    /// <summary>Surface::invalidate: the surface must be drawn again before it is blitted</summary>
    procedure Invalidate(AValid: Boolean = True);
    /// <summary>The key of the tooltip string (Surface::setTooltip)</summary>
    property Tooltip: string read FTooltip write FTooltip;
  end;

implementation

procedure TXcomWidget.Think;
begin
end;

procedure TXcomWidget.InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage);
begin
end;

procedure TXcomWidget.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
var
  LColors: TArray<TXcomColor>;
begin
  if ACount <= 0 then
    Exit;
  SetLength(LColors, ACount);
  Move(AColors^, LColors[0], ACount * SizeOf(TXcomColor));
  SetColors(LColors, AFirst);
end;

function TXcomWidget.GetColor: Byte;
begin
  Result := 0;
end;

procedure TXcomWidget.StateInitialized;
begin
end;

procedure TXcomWidget.RedrawText;
begin
end;

procedure TXcomWidget.FrameAdded;
begin
end;

procedure TXcomWidget.SetColor(AColor: Byte);
begin
end;

procedure TXcomWidget.SetSecondaryColor(AColor: Byte);
begin
end;

procedure TXcomWidget.SetBorderColor(AColor: Byte);
begin
end;

procedure TXcomWidget.SetHighContrast(AContrast: Boolean);
begin
end;

procedure TXcomWidget.Invalidate(AValid: Boolean);
begin
  Redraw := AValid;
end;

end.
