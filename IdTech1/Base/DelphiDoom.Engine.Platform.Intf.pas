{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - whole files for the demos, the saves and the scripts   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Platform.Intf;

{$I Doom32.inc}

interface

type
  /// <summary>
  ///   Writes, adds to and reads a whole file: the demos, the savegames of Strife and Hexen, the
  ///   globals of PascalScript, the lumps written by the console. A file read goes to the zone
  ///   memory (PU_STATIC), as the old M_ReadFile. The composition root gives it to the modules
  ///   that use it. It was the facade m_misc.pas
  /// </summary>
  IEngineFiles = interface
    ['{F4D1A6B8-2C73-4E05-9A61-B8E2C47D0F93}']
    /// <summary>Writes ALength bytes of ASource to the file (M_WriteFile); false if it fails</summary>
    function WriteFile(const AName: string; const ASource: Pointer; const ALength: Integer): Boolean;
    /// <summary>Adds ALength bytes of ASource at the end of the file (M_AppendFile); the bytes written</summary>
    function AppendFile(const AName: string; const ASource: Pointer; const ALength: Integer): Integer;
    /// <summary>
    ///   Reads the whole file in a new block of the zone memory, PU_STATIC (M_ReadFile); the
    ///   length of the file. A file that can not be read stops the game with I_Error
    /// </summary>
    function ReadFile(const AName: string; var ABuffer: Pointer): Integer;
  end;

implementation

end.
