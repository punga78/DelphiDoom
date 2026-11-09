{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - an 8 bit indexed surface (Surface of      }
{  OpenXcom without SDL)                                                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.Surface;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Image,
  DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Sdl;

type
  /// <summary>
  ///   A picture of 8 bits per pixel with a palette of 256 colors, a position, a crop rectangle and the color key 0
  ///   (index 0 is transparent): the Surface of OpenXcom. Pixels are Width x Height bytes (no padding). The
  ///   operations that OpenXcom does with SDL (fill, blit) follow SDL 1.2: see TXcomSdl. Drawing of lines, circles
  ///   and polygons (SDL_gfx) is not in this class. A surface owns its pixels and is freed by its owner
  /// </summary>
  TXcomSurface = class
  strict private
    FImage: TXcomImage;
    FX: Integer;
    FY: Integer;
    FCrop: TXcomRect;
    FVisible: Boolean;
    FHidden: Boolean;
    FRedraw: Boolean;
    FTftdMode: Boolean;
    procedure Resize(AWidth, AHeight: Integer);
  public
    /// <summary>A blank surface: all pixels 0, a palette of 256 black colors, visible, at (AX, AY)</summary>
    constructor Create(AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0);
    /// <summary>
    ///   The copy constructor of Surface: a deep copy with the same position, crop and flags. As in the C++ only
    ///   the first 255 colors of the palette are copied: the last one stays black
    /// </summary>
    function Clone: TXcomSurface;
    function Width: Integer;
    function Height: Integer;
    /// <summary>The pixels in rows from the top, Width bytes each</summary>
    function Pixels: TBytes;
    function PixelPointer(AX, AY: Integer): PByte;
    property X: Integer read FX write FX;
    property Y: Integer read FY write FY;
    property Visible: Boolean read FVisible write FVisible;
    property Hidden: Boolean read FHidden write FHidden;
    /// <summary>True after a change of size: the next Blit first clears the surface (Surface::draw)</summary>
    property Redraw: Boolean read FRedraw write FRedraw;
    property TftdMode: Boolean read FTftdMode write FTftdMode;
    /// <summary>The crop rectangle: size 0 x 0 means no crop</summary>
    property Crop: TXcomRect read FCrop write FCrop;
    procedure ResetCrop;
    function Palette: TXcomPalette;
    /// <summary>
    ///   SDL_SetColors: replaces AColors.Length colors from AFirstColor; the colors that fall outside the 256
    ///   of the palette are ignored
    /// </summary>
    procedure SetColors(const AColors: array of TXcomColor; AFirstColor: Integer = 0);
    /// <summary>The pixel, or 0 for a position outside the surface</summary>
    function GetPixel(AX, AY: Integer): Byte;
    /// <summary>Changes a pixel; a position outside the surface is ignored</summary>
    procedure SetPixel(AX, AY: Integer; AValue: Byte);
    procedure SetPixelIterative(var AX, AY: Integer; AValue: Byte);
    /// <summary>
    ///   Surface::clear: fills the whole surface with the low byte of the color
    /// </summary>
    procedure Clear(AColor: Cardinal = 0);
    /// <summary>
    ///   Surface::offset: adds AOffset to every non transparent pixel (multiplying by AMul first if AOffset is
    ///   positive, dividing by it if negative), keeping the result between AMin and AMax (-1 means no limit)
    /// </summary>
    procedure Offset(AOffset: Integer; AMin: Integer = -1; AMax: Integer = -1; AMul: Integer = 1);
    /// <summary>Surface::offsetBlock: like Offset but the result stays inside the block of ABlock colors of the pixel</summary>
    procedure OffsetBlock(AOffset: Integer; ABlock: Integer = 16; AMul: Integer = 1);
    /// <summary>Surface::invert: mirrors every non transparent pixel around AMiddle</summary>
    procedure Invert(AMiddle: Byte);
    /// <summary>
    ///   Surface::copy: copies into this surface the part of ASource that this surface covers, pixel by pixel
    ///   (the position of both surfaces counts; what is outside ASource is 0)
    /// </summary>
    procedure Copy(ASource: TXcomSurface);
    /// <summary>Surface::drawRect with the SDL conversion of the arguments (signed 16 bit position, unsigned size)</summary>
    procedure DrawRect(AX, AY, AWidth, AHeight: Integer; AColor: Byte); overload;
    procedure DrawRect(const ARect: TXcomRect; AColor: Byte); overload;
    /// <summary>Surface::draw: the base surface just clears itself and forgets that it must be redrawn</summary>
    procedure Draw;
    /// <summary>
    ///   Surface::blit: if the surface is visible and not hidden it is copied (with its crop) on ATarget at its
    ///   own position, the index 0 being transparent
    /// </summary>
    procedure Blit(ATarget: TXcomSurface);
    /// <summary>Surface::setWidth: the surface changes size keeping the pixels it can, and must be redrawn</summary>
    procedure SetWidth(AWidth: Integer);
    procedure SetHeight(AHeight: Integer);
  end;

implementation

{ TXcomSurface }

constructor TXcomSurface.Create(AWidth, AHeight: Integer; AX: Integer; AY: Integer);
begin
  inherited Create;
  FImage := TXcomImage.Create(AWidth, AHeight);
  FImage.HasPalette := True;
  FImage.Palette := TXcomPalette.Create(XCOM_SURFACE_COLORS);
  FX := AX;
  FY := AY;
  FVisible := True;
end;

function TXcomSurface.Clone: TXcomSurface;
var
  LIndex: Integer;
begin
  Result := TXcomSurface.Create(Width, Height, FX, FY);
  Move(FImage.Pixels[0], Result.FImage.Pixels[0], Length(FImage.Pixels));
  for LIndex := 0 to XCOM_SURFACE_COLORS - 2 do
    Result.FImage.Palette.Colors[LIndex] := FImage.Palette.Colors[LIndex];
  Result.FCrop := FCrop;
  Result.FVisible := FVisible;
  Result.FHidden := FHidden;
  Result.FRedraw := FRedraw;
  Result.FTftdMode := FTftdMode;
end;

function TXcomSurface.Width: Integer;
begin
  Result := FImage.Width;
end;

function TXcomSurface.Height: Integer;
begin
  Result := FImage.Height;
end;

function TXcomSurface.Pixels: TBytes;
begin
  Result := FImage.Pixels;
end;

function TXcomSurface.PixelPointer(AX, AY: Integer): PByte;
begin
  Result := @FImage.Pixels[AY * FImage.Width + AX];
end;

procedure TXcomSurface.ResetCrop;
begin
  FCrop := TXcomRect.Make(0, 0, 0, 0);
end;

function TXcomSurface.Palette: TXcomPalette;
begin
  Result := FImage.Palette;
end;

procedure TXcomSurface.SetColors(const AColors: array of TXcomColor; AFirstColor: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AColors) do
    if (AFirstColor + LIndex >= 0) and (AFirstColor + LIndex < XCOM_SURFACE_COLORS) then
      FImage.Palette.Colors[AFirstColor + LIndex] := AColors[LIndex];
end;

function TXcomSurface.GetPixel(AX, AY: Integer): Byte;
begin
  Result := FImage.GetPixel(AX, AY);
end;

procedure TXcomSurface.SetPixel(AX, AY: Integer; AValue: Byte);
begin
  FImage.SetPixel(AX, AY, AValue);
end;

procedure TXcomSurface.SetPixelIterative(var AX, AY: Integer; AValue: Byte);
begin
  FImage.SetPixelIterative(AX, AY, AValue);
end;

procedure TXcomSurface.Clear(AColor: Cardinal);
begin
  FillChar(FImage.Pixels[0], Length(FImage.Pixels), Byte(AColor and $FF));
end;

procedure TXcomSurface.Offset(AOffset, AMin, AMax, AMul: Integer);
var
  LX, LY: Integer;
  LPixel: Byte;
  LValue: Integer;
begin
  if AOffset = 0 then
    Exit;
  if AMul = 0 then
    raise EXcomSurfaceException.Create('Xcom: Surface.Offset with a zero multiplier');
  LX := 0;
  LY := 0;
  while (LX < Width) and (LY < Height) do
  begin
    LPixel := GetPixel(LX, LY);
    if AOffset > 0 then
      LValue := LPixel * AMul + AOffset
    else
      LValue := (LPixel + AOffset) div AMul;
    if (AMin <> -1) and (LValue < AMin) then
      LValue := AMin
    else if (AMax <> -1) and (LValue > AMax) then
      LValue := AMax;
    if LPixel > 0 then
      SetPixelIterative(LX, LY, Byte(LValue and $FF))
    else
      SetPixelIterative(LX, LY, 0);
  end;
end;

procedure TXcomSurface.OffsetBlock(AOffset, ABlock, AMul: Integer);
var
  LX, LY: Integer;
  LPixel: Byte;
  LValue, LMin, LMax: Integer;
begin
  if AOffset = 0 then
    Exit;
  if (AMul = 0) or (ABlock = 0) then
    raise EXcomSurfaceException.Create('Xcom: Surface.OffsetBlock with a zero multiplier or block');
  LX := 0;
  LY := 0;
  while (LX < Width) and (LY < Height) do
  begin
    LPixel := GetPixel(LX, LY);
    LMin := LPixel div ABlock * ABlock;
    LMax := LMin + ABlock;
    if AOffset > 0 then
      LValue := LPixel * AMul + AOffset
    else
      LValue := (LPixel + AOffset) div AMul;
    if LValue < LMin then
      LValue := LMin
    else if LValue > LMax then
      LValue := LMax;
    if LPixel > 0 then
      SetPixelIterative(LX, LY, Byte(LValue and $FF))
    else
      SetPixelIterative(LX, LY, 0);
  end;
end;

procedure TXcomSurface.Invert(AMiddle: Byte);
var
  LX, LY: Integer;
  LPixel: Byte;
begin
  LX := 0;
  LY := 0;
  while (LX < Width) and (LY < Height) do
  begin
    LPixel := GetPixel(LX, LY);
    if LPixel > 0 then
      SetPixelIterative(LX, LY, Byte((LPixel + 2 * (Integer(AMiddle) - Integer(LPixel))) and $FF))
    else
      SetPixelIterative(LX, LY, 0);
  end;
end;

procedure TXcomSurface.Copy(ASource: TXcomSurface);
var
  LFromX, LFromY, LX, LY: Integer;
begin
  LFromX := FX - ASource.X;
  LFromY := FY - ASource.Y;
  LX := 0;
  LY := 0;
  while (LX < Width) and (LY < Height) do
    SetPixelIterative(LX, LY, ASource.GetPixel(LFromX + LX, LFromY + LY));
end;

procedure TXcomSurface.DrawRect(AX, AY, AWidth, AHeight: Integer; AColor: Byte);
begin
  // the arguments are Sint16 in the C++
  AX := SmallInt(AX and $FFFF);
  AY := SmallInt(AY and $FFFF);
  AWidth := SmallInt(AWidth and $FFFF);
  AHeight := SmallInt(AHeight and $FFFF);
  if (AWidth = 0) or (AHeight = 0) then
    Exit;
  TXcomSdl.FillRect(@FImage.Pixels[0], Width, Height, TXcomRect.Make(AX, AY, AWidth, AHeight), AColor);
end;

procedure TXcomSurface.DrawRect(const ARect: TXcomRect; AColor: Byte);
begin
  if (ARect.W = 0) or (ARect.H = 0) then
    Exit;
  TXcomSdl.FillRect(@FImage.Pixels[0], Width, Height, ARect, AColor);
end;

procedure TXcomSurface.Draw;
begin
  FRedraw := False;
  Clear;
end;

procedure TXcomSurface.Blit(ATarget: TXcomSurface);
var
  LCrop: TXcomRect;
begin
  if FVisible and not FHidden then
  begin
    if FRedraw then
      Draw;
    LCrop := FCrop;
    if (LCrop.W = 0) and (LCrop.H = 0) then
      TXcomSdl.BlitKeyed(@FImage.Pixels[0], Width, Height, FImage.Palette, nil, @ATarget.FImage.Pixels[0],
        ATarget.Width, ATarget.Height, ATarget.FImage.Palette, FX, FY)
    else
      TXcomSdl.BlitKeyed(@FImage.Pixels[0], Width, Height, FImage.Palette, @LCrop, @ATarget.FImage.Pixels[0],
        ATarget.Width, ATarget.Height, ATarget.FImage.Palette, FX, FY);
  end;
end;

procedure TXcomSurface.Resize(AWidth, AHeight: Integer);
var
  LNew: TXcomImage;
begin
  LNew := TXcomImage.Create(AWidth, AHeight);
  LNew.HasPalette := True;
  LNew.Palette := FImage.Palette;
  TXcomSdl.BlitKeyed(@FImage.Pixels[0], Width, Height, FImage.Palette, nil, @LNew.Pixels[0], AWidth, AHeight,
    LNew.Palette, 0, 0);
  FImage := LNew;
end;

procedure TXcomSurface.SetWidth(AWidth: Integer);
begin
  Resize(AWidth, Height);
  FRedraw := True;
end;

procedure TXcomSurface.SetHeight(AHeight: Integer);
begin
  Resize(Width, AHeight);
  FRedraw := True;
end;

end.
