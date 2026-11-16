{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - drawing the text                                  }
{                                                                              }
{  Port of war1 (acoto87/war1), war_font.c (wfont_renderSingleSpriteTextSpan,  }
{  wfont_renderSingleSpriteText, wfont_renderMultiSpriteText), (c) 2019        }
{  Alejandro Coto Gutierrez, zlib License (see Games\War\LICENSE-war1.txt).    }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Text.Renderer;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Font.Types, DelphiDoom.War.Render.Types,
  DelphiDoom.War.Render.Transform, DelphiDoom.War.Text.Types, DelphiDoom.War.Text.Intf;

type
  /// <summary>
  ///   The drawing of a text with the glyphs of a font image: each glyph becomes a blit (a part of the image of the font
  ///   and where it goes, in the color of the text) in the transform it was given. The image of the font is not
  ///   needed here: the pixels are put by TWarImageBlitter. With the debug flag "font" on (IWarTextDebug) the box of every
  ///   glyph is filled in green and every text and every line of a text is outlined
  /// </summary>
  TWarTextRenderer = class
  strict private
    FTransform: TWarRenderTransform;
    FDebug: IWarTextDebug;
    function OutlineOn: Boolean; inline;
    function RenderSpan(const AText: AnsiString; AIndex, ACount: Integer; AX, AY: Single; const AColor: TWarRgba;
      const AFont: TWarFontData; ABoundingsX, AScale: Single): Single;
  public
    /// <summary>The transform receives the blits (it is not owned)</summary>
    constructor Create(const ATransform: TWarRenderTransform);
    /// <summary>
    ///   wfont_renderSingleSpriteText: a text in one line at (AX, AY), aligned in the bounds if they are not zero, with the
    ///   highlight of the parameters. A highlight that goes past the end of the text draws the blank glyph of the character 0
    ///   for each character it goes past (the original reads the zeros of its buffer); EWarException if the highlight
    ///   starts before the text or a character has no glyph
    /// </summary>
    procedure RenderSingle(const AText: AnsiString; AX, AY: Single; const AParams: TWarFontParams);
    /// <summary>wfont_renderMultiSpriteText: a text in lines, wrapped, trimmed and aligned as the parameters say</summary>
    procedure RenderMulti(const AText: AnsiString; AX, AY: Single; const AParams: TWarFontParams);
    /// <summary>Where the flag "font" is read (nil: off, as the original with no debug flag)</summary>
    property Debug: IWarTextDebug read FDebug write FDebug;
  end;

implementation

uses
  DelphiDoom.War.Text.Layout;

const
  /// <summary>WAR_COLOR_GREEN_SELECTION (0xFF00C700) and WAR_COLOR_RED_SELECTION (0xFF0000C7) as bytes R G B A</summary>
  GREEN_SELECTION: TWarRgba = (R: 0; G: 199; B: 0; A: 255);
  RED_SELECTION: TWarRgba = (R: 199; G: 0; B: 0; A: 255);

{ TWarTextRenderer }

constructor TWarTextRenderer.Create(const ATransform: TWarRenderTransform);
begin
  inherited Create;
  FTransform := ATransform;
end;

function TWarTextRenderer.OutlineOn: Boolean;
begin
  Result := Assigned(FDebug) and FDebug.IsFontOutlineOn;
end;

function TWarTextRenderer.RenderSpan(const AText: AnsiString; AIndex, ACount: Integer; AX, AY: Single;
  const AColor: TWarRgba; const AFont: TWarFontData; ABoundingsX, AScale: Single): Single;
var
  LIndex: Integer;
  LChar: AnsiChar;
  LGlyph: TWarGlyph;
  LAdvance: Single;
  LWidth: Single;
  LStep: Single;
  LScaled: Single;
  LSource: TWarRectF;
  LDestination: TWarRectF;
