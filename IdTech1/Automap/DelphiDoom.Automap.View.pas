{******************************************************************************}
{                                                                              }
{  DelphiDoom: automap library - the view of the map and its navigation        }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Automap.View;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Automap.Types, DelphiDoom.Automap.Intf;

type
  /// <summary>
  ///   The state of the window of the automap (what the old am_map kept in its globals m_x, m_y,
  ///   scale_mtof, min_x, followplayer ...) with the rules that move it. It is both the view that
  ///   the drawing reads and the navigator that the keys and the tics drive.
  /// </summary>
  /// <remarks>
  ///   The wraparound of the fixed point products is wanted (as in the old code), so the unit
  ///   turns overflow and range checks off.
  /// </remarks>
  TAutomapView = class(TInterfacedObject, IAutomapView, IAutomapNavigator)
  strict private
    FWindow: TAutomapWindow;
    FFollowPlayer: Boolean;
    // the limits of the level, in map coordinates
    FLevelMinX: TFixed;
    FLevelMinY: TFixed;
    FLevelMaxX: TFixed;
    FLevelMaxY: TFixed;
    FMinScale: TFixed;
    FMaxScale: TFixed;
    // the place and scale kept for recovery
    FSavedMapX: TFixed;
    FSavedMapY: TFixed;
    FSavedMapWidth: TFixed;
    FSavedMapHeight: TFixed;
    // where the player was when the window followed it the last time
    FOldPlayerX: TFixed;
    FOldPlayerY: TFixed;
    FPanX: TFixed;
    FPanY: TFixed;
    FZoomMapToFrame: TFixed;
    FZoomFrameToMap: TFixed;
    procedure ActivateNewScale;
    procedure ChangeWindowLocation;
    procedure ChangeWindowScale;
    procedure FollowPlayerLocation(const APlayerX, APlayerY: TFixed);
    procedure SetScaleMapToFrame(const AValue: TFixed);
  public
    constructor Create;
    // IAutomapView
    function GetWindow: TAutomapWindow;
    procedure SetFrame(const AX, AY, AWidth, AHeight: Integer);
    function FrameToMap(const AValue: Integer): Integer;
    function MapToFrame(const AValue: Integer): Integer;
    function MapToFrameX(const AValue: Integer): Integer;
    function MapToFrameY(const AValue: Integer): Integer;
    function ClipLine(const AMapLine: TAutomapLine; var AFrameLine: TAutomapFrameLine): Boolean;
    // IAutomapNavigator
    function GetFollowPlayer: Boolean;
    procedure SetFollowPlayer(const AValue: Boolean);
    function GetPanX: TFixed;
    procedure SetPanX(const AValue: TFixed);
    function GetPanY: TFixed;
    procedure SetPanY(const AValue: TFixed);
    function GetZoomMapToFrame: TFixed;
    function GetZoomFrameToMap: TFixed;
    function GetMinScale: TFixed;
    function GetMaxScale: TFixed;
    procedure FitToVertices(const AVertices: PAutomapPoint; const ACount, AStride: Integer);
    procedure InitializeScale;
    procedure StartWindow(const AHasPlayer: Boolean; const APlayerX, APlayerY: TFixed);
    procedure SetZoom(const AMapToFrame, AFrameToMap: TFixed);
    procedure Tick(const APlayerX, APlayerY: TFixed);
    procedure CenterOnPlayer(const APlayerX, APlayerY: TFixed);
    procedure ForgetPlayerLocation;
    procedure SaveScaleAndLocation;
    procedure RestoreScaleAndLocation(const APlayerX, APlayerY: TFixed);
    procedure MinOutWindowScale;
    procedure MaxOutWindowScale;
  end;

implementation

uses
  DelphiDoom.MathCore.FixedMath, DelphiDoom.Automap.Transform, DelphiDoom.Automap.LineClipper;

const
  // the value that means "the player was nowhere" (the old f_oldloc.x := MAXINT)
  NO_PLAYER_LOCATION = High(Integer);

{ TAutomapView }

