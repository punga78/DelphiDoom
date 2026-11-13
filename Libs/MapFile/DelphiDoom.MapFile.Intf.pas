{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the contracts of the reader and the writer   }
{                                                                              }
{  Written for this library (the original has idMapFile::Parse and Write).     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Intf;

interface

uses
  DelphiDoom.MapFile.Map;

type
  /// <summary>Turns the text of a .map file into the model. The caller owns the map that is returned</summary>
  IMapFileReader = interface
    ['{4D7B2C1E-6A31-4E0B-9C52-7F3A18D0B601}']
    /// <summary>
    ///   Reads a file; the name does not need an extension. Unless <c>AIgnoreRegion</c> a
    ///   ".reg" file is tried before the ".map" file. nil if there is no file; a text that is
    ///   not valid raises EMapFileException
    /// </summary>
    function Parse(const AFileName: AnsiString; const AIgnoreRegion: Boolean = False;
      const AIsOsPath: Boolean = False): TMapFile;
    /// <summary>Reads a text that is already in memory; the name is only used in the messages</summary>
    function ParseText(const AText, AName: AnsiString): TMapFile;
  end;

  /// <summary>Turns the model into the text of a .map file (always the current version)</summary>
  IMapFileWriter = interface
    ['{4D7B2C1E-6A31-4E0B-9C52-7F3A18D0B602}']
    /// <summary>Writes the file with the extension given; false if the file cannot be written</summary>
    function Write(const AMap: TMapFile; const AFileName, AExtension: AnsiString): Boolean;
    /// <summary>The text that Write would write</summary>
    function ToText(const AMap: TMapFile): AnsiString;
  end;

implementation

end.
