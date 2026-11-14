{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what the gatherers tell the game around them      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Gather.Intf;

interface

uses
  DelphiDoom.War.Model.Types;

type
  /// <summary>
  ///   The sounds of the gatherers. The calls are rare (a blow of the axe each half second per chopper), never per tic
  ///   and unit. The collapse of an exhausted gold mine is told with IWarModelEvents.BuildingCollapsing
  /// </summary>
  IWarGatherEvents = interface
    ['{5D2C7E81-4B39-4A6F-9E10-83F4A7B6C2D5}']
    /// <summary>
    ///   An axe hits a tree at the position (pixels): wa_createAudioRandomWithPosition with WAR_TREE_CHOPPING_1 to 4
    /// </summary>
    procedure TreeChopped(const APosition: TWarVec2);
  end;

implementation

end.