constructor TAutomapView.Create;
begin
  inherited Create;
  FFollowPlayer := True;
  // the old code left the scale frame to map at 0 until the first level started
  SetScaleMapToFrame(AUTOMAP_INITIAL_SCALE);
  FZoomMapToFrame := FIXED_ONE;
  FZoomFrameToMap := FIXED_ONE;
end;

function TAutomapView.GetWindow: TAutomapWindow;
begin
  Result := FWindow;
end;

procedure TAutomapView.SetFrame(const AX, AY, AWidth, AHeight: Integer);
begin
  FWindow.FrameX := AX;
  FWindow.FrameY := AY;
  FWindow.FrameWidth := AWidth;
  FWindow.FrameHeight := AHeight;
end;

function TAutomapView.FrameToMap(const AValue: Integer): Integer;
begin
  Result := TAutomapTransform.FrameToMap(FWindow, AValue);
end;

function TAutomapView.MapToFrame(const AValue: Integer): Integer;
begin
  Result := TAutomapTransform.MapToFrame(FWindow, AValue);
end;

function TAutomapView.MapToFrameX(const AValue: Integer): Integer;
begin
  Result := TAutomapTransform.MapToFrameX(FWindow, AValue);
end;

function TAutomapView.MapToFrameY(const AValue: Integer): Integer;
begin
  Result := TAutomapTransform.MapToFrameY(FWindow, AValue);
end;

function TAutomapView.ClipLine(const AMapLine: TAutomapLine;
  var AFrameLine: TAutomapFrameLine): Boolean;
begin
  Result := TAutomapLineClipper.Clip(FWindow, AMapLine, AFrameLine);
end;

function TAutomapView.GetFollowPlayer: Boolean;
begin
  Result := FFollowPlayer;
end;

procedure TAutomapView.SetFollowPlayer(const AValue: Boolean);
begin
  FFollowPlayer := AValue;
end;

function TAutomapView.GetPanX: TFixed;
begin
  Result := FPanX;
end;

procedure TAutomapView.SetPanX(const AValue: TFixed);
begin
  FPanX := AValue;
end;

function TAutomapView.GetPanY: TFixed;
begin
  Result := FPanY;
end;

procedure TAutomapView.SetPanY(const AValue: TFixed);
begin
  FPanY := AValue;
end;

function TAutomapView.GetZoomMapToFrame: TFixed;
begin
  Result := FZoomMapToFrame;
end;

function TAutomapView.GetZoomFrameToMap: TFixed;
begin
  Result := FZoomFrameToMap;
end;

function TAutomapView.GetMinScale: TFixed;
begin
  Result := FMinScale;
end;

function TAutomapView.GetMaxScale: TFixed;
begin
  Result := FMaxScale;
end;

procedure TAutomapView.SetScaleMapToFrame(const AValue: TFixed);
begin
  FWindow.ScaleMapToFrame := AValue;
  FWindow.ScaleFrameToMap := TFixedMath.Divide(FIXED_ONE, AValue);
end;

procedure TAutomapView.ActivateNewScale;
begin
  FWindow.MapX := FWindow.MapX + FWindow.MapWidth div 2;
  FWindow.MapY := FWindow.MapY + FWindow.MapHeight div 2;
  FWindow.MapWidth := FrameToMap(FWindow.FrameWidth);
  FWindow.MapHeight := FrameToMap(FWindow.FrameHeight);
  FWindow.MapX := FWindow.MapX - FWindow.MapWidth div 2;
  FWindow.MapY := FWindow.MapY - FWindow.MapHeight div 2;
  FWindow.MapX2 := FWindow.MapX + FWindow.MapWidth;
  FWindow.MapY2 := FWindow.MapY + FWindow.MapHeight;
end;

