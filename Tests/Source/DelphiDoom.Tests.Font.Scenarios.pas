{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the font library - the scenarios of the golden files    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  This unit is compiled by the tests and by the harness that makes the golden  }
{  files from the old DD_FONT (outside of the repository): it must not use      }
{  anything of the libraries                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Font.Scenarios;

{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

type
  /// <summary>One export of a text: the font, the colors, the palette (0..5 the games, 6 the gray ramp) and the options</summary>
  TFontScenario = record
    Id: Integer;
    FontSize: Integer;
    Style: Integer;
    CellWidth: Integer;
    CellHeight: Integer;
    FrontColor: Integer;
    BackColor: Integer;
    Text: string;
    Palette: Integer;
    FixedPitch: Boolean;
    PerlinNoise: Boolean;
    Solid: Boolean;
    DefaultOffsets: Boolean;
    OffsetX: Integer;
    OffsetY: Integer;
  end;

  /// <summary>A picture of palette indices for the patch writer</summary>
  TPatchCase = record
    Width: Integer;
    Height: Integer;
    Solid: Boolean;
    DefaultOffsets: Boolean;
    OffsetX: Integer;
    OffsetY: Integer;
    Pixels: TArray<Byte>;
  end;

  /// <summary>One WAD of the generator: which of the scenarios gives the font, and what the WAD holds</summary>
  TWadCase = record
    Scenario: Integer;
    /// <summary>0 one text, 1 the characters, 2 the digits</summary>
    Mode: Integer;
    Text: string;
    Prefix: string;
  end;

  TFontScenarios = class sealed
  public
    class function Count: Integer; static;
    class function Item(AIndex: Integer): TFontScenario; static;
    class function PatchCaseCount: Integer; static;
    class function PatchCase(AIndex: Integer): TPatchCase; static;
    class function WadCaseCount: Integer; static;
    class function WadCase(AIndex: Integer): TWadCase; static;
    /// <summary>The kinds of the files of a palette: sizes 768, 1024, 1536, 2048, 800, 100 and 3072 bytes</summary>
    class function ExternalPaletteKindCount: Integer; static;
    class function ExternalPaletteFile(AKind: Integer): TArray<Byte>; static;
  end;

const
  /// <summary>The names of the palettes of the scenarios; the last one is a file that does not exist (the gray ramp)</summary>
  SCENARIO_PALETTE_NAMES: array[0..6] of string = ('DOOM', 'HERETIC', 'HEXEN', 'STRIFE', 'RADIX', 'GLSPEED',
    'nofile.pal');

implementation

const
  SCENARIO_COUNT = 360;
  PATCH_CASE_COUNT = 40;
  EXTERNAL_PALETTE_SIZES: array[0..6] of Integer = (768, 1024, 1536, 2048, 800, 100, 3072);
  SIZES: array[0..5] of Integer = (8, 12, 6, 20, 10, 4);
  STYLES: array[0..5] of Integer = (0, 1, 2, 4, 8, 3);
  CELLS_W: array[0..5] of Integer = (16, 20, 12, 32, 8, 6);
  CELLS_H: array[0..5] of Integer = (16, 24, 12, 32, 16, 10);
  COLORS: array[0..5] of Integer = ($FFFFFF, $0000FF, $00FF00, $A0A0A0, $101010, $FF8040);
  BACKS: array[0..5] of Integer = (0, $400000, $004000, $202020, $000000, $0A0A50);
  TEXTS: array[0..9] of string = ('Doom Font Creator', 'A', 'ab', ' ', 'Hello World 12345', 'WWWWWWWWWWWWWWWWWWWW',
    '!@#$%+-AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz', 'iiiii', 'Wad', '0123456789');
  OFFSETS_X: array[0..2] of Integer = (0, 5, -3);
  OFFSETS_Y: array[0..2] of Integer = (3, -7, 12);

class function TFontScenarios.Count: Integer;
begin
  Result := SCENARIO_COUNT;
end;

class function TFontScenarios.Item(AIndex: Integer): TFontScenario;
var
  LState: Cardinal;
  LFont: Integer;

  function Next(AModulus: Integer): Integer;
  begin
    LState := LState * 1664525 + 1013904223;
    Result := Integer((LState shr 8) mod Cardinal(AModulus));
  end;

begin
  // the scenario i is made by a generator that starts at i: it does not depend on the ones before
  LState := Cardinal(AIndex) * 2654435761 + 12345;
  LFont := Next(6);
  Result.Id := AIndex;
  Result.FontSize := SIZES[LFont];
  Result.Style := STYLES[LFont];
  Result.CellWidth := CELLS_W[LFont];
  Result.CellHeight := CELLS_H[LFont];
  Result.FrontColor := COLORS[Next(6)];
  Result.BackColor := BACKS[Next(6)];
  Result.Text := TEXTS[Next(10)];
  // the first scenarios walk the palettes so that each one is used
  if AIndex < 7 then
    Result.Palette := AIndex
  else
    Result.Palette := Next(7);
  Result.FixedPitch := Next(2) = 1;
  Result.PerlinNoise := Next(2) = 1;
  Result.Solid := Next(4) = 0;
  Result.DefaultOffsets := Next(2) = 0;
  Result.OffsetX := OFFSETS_X[Next(3)];
  Result.OffsetY := OFFSETS_Y[Next(3)];
end;

class function TFontScenarios.PatchCaseCount: Integer;
begin
  Result := PATCH_CASE_COUNT;
end;

class function TFontScenarios.PatchCase(AIndex: Integer): TPatchCase;
var
  LState: Cardinal;
  LIndex: Integer;
  LDensity: Integer;

  function Next(AModulus: Integer): Integer;
  begin
    LState := LState * 1664525 + 1013904223;
    Result := Integer((LState shr 8) mod Cardinal(AModulus));
  end;

begin
  LState := Cardinal(AIndex) * 2654435761 + 777;
  Result.Solid := Odd(AIndex div 5);
  Result.DefaultOffsets := AIndex mod 3 <> 0;
  Result.OffsetX := Next(21) - 10;
  Result.OffsetY := Next(21) - 10;
  // the first cases are the edges: a pixel, a full picture, a picture without a pixel, the tallest, the widest
  case AIndex of
    0: begin Result.Width := 1; Result.Height := 1; LDensity := 0; end;
    1: begin Result.Width := 1; Result.Height := 1; LDensity := 100; end;
    2: begin Result.Width := 16; Result.Height := 16; LDensity := 100; end;
    3: begin Result.Width := 16; Result.Height := 16; LDensity := 0; end;
    4: begin Result.Width := 3; Result.Height := 255; LDensity := 60; end;
    5: begin Result.Width := 320; Result.Height := 20; LDensity := 50; end;
    6: begin Result.Width := 1; Result.Height := 40; LDensity := 50; end;
    7: begin Result.Width := 40; Result.Height := 1; LDensity := 50; end;
  else
    begin
      Result.Width := 2 + Next(60);
      Result.Height := 2 + Next(40);
      LDensity := Next(101);
    end;
  end;
  SetLength(Result.Pixels, Result.Width * Result.Height);
  for LIndex := 0 to Length(Result.Pixels) - 1 do
    if Next(100) < LDensity then
      Result.Pixels[LIndex] := Byte(1 + Next(255))
    else
      Result.Pixels[LIndex] := 0;
end;

class function TFontScenarios.WadCaseCount: Integer;
begin
  Result := 6;
end;

class function TFontScenarios.WadCase(AIndex: Integer): TWadCase;
begin
  Result.Scenario := 3 + (AIndex div 3) * 8;
  Result.Mode := AIndex mod 3;
  case Result.Mode of
    0:
      begin
        Result.Text := 'Hello World 12345';
        Result.Prefix := '';
      end;
    1:
      begin
        Result.Text := '';
        Result.Prefix := 'STCFN';
      end;
  else
    begin
      Result.Text := '';
      Result.Prefix := 'STTNUM';
    end;
  end;
end;

class function TFontScenarios.ExternalPaletteKindCount: Integer;
begin
  Result := Length(EXTERNAL_PALETTE_SIZES);
end;

class function TFontScenarios.ExternalPaletteFile(AKind: Integer): TArray<Byte>;
var
  LIndex: Integer;
begin
  SetLength(Result, EXTERNAL_PALETTE_SIZES[AKind]);
  for LIndex := 0 to Length(Result) - 1 do
    Result[LIndex] := Byte(LIndex * 7 + 3 + AKind * 11);
end;

end.
