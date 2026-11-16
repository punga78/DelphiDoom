{******************************************************************************}
{                                                                              }
{  DelphiDoom: definitions library - the types of the model                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Definitions.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The longest name of a texture or of a flat in a SWITCHES lump</summary>
  DEFINITIONS_NAME_LENGTH = 8;
  /// <summary>The old engine stopped at this number of animations of ANIMDEFS</summary>
  DEFINITIONS_MAX_ANIMATIONS = 128;
  /// <summary>The old engine stopped at this number of frames (all the animations together)</summary>
  DEFINITIONS_MAX_FRAMES = 512;
  DEFINITIONS_FRACUNIT = 65536;

type
  /// <summary>The games that have a table of switches and of terrains of their own</summary>
  TDefGame = (Doom, Heretic, Hexen, Strife);

  /// <summary>A text that the old engine did not accept: it stopped with I_Error</summary>
  EDefinitionsException = class(Exception);

  /// <summary>What an animation of ANIMDEFS animates</summary>
  TDefAnimKind = (Flat, Texture);

  /// <summary>
  ///   One "pic" line of an animation. The picture is the first one of the animation plus
  ///   PicNumber - 1 (the engine knows the numbers of the textures and flats)
  /// </summary>
  TDefAnimFrame = record
    PicNumber: Integer;
    /// <summary>The tics, or the minimum of "rand" when IsRandom</summary>
    Tics: Integer;
    IsRandom: Boolean;
    RandomMax: Integer;
    /// <summary>
    ///   The tics as the old engine kept them: for "rand" the minimum in the high word and
    ///   the size of the range times 256 (so a plain "tics" above 255 reads as a random one:
    ///   an old defect that the animation code of the engine relies on)
    /// </summary>
    function PackedTics: Integer;
  end;

  /// <summary>An animation of ANIMDEFS whose name exists in the game</summary>
  TDefAnimation = record
    Kind: TDefAnimKind;
    Name: string;
    Frames: TArray<TDefAnimFrame>;
    /// <summary>
    ///   The pictures that the old engine added to the lists of the animated flats or
    ///   textures, as differences from the first one: 0 for the first, PicNumber - 1 for
    ///   each "pic" line (also for the lines that were not kept as frames)
    /// </summary>
    AnimatedOffsets: TArray<Integer>;
  end;

  /// <summary>A pair of textures of a switch: off and on</summary>
  TDefSwitchPair = record
    Name1: string;
    Name2: string;
    /// <summary>1 shareware, 2 registered, 3 Doom II (-1 ends the table)</summary>
    Episode: SmallInt;
    /// <summary>The sound of the SWITCHES lump of Strife; 0 for the other tables</summary>
    Sound: Integer;
    /// <summary>The sound of the compiled tables of Hexen and Strife, as the engine calls it</summary>
    SoundName: string;
  end;

  /// <summary>A pair of the table that the engine can use: both the textures were found</summary>
  TDefResolvedSwitch = record
    Pair: TDefSwitchPair;
    Texture1: Integer;
    Texture2: Integer;
  end;

  /// <summary>
  ///   The kind of floor, in neutral words: each game numbers its own FLOOR_* constants
  ///   (Hexen also has a liquid in its list that no flat of the table uses)
  /// </summary>
  TDefTerrainKind = (Solid, Water, Lava, Sludge, Nukage, Ice);

  /// <summary>The terrain of a flat</summary>
  TDefTerrainEntry = record
    Name: string;
    Kind: TDefTerrainKind;
  end;

implementation

{ TDefAnimFrame }

function TDefAnimFrame.PackedTics: Integer;
begin
  if IsRandom then
    Result := (Tics * DEFINITIONS_FRACUNIT) + ((RandomMax - Tics + 1) * 256)
  else
    Result := Tics;
end;

end.
