{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - Text of OpenXcom                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.Text;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.PaletteShift, DelphiDoom.XcomUi.TextInk, DelphiDoom.XcomSurface.Ink.Types,
  DelphiDoom.XcomSurface.FontDetail.Intf;

type
  /// <summary>
  ///   A piece of text drawn with a font: word wrap, alignment, two colors, the small font after a #2 token,
  ///   scrolling with the mouse wheel. The text is measured and broken into lines when it is set
  /// </summary>
  TXcomText = class(TXcomInteractiveSurface)
  strict private
    FBig: TXcomFont;
    FSmall: TXcomFont;
    FFont: TXcomFont;
    FFontOriginal: TXcomFont;
    FLanguage: TXcomLanguage;
    FText: string;
    FProcessed: TList<Cardinal>;
    FWrap: Boolean;
    FInvert: Boolean;
    FContrast: Boolean;
    FIndent: Boolean;
    FScroll: Boolean;
    FAlign: TXcomTextHAlign;
    FVerticalAlign: TXcomTextVAlign;
    FColor: Byte;
    FColor2: Byte;
    FScrollY: Integer;
    FLineWidth: TList<Integer>;
    FLineHeight: TList<Integer>;
    FDebugUi: Boolean;
    FInk: TXcomTextInk;
    FInkScale: Integer;
    FInkBuffer: TXcomInkBuffer;
    FInkBufferValid: Boolean;
    procedure PrepareInk;
    procedure ProcessText;
    function LineX(ALine: Integer): Integer;
    class function IsLineBreak(ACode: Cardinal): Boolean; static; inline;
    class function IsSpace(ACode: Cardinal): Boolean; static; inline;
    class function IsSeparator(ACode: Cardinal): Boolean; static; inline;
  protected
    procedure MousePress(AAction: TXcomAction); override;
  public
    constructor Create(AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0);
    destructor Destroy; override;
    procedure SetBig;
    procedure SetSmall;
    function GetFont: TXcomFont;
    procedure InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage); override;
    /// <summary>
    ///   Text::setText: a big text that does not fit in the surface (and does not end with a point) falls back to
    ///   the small font
    /// </summary>
    procedure SetText(const AText: string);
    function GetText: string;
    procedure SetWordWrap(AWrap: Boolean; AIndent: Boolean = False);
    procedure SetInvert(AInvert: Boolean);
    procedure SetHighContrast(AContrast: Boolean); override;
    procedure SetAlign(AAlign: TXcomTextHAlign);
    function GetAlign: TXcomTextHAlign;
    procedure SetVerticalAlign(AAlign: TXcomTextVAlign);
    function GetVerticalAlign: TXcomTextVAlign;
    procedure SetColor(AColor: Byte); override;
    function GetColor: Byte; override;
    procedure SetSecondaryColor(AColor: Byte); override;
    function GetSecondaryColor: Byte;
    /// <summary>Text::getNumLines: the number of lines when wrapping, else 1</summary>
    function GetNumLines: Integer;
    /// <summary>Text::getTextHeight: the height of a line, or of all of them (-1)</summary>
    function GetTextHeight(ALine: Integer = -1): Integer;
    /// <summary>Text::getTextWidth: the width of a line, or of the widest one (-1)</summary>
    function GetTextWidth(ALine: Integer = -1): Integer;
    procedure SetScrollable(AScroll: Boolean);
    procedure Draw; override;
    procedure RedrawText; override;
    /// <summary>
    ///   Surface::blit. On the picture of a screen that composes in true color, with a font that has its characters
    ///   at the resolution of the display (issue 184), the text also leaves them to the screen: they are shown
    ///   in place of the ones of the picture, on the same cells
    /// </summary>
    procedure Blit(ATarget: TXcomSurface); override;
    /// <summary>
    ///   The characters of the last Draw for the resolution of the display, for a widget that draws this text on
    ///   itself; nil when the fonts only have their pictures
    /// </summary>
    function Ink: TXcomTextInk;
    /// <summary>True when the scale of the display is not the one the text was drawn for: it must be drawn again</summary>
    function IsInkStale: Boolean;
    /// <summary>The scale the fonts of the text have their characters at now (0: only the pictures)</summary>
    function DetailScale: Integer;
    /// <summary>
    ///   Draws the text on a surface of indexes that is AScale times finer than the game, its corner at (AX, AY):
    ///   false, and nothing drawn, when the text has no characters at that scale
    /// </summary>
    function DrawDetail(ATarget: TXcomSurface; AX, AY, AScale: Integer): Boolean;
    /// <summary>Options::debugUi: a frame is drawn around the text</summary>
    property DebugUi: Boolean read FDebugUi write FDebugUi;
  end;

