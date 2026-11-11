{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - Screen of OpenXcom (the picture of the     }
{  game, its scaling to the window and the palette of the display)              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Screen;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Options,
  DelphiDoom.XcomEngine.Action;

const
  XCOM_ORIGINAL_WIDTH = 320;
  XCOM_ORIGINAL_HEIGHT = 200;

type
  /// <summary>ScaleType of the options: the size of the game picture as a function of the original and the window</summary>
  TXcomScaleType = (stOriginal, st15x, st2x, stScreenDiv3, stScreenDiv2, stScreen);

  /// <summary>
  ///   The picture where every state draws (the base surface, 8 bits with a palette) and how it goes to the window:
  ///   scaled by the nearest pixel (Zoom::_zoomSurfaceY, the software scaler without filters) with black bands when
  ///   the aspect ratio is kept. The software filters (HQX, xBRZ, Scale2x) are not ported. With Options::useOpenGL
  ///   a device that is an IXcomFilteredDisplay receives the base surface and scales it itself (the OpenGL class of
  ///   the C++); the scaled picture is made all the same, for DisplayPixels. The palette is deferred as in the
  ///   C++: it reaches the display with the next flip
  /// </summary>
  TXcomScreen = class
  strict private
    FOptions: TXcomOptions;
    FDevice: IXcomVideoDevice;
    FFiltered: IXcomFilteredDisplay;
    FSurface: TXcomSurface;
    FDisplay: TBytes;
    FDisplayWidth: Integer;
    FDisplayHeight: Integer;
    FBaseWidth: Integer;
    FBaseHeight: Integer;
    FScaleX: Double;
    FScaleY: Double;
    FTopBlackBand: Integer;
    FBottomBlackBand: Integer;
    FLeftBlackBand: Integer;
    FRightBlackBand: Integer;
    FCursorTopBlackBand: Integer;
    FCursorLeftBlackBand: Integer;
    FDeferredPalette: TXcomColors;
    FScreenshotRequested: Boolean;
    procedure Zoom(ADestWidth, ADestHeight, ALeft, ATop: Integer);
    procedure GiveDisplayFilter;
    procedure TakeDisplayFilter;
  public
    constructor Create(AOptions: TXcomOptions; const ADevice: IXcomVideoDevice);
    destructor Destroy; override;
    /// <summary>Screen::getSurface: the base surface the states blit on</summary>
    function GetSurface: TXcomSurface;
    /// <summary>Screen::handle: the screenshot key; returns true when the key asks for one (see TakeScreenshotRequest)</summary>
    procedure Handle(AAction: TXcomAction);
    /// <summary>True once after a screenshot key was seen; the caller saves the picture with DisplayPixels</summary>
    function TakeScreenshotRequest: Boolean;
    /// <summary>Screen::flip: scales the base surface to the display and shows it</summary>
    procedure Flip;
    /// <summary>Screen::clear</summary>
    procedure Clear;
    /// <summary>Screen::setPalette: the colors go to the base surface and, with the next flip, to the display</summary>
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256);
    function Palette: PXcomColors;
    function Width: Integer;
    function Height: Integer;
    /// <summary>Screen::resetDisplay: the display and the base surface take the sizes of the options</summary>
    procedure ResetDisplay(AResetVideo: Boolean = True);
    function XScale: Double;
    function YScale: Double;
    function CursorTopBlackBand: Integer;
    function CursorLeftBlackBand: Integer;
    /// <summary>Screen::getDX: the shift to center an original size (320 x 200) screen in the base surface</summary>
    function DX: Integer;
    function DY: Integer;
    /// <summary>The last flipped picture: Width x Height indexed pixels of the display (what screenshot saves)</summary>
    function DisplayPixels: TBytes;
    /// <summary>Screen::updateScale: the size of the game picture for a scale type</summary>
    class procedure UpdateScale(AOptions: TXcomOptions; AType: Integer; var AWidth, AHeight: Integer;
      AChange: Boolean); static;
  end;

implementation

