{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the characters of a font of the system     }
{  at the resolution of the display (issue 184): drawn again, larger, for the   }
{  cells of the pictures that were laid over a font of the game                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.DetailFont;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomSurface.Glyph.Types, DelphiDoom.XcomSurface.Ink.Types,
  DelphiDoom.XcomSurface.GlyphRasterizer.Intf, DelphiDoom.XcomSurface.FontDetail.Intf, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.TrueColor.Intf;

type
  /// <summary>
  ///   IXcomFontDetail of a font of the game that got the characters of a font of the system. The scale is the
  ///   one of the display (IXcomDetailLayers.DetailScale: it changes with the size of the window); the rasterizer
  ///   of a scale is opened the first time a character is asked for at that scale and the characters are kept.
  ///   A character goes where its picture at 320 x 200 is: on the same baseline, its body centered on the columns
  ///   of the body of the picture, so the cells, the widths and the lines of the text do not change. Only the
  ///   characters the pictures took from the font of the system are drawn: the others stay pictures of the game.
  ///   The handles of the system belong to the rasterizer, that goes with this object or at a change of scale
  /// </summary>
  TXcomDetailFont = class(TInterfacedObject, IXcomFontDetail)
  strict private
    type
      TEntry = record
        Found: Boolean;
        Glyph: TXcomDetailGlyph;
      end;
    var
      FFont: TXcomFont;
      FFace: TXcomFontFace;
      FReport: TXcomFontOverlayReport;
      FFactory: IXcomGlyphRasterizerFactory;
      FDisplay: IXcomDetailLayers;
      FLayers: IXcomInkLayers;
      FLog: IXcomLog;
      FRasterizer: IXcomGlyphRasterizer;
      FRasterScale: Integer;
      FGlyphs: TDictionary<Cardinal, TEntry>;
    procedure Open(AScale: Integer);
    function BodyColumns(const AChar: TXcomFontChar; out AFirst, ACount: Integer): Boolean;
  public
    /// <param name="AFont">The font of the game, after the pictures were added; not owned (it holds this object)</param>
    /// <param name="AReport">What the builder of the pictures said: where the rows and the baseline are</param>
    /// <param name="ADisplay">Says the scale of the display</param>
    /// <param name="ALayers">Where the widgets leave the ink</param>
    /// <param name="ALog">nil for no log</param>
    constructor Create(AFont: TXcomFont; const AFace: TXcomFontFace; const AReport: TXcomFontOverlayReport;
      const AFactory: IXcomGlyphRasterizerFactory; const ADisplay: IXcomDetailLayers; const ALayers: IXcomInkLayers;
      const ALog: IXcomLog);
    destructor Destroy; override;
    function Scale: Integer;
    function TryGetGlyph(ACode: Cardinal; out AGlyph: TXcomDetailGlyph): Boolean;
    function Layers: IXcomInkLayers;
  end;

implementation

uses
  DelphiDoom.XcomSurface.DetailGlyphBuilder;

const
  SLevelWarning = 'WARN';
  SNoRasterizer = 'font "%s" %d at %d times: %s: the text stays the one of the 320 x 200 screen';

constructor TXcomDetailFont.Create(AFont: TXcomFont; const AFace: TXcomFontFace;
  const AReport: TXcomFontOverlayReport; const AFactory: IXcomGlyphRasterizerFactory;
  const ADisplay: IXcomDetailLayers; const ALayers: IXcomInkLayers; const ALog: IXcomLog);
begin
  inherited Create;
  if not Assigned(AFont) then
    raise EArgumentNilException.Create('AFont');
  if not Assigned(AFactory) then
    raise EArgumentNilException.Create('AFactory');
  if not Assigned(ADisplay) then
    raise EArgumentNilException.Create('ADisplay');
  if not Assigned(ALayers) then
    raise EArgumentNilException.Create('ALayers');
  FFont := AFont;
  FFace := AFace;
  FReport := AReport;
  FFactory := AFactory;
  FDisplay := ADisplay;
  FLayers := ALayers;
  FLog := ALog;
  FGlyphs := TDictionary<Cardinal, TEntry>.Create;
end;

destructor TXcomDetailFont.Destroy;
begin
  FRasterizer := nil;
  FGlyphs.Free;
  inherited Destroy;
end;

function TXcomDetailFont.Scale: Integer;
begin
  Result := FDisplay.DetailScale;
end;

function TXcomDetailFont.Layers: IXcomInkLayers;
begin
  Result := FLayers;
end;

procedure TXcomDetailFont.Open(AScale: Integer);
var
  LReason: string;
  LName: string;
begin
  // the characters of another scale are of no use, and neither are the handles that drew them
  FGlyphs.Clear;
  FRasterizer := nil;
  FRasterScale := AScale;
  FRasterizer := FFactory.CreateRasterizer(FFace, AScale, LReason);
  if not Assigned(FRasterizer) and Assigned(FLog) then
  begin
    LName := FFace.Name;
    if LName = '' then
      LName := FFace.FileName;
    FLog.Write(SLevelWarning, Format(SNoRasterizer, [LName, FFace.Size, AScale, LReason]));
  end;
end;

function TXcomDetailFont.BodyColumns(const AChar: TXcomFontChar; out AFirst, ACount: Integer): Boolean;
var
  LSurface: TXcomSurface;
  LX: Integer;
  LY: Integer;
  LLast: Integer;
  LLevel: Byte;
begin
  // the columns of the picture of the character that have the body (the levels below the ones of the outline)
  LSurface := FFont.ImageSurface(AChar.ImageIndex);
  AFirst := -1;
  LLast := -1;
  for LX := 0 to AChar.Rect.W - 1 do
    for LY := 0 to AChar.Rect.H - 1 do
    begin
      LLevel := LSurface.GetPixel(AChar.Rect.X + LX, AChar.Rect.Y + LY);
      if (LLevel <> 0) and (LLevel < XCOM_GLYPH_LEVEL_OUTLINE) then
      begin
        if AFirst < 0 then
          AFirst := LX;
        LLast := LX;
        Break;
      end;
    end;
  Result := AFirst >= 0;
  ACount := LLast - AFirst + 1;
end;

function TXcomDetailFont.TryGetGlyph(ACode: Cardinal; out AGlyph: TXcomDetailGlyph): Boolean;
var
  LScale: Integer;
  LEntry: TEntry;
  LChar: TXcomFontChar;
  LCoverage: TXcomGlyphBitmap;
  LFirst: Integer;
  LCount: Integer;
begin
  AGlyph := Default(TXcomDetailGlyph);
  LScale := Scale;
  if LScale < 2 then
    Exit(False);
  if LScale <> FRasterScale then
    Open(LScale);
  if FGlyphs.TryGetValue(ACode, LEntry) then
  begin
    AGlyph := LEntry.Glyph;
    Exit(LEntry.Found);
  end;
  LEntry.Found := False;
  LEntry.Glyph := Default(TXcomDetailGlyph);
  // only a character that the text draws with a picture made from the font of the system
  if Assigned(FRasterizer) and FFont.TryGetChar(ACode, LChar) and (LChar.ImageIndex >= FReport.FirstImage)
    and BodyColumns(LChar, LFirst, LCount) and FRasterizer.HasGlyph(ACode)
    and FRasterizer.Rasterize(ACode, LCoverage) and (LCoverage.Width > 0) and (LCoverage.Height > 0) then
  begin
    LEntry.Glyph := TXcomDetailGlyphBuilder.Build(LCoverage, FReport.Outlined, LScale);
    // Build left the position of the rectangle relative to the coverage: the coverage is centered on the body
    // of the picture and stands on the baseline the pictures were placed with
    Inc(LEntry.Glyph.Left, LScale * LFirst + (LScale * LCount - LCoverage.Width) div 2);
    Inc(LEntry.Glyph.Top, LCoverage.Top - FRasterizer.Baseline + LScale * (FReport.Baseline - FReport.LineTop));
    LEntry.Found := True;
  end;
  FGlyphs.Add(ACode, LEntry);
  AGlyph := LEntry.Glyph;
  Result := LEntry.Found;
end;

end.