begin
  Result := AX;
  if ACount <= 0 then
    Exit;
  // a span that goes past the end of the text (the tooltip of a price has a highlight of the text of the status, which is longer
  // than the number): the original reads the bytes of its buffer after the number, which are zeros, and draws the glyph of the
  // character 0 (the first one, the blank) for each of them. Before the start of the text it reads before the buffer
  if AIndex < 0 then
    raise EWarException.CreateFmt(SWarTextOutside, [ACount, AIndex, Length(AText)]);
  LAdvance := AFont.Advance;
  FTransform.Save;
  // the color of the text tints the image of the font
  FTransform.SetColorMod(AColor.R, AColor.G, AColor.B);
  for LIndex := 0 to ACount - 1 do
  begin
    LScaled := Result * AScale;
    if (ABoundingsX > 0) and (LScaled > ABoundingsX) then
      Break;
    if AIndex + LIndex < Length(AText) then
      LChar := AText[AIndex + LIndex + 1]
    else
      LChar := #0;
    if LChar = #10 then
    begin
      // a single text span is one line: the line feeds are spaces
      LGlyph := TWarTextLayout.GlyphOf(AFont, ' ');
      LWidth := LGlyph.Width;
      LStep := LWidth + LAdvance;
      Result := Result + LStep;
    end
    else if LChar = #9 then
    begin
      LGlyph := TWarTextLayout.GlyphOf(AFont, ' ');
      LWidth := LGlyph.Width;
      LStep := WAR_TAB_WIDTH * LWidth;
      LStep := LStep + LAdvance;
      Result := Result + LStep;
    end
    else
    begin
      LGlyph := TWarTextLayout.GlyphOf(AFont, LChar);
      LSource.X := LGlyph.X;
      LSource.Y := LGlyph.Y;
      LSource.Width := LGlyph.Width;
      LSource.Height := LGlyph.Height;
      LDestination.X := Result;
      LDestination.Y := AY;
      LDestination.Width := LGlyph.Width;
      LDestination.Height := LGlyph.Height;
      if OutlineOn then
        FTransform.FillRect(LDestination, GREEN_SELECTION);
      if LChar <> ' ' then
        FTransform.SubImage(LSource, LDestination, 1, 1);
      LWidth := LGlyph.Width;
      LStep := LWidth + LAdvance;
      Result := Result + LStep;
    end;
  end;
  // reset the color of the image to white
  FTransform.SetColorMod(255, 255, 255);
  FTransform.Restore;
end;

procedure TWarTextRenderer.RenderSingle(const AText: AnsiString; AX, AY: Single; const AParams: TWarFontParams);
var
  LLineHeight: Single;
  LScale: Single;
  LTextSize: TWarTextSize;
  LOffset: TWarTextSize;
  LLength: Integer;
  LX: Single;
  LColor: TWarRgba;
  LOutline: TWarRectF;
begin
  LLineHeight := AParams.FontData.LineHeight;
  LScale := AParams.FontSize / LLineHeight;
  LTextSize := TWarTextLayout.MeasureSingle(AText, -1, AParams);
  LLength := Length(AText);
  FTransform.Save;
  FTransform.Translate(AX, AY);
  if (AParams.BoundingsX <> 0) or (AParams.BoundingsY <> 0) then
  begin
    LOffset := TWarTextLayout.AlignmentOffset(AParams.HorizontalAlign, AParams.VerticalAlign, AParams.BoundingsX,
      AParams.BoundingsY, LTextSize);
    FTransform.Translate(LOffset.X, LOffset.Y);
  end;
  FTransform.Scale(LScale, LScale);
  if OutlineOn then
  begin
    LOutline.X := 0;
    LOutline.Y := 0;
    LOutline.Width := LTextSize.X / LScale;
    LOutline.Height := 1.5;
    FTransform.StrokeRect(LOutline, GREEN_SELECTION);
  end;
  if AParams.HighlightIndex >= 0 then
  begin
    LX := RenderSpan(AText, 0, AParams.HighlightIndex, 0, 0, AParams.FontColor, AParams.FontData, AParams.BoundingsX,
      LScale);
    LX := RenderSpan(AText, AParams.HighlightIndex, AParams.HighlightCount, LX, 0, AParams.HighlightColor,
      AParams.FontData, AParams.BoundingsX, LScale);
    RenderSpan(AText, AParams.HighlightIndex + AParams.HighlightCount,
      LLength - AParams.HighlightIndex - AParams.HighlightCount, LX, 0, AParams.FontColor, AParams.FontData,
      AParams.BoundingsX, LScale);
  end
  else
  begin
    // no highlight (-1) or all of it (-2)
    if AParams.HighlightIndex = WAR_ALL_HIGHLIGHT then
      LColor := AParams.HighlightColor
    else
      LColor := AParams.FontColor;
    RenderSpan(AText, 0, LLength, 0, 0, LColor, AParams.FontData, AParams.BoundingsX, LScale);
  end;
  FTransform.Restore;
end;

procedure TWarTextRenderer.RenderMulti(const AText: AnsiString; AX, AY: Single; const AParams: TWarFontParams);
var
  LLineHeightOfFont: Single;
  LScale: Single;
  LRowHeight: Single;
  LLines: TArray<TWarTextSpan>;
  LTextSize: TWarTextSize;
  LOffset: TWarTextSize;
  LLine: Integer;
  LLineStart: Integer;
  LLineLength: Integer;
  LLineText: AnsiString;
  LLineAlign: Single;
  LLineY: Single;
  LScaledY: Single;
  LX: Single;
  LHighlightIndex: Integer;
  LHighlightCount: Integer;
  LColor: TWarRgba;
  LOutline: TWarRectF;