implementation

constructor TXcomText.Create(AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FProcessed := TList<Cardinal>.Create;
  FLineWidth := TList<Integer>.Create;
  FLineHeight := TList<Integer>.Create;
end;

destructor TXcomText.Destroy;
begin
  FInk.Free;
  FLineHeight.Free;
  FLineWidth.Free;
  FProcessed.Free;
  inherited Destroy;
end;

class function TXcomText.IsLineBreak(ACode: Cardinal): Boolean;
begin
  Result := (ACode = 10) or (ACode = XCOM_TOKEN_NEWLINE_SMALL);
end;

class function TXcomText.IsSpace(ACode: Cardinal): Boolean;
begin
  Result := (ACode = 32) or (ACode = XCOM_TOKEN_NBSP);
end;

class function TXcomText.IsSeparator(ACode: Cardinal): Boolean;
begin
  Result := (ACode = Ord('-')) or (ACode = Ord('/'));
end;

procedure TXcomText.SetBig;
begin
  FFont := FBig;
  FFontOriginal := FBig;
  ProcessText;
end;

procedure TXcomText.SetSmall;
begin
  FFont := FSmall;
  FFontOriginal := FSmall;
  ProcessText;
end;

function TXcomText.GetFont: TXcomFont;
begin
  Result := FFont;
end;

procedure TXcomText.InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage);
begin
  FBig := ABig;
  FSmall := ASmall;
  FLanguage := ALanguage;
  SetSmall;
end;

procedure TXcomText.SetText(const AText: string);
begin
  FText := AText;
  FFont := FFontOriginal;
  ProcessText;
  if (FText <> '') and (FFont = FBig) and
    ((GetTextWidth > Width) or (GetTextHeight > Height)) and (FText[Length(FText)] <> '.') then
  begin
    // Issue 184: a big font that got the characters of a font of the system is a little wider than the
    // pictures of the game. A text that fitted with those is drawn with them, before going to the small font
    // (the six time buttons of the geoscape: their small font has no lower case letters)
    if Assigned(FBig.Original) then
    begin
      FFont := FBig.Original;
      ProcessText;
      if (GetTextWidth <= Width) and (GetTextHeight <= Height) then
        Exit;
    end;
    FFont := FSmall;
    ProcessText;
  end;
end;

function TXcomText.GetText: string;
begin
  Result := FText;
end;

procedure TXcomText.SetWordWrap(AWrap, AIndent: Boolean);
begin
  if (AWrap <> FWrap) or (AIndent <> FIndent) then
  begin
    FWrap := AWrap;
    FIndent := AIndent;
    ProcessText;
  end;
end;

procedure TXcomText.SetInvert(AInvert: Boolean);
begin
  FInvert := AInvert;
  Redraw := True;
end;

procedure TXcomText.SetHighContrast(AContrast: Boolean);
begin
  FContrast := AContrast;
  Redraw := True;
end;

procedure TXcomText.SetAlign(AAlign: TXcomTextHAlign);
begin
  FAlign := AAlign;
  Redraw := True;
end;

function TXcomText.GetAlign: TXcomTextHAlign;
begin
  Result := FAlign;
end;

