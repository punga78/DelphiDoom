{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model of Quake III Arena:     }
{  the area portals                                                            }
{                                                                              }
{  Port of the AREAPORTALS part of cm_test.c (CM_FloodArea_r,                  }
{  CM_FloodAreaConnections, CM_AdjustAreaPortalState, CM_AreasConnected,       }
{  CM_WriteAreaBits) from the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Q3.AreaFlood;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.ClipMap;

type
  /// <summary>
  ///   Which areas are connected through open portals: a flood fill that numbers the areas
  ///   that can reach each other, redone when a portal opens or closes.
  /// </summary>
  TQ3AreaFlood = class
  strict private
    FMap: TQ3ClipMap;
    procedure FloodArea(const AAreaNum, AFloodNum: Integer);
  public
    constructor Create(const AMap: TQ3ClipMap);
    /// <summary>CM_FloodAreaConnections</summary>
    procedure FloodConnections;
    /// <summary>CM_AdjustAreaPortalState</summary>
    procedure AdjustPortalState(const AArea1, AArea2: Integer; const AOpen: Boolean);
    /// <summary>CM_AreasConnected</summary>
    function AreasConnected(const AArea1, AArea2: Integer): Boolean;
    /// <summary>CM_WriteAreaBits: the buffer is made long enough if it is not</summary>
    function WriteAreaBits(var ABuffer: TBytes; const AArea: Integer): Integer;
  end;

implementation

resourcestring
  SReflooded = 'FloodArea_r: reflooded';
  SBadAreaNumber = 'CM_ChangeAreaPortalState: bad area number';
  SNegativeCount = 'CM_AdjustAreaPortalState: negative reference count';
  SAreaTooBig = 'area >= cm.numAreas';
  SBadWriteArea = 'CM_WriteAreaBits: bad area number %d';

constructor TQ3AreaFlood.Create(const AMap: TQ3ClipMap);
begin
  inherited Create;
  FMap := AMap;
end;

procedure TQ3AreaFlood.FloodArea(const AAreaNum, AFloodNum: Integer);
var
  LIndex: Integer;
begin
  if FMap.Areas[AAreaNum].FloodValid = FMap.FloodValid then
  begin
    if FMap.Areas[AAreaNum].FloodNum = AFloodNum then
      Exit;
    raise EQ3CollisionException.Create(SReflooded);
  end;

  FMap.Areas[AAreaNum].FloodNum := AFloodNum;
  FMap.Areas[AAreaNum].FloodValid := FMap.FloodValid;
  for LIndex := 0 to FMap.NumAreas - 1 do
    if FMap.AreaPortals[AAreaNum * FMap.NumAreas + LIndex] > 0 then
      FloodArea(LIndex, AFloodNum);
end;

procedure TQ3AreaFlood.FloodConnections;
var
  LIndex, LFloodNum: Integer;
begin
  // all current floods are now invalid
  Inc(FMap.FloodValid);
  LFloodNum := 0;

  for LIndex := 0 to FMap.NumAreas - 1 do
  begin
    if FMap.Areas[LIndex].FloodValid = FMap.FloodValid then
      Continue; // already flooded into
    Inc(LFloodNum);
    FloodArea(LIndex, LFloodNum);
  end;
end;

procedure TQ3AreaFlood.AdjustPortalState(const AArea1, AArea2: Integer; const AOpen: Boolean);
begin
  if (AArea1 < 0) or (AArea2 < 0) then
    Exit;

  if (AArea1 >= FMap.NumAreas) or (AArea2 >= FMap.NumAreas) then
    raise EQ3CollisionException.Create(SBadAreaNumber);

  if AOpen then
  begin
    Inc(FMap.AreaPortals[AArea1 * FMap.NumAreas + AArea2]);
    Inc(FMap.AreaPortals[AArea2 * FMap.NumAreas + AArea1]);
  end
  else
  begin
    Dec(FMap.AreaPortals[AArea1 * FMap.NumAreas + AArea2]);
    Dec(FMap.AreaPortals[AArea2 * FMap.NumAreas + AArea1]);
    if FMap.AreaPortals[AArea2 * FMap.NumAreas + AArea1] < 0 then
      raise EQ3CollisionException.Create(SNegativeCount);
  end;

  FloodConnections;
end;

function TQ3AreaFlood.AreasConnected(const AArea1, AArea2: Integer): Boolean;
begin
  if FMap.NoAreas then
    Exit(True);

  if (AArea1 < 0) or (AArea2 < 0) then
    Exit(False);

  if (AArea1 >= FMap.NumAreas) or (AArea2 >= FMap.NumAreas) then
    raise EQ3CollisionException.Create(SAreaTooBig);

  Result := FMap.Areas[AArea1].FloodNum = FMap.Areas[AArea2].FloodNum;
end;

function TQ3AreaFlood.WriteAreaBits(var ABuffer: TBytes; const AArea: Integer): Integer;
var
  LIndex, LFloodNum: Integer;
begin
  Result := (FMap.NumAreas + 7) shr 3;
  if Length(ABuffer) < Result then
    SetLength(ABuffer, Result);

  if FMap.NoAreas or (AArea = -1) then
  begin
    // for debugging, send everything
    for LIndex := 0 to Result - 1 do
      ABuffer[LIndex] := 255;
  end
  else
  begin
    // the original does not check the number: it reads outside of the areas
    if (AArea < 0) or (AArea >= FMap.NumAreas) then
      raise EQ3CollisionException.CreateFmt(SBadWriteArea, [AArea]);
    LFloodNum := FMap.Areas[AArea].FloodNum;
    for LIndex := 0 to FMap.NumAreas - 1 do
      if FMap.Areas[LIndex].FloodNum = LFloodNum then
        ABuffer[LIndex shr 3] := ABuffer[LIndex shr 3] or (1 shl (LIndex and 7));
  end;
end;

end.
