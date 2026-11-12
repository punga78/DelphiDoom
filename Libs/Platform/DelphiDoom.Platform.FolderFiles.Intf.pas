{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - files looked for in several folders: the      }
{  contract                                                                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.FolderFiles.Intf;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Platform.Types;

type
  /// <summary>
  ///   The files of a program that are read from a list of folders in order of priority (the data of a game in one
  ///   folder, a mod or the files taken out of the executable in another): a file is the one of the first folder
  ///   that has it. Names may use / or \ for the folders inside; the case of a name counts as much as it counts for
  ///   the file system (on Windows it does not)
  /// </summary>
  IFolderFiles = interface
    ['{2C7E15A9-6F43-4D80-B5E1-90A3D7C4F268}']
    /// <summary>The full path of the file in the first folder that has it; empty when no folder has it</summary>
    function Find(const AName: string): string;
    function Exists(const AName: string): Boolean;
    /// <summary>
    ///   A new stream to read the file, that the caller owns; EFolderFileException when no folder has the file or
    ///   it cannot be opened
    /// </summary>
    function OpenStream(const AName: string): TStream;
    /// <summary>The whole file; EFolderFileException when no folder has it or it cannot be read</summary>
    function ReadAll(const AName: string): TBytes;
  end;

  /// <summary>A file that no folder has, or that could not be read</summary>
  EFolderFileException = class(EPlatformException);

implementation

end.
