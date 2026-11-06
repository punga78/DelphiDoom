{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the contracts                               }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Intf;

interface

uses
  DelphiDoom.MathCore.Types;

type
  /// <summary>Where the unpredictable numbers come from (the old I_Random used Random(256))</summary>
  IEntropySource = interface
    ['{2B7E4D19-5C83-4A06-9F31-8D52C1E7A640}']
    /// <summary>A number in 0..ARange-1</summary>
    function Next(ARange: Integer): Integer;
  end;

  /// <summary>
  ///   The random numbers of the game: tables with an index that the game saves and restores
  ///   (savegames, demos). The state is in the object, not in globals. All the numbers are in
  ///   0..255; the index is moved first, then the table is read (so a new object gives the
  ///   second number of the table first, as the old ones did)
  /// </summary>
  IGameRandom = interface
    ['{9A14C6F2-3E57-4B8D-A0C9-71D6E2B5F384}']
    /// <summary>The menu / presentation random (the old M_Random)</summary>
    function NextMenu: Integer;
    /// <summary>The play simulation random (the old P_Random)</summary>
    function NextPlay: Integer;
    /// <summary>As NextPlay, for the code that is not compatible with the old demos (the old N_Random)</summary>
    function NextNonCompatible: Integer;
    /// <summary>A really random number, not repeatable (the old I_Random)</summary>
    function NextUnpredictable: Integer;
    /// <summary>The 10007 numbers of the system table (the old Sys_Random)</summary>
    function NextSystem: Integer;
    /// <summary>The table with an index of the caller, which is moved (the old C_Random)</summary>
    function NextWithIndex(var AIndex: Integer): Integer;
    /// <summary>The number of the table for a seed, without moving any index (the old P_RandomFromSeed)</summary>
    function FromSeed(const ASeed: Integer): Integer;
    /// <summary>Back to the start of the table; forgets the saved indexes (the old M_ClearRandom)</summary>
    procedure Clear;
    /// <summary>Saves the play index (the old P_SaveRandom)</summary>
    procedure SavePlayIndex;
    /// <summary>Restores the last saved play index; False if there is none (the old P_RestoreRandom)</summary>
    function RestorePlayIndex: Boolean;
    /// <summary>A random angle in -spread..spread (degrees in fixed point), as an integer (the old P_RandomHitscanAngle)</summary>
    function HitscanAngle(const ASpread: TFixed): Integer;
    /// <summary>The same angle, as a slope (the old P_RandomHitscanSlope)</summary>
    function HitscanSlope(const ASpread: TFixed): Integer;

    function GetMenuIndex: Integer;
    procedure SetMenuIndex(const AValue: Integer);
    function GetPlayIndex: Integer;
    procedure SetPlayIndex(const AValue: Integer);
    function GetNonCompatibleIndex: Integer;
    procedure SetNonCompatibleIndex(const AValue: Integer);
    function GetSystemIndex: Integer;
    procedure SetSystemIndex(const AValue: Integer);
    function GetSystemSeed: Integer;
    procedure SetSystemSeed(const AValue: Integer);
    /// <summary>The indexes (the old rndindex, prndindex, nrndindex, sysrndindex, sysrndseed)</summary>
    property MenuIndex: Integer read GetMenuIndex write SetMenuIndex;
    property PlayIndex: Integer read GetPlayIndex write SetPlayIndex;
    property NonCompatibleIndex: Integer read GetNonCompatibleIndex write SetNonCompatibleIndex;
    property SystemIndex: Integer read GetSystemIndex write SetSystemIndex;
    property SystemSeed: Integer read GetSystemSeed write SetSystemSeed;
  end;

  /// <summary>
  ///   A table of integers addressed by the hash of a text (the old m_hash): the hash gives one
  ///   of 65536 places, a text with the same hash takes the place of the other
  /// </summary>
  IStringHashTable = interface
    ['{C3D8F5A1-6B42-4E97-8A1D-5F0E9B3C7D26}']
    /// <summary>The index stored for the hash of the text (0 if none)</summary>
    function IndexOf(const AText: string): Integer;
    /// <summary>Stores the index for the hash of the text</summary>
    procedure Update(const AText: string; const AIndex: Integer);
  end;

implementation

end.
