{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what is around a sector, for the platforms             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Plat.Surroundings;

interface

uses
  DelphiDoom.Thinkers.Platform.Intf;

type
  /// <summary>
  ///   Answers the platforms about a sector of the level (the handle is a Psector_t): the floors
  ///   around it, its heights, its floor picture and its type. It writes in the sector itself
  /// </summary>
  TEnginePlatSurroundings = class(TInterfacedObject, IPlatSurroundings)
  public
    function LowestFloorSurrounding(ASector: Pointer): Integer;
    function HighestFloorSurrounding(ASector: Pointer): Integer;
    function NextHighestFloor(ASector: Pointer; AHeight: Integer): Integer;
    function GetFloorHeight(ASector: Pointer): Integer;
    function GetCeilingHeight(ASector: Pointer): Integer;
    procedure SetFloorPicture(ASector: Pointer; APicture: Integer);
    procedure ClearSpecial(ASector: Pointer);
  end;

implementation

uses
  r_defs,
  p_spec;

{ TEnginePlatSurroundings }

function TEnginePlatSurroundings.LowestFloorSurrounding(ASector: Pointer): Integer;
begin
  Result := P_FindLowestFloorSurrounding(Psector_t(ASector));
end;

function TEnginePlatSurroundings.HighestFloorSurrounding(ASector: Pointer): Integer;
begin
  Result := P_FindHighestFloorSurrounding(Psector_t(ASector));
end;

function TEnginePlatSurroundings.NextHighestFloor(ASector: Pointer; AHeight: Integer): Integer;
begin
  Result := P_FindNextHighestFloor(Psector_t(ASector), AHeight);
end;

function TEnginePlatSurroundings.GetFloorHeight(ASector: Pointer): Integer;
begin
  Result := Psector_t(ASector).floorheight;
end;

function TEnginePlatSurroundings.GetCeilingHeight(ASector: Pointer): Integer;
begin
  Result := Psector_t(ASector).ceilingheight;
end;

procedure TEnginePlatSurroundings.SetFloorPicture(ASector: Pointer; APicture: Integer);
begin
  Psector_t(ASector).floorpic := SmallInt(APicture);
end;

procedure TEnginePlatSurroundings.ClearSpecial(ASector: Pointer);
begin
  Psector_t(ASector).special := 0;
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  // Heretic and Hexen sectors have no old special
  Psector_t(ASector).oldspecial := 0;
{$IFEND}
end;

end.
