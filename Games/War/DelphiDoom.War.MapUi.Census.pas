{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what the objectives count in the game in course   }
{                                                                              }
{  Port of war1 (acoto87/war1), war_units.c (wu_getTotalNumberOfUnits and the   }
{  other counts that war_campaigns.c reads), (c) 2019 Alejandro Coto Gutierrez, }
{  zlib License (see Games\War\LICENSE-war1.txt). This is an altered version,   }
{  not the original.                                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Census;

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Campaign.Intf, DelphiDoom.War.Model.Context;

type
  /// <summary>IWarCensus on the model of the game in course. Not counted by reference: the scene owns the model it reads</summary>
  TWarMapCensus = class(TInterfacedObject, IWarCensus)
  strict private
    FContext: TWarModelContext;
  public
    constructor Create(const AContext: TWarModelContext);
    function GetPlayerRace(APlayer: Integer): TWarRace;
    function GetBuildingsOfType(APlayer: Integer; AUnitType: Byte): Integer;
    function GetTotalUnits(APlayer: Integer): Integer;
    function GetTotalDudes(APlayer: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.War.Model.Types;

{ TWarMapCensus }

constructor TWarMapCensus.Create(const AContext: TWarModelContext);
begin
  inherited Create;
  FContext := AContext;
end;

function TWarMapCensus.GetPlayerRace(APlayer: Integer): TWarRace;
begin
  Result := FContext.Players[APlayer]^.Race;
end;

function TWarMapCensus.GetBuildingsOfType(APlayer: Integer; AUnitType: Byte): Integer;
begin
  Result := FContext.Queries.CountBuildingsOfType(APlayer, AUnitType, True);
end;

function TWarMapCensus.GetTotalUnits(APlayer: Integer): Integer;
var
  LUnits: TArray<Integer>;
  LIndex: Integer;
begin
  // wu_getTotalNumberOfUnits: every unit entity of the player
  Result := 0;
  LUnits := FContext.Pool.OfType[WAR_ENTITY_UNIT].ToArray;
  for LIndex := 0 to High(LUnits) do
    if FContext.Pool.Slots[LUnits[LIndex]]^.UnitData.Player = APlayer then
      Inc(Result);
end;

function TWarMapCensus.GetTotalDudes(APlayer: Integer): Integer;
begin
  Result := FContext.Queries.CountDudes(APlayer);
end;

end.
