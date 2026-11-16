{******************************************************************************}
{                                                                              }
{  DelphiDoom: definitions library - contracts                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Definitions.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Definitions.Types;

type
  /// <summary>What the game has: ANIMDEFS ignores the animations of pictures it does not have</summary>
  IDefAnimNameCatalog = interface
    ['{5B1D7C42-93A6-4E08-B7F1-2C4A8E6D0953}']
    /// <summary>True if a lump with that name exists (the old test for the flats)</summary>
    function HasFlat(const AName: string): Boolean;
    /// <summary>True if a texture with that name exists</summary>
    function HasTexture(const AName: string): Boolean;
  end;

  /// <summary>Reads the text of an ANIMDEFS lump</summary>
  IDefAnimDefsParser = interface
    ['{E2A94F16-7D30-4B85-A1C9-60F3B8D2745E}']
    /// <summary>
    ///   The animations whose picture exists, in the order of the text. A text that the old
    ///   engine did not accept (too many animations or frames, an animation with less than
    ///   two frames) raises EDefinitionsException; the other problems are warnings to the log
    /// </summary>
    function Parse(const AText: string): TArray<TDefAnimation>;
  end;

  /// <summary>Reads a SWITCHES lump (the BOOM format)</summary>
  IDefSwitchLumpReader = interface
    ['{93C6E0B7-1A58-4D2F-8E74-B5D1F3A60C82}']
    /// <summary>
    ///   Every entry of the lump, also those after the entry that ends the table and the
    ///   terminator itself: the selector decides where the table stops
    /// </summary>
    function Read(const ABytes: TBytes): TArray<TDefSwitchPair>;
  end;

  /// <summary>The textures of the game</summary>
  IDefTextureLookup = interface
    ['{47F8A2D3-C0B1-4E96-95A7-1D6E3B8C2F04}']
    /// <summary>The number of the texture, or a negative number if there is none</summary>
    function CheckTextureNumForName(const AName: string): Integer;
  end;

  /// <summary>Chooses the pairs of a table that the game uses</summary>
  IDefSwitchSelector = interface
    ['{0D5B3E81-6F27-4C94-A8E0-39B7C1F5D246}']
    /// <summary>
    ///   Takes the entries up to the first one that ends the table (episode -1 or a pair
    ///   with an empty name), those whose episode is not above AMaxEpisode, and of these the
    ///   ones whose textures both exist. A texture that does not exist is a warning
    /// </summary>
    function Select(const ATable: TArray<TDefSwitchPair>; AMaxEpisode: Integer): TArray<TDefResolvedSwitch>;
  end;

  /// <summary>The terrain of the flats of a game</summary>
  IDefTerrainTable = interface
    ['{B8E1D045-2A9C-4F73-86D1-7C0E5A3B9F28}']
    /// <summary>The terrain of the flat (the case does not matter); Solid if the flat is not in the table</summary>
    function KindForName(const AFlatName: string): TDefTerrainKind;
    function Count: Integer;
    function Entry(AIndex: Integer): TDefTerrainEntry;
  end;

implementation

end.
