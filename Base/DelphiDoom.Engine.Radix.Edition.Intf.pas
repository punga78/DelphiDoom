{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - which RADIX.DAT was loaded                             }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Radix.Edition.Intf;

interface

uses
  DelphiDoom.Radix.Editions;

type
  /// <summary>
  ///   The release of the RADIX.DAT that the engine has translated (shareware or registered,
  ///   1.0, 1.1 or 2.0), told by the CRC-32 of the file as the old fork did
  /// </summary>
  IEngineRadixEdition = interface
    ['{0D93B5A7-62E4-4C18-A7F0-9B315C2E84D6}']
    /// <summary>reUnknown until a RADIX.DAT is translated, and for a file that the table does not have</summary>
    function GetEdition: TRadixEdition;
    /// <summary>The CRC-32 of the last file translated; 0 when there is none</summary>
    function GetCrc32: Cardinal;
    property Edition: TRadixEdition read GetEdition;
    property Crc32: Cardinal read GetCrc32;
  end;

implementation

end.
