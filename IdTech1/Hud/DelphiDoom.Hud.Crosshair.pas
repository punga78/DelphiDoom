{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - the crosshair                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.Crosshair;

interface

uses
  DelphiDoom.Hud.Types;

type
  /// <summary>Which crosshair to draw and where, from what the player aims at</summary>
  THudCrosshair = class sealed
  public
    /// <summary>
    ///   The crosshair to draw: 0 is the still one (nothing or a friend aimed at), 1 to 4 are the
    ///   spinning ones of an enemy, that change every eight tics from the moment it was aimed at
    /// </summary>
    class function PatchIndex(const ATarget: THudCrosshairTarget;
      const ALevelTime, ACrossTic: Integer): Integer; static;
    /// <summary>
    ///   Columns the crosshair moves to the side when the player looks up or down (lookdir2 is a
    ///   byte: below 128 it is up, else down)
    /// </summary>
    class function OffsetX(const ALookDir, AViewWidth: Integer): Integer; static;
  end;

implementation

{ THudCrosshair }

class function THudCrosshair.PatchIndex(const ATarget: THudCrosshairTarget;
  const ALevelTime, ACrossTic: Integer): Integer;
begin
  if ATarget = THudCrosshairTarget.Enemy then
    Result := (((ALevelTime - ACrossTic) div 8) mod 4) + 1
  else
    Result := 0;
end;

class function THudCrosshair.OffsetX(const ALookDir, AViewWidth: Integer): Integer;
begin
  if ALookDir < 128 then
    Result := ALookDir * AViewWidth div 40
  else
    Result := -(255 - ALookDir) * AViewWidth div 40;
end;

end.