procedure TAutomapView.ChangeWindowLocation;
begin
  if (FPanX <> 0) or (FPanY <> 0) then
  begin
    FFollowPlayer := False;
    FOldPlayerX := NO_PLAYER_LOCATION;
  end;

  FWindow.MapX := FWindow.MapX + FPanX;
  FWindow.MapY := FWindow.MapY + FPanY;

  if FWindow.MapX + FWindow.MapWidth div 2 > FLevelMaxX then
    FWindow.MapX := FLevelMaxX - FWindow.MapWidth div 2
  else if FWindow.MapX + FWindow.MapWidth div 2 < FLevelMinX then
    FWindow.MapX := FLevelMinX - FWindow.MapWidth div 2;

  if FWindow.MapY + FWindow.MapHeight div 2 > FLevelMaxY then
    FWindow.MapY := FLevelMaxY - FWindow.MapHeight div 2
  else if FWindow.MapY + FWindow.MapHeight div 2 < FLevelMinY then
    FWindow.MapY := FLevelMinY - FWindow.MapHeight div 2;

  FWindow.MapX2 := FWindow.MapX + FWindow.MapWidth;
  FWindow.MapY2 := FWindow.MapY + FWindow.MapHeight;
end;

procedure TAutomapView.ChangeWindowScale;
begin
  // Change the scaling multipliers
  SetScaleMapToFrame(TFixedMath.Mul(FWindow.ScaleMapToFrame, FZoomMapToFrame));

  if FWindow.ScaleMapToFrame < FMinScale then
    MinOutWindowScale
  else if FWindow.ScaleMapToFrame > FMaxScale then
    MaxOutWindowScale
  else
    ActivateNewScale;
end;

procedure TAutomapView.FollowPlayerLocation(const APlayerX, APlayerY: TFixed);
begin
  if (FOldPlayerX <> APlayerX) or (FOldPlayerY <> APlayerY) then
  begin
    FWindow.MapX := FrameToMap(MapToFrame(APlayerX div AUTOMAP_FRACTOMAPUNIT)) -
      FWindow.MapWidth div 2;
    FWindow.MapY := FrameToMap(MapToFrame(APlayerY div AUTOMAP_FRACTOMAPUNIT)) -
      FWindow.MapHeight div 2;
    FWindow.MapX2 := FWindow.MapX + FWindow.MapWidth;
    FWindow.MapY2 := FWindow.MapY + FWindow.MapHeight;
    FOldPlayerX := APlayerX;
    FOldPlayerY := APlayerY;
  end;
end;

procedure TAutomapView.FitToVertices(const AVertices: PAutomapPoint; const ACount, AStride: Integer);
var
  LIndex: Integer;
  LVertex: PAutomapPoint;
  LMinX: TFixed;
  LMinY: TFixed;
  LMaxX: TFixed;
  LMaxY: TFixed;
  LScaleX: TFixed;
  LScaleY: TFixed;
begin
  LMinX := High(Integer);
  LMinY := High(Integer);
  LMaxX := -High(Integer);
  LMaxY := -High(Integer);

  LVertex := AVertices;
  for LIndex := 0 to ACount - 1 do
  begin
    // the old code skipped the test of the maximum for a vertex that became the minimum, and
    // lost the first vertex when it was the biggest: both tests are made for every vertex
    if LVertex.X < LMinX then
      LMinX := LVertex.X;
    if LVertex.X > LMaxX then
      LMaxX := LVertex.X;
    if LVertex.Y < LMinY then
      LMinY := LVertex.Y;
    if LVertex.Y > LMaxY then
      LMaxY := LVertex.Y;
    LVertex := PAutomapPoint(PByte(LVertex) + AStride);
  end;

  FLevelMaxX := LMaxX div AUTOMAP_FRACTOMAPUNIT;
  FLevelMinX := LMinX div AUTOMAP_FRACTOMAPUNIT;
  FLevelMaxY := LMaxY div AUTOMAP_FRACTOMAPUNIT;
  FLevelMinY := LMinY div AUTOMAP_FRACTOMAPUNIT;

  LScaleX := TFixedMath.Divide(FWindow.FrameWidth * FIXED_ONE, FLevelMaxX - FLevelMinX);
  LScaleY := TFixedMath.Divide(FWindow.FrameHeight * FIXED_ONE, FLevelMaxY - FLevelMinY);

  if LScaleX < LScaleY then
    FMinScale := LScaleX
  else
    FMinScale := LScaleY;

  FMaxScale := TFixedMath.Divide(FWindow.FrameHeight * FIXED_ONE, 2 * AUTOMAP_PLAYERRADIUS);
end;

procedure TAutomapView.InitializeScale;
var
  LScale: TFixed;
