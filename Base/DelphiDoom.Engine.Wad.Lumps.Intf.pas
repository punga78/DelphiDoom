{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the lumps as the classes of the engine ask for them    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Wad.Lumps.Intf;

interface

type
  /// <summary>
  ///   What a class of the engine asks for the lumps of the loaded files: find one by name, its
  ///   length and bytes, its copy in the lump cache (lumpcache[], zone memory) and the
  ///   files that are added while the game runs. The classes receive one from the composition
  ///   root instead of calling the W_* functions of w_wad.pas. The directory exists only
  ///   after W_InitMultipleFiles: the answers always come from the files loaded at the
  ///   moment of the call. A lump that does not exist is an I_Error, as in the W_* functions
  /// </summary>
  IEngineLumps = interface
    ['{7A41C9E2-5D38-4B60-8F1A-23C6E0D95B74}']
    /// <summary>The number of lumps of the directory (W_NumLumps)</summary>
    function Count: Integer;
    /// <summary>The last lump with the name, -1 if there is none (W_CheckNumForName)</summary>
    function CheckNumForName(const AName: string; AFlags: LongWord = 0): Integer;
    /// <summary>As CheckNumForName, but a lump that is not there is an I_Error (W_GetNumForName)</summary>
    function GetNumForName(const AName: string; AFlags: LongWord = 0): Integer;
    /// <summary>The name of the lump, up to 8 characters (char8tostring of W_GetNameForNum)</summary>
    function NameOf(ALump: Integer): string;
    /// <summary>The length in bytes of the lump (W_LumpLength)</summary>
    function LengthOf(ALump: Integer): Integer;
    /// <summary>The CRC-32 of the lump in 8 hexadecimal digits (W_LumpCRC32)</summary>
    function Crc32Of(ALump: Integer): string;
    /// <summary>The lump as text, a #0 is a space (W_TextLumpNum)</summary>
    function TextOf(ALump: Integer): string;
    /// <summary>Reads the lump into ADestination, which must hold LengthOf(ALump) bytes (W_ReadLump)</summary>
    procedure Read(ALump: Integer; ADestination: Pointer);
    /// <summary>
    ///   The lump in the lump cache with the zone tag ATag; the block belongs to the zone and is
    ///   released with the allocator (W_CacheLumpNum)
    /// </summary>
    function Cache(ALump: Integer; ATag: Integer): Pointer;
    /// <summary>Adds a WAD file from disk to the directory while the game runs (W_RuntimeLoad)</summary>
    procedure RuntimeLoadFile(const AFileName: string);
    /// <summary>Flushes the reloadable lumps and reads their directory again (W_Reload)</summary>
    procedure Reload;
  end;

implementation

end.
