{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the occupation grid of the map for the model      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.GridOccupancy;

interface

uses
  System.Types, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.Construction.Intf;

type
  /// <summary>
  ///   IWarOccupancy over the TWarPathGrid of a game map (the grid is not owned); it also answers which tile is free
  ///   and where the nearest free one is (IWarOccupancyProbe), which building and training ask when a unit comes out
  /// </summary>
  TWarGridOccupancy = class(TInterfacedObject, IWarOccupancy, IWarOccupancyProbe)
  strict private
    FGrid: TWarPathGrid;
  public
    constructor Create(const AGrid: TWarPathGrid);
    procedure SetStaticEntity(AStartX, AStartY, AWidth, AHeight: Integer; AId: Word);
    procedure SetFreeTiles(AStartX, AStartY, AWidth, AHeight: Integer);
    function IsEmpty(ATileX, ATileY: Integer): Boolean;
    procedure FindEmptyTile(ATileX, ATileY: Integer; out AFoundX, AFoundY: Integer);
  end;

implementation

{ TWarGridOccupancy }

constructor TWarGridOccupancy.Create(const AGrid: TWarPathGrid);
begin
  inherited Create;
  FGrid := AGrid;
end;

procedure TWarGridOccupancy.SetStaticEntity(AStartX, AStartY, AWidth, AHeight: Integer; AId: Word);
begin
  FGrid.SetStaticEntity(AStartX, AStartY, AWidth, AHeight, AId);
end;

procedure TWarGridOccupancy.SetFreeTiles(AStartX, AStartY, AWidth, AHeight: Integer);
begin
  FGrid.SetFreeTiles(AStartX, AStartY, AWidth, AHeight);
end;

function TWarGridOccupancy.IsEmpty(ATileX, ATileY: Integer): Boolean;
begin
  Result := FGrid.IsEmpty(ATileX, ATileY);
end;

procedure TWarGridOccupancy.FindEmptyTile(ATileX, ATileY: Integer; out AFoundX, AFoundY: Integer);
var
  LFound: TPoint;
begin
  LFound := FGrid.FindEmptyTile(ATileX, ATileY);
  AFoundX := LFound.X;
  AFoundY := LFound.Y;
end;

end.