procedure TXcomText.SetVerticalAlign(AAlign: TXcomTextVAlign);
begin
  FVerticalAlign := AAlign;
  Redraw := True;
end;

function TXcomText.GetVerticalAlign: TXcomTextVAlign;
begin
  Result := FVerticalAlign;
end;

procedure TXcomText.SetColor(AColor: Byte);
begin
  FColor := AColor;
  FColor2 := AColor;
  Redraw := True;
end;

function TXcomText.GetColor: Byte;
begin
  Result := FColor;
end;

procedure TXcomText.SetSecondaryColor(AColor: Byte);
begin
  FColor2 := AColor;
  Redraw := True;
end;

function TXcomText.GetSecondaryColor: Byte;
begin
  Result := FColor2;
end;

function TXcomText.GetNumLines: Integer;
begin
  if FWrap then
    Result := FLineHeight.Count
  else
    Result := 1;
end;

function TXcomText.GetTextHeight(ALine: Integer): Integer;
var
  LValue: Integer;
begin
  if ALine = -1 then
  begin
    Result := 0;
    for LValue in FLineHeight do
      Inc(Result, LValue);
  end
  else
    Result := FLineHeight[ALine];
end;

function TXcomText.GetTextWidth(ALine: Integer): Integer;
var
  LValue: Integer;
begin
  if ALine = -1 then
  begin
    Result := 0;
    for LValue in FLineWidth do
      if LValue > Result then
        Result := LValue;
  end
  else
    Result := FLineWidth[ALine];
end;

procedure TXcomText.ProcessText;
var
  LCodes: TArray<Cardinal>;
  LIndex: Integer;
  LWidth: Integer;
  LWord: Integer;
  LSpace: Integer;
  LIndentation: Integer;
  LStart: Boolean;
  LFont: TXcomFont;
  LCharWidth: Integer;
  LIndentLocation: Integer;
  LCount: Integer;
  LCode: Cardinal;
begin
  if (FFont = nil) or (FLanguage = nil) then
    Exit;
  LCodes := TXcomFont.CodePoints(FText);
  FProcessed.Clear;
  FProcessed.AddRange(LCodes);
  FLineWidth.Clear;
  FLineHeight.Clear;
  FScrollY := 0;
  LWidth := 0;
  LWord := 0;
  LSpace := 0;
  LIndentation := 0;
  LStart := True;
  LFont := FFont;
  LIndex := 0;
  // the string grows while the loop runs (the line breaks are inserted into it), so the size is read every time
  while LIndex <= FProcessed.Count do
  begin
    if LIndex = FProcessed.Count then
      LCode := 0
    else
      LCode := FProcessed[LIndex];
    if (LIndex = FProcessed.Count) or IsLineBreak(LCode) then
    begin
      FLineWidth.Add(LWidth);
      FLineHeight.Add(LFont.GetCharSize(10).H);
      LWidth := 0;
      LWord := 0;
      LStart := True;
      if LIndex = FProcessed.Count then
        Break
      else if LCode = XCOM_TOKEN_NEWLINE_SMALL then
        LFont := FSmall;
    end
    else if IsSpace(LCode) or IsSeparator(LCode) then
    begin
      if LIndex = LIndentation then
        Inc(LIndentation);
      LSpace := LIndex;
      Inc(LWidth, LFont.GetCharSize(LCode).W);
      LWord := 0;
      LStart := False;
    end
    else if LCode <> XCOM_TOKEN_COLOR_FLIP then
    begin
      LCharWidth := LFont.GetCharSize(LCode).W;
      Inc(LWidth, LCharWidth);
      Inc(LWord, LCharWidth);
      if FWrap and (LWidth >= Width) and ((not LStart) or (FLanguage.TextWrapping = twLetters)) then
      begin
        LIndentLocation := LIndex;
        if (FLanguage.TextWrapping = twWords) or IsSpace(LCode) then
        begin
          Dec(LWidth, LWord);
          LIndentLocation := LSpace;
          if IsSpace(FProcessed[LSpace]) then
          begin
            Dec(LWidth, LFont.GetCharSize(FProcessed[LSpace]).W);
            FProcessed[LSpace] := 10;
          end
          else
          begin
            FProcessed.Insert(LSpace + 1, 10);
            Inc(LIndentLocation);
          end;
        end
        else if FLanguage.TextWrapping = twLetters then
        begin
          FProcessed.Insert(LIndex, 10);
          Dec(LWidth, LCharWidth);
        end;
        if LIndentation > 0 then
        begin
          for LCount := 1 to LIndentation do
            FProcessed.Insert(LIndentLocation + 1, 9);
          Inc(LIndentLocation, LIndentation);
        end;
        if FIndent then
        begin
          FProcessed.Insert(LIndentLocation + 1, 9);
          Inc(LWidth, LFont.GetCharSize(9).W);
        end;
        FLineWidth.Add(LWidth);
        FLineHeight.Add(LFont.GetCharSize(10).H);
        if FLanguage.TextWrapping = twWords then
          LWidth := LWord
        else if FLanguage.TextWrapping = twLetters then
          LWidth := 0;
        LStart := True;
      end;
    end;
    Inc(LIndex);
  end;
  Redraw := True;