constructor TXcomScreen.Create(AOptions: TXcomOptions; const ADevice: IXcomVideoDevice);
begin
  inherited Create;
  FOptions := AOptions;
  FDevice := ADevice;
  Supports(FDevice, IXcomFilteredDisplay, FFiltered);
  FBaseWidth := XCOM_ORIGINAL_WIDTH;
  FBaseHeight := XCOM_ORIGINAL_HEIGHT;
  FScaleX := 1.0;
  FScaleY := 1.0;
  ResetDisplay;
end;

destructor TXcomScreen.Destroy;
begin
  FSurface.Free;
  inherited Destroy;
end;

function TXcomScreen.GetSurface: TXcomSurface;
begin
  Result := FSurface;
end;

procedure TXcomScreen.Handle(AAction: TXcomAction);
begin
  if (AAction.Details^.Kind = ekKeyDown) and (AAction.Details^.Key = FOptions.KeyScreenshot) then
    FScreenshotRequested := True;
end;

function TXcomScreen.TakeScreenshotRequest: Boolean;
begin
  Result := FScreenshotRequested;
  FScreenshotRequested := False;
end;

procedure TXcomScreen.Zoom(ADestWidth, ADestHeight, ALeft, ATop: Integer);
var
  LStepX: TArray<Integer>;
  LStepY: TArray<Integer>;
  LCounter: Integer;
  LX: Integer;
  LY: Integer;
  LSourceRow: Integer;
  LSourceColumn: Integer;
  LSource: TBytes;
  LSourceWidth: Integer;
  LSourceHeight: Integer;
begin
  // Zoom::_zoomSurfaceY: the source index advances by a precomputed step after every destination pixel
  LSource := FSurface.Pixels;
  LSourceWidth := FSurface.Width;
  LSourceHeight := FSurface.Height;
  SetLength(LStepX, ADestWidth);
  SetLength(LStepY, ADestHeight);
  LCounter := 0;
  for LX := 0 to ADestWidth - 1 do
  begin
    Inc(LCounter, LSourceWidth);
    LStepX[LX] := 0;
    while LCounter >= ADestWidth do
    begin
      Dec(LCounter, ADestWidth);
      Inc(LStepX[LX]);
    end;
  end;
  LCounter := 0;
  for LY := 0 to ADestHeight - 1 do
  begin
    Inc(LCounter, LSourceHeight);
    LStepY[LY] := 0;
    while LCounter >= ADestHeight do
    begin
      Dec(LCounter, ADestHeight);
      Inc(LStepY[LY]);
    end;
  end;
  LSourceRow := 0;
  for LY := 0 to ADestHeight - 1 do
  begin
    LSourceColumn := 0;
    for LX := 0 to ADestWidth - 1 do
    begin
      FDisplay[(ATop + LY) * FDisplayWidth + ALeft + LX] := LSource[LSourceRow * LSourceWidth + LSourceColumn];
      Inc(LSourceColumn, LStepX[LX]);
    end;
    Inc(LSourceRow, LStepY[LY]);
  end;
end;

procedure TXcomScreen.GiveDisplayFilter;
var
  LFilter: TXcomDisplayFilter;
begin
  if not Assigned(FFiltered) then
    Exit;
  LFilter.UseOpenGL := FOptions.UseOpenGL;
  LFilter.Shader := FOptions.UseOpenGLShader;
  LFilter.Smoothing := FOptions.GetBool('useOpenGLSmoothing');
  LFilter.VSync := FOptions.GetBool('vSyncForOpenGL');
  FFiltered.SetDisplayFilter(LFilter);
end;

procedure TXcomScreen.TakeDisplayFilter;
var
  LFilter: TXcomDisplayFilter;
begin
  // Screen::resetDisplay: a display that cannot be made with OpenGL is made without it and the option is turned
  // off; a shader that cannot be used is forgotten
  if not (Assigned(FFiltered) and FOptions.UseOpenGL) then
    Exit;
  LFilter := FFiltered.DisplayFilter;
  if not LFilter.UseOpenGL then
    FOptions.UseOpenGL := False
  else if LFilter.Shader = '' then
    FOptions.UseOpenGLShader := '';
end;

procedure TXcomScreen.Flip;
var
  LWidth: Integer;
  LHeight: Integer;
  LBands: TXcomBlackBands;
