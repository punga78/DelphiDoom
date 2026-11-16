{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - paints the characters of a text at the    }
{  resolution of the display: as ink (color of the palette and coverage) or,    }
{  where there is no alpha, with the levels of the game                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.InkPainter;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Glyph.Types,
  DelphiDoom.XcomSurface.Ink.Types;

type
  /// <summary>
  ///   The color of a character as Text of OpenXcom gives it (PaletteShift): the palette index of a level of the
  ///   font is AColor + level * AMultiplier, mirrored around AMiddle when the text is inverted
  /// </summary>
  TXcomInkColor = record
    Color: Integer;
    Multiplier: Integer;
    Middle: Integer;
    class function Make(AColor, AMultiplier, AMiddle: Integer): TXcomInkColor; static;
    /// <summary>color + level * mul + (mid ? 2 * (mid - level) : 0), wrapped to a byte</summary>
    function IndexOf(ALevel: Integer): Byte;
  end;

  /// <summary>
  ///   Draws one character of a text on something AScale times larger than the picture of the game. The body of
  ///   a character of the font of the system has the brightest level of the font (1) and its coverage as alpha;
  ///   a character that stayed a picture of the game is that picture with every pixel AScale times larger. All
  ///   the positions are in pixels of the target; nothing is drawn outside AClip
  /// </summary>
  TXcomInkPainter = class sealed
  strict private
    class function InClip(AX, AY: Integer; const AClip: TXcomRect): Boolean; static; inline;
    class function SourceOf(APicture: TXcomSurface): TXcomRect; static;
  public
    /// <summary>The character at (AX, AY), the corner of its cell, as ink</summary>
    class procedure PaintGlyph(var ABuffer: TXcomInkBuffer; const AGlyph: TXcomDetailGlyph; AX, AY: Integer;
      const AColor: TXcomInkColor; const AClip: TXcomRect); static;
    /// <summary>The cropped part of a picture of the font, each pixel AScale times larger, as ink that covers all</summary>
    class procedure PaintEnlarged(var ABuffer: TXcomInkBuffer; APicture: TXcomSurface; AX, AY: Integer;
      const AColor: TXcomInkColor; const AClip: TXcomRect); static;
    /// <summary>
    ///   The character on a surface of indexes (no alpha: the globe of the geoscape): the coverage of the body
    ///   becomes the levels 1 to 3 as in the pictures laid over the font, the outline is where it covers half
    /// </summary>
    class procedure DrawGlyph(ATarget: TXcomSurface; const AGlyph: TXcomDetailGlyph; AX, AY: Integer;
      const AColor: TXcomInkColor); static;
    class procedure DrawEnlarged(ATarget: TXcomSurface; APicture: TXcomSurface; AX, AY, AScale: Integer;
      const AColor: TXcomInkColor); static;
  end;

implementation

uses
  DelphiDoom.XcomSurface.GlyphLevels;

const
  OPAQUE = 255;
  HALF_COVERED = 128;

class function TXcomInkColor.Make(AColor, AMultiplier, AMiddle: Integer): TXcomInkColor;
begin
  Result.Color := AColor;
  Result.Multiplier := AMultiplier;
  Result.Middle := AMiddle;
end;

function TXcomInkColor.IndexOf(ALevel: Integer): Byte;
var
  LInverse: Integer;
begin
  LInverse := 0;
  if Middle <> 0 then
    LInverse := 2 * (Middle - ALevel);
  Result := Byte((Color + ALevel * Multiplier + LInverse) and $FF);
end;

class function TXcomInkPainter.InClip(AX, AY: Integer; const AClip: TXcomRect): Boolean;
begin
  Result := (AX >= AClip.X) and (AY >= AClip.Y) and (AX < AClip.X + AClip.W) and (AY < AClip.Y + AClip.H);
end;

class function TXcomInkPainter.SourceOf(APicture: TXcomSurface): TXcomRect;
begin
  Result := APicture.Crop;
  if (Result.W = 0) or (Result.H = 0) then
    Result := TXcomRect.Make(0, 0, APicture.Width, APicture.Height);
end;

class procedure TXcomInkPainter.PaintGlyph(var ABuffer: TXcomInkBuffer; const AGlyph: TXcomDetailGlyph; AX,
  AY: Integer; const AColor: TXcomInkColor; const AClip: TXcomRect);
var
  LX: Integer;
  LY: Integer;
  LIndex: Integer;
  LFront: Byte;
  LBody: Byte;
  LOutline: Byte;
  LBack: Byte;
  LLevels: array[XCOM_GLYPH_LEVEL_OUTLINE..XCOM_GLYPH_LEVEL_CORNER] of Byte;
  LHasOutline: Boolean;
begin
  LFront := AColor.IndexOf(XCOM_GLYPH_LEVEL_FIRST);
  LLevels[XCOM_GLYPH_LEVEL_OUTLINE] := AColor.IndexOf(XCOM_GLYPH_LEVEL_OUTLINE);
  LLevels[XCOM_GLYPH_LEVEL_CORNER] := AColor.IndexOf(XCOM_GLYPH_LEVEL_CORNER);
  LHasOutline := Length(AGlyph.Outline) > 0;
  for LY := 0 to AGlyph.Height - 1 do
    for LX := 0 to AGlyph.Width - 1 do
    begin
      LIndex := LY * AGlyph.Width + LX;
      LBody := AGlyph.Body[LIndex];
      LOutline := 0;
      LBack := 0;
      if LHasOutline then
      begin
        LOutline := AGlyph.Outline[LIndex];
        if LOutline <> 0 then
          LBack := LLevels[AGlyph.OutlineLevel[LIndex]];
      end;
      if ((LBody <> 0) or (LOutline <> 0)) and InClip(AX + AGlyph.Left + LX, AY + AGlyph.Top + LY, AClip) then
        ABuffer.Put(AX + AGlyph.Left + LX, AY + AGlyph.Top + LY, TXcomInkBuffer.Pack(LFront, LBody, LBack, LOutline));
    end;
end;

class procedure TXcomInkPainter.PaintEnlarged(var ABuffer: TXcomInkBuffer; APicture: TXcomSurface; AX, AY: Integer;
  const AColor: TXcomInkColor; const AClip: TXcomRect);
var
  LSource: TXcomRect;
  LX: Integer;
  LY: Integer;
  LSubX: Integer;
  LSubY: Integer;
  LLevel: Byte;
  LValue: TXcomInkPixel;
begin
  LSource := SourceOf(APicture);
  for LY := 0 to LSource.H - 1 do
    for LX := 0 to LSource.W - 1 do
    begin
      LLevel := APicture.GetPixel(LSource.X + LX, LSource.Y + LY);
      if LLevel = 0 then
        Continue;
      LValue := TXcomInkBuffer.Pack(AColor.IndexOf(LLevel), OPAQUE, 0, 0);
      for LSubY := 0 to ABuffer.Scale - 1 do
        for LSubX := 0 to ABuffer.Scale - 1 do
          if InClip(AX + LX * ABuffer.Scale + LSubX, AY + LY * ABuffer.Scale + LSubY, AClip) then
            ABuffer.Put(AX + LX * ABuffer.Scale + LSubX, AY + LY * ABuffer.Scale + LSubY, LValue);
    end;
end;

class procedure TXcomInkPainter.DrawGlyph(ATarget: TXcomSurface; const AGlyph: TXcomDetailGlyph; AX, AY: Integer;
  const AColor: TXcomInkColor);
var
  LX: Integer;
  LY: Integer;
  LIndex: Integer;
  LLevel: Byte;
begin
  for LY := 0 to AGlyph.Height - 1 do
    for LX := 0 to AGlyph.Width - 1 do
    begin
      LIndex := LY * AGlyph.Width + LX;
      LLevel := TXcomGlyphLevels.LevelOf(AGlyph.Body[LIndex]);
      if (LLevel = 0) and (Length(AGlyph.Outline) > 0) and (AGlyph.Outline[LIndex] >= HALF_COVERED) then
        LLevel := AGlyph.OutlineLevel[LIndex];
      if LLevel <> 0 then
        ATarget.SetPixel(AX + AGlyph.Left + LX, AY + AGlyph.Top + LY, AColor.IndexOf(LLevel));
    end;
end;

class procedure TXcomInkPainter.DrawEnlarged(ATarget: TXcomSurface; APicture: TXcomSurface; AX, AY, AScale: Integer;
  const AColor: TXcomInkColor);
var
  LSource: TXcomRect;
  LX: Integer;
  LY: Integer;
  LSubX: Integer;
  LSubY: Integer;
  LLevel: Byte;
begin
  LSource := SourceOf(APicture);
  for LY := 0 to LSource.H - 1 do
    for LX := 0 to LSource.W - 1 do
    begin
      LLevel := APicture.GetPixel(LSource.X + LX, LSource.Y + LY);
      if LLevel = 0 then
        Continue;
      for LSubY := 0 to AScale - 1 do
        for LSubX := 0 to AScale - 1 do
          ATarget.SetPixel(AX + LX * AScale + LSubX, AY + LY * AScale + LSubY, AColor.IndexOf(LLevel));
    end;
end;

end.
