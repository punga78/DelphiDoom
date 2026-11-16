{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the screen of the menus, of the intro and of     }
{  the movies: the 8 bit buffer and the palette that is shown                   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): loadscreen of intro.pas,    }
{  VI_FillPalette of d_video.pas and what I_SetPalette of i_video.pas leaves    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Display;

// the 6 bit values of a palette lump times 4 wrap around in the byte, as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Canvas;

const
  GREED_DISPLAY_PALETTE_BYTES = 768;

type
  /// <summary>
  ///   What the menus, the title screens and the movies share in the original: the buffer (screen and viewbuffer
  ///   are the same 320 x 200 bytes), the palette given to I_SetPalette (768 bytes, 8 bit values) and the array
  ///   colors of intro.pas (the palette of the last picture that loadscreen has read). Each SetPalette sets the
  ///   ApproxZero of the canvas as I_SetPalette does. The program shows Palette when PaletteVersion changes and
  ///   clears its own 640 x 400 picture of the level when RenderClears changes (R_ClearRenderBuffer)
  /// </summary>
  TGreedDisplay = class
  strict private
    FCanvas: TGreedCanvas;
    FArchive: IGreedArchive;
    FPalette: TBytes;
    FColors: TBytes;
    FPaletteVersion: Integer;
    FRenderClears: Integer;
  public
    constructor Create(ACanvas: TGreedCanvas; const AArchive: IGreedArchive);
    /// <summary>I_SetPalette: the first 768 bytes are copied; EGreedDataException if they are fewer</summary>
    procedure SetPalette(const APalette: TBytes);
    /// <summary>VI_FillPalette: every color the same</summary>
    procedure FillPalette(ARed, AGreen, ABlue: Integer);
    /// <summary>I_SetPalette(CA_CachePalette(lump)): the lump with each byte times 4</summary>
    procedure SetPaletteFromLump(const AName: string);
    /// <summary>I_SetPalette(@colors)</summary>
    procedure ShowColors;
    /// <summary>
    ///   loadscreen: false, and nothing changes, if there is no lump with that name; otherwise the picture is copied
    ///   at (0, 0) as it is, Colors becomes the following lump times 4 and RenderClears grows by one. The palette
    ///   shown does not change
    /// </summary>
    function LoadScreen(const AName: string): Boolean;
    /// <summary>memset(screen, value, 64000)</summary>
    procedure FillScreen(AValue: Integer);
    /// <summary>R_ClearRenderBuffer asked by a movie</summary>
    procedure ClearRender;
    property Canvas: TGreedCanvas read FCanvas;
    property Archive: IGreedArchive read FArchive;
    /// <summary>The palette that is shown (not a copy: do not change it)</summary>
    property Palette: TBytes read FPalette;
    /// <summary>colors of intro.pas; a caller may save and put it back (DoIntroMenu)</summary>
    property Colors: TBytes read FColors write FColors;
    property PaletteVersion: Integer read FPaletteVersion;
    property RenderClears: Integer read FRenderClears;
  end;

implementation

uses
  DelphiDoom.Greed.Types, DelphiDoom.Greed.PaletteFader;

{ TGreedDisplay }

constructor TGreedDisplay.Create(ACanvas: TGreedCanvas; const AArchive: IGreedArchive);
begin
  inherited Create;
  if not Assigned(ACanvas) then
    raise EArgumentNilException.Create('ACanvas');
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  FCanvas := ACanvas;
  FArchive := AArchive;
  SetLength(FPalette, GREED_DISPLAY_PALETTE_BYTES);
  SetLength(FColors, GREED_DISPLAY_PALETTE_BYTES);
end;

procedure TGreedDisplay.SetPalette(const APalette: TBytes);
begin
  if Length(APalette) < GREED_DISPLAY_PALETTE_BYTES then
    raise EGreedDataException.CreateFmt(SGreedPaletteTooShort, [Length(APalette), GREED_DISPLAY_PALETTE_BYTES]);
  FPalette := Copy(APalette, 0, GREED_DISPLAY_PALETTE_BYTES);
  FCanvas.ApproxZero := TGreedPaletteFader.ApproximateZero(FPalette);
  Inc(FPaletteVersion);
end;

procedure TGreedDisplay.FillPalette(ARed, AGreen, ABlue: Integer);
begin
  SetPalette(TGreedPaletteFader.FillPalette(ARed, AGreen, ABlue));
end;

procedure TGreedDisplay.SetPaletteFromLump(const AName: string);
var
  LLump: TBytes;
  LPalette: TBytes;
  LIndex: Integer;
begin
  LLump := FArchive.ReadLump(FArchive.RequireIndexOf(AName));
  if Length(LLump) < GREED_DISPLAY_PALETTE_BYTES then
    raise EGreedDataException.CreateFmt(SGreedPaletteTooShort, [Length(LLump), GREED_DISPLAY_PALETTE_BYTES]);
  SetLength(LPalette, GREED_DISPLAY_PALETTE_BYTES);
  for LIndex := 0 to GREED_DISPLAY_PALETTE_BYTES - 1 do
    LPalette[LIndex] := Byte(LLump[LIndex] * 4);
  SetPalette(LPalette);
end;

procedure TGreedDisplay.ShowColors;
begin
  SetPalette(FColors);
end;

function TGreedDisplay.LoadScreen(const AName: string): Boolean;
var
  LLump: Integer;
  LPalette: TBytes;
  LColors: TBytes;
  LIndex: Integer;
begin
  LLump := FArchive.IndexOf(AName);
  Result := LLump >= 0;
  if not Result then
    Exit;
  Inc(FRenderClears);
  FCanvas.DrawPicSolidUntranslated(0, 0, FArchive.ReadLump(LLump));
  LPalette := FArchive.ReadLump(LLump + 1);
  if Length(LPalette) < GREED_DISPLAY_PALETTE_BYTES then
    raise EGreedDataException.CreateFmt(SGreedPaletteTooShort, [Length(LPalette), GREED_DISPLAY_PALETTE_BYTES]);
  // a new array: who saved Colors keeps the old values
  SetLength(LColors, GREED_DISPLAY_PALETTE_BYTES);
  for LIndex := 0 to GREED_DISPLAY_PALETTE_BYTES - 1 do
    LColors[LIndex] := Byte(LPalette[LIndex] * 4);
  FColors := LColors;
end;

procedure TGreedDisplay.FillScreen(AValue: Integer);
begin
  FillChar(FCanvas.Pixels[0], Length(FCanvas.Pixels), Byte(AValue and $FF));
end;

procedure TGreedDisplay.ClearRender;
begin
  Inc(FRenderClears);
end;

end.
