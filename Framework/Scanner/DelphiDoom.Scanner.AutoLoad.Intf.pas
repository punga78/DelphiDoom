{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the contracts of the AUTOLOAD lumps            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.AutoLoad.Intf;

interface

type
  /// <summary>The lumps of the loaded files, as the engine has them</summary>
  IAutoLoadLumps = interface
    ['{8A41D6C3-0E57-4B92-9F18-C3D7E2A5B064}']
    function GetCount: Integer;
    /// <summary>The name of a lump, in upper case</summary>
    function NameOf(AIndex: Integer): string;
    /// <summary>The text of a lump</summary>
    function TextOf(AIndex: Integer): string;
    property Count: Integer read GetCount;
  end;

  /// <summary>What happens to a file named by an AUTOLOAD lump: the engine adds it</summary>
  IAutoLoadFileSink = interface
    ['{2F9B7E05-D1A8-4C63-86E4-5A0C1B7D93F2}']
    procedure AddFile(const AFileName: string);
  end;

  /// <summary>Reads the AUTOLOAD lumps and gives their file names to the sink</summary>
  IAutoLoadReader = interface
    ['{B6E3A90D-47C1-4852-A7F6-E01D9C58B3A4}']
    /// <summary>
    ///   Every lump named AUTOLOAD, in order, is read as a list of file names (words and
    ///   texts between quotes; // comments); each name goes to the sink as soon as it is read
    /// </summary>
    procedure Load;
  end;

implementation

end.
