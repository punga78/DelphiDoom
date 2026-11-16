{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the characters of a font of Windows drawn with GDI      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Win.GdiGlyphRasterizer;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.XcomSurface.Glyph.Types, DelphiDoom.XcomSurface.GlyphRasterizer.Intf;

type
  /// <summary>
  ///   IXcomGlyphRasterizer on GDI: a font and a memory device context. With antialiasing a scalable font gives
  ///   the gray levels of its outlines (GetGlyphOutline, 65 levels, not hinted to whole pixels); without it, and
  ///   for the bitmap fonts of Windows, one character at a time is written in white on black in a 32 bit bitmap
  ///   (the pixels the system would draw: hinted, either on or off; the green of a pixel is how much it is
  ///   covered). The handles belong to the object and go with it; it must be created, used and freed by one thread
  /// </summary>
  TXcomGdiGlyphRasterizer = class(TInterfacedObject, IXcomGlyphRasterizer)
  strict private
    const
      GGI_MARK_NONEXISTING_GLYPHS = 1;
      NO_GLYPH = $FFFF;
      MARGIN = 8;
      FIRST_RASTER_CHAR = 33;
      LAST_RASTER_CHAR = 126;
      GRAY8_LEVELS = 64;
    var
      FDC: HDC;
      FFont: HFONT;
      FOldFont: HGDIOBJ;
      FBitmap: HBITMAP;
      FOldBitmap: HGDIOBJ;
      FBits: PCardinal;
      FWidth: Integer;
      FHeight: Integer;
      FOriginX: Integer;
      FOriginY: Integer;
      FScalable: Boolean;
      FFaceName: string;
      FAntialias: Boolean;
      FAscent: Integer;
    procedure Release;
    /// <summary>GetGlyphOutline: the gray levels of the outline of the character, whatever the size</summary>
    function RasterizeOutline(ACode: Cardinal; out AGlyph: TXcomGlyphBitmap): Boolean;
    /// <summary>TextOut in the bitmap: the pixels the system draws (a bitmap font, or no antialiasing)</summary>
    function RasterizeText(ACode: Cardinal; out AGlyph: TXcomGlyphBitmap): Boolean;
  public
    /// <param name="APixelSize">The height of the em square in pixels</param>
    /// <exception cref="EOSError">GDI could not create the context, the font or the bitmap</exception>
    constructor Create(const AFaceName: string; APixelSize: Integer; ABold, AAntialias: Boolean);
    destructor Destroy; override;
    /// <summary>The family GDI really selected: another one when the font asked for is not installed</summary>
    property FaceName: string read FFaceName;
    function HasGlyph(ACode: Cardinal): Boolean;
    function Rasterize(ACode: Cardinal; out AGlyph: TXcomGlyphBitmap): Boolean;
    /// <summary>The ascent of the font: Top is counted from the top of the line in both ways of drawing</summary>
    function Baseline: Integer;
  end;

implementation

constructor TXcomGdiGlyphRasterizer.Create(const AFaceName: string; APixelSize: Integer; ABold, AAntialias: Boolean);
var
  LWeight: Integer;
  LQuality: Cardinal;
  LMetrics: TTextMetric;
  LInfo: TBitmapInfo;
  LName: array[0..LF_FACESIZE] of Char;
  LBits: Pointer;
begin
  inherited Create;
  try
    FDC := CreateCompatibleDC(0);
    if FDC = 0 then
      RaiseLastOSError;
    if ABold then
      LWeight := FW_BOLD
    else
      LWeight := FW_NORMAL;
    if AAntialias then
      LQuality := ANTIALIASED_QUALITY
    else
      LQuality := NONANTIALIASED_QUALITY;
    FFont := CreateFont(-APixelSize, 0, 0, 0, LWeight, 0, 0, 0, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
      CLIP_DEFAULT_PRECIS, LQuality, DEFAULT_PITCH or FF_DONTCARE, PChar(AFaceName));
    if FFont = 0 then
      RaiseLastOSError;
    FOldFont := SelectObject(FDC, FFont);
    if not GetTextMetrics(FDC, LMetrics) then
      RaiseLastOSError;
    FScalable := LMetrics.tmPitchAndFamily and (TMPF_TRUETYPE or TMPF_VECTOR) <> 0;
    FAntialias := AAntialias;
    FAscent := LMetrics.tmAscent;
    FillChar(LName, SizeOf(LName), 0);
    GetTextFace(FDC, Length(LName), LName);
    FFaceName := LName;
    // room for a character that goes out of its cell on every side
    FOriginX := LMetrics.tmHeight + MARGIN;
    FOriginY := LMetrics.tmHeight + MARGIN;
    FWidth := 4 * LMetrics.tmHeight + 2 * MARGIN;
    FHeight := 3 * LMetrics.tmHeight + 2 * MARGIN;
    FillChar(LInfo, SizeOf(LInfo), 0);
    LInfo.bmiHeader.biSize := SizeOf(LInfo.bmiHeader);
    LInfo.bmiHeader.biWidth := FWidth;
    // top down
    LInfo.bmiHeader.biHeight := -FHeight;
    LInfo.bmiHeader.biPlanes := 1;
    LInfo.bmiHeader.biBitCount := 32;
    LInfo.bmiHeader.biCompression := BI_RGB;
    LBits := nil;
    FBitmap := CreateDIBSection(FDC, LInfo, DIB_RGB_COLORS, LBits, 0, 0);
    if (FBitmap = 0) or not Assigned(LBits) then
      RaiseLastOSError;
    FBits := LBits;
    FOldBitmap := SelectObject(FDC, FBitmap);
    SetBkMode(FDC, TRANSPARENT);
    SetTextColor(FDC, $FFFFFF);
    SetTextAlign(FDC, TA_LEFT or TA_TOP);
  except
    Release;
    raise;
  end;
end;

destructor TXcomGdiGlyphRasterizer.Destroy;
begin
  Release;
  inherited Destroy;
end;

procedure TXcomGdiGlyphRasterizer.Release;
begin
  if FDC <> 0 then
  begin
    if FOldBitmap <> 0 then
      SelectObject(FDC, FOldBitmap);
    if FOldFont <> 0 then
      SelectObject(FDC, FOldFont);
  end;
  if FBitmap <> 0 then
    DeleteObject(FBitmap);
  if FFont <> 0 then
    DeleteObject(FFont);
  if FDC <> 0 then
    DeleteDC(FDC);
  FBitmap := 0;
  FFont := 0;
  FDC := 0;
  FOldBitmap := 0;
  FOldFont := 0;
  FBits := nil;
end;

function TXcomGdiGlyphRasterizer.HasGlyph(ACode: Cardinal): Boolean;
var
  LChar: WideChar;
  LIndex: Word;
begin
  // a bitmap font of Windows is a code page: only the ASCII characters are surely the ones asked for
  if not FScalable then
    Exit((ACode >= FIRST_RASTER_CHAR) and (ACode <= LAST_RASTER_CHAR));
  // outside the basic plane GDI has no question to ask the font
  if ACode > $FFFF then
    Exit(False);
  LChar := WideChar(ACode);
  LIndex := NO_GLYPH;
  Result := (GetGlyphIndicesW(FDC, @LChar, 1, @LIndex, GGI_MARK_NONEXISTING_GLYPHS) <> GDI_ERROR) and
    (LIndex <> NO_GLYPH);
end;

function TXcomGdiGlyphRasterizer.RasterizeOutline(ACode: Cardinal; out AGlyph: TXcomGlyphBitmap): Boolean;
var
  LMetrics: TGlyphMetrics;
  LMatrix: TMat2;
  LSize: DWORD;
  LBuffer: TBytes;
  LPitch: Integer;
  LX: Integer;
  LY: Integer;
begin
  AGlyph := TXcomGlyphBitmap.Make(0, 0, 0);
  FillChar(LMatrix, SizeOf(LMatrix), 0);
  LMatrix.eM11.value := 1;
  LMatrix.eM22.value := 1;
  FillChar(LMetrics, SizeOf(LMetrics), 0);
  LSize := GetGlyphOutlineW(FDC, ACode, GGO_GRAY8_BITMAP, LMetrics, 0, nil, LMatrix);
  // a space has no bitmap
  if (LSize = GDI_ERROR) or (LSize = 0) then
    Exit(False);
  SetLength(LBuffer, LSize);
  if GetGlyphOutlineW(FDC, ACode, GGO_GRAY8_BITMAP, LMetrics, LSize, @LBuffer[0], LMatrix) = GDI_ERROR then
    Exit(False);
  // the rows are aligned to four bytes and a pixel goes from 0 to 64
  LPitch := (Integer(LMetrics.gmBlackBoxX) + 3) and not 3;
  if Integer(LMetrics.gmBlackBoxY) * LPitch > Integer(LSize) then
    Exit(False);
  AGlyph := TXcomGlyphBitmap.Make(LMetrics.gmBlackBoxX, LMetrics.gmBlackBoxY, FAscent - LMetrics.gmptGlyphOrigin.Y);
  for LY := 0 to AGlyph.Height - 1 do
    for LX := 0 to AGlyph.Width - 1 do
      AGlyph.Pixels[LY * AGlyph.Width + LX] := Byte(LBuffer[LY * LPitch + LX] * 255 div GRAY8_LEVELS);
  Result := True;
end;

function TXcomGdiGlyphRasterizer.Rasterize(ACode: Cardinal; out AGlyph: TXcomGlyphBitmap): Boolean;
begin
  // with antialiasing TextOut follows the font, and many fonts ask for none at the sizes of this screen (an N
  // of Consolas 9 is a full rectangle): the outline in gray levels is asked for directly
  if FScalable and FAntialias then
    Result := RasterizeOutline(ACode, AGlyph)
  else
    Result := RasterizeText(ACode, AGlyph);
end;

function TXcomGdiGlyphRasterizer.Baseline: Integer;
begin
  Result := FAscent;
end;

function TXcomGdiGlyphRasterizer.RasterizeText(ACode: Cardinal; out AGlyph: TXcomGlyphBitmap): Boolean;
var
  LChar: WideChar;
  LX: Integer;
  LY: Integer;
  LLeft: Integer;
  LRight: Integer;
  LTop: Integer;
  LBottom: Integer;
  LPixel: PCardinal;
begin
  AGlyph := TXcomGlyphBitmap.Make(0, 0, 0);
  if ACode > $FFFF then
    Exit(False);
  LChar := WideChar(ACode);
  FillChar(FBits^, FWidth * FHeight * SizeOf(Cardinal), 0);
  if not TextOutW(FDC, FOriginX, FOriginY, @LChar, 1) then
    Exit(False);
  GdiFlush;
  LLeft := FWidth;
  LRight := -1;
  LTop := FHeight;
  LBottom := -1;
  LPixel := FBits;
  for LY := 0 to FHeight - 1 do
    for LX := 0 to FWidth - 1 do
    begin
      if LPixel^ and $00FF00 <> 0 then
      begin
        if LX < LLeft then
          LLeft := LX;
        if LX > LRight then
          LRight := LX;
        if LY < LTop then
          LTop := LY;
        LBottom := LY;
      end;
      Inc(LPixel);
    end;
  if LRight < 0 then
    Exit(False);
  AGlyph := TXcomGlyphBitmap.Make(LRight - LLeft + 1, LBottom - LTop + 1, LTop - FOriginY);
  for LY := LTop to LBottom do
  begin
    LPixel := FBits;
    Inc(LPixel, LY * FWidth + LLeft);
    for LX := 0 to AGlyph.Width - 1 do
    begin
      AGlyph.Pixels[(LY - LTop) * AGlyph.Width + LX] := Byte(LPixel^ shr 8 and $FF);
      Inc(LPixel);
    end;
  end;
  Result := True;
end;

end.
