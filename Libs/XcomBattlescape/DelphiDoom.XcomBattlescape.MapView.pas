{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape drawing library - the view of the game in       }
{  progress on the map (what BattlescapeGame asks of Map and Camera)            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattlescape.MapView;

interface

uses
  DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.View.Intf,
  DelphiDoom.XcomBattlescape.Map;

type
  /// <summary>
  ///   IXcomBattleView for a game that draws: the calls about the camera, the cursor and the drawings of the
  ///   units go to the map; the rest (messages, sounds, the screens of the turns, the explosions and the
  ///   projectiles that the map does not draw yet) to another view, given by the owner
  /// </summary>
  TXcomBattleMapView = class(TInterfacedObject, IXcomBattleView)
  strict private
    FMap: TXcomBattleMap;
    FOther: IXcomBattleView;
  public
    /// <param name="AMap">The map (not owned)</param>
    /// <param name="AOther">The view that gets what the map does not draw</param>
    constructor Create(const AMap: TXcomBattleMap; const AOther: IXcomBattleView);
    procedure Warning(const AMessage: string);
    procedure Debug(const AMessage: string);
    procedure UpdateSoldierInfo;
    procedure CenterOnPosition(const APosition: TXcomPosition; AGraphic: Boolean = True);
    procedure SetViewLevel(ALevel: Integer);
    function IsOnScreen(const APosition: TXcomPosition; AUnitWalking: Boolean; AUnitSize: Integer;
      ABoundary: Boolean): Boolean;
    procedure CacheUnits;
    procedure CacheUnit(const AUnit: TXcomBattleUnit);
    procedure SetStateInterval(AMilliseconds: Integer);
    procedure ShowPsiButton(AShow: Boolean);
    procedure ShowLaunchButton(AShow: Boolean);
    procedure SetUnitDying(ADying: Boolean);
    procedure SetCursorType(ACursorType: Integer; ASize: Integer = 1);
    procedure PlaySound(ASound: Integer; const APosition: TXcomPosition);
    procedure AddExplosion(const ACenter: TXcomPosition; AStartFrame, AFrameDelay: Integer; ABig, AHit: Boolean);
    procedure AddVaporCloud(const AVoxel: TXcomPosition; ADensity, AColor: Integer);
    procedure ResetObstacles;
    procedure EnableObstacles;
    procedure DisableObstacles;
    procedure SetProjectile(const AProjectile: TObject);
    procedure SetBlastFlash(AFlash: Boolean);
    function BlastFlash: Boolean;
    function AnimateExplosions: Boolean;
    procedure SoldierKilled(const AUnit: TXcomBattleUnit);
    procedure ShowUnitMessage(const AUnit: TXcomBattleUnit; const AMessage: string; ANeedsConfirmation: Boolean);
    procedure FinishBattle(AAbort: Boolean; AInExitArea: Integer);
    procedure NextTurn;
    procedure ShowCursor(AVisible: Boolean);
    function CameraOffset: TXcomPosition;
    procedure SetCameraOffset(const AOffset: TXcomPosition);
    procedure AddWaypoint(const APosition: TXcomPosition);
    procedure RemoveLastWaypoint;
    procedure ClearWaypoints;
    procedure ShowUnitInfo(const AUnit: TXcomBattleUnit);
  end;

implementation

constructor TXcomBattleMapView.Create(const AMap: TXcomBattleMap; const AOther: IXcomBattleView);
begin
  inherited Create;
  FMap := AMap;
  FOther := AOther;
end;

procedure TXcomBattleMapView.Warning(const AMessage: string);
begin
  FOther.Warning(AMessage);
end;

procedure TXcomBattleMapView.Debug(const AMessage: string);
begin
  FOther.Debug(AMessage);
end;

procedure TXcomBattleMapView.UpdateSoldierInfo;
begin
  FOther.UpdateSoldierInfo;
end;

procedure TXcomBattleMapView.CenterOnPosition(const APosition: TXcomPosition; AGraphic: Boolean);
begin
  FMap.Camera.CenterOnPosition(APosition);
  FOther.CenterOnPosition(APosition, AGraphic);
end;

procedure TXcomBattleMapView.SetViewLevel(ALevel: Integer);
begin
  FMap.Camera.SetViewLevel(ALevel);
  FOther.SetViewLevel(ALevel);
end;

function TXcomBattleMapView.IsOnScreen(const APosition: TXcomPosition; AUnitWalking: Boolean; AUnitSize: Integer;
  ABoundary: Boolean): Boolean;
begin
  Result := FMap.Camera.IsOnScreen(APosition, AUnitWalking, AUnitSize, ABoundary);
end;

procedure TXcomBattleMapView.CacheUnits;
begin
  FMap.CacheUnits;
end;

procedure TXcomBattleMapView.CacheUnit(const AUnit: TXcomBattleUnit);
begin
  FMap.CacheUnit(AUnit);
end;

procedure TXcomBattleMapView.SetStateInterval(AMilliseconds: Integer);
begin
  FOther.SetStateInterval(AMilliseconds);
end;

procedure TXcomBattleMapView.ShowPsiButton(AShow: Boolean);
begin
  FOther.ShowPsiButton(AShow);
end;

procedure TXcomBattleMapView.ShowLaunchButton(AShow: Boolean);
begin
  FOther.ShowLaunchButton(AShow);
end;

procedure TXcomBattleMapView.SetUnitDying(ADying: Boolean);
begin
  FMap.UnitDying := ADying;
  FOther.SetUnitDying(ADying);
end;

procedure TXcomBattleMapView.SetCursorType(ACursorType, ASize: Integer);
begin
  FMap.SetCursorType(ACursorType, ASize);
end;

procedure TXcomBattleMapView.PlaySound(ASound: Integer; const APosition: TXcomPosition);
begin
  FOther.PlaySound(ASound, APosition);
end;

procedure TXcomBattleMapView.AddExplosion(const ACenter: TXcomPosition; AStartFrame, AFrameDelay: Integer; ABig,
  AHit: Boolean);
begin
  FOther.AddExplosion(ACenter, AStartFrame, AFrameDelay, ABig, AHit);
end;

procedure TXcomBattleMapView.AddVaporCloud(const AVoxel: TXcomPosition; ADensity, AColor: Integer);
begin
  FMap.AddVaporCloud(AVoxel, ADensity, AColor);
end;

procedure TXcomBattleMapView.ResetObstacles;
begin
  FMap.ResetObstacles;
end;

procedure TXcomBattleMapView.EnableObstacles;
begin
  FMap.EnableObstacles;
end;

procedure TXcomBattleMapView.DisableObstacles;
begin
  FMap.DisableObstacles;
end;

procedure TXcomBattleMapView.SetProjectile(const AProjectile: TObject);
begin
  FOther.SetProjectile(AProjectile);
end;

procedure TXcomBattleMapView.SetBlastFlash(AFlash: Boolean);
begin
  FOther.SetBlastFlash(AFlash);
end;

function TXcomBattleMapView.BlastFlash: Boolean;
begin
  Result := FOther.BlastFlash;
end;

function TXcomBattleMapView.AnimateExplosions: Boolean;
begin
  Result := FOther.AnimateExplosions;
end;

procedure TXcomBattleMapView.SoldierKilled(const AUnit: TXcomBattleUnit);
begin
  FOther.SoldierKilled(AUnit);
end;

procedure TXcomBattleMapView.ShowUnitMessage(const AUnit: TXcomBattleUnit; const AMessage: string;
  ANeedsConfirmation: Boolean);
begin
  FOther.ShowUnitMessage(AUnit, AMessage, ANeedsConfirmation);
end;

procedure TXcomBattleMapView.FinishBattle(AAbort: Boolean; AInExitArea: Integer);
begin
  FOther.FinishBattle(AAbort, AInExitArea);
end;

procedure TXcomBattleMapView.NextTurn;
begin
  FOther.NextTurn;
end;

procedure TXcomBattleMapView.ShowCursor(AVisible: Boolean);
begin
  FOther.ShowCursor(AVisible);
end;

function TXcomBattleMapView.CameraOffset: TXcomPosition;
begin
  Result := FMap.Camera.MapOffset;
end;

procedure TXcomBattleMapView.SetCameraOffset(const AOffset: TXcomPosition);
begin
  FMap.Camera.MapOffset := AOffset;
  FMap.Invalidate;
end;

procedure TXcomBattleMapView.AddWaypoint(const APosition: TXcomPosition);
begin
  FMap.Waypoints.Add(APosition);
end;

procedure TXcomBattleMapView.RemoveLastWaypoint;
begin
  if FMap.Waypoints.Count > 0 then
    FMap.Waypoints.Delete(FMap.Waypoints.Count - 1);
end;

procedure TXcomBattleMapView.ClearWaypoints;
begin
  FMap.Waypoints.Clear;
end;

procedure TXcomBattleMapView.ShowUnitInfo(const AUnit: TXcomBattleUnit);
begin
  FOther.ShowUnitInfo(AUnit);
end;

end.
