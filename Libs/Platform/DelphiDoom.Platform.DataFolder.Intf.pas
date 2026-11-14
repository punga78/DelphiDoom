{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the folder of the data of a program: the      }
{  contract                                                                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.DataFolder.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Platform.Types;

type
  /// <summary>
  ///   What the locator asks the disk: the only part of it that touches the file system, so that the rules are
  ///   tried with a fake in the tests
  /// </summary>
  IDataFolderProbe = interface
    ['{5B0E8D41-3A92-4C67-9F14-D2A86E7C3B15}']
    /// <summary>True when the folder exists</summary>
    function FolderExists(const AFolder: string): Boolean;
    /// <summary>
    ///   True when the folder has the files of a game (a WAD, a PK3, a system WAD, an ini file or the folder DATA)
    /// </summary>
    function HasGameFiles(const AFolder: string): Boolean;
    /// <summary>The full path of a folder given as the user wrote it, relative to the current folder</summary>
    function FullPath(const AFolder: string): string;
  end;

  /// <summary>
  ///   Where a program finds its data. The executables are built in bin\Platform\Configuration\Area (so that Debug and
  ///   Release, 32 and 64 bit never share a file), while the data of the games (WAD, ini, DATA, saves, logs) stay in
  ///   bin\Area: they are not copied for every combination
  /// </summary>
  IDataFolderLocator = interface
    ['{8C3F6A12-D705-4E98-B1C4-7A5E09D2F683}']
    /// <summary>
    ///   The folder the program works in, with the last backslash. The order: the folder the user asked for
    ///   (ARequestedFolder, the option -data), the folder of the executable when it has the files of a game, the
    ///   folder bin\Area when the executable is in bin\Platform\Configuration\Area, the folder of the executable.
    ///   EDataFolderException when the folder that was asked for does not exist
    /// </summary>
    function Locate(const AExecutableFolder, ARequestedFolder: string): string;
  end;

  /// <summary>The folder asked for with -data does not exist</summary>
  EDataFolderException = class(EPlatformException);

implementation

end.
