{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the font library - the fakes                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Font.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections,
  DelphiDoom.Palette.GamePalettes,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Settings,
  DelphiDoom.Font.Intf,
  DelphiDoom.Tests.Font.Scenarios;

type
  /// <summary>
  ///   The rasterizer of the tests: the character of TSyntheticGlyphs in the colors of the settings (the one that
  ///   the old DD_FONT of the harness painted with), and a count of the characters that it was asked for
  /// </summary>
  TSyntheticRasterizer = class(TInterfacedObject, IFontRasterizer)
  public
    Calls: Integer;
    Characters: TList<Char>;
    /// <summary>The settings of the last character that was asked for</summary>
    LastSettings: TFontSettings;
    constructor Create;
    destructor Destroy; override;
    function RenderCharacter(const ASettings: TFontSettings; ACharacter: Char): TFontImage;
  end;

  /// <summary>A rasterizer that draws a flat picture of the size that it is told to (for the tests of a wrong rasterizer)</summary>
  TFlatRasterizer = class(TInterfacedObject, IFontRasterizer)
  public
    Width: Integer;
    Height: Integer;
    Color: Cardinal;
    function RenderCharacter(const ASettings: TFontSettings; ACharacter: Char): TFontImage;
  end;

  /// <summary>Fingerprints (FNV-1a, 64 bit) as the golden files of the font tests write them</summary>
  TFontDigests = class sealed
  public
    class function OfBytes(const ABytes: TBytes): string; static;
    class function OfPixels(const APixels: TArray<Cardinal>; ACount: Integer): string; static;
  end;

  /// <summary>The settings and the palette of a scenario, as the golden files were made</summary>
  TFontScenarioBridge = class sealed
  public
    class function Settings(const AScenario: TFontScenario): TFontSettings; static;
    class function Palette(const AScenario: TFontScenario): TFontPaletteSelection; static;
    class function Options(const AScenario: TFontScenario): TFontExportOptions; static;
  end;

implementation

uses
  DelphiDoom.Tests.Sound.Digest,
  DelphiDoom.Tests.Font.SyntheticGlyphs;

{ TSyntheticRasterizer }

constructor TSyntheticRasterizer.Create;
begin
  inherited Create;
  Characters := TList<Char>.Create;
end;

destructor TSyntheticRasterizer.Destroy;
begin
  Characters.Free;
  inherited Destroy;
end;

function TSyntheticRasterizer.RenderCharacter(const ASettings: TFontSettings; ACharacter: Char): TFontImage;
var
  LX: Integer;
  LY: Integer;
  LChannel: Integer;
  LBack: array[0..2] of Integer;
  LFront: array[0..2] of Integer;
  LValue: array[0..2] of Integer;
begin
  Inc(Calls);
  LastSettings := ASettings;
  Characters.Add(ACharacter);
  Result := TFontImage.Create(ASettings.DrawWidth, ASettings.DrawHeight);
  LFront[0] := TFontSettings.RedOf(ASettings.FrontColor);
  LFront[1] := TFontSettings.GreenOf(ASettings.FrontColor);
  LFront[2] := TFontSettings.BlueOf(ASettings.FrontColor);
  LBack[0] := TFontSettings.RedOf(ASettings.BackColor);
  LBack[1] := TFontSettings.GreenOf(ASettings.BackColor);
  LBack[2] := TFontSettings.BlueOf(ASettings.BackColor);
  for LY := 0 to ASettings.DrawHeight - 1 do
    for LX := 0 to ASettings.DrawWidth - 1 do
    begin
      for LChannel := 0 to 2 do
        LValue[LChannel] := TSyntheticGlyphs.Mix(LBack[LChannel], LFront[LChannel],
          TSyntheticGlyphs.Coverage(Ord(ACharacter), LX, LY, LChannel, ASettings.DrawWidth,
            ASettings.DrawHeight, ASettings.FontSize, ASettings.Style));
      Result.Pixels[LY * ASettings.DrawWidth + LX] := (Cardinal(LValue[0]) shl 16) or (Cardinal(LValue[1]) shl 8) or
        Cardinal(LValue[2]);
    end;
end;

{ TFlatRasterizer }

function TFlatRasterizer.RenderCharacter(const ASettings: TFontSettings; ACharacter: Char): TFontImage;
var
  LIndex: Integer;
begin
  Result := TFontImage.Create(Width, Height);
  for LIndex := 0 to Length(Result.Pixels) - 1 do
    Result.Pixels[LIndex] := Color;
end;

{ TFontDigests }

class function TFontDigests.OfBytes(const ABytes: TBytes): string;
var
  LDigest: TSoundDigest;
begin
  LDigest := TSoundDigest.Start;
  if Length(ABytes) > 0 then
    LDigest.AddBuffer(@ABytes[0], Length(ABytes));
  Result := IntToHex(LDigest.Value, 16) + ':' + IntToStr(Length(ABytes));
end;

class function TFontDigests.OfPixels(const APixels: TArray<Cardinal>; ACount: Integer): string;
var
  LDigest: TSoundDigest;
begin
  LDigest := TSoundDigest.Start;
  if ACount > 0 then
    LDigest.AddBuffer(@APixels[0], ACount * SizeOf(Cardinal));
  Result := IntToHex(LDigest.Value, 16) + ':' + IntToStr(ACount);
end;

{ TFontScenarioBridge }

class function TFontScenarioBridge.Settings(const AScenario: TFontScenario): TFontSettings;
begin
  Result := TFontSettings.Initial;
  Result.FontSize := AScenario.FontSize;
  Result.Style := AScenario.Style;
  Result.DrawWidth := AScenario.CellWidth;
  Result.DrawHeight := AScenario.CellHeight;
  Result.FrontColor := AScenario.FrontColor;
  Result.BackColor := AScenario.BackColor;
end;

class function TFontScenarioBridge.Palette(const AScenario: TFontScenario): TFontPaletteSelection;
begin
  if AScenario.Palette <= Ord(High(TGamePalette)) then
    Result := TFontPaletteSelection.Create(TGamePalettes.ToColors(TGamePalettes.Colors(TGamePalette(AScenario.Palette))),
      TGamePalettes.FirstUsableIndex(TGamePalette(AScenario.Palette)),
      TGamePalettes.LastUsableIndex(TGamePalette(AScenario.Palette)))
  else
    Result := TFontPaletteSelection.Create(TGamePalettes.ToColors(TGamePalettes.GrayscaleColors),
      TGamePalettes.FirstUsableIndexOfOther, TGamePalettes.LastUsableIndexOfOther);
end;

class function TFontScenarioBridge.Options(const AScenario: TFontScenario): TFontExportOptions;
begin
  if AScenario.DefaultOffsets then
    Result := TFontExportOptions.CreateWithDefaultOffsets(AScenario.FixedPitch, AScenario.PerlinNoise,
      AScenario.Solid)
  else
    Result := TFontExportOptions.Create(AScenario.FixedPitch, AScenario.PerlinNoise, AScenario.Solid,
      AScenario.OffsetX, AScenario.OffsetY);
end;

end.
