{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the types of the lights                      }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Light.Types;

{$SCOPEDENUMS ON}

interface

type
  /// <summary>The games that have lights; each one has its own rules and special numbers</summary>
  TLightGame = (Doom, Heretic, Hexen, Strife);

  /// <summary>
  ///   The kinds of light of the scripted specials (the old lighttype_t of udmf_lights): the order
  ///   is the one of the enumeration saved in the thinker, so Ord() converts between the two
  /// </summary>
  TLightKind = (
    RaiseByValue,
    LowerByValue,
    ChangeToValue,
    Fade,
    Glow,
    Flicker,
    Strobe,
    MaxNeighbor,
    MinNeighbor,
    StrobeDoom
  );

  /// <summary>The arguments 1 to 4 of a scripted light special (argument 0 is the tag)</summary>
  TLightArguments = record
    Arg1: Integer;
    Arg2: Integer;
    Arg3: Integer;
    Arg4: Integer;
  end;

  /// <summary>
  ///   What a scripted light keeps between two tics (the fields of light_t after the sector and
  ///   the kind). The meaning of each value depends on the kind
  /// </summary>
  TLightScriptedState = record
    Value1: Integer;
    Value2: Integer;
    Tics1: Integer;
    Tics2: Integer;
    Count: Integer;
  end;

  /// <summary>What the spawn of a scripted light did</summary>
  TLightScriptedOutcome = (
    /// <summary>The kind is not known: nothing was done and the special fails</summary>
    Invalid,
    /// <summary>The light level was changed at once: the special works and no thinker is needed</summary>
    Instant,
    /// <summary>The light changes in time: the engine makes a thinker with the returned state</summary>
    Thinker
  );

  /// <summary>
  ///   The numbers of the sectors that make a sequence of phased lights in a game: the special of
  ///   the first sector, of the two kinds that follow one another and the bits of the special that
  ///   mean "phased light"
  /// </summary>
  TLightSequenceProfile = record
    SequenceStart: Integer;
    Sequence: Integer;
    SequenceAlt: Integer;
    PhaseMask: Integer;
  end;

const
  /// <summary>One in fixed point (16.16)</summary>
  LIGHT_FRACUNIT = 65536;
  /// <summary>How much a glowing light changes in a tic (GLOWSPEED)</summary>
  LIGHT_GLOW_SPEED = 8;
  /// <summary>How long a strobe is bright (STROBEBRIGHT)</summary>
  LIGHT_STROBE_BRIGHT_TICS = 5;
  /// <summary>The steps of a phased light before it starts again</summary>
  LIGHT_PHASE_STEPS = 64;

implementation

end.
