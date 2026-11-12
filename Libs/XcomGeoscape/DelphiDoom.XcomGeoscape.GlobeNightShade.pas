{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - the shadow of the night of the globe     }
{  drawn finer than the game picture (issue 183): Globe::drawShadow with whole  }
{  numbers, on a picture of the land that is kept                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.GlobeNightShade;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The shadow of the night for a globe that is the finer drawing of the globe of the game. It does what
  ///   Globe::drawShadow does to every pixel (the shade from the angle between the place and the sun, less the noise;
  ///   the sea takes one of its 32 colors, the land moves inside its block of 16) but with whole numbers: the place
  ///   of a pixel on the sphere is a table of 16 bit heights and the product with the sun is a sum of three
  ///   terms, so a picture sixteen times the one of the game is shaded in a few milliseconds. It reads the land
  ///   from one picture and writes the shaded land to another: the land is rasterized once for a view and shaded
  ///   again when the sun moves.
  ///   The shade of a pixel can differ by one level from the one the floating point routine gives where the angle
  ///   falls on the edge of a level (the height has 16 bits)
  /// </summary>
  TXcomGlobeNightShade = class
  public
    const
      /// <summary>The side of the square table of noise of the globe</summary>
      NOISE_SIZE = 60;
      /// <summary>How far the sun (a vector of length 1) moves before the shadow is worth drawing again: a quarter of
      /// a level of shade where the levels are closest</summary>
      SUN_STEP = 0.001;
  strict private
    const
      SHIFT = 22;
      LEVEL_BIAS = 256;
      LEVEL_COUNT = 512;
      NOISE_LEVELS = 4;
    var
      FWidth: Integer;
      FHeight: Integer;
      FScale: Integer;
      FOceanColor: Byte;
      FOceanShading: Boolean;
      FRadius: Double;
      FHeights: TArray<Word>;
      FLevels: array[0..NOISE_LEVELS * LEVEL_COUNT - 1] of Byte;
      FColumnTerms: TArray<Integer>;
      FNoiseColumns: TArray<Integer>;
    procedure BuildHeights;
    class function Scaled(AValue: Double): Integer; static;
  public
    /// <param name="AWidth">The width of the pictures (the one of the globe of the game times AScale)</param>
    /// <param name="AScale">How many pixels of these pictures a pixel of the game takes: a cell of noise covers
    /// that many</param>
    /// <param name="AGradient">The 240 values of the table of GlobeStaticData (the shade for an angle)</param>
    constructor Create(AWidth, AHeight, AScale: Integer; AOceanColor: Byte; AOceanShading: Boolean;
      const AGradient: array of SmallInt);
    /// <summary>The radius of the globe in pixels of these pictures (the table of the heights is made again when it changes)</summary>
    procedure SetRadius(ARadius: Double);
    /// <summary>
    ///   Shades ALand into ATarget (both AWidth x AHeight; they can be the same picture). The sphere is centered in
    ///   the middle of the picture moved by the offset, as the table of Globe.cpp is; a pixel that is not on the
    ///   sphere or has no land or sea becomes 0, the pixels the moved table does not reach are copied
    /// </summary>
    /// <param name="ASunX">The direction of the sun seen from the center of the view (length 1)</param>
    /// <param name="ANoise">NOISE_SIZE x NOISE_SIZE values 0..3</param>
    procedure Shade(const ALand: TBytes; var ATarget: TBytes; AOffsetX, AOffsetY: Integer; ASunX, ASunY,
      ASunZ: Double; const ANoise: TArray<SmallInt>);
    /// <summary>True when the sun moved less than SUN_STEP: the shadow drawn for the first sun still stands</summary>
    class function SameSun(AX1, AY1, AZ1, AX2, AY2, AZ2: Double): Boolean; static;
    property Radius: Double read FRadius;
  end;

implementation

const
  SBadSize = 'XcomGlobeNightShade: the pictures have another size';
  SBadNoise = 'XcomGlobeNightShade: the noise has 60 x 60 values';
  SBadGradient = 'XcomGlobeNightShade: the gradient has 240 values';

constructor TXcomGlobeNightShade.Create(AWidth, AHeight, AScale: Integer; AOceanColor: Byte;
  AOceanShading: Boolean; const AGradient: array of SmallInt);
var
  LNoise: Integer;
  LLevel: Integer;
  LStep: Integer;
  LValue: Integer;
begin
  inherited Create;
  if (AWidth <= 0) or (AHeight <= 0) or (AScale < 1) then
    raise EArgumentException.Create(SBadSize);
  if Length(AGradient) <> 240 then
    raise EArgumentException.Create(SBadGradient);
  FWidth := AWidth;
  FHeight := AHeight;
  FScale := AScale;
  FOceanColor := AOceanColor;
  FOceanShading := AOceanShading;
  SetLength(FColumnTerms, AWidth);
  SetLength(FNoiseColumns, AWidth);
  // the shade for every whole part of the angle term (moved by LEVEL_BIAS to be positive) and every noise:
  // getShadowValue rounds the term towards zero, a shift rounds it down
  for LNoise := 0 to NOISE_LEVELS - 1 do
    for LLevel := 0 to LEVEL_COUNT - 1 do
    begin
      LStep := LLevel - LEVEL_BIAS;
      if LStep < 0 then
        Inc(LStep);
      if LLevel - LEVEL_BIAS < -110 then
        LValue := -31
      else if LLevel - LEVEL_BIAS >= 120 then
        LValue := 50
      else
        LValue := AGradient[LStep + 120];
      Dec(LValue, LNoise);
      if LValue < 0 then
        LValue := 0
      else if LValue > 31 then
        LValue := 31;
      FLevels[LNoise * LEVEL_COUNT + LLevel] := Byte(LValue);
    end;
end;

class function TXcomGlobeNightShade.Scaled(AValue: Double): Integer;
const
  LIMIT = 400.0;
begin
  // the terms of the pixels that are on the sphere stay within 250; the others are not used
  if AValue > LIMIT then
    AValue := LIMIT
  else if AValue < -LIMIT then
    AValue := -LIMIT;
  Result := Round(AValue * (1 shl SHIFT));
end;

procedure TXcomGlobeNightShade.SetRadius(ARadius: Double);
begin
  if (ARadius = FRadius) and (Length(FHeights) > 0) then
    Exit;
  FRadius := ARadius;
  BuildHeights;
end;

procedure TXcomGlobeNightShade.BuildHeights;
var
  LX: Integer;
  LY: Integer;
  LDeltaX: Double;
  LDeltaY: Double;
  LLimit: Double;
  LRest: Double;
  LValue: Integer;
  LCell: PWord;
begin
  // CircleNorm of Globe.cpp for every pixel, keeping only the height (x and y are the pixel itself)
  SetLength(FHeights, FWidth * FHeight);
  LLimit := FRadius * FRadius;
  LCell := @FHeights[0];
  for LY := 0 to FHeight - 1 do
  begin
    LDeltaY := LY + 0.5 - FHeight div 2;
    for LX := 0 to FWidth - 1 do
    begin
      LDeltaX := LX + 0.5 - FWidth div 2;
      LRest := LLimit - (LDeltaX * LDeltaX + LDeltaY * LDeltaY);
      if LRest > 0 then
      begin
        LValue := Round(Sqrt(LRest) / FRadius * 65535);
        // 0 means "not on the sphere"
        if LValue < 1 then
          LValue := 1;
        LCell^ := Word(LValue);
      end
      else
        LCell^ := 0;
      Inc(LCell);
    end;
  end;
end;

class function TXcomGlobeNightShade.SameSun(AX1, AY1, AZ1, AX2, AY2, AZ2: Double): Boolean;
begin
  Result := Sqr(AX1 - AX2) + Sqr(AY1 - AY2) + Sqr(AZ1 - AZ2) < SUN_STEP * SUN_STEP;
end;

procedure TXcomGlobeNightShade.Shade(const ALand: TBytes; var ATarget: TBytes; AOffsetX, AOffsetY: Integer; ASunX,
  ASunY, ASunZ: Double; const ANoise: TArray<SmallInt>);
var
  LX: Integer;
  LY: Integer;
  LTableX: Integer;
  LTableY: Integer;
  LFirstX: Integer;
  LLastX: Integer;
  LRowTerm: Integer;
  LHeightTerm: Integer;
  LNoiseRow: Integer;
  LShadow: Integer;
  LEnd: Integer;
  LGroup: Integer;
  LOcean: Integer;
  LSource: PByte;
  LDest: PByte;
  LHeight: PWord;
  LValue: Byte;
begin
  if (Length(ALand) <> FWidth * FHeight) or (Length(ATarget) <> FWidth * FHeight) or (Length(FHeights) = 0) then
    raise EArgumentException.Create(SBadSize);
  if Length(ANoise) <> NOISE_SIZE * NOISE_SIZE then
    raise EArgumentException.Create(SBadNoise);
  // getShadowValue: (|earth - sun|^2 - 2) * 125 is -250 times the product of the two vectors of length 1.
  // The term of a pixel is the sum of one for its column, one for its row and its height times a factor
  LHeightTerm := Round(-250.0 * ASunZ / 65535 * (1 shl SHIFT));
  for LX := 0 to FWidth - 1 do
  begin
    LTableX := LX - AOffsetX;
    FColumnTerms[LX] := Scaled(-250.0 * ASunX * (LTableX + 0.5 - FWidth div 2) / FRadius);
    FNoiseColumns[LX] := (LX div FScale) mod NOISE_SIZE;
  end;
  LFirstX := AOffsetX;
  if LFirstX < 0 then
    LFirstX := 0;
  LLastX := FWidth - 1 + AOffsetX;
  if LLastX > FWidth - 1 then
    LLastX := FWidth - 1;
  LOcean := FOceanColor;
  for LY := 0 to FHeight - 1 do
  begin
    LTableY := LY - AOffsetY;
    if (LTableY < 0) or (LTableY >= FHeight) or (LFirstX > LLastX) then
    begin
      if Pointer(ALand) <> Pointer(ATarget) then
        Move(ALand[LY * FWidth], ATarget[LY * FWidth], FWidth);
      Continue;
    end;
    if Pointer(ALand) <> Pointer(ATarget) then
    begin
      if LFirstX > 0 then
        Move(ALand[LY * FWidth], ATarget[LY * FWidth], LFirstX);
      if LLastX < FWidth - 1 then
        Move(ALand[LY * FWidth + LLastX + 1], ATarget[LY * FWidth + LLastX + 1], FWidth - 1 - LLastX);
    end;
    LRowTerm := Scaled(-250.0 * ASunY * (LTableY + 0.5 - FHeight div 2) / FRadius) + (LEVEL_BIAS shl SHIFT);
    LNoiseRow := ((LY div FScale) mod NOISE_SIZE) * NOISE_SIZE;
    LSource := @ALand[LY * FWidth + LFirstX];
    LDest := @ATarget[LY * FWidth + LFirstX];
    LHeight := @FHeights[LTableY * FWidth + LFirstX - AOffsetX];
    for LX := LFirstX to LLastX do
    begin
      LValue := LSource^;
      if (LValue <> 0) and (LHeight^ <> 0) then
      begin
        LShadow := FLevels[ANoise[LNoiseRow + FNoiseColumns[LX]] * LEVEL_COUNT +
          ((LRowTerm + FColumnTerms[LX] + LHeight^ * LHeightTerm) shr SHIFT)];
        if FOceanShading and (LValue >= LOcean) and (LValue < LOcean + 32) then
          LValue := Byte(LOcean + LShadow)
        else if LShadow >= 3 then
        begin
          // getLandShadow: a third of the shade, inside the block of 16 of the color
          LEnd := LValue + LShadow div 3;
          LGroup := LValue and $F0;
          if LEnd > LGroup + $0F then
            LValue := Byte(LGroup + $0F)
          else
            LValue := Byte(LEnd);
        end;
        LDest^ := LValue;
      end
      else
        LDest^ := 0;
      Inc(LSource);
      Inc(LDest);
      Inc(LHeight);
    end;
  end;
end;

end.
