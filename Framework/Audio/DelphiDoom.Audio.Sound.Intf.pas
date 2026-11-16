{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the tables of sounds and songs as the rules see  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Sound.Intf;

interface

type
  /// <summary>
  ///   Finds a lump by name: its number, or -1 if there is none (W_CheckNumForName of the
  ///   engine, given by the composition root)
  /// </summary>
  TSoundLumpFinder = reference to function(const AName: string): Integer;

  /// <summary>
  ///   The name of the lump of a sound from the name or the alias that a script gives (the
  ///   aliases of SNDINFO, given by the composition root); '0' if there is none
  /// </summary>
  TSoundNameResolver = reference to function(const AName: string): string;

  /// <summary>
  ///   The table of the sounds (S_sfx of sounddata.pas) as the number resolver reads it. The
  ///   table stays data of the engine and its record differs from game to game (Hexen has
  ///   a tag name and no link): every game gives its own table, with its loops. Other code
  ///   (Dehacked, ScriptHost, Radix) writes S_sfx directly, so nothing here is cached
  /// </summary>
  ISfxTable = interface
    ['{E41A9C07-3B58-4D26-9F70-A5C18D2E6B43}']
    /// <summary>The sounds in use (numsfx)</summary>
    function GetCount: Integer;
    procedure SetCount(AValue: Integer);
    /// <summary>The slots of the table (MAX_NUMSFX)</summary>
    function Capacity: Integer;
    /// <summary>The name of any slot below Capacity, as it is stored</summary>
    function NameOf(AIndex: Integer): string;
    /// <summary>The sound that stands for a missing one (the pistol, for Doom)</summary>
    function DefaultSfx: Integer;
    /// <summary>
    ///   True for the games with the numbers of DEHEXTRA and the free slots (Doom and the
    ///   games that use its tables)
    /// </summary>
    function HasDynamicSlots: Boolean;
    /// <summary>
    ///   The first slot from 1 to Count - 1 that the game accepts for the upper case name
    ///   (TSoundNames.SfxMatches, with the tag name for Hexen), -1 if there is none; the
    ///   loop is here, not one call per slot
    /// </summary>
    function FindByName(const AUpperName: string): Integer;
    /// <summary>The first slot from AFirst to Count - 1 without a name, -1 if there is none</summary>
    function FindEmptySlot(AFirst: Integer): Integer;
    /// <summary>
    ///   Writes a new sound in the slot with the values of a sound without lump (priority 72, no
    ///   pitch, no volume, no data, lump -1, no random list); ATagName is for the games that
    ///   have one
    /// </summary>
    procedure Define(AIndex: Integer; const AName, ATagName: string);
    property Count: Integer read GetCount write SetCount;
  end;

  /// <summary>The number of a sound from its name, and its name from its number (sounds.pas)</summary>
  ISfxNumberResolver = interface
    ['{7D26F0B9-48A3-4E15-B6C2-90E3A1D5F847}']
    /// <summary>S_GetSoundNumForName: a sound is registered if the table does not have it</summary>
    function NumberForName(const AName: string): Integer;
    /// <summary>S_GetSoundNameForNum: the name in upper case, '' if the number is out of the table</summary>
    function NameForNumber(ANumber: Integer): string;
  end;

  /// <summary>
  ///   The table of the songs (S_music of sounddata.pas) as the number resolver reads it.
  ///   The table stays data of the engine: the engine gives the slots, the rules are in
  ///   TMusicNumberResolver
  /// </summary>
  IMusicTable = interface
    ['{5C0E8A31-72D4-4B9F-A3E6-1D4F90B2C857}']
    /// <summary>The songs in use (nummusic)</summary>
    function GetCount: Integer;
    procedure SetCount(AValue: Integer);
    /// <summary>The slots of the table (MAX_MUS)</summary>
    function Capacity: Integer;
    /// <summary>
    ///   The first slot from 1 to Count - 1 that TSoundNames.MusicMatches accepts for the
    ///   upper case name, -1 if there is none; the loop is here, not one call per slot
    /// </summary>
    function FindByName(const AUpperName: string): Integer;
    /// <summary>Writes the name and the lump of a new song in the slot</summary>
    procedure Define(AIndex: Integer; const AName: string; ALumpNumber: Integer);
    property Count: Integer read GetCount write SetCount;
  end;

  /// <summary>The number of a song from its name or from its number as text (S_GetMusicNumForName)</summary>
  IMusicNumberResolver = interface
    ['{B2D74F16-9E30-4A85-8C1B-6F52E0A3D794}']
    function NumberForName(const AName: string): Integer;
  end;

implementation

end.
