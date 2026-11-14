{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixFlightModel                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the arithmetic of the flight of P_MovePlayer (p_user.pas of Rad-X)   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Flight.Model;

interface

type
  /// <summary>
  ///   The numbers of the flight of the craft: the drag at every tic, the climb or the dive that
  ///   comes from the pitch while the craft moves forward, the fixed speed of the keys that fly
  ///   up and down. Momenta are 16.16 fixed point; the pitch is lookdir16 of the engine (16 for
  ///   each step of the look up/down)
  /// </summary>
  TRadixFlightModel = class
  public const
    /// <summary>The vertical speed of the keys fly up / fly down (8 map units a tic)</summary>
    FLY_KEY_SPEED = 8 * 65536;
    /// <summary>The move factor is multiplied by this (16.16) with the maneuver jets: 160000 / 65536</summary>
    MANEUVER_JETS_FACTOR = 160000;
  public
    /// <summary>The momentum on one axis after the drag of a tic: 15/16, or 7/8 with the maneuver jets</summary>
    class function Drag(AMomentum: Integer; AManeuverJets: Boolean): Integer; static;
    /// <summary>The vertical momentum after the drag of a tic (always 15/16)</summary>
    class function VerticalDrag(AMomentum: Integer): Integer; static;
    /// <summary>
    ///   The vertical momentum that the pitch gives to a craft that moves at AForwardSpeed along
    ///   its nose (negative when it slides backwards): (speed / 16) * pitch / 256
    /// </summary>
    class function PitchThrust(AForwardSpeed, ALookDir16: Integer): Integer; static;
    /// <summary>
    ///   The vertical momentum of a tic. The thrust of the pitch of the tic before is taken away,
    ///   the rest is dragged, the new thrust is added
    /// </summary>
    /// <param name="APreviousThrust">What PitchThrust gave the tic before</param>
    /// <param name="ANewThrust">What PitchThrust gives now (the caller keeps it for the next tic)</param>
    class function VerticalMomentum(AMomentum, APreviousThrust, ANewThrust: Integer): Integer; static;
    /// <summary>The move factor of the craft: the one of the sector, larger with the maneuver jets</summary>
    class function MoveFactor(ASectorFactor: Integer; AManeuverJets: Boolean): Integer; static;
    /// <summary>
    ///   True for a craft that something stopped: it had a speed of at least STOPPED_MIN_SPEED on
    ///   the plane at the end of the tic before and in this tic it has made less than half of that
    ///   way (16.16 fixed point). The count of the hits against the walls of the debriefing
    /// </summary>
    class function IsStopped(AMomentumX, AMomentumY, ADeltaX, ADeltaY: Integer): Boolean; static;
  public const
    /// <summary>A slower craft is not counted as stopped (4 map units a tic)</summary>
    STOPPED_MIN_SPEED = 4 * 65536;
  end;

implementation

{ TRadixFlightModel }

class function TRadixFlightModel.IsStopped(AMomentumX, AMomentumY, ADeltaX, ADeltaY: Integer): Boolean;
var
  LSpeedSquare: Double;
  LWaySquare: Double;
begin
  LSpeedSquare := Double(AMomentumX) * AMomentumX + Double(AMomentumY) * AMomentumY;
  LWaySquare := Double(ADeltaX) * ADeltaX + Double(ADeltaY) * ADeltaY;
  Result := (LSpeedSquare >= Double(STOPPED_MIN_SPEED) * STOPPED_MIN_SPEED) and (4 * LWaySquare < LSpeedSquare);
end;

class function TRadixFlightModel.Drag(AMomentum: Integer; AManeuverJets: Boolean): Integer;
begin
  if AManeuverJets then
    Result := Integer(Int64(AMomentum) * 7 div 8)
  else
    Result := Integer(Int64(AMomentum) * 15 div 16);
end;

class function TRadixFlightModel.VerticalDrag(AMomentum: Integer): Integer;
begin
  Result := Integer(Int64(AMomentum) * 15 div 16);
end;

class function TRadixFlightModel.PitchThrust(AForwardSpeed, ALookDir16: Integer): Integer;
begin
  Result := Integer((Int64(AForwardSpeed div 16) * ALookDir16) div 256);
end;

class function TRadixFlightModel.VerticalMomentum(AMomentum, APreviousThrust, ANewThrust: Integer): Integer;
begin
  Result := VerticalDrag(AMomentum - APreviousThrust) + ANewThrust;
end;

class function TRadixFlightModel.MoveFactor(ASectorFactor: Integer; AManeuverJets: Boolean): Integer;
begin
  if AManeuverJets then
    Result := Integer((Int64(ASectorFactor) * MANEUVER_JETS_FACTOR) div 65536)
  else
    Result := ASectorFactor;
end;

end.
