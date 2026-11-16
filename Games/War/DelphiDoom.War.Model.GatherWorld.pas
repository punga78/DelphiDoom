{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the map that the gatherers work on                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.GatherWorld;

interface

uses
  DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Map.Forests, DelphiDoom.War.Model.Gather.Intf;

type
  /// <summary>
  ///   The parts of the game map that the states of the gatherers read and change: the occupation grid (where a unit
  ///   steps out of a mine or a town hall), the forests (the trees, felling) and the sounds. The grid and the forests are
  ///   the ones of the map and are not owned. A concrete class on purpose: the chopping state asks it for a tree at every
  ///   tic and a call through an interface per unit and tic is not allowed in the hot path
  /// </summary>
  TWarGatherWorld = class
  strict private
    FGrid: TWarPathGrid;
    FForests: TWarMapForests;
    FEvents: IWarGatherEvents;
  public
    /// <summary>Without events nobody hears the axes</summary>
    constructor Create(const AGrid: TWarPathGrid; const AForests: TWarMapForests; const AEvents: IWarGatherEvents = nil);
    property Grid: TWarPathGrid read FGrid;
    property Forests: TWarMapForests read FForests;
    property Events: IWarGatherEvents read FEvents;
  end;

implementation

uses
  DelphiDoom.War.Model.Gather.NullEvents;

{ TWarGatherWorld }

constructor TWarGatherWorld.Create(const AGrid: TWarPathGrid; const AForests: TWarMapForests;
  const AEvents: IWarGatherEvents);
begin
  inherited Create;
  FGrid := AGrid;
  FForests := AForests;
  if Assigned(AEvents) then
    FEvents := AEvents
  else
    FEvents := TWarNullGatherEvents.Create;
end;

end.
