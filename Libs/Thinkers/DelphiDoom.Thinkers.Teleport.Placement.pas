{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the height of a thing after a teleport       }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Teleport.Placement;

// Heights are fixed point: the old code let the sums wrap and so does this one
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types;

type
  /// <summary>What decides the height of a thing that was moved to the destination of a teleport</summary>
  TTeleportSettleInput = record
    IsPlayer: Boolean;
    IsMissile: Boolean;
    /// <summary>The player flies (Heretic and Hexen; false in Doom and Strife)</summary>
    IsFlying: Boolean;
    /// <summary>How high the thing was above its floor before the teleport</summary>
    AboveFloor: TFixed;
    /// <summary>The floor and the ceiling of the destination, and the height of the thing</summary>
    FloorZ: TFixed;
    CeilingZ: TFixed;
    Height: TFixed;
    /// <summary>The teleport makes fog: then a player also looks straight ahead</summary>
    UseFog: Boolean;
  end;

  /// <summary>The height of the thing and what the game must do to the view of a player</summary>
  TTeleportSettleOutput = record
    Z: TFixed;
    /// <summary>The thing is a player: its view height follows the new height</summary>
    UpdatesViewHeight: Boolean;
    /// <summary>The player looks straight ahead (the look up/down is zero)</summary>
    ResetsLook: Boolean;
  end;

  /// <summary>
  ///   The height at which a thing lands (P_Teleport of Heretic and PH_Teleport): on the floor,
  ///   except a flying player and a missile, which keep their height above it without touching the
  ///   ceiling
  /// </summary>
  TTeleportPlacement = class
  public
    class procedure Settle(const AInput: TTeleportSettleInput;
      out AOutput: TTeleportSettleOutput); static;
  end;

implementation

{ TTeleportPlacement }

class procedure TTeleportPlacement.Settle(const AInput: TTeleportSettleInput;
  out AOutput: TTeleportSettleOutput);
begin
  AOutput.UpdatesViewHeight := False;
  AOutput.ResetsLook := False;

  if AInput.IsPlayer then
  begin
    AOutput.UpdatesViewHeight := True;
    if AInput.IsFlying and (AInput.AboveFloor <> 0) then
    begin
      AOutput.Z := AInput.FloorZ + AInput.AboveFloor;
      if AOutput.Z + AInput.Height > AInput.CeilingZ then
        AOutput.Z := AInput.CeilingZ - AInput.Height;
    end
    else
    begin
      AOutput.Z := AInput.FloorZ;
      AOutput.ResetsLook := AInput.UseFog;
    end;
  end
  else if AInput.IsMissile then
  begin
    AOutput.Z := AInput.FloorZ + AInput.AboveFloor;
    if AOutput.Z + AInput.Height > AInput.CeilingZ then
      AOutput.Z := AInput.CeilingZ - AInput.Height;
  end
  else
    AOutput.Z := AInput.FloorZ;
end;

end.
