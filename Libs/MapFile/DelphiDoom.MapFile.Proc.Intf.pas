{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the contracts of the .proc reader and writer }
{                                                                              }
{  Written for this library (the original reads the file inside the renderer   }
{  and writes it inside dmap).                                                 }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.Intf;

interface

uses
  DelphiDoom.MapFile.Proc.ProcFile;

type
  /// <summary>Turns the text of a .proc file into the model. The caller owns the file that is returned</summary>
  IProcFileReader = interface
    ['{4D7B2C1E-6A31-4E0B-9C52-7F3A18D0B611}']
    /// <summary>
    ///   Reads "NAME.proc" (the extension of the name is replaced); nil if there is no file; a
    ///   text that is not valid raises EProcFileException
    /// </summary>
    function Parse(const AFileName: AnsiString): TProcFile;
    /// <summary>Reads a text that is already in memory; the name is only used in the messages</summary>
    function ParseText(const AText, AName: AnsiString): TProcFile;
  end;

  /// <summary>Turns the model into the text of a .proc file, in the format of dmap</summary>
  IProcFileWriter = interface
    ['{4D7B2C1E-6A31-4E0B-9C52-7F3A18D0B612}']
    /// <summary>Writes "NAME.proc"; false if the file cannot be written</summary>
    function Write(const AFile: TProcFile; const AFileName: AnsiString): Boolean;
    /// <summary>The text that Write would write</summary>
    function ToText(const AFile: TProcFile): AnsiString;
  end;

implementation

end.