begin
  LScale := TFixedMath.Divide(FMinScale, Trunc(0.7 * FIXED_ONE));
  if LScale > FMaxScale then
    LScale := FMinScale;
  SetScaleMapToFrame(LScale);
end;

procedure TAutomapView.StartWindow(const AHasPlayer: Boolean; const APlayerX, APlayerY: TFixed);
begin
  FOldPlayerX := NO_PLAYER_LOCATION;
  FPanX := 0;
  FPanY := 0;
  FZoomFrameToMap := FIXED_ONE;
  FZoomMapToFrame := FIXED_ONE;

  FWindow.MapWidth := FrameToMap(FWindow.FrameWidth);
  FWindow.MapHeight := FrameToMap(FWindow.FrameHeight);

  if AHasPlayer then
  begin
    FWindow.MapX := (APlayerX div AUTOMAP_FRACTOMAPUNIT) - FWindow.MapWidth div 2;
    FWindow.MapY := (APlayerY div AUTOMAP_FRACTOMAPUNIT) - FWindow.MapHeight div 2;
  end;

  ChangeWindowLocation;

  SaveScaleAndLocation;
end;

procedure TAutomapView.SetZoom(const AMapToFrame, AFrameToMap: TFixed);
begin
  FZoomMapToFrame := AMapToFrame;
  FZoomFrameToMap := AFrameToMap;
end;

procedure TAutomapView.Tick(const APlayerX, APlayerY: TFixed);
begin
  if FFollowPlayer then
    FollowPlayerLocation(APlayerX, APlayerY);

  // Change the zoom if necessary
  if FZoomFrameToMap <> FIXED_ONE then
    ChangeWindowScale;

  // Change x,y location
  if (FPanX <> 0) or (FPanY <> 0) then
    ChangeWindowLocation;
end;

procedure TAutomapView.CenterOnPlayer(const APlayerX, APlayerY: TFixed);
begin
  // the old AM_Drawer did not update the upper right corner here: it keeps the one of the tic
  FWindow.MapWidth := FrameToMap(FWindow.FrameWidth);
  FWindow.MapHeight := FrameToMap(FWindow.FrameHeight);
  FWindow.MapX := APlayerX div AUTOMAP_FRACTOMAPUNIT - FWindow.MapWidth div 2;
  FWindow.MapY := APlayerY div AUTOMAP_FRACTOMAPUNIT - FWindow.MapHeight div 2;
end;

procedure TAutomapView.ForgetPlayerLocation;
begin
  FOldPlayerX := NO_PLAYER_LOCATION;
end;

procedure TAutomapView.SaveScaleAndLocation;
begin
  FSavedMapX := FWindow.MapX;
  FSavedMapY := FWindow.MapY;
  FSavedMapWidth := FWindow.MapWidth;
  FSavedMapHeight := FWindow.MapHeight;
end;

procedure TAutomapView.RestoreScaleAndLocation(const APlayerX, APlayerY: TFixed);
begin
  FWindow.MapWidth := FSavedMapWidth;
  FWindow.MapHeight := FSavedMapHeight;
  if not FFollowPlayer then
  begin
    FWindow.MapX := FSavedMapX;
    FWindow.MapY := FSavedMapY;
  end
  else
  begin
    FWindow.MapX := (APlayerX div AUTOMAP_FRACTOMAPUNIT) - FWindow.MapWidth div 2;
    FWindow.MapY := (APlayerY div AUTOMAP_FRACTOMAPUNIT) - FWindow.MapHeight div 2;
  end;

  FWindow.MapX2 := FWindow.MapX + FWindow.MapWidth;
  FWindow.MapY2 := FWindow.MapY + FWindow.MapHeight;

  // Change the scaling multipliers
  SetScaleMapToFrame(TFixedMath.Divide(FWindow.FrameWidth * FIXED_ONE, FWindow.MapWidth));
end;

procedure TAutomapView.MinOutWindowScale;
begin
  SetScaleMapToFrame(FMinScale);
  ActivateNewScale;
end;

procedure TAutomapView.MaxOutWindowScale;
begin
  SetScaleMapToFrame(FMaxScale);
  ActivateNewScale;
end;

end.
