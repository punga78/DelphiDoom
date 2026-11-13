{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: the list of mods        }
{                                                                              }
{  Written from the description of idFileSystem::ListMods                      }
{  (framework\FileSystem.h); licensed under the GNU General Public License,    }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.ModList.Intf;

interface

uses
  DelphiDoom.Wad.Fs.Types;

type
  /// <summary>The mods the game finds on the disk (the game folders that hold at least one pak)</summary>
  IGameModLister = interface
    ['{3A91C6E4-0F27-4D58-B8E3-9C14A6D70B52}']
    /// <summary>
    ///   ListMods: the first entry is the base game (an empty name and its description), then the game folders
    ///   with paks, sorted without regard to case, each with the first line of its description.txt (or its own
    ///   name when it has none)
    /// </summary>
    function ListMods: TGameModList;
  end;

implementation

end.
