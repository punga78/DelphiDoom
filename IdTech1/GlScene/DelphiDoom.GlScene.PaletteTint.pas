{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL scene - the tint of the screen for a palette number      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlScene.PaletteTint;

interface

type
  /// <summary>The colour laid over the whole screen when the game asks for a palette (damage, pickup, radiation...)</summary>
  TGlScenePaletteTint = record
    Red: Single;
    Green: Single;
    Blue: Single;
    Alpha: Single;
  end;

  /// <summary>
  ///   What gld_SetPalette of gl_render.pas does when the video card has no shared texture palette: the palette
  ///   numbers of the game (1..8 red, 9..12 yellow, 13 green and in Hexen 14..20 green and 21 blue) become a
  ///   colour and an opacity, drawn over the screen at the end of the scene
  /// </summary>
  TGlScenePaletteTints = class sealed
  public
    /// <summary>
    ///   The tint of the palette: zero for the normal palette (0) and for numbers the game does not use; every
    ///   component is at most 1. AHexenPalettes turns on the two ranges that only Hexen has
    /// </summary>
    class function Compute(APalette: Integer; const AHexenPalettes: Boolean): TGlScenePaletteTint; static;
  end;

implementation

{ TGlScenePaletteTints }

class function TGlScenePaletteTints.Compute(APalette: Integer; const AHexenPalettes: Boolean): TGlScenePaletteTint;
begin
  Result.Red := 0.0;
  Result.Green := 0.0;
  Result.Blue := 0.0;
  Result.Alpha := 0.0;
  if APalette > 0 then
  begin
    if APalette <= 8 then
    begin
      Result.Red := APalette / 2.0;
      Result.Green := 0.0;
      Result.Blue := 0.0;
      Result.Alpha := APalette / 10.0;
    end
    else if APalette <= 12 then
    begin
      APalette := APalette - 8;
      Result.Red := APalette * 1.0;
      Result.Green := APalette * 0.8;
      Result.Blue := APalette * 0.1;
      Result.Alpha := APalette / 11.0;
    end
    else if APalette = 13 then
    begin
      Result.Red := 0.4;
      Result.Green := 1.0;
      Result.Blue := 0.0;
      Result.Alpha := 0.2;
    end
    else if AHexenPalettes and (APalette < 21) then
    begin
      APalette := APalette - 13;
      Result.Red := 0.0;
      Result.Green := APalette / 2.0;
      Result.Blue := 0.0;
      Result.Alpha := APalette / 10.0;
    end
    else if AHexenPalettes and (APalette = 21) then
    begin
      Result.Red := 0.0;
      Result.Green := 0.0;
      Result.Blue := 1.0;
      Result.Alpha := 0.8;
    end;
  end;
  if Result.Red > 1.0 then
    Result.Red := 1.0;
  if Result.Green > 1.0 then
    Result.Green := 1.0;
  if Result.Blue > 1.0 then
    Result.Blue := 1.0;
  if Result.Alpha > 1.0 then
    Result.Alpha := 1.0;
end;

end.