end;

function TXcomText.LineX(ALine: Integer): Integer;
begin
  Result := 0;
  case FLanguage.TextDirection of
    tdLeftToRight:
      case FAlign of
        haLeft:
          ;
        haCenter:
          Result := Ceil((Width + FFont.Spacing - FLineWidth[ALine]) / 2.0);
        haRight:
          Result := Width - 1 - FLineWidth[ALine];
      end;
    tdRightToLeft:
      case FAlign of
        haLeft:
          Result := Width - 1;
        haCenter:
          Result := Width - Ceil((Width + FFont.Spacing - FLineWidth[ALine]) / 2.0);
        haRight:
          Result := FLineWidth[ALine];
      end;
  end;
end;

procedure TXcomText.Draw;
var
  LX: Integer;
  LY: Integer;
  LLine: Integer;
  LHeight: Integer;
  LFont: TXcomFont;
  LColor: Integer;
  LMultiplier: Integer;
  LDirection: Integer;
  LMiddle: Integer;
  LCode: Cardinal;
  LGlyph: TXcomSurface;
begin
  inherited Draw;
  PrepareInk;
  if (FText = '') or (FFont = nil) then
    Exit;
  if FDebugUi then
  begin
    DrawRect(0, 0, Width, Height, 5);
    DrawRect(1, 1, Width - 2, Height - 2, 0);
  end;
  LLine := 0;
  LFont := FFont;
  LColor := FColor;
  LHeight := GetTextHeight;
  if FScroll then
    LY := FScrollY
  else
    case FVerticalAlign of
      vaTop:
        LY := 0;
      vaMiddle:
        LY := Ceil((Height - LHeight) / 2.0);
      vaBottom:
        LY := Height - LHeight;
    else
      LY := 0;
    end;
  LX := LineX(LLine);
  LMultiplier := 1;
  if FContrast then
    LMultiplier := 3;
  LDirection := 1;
  if FLanguage.TextDirection = tdRightToLeft then
    LDirection := -1;
  LMiddle := 0;
  if FInvert then
    LMiddle := 3;
  for LCode in FProcessed do
  begin
    if IsSpace(LCode) or (LCode = 9) then
      Inc(LX, LDirection * LFont.GetCharSize(LCode).W)
    else if IsLineBreak(LCode) then
    begin
      Inc(LLine);
      Inc(LY, LFont.GetCharSize(LCode).H);
      LX := LineX(LLine);
      if LCode = XCOM_TOKEN_NEWLINE_SMALL then
        LFont := FSmall;
    end
    else if LCode = XCOM_TOKEN_COLOR_FLIP then
    begin
      if LColor = FColor then
        LColor := FColor2
      else
        LColor := FColor;
    end
    else
    begin
      if LDirection < 0 then
        Inc(LX, LDirection * LFont.GetCharSize(LCode).W);
      LGlyph := LFont.GetChar(LCode);
      LGlyph.X := LX;
      LGlyph.Y := LY;
      TXcomPaletteShift.Draw(Self, LGlyph, LColor, LMultiplier, LMiddle);
      if Assigned(FInk) then
        FInk.Add(LFont, LCode, LX, LY, LColor, LMultiplier, LMiddle);
      if LDirection > 0 then
        Inc(LX, LDirection * LFont.GetCharSize(LCode).W);
    end;
  end;
