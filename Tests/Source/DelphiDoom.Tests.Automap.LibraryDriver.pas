{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the automap library - the driver on the library        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.LibraryDriver;

interface

uses
  DelphiDoom.Automap.Types, DelphiDoom.Automap.Intf, DelphiDoom.Tests.Automap.Scenarios;

type
  /// <summary>The driver of the scenarios on the classes of the library</summary>
  TLibraryDriver = class(TInterfacedObject, IAutomapDriver)
  strict private
    FView: IAutomapView;
    FNavigator: IAutomapNavigator;
    FMarks: IAutomapMarks;
  public
    constructor Create;
    procedure SetFrame(const AX, AY, AWidth, AHeight: Integer);
    procedure FitVertices(const AVertices: TArray<TAutomapPoint>);
    procedure InitializeScale;
    procedure StartWindow(const AHasPlayer: Boolean; const APlayerX, APlayerY: Integer);
    procedure SetPan(const AX, AY: Integer);
    procedure SetZoom(const AMapToFrame, AFrameToMap: Integer);
    procedure SetFollow(const AValue: Boolean);
    procedure ForgetPlayerLocation;
    procedure Tick(const APlayerX, APlayerY: Integer);
    procedure CenterOnPlayer(const APlayerX, APlayerY: Integer);
    procedure SaveScaleAndLocation;
    procedure RestoreScaleAndLocation(const APlayerX, APlayerY: Integer);
    procedure MinOut;
    procedure MaxOut;
    function FrameToMap(const AValue: Integer): Integer;
    function MapToFrame(const AValue: Integer): Integer;
    function MapToFrameX(const AValue: Integer): Integer;
    function MapToFrameY(const AValue: Integer): Integer;
    function Clip(const AMapLine: TAutomapLine; var AFrameLine: TAutomapFrameLine): Boolean;
    procedure Rotate(var AX, AY: Integer; const AAngle: Cardinal; const ACenterX, ACenterY: Integer);
    procedure RotateExact(var AX, AY: Integer; const AAngle: Cardinal; const ACenterX, ACenterY: Integer);
    procedure AddMarkAtCenter;
    procedure ClearMarks;
    function MarkValues: TArray<Integer>;
    function Snapshot: TArray<Integer>;
    function ZoomIn: Integer;
    function ZoomOut: Integer;
  end;

implementation

uses
  DelphiDoom.Automap.Factory, DelphiDoom.Automap.Rotation;

{ TLibraryDriver }

constructor TLibraryDriver.Create;
begin
  inherited Create;
  TAutomapFactory.CreateView(FView, FNavigator);
  FMarks := TAutomapFactory.CreateMarks;
end;

procedure TLibraryDriver.SetFrame(const AX, AY, AWidth, AHeight: Integer);
begin
  FView.SetFrame(AX, AY, AWidth, AHeight);
end;

procedure TLibraryDriver.FitVertices(const AVertices: TArray<TAutomapPoint>);
begin
  FNavigator.FitToVertices(@AVertices[0], Length(AVertices), SizeOf(TAutomapPoint));
end;

procedure TLibraryDriver.InitializeScale;
begin
  FNavigator.InitializeScale;
end;

procedure TLibraryDriver.StartWindow(const AHasPlayer: Boolean; const APlayerX, APlayerY: Integer);
begin
  FNavigator.StartWindow(AHasPlayer, APlayerX, APlayerY);
end;

procedure TLibraryDriver.SetPan(const AX, AY: Integer);
begin
  FNavigator.PanX := AX;
  FNavigator.PanY := AY;
end;

procedure TLibraryDriver.SetZoom(const AMapToFrame, AFrameToMap: Integer);
begin
  FNavigator.SetZoom(AMapToFrame, AFrameToMap);
end;

procedure TLibraryDriver.SetFollow(const AValue: Boolean);
begin
  FNavigator.FollowPlayer := AValue;
end;

procedure TLibraryDriver.ForgetPlayerLocation;
begin
  FNavigator.ForgetPlayerLocation;
end;

procedure TLibraryDriver.Tick(const APlayerX, APlayerY: Integer);
begin
  FNavigator.Tick(APlayerX, APlayerY);
end;

procedure TLibraryDriver.CenterOnPlayer(const APlayerX, APlayerY: Integer);
begin
  FNavigator.CenterOnPlayer(APlayerX, APlayerY);
end;

procedure TLibraryDriver.SaveScaleAndLocation;
begin
  FNavigator.SaveScaleAndLocation;
end;

procedure TLibraryDriver.RestoreScaleAndLocation(const APlayerX, APlayerY: Integer);
begin
  FNavigator.RestoreScaleAndLocation(APlayerX, APlayerY);
end;

procedure TLibraryDriver.MinOut;
begin
  FNavigator.MinOutWindowScale;
end;

procedure TLibraryDriver.MaxOut;
begin
  FNavigator.MaxOutWindowScale;
end;

function TLibraryDriver.FrameToMap(const AValue: Integer): Integer;
begin
  Result := FView.FrameToMap(AValue);
end;

function TLibraryDriver.MapToFrame(const AValue: Integer): Integer;
begin
  Result := FView.MapToFrame(AValue);
end;

function TLibraryDriver.MapToFrameX(const AValue: Integer): Integer;
begin
  Result := FView.MapToFrameX(AValue);
end;

function TLibraryDriver.MapToFrameY(const AValue: Integer): Integer;
begin
  Result := FView.MapToFrameY(AValue);
end;

function TLibraryDriver.Clip(const AMapLine: TAutomapLine; var AFrameLine: TAutomapFrameLine): Boolean;
begin
  Result := FView.ClipLine(AMapLine, AFrameLine);
end;

procedure TLibraryDriver.Rotate(var AX, AY: Integer; const AAngle: Cardinal; const ACenterX, ACenterY: Integer);
begin
  TAutomapRotation.Rotate(AX, AY, AAngle, ACenterX, ACenterY);
end;

procedure TLibraryDriver.RotateExact(var AX, AY: Integer; const AAngle: Cardinal; const ACenterX, ACenterY: Integer);
begin
  TAutomapRotation.RotateExact(AX, AY, AAngle, ACenterX, ACenterY);
end;

procedure TLibraryDriver.AddMarkAtCenter;
var
  LWindow: TAutomapWindow;
begin
  LWindow := FView.Window;
  FMarks.Add(LWindow.MapX + LWindow.MapWidth div 2, LWindow.MapY + LWindow.MapHeight div 2);
end;

procedure TLibraryDriver.ClearMarks;
begin
  FMarks.Clear;
end;

function TLibraryDriver.MarkValues: TArray<Integer>;
var
  LIndex: Integer;
begin
  SetLength(Result, 1 + 2 * FMarks.Count);
  Result[0] := FMarks.NextIndex;
  for LIndex := 0 to FMarks.Count - 1 do
  begin
    Result[1 + 2 * LIndex] := FMarks.Point(LIndex).X;
    // an empty mark has a leftover y: only the x counts
    if FMarks.IsUsed(LIndex) then
      Result[2 + 2 * LIndex] := FMarks.Point(LIndex).Y
    else
      Result[2 + 2 * LIndex] := 0;
  end;
end;

function TLibraryDriver.Snapshot: TArray<Integer>;
var
  LWindow: TAutomapWindow;
begin
  LWindow := FView.Window;
  Result := TArray<Integer>.Create(LWindow.FrameX, LWindow.FrameY, LWindow.FrameWidth,
    LWindow.FrameHeight, LWindow.MapX, LWindow.MapY, LWindow.MapX2, LWindow.MapY2,
    LWindow.MapWidth, LWindow.MapHeight, LWindow.ScaleMapToFrame, LWindow.ScaleFrameToMap,
    FNavigator.PanX, FNavigator.PanY, FNavigator.ZoomMapToFrame, FNavigator.ZoomFrameToMap,
    FNavigator.MinScale, FNavigator.MaxScale, Ord(FNavigator.FollowPlayer));
end;

function TLibraryDriver.ZoomIn: Integer;
begin
  Result := AUTOMAP_ZOOM_IN;
end;

function TLibraryDriver.ZoomOut: Integer;
begin
  Result := AUTOMAP_ZOOM_OUT;
end;

end.
