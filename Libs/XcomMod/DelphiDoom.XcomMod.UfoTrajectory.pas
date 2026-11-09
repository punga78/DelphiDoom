{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - the path of a UFO (UfoTrajectory)         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.UfoTrajectory;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>TrajectoryWaypoint: where a UFO goes, at what altitude and at what percentage of its speed</summary>
  TXcomTrajectoryWaypoint = record
    Zone: Cardinal;
    Altitude: Cardinal;
    Speed: Cardinal;
  end;

  /// <summary>
  ///   Represents a trajectory that a UFO can take, which is composed of a few waypoints. The numbers are 32 bit
  ///   (size_t of the Win32 build) and a negative number in the node wraps as it does in the C++
  /// </summary>
  TXcomUfoTrajectory = class
  public
    const
      RETALIATION_ASSAULT_RUN = '__RETALIATION_ASSAULT_RUN';
  strict private
    FId: string;
    FGroundTimer: Cardinal;
    FWaypoints: TArray<TXcomTrajectoryWaypoint>;
    class function ReadWaypoints(const ANode: IYamlNode;
      const ADefault: TArray<TXcomTrajectoryWaypoint>): TArray<TXcomTrajectoryWaypoint>; static;
  public
    constructor Create(const AId: string);
    procedure Load(const ANode: IYamlNode);
    property Id: string read FId;
    property GroundTimer: Cardinal read FGroundTimer;
    property Waypoints: TArray<TXcomTrajectoryWaypoint> read FWaypoints;
    function WaypointCount: Integer;
    /// <summary>applySpeedPercentage: the base speed scaled by the waypoint (the product wraps like an int)</summary>
    function ApplySpeedPercentage(AWaypoint: Integer; ABaseSpeed: Integer): Integer;
  end;

implementation

{ TXcomUfoTrajectory }

constructor TXcomUfoTrajectory.Create(const AId: string);
begin
  inherited Create;
  FId := AId;
  FGroundTimer := 5;
end;

class function TXcomUfoTrajectory.ReadWaypoints(const ANode: IYamlNode;
  const ADefault: TArray<TXcomTrajectoryWaypoint>): TArray<TXcomTrajectoryWaypoint>;
var
  LField, LItem: IYamlNode;
  LItems, LCells: TArray<IYamlNode>;
  LIndex: Integer;
begin
  LField := TXcomNodeReader.Field(ANode, 'waypoints');
  if not LField.IsDefined or not LField.IsSequence then
    Exit(ADefault);
  LItems := LField.Items;
  SetLength(Result, Length(LItems));
  for LIndex := 0 to High(LItems) do
  begin
    LItem := LItems[LIndex];
    // convert<TrajectoryWaypoint>::decode: a sequence of exactly three ints stored as size_t
    if not LItem.IsSequence or (LItem.Size <> 3) then
      raise EYamlBadConversion.Create(LItem.Mark, 'bad conversion');
    LCells := LItem.Items;
    Result[LIndex].Zone := Cardinal(LCells[0].AsInteger);
    Result[LIndex].Altitude := Cardinal(LCells[1].AsInteger);
    Result[LIndex].Speed := Cardinal(LCells[2].AsInteger);
  end;
end;

procedure TXcomUfoTrajectory.Load(const ANode: IYamlNode);
begin
  FId := TXcomNodeReader.ReadString(ANode, 'id', FId);
  FGroundTimer := TXcomNodeReader.ReadSize(ANode, 'groundTimer', FGroundTimer);
  FWaypoints := ReadWaypoints(ANode, FWaypoints);
end;

function TXcomUfoTrajectory.WaypointCount: Integer;
begin
  Result := Length(FWaypoints);
end;

function TXcomUfoTrajectory.ApplySpeedPercentage(AWaypoint, ABaseSpeed: Integer): Integer;
begin
  // baseSpeed * speed / 100 with an int and a size_t: the arithmetic is unsigned
  Result := Integer(Cardinal(Cardinal(ABaseSpeed) * FWaypoints[AWaypoint].Speed) div 100);
end;

end.
