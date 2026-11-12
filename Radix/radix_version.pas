{******************************************************************************}
{                                                                              }
{  DelphiDoom: Radix game - the release of RADIX.DAT in use                    }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of radix_version.pas of Rad-X: the table of the CRC-32 is              }
{  TRadixEditions of Libs\Radix, the file is the one the engine translated     }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}

unit radix_version;

interface

uses
  doomdef,
  DelphiDoom.Radix.Editions,
  DelphiDoom.Engine.Radix.Edition.Intf;

//==============================================================================
//
// RX_ConfigureVersion
// Gives the unit who knows which RADIX.DAT was translated. The composition root
// calls it; without it the functions below are an I_Error
//
//==============================================================================
procedure RX_ConfigureVersion(const AEdition: IEngineRadixEdition);

//==============================================================================
//
// RX_RadixVersion
// The release of the RADIX.DAT that was loaded (radixversion of Rad-X)
//
//==============================================================================
function RX_RadixVersion: TRadixEdition;

//==============================================================================
//
// RX_GameMode
// shareware or registered; indetermined for a file that the table does not have
// (RX_GameModeFromCrc32 of Rad-X)
//
//==============================================================================
function RX_GameMode: GameMode_t;

//==============================================================================
//
// RX_VersionString
//
//==============================================================================
function RX_VersionString: string;

implementation

uses
  i_system;

var
  radix_edition: IEngineRadixEdition = nil;

//==============================================================================
//
// RX_ConfigureVersion
//
//==============================================================================
procedure RX_ConfigureVersion(const AEdition: IEngineRadixEdition);
begin
  radix_edition := AEdition;
end;

//==============================================================================
//
// RX_RadixVersion
//
//==============================================================================
function RX_RadixVersion: TRadixEdition;
begin
  if not Assigned(radix_edition) then
    I_Error('RX_RadixVersion(): RX_ConfigureVersion was not called');
  result := radix_edition.Edition;
end;

//==============================================================================
//
// RX_GameMode
//
//==============================================================================
function RX_GameMode: GameMode_t;
var
  edition: TRadixEdition;
begin
  edition := RX_RadixVersion;
  if not TRadixEditions.IsKnown(edition) then
    result := indetermined
  else if TRadixEditions.IsRegistered(edition) then
    result := registered
  else
    result := shareware;
end;

//==============================================================================
//
// RX_VersionString
//
//==============================================================================
function RX_VersionString: string;
begin
  result := TRadixEditions.Title(RX_RadixVersion);
end;

end.