begin
  LWidth := FDisplayWidth - FLeftBlackBand - FRightBlackBand;
  LHeight := FDisplayHeight - FTopBlackBand - FBottomBlackBand;
  if (LWidth > 0) and (LHeight > 0) then
    Zoom(LWidth, LHeight, FLeftBlackBand, FTopBlackBand);
  if Assigned(FFiltered) and FOptions.UseOpenGL then
  begin
    LBands.Top := FTopBlackBand;
    LBands.Bottom := FBottomBlackBand;
    LBands.Left := FLeftBlackBand;
    LBands.Right := FRightBlackBand;
    if FFiltered.PresentUnscaled(FSurface.Pixels, FSurface.Width, FSurface.Height, FDeferredPalette, FDisplayWidth,
      FDisplayHeight, LBands) then
      Exit;
  end;
  FDevice.Present(FDisplay, FDisplayWidth, FDisplayHeight, FDeferredPalette);
end;

procedure TXcomScreen.Clear;
begin
  FSurface.Clear;
  if Length(FDisplay) > 0 then
    FillChar(FDisplay[0], Length(FDisplay), 0);
end;

procedure TXcomScreen.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
var
  LColors: TArray<TXcomColor>;
begin
  if ACount <= 0 then
    Exit;
  Move(AColors^, FDeferredPalette[AFirst], ACount * SizeOf(TXcomColor));
  SetLength(LColors, ACount);
  Move(AColors^, LColors[0], ACount * SizeOf(TXcomColor));
  FSurface.SetColors(LColors, AFirst);
end;

function TXcomScreen.Palette: PXcomColors;
begin
  Result := @FDeferredPalette;
end;

function TXcomScreen.Width: Integer;
begin
  Result := FDisplayWidth;
end;

function TXcomScreen.Height: Integer;
begin
  Result := FDisplayHeight;
end;

procedure TXcomScreen.ResetDisplay(AResetVideo: Boolean);
var
  LWidth: Integer;
  LHeight: Integer;
  LPixelRatioY: Double;
  LCursorInBlackBands: Boolean;
  LTarget: Integer;
  LStyle: IXcomWindowStyle;
begin
  LWidth := FOptions.DisplayWidth;
  LHeight := FOptions.DisplayHeight;
  FBaseWidth := FOptions.BaseXResolution;
  FBaseHeight := FOptions.BaseYResolution;
  if (not Assigned(FSurface)) or (FSurface.Width <> FBaseWidth) or (FSurface.Height <> FBaseHeight) then
  begin
    FSurface.Free;
    FSurface := TXcomSurface.Create(FBaseWidth, FBaseHeight);
    FSurface.SetColors(FDeferredPalette);
  end;
  if AResetVideo or (Length(FDisplay) = 0) then
  begin
    if Supports(FDevice, IXcomWindowStyle, LStyle) then
      LStyle.SetWindowStyle(FOptions.Borderless, FOptions.AllowResize);
    GiveDisplayFilter;
    FDevice.SetMode(LWidth, LHeight, FOptions.Fullscreen);
    TakeDisplayFilter;
  end;
  FDisplayWidth := LWidth;
  FDisplayHeight := LHeight;
  SetLength(FDisplay, LWidth * LHeight);
  FillChar(FDisplay[0], Length(FDisplay), 0);
  FOptions.DisplayWidth := FDisplayWidth;
  FOptions.DisplayHeight := FDisplayHeight;
  FScaleX := FDisplayWidth / FBaseWidth;
  FScaleY := FDisplayHeight / FBaseHeight;
  LPixelRatioY := 1.0;
  if FOptions.NonSquarePixelRatio and not FOptions.AllowResize then
    LPixelRatioY := 1.2;
  if not FOptions.KeepAspectRatio then
    LCursorInBlackBands := False
  else if FOptions.Fullscreen then
    LCursorInBlackBands := FOptions.CursorInBlackBandsInFullscreen
  else if not FOptions.Borderless then
    LCursorInBlackBands := FOptions.CursorInBlackBandsInWindow
  else
    LCursorInBlackBands := FOptions.CursorInBlackBandsInBorderlessWindow;
  FTopBlackBand := 0;
  FBottomBlackBand := 0;
  FLeftBlackBand := 0;
  FRightBlackBand := 0;
  FCursorTopBlackBand := 0;
  FCursorLeftBlackBand := 0;
  if (FScaleX > FScaleY) and FOptions.KeepAspectRatio then
  begin
    LTarget := Floor(FScaleY * FBaseWidth);
    FLeftBlackBand := Max(0, (FDisplayWidth - LTarget) div 2);
    FRightBlackBand := FDisplayWidth - LTarget - FLeftBlackBand;
    if LCursorInBlackBands then
    begin
      FScaleX := FScaleY;
      FCursorLeftBlackBand := FLeftBlackBand;
    end;
  end
  else if (FScaleY > FScaleX) and FOptions.KeepAspectRatio then
  begin
    LTarget := Floor(FScaleX * FBaseHeight * LPixelRatioY);
    FTopBlackBand := Max(0, (FDisplayHeight - LTarget) div 2);
    FBottomBlackBand := Max(0, FDisplayHeight - LTarget - FTopBlackBand);
    if LCursorInBlackBands then
    begin
      FScaleY := FScaleX;
      FCursorTopBlackBand := FTopBlackBand;
    end;
  end;
