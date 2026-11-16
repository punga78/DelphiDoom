{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the model without a game around it                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.NullServices;

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Intf;

type
  /// <summary>IWarModelEvents that does nothing (the default when nobody listens)</summary>
  TWarNullModelEvents = class(TInterfacedObject, IWarModelEvents)
  public
    procedure FlashStatus(AMessage: TWarStatusMessage);
    procedure EntityLeftSelection(AEntityId: Word);
    procedure UnitDied(AEntityId: Word; AUnitType: Integer; const APosition: TWarVec2);
    procedure BuildingCollapsing(AEntityId: Word; AUnitType: Integer; const APosition: TWarVec2);
    procedure BuildingDamaged(AEntityId: Word; AHpPercent: Integer);
  end;

  /// <summary>IWarOccupancy that does nothing</summary>
  TWarNullOccupancy = class(TInterfacedObject, IWarOccupancy)
  public
    procedure SetStaticEntity(AStartX, AStartY, AWidth, AHeight: Integer; AId: Word);
    procedure SetFreeTiles(AStartX, AStartY, AWidth, AHeight: Integer);
  end;

implementation

{ TWarNullModelEvents }

procedure TWarNullModelEvents.FlashStatus(AMessage: TWarStatusMessage);
begin
end;

procedure TWarNullModelEvents.EntityLeftSelection(AEntityId: Word);
begin
end;

procedure TWarNullModelEvents.UnitDied(AEntityId: Word; AUnitType: Integer; const APosition: TWarVec2);
begin
end;

procedure TWarNullModelEvents.BuildingCollapsing(AEntityId: Word; AUnitType: Integer; const APosition: TWarVec2);
begin
end;

procedure TWarNullModelEvents.BuildingDamaged(AEntityId: Word; AHpPercent: Integer);
begin
end;

{ TWarNullOccupancy }

procedure TWarNullOccupancy.SetStaticEntity(AStartX, AStartY, AWidth, AHeight: Integer; AId: Word);
begin
end;

procedure TWarNullOccupancy.SetFreeTiles(AStartX, AStartY, AWidth, AHeight: Integer);
begin
end;

end.
