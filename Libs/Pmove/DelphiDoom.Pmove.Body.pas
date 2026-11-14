{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - the body of the player: water level and size    }
{                                                                              }
{  Port of PM_SetWaterLevel and PM_CheckDuck of bg_pmove.c, from the Quake III }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.Body;

// float arithmetic as the C code does it: one operation at a time, into a Single
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Pmove.Types, DelphiDoom.Pmove.State;

type
  /// <summary>How deep in water the player is and how big its box is (standing, ducking, dead)</summary>
  TPmoveBody = class
  strict private
    FState: TPmoveState;
  public
    constructor Create(const AState: TPmoveState);
    /// <summary>PM_SetWaterLevel: the water level (0 to 3) and type, accounting for ducking</summary>
    procedure SetWaterLevel;
    /// <summary>PM_CheckDuck: sets mins, maxs and the view height</summary>
    procedure CheckDuck;
  end;

implementation

constructor TPmoveBody.Create(const AState: TPmoveState);
begin
  inherited Create;
  FState := AState;
end;

procedure TPmoveBody.SetWaterLevel;
var
  LPoint: TQ3Vec3;
  LContents, LSample1, LSample2: Integer;
  LOrigin: PQ3Vec3;
  LHeight: Single;
begin
  // get waterlevel, accounting for ducking
  FState.Pm.WaterLevel := 0;
  FState.Pm.WaterType := 0;
  LOrigin := FState.Origin;

  LPoint[0] := LOrigin^[0];
  LPoint[1] := LOrigin^[1];
  LHeight := LOrigin^[2] + Q3_MINS_Z;
  LPoint[2] := LHeight + 1;
  LContents := FState.PointContents(LPoint);

  if (LContents and Q3_MASK_WATER) <> 0 then
  begin
    LSample2 := FState.Pm.Ps.ViewHeight - Q3_MINS_Z;
    LSample1 := LSample2 div 2;

    FState.Pm.WaterType := LContents;
    FState.Pm.WaterLevel := 1;
    LHeight := LOrigin^[2] + Q3_MINS_Z;
    LPoint[2] := LHeight + LSample1;
    LContents := FState.PointContents(LPoint);
    if (LContents and Q3_MASK_WATER) <> 0 then
    begin
      FState.Pm.WaterLevel := 2;
      LHeight := LOrigin^[2] + Q3_MINS_Z;
      LPoint[2] := LHeight + LSample2;
      LContents := FState.PointContents(LPoint);
      if (LContents and Q3_MASK_WATER) <> 0 then
        FState.Pm.WaterLevel := 3;
    end;
  end;
end;

procedure TPmoveBody.CheckDuck;
var
  LTrace: TQ3Trace;
begin
  if FState.Pm.Ps.Powerups[Q3_PW_INVULNERABILITY] <> 0 then
  begin
    if (FState.Pm.Ps.PmFlags and Q3_PMF_INVULEXPAND) <> 0 then
    begin
      // invulnerability sphere has a 42 units radius
      FState.Pm.Mins[0] := -42;
      FState.Pm.Mins[1] := -42;
      FState.Pm.Mins[2] := -42;
      FState.Pm.Maxs[0] := 42;
      FState.Pm.Maxs[1] := 42;
      FState.Pm.Maxs[2] := 42;
    end
    else
    begin
      FState.Pm.Mins[0] := -15;
      FState.Pm.Mins[1] := -15;
      FState.Pm.Mins[2] := Q3_MINS_Z;
      FState.Pm.Maxs[0] := 15;
      FState.Pm.Maxs[1] := 15;
      FState.Pm.Maxs[2] := 16;
    end;
    FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags or Q3_PMF_DUCKED;
    FState.Pm.Ps.ViewHeight := Q3_CROUCH_VIEWHEIGHT;
    Exit;
  end;
  FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags and (not Q3_PMF_INVULEXPAND);

  FState.Pm.Mins[0] := -15;
  FState.Pm.Mins[1] := -15;

  FState.Pm.Maxs[0] := 15;
  FState.Pm.Maxs[1] := 15;

  FState.Pm.Mins[2] := Q3_MINS_Z;

  if FState.Pm.Ps.PmType = Q3_PM_DEAD then
  begin
    FState.Pm.Maxs[2] := -8;
    FState.Pm.Ps.ViewHeight := Q3_DEAD_VIEWHEIGHT;
    Exit;
  end;

  if FState.Pm.Cmd.UpMove < 0 then
    // duck
    FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags or Q3_PMF_DUCKED
  else if (FState.Pm.Ps.PmFlags and Q3_PMF_DUCKED) <> 0 then
  begin
    // stand up if possible: try to stand up
    FState.Pm.Maxs[2] := 32;
    LTrace := FState.Trace(FState.Origin^, FState.Pm.Mins, FState.Pm.Maxs, FState.Origin^);
    if not LTrace.AllSolid then
      FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags and (not Q3_PMF_DUCKED);
  end;

  if (FState.Pm.Ps.PmFlags and Q3_PMF_DUCKED) <> 0 then
  begin
    FState.Pm.Maxs[2] := 16;
    FState.Pm.Ps.ViewHeight := Q3_CROUCH_VIEWHEIGHT;
  end
  else
  begin
    FState.Pm.Maxs[2] := 32;
    FState.Pm.Ps.ViewHeight := Q3_DEFAULT_VIEWHEIGHT;
  end;
end;

end.