end;

function TXcomScreen.XScale: Double;
begin
  Result := FScaleX;
end;

function TXcomScreen.YScale: Double;
begin
  Result := FScaleY;
end;

function TXcomScreen.CursorTopBlackBand: Integer;
begin
  Result := FCursorTopBlackBand;
end;

function TXcomScreen.CursorLeftBlackBand: Integer;
begin
  Result := FCursorLeftBlackBand;
end;

function TXcomScreen.DX: Integer;
begin
  Result := (FBaseWidth - XCOM_ORIGINAL_WIDTH) div 2;
end;

function TXcomScreen.DY: Integer;
begin
  Result := (FBaseHeight - XCOM_ORIGINAL_HEIGHT) div 2;
end;

function TXcomScreen.DisplayPixels: TBytes;
begin
  Result := FDisplay;
end;

class procedure TXcomScreen.UpdateScale(AOptions: TXcomOptions; AType: Integer; var AWidth, AHeight: Integer;
  AChange: Boolean);
var
  LPixelRatioY: Double;
begin
  LPixelRatioY := 1.0;
  if AOptions.NonSquarePixelRatio then
    LPixelRatioY := 1.2;
  case TXcomScaleType(AType) of
    st15x:
      begin
        AWidth := Trunc(XCOM_ORIGINAL_WIDTH * 1.5);
        AHeight := Trunc(XCOM_ORIGINAL_HEIGHT * 1.5);
      end;
    st2x:
      begin
        AWidth := XCOM_ORIGINAL_WIDTH * 2;
        AHeight := XCOM_ORIGINAL_HEIGHT * 2;
      end;
    stScreenDiv3:
      begin
        AWidth := Trunc(AOptions.DisplayWidth / 3.0);
        AHeight := Trunc(AOptions.DisplayHeight / LPixelRatioY / 3.0);
      end;
    stScreenDiv2:
      begin
        AWidth := Trunc(AOptions.DisplayWidth / 2.0);
        AHeight := Trunc(AOptions.DisplayHeight / LPixelRatioY / 2.0);
      end;
    stScreen:
      begin
        AWidth := AOptions.DisplayWidth;
        AHeight := Trunc(AOptions.DisplayHeight / LPixelRatioY);
      end;
  else
    AWidth := XCOM_ORIGINAL_WIDTH;
    AHeight := XCOM_ORIGINAL_HEIGHT;
  end;
  AWidth := Max(AWidth, XCOM_ORIGINAL_WIDTH);
  AHeight := Max(AHeight, XCOM_ORIGINAL_HEIGHT);
  if AChange and ((AOptions.BaseXResolution <> AWidth) or (AOptions.BaseYResolution <> AHeight)) then
  begin
    AOptions.BaseXResolution := AWidth;
    AOptions.BaseYResolution := AHeight;
  end;
end;

end.
