{******************************************************************************}
{                                                                              }
{  DelphiDoom: dynamic lights library - the types of the model                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DynLights.Types;

interface

{$SCOPEDENUMS ON}

const
  /// <summary>The names of the lights are cut to this length (they were short strings)</summary>
  DYNLIGHT_NAME_LENGTH = 32;
  /// <summary>Tics per second: the intervals are kept in tics of 16.16 fixed point</summary>
  DYNLIGHT_TICRATE = 35;
  DYNLIGHT_FRACUNIT = 65536;

type
  /// <summary>The kinds of light of a GLDEFS or LIGHTDEF lump</summary>
  TDynLightKind = (Point, Flicker, Pulse);

  /// <summary>
  ///   What a light says in the definition. Colors are 0..1 (and more, nothing limits them),
  ///   sizes and offsets are in map units divided by the map coefficient the parser was given
  /// </summary>
  TDynLightDefinition = record
    Name: string;
    Kind: TDynLightKind;
    R1, G1, B1: Single;
    R2, G2, B2: Single;
    /// <summary>In tics of 16.16 fixed point; 0 if the light has none</summary>
    ColorInterval: Integer;
    /// <summary>0..255</summary>
    ColorChance: Integer;
    Size1: Single;
    /// <summary>The second size of flicker and pulse lights</summary>
    Size2: Single;
    Interval: Integer;
    Chance: Integer;
    OffsetX1, OffsetY1, OffsetZ1: Single;
    OffsetX2, OffsetY2, OffsetZ2: Single;
    RandomOffset: Boolean;
    /// <summary>Makes each light flicker or pulse out of step with the others</summary>
    RandomSeed: Integer;
  end;

  /// <summary>
  ///   What the renderer draws of a light at a given time. The renderers of the engine read it
  ///   with the field names of the old GLDRenderLight (r, g, b, radius, x, y, z, shadow), which
  ///   is now this record
  /// </summary>
  TDynLightRender = record
    R, G, B: Single;
    Radius: Single;
    X, Y, Z: Single;
    Shadow: Boolean;
  end;
  PDynLightRender = ^TDynLightRender;

implementation

end.
