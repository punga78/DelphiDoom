{******************************************************************************}
{                                                                              }
{  DD_Tools: draws a character with GDI for the font editor                     }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Win.FontRasterizer;

interface

uses
  System.SysUtils,
  Vcl.Graphics,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Settings,
  DelphiDoom.Font.Intf;

type
  /// <summary>
  ///   IFontRasterizer with TCanvas.TextOut, as DrawCharToCanvas of TFontEngine did: a 32 bit bitmap of the size
  ///   of the cell, filled with the background, the character drawn at the top left corner in the font of the
  ///   settings. The result depends on the machine (hinting, ClearType, the fonts that are installed): it is
  ///   what the old tool showed. The bitmap is kept from one character to the next
  /// </summary>
  TVclFontRasterizer = class(TInterfacedObject, IFontRasterizer)
  strict private
    FBitmap: TBitmap;
  public
    constructor Create;
    destructor Destroy; override;
    function RenderCharacter(const ASettings: TFontSettings; ACharacter: Char): TFontImage;
  end;

implementation

uses
  System.Classes, System.Math, System.Types;

{ TVclFontRasterizer }

constructor TVclFontRasterizer.Create;
begin
  inherited Create;
  FBitmap := TBitmap.Create;
  FBitmap.PixelFormat := pf32bit;
end;

destructor TVclFontRasterizer.Destroy;
begin
  FBitmap.Free;
  inherited Destroy;
end;

function TVclFontRasterizer.RenderCharacter(const ASettings: TFontSettings; ACharacter: Char): TFontImage;
var
  LCanvas: TCanvas;
  LStyle: TFontStyles;
  LRow: Integer;
  LIndex: Integer;
begin
  Result := TFontImage.Create(Max(0, ASettings.DrawWidth), Max(0, ASettings.DrawHeight));
  if (Result.Width = 0) or (Result.Height = 0) then
    Exit;
  FBitmap.SetSize(Result.Width, Result.Height);
  LCanvas := FBitmap.Canvas;
  LCanvas.Pen.Style := psClear;
  LCanvas.Pen.Color := TColor(ASettings.BackColor);
  LCanvas.Brush.Style := bsSolid;
  LCanvas.Brush.Color := TColor(ASettings.BackColor);
  LStyle := [];
  if ASettings.IsBold then
    Include(LStyle, fsBold);
  if ASettings.IsItalic then
    Include(LStyle, fsItalic);
  if ASettings.IsUnderline then
    Include(LStyle, fsUnderline);
  if ASettings.IsStrikeOut then
    Include(LStyle, fsStrikeOut);
  // the order of the original: the height first, then the size (the size wins)
  LCanvas.Font.Height := ASettings.Height;
  LCanvas.Font.Pitch := TFontPitch(Ord(ASettings.Pitch));
  LCanvas.Font.Style := LStyle;
  LCanvas.Font.Charset := TFontCharset(ASettings.Charset);
  LCanvas.Font.Color := TColor(ASettings.FrontColor);
  LCanvas.Font.Name := ASettings.FontName;
  LCanvas.Font.Size := ASettings.FontSize;
  LCanvas.FillRect(Rect(0, 0, Result.Width, Result.Height));
  LCanvas.TextOut(0, 0, ACharacter);
  for LRow := 0 to Result.Height - 1 do
    Move(FBitmap.ScanLine[LRow]^, Result.Pixels[LRow * Result.Width], Result.Width * SizeOf(Cardinal));
  for LIndex := 0 to Length(Result.Pixels) - 1 do
    Result.Pixels[LIndex] := Result.Pixels[LIndex] and $FFFFFF;
end;

end.
