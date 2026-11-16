{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the fonts of the system chosen in the      }
{  options, laid over the fonts of the game when they fit                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.RasterFontOverlay;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomSurface.Font, DelphiDoom.XcomSurface.Glyph.Types,
  DelphiDoom.XcomSurface.GlyphRasterizer.Intf, DelphiDoom.XcomSurface.FontOverlay.Intf,
  DelphiDoom.XcomSurface.FontDetail.Intf, DelphiDoom.XcomEngine.TrueColor.Intf,
  DelphiDoom.XcomEngine.FontReloader.Intf;

type
  /// <summary>
  ///   IXcomFontOverlay for the fonts listed in the options: opens the font of the system, checks at the start
  ///   that it fits the cells of the original font and adds its characters. A font that is not there, or is too
  ///   tall or too wide (and not allowed to shrink until it fits), leaves the original font as it is, with a
  ///   warning in the log; so does a single character that the font does not have. The rasterizer of a font lives only during its Apply (the loading thread)
  /// </summary>
  TXcomRasterFontOverlay = class(TInterfacedObject, IXcomFontOverlay, IXcomFontNotices)
  strict private
    FSettings: TArray<TXcomFontOverlaySettings>;
    FFactory: IXcomGlyphRasterizerFactory;
    FLog: IXcomLog;
    FDisplay: IXcomDetailLayers;
    FLayers: IXcomInkLayers;
    FNotices: TArray<string>;
    procedure Say(const ALevel, AText: string);
    procedure Tell(const AText: string);
    class function Words(const AFontId: string): string; static;
    class function Quoted(const AFace: TXcomFontFace): string; static;
    class function Describe(const AFace: TXcomFontFace): string; static;
  public
    /// <param name="ALog">nil for no log</param>
    /// <param name="ADisplay">
    ///   With ALayers: the fonts also get their characters at the resolution of the display (IXcomFontDetail),
    ///   for a screen that composes in true color at a whole scale. nil, the default: only the pictures
    /// </param>
    constructor Create(const ASettings: TArray<TXcomFontOverlaySettings>; const AFactory: IXcomGlyphRasterizerFactory;
      const ALog: IXcomLog; const ADisplay: IXcomDetailLayers = nil; const ALayers: IXcomInkLayers = nil);
    procedure Apply(const AFontId: string; AFont: TXcomFont);
    /// <summary>What the player is told (IXcomFontNotices): the fonts that could not be used as chosen</summary>
    function Notices: TArray<string>;
  end;

implementation

uses
  DelphiDoom.XcomSurface.FontOverlayBuilder, DelphiDoom.XcomEngine.DetailFont;

const
  SLevelWarning = 'WARN';
  SLevelInfo = 'INFO';
  SNotFound = 'font %s: %s not used (%s): the original font stays';
  STooTall = 'font %s: %s is %d pixels tall and the limit is %d: the original font stays';
  STooWide = 'font %s: %s has letters %d pixels wide and the limit is %d: the original font stays';
  SNoGlyphs = 'font %s: %s has none of the characters of the font: the original font stays';
  SApplied = 'font %s: %s, %d characters (%d x %d); from the original font: %d missing, %d too wide; %d cut';
  SPartial = 'font %s: %d characters are not in %s or are too wide and stay the original ones';
  SShrunk = 'font %s: too large for the cells at %d pixels, reduced to %d';
  SNoticeNotFound = 'The font %s is not installed, so the %s stays the original one.';
  SNoticeTooLarge = 'The font %s at size %d does not fit the %s. Try a smaller size or turn on shrink to fit. ' +
    'The original font stays.';
  SNoticeShrunk = 'The %s was made smaller to fit: size %d instead of %d.';
  SNoticeNoGlyphs = 'The font %s has none of the characters of the %s, so it stays the original one.';

constructor TXcomRasterFontOverlay.Create(const ASettings: TArray<TXcomFontOverlaySettings>;
  const AFactory: IXcomGlyphRasterizerFactory; const ALog: IXcomLog; const ADisplay: IXcomDetailLayers;
  const ALayers: IXcomInkLayers);
begin
  inherited Create;
  if not Assigned(AFactory) then
    raise EArgumentNilException.Create('AFactory');
  FSettings := ASettings;
  FFactory := AFactory;
  FLog := ALog;
  FDisplay := ADisplay;
  FLayers := ALayers;
end;

procedure TXcomRasterFontOverlay.Say(const ALevel, AText: string);
begin
  if Assigned(FLog) then
    FLog.Write(ALevel, AText);
end;

procedure TXcomRasterFontOverlay.Tell(const AText: string);
begin
  FNotices := FNotices + [AText];
end;

class function TXcomRasterFontOverlay.Words(const AFontId: string): string;
begin
  if SameText(AFontId, 'FONT_BIG') then
    Result := 'big font'
  else if SameText(AFontId, 'FONT_SMALL') then
    Result := 'small font'
  else if SameText(AFontId, 'FONT_GEO_BIG') then
    Result := 'geoscape big font'
  else if SameText(AFontId, 'FONT_GEO_SMALL') then
    Result := 'geoscape small font'
  else
    Result := AFontId;
end;

class function TXcomRasterFontOverlay.Quoted(const AFace: TXcomFontFace): string;
begin
  Result := AFace.Name;
  if Result = '' then
    Result := ExtractFileName(AFace.FileName);
  Result := '"' + Result + '"';
end;

function TXcomRasterFontOverlay.Notices: TArray<string>;
begin
  Result := FNotices;
end;

class function TXcomRasterFontOverlay.Describe(const AFace: TXcomFontFace): string;
begin
  Result := AFace.Name;
  if Result = '' then
    Result := AFace.FileName;
  Result := Format('"%s" %d', [Result, AFace.Size]);
  if AFace.Bold then
    Result := Result + ' bold';
end;

procedure TXcomRasterFontOverlay.Apply(const AFontId: string; AFont: TXcomFont);
var
  LSettings: TXcomFontOverlaySettings;
  LFound: Boolean;
  LCandidate: TXcomFontOverlaySettings;
  LRasterizer: IXcomGlyphRasterizer;
  LReason: string;
  LBuilder: TXcomFontOverlayBuilder;
  LReport: TXcomFontOverlayReport;
  LName: string;
  LAsked: Integer;
  LApplied: Boolean;
  LRetry: Boolean;
begin
  LFound := False;
  // the last entry of a font wins, as a key written twice
  for LCandidate in FSettings do
    if SameText(LCandidate.FontId, AFontId) then
    begin
      LSettings := LCandidate;
      LFound := True;
    end;
  if not LFound then
    Exit;
  LAsked := LSettings.Face.Size;
  LBuilder := TXcomFontOverlayBuilder.Create;
  try
    repeat
      LName := Describe(LSettings.Face);
      LRasterizer := FFactory.CreateRasterizer(LSettings.Face, 1, LReason);
      if not Assigned(LRasterizer) then
      begin
        Say(SLevelWarning, Format(SNotFound, [AFontId, LName, LReason]));
        Tell(Format(SNoticeNotFound, [Quoted(LSettings.Face), Words(AFontId)]));
        Exit;
      end;
      LApplied := LBuilder.Apply(AFont, LRasterizer, LSettings, LReport);
      // the option of the font: one pixel smaller until it fits the cells, instead of the refusal
      LRetry := (not LApplied) and LSettings.Shrink and (LReport.Refusal in [frTooTall, frTooWide])
        and (LSettings.Face.Size > XCOM_FONT_SMALLEST_SIZE);
      if LRetry then
        Dec(LSettings.Face.Size);
    until not LRetry;
    if LApplied then
    begin
      if LSettings.Face.Size <> LAsked then
      begin
        Say(SLevelInfo, Format(SShrunk, [AFontId, LAsked, LSettings.Face.Size]));
        Tell(Format(SNoticeShrunk, [Words(AFontId), LSettings.Face.Size, LAsked]));
      end;
      Say(SLevelInfo, Format(SApplied, [AFontId, LName, LReport.Replaced, LReport.Width, LReport.Height,
        LReport.Missing, LReport.TooWide, LReport.Clipped]));
      if LReport.Missing + LReport.TooWide > 0 then
        Say(SLevelWarning, Format(SPartial, [AFontId, LReport.Missing + LReport.TooWide, LName]));
      // the same font draws the text again at the resolution of the display, when the screen has one
      if Assigned(FDisplay) and Assigned(FLayers) then
        AFont.Detail := TXcomDetailFont.Create(AFont, LSettings.Face, LReport, FFactory, FDisplay, FLayers, FLog);
    end
    else
      case LReport.Refusal of
        frTooTall:
          begin
            Say(SLevelWarning, Format(STooTall, [AFontId, LName, LReport.Height, LReport.HeightLimit]));
            Tell(Format(SNoticeTooLarge, [Quoted(LSettings.Face), LAsked, Words(AFontId)]));
          end;
        frTooWide:
          begin
            Say(SLevelWarning, Format(STooWide, [AFontId, LName, LReport.Width, LReport.WidthLimit]));
            Tell(Format(SNoticeTooLarge, [Quoted(LSettings.Face), LAsked, Words(AFontId)]));
          end;
      else
        begin
          Say(SLevelWarning, Format(SNoGlyphs, [AFontId, LName]));
          Tell(Format(SNoticeNoGlyphs, [Quoted(LSettings.Face), Words(AFontId)]));
        end;
      end;
  finally
    LBuilder.Free;
  end;
end;

end.