begin
  LLineHeightOfFont := AParams.FontData.LineHeight;
  LScale := AParams.FontSize / LLineHeightOfFont;
  if AParams.LineHeight > 0 then
    LRowHeight := AParams.LineHeight
  else
    LRowHeight := LLineHeightOfFont;
  LLines := TWarTextLayout.SplitIntoLines(AText, WAR_MAX_LINES, AParams.BoundingsX, AParams);
  FTransform.Save;
  FTransform.Translate(AX, AY);
  LTextSize := TWarTextLayout.MeasureMulti(AText, AParams);
  LOffset := TWarTextLayout.AlignmentOffset(AParams.HorizontalAlign, AParams.VerticalAlign, AParams.BoundingsX,
    AParams.BoundingsY, LTextSize);
  FTransform.Translate(LOffset.X, LOffset.Y);
  if OutlineOn then
  begin
    LOutline.X := 0;
    LOutline.Y := 0;
    LOutline.Width := LTextSize.X;
    LOutline.Height := LTextSize.Y;
    FTransform.StrokeRect(LOutline, RED_SELECTION);
  end;
  LLineStart := 0;
  for LLine := 0 to High(LLines) do
  begin
    LLineLength := LLines[LLine].Length;
    LLineText := Copy(AText, LLines[LLine].Start + 1, LLineLength);
    LLineAlign := TWarTextLayout.LineAlignmentOffset(AParams.LineAlign, LTextSize.X, LLines[LLine].Width);
    LLineY := LLine * LRowHeight;
    LScaledY := LLineY * LScale;
    if LScaledY > AParams.BoundingsY then
      Break;
    FTransform.Save;
    FTransform.Translate(LLineAlign, 0);
    FTransform.Scale(LScale, LScale);
    FTransform.Translate(0, LLineY);
    if OutlineOn then
    begin
      LOutline.X := 0;
      LOutline.Y := 0;
      LOutline.Width := LLines[LLine].Width / LScale;
      LOutline.Height := LRowHeight;
      FTransform.StrokeRect(LOutline, GREEN_SELECTION);
    end;
    if (AParams.HighlightIndex >= LLineStart) and (AParams.HighlightIndex < LLineStart + LLineLength) then
    begin
      LHighlightIndex := AParams.HighlightIndex - LLineStart;
      LHighlightCount := LLineLength - LHighlightIndex;
      if AParams.HighlightCount < LHighlightCount then
        LHighlightCount := AParams.HighlightCount;
      LX := RenderSpan(LLineText, 0, LHighlightIndex, 0, 0, AParams.FontColor, AParams.FontData, AParams.BoundingsX, LScale);
      LX := RenderSpan(LLineText, LHighlightIndex, LHighlightCount, LX, 0, AParams.HighlightColor, AParams.FontData,
        AParams.BoundingsX, LScale);
      RenderSpan(LLineText, LHighlightIndex + LHighlightCount, LLineLength - LHighlightIndex - LHighlightCount, LX, 0,
        AParams.FontColor, AParams.FontData, AParams.BoundingsX, LScale);
    end
    else if (AParams.HighlightIndex < LLineStart) and (AParams.HighlightIndex + AParams.HighlightCount >= LLineStart) then
    begin
      LHighlightCount := AParams.HighlightIndex + AParams.HighlightCount - LLineStart;
      if LLineLength < LHighlightCount then
        LHighlightCount := LLineLength;
      LX := RenderSpan(LLineText, 0, LHighlightCount, 0, 0, AParams.HighlightColor, AParams.FontData, AParams.BoundingsX,
        LScale);
      RenderSpan(LLineText, LHighlightCount, LLineLength - LHighlightCount, LX, 0, AParams.FontColor, AParams.FontData,
        AParams.BoundingsX, LScale);
    end
    else
    begin
      if AParams.HighlightIndex = WAR_ALL_HIGHLIGHT then
        LColor := AParams.HighlightColor
      else
        LColor := AParams.FontColor;
      RenderSpan(LLineText, 0, LLineLength, 0, 0, LColor, AParams.FontData, AParams.BoundingsX, LScale);
    end;
    FTransform.Restore;
    Inc(LLineStart, LLineLength);
  end;
  FTransform.Restore;
end;

end.
