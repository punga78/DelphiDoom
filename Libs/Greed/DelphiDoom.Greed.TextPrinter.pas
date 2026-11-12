{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the text on the 8 bit buffer of the HUD          }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): FN_RawPrint .. FN_RawPrint4,}
{  FN_Print, FN_PrintCentered and FN_BlockCenterPrintf of d_font.pas            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.TextPrinter;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Font;

type
  /// <summary>
  ///   The print state of d_font.pas (font, fontbasecolor, fontspacing, printx, printy) and its routines, on a
  ///   canvas. The four raw prints differ in two things: RawPrint and RawPrint4 draw the background of a character
  ///   too (with ApproxZero, so the text hides what is below), RawPrint2 and RawPrint3 only its pixels; RawPrint
  ///   and RawPrint3 go to the screen and RawPrint2 and RawPrint4 to the view buffer, which here are the same
  ///   canvas (the rows of the view buffer are windowWidth apart, 320 when the HUD is drawn).
  ///   The printf of the original is not here: the caller gives the text already made (FN_Printf = Print,
  ///   FN_CenterPrintf = PrintCentered, FN_BlockCenterPrintf = BlockCenterPrint).
  ///   Differences from the original: the pixels outside the canvas are not drawn, and a print without a font
  ///   raises (the original follows a nil pointer)
  /// </summary>
  TGreedTextPrinter = class
  strict private
    FCanvas: TGreedCanvas;
    FFont: TGreedFont;
    FBaseColor: Integer;
    FSpacing: Integer;
    FPrintX: Integer;
    FPrintY: Integer;
    procedure Draw(const AText: string; ABackground: Boolean);
    procedure RequireFont;
  public
    constructor Create(ACanvas: TGreedCanvas);
    /// <summary>FN_RawPrint: text and background at (PrintX, PrintY); PrintX ends after the text</summary>
    procedure RawPrint(const AText: string);
    /// <summary>FN_RawPrint2: text only</summary>
    procedure RawPrint2(const AText: string);
    /// <summary>FN_RawPrint3: text only</summary>
    procedure RawPrint3(const AText: string);
    /// <summary>FN_RawPrint4: text and background</summary>
    procedure RawPrint4(const AText: string);
    /// <summary>FN_RawWidth with the font and the spacing of now</summary>
    function RawWidth(const AText: string): Integer;
    /// <summary>
    ///   FN_Print (and FN_Printf): each line with RawPrint, then PrintX goes back to 0 and PrintY down by the height
    ///   of the font. The lines are split as TStringList.Text does (CR, LF or both)
    /// </summary>
    procedure Print(const AText: string);
    /// <summary>FN_PrintCentered (and FN_CenterPrintf): each line with RawPrint3, centered in 320 pixels</summary>
    procedure PrintCentered(const AText: string);
    /// <summary>
    ///   FN_BlockCenterPrintf: PrintY is set so that the lines (counted by their line feeds) are in the middle of
    ///   200 rows, then PrintCentered
    /// </summary>
    procedure BlockCenterPrint(const AText: string);
    /// <summary>font: not owned</summary>
    property Font: TGreedFont read FFont write FFont;
    /// <summary>fontbasecolor: added to each pixel of a character</summary>
    property BaseColor: Integer read FBaseColor write FBaseColor;
    /// <summary>fontspacing: 1 when the program starts</summary>
    property Spacing: Integer read FSpacing write FSpacing;
    /// <summary>printx and printy: the top left corner of the next character</summary>
    property PrintX: Integer read FPrintX write FPrintX;
    property PrintY: Integer read FPrintY write FPrintY;
    property Canvas: TGreedCanvas read FCanvas;
  end;

implementation

uses
  System.Classes, DelphiDoom.Greed.Types;

const
  SGreedNoFont = 'Greed: a text is printed before a font is chosen';

{ TGreedTextPrinter }

constructor TGreedTextPrinter.Create(ACanvas: TGreedCanvas);
begin
  inherited Create;
  if not Assigned(ACanvas) then
    raise EArgumentNilException.Create('ACanvas');
  FCanvas := ACanvas;
  FSpacing := 1;
end;

procedure TGreedTextPrinter.RequireFont;
begin
  if not Assigned(FFont) then
    raise EGreedException.Create(SGreedNoFont);
end;

procedure TGreedTextPrinter.Draw(const AText: string; ABackground: Boolean);
var
  LIndex: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LSource: Integer;
  LRow: Integer;
  LPixel: Byte;
  LZero: Byte;
begin
  RequireFont;
  LHeight := FFont.Height;
  LZero := FCanvas.ApproxZero;
  for LIndex := 1 to Length(AText) do
  begin
    LWidth := FFont.CharWidth(AText[LIndex]);
    LSource := FFont.CharOffset(AText[LIndex]);
    while LWidth > 0 do
    begin
      for LRow := 0 to LHeight - 1 do
      begin
        LPixel := FFont.DataAt(LSource);
        Inc(LSource);
        if LPixel <> 0 then
          FCanvas.PutPixel(FPrintX, FPrintY + LRow, FBaseColor + LPixel)
        else if ABackground then
          FCanvas.PutPixel(FPrintX, FPrintY + LRow, LZero);
      end;
      Inc(FPrintX);
      Dec(LWidth);
    end;
    FPrintX := FPrintX + FSpacing;
  end;
end;

procedure TGreedTextPrinter.RawPrint(const AText: string);
begin
  Draw(AText, True);
end;

procedure TGreedTextPrinter.RawPrint2(const AText: string);
begin
  Draw(AText, False);
end;

procedure TGreedTextPrinter.RawPrint3(const AText: string);
begin
  Draw(AText, False);
end;

procedure TGreedTextPrinter.RawPrint4(const AText: string);
begin
  Draw(AText, True);
end;

function TGreedTextPrinter.RawWidth(const AText: string): Integer;
begin
  RequireFont;
  Result := FFont.RawWidth(AText, FSpacing);
end;

procedure TGreedTextPrinter.Print(const AText: string);
var
  LLines: TStringList;
  LIndex: Integer;
  LHeight: Integer;
begin
  RequireFont;
  LHeight := FFont.Height;
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    for LIndex := 0 to LLines.Count - 1 do
    begin
      if LLines[LIndex] <> '' then
        RawPrint(LLines[LIndex]);
      FPrintX := 0;
      FPrintY := FPrintY + LHeight;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TGreedTextPrinter.PrintCentered(const AText: string);
var
  LLines: TStringList;
  LIndex: Integer;
  LHeight: Integer;
begin
  RequireFont;
  LHeight := FFont.Height;
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    for LIndex := 0 to LLines.Count - 1 do
    begin
      if LLines[LIndex] <> '' then
      begin
        FPrintX := (GREED_CANVAS_WIDTH - RawWidth(LLines[LIndex])) div 2;
        RawPrint3(LLines[LIndex]);
      end;
      FPrintX := 0;
      FPrintY := FPrintY + LHeight;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TGreedTextPrinter.BlockCenterPrint(const AText: string);
var
  LIndex: Integer;
  LHeight: Integer;
begin
  RequireFont;
  LHeight := FFont.Height;
  for LIndex := 1 to Length(AText) do
    if AText[LIndex] = #10 then
      Inc(LHeight, FFont.Height);
  FPrintY := (GREED_CANVAS_HEIGHT - LHeight) div 2;
  PrintCentered(AText);
end;

end.
