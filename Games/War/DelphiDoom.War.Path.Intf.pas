{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - who makes the flow fields                          }
{                                                                              }
{  Port of war1 (acoto87/war1), war_pathfinder.c (wpath_computeFlowField), (c)  }
{  2019 Alejandro Coto Gutierrez, zlib License (see Games\War\LICENSE-war1.txt). }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Path.Intf;

interface

uses
  DelphiDoom.War.Path.FlowField;

type
  /// <summary>
  ///   The one thing the debug drawing of the flow field asks of the movement: the field of a goal tile, made again (as
  ///   wpath_computeFlowField does: the field that the units keep for that goal is the same object, and it changes)
  /// </summary>
  IWarFlowFieldSource = interface
    ['{6E1B8D34-5A92-4C07-B8F3-0D2A7E94C615}']
    /// <summary>wpath_computeFlowField; EWarException for a tile outside the map</summary>
    function ComputeFlowField(ATileX, ATileY: Integer): TWarFlowField;
  end;

implementation

end.
