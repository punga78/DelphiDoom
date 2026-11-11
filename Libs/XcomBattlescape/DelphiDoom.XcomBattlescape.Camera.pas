{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape drawing library - the camera (Camera)           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattlescape.Camera;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomMod.MapBlock;

type
  /// <summary>
  ///   The view on the map: the offset of the map on the screen, the level, the conversions between tiles,
  ///   voxels and screen positions, and the scrolling that keeps the center of the screen inside the map. It
  ///   knows nothing of the map surface: it is given the sizes and tells the owner when the map must be redrawn
  /// </summary>
  TXcomCamera = class
  strict private
    FSpriteWidth: Integer;
    FSpriteHeight: Integer;
    FMapSizeX: Integer;
    FMapSizeY: Integer;
    FMapSizeZ: Integer;
    FScreenWidth: Integer;
    FScreenHeight: Integer;
    FVisibleMapHeight: Integer;
    FIconWidth: Integer;
    FIconHeight: Integer;
    FMapOffset: TXcomPosition;
    FCenter: TXcomPosition;
    FShowAllLayers: Boolean;
    FOnChanged: TProc;
  public
    /// <param name="AScreenWidth">The width of the map surface</param>
    /// <param name="AScreenHeight">The height of the map surface</param>
    /// <param name="AVisibleMapHeight">The height of the map without the panel of the icons</param>
    constructor Create(ASpriteWidth, ASpriteHeight, AMapSizeX, AMapSizeY, AMapSizeZ, AScreenWidth, AScreenHeight,
      AVisibleMapHeight, AIconWidth, AIconHeight: Integer);
    /// <summary>scrollXY: moves the map and keeps the center inside it</summary>
    procedure ScrollXY(AX, AY: Integer; ARedraw: Boolean);
    /// <summary>jumpXY</summary>
    procedure JumpXY(AX, AY: Integer);
    procedure Up;
    procedure Down;
    /// <summary>setViewLevel</summary>
    procedure SetViewLevel(ALevel: Integer);
    /// <summary>centerOnPosition</summary>
    procedure CenterOnPosition(const AMapPosition: TXcomPosition; ARedraw: Boolean = True);
    function CenterPosition: TXcomPosition;
    procedure ConvertScreenToMap(AScreenX, AScreenY: Integer; out AMapX, AMapY: Integer);
    function ConvertMapToScreen(const AMapPosition: TXcomPosition): TXcomPosition;
    function ConvertVoxelToScreen(const AVoxelPosition: TXcomPosition): TXcomPosition;
    function ViewLevel: Integer;
    /// <summary>isOnScreen</summary>
    function IsOnScreen(const AMapPosition: TXcomPosition; AUnitWalking: Boolean; AUnitSize: Integer;
      ABoundary: Boolean): Boolean;
    /// <summary>toggleShowAllLayers: the new setting (1 or 2)</summary>
    function ToggleShowAllLayers: Integer;
    property SpriteWidth: Integer read FSpriteWidth;
    property SpriteHeight: Integer read FSpriteHeight;
    property MapOffset: TXcomPosition read FMapOffset write FMapOffset;
    property ShowAllLayers: Boolean read FShowAllLayers;
    property VisibleMapHeight: Integer read FVisibleMapHeight;
    /// <summary>Called when the map must be redrawn (Map::invalidate / Map::draw)</summary>
    property OnChanged: TProc read FOnChanged write FOnChanged;
  end;

implementation

constructor TXcomCamera.Create(ASpriteWidth, ASpriteHeight, AMapSizeX, AMapSizeY, AMapSizeZ, AScreenWidth,
  AScreenHeight, AVisibleMapHeight, AIconWidth, AIconHeight: Integer);
begin
  inherited Create;
  FSpriteWidth := ASpriteWidth;
  FSpriteHeight := ASpriteHeight;
  FMapSizeX := AMapSizeX;
  FMapSizeY := AMapSizeY;
  FMapSizeZ := AMapSizeZ;
  FScreenWidth := AScreenWidth;
  FScreenHeight := AScreenHeight;
  FVisibleMapHeight := AVisibleMapHeight;
  FIconWidth := AIconWidth;
  FIconHeight := AIconHeight;
  FMapOffset := TXcomPosition.Make(-250, 250, 0);
end;

procedure TXcomCamera.ScrollXY(AX, AY: Integer; ARedraw: Boolean);
var
  LDone: Boolean;
begin
  FMapOffset.X := FMapOffset.X + AX;
  FMapOffset.Y := FMapOffset.Y + AY;
  repeat
    LDone := False;
    ConvertScreenToMap(FScreenWidth div 2, FVisibleMapHeight div 2, FCenter.X, FCenter.Y);
    // handling map bounds
    if FCenter.X < 0 then
    begin
      FMapOffset.X := FMapOffset.X - 1;
      FMapOffset.Y := FMapOffset.Y - 1;
    end
    else if FCenter.X > FMapSizeX - 1 then
    begin
      FMapOffset.X := FMapOffset.X + 1;
      FMapOffset.Y := FMapOffset.Y + 1;
    end
    else if FCenter.Y < 0 then
    begin
      FMapOffset.X := FMapOffset.X + 1;
      FMapOffset.Y := FMapOffset.Y - 1;
    end
    else if FCenter.Y > FMapSizeY - 1 then
    begin
      FMapOffset.X := FMapOffset.X - 1;
      FMapOffset.Y := FMapOffset.Y + 1;
    end
    else
      LDone := True;
  until LDone;
  if ARedraw and Assigned(FOnChanged) then
    FOnChanged();
end;

procedure TXcomCamera.JumpXY(AX, AY: Integer);
begin
  FMapOffset.X := FMapOffset.X + AX;
  FMapOffset.Y := FMapOffset.Y + AY;
  ConvertScreenToMap(FScreenWidth div 2, FVisibleMapHeight div 2, FCenter.X, FCenter.Y);
end;

procedure TXcomCamera.Up;
begin
  if FMapOffset.Z < FMapSizeZ - 1 then
  begin
    FMapOffset.Z := FMapOffset.Z + 1;
    FMapOffset.Y := FMapOffset.Y + FSpriteHeight * 3 div 5;
    if Assigned(FOnChanged) then
      FOnChanged();
  end;
end;

procedure TXcomCamera.Down;
begin
  if FMapOffset.Z > 0 then
  begin
    FMapOffset.Z := FMapOffset.Z - 1;
    FMapOffset.Y := FMapOffset.Y - FSpriteHeight * 3 div 5;
    if Assigned(FOnChanged) then
      FOnChanged();
  end;
end;

procedure TXcomCamera.SetViewLevel(ALevel: Integer);
begin
  FMapOffset.Z := EnsureRange(ALevel, 0, FMapSizeZ - 1);
  if Assigned(FOnChanged) then
    FOnChanged();
end;

procedure TXcomCamera.CenterOnPosition(const AMapPosition: TXcomPosition; ARedraw: Boolean);
var
  LScreen: TXcomPosition;
begin
  FCenter := AMapPosition;
  FCenter.X := EnsureRange(FCenter.X, -1, FMapSizeX);
  FCenter.Y := EnsureRange(FCenter.Y, -1, FMapSizeY);
  LScreen := ConvertMapToScreen(FCenter);
  FMapOffset.X := -(LScreen.X - (FScreenWidth div 2));
  FMapOffset.Y := -(LScreen.Y - (FVisibleMapHeight div 2));
  FMapOffset.Z := FCenter.Z;
  if ARedraw and Assigned(FOnChanged) then
    FOnChanged();
end;

function TXcomCamera.CenterPosition: TXcomPosition;
begin
  FCenter.Z := FMapOffset.Z;
  Result := FCenter;
end;

procedure TXcomCamera.ConvertScreenToMap(AScreenX, AScreenY: Integer; out AMapX, AMapY: Integer);
begin
  // add half a tileheight to the mouseposition per layer we are above the floor
  AScreenY := AScreenY + (-FSpriteWidth div 2) + FMapOffset.Z * ((FSpriteHeight + FSpriteWidth div 4) div 2);
  // calculate the actual x/y pixelposition on a diamond shaped map taking the view offset into account
  AMapY := -AScreenX + FMapOffset.X + 2 * AScreenY - 2 * FMapOffset.Y;
  AMapX := AScreenY - FMapOffset.Y - AMapY div 4 - (FSpriteWidth div 4);
  // to get the row&col itself, divide by the size of a tile
  AMapX := AMapX div (FSpriteWidth div 4);
  AMapY := AMapY div FSpriteWidth;
  AMapX := EnsureRange(AMapX, -1, FMapSizeX);
  AMapY := EnsureRange(AMapY, -1, FMapSizeY);
end;

function TXcomCamera.ConvertMapToScreen(const AMapPosition: TXcomPosition): TXcomPosition;
begin
  Result.Z := 0;
  Result.X := AMapPosition.X * (FSpriteWidth div 2) - AMapPosition.Y * (FSpriteWidth div 2);
  Result.Y := AMapPosition.X * (FSpriteWidth div 4) + AMapPosition.Y * (FSpriteWidth div 4) -
    AMapPosition.Z * ((FSpriteHeight + FSpriteWidth div 4) div 2);
end;

function TXcomCamera.ConvertVoxelToScreen(const AVoxelPosition: TXcomPosition): TXcomPosition;
var
  LMap: TXcomPosition;
  LDx: Double;
  LDy: Double;
  LDz: Double;
begin
  LMap := TXcomPosition.Make(AVoxelPosition.X div 16, AVoxelPosition.Y div 16, AVoxelPosition.Z div 24);
  Result := ConvertMapToScreen(LMap);
  LDx := AVoxelPosition.X - (LMap.X * 16);
  LDy := AVoxelPosition.Y - (LMap.Y * 16);
  LDz := AVoxelPosition.Z - (LMap.Z * 24);
  Result.X := Result.X + Trunc(LDx - LDy) + (FSpriteWidth div 2);
  Result.Y := Result.Y + Trunc((FSpriteHeight / 2.0) + (LDx / 2.0) + (LDy / 2.0) - LDz);
  Result.X := Result.X + FMapOffset.X;
  Result.Y := Result.Y + FMapOffset.Y;
end;

function TXcomCamera.ViewLevel: Integer;
begin
  Result := FMapOffset.Z;
end;

function TXcomCamera.ToggleShowAllLayers: Integer;
begin
  FShowAllLayers := not FShowAllLayers;
  if FShowAllLayers then
    Result := 2
  else
    Result := 1;
end;

function TXcomCamera.IsOnScreen(const AMapPosition: TXcomPosition; AUnitWalking: Boolean; AUnitSize: Integer;
  ABoundary: Boolean): Boolean;
var
  LScreen: TXcomPosition;
  LPosX: Integer;
  LPosY: Integer;
  LSizeX: Integer;
  LSizeY: Integer;
  LSide: Integer;
begin
  LScreen := ConvertMapToScreen(AMapPosition);
  LPosX := FSpriteWidth div 2;
  LPosY := FSpriteHeight - FSpriteWidth div 4;
  LSizeX := FSpriteWidth div 2;
  LSizeY := FSpriteHeight div 2;
  if AUnitSize > 0 then
  begin
    LPosY := LPosY - FSpriteWidth div 4;
    LSizeX := FSpriteWidth * AUnitSize;
    LSizeY := FSpriteWidth * AUnitSize div 2;
  end;
  LScreen.X := LScreen.X + FMapOffset.X + LPosX;
  LScreen.Y := LScreen.Y + FMapOffset.Y + LPosY;
  if AUnitWalking then
  begin
    // to make sprite updates even being slightly outside of screen
    if ABoundary then
    begin
      LSizeX := LSizeX + FSpriteWidth;
      LSizeY := LSizeY + FSpriteWidth div 2;
    end;
    if (LScreen.X < 0 - LSizeX) or (LScreen.X >= FScreenWidth + LSizeX) or (LScreen.Y < 0 - LSizeY) or
      (LScreen.Y >= FScreenHeight + LSizeY) then
      Exit(False); // totally outside
    LSide := (FScreenWidth - FIconWidth) div 2;
    if LScreen.Y < (FScreenHeight - FIconHeight) + LSizeY then
      Exit(True); // above icons
    if (LSide > 1) and ((LScreen.X < LSide + LSizeX) or (LScreen.X >= (FScreenWidth - LSide - LSizeX))) then
      Exit(True); // at sides (if there are any)
    Result := False;
  end
  else
    Result := (LScreen.X >= 0) and (LScreen.X <= FScreenWidth - 10) and (LScreen.Y >= 0) and
      (LScreen.Y <= FScreenHeight - 10);
end;

end.
