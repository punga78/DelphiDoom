{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - the colors of the pixels of an 8 bit      }
{  picture that are a blend and so are no color of its palette (issue 183:      }
{  smoke, fire and shadows of the battle shown in true color)                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.BlendOverlay;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Types;

type
  /// <summary>
  ///   Goes with an 8 bit surface that is drawn sprite after sprite (the map of the battle) and keeps, for the
  ///   pixels where a sprite was laid as a veil and not as a solid, the color the pixel really has: the blend of
  ///   what was under it and the sprite. The surface itself is drawn as always (its indexes do not change); who
  ///   shows it in true color takes the colors kept here in place of the ones of the palette.
  ///   The order of the drawing is kept by telling the overlay every sprite: a veil blends with the color under it
  ///   (a blend too, when a veil is laid on a veil), a solid sprite takes away the blend of the pixels it covers
  /// </summary>
  TXcomBlendOverlay = class
  public
    const
      /// <summary>The opacity of a solid sprite</summary>
      OPAQUE = 256;
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FValid: TBytes;
    FColors: TArray<Cardinal>;
    FPalette: array[0..255] of Cardinal;
    FBefore: TBytes;
    FBeforeX: Integer;
    FBeforeY: Integer;
    FBeforeWidth: Integer;
    FBeforeHeight: Integer;
    FCount: Integer;
    FLeft: Integer;
    FTop: Integer;
    FRight: Integer;
    FBottom: Integer;
    procedure Keep(AIndex, AX, AY: Integer; AColor: Cardinal);
    function Outside(AX, AY, AWidth, AHeight: Integer): Boolean;
    class function Mix(AUnder, AOver: Cardinal; AOpacity: Integer): Cardinal; static;
  public
    constructor Create(AWidth, AHeight: Integer);
    /// <summary>The palette of the surface: the colors its indexes have</summary>
    procedure SetPalette(const AColors: array of TXcomColor);
    /// <summary>Forgets every blend (the surface is drawn again from nothing)</summary>
    procedure Clear;
    /// <summary>
    ///   A solid sprite was drawn on the surface at (AX, AY): the pixels it has (not 0) are colors of the palette
    ///   again. With AHalf only its right half was drawn (blitNShade)
    /// </summary>
    procedure Cover(ASprite: TXcomSurface; AX, AY: Integer; AHalf: Boolean = False); overload;
    /// <summary>The same for a sprite drawn only inside ARange</summary>
    procedure Cover(ASprite: TXcomSurface; AX, AY: Integer; const ARange: TXcomGraphSubset); overload;
    /// <summary>One pixel of the surface was written</summary>
    procedure CoverPixel(AX, AY: Integer);
    /// <summary>Before a sprite is drawn as a veil: the rectangle of the surface it is going to be drawn on</summary>
    procedure BeginVeil(ASurface: TXcomSurface; AX, AY, AWidth, AHeight: Integer);
    /// <summary>
    ///   After the sprite was drawn (solid, as the game does) at (AX, AY), the same as given to BeginVeil: every
    ///   pixel of it inside ARange keeps the blend of what was there and the color the sprite left, AOpacity parts
    ///   of 256 of the latter
    /// </summary>
    procedure EndVeil(ASurface, ASprite: TXcomSurface; AX, AY, AOpacity: Integer; const ARange: TXcomGraphSubset);
    /// <summary>
    ///   A shadow on what is drawn so far: the pixels of the ellipse are made darker, AOpacity parts of 256 of
    ///   black. The surface is not touched
    /// </summary>
    procedure Darken(ASurface: TXcomSurface; ACenterX, ACenterY, ARadiusX, ARadiusY, AOpacity: Integer);
    /// <summary>True when at least one pixel is a blend</summary>
    function HasBlends: Boolean;
    /// <summary>1 for the pixels that are a blend, row after row</summary>
    property Valid: TBytes read FValid;
    /// <summary>The colors ($FFRRGGBB) of the pixels that are a blend</summary>
    property Colors: TArray<Cardinal> read FColors;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    /// <summary>The whole surface as a range</summary>
    function Everything: TXcomGraphSubset;
  end;

implementation

constructor TXcomBlendOverlay.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  if (AWidth <= 0) or (AHeight <= 0) then
    raise EArgumentException.Create('XcomBlendOverlay: the size');
  FWidth := AWidth;
  FHeight := AHeight;
  SetLength(FValid, AWidth * AHeight);
  SetLength(FColors, AWidth * AHeight);
  Clear;
end;

procedure TXcomBlendOverlay.SetPalette(const AColors: array of TXcomColor);
var
  LIndex: Integer;
begin
  for LIndex := 0 to Min(255, High(AColors)) do
    FPalette[LIndex] := $FF000000 or (Cardinal(AColors[LIndex].Red) shl 16) or
      (Cardinal(AColors[LIndex].Green) shl 8) or Cardinal(AColors[LIndex].Blue);
end;

procedure TXcomBlendOverlay.Clear;
begin
  if FCount > 0 then
    FillChar(FValid[0], Length(FValid), 0);
  FCount := 0;
  FLeft := FWidth;
  FTop := FHeight;
  FRight := -1;
  FBottom := -1;
end;

function TXcomBlendOverlay.HasBlends: Boolean;
begin
  Result := FCount > 0;
end;

function TXcomBlendOverlay.Everything: TXcomGraphSubset;
begin
  Result := TXcomGraphSubset.Make(0, FWidth, 0, FHeight);
end;

class function TXcomBlendOverlay.Mix(AUnder, AOver: Cardinal; AOpacity: Integer): Cardinal;
var
  LRest: Cardinal;
  LPart: Cardinal;
begin
  LPart := Cardinal(AOpacity);
  LRest := Cardinal(OPAQUE - AOpacity);
  Result := $FF000000
    or (((((AUnder shr 16) and $FF) * LRest + ((AOver shr 16) and $FF) * LPart) shr 8) shl 16)
    or (((((AUnder shr 8) and $FF) * LRest + ((AOver shr 8) and $FF) * LPart) shr 8) shl 8)
    or (((AUnder and $FF) * LRest + (AOver and $FF) * LPart) shr 8);
end;

procedure TXcomBlendOverlay.Keep(AIndex, AX, AY: Integer; AColor: Cardinal);
begin
  if FValid[AIndex] = 0 then
  begin
    FValid[AIndex] := 1;
    Inc(FCount);
  end;
  FColors[AIndex] := AColor;
  if AX < FLeft then
    FLeft := AX;
  if AX > FRight then
    FRight := AX;
  if AY < FTop then
    FTop := AY;
  if AY > FBottom then
    FBottom := AY;
end;

function TXcomBlendOverlay.Outside(AX, AY, AWidth, AHeight: Integer): Boolean;
begin
  // nothing is a blend there: most of the sprites of a frame are told to the overlay for nothing
  Result := (FCount = 0) or (AX > FRight) or (AY > FBottom) or (AX + AWidth <= FLeft) or (AY + AHeight <= FTop);
end;

procedure TXcomBlendOverlay.Cover(ASprite: TXcomSurface; AX, AY: Integer; AHalf: Boolean);
var
  LRange: TXcomGraphSubset;
begin
  LRange := Everything;
  if AHalf then
    LRange.BegX := AX + ASprite.Width div 2;
  Cover(ASprite, AX, AY, LRange);
end;

procedure TXcomBlendOverlay.Cover(ASprite: TXcomSurface; AX, AY: Integer; const ARange: TXcomGraphSubset);
var
  LX: Integer;
  LY: Integer;
  LTargetX: Integer;
  LTargetY: Integer;
  LIndex: Integer;
  LPixels: TBytes;
begin
  if (not Assigned(ASprite)) or Outside(AX, AY, ASprite.Width, ASprite.Height) then
    Exit;
  LPixels := ASprite.Pixels;
  for LY := 0 to ASprite.Height - 1 do
  begin
    LTargetY := AY + LY;
    if (LTargetY < FTop) or (LTargetY > FBottom) or (LTargetY < ARange.BegY) or (LTargetY >= ARange.EndY) then
      Continue;
    for LX := 0 to ASprite.Width - 1 do
    begin
      LTargetX := AX + LX;
      if (LTargetX < FLeft) or (LTargetX > FRight) or (LTargetX < ARange.BegX) or (LTargetX >= ARange.EndX)
        or (LPixels[LY * ASprite.Width + LX] = 0) then
        Continue;
      LIndex := LTargetY * FWidth + LTargetX;
      if FValid[LIndex] <> 0 then
      begin
        FValid[LIndex] := 0;
        Dec(FCount);
      end;
    end;
  end;
end;

procedure TXcomBlendOverlay.CoverPixel(AX, AY: Integer);
var
  LIndex: Integer;
begin
  if (FCount = 0) or (AX < 0) or (AY < 0) or (AX >= FWidth) or (AY >= FHeight) then
    Exit;
  LIndex := AY * FWidth + AX;
  if FValid[LIndex] <> 0 then
  begin
    FValid[LIndex] := 0;
    Dec(FCount);
  end;
end;

procedure TXcomBlendOverlay.BeginVeil(ASurface: TXcomSurface; AX, AY, AWidth, AHeight: Integer);
var
  LRow: Integer;
begin
  // the part of the rectangle that is on the surface
  FBeforeX := AX;
  FBeforeY := AY;
  FBeforeWidth := AWidth;
  FBeforeHeight := AHeight;
  if FBeforeX < 0 then
  begin
    Inc(FBeforeWidth, FBeforeX);
    FBeforeX := 0;
  end;
  if FBeforeY < 0 then
  begin
    Inc(FBeforeHeight, FBeforeY);
    FBeforeY := 0;
  end;
  if FBeforeX + FBeforeWidth > FWidth then
    FBeforeWidth := FWidth - FBeforeX;
  if FBeforeY + FBeforeHeight > FHeight then
    FBeforeHeight := FHeight - FBeforeY;
  if (FBeforeWidth <= 0) or (FBeforeHeight <= 0) or (ASurface.Width <> FWidth) or (ASurface.Height <> FHeight) then
  begin
    FBeforeWidth := 0;
    Exit;
  end;
  if Length(FBefore) < FBeforeWidth * FBeforeHeight then
    SetLength(FBefore, FBeforeWidth * FBeforeHeight);
  for LRow := 0 to FBeforeHeight - 1 do
    Move(ASurface.Pixels[(FBeforeY + LRow) * FWidth + FBeforeX], FBefore[LRow * FBeforeWidth], FBeforeWidth);
end;

procedure TXcomBlendOverlay.EndVeil(ASurface, ASprite: TXcomSurface; AX, AY, AOpacity: Integer;
  const ARange: TXcomGraphSubset);
var
  LX: Integer;
  LY: Integer;
  LTargetX: Integer;
  LTargetY: Integer;
  LIndex: Integer;
  LUnder: Cardinal;
  LSprite: TBytes;
  LSurface: TBytes;
begin
  if (FBeforeWidth <= 0) or (not Assigned(ASprite)) then
    Exit;
  if AOpacity >= OPAQUE then
  begin
    Cover(ASprite, AX, AY, ARange);
    Exit;
  end;
  if AOpacity < 0 then
    AOpacity := 0;
  LSprite := ASprite.Pixels;
  LSurface := ASurface.Pixels;
  for LY := 0 to ASprite.Height - 1 do
  begin
    LTargetY := AY + LY;
    if (LTargetY < FBeforeY) or (LTargetY >= FBeforeY + FBeforeHeight) or (LTargetY < ARange.BegY)
      or (LTargetY >= ARange.EndY) then
      Continue;
    for LX := 0 to ASprite.Width - 1 do
    begin
      LTargetX := AX + LX;
      if (LTargetX < FBeforeX) or (LTargetX >= FBeforeX + FBeforeWidth) or (LTargetX < ARange.BegX)
        or (LTargetX >= ARange.EndX) or (LSprite[LY * ASprite.Width + LX] = 0) then
        Continue;
      LIndex := LTargetY * FWidth + LTargetX;
      // what was under the veil: a blend when a veil was already there, else the color of the palette
      if FValid[LIndex] <> 0 then
        LUnder := FColors[LIndex]
      else
        LUnder := FPalette[FBefore[(LTargetY - FBeforeY) * FBeforeWidth + LTargetX - FBeforeX]];
      Keep(LIndex, LTargetX, LTargetY, Mix(LUnder, FPalette[LSurface[LIndex]], AOpacity));
    end;
  end;
  FBeforeWidth := 0;
end;

procedure TXcomBlendOverlay.Darken(ASurface: TXcomSurface; ACenterX, ACenterY, ARadiusX, ARadiusY,
  AOpacity: Integer);
var
  LX: Integer;
  LY: Integer;
  LIndex: Integer;
  LUnder: Cardinal;
  LSurface: TBytes;
begin
  if (ARadiusX <= 0) or (ARadiusY <= 0) or (ASurface.Width <> FWidth) or (ASurface.Height <> FHeight) then
    Exit;
  LSurface := ASurface.Pixels;
  for LY := ACenterY - ARadiusY to ACenterY + ARadiusY do
  begin
    if (LY < 0) or (LY >= FHeight) then
      Continue;
    for LX := ACenterX - ARadiusX to ACenterX + ARadiusX do
    begin
      if (LX < 0) or (LX >= FWidth) then
        Continue;
      // inside the ellipse, in whole numbers
      if Sqr(LX - ACenterX) * Sqr(ARadiusY) + Sqr(LY - ACenterY) * Sqr(ARadiusX) > Sqr(ARadiusX) * Sqr(ARadiusY) then
        Continue;
      LIndex := LY * FWidth + LX;
      if FValid[LIndex] <> 0 then
        LUnder := FColors[LIndex]
      else
        LUnder := FPalette[LSurface[LIndex]];
      Keep(LIndex, LX, LY, Mix(LUnder, $FF000000, AOpacity));
    end;
  end;
end;

end.
