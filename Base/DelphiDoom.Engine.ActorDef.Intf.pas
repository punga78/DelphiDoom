{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the ACTORDEF, DECORATE and SNDINFO lumps                }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.ActorDef.Intf;

interface

type
  /// <summary>
  ///   Reads the ACTORDEF and DECORATE lumps (and the files of the PAKs with those names) with
  ///   the parser of Libs\ActorDef, and SNDINFO with the sound aliases. The composition root
  ///   gives it to the main loop of each game (d_main). It was the facade sc_actordef.pas
  /// </summary>
  IEngineActorDefLumps = interface
    ['{5C2E9A71-3B48-4D06-8F17-A9D6E30C4B85}']
    /// <summary>
    ///   The constants of the scripts and the console commands that print and save the
    ///   current tables (SC_Init)
    /// </summary>
    procedure Initialize;
    /// <summary>
    ///   Frees the names of the states and the constants (SC_ShutDown). The parser stays: an
    ///   I_Error inside a parse shuts the game down while the parser is still running
    /// </summary>
    procedure ShutDown;
    /// <summary>Every SNDINFO lump and file, in order, as one text (SC_ParseSndInfoLumps)</summary>
    procedure ParseSoundInfoLumps;
    /// <summary>
    ///   STATEDEF, then every ACTORDEF lump and, with decorate_as_actordef, every DECORATE lump;
    ///   then the files of the PAKs with those names (SC_ParseActordefLumps)
    /// </summary>
    procedure ParseActorDefLumps;
    /// <summary>One text of ACTORDEF (SC_ParseActordefLump): a thinker comes back here</summary>
    procedure ParseText(const AText: string);
  end;

implementation

end.
