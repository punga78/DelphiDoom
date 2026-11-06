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

type
  /// <summary>Raised for positions that do not exist</summary>
  EConfigurationException = class(Exception);

implementation

end.
