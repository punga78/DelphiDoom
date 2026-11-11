{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - an action of a unit (BattleAction)    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Action;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Types,
  DelphiDoom.XcomBattle.Model;

type
  /// <summary>
  ///   What a unit is about to do or doing: the type (BA_*), the actor, the weapon, the target, the waypoints of a
  ///   missile and the result text (BattleAction). The C++ passes it by value or by reference; here it is a class
  ///   that owns only its waypoint list: the actor and the weapon belong to the saved battle
  /// </summary>
  TXcomBattleAction = class
  strict private
    FWaypoints: TList<TXcomPosition>;
  public
    ActionType: Integer;
    Actor: TXcomBattleUnit;
    Weapon: TXcomBattleItem;
    Target: TXcomPosition;
    TimeUnits: Integer;
    Targeting: Boolean;
    Value: Integer;
    ResultText: string;
    Strafe: Boolean;
    Run: Boolean;
    Diff: Integer;
    AutoShotCounter: Integer;
    CameraPosition: TXcomPosition;
    /// <summary>Ignoring newly spotted units</summary>
    Desperate: Boolean;
    FinalFacing: Integer;
    FinalAction: Boolean;
    /// <summary>First action of the turn, second, and so on</summary>
    Number: Integer;
    constructor Create;
    destructor Destroy; override;
    /// <summary>Copies every field of another action (the C++ copy of a BattleAction)</summary>
    procedure Assign(const ASource: TXcomBattleAction);
    property Waypoints: TList<TXcomPosition> read FWaypoints;
  end;

implementation

{ TXcomBattleAction }

constructor TXcomBattleAction.Create;
begin
  inherited Create;
  FWaypoints := TList<TXcomPosition>.Create;
  ActionType := BA_NONE;
  CameraPosition := TXcomPosition.Make(0, 0, -1);
  FinalFacing := -1;
end;

destructor TXcomBattleAction.Destroy;
begin
  FWaypoints.Free;
  inherited Destroy;
end;

procedure TXcomBattleAction.Assign(const ASource: TXcomBattleAction);
begin
  ActionType := ASource.ActionType;
  Actor := ASource.Actor;
  Weapon := ASource.Weapon;
  Target := ASource.Target;
  FWaypoints.Clear;
  FWaypoints.AddRange(ASource.FWaypoints);
  TimeUnits := ASource.TimeUnits;
  Targeting := ASource.Targeting;
  Value := ASource.Value;
  ResultText := ASource.ResultText;
  Strafe := ASource.Strafe;
  Run := ASource.Run;
  Diff := ASource.Diff;
  AutoShotCounter := ASource.AutoShotCounter;
  CameraPosition := ASource.CameraPosition;
  Desperate := ASource.Desperate;
  FinalFacing := ASource.FinalFacing;
  FinalAction := ASource.FinalAction;
  Number := ASource.Number;
end;

end.
