{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - the view angles                                 }
{                                                                              }
{  Port of PM_UpdateViewAngles of bg_pmove.c, from the Quake III Arena GPL     }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.ViewAngles;

// the sum of the command angle and the delta angle is stored in a short: it wraps around
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Types, DelphiDoom.Pmove.Types;

type
  /// <summary>The angles the player looks at: the command angles plus the delta angles of the state</summary>
  TPmoveViewAngles = class
  public
    /// <summary>
    ///   PM_UpdateViewAngles: circularly clamps the angles with the deltas; the pitch never goes over 90
    ///   degrees up or down (the delta angle of the state is moved to keep it there). It can be used alone when
    ///   only the view angles are updated instead of a full move
    /// </summary>
    class procedure Update(var APlayerState: TQ3PlayerState; const ACommand: TQ3UserCmd); static;
    /// <summary>SHORT2ANGLE: a 16 bit angle in degrees, the factor is a double</summary>
    class function ShortToAngle(const AValue: SmallInt): Single; static;
  end;

implementation

class function TPmoveViewAngles.ShortToAngle(const AValue: SmallInt): Single;
const
  FACTOR: Double = 360.0 / 65536;
var
  LAngle: Double;
begin
  LAngle := AValue * FACTOR;
  Result := LAngle;
end;

class procedure TPmoveViewAngles.Update(var APlayerState: TQ3PlayerState; const ACommand: TQ3UserCmd);
var
  LIndex: Integer;
  LTemp: SmallInt;
begin
  if (APlayerState.PmType = Q3_PM_INTERMISSION) or (APlayerState.PmType = Q3_PM_SPINTERMISSION) then
    Exit; // no view changes at all

  if (APlayerState.PmType <> Q3_PM_SPECTATOR) and (APlayerState.Stats[Q3_STAT_HEALTH] <= 0) then
    Exit; // no view changes at all

  // circularly clamp the angles with deltas
  for LIndex := 0 to 2 do
  begin
    LTemp := SmallInt(ACommand.Angles[LIndex] + APlayerState.DeltaAngles[LIndex]);
    if LIndex = Q3_PITCH then
    begin
      // don't let the player look up or down more than 90 degrees
      if LTemp > 16000 then
      begin
        APlayerState.DeltaAngles[LIndex] := 16000 - ACommand.Angles[LIndex];
        LTemp := 16000;
      end
      else if LTemp < -16000 then
      begin
        APlayerState.DeltaAngles[LIndex] := -16000 - ACommand.Angles[LIndex];
        LTemp := -16000;
      end;
    end;
    APlayerState.ViewAngles[LIndex] := ShortToAngle(LTemp);
  end;
end;

end.
