{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - a fixed waypoint on the globe         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Waypoint;

interface

uses
  DelphiDoom.XcomSave.Target;

type
  /// <summary>Waypoint: a fixed point on the world chosen by the player</summary>
  TXcomWaypoint = class(TXcomTarget)
  public
    /// <summary>STR_WAY_POINT</summary>
    function TargetType: string; override;
    /// <summary>The globe marker: 6</summary>
    function Marker: Integer; override;
  end;

implementation

{ TXcomWaypoint }

function TXcomWaypoint.TargetType: string;
begin
  Result := 'STR_WAY_POINT';
end;

function TXcomWaypoint.Marker: Integer;
begin
  Result := 6;
end;

end.
