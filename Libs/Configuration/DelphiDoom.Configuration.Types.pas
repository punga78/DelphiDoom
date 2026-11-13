{******************************************************************************}
{                                                                              }
{  DelphiDoom: configuration library - shared constants and exception          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Configuration.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The oldest version of the engine whose configuration file is still read</summary>
  CONFIGURATION_OLDEST_VERSION = 110;

  /// <summary>Who can change an option from the console: nobody (the DFS_NEVER of m_defs)</summary>
  CONFIGURATION_SET_NEVER = 0;
  /// <summary>The option can be changed in a game with one player (DFS_SINGLEPLAYER)</summary>
  CONFIGURATION_SET_SINGLEPLAYER = 1;
  /// <summary>The option can be changed in a network game (DFS_NETWORK)</summary>
  CONFIGURATION_SET_NETWORK = 2;
  /// <summary>The option can always be changed (DFS_ALWAYS)</summary>
  CONFIGURATION_SET_ALWAYS = 3;

type
  /// <summary>Raised for positions that do not exist</summary>
  EConfigurationException = class(Exception);

  /// <summary>
  ///   What a row of the table of the options holds (the ttype_t of m_defs): a text, a number,
  ///   a boolean, or the name of a group of the file
  /// </summary>
  TConfigurationItemKind = (cikString, cikInteger, cikBoolean, cikGroup);

  /// <summary>The values a row starts with (and goes back to with a reset)</summary>
  TConfigurationDefaults = record
    StringValue: string;
    IntegerValue: Integer;
    BooleanValue: Boolean;
  end;

implementation

end.
