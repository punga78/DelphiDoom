{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixControlRules                              }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the rules of the afterburner and of the key of the plasma bomb of   }
{  G_BuildTiccmd (g_game.pas), RX_PlayerThink (radix_player.pas) and           }
{  P_PlayerThink (p_user.pas) of Rad-X                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Control.Rules;

interface

type
  /// <summary>
  ///   The two keys that the craft of Radix has more than the marine of Doom. The afterburner works
  ///   while the craft is pushed and has energy left, makes it faster and drains the energy; the
  ///   plasma bomb goes off once for every press of its key
  /// </summary>
  TRadixControlRules = class
  public const
    /// <summary>The afterburner needs more energy than this (MIN_AFTERBURNER_ENERGY of Rad-X)</summary>
    MIN_AFTERBURNER_ENERGY = 4;
    /// <summary>The afterburner takes one point of energy every so many tics (leveltime and 7 = 0)</summary>
    AFTERBURNER_DRAIN_PERIOD = 8;
    /// <summary>The forward move of the ticcmd of a craft that runs, and with the afterburner (forwardmove[1], [2])</summary>
    RUN_MOVE = $32;
    AFTERBURNER_MOVE = $46;
  public
    /// <summary>
    ///   The afterburner is on: its key is down, the craft is pushed forward, backward or sideways and
    ///   has more than MIN_AFTERBURNER_ENERGY
    /// </summary>
    class function AfterburnerOn(AKeyDown: Boolean; AEnergy, AForwardMove, ASideMove: Integer): Boolean; static;
    /// <summary>
    ///   What the afterburner adds on one axis to the way a craft makes in a tic at AMomentum: Rad-X
    ///   pushed 70 instead of 50, so with the same drag the speed was 7/5 and the rest is 2/5
    /// </summary>
    class function AfterburnerSlide(AMomentum: Integer): Integer; static;
    /// <summary>
    ///   The energy that the afterburner takes at the tic ALevelTime: one point every
    ///   AFTERBURNER_DRAIN_PERIOD tics, from the reserve first and then from the energy. True when a
    ///   point was taken
    /// </summary>
    class function DrainAfterburner(ALevelTime: Integer; var AEnergyReserve, AEnergy: Integer): Boolean; static;
    /// <summary>
    ///   A plasma bomb is asked: the key went down at this tic. AWasDown is the state that the caller
    ///   keeps, and becomes the state of the key
    /// </summary>
    class function PlasmaBombAsked(AKeyDown: Boolean; var AWasDown: Boolean): Boolean; static;
  end;

implementation

{ TRadixControlRules }

class function TRadixControlRules.AfterburnerOn(AKeyDown: Boolean; AEnergy, AForwardMove,
  ASideMove: Integer): Boolean;
begin
  Result := AKeyDown and (AEnergy > MIN_AFTERBURNER_ENERGY) and ((AForwardMove <> 0) or (ASideMove <> 0));
end;

class function TRadixControlRules.AfterburnerSlide(AMomentum: Integer): Integer;
begin
  Result := Integer(Int64(AMomentum) * (AFTERBURNER_MOVE - RUN_MOVE) div RUN_MOVE);
end;

class function TRadixControlRules.DrainAfterburner(ALevelTime: Integer; var AEnergyReserve,
  AEnergy: Integer): Boolean;
begin
  Result := False;
  if ALevelTime mod AFTERBURNER_DRAIN_PERIOD <> 0 then
    Exit;
  if AEnergyReserve > 0 then
  begin
    Dec(AEnergyReserve);
    Result := True;
  end
  else if AEnergy > 0 then
  begin
    Dec(AEnergy);
    Result := True;
  end;
end;

class function TRadixControlRules.PlasmaBombAsked(AKeyDown: Boolean; var AWasDown: Boolean): Boolean;
begin
  Result := AKeyDown and not AWasDown;
  AWasDown := AKeyDown;
end;

end.
