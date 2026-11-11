{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - a battle without a screen             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.View.Null;

interface

uses
  System.Generics.Collections, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomSave.BattleUnitKills,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.View.Intf;

type
  /// <summary>
  ///   IXcomBattleView that shows nothing: the messages are kept (for the tests and the logs), the explosions
  ///   are over at once and no unit is ever on the screen. The battle on a server, the tests and the parity runs
  ///   use it
  /// </summary>
  TXcomBattleNullView = class(TInterfacedObject, IXcomBattleView)
  strict private
    FWarnings: TList<string>;
    FFinished: Boolean;
    FAborted: Boolean;
    FInExitArea: Integer;
    FNextTurns: Integer;
    FKilledSoldiers: Integer;
    FExplosionSprites: Integer;
  public
    constructor Create;
    destructor Destroy; override;
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
    procedure SoldierKilled(const AUnit: TXcomBattleUnit; ACause: TXcomBattleUnitKills);
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
    /// <summary>The warnings shown so far, in order</summary>
    property Warnings: TList<string> read FWarnings;
    /// <summary>finishBattle was called</summary>
    property Finished: Boolean read FFinished;
    property Aborted: Boolean read FAborted;
    property InExitArea: Integer read FInExitArea;
    /// <summary>How many times the next turn screen would have been shown</summary>
    property NextTurns: Integer read FNextTurns;
    property KilledSoldiers: Integer read FKilledSoldiers;
    /// <summary>How many explosion sprites the battle asked for</summary>
    property ExplosionSprites: Integer read FExplosionSprites;
  end;

implementation

constructor TXcomBattleNullView.Create;
begin
  inherited Create;
  FWarnings := TList<string>.Create;
end;

destructor TXcomBattleNullView.Destroy;
begin
  FWarnings.Free;
  inherited Destroy;
end;

procedure TXcomBattleNullView.Warning(const AMessage: string);
begin
  FWarnings.Add(AMessage);
end;

procedure TXcomBattleNullView.Debug(const AMessage: string);
begin
end;

procedure TXcomBattleNullView.UpdateSoldierInfo;
begin
end;

procedure TXcomBattleNullView.CenterOnPosition(const APosition: TXcomPosition; AGraphic: Boolean);
begin
end;

procedure TXcomBattleNullView.SetViewLevel(ALevel: Integer);
begin
end;

function TXcomBattleNullView.IsOnScreen(const APosition: TXcomPosition; AUnitWalking: Boolean; AUnitSize: Integer;
  ABoundary: Boolean): Boolean;
begin
  Result := False;
end;

procedure TXcomBattleNullView.CacheUnits;
begin
end;

procedure TXcomBattleNullView.CacheUnit(const AUnit: TXcomBattleUnit);
begin
end;

procedure TXcomBattleNullView.SetStateInterval(AMilliseconds: Integer);
begin
end;

procedure TXcomBattleNullView.ShowPsiButton(AShow: Boolean);
begin
end;

procedure TXcomBattleNullView.ShowLaunchButton(AShow: Boolean);
begin
end;

procedure TXcomBattleNullView.SetUnitDying(ADying: Boolean);
begin
end;

procedure TXcomBattleNullView.SetCursorType(ACursorType, ASize: Integer);
begin
end;

procedure TXcomBattleNullView.PlaySound(ASound: Integer; const APosition: TXcomPosition);
begin
end;

procedure TXcomBattleNullView.AddExplosion(const ACenter: TXcomPosition; AStartFrame, AFrameDelay: Integer;
  ABig, AHit: Boolean);
begin
  Inc(FExplosionSprites);
end;

procedure TXcomBattleNullView.AddVaporCloud(const AVoxel: TXcomPosition; ADensity, AColor: Integer);
begin
  // no map: no particles
end;

procedure TXcomBattleNullView.ResetObstacles;
begin
  // the obstacle marks only matter to the drawing
end;

procedure TXcomBattleNullView.EnableObstacles;
begin
end;

procedure TXcomBattleNullView.DisableObstacles;
begin
end;

procedure TXcomBattleNullView.SetProjectile(const AProjectile: TObject);
begin
end;

procedure TXcomBattleNullView.SetBlastFlash(AFlash: Boolean);
begin
end;

function TXcomBattleNullView.BlastFlash: Boolean;
begin
  Result := False;
end;

function TXcomBattleNullView.AnimateExplosions: Boolean;
begin
  Result := True;
end;

procedure TXcomBattleNullView.SoldierKilled(const AUnit: TXcomBattleUnit; ACause: TXcomBattleUnitKills);
begin
  Inc(FKilledSoldiers);
  // nobody keeps the cause of the death
  ACause.Free;
end;

procedure TXcomBattleNullView.ShowUnitMessage(const AUnit: TXcomBattleUnit; const AMessage: string;
  ANeedsConfirmation: Boolean);
begin
end;

procedure TXcomBattleNullView.FinishBattle(AAbort: Boolean; AInExitArea: Integer);
begin
  FFinished := True;
  FAborted := AAbort;
  FInExitArea := AInExitArea;
end;

procedure TXcomBattleNullView.NextTurn;
begin
  Inc(FNextTurns);
end;

procedure TXcomBattleNullView.ShowCursor(AVisible: Boolean);
begin
end;

function TXcomBattleNullView.CameraOffset: TXcomPosition;
begin
  // no screen: an action never comes back to a camera position
  Result := TXcomPosition.Make(0, 0, -1);
end;

procedure TXcomBattleNullView.SetCameraOffset(const AOffset: TXcomPosition);
begin
end;

procedure TXcomBattleNullView.AddWaypoint(const APosition: TXcomPosition);
begin
end;

procedure TXcomBattleNullView.RemoveLastWaypoint;
begin
end;

procedure TXcomBattleNullView.ClearWaypoints;
begin
end;

procedure TXcomBattleNullView.ShowUnitInfo(const AUnit: TXcomBattleUnit);
begin
end;

end.
