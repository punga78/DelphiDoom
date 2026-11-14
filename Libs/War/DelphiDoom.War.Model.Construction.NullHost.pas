{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the default host of building and training          }
{                                                                              }
{  Port of war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Construction.NullHost;

interface

uses
  DelphiDoom.War.Model.Construction.Intf;

type
  /// <summary>
  ///   IWarConstructionHost for a game that does not draw or play: no image has frames, nobody listens to the sounds
  ///   and the whole map is known. It is what the model uses until the game gives its own
  /// </summary>
  TWarNullConstructionHost = class(TInterfacedObject, IWarConstructionHost)
  public
    function UnitFrames(AUnitType: Integer): Integer;
    function ConstructionFrames(AUnitType: Integer): Integer;
    procedure PlaySound(AAudioId: Integer);
    procedure PlayRandomSound(AFromId, AToId: Integer);
    procedure Acknowledge(APlayer: Integer);
    function IsTileKnown(ATileX, ATileY: Integer): Boolean;
  end;

  /// <summary>IWarOccupancyProbe of a grid that does not exist: every tile is empty and a unit stays where it is</summary>
  TWarNullOccupancyProbe = class(TInterfacedObject, IWarOccupancyProbe)
  public
    function IsEmpty(ATileX, ATileY: Integer): Boolean;
    procedure FindEmptyTile(ATileX, ATileY: Integer; out AFoundX, AFoundY: Integer);
  end;

implementation

{ TWarNullConstructionHost }

function TWarNullConstructionHost.UnitFrames(AUnitType: Integer): Integer;
begin
  Result := 0;
end;

function TWarNullConstructionHost.ConstructionFrames(AUnitType: Integer): Integer;
begin
  Result := 0;
end;

procedure TWarNullConstructionHost.PlaySound(AAudioId: Integer);
begin
end;

procedure TWarNullConstructionHost.PlayRandomSound(AFromId, AToId: Integer);
begin
end;

procedure TWarNullConstructionHost.Acknowledge(APlayer: Integer);
begin
end;

function TWarNullConstructionHost.IsTileKnown(ATileX, ATileY: Integer): Boolean;
begin
  Result := True;
end;

{ TWarNullOccupancyProbe }

function TWarNullOccupancyProbe.IsEmpty(ATileX, ATileY: Integer): Boolean;
begin
  Result := True;
end;

procedure TWarNullOccupancyProbe.FindEmptyTile(ATileX, ATileY: Integer; out AFoundX, AFoundY: Integer);
begin
  AFoundX := ATileX;
  AFoundY := ATileY;
end;

end.
