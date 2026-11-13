{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the contract of the .aas reader              }
{                                                                              }
{  Written for this library (the original loads the file in idAASFileLocal).   }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.Intf;

interface

uses
  DelphiDoom.MapFile.Aas.AasFile;

type
  /// <summary>Turns the text of an .aas file into the model. The caller owns the file that is returned</summary>
  IAasFileReader = interface
    ['{4D7B2C1E-6A31-4E0B-9C52-7F3A18D0B621}']
    /// <summary>
    ///   Reads the file with the name given (the extension is part of the name: "aas48", "aas32"
    ///   or whatever the settings say). nil if there is no file. With a <c>ACrc</c> other than 0
    ///   the CRC of the map in the file must be the same, or EAasFileOutOfDateException is raised
    ///   (idAASFileLocal::Load returns false and warns). A text that is not valid raises
    ///   EAasFileException
    /// </summary>
    function Parse(const AFileName: AnsiString; const ACrc: Cardinal = 0): TAasFile;
    /// <summary>Reads a text that is already in memory; the name is only used in the messages</summary>
    function ParseText(const AText, AName: AnsiString; const ACrc: Cardinal = 0): TAasFile;
  end;

implementation

end.
