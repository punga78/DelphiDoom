{******************************************************************************}
{                                                                              }
{  DelphiDoom: MUSINFO library - the contracts                                }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MusInfo.Intf;

interface

uses
  DelphiDoom.MusInfo.Types;

type
  /// <summary>The number the game gives to a music, by its name</summary>
  IMusInfoMusicResolver = interface
    ['{6B3E8D21-47A9-4F05-B2C8-91D4E7A03F56}']
    /// <param name="AUpperName">The name in upper case</param>
    /// <returns>The number, or a negative one if the game has no such music</returns>
    function MusicNumberFor(const AUpperName: string): Integer;
  end;

  /// <summary>Where the text of the MUSINFO lump comes from</summary>
  IMusInfoTextSource = interface
    ['{D17A5C94-3E62-4B80-A9F1-2C6B08E5D473}']
    /// <param name="AUpperName">The name of the lump, in upper case</param>
    /// <returns>False if no loaded file has such a lump</returns>
    function TryGetText(const AUpperName: string; out AText: string): Boolean;
  end;

  /// <summary>Reads the text of a MUSINFO lump: every line is an entry, nothing is looked up</summary>
  IMusInfoParser = interface
    ['{4F92B6E0-8D13-4C57-A3B9-E50A1D7C6842}']
    /// <returns>
    ///   The entries in the order of the text; MusicNumber is not set. The problems of the
    ///   text are warnings to the log, never exceptions
    /// </returns>
    function Parse(const AText: string): TArray<TMusInfoEntry>;
  end;

  /// <summary>The music of each (map, id) pair, as the game asks for it</summary>
  IMusInfoCatalog = interface
    ['{A85D3F17-6C20-49E4-8B71-F3D96E0A52C8}']
    /// <summary>
    ///   Adds an entry; one with the same map and id is replaced. The number of the music is
    ///   asked to the resolver, whatever AEntry.MusicNumber says
    /// </summary>
    /// <returns>False (and a warning) if the catalog is full</returns>
    function Add(const AEntry: TMusInfoEntry): Boolean;
    /// <summary>Forgets every entry</summary>
    procedure Clear;
    /// <param name="AMapName">Any case</param>
    /// <returns>The number of the music, or -1 if there is no such entry</returns>
    function Find(AMusicId: Integer; const AMapName: string): Integer;
    function Count: Integer;
    function GetEntry(AIndex: Integer): TMusInfoEntry;
  end;

  /// <summary>Reads the lump and fills the catalog (the old P_InitMusInfo)</summary>
  IMusInfoLoader = interface
    ['{19C7E4B8-A253-4D96-8F0E-7B3A6D1C5E92}']
    /// <summary>Does nothing if there is no MUSINFO lump; the catalog keeps what it had</summary>
    procedure Load;
  end;

implementation

end.