end;

procedure TXcomText.RedrawText;
begin
  Draw;
end;

procedure TXcomText.PrepareInk;
var
  LDetail: IXcomFontDetail;
begin
  // nothing new unless a font of the text has its characters at the resolution of the display
  FreeAndNil(FInk);
  FInkBufferValid := False;
  FInkBuffer := Default(TXcomInkBuffer);
  FInkScale := 0;
  LDetail := TXcomTextInk.DetailOf(FFont, FSmall);
  if Assigned(LDetail) then
  begin
    FInk := TXcomTextInk.Create(LDetail);
    FInkScale := FInk.Scale;
  end;
end;

function TXcomText.Ink: TXcomTextInk;
begin
  Result := FInk;
end;

function TXcomText.IsInkStale: Boolean;
begin
  Result := DetailScale <> FInkScale;
end;

function TXcomText.DetailScale: Integer;
begin
  Result := TXcomTextInk.ScaleOf(FFont, FSmall);
end;

procedure TXcomText.Blit(ATarget: TXcomSurface);
begin
  if Visible and not Hidden then
  begin
    // the window changed size after the text was drawn
    if IsInkStale then
      Redraw := True;
    if Redraw then
      Draw;
    // the text of the picture is drawn as always: it tells the screen where the text is still seen. On another
    // surface (a button, a list) BeginInk says no, and the owner of that surface leaves the ink
    if Assigned(FInk) and (FInk.Count > 0) and (Crop.W = 0) and (Crop.H = 0)
      and FInk.Layers.BeginInk(ATarget, X, Y, Width, Height) then
    begin
      inherited Blit(ATarget);
      if not FInkBufferValid then
      begin
        FInkBuffer := TXcomInkBuffer.Make(Width, Height, FInk.Scale);
        FInk.PaintTo(FInkBuffer, 0, 0, Width, Height);
        FInkBufferValid := True;
      end;
      FInk.Layers.EndInk(ATarget, FInkBuffer, nil);
      Exit;
    end;
  end;
  inherited Blit(ATarget);
end;

function TXcomText.DrawDetail(ATarget: TXcomSurface; AX, AY, AScale: Integer): Boolean;
begin
  if IsInkStale then
    Redraw := True;
  if Redraw then
    Draw;
  Result := Assigned(FInk) and (FInk.Scale = AScale) and Visible and not Hidden;
  if Result then
    FInk.DrawTo(ATarget, AX, AY);
end;

procedure TXcomText.SetScrollable(AScroll: Boolean);
begin
  FScroll := AScroll;
end;

procedure TXcomText.MousePress(AAction: TXcomAction);
var
  LScrollArea: Integer;
  LScrollAmount: Integer;
begin
  inherited MousePress(AAction);
  if FScroll and ((AAction.Details^.Button = XCOM_BUTTON_WHEELUP) or (AAction.Details^.Button = XCOM_BUTTON_WHEELDOWN)) then
  begin
    LScrollArea := Height - GetTextHeight;
    if LScrollArea < 0 then
    begin
      LScrollAmount := FFont.Height + FFont.Spacing;
      if AAction.Details^.Button = XCOM_BUTTON_WHEELDOWN then
        LScrollAmount := -LScrollAmount;
      FScrollY := EnsureRange(FScrollY + LScrollAmount, LScrollArea, 0);
      Redraw := True;
    end;
  end;
end;

end.
