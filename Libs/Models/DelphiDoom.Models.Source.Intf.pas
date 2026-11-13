{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - where the files of the models come from     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Source.Intf;

interface

type
  /// <summary>
  ///   Reads the file of a model or of an animation by its name. It replaces <c>fileSystem</c>
  ///   (idFileSystem::ReadFile with the time stamp): the adapter that goes through the file
  ///   system of the engine (issue 99) implements it; the tests use a list in memory.
  /// </summary>
  IModelFileSource = interface
    ['{3F6A81D5-0C94-4E27-B58B-7D2E91A4C6F0}']
    /// <summary>
    ///   The bytes of the file (an 8-bit string, as the files of the models are read) and its
    ///   time stamp; false when the file does not exist
    /// </summary>
    function ReadFile(const AName: AnsiString; out AData: AnsiString; out ATimeStamp: Int64): Boolean;
  end;

implementation

end.
