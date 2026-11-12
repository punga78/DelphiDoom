{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - lays the characters of a font of the      }
{  system over a font of the game                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.FontOverlayBuilder;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomSurface.Glyph.Types, DelphiDoom.XcomSurface.GlyphRasterizer.Intf;

type
  /// <summary>
  ///   Draws the characters of a font of the game with a rasterizer and adds them to the font as new pictures,
  ///   one for every picture of the original: a grid of cells with the same conventions (the levels 1 to 5, the
  ///   outline, the cut to the columns in use or the whole cell of a monospace font). The original pictures stay
  ///   in the font: the first one still gives the height of a line and the width of a space, so the screens keep
  ///   their layout, and a character that the new font does not have, or draws too wide, is still the original
  ///   one. Who draws the text sees a TXcomFont as before
  /// </summary>
  TXcomFontOverlayBuilder = class
  strict private
    type
      TEntry = record
        Code: Cardinal;
        Glyph: TXcomGlyphBitmap;
      end;
    const
      COLUMNS = 16;
      FIRST_PRINTABLE = 33;
      LAST_ASCII = 126;
    class function IsLetterOrDigit(ACode: Cardinal): Boolean; static;
    class function HasInk(const AGlyph: TXcomGlyphBitmap): Boolean; static;
    class function Limit(ASize, ATolerance: Integer): Integer; static;
    function Collect(AFont: TXcomFont; AImage: Integer; const ARasterizer: IXcomGlyphRasterizer; AOutline: Boolean;
      var AReport: TXcomFontOverlayReport): TList<TEntry>;
    function CutToCell(const AGlyph: TXcomGlyphBitmap; ATop, AHeight: Integer; out AClipped: Boolean): TXcomGlyphBitmap;
    procedure AddPage(AFont: TXcomFont; AEntries: TList<TEntry>; AWidthLimit, ATop, AHeight, ASpacing: Integer;
      var AReport: TXcomFontOverlayReport);
  public
    const
      /// <summary>A font is outlined when at least one pixel in this many has a level of the outline</summary>
      OUTLINE_SHARE = 4;
    /// <summary>
    ///   Whether the first picture of a font draws its characters with an outline (the big and small fonts do:
    ///   seven pixels in ten are outline; the fonts of the geoscape have none)
    /// </summary>
    class function IsOutlined(AFont: TXcomFont): Boolean; static;
    /// <summary>
    ///   Adds the pictures to AFont. False, and the font untouched, when the reference characters (the printable
    ///   ASCII ones of the first picture) are missing, or taller than the first cell of the original beyond the
    ///   tolerance, or its letters and digits wider. The other characters are placed on the same rows: what
    ///   falls outside the cell is cut
    /// </summary>
    function Apply(AFont: TXcomFont; const ARasterizer: IXcomGlyphRasterizer;
      const ASettings: TXcomFontOverlaySettings; out AReport: TXcomFontOverlayReport): Boolean;
  end;

implementation

uses
  DelphiDoom.XcomSurface.GlyphLevels;

const
  SNoFont = 'Xcom: no font to lay the characters over';
  SNoRasterizer = 'Xcom: no rasterizer for the characters of the font';

class function TXcomFontOverlayBuilder.IsLetterOrDigit(ACode: Cardinal): Boolean;
begin
  Result := ((ACode >= Ord('0')) and (ACode <= Ord('9'))) or ((ACode >= Ord('A')) and (ACode <= Ord('Z'))) or
    ((ACode >= Ord('a')) and (ACode <= Ord('z')));
end;

class function TXcomFontOverlayBuilder.HasInk(const AGlyph: TXcomGlyphBitmap): Boolean;
var
  LPixel: Byte;
begin
  for LPixel in AGlyph.Pixels do
    if LPixel <> 0 then
      Exit(True);
  Result := False;
end;

class function TXcomFontOverlayBuilder.Limit(ASize, ATolerance: Integer): Integer;
begin
  if ATolerance < 0 then
    ATolerance := 0;
  Result := ASize * (100 + ATolerance) div 100;
end;

class function TXcomFontOverlayBuilder.IsOutlined(AFont: TXcomFont): Boolean;
var
  LPixel: Byte;
  LInk: Integer;
  LOutline: Integer;
begin
  LInk := 0;
  LOutline := 0;
  if AFont.ImageCount > 0 then
    for LPixel in AFont.ImageSurface(0).Pixels do
    begin
      if LPixel <> 0 then
        Inc(LInk);
      if (LPixel >= XCOM_GLYPH_LEVEL_OUTLINE) and (LPixel <= XCOM_GLYPH_LEVEL_LAST) then
        Inc(LOutline);
    end;
  // FontGeoSmall.png has one stray pixel of level 4 in 1615: an outline is most of the pixels of a character
  Result := LOutline * OUTLINE_SHARE >= LInk;
  if LInk = 0 then
    Result := False;
end;

function TXcomFontOverlayBuilder.Collect(AFont: TXcomFont; AImage: Integer;
  const ARasterizer: IXcomGlyphRasterizer; AOutline: Boolean; var AReport: TXcomFontOverlayReport): TList<TEntry>;
var
  LCode: Cardinal;
  LCoverage: TXcomGlyphBitmap;
  LEntry: TEntry;
begin
  Result := TList<TEntry>.Create;
  try
    for LCode in AFont.CodesOfImage(AImage) do
    begin
      if LCode < FIRST_PRINTABLE then
        Continue;
      LEntry.Code := LCode;
      if ARasterizer.HasGlyph(LCode) and ARasterizer.Rasterize(LCode, LCoverage) then
      begin
        LEntry.Glyph := TXcomGlyphLevels.Reduce(LCoverage, AOutline);
        // a thin character can lose every pixel in the reduction: it stays the original one
        if HasInk(LEntry.Glyph) then
        begin
          Result.Add(LEntry);
          Continue;
        end;
      end;
      Inc(AReport.Missing);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TXcomFontOverlayBuilder.CutToCell(const AGlyph: TXcomGlyphBitmap; ATop, AHeight: Integer;
  out AClipped: Boolean): TXcomGlyphBitmap;
var
  LX: Integer;
  LY: Integer;
  LRow: Integer;
  LPixel: Byte;
begin
  // the rows of the cell, with the character on the rows its Top says
  Result := TXcomGlyphBitmap.Make(AGlyph.Width, AHeight, ATop);
  AClipped := False;
  for LY := 0 to AGlyph.Height - 1 do
  begin
    LRow := AGlyph.Top + LY - ATop;
    for LX := 0 to AGlyph.Width - 1 do
    begin
      LPixel := AGlyph.At(LX, LY);
      if LPixel = 0 then
        Continue;
      if (LRow < 0) or (LRow >= AHeight) then
        AClipped := True
      else
        Result.Pixels[LRow * Result.Width + LX] := LPixel;
    end;
  end;
end;

procedure TXcomFontOverlayBuilder.AddPage(AFont: TXcomFont; AEntries: TList<TEntry>; AWidthLimit, ATop, AHeight,
  ASpacing: Integer; var AReport: TXcomFontOverlayReport);
var
  LCells: TList<TEntry>;
  LEntry: TEntry;
  LCell: TEntry;
  LClipped: Boolean;
  LCellWidth: Integer;
  LSurface: TXcomSurface;
  LCodes: TArray<Cardinal>;
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
  LPixel: Byte;
begin
  LCells := TList<TEntry>.Create;
  try
    LCellWidth := 0;
    for LEntry in AEntries do
    begin
      if LEntry.Glyph.Width > AWidthLimit then
      begin
        Inc(AReport.TooWide);
        Continue;
      end;
      LCell.Code := LEntry.Code;
      LCell.Glyph := CutToCell(LEntry.Glyph, ATop, AHeight, LClipped);
      if not HasInk(LCell.Glyph) then
      begin
        Inc(AReport.Missing);
        Continue;
      end;
      if LClipped then
        Inc(AReport.Clipped);
      if LCell.Glyph.Width > LCellWidth then
        LCellWidth := LCell.Glyph.Width;
      LCells.Add(LCell);
    end;
    if LCells.Count = 0 then
      Exit;
    SetLength(LCodes, LCells.Count);
    LSurface := TXcomSurface.Create(COLUMNS * LCellWidth, ((LCells.Count + COLUMNS - 1) div COLUMNS) * AHeight);
    try
      for LIndex := 0 to LCells.Count - 1 do
      begin
        LCell := LCells[LIndex];
        LCodes[LIndex] := LCell.Code;
        for LY := 0 to AHeight - 1 do
          for LX := 0 to LCell.Glyph.Width - 1 do
          begin
            LPixel := LCell.Glyph.At(LX, LY);
            if LPixel <> 0 then
              LSurface.SetPixel(LIndex mod COLUMNS * LCellWidth + LX, LIndex div COLUMNS * AHeight + LY, LPixel);
          end;
      end;
    except
      LSurface.Free;
      raise;
    end;
    // the font owns the surface from here
    AFont.Init(AFont.AddImage(LCellWidth, AHeight, ASpacing, LSurface), LCodes);
    Inc(AReport.Replaced, LCells.Count);
  finally
    LCells.Free;
  end;
end;

function TXcomFontOverlayBuilder.Apply(AFont: TXcomFont; const ARasterizer: IXcomGlyphRasterizer;
  const ASettings: TXcomFontOverlaySettings; out AReport: TXcomFontOverlayReport): Boolean;
var
  LPages: TObjectList<TList<TEntry>>;
  LOriginalOutlined: Boolean;
  LOutline: Boolean;
  LImageCount: Integer;
  LImage: Integer;
  LEntry: TEntry;
  LTop: Integer;
  LBottom: Integer;
  LWidth: Integer;
  LLetterWidth: Integer;
  LFound: Boolean;
  LSpacing: Integer;
begin
  AReport := Default(TXcomFontOverlayReport);
  if not Assigned(AFont) or (AFont.ImageCount = 0) then
    raise EXcomSurfaceException.Create(SNoFont);
  if not Assigned(ARasterizer) then
    raise EArgumentNilException.Create(SNoRasterizer);
  LOriginalOutlined := IsOutlined(AFont);
  LOutline := (ASettings.Outline = goOn) or ((ASettings.Outline = goAuto) and LOriginalOutlined);
  LImageCount := AFont.ImageCount;
  LPages := TObjectList<TList<TEntry>>.Create(True);
  try
    for LImage := 0 to LImageCount - 1 do
      LPages.Add(Collect(AFont, LImage, ARasterizer, LOutline, AReport));
    // the reference: the printable ASCII characters of the first picture give the rows of the line
    LFound := False;
    LTop := 0;
    LBottom := 0;
    LWidth := 0;
    LLetterWidth := 0;
    for LEntry in LPages[0] do
    begin
      if LEntry.Code > LAST_ASCII then
        Continue;
      if not LFound or (LEntry.Glyph.Top < LTop) then
        LTop := LEntry.Glyph.Top;
      if not LFound or (LEntry.Glyph.Top + LEntry.Glyph.Height > LBottom) then
        LBottom := LEntry.Glyph.Top + LEntry.Glyph.Height;
      LFound := True;
      if LEntry.Glyph.Width > LWidth then
        LWidth := LEntry.Glyph.Width;
      if IsLetterOrDigit(LEntry.Code) and (LEntry.Glyph.Width > LLetterWidth) then
        LLetterWidth := LEntry.Glyph.Width;
    end;
    if not LFound then
    begin
      AReport.Refusal := frNoGlyphs;
      Exit(False);
    end;
    if LLetterWidth = 0 then
      LLetterWidth := LWidth;
    AReport.Height := LBottom - LTop;
    AReport.Width := LLetterWidth;
    AReport.HeightLimit := Limit(AFont.Height, ASettings.Tolerance);
    AReport.WidthLimit := Limit(AFont.Width, ASettings.Tolerance);
    if AReport.Height > AReport.HeightLimit then
      AReport.Refusal := frTooTall
    else if AReport.Width > AReport.WidthLimit then
      AReport.Refusal := frTooWide;
    if AReport.Refusal <> frNone then
      Exit(False);
    AReport.FirstImage := LImageCount;
    AReport.LineTop := LTop - ASettings.OffsetY;
    AReport.Baseline := ARasterizer.Baseline;
    AReport.Outlined := LOutline;
    for LImage := 0 to LImageCount - 1 do
    begin
      LSpacing := ASettings.Spacing;
      if not ASettings.HasSpacing then
      begin
        // an outline takes a pixel on each side of the character: the body keeps its distance
        LSpacing := AFont.Image(LImage).Spacing;
        if LOriginalOutlined and not LOutline then
          Inc(LSpacing, 2)
        else if LOutline and not LOriginalOutlined then
          Dec(LSpacing, 2);
      end;
      AddPage(AFont, LPages[LImage], Limit(AFont.Image(LImage).Width, ASettings.Tolerance),
        LTop - ASettings.OffsetY, AReport.Height, LSpacing, AReport);
    end;
    Result := AReport.Replaced > 0;
    if not Result then
      AReport.Refusal := frNoGlyphs;
  finally
    LPages.Free;
  end;
end;

end.
