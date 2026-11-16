{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the classic floors (T_MoveFloor, EV_DoFloor) }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Floor.Machine;

// The heights are 16.16 fixed point and the old code let the sums wrap
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Thinkers.Floor.Types;

type
  /// <summary>
  ///   The decisions of the classic floors of Doom and of Strife: what a floor that arrived does
  ///   to its sector (T_MoveFloor), the values of a new floor (the case of EV_DoFloor) and of
  ///   the steps of a staircase (EV_BuildStairs). The two old copies of p_floor differ by the
  ///   profile and by the version of the engine (Doom reads it for the old demos)
  /// </summary>
  /// <remarks>No state, no allocation, no call: the game looks for the heights around the sector</remarks>
  TFloorMachine = class sealed
  public
    /// <summary>What a floor of AKind that reached its destination going ADirection changes in its sector</summary>
    class function Arrival(AKind: TFloorKind; ADirection: Integer): TFloorActions; static;
    /// <summary>The values of a new floor of AKind; false for a kind that EV_DoFloor does not make (nothing is written)</summary>
    class function Plan(AKind: TFloorKind; out APlan: TFloorPlan): Boolean; static;
    /// <summary>
    ///   The destination of a new floor whose target is not a texture. ANeighbor is the height
    ///   that the game found around the sector for the target of the plan (unused for Relative)
    /// </summary>
    class function Destination(AKind: TFloorKind; const APlan: TFloorPlan; AFloorHeight,
      ACeilingHeight, ANeighbor: Integer; const AProfile: TFloorProfile): Integer; static;
    /// <summary>
    ///   Where the search of the shortest lower texture starts: no texture found leaves this
    ///   size (32000 units, or the largest integer in the engines up to 1.15)
    /// </summary>
    class function TextureStartSize(AModern: Boolean): Integer; static;
    /// <summary>
    ///   The destination of a floor that rises by the height ASize of a texture; the modern
    ///   engines work in whole units and stop at 32000 so that the sum cannot overflow
    /// </summary>
    class function TextureDestination(AFloorHeight, ASize: Integer; AModern: Boolean): Integer; static;
    /// <summary>The values of the steps of a staircase</summary>
    class function StairPlan(AKind: TStairKind; AModern: Boolean;
      const AProfile: TFloorProfile): TStairPlan; static;
  end;

implementation

uses
  DelphiDoom.MathCore.FixedMath;

const
  CHANGER_KINDS = [TFloorKind.GenFloorChg, TFloorKind.GenFloorChg0, TFloorKind.GenFloorChgT];
  FRACUNIT = 65536;
  CRUSH_GAP = 8 * FRACUNIT;

{ TFloorMachine }

class function TFloorMachine.Arrival(AKind: TFloorKind; ADirection: Integer): TFloorActions;
begin
  Result := [];
  if (ADirection <> 1) and (ADirection <> -1) then
    Exit;
  if AKind in CHANGER_KINDS then
  begin
    // jff: the plain changer keeps the special of the sector
    if AKind <> TFloorKind.GenFloorChg then
      Result := [TFloorAction.TransferSpecial, TFloorAction.TransferOldSpecial];
    Include(Result, TFloorAction.ChangeTexture);
  end
  else if ((ADirection = 1) and (AKind = TFloorKind.DonutRaise)) or
    ((ADirection = -1) and (AKind = TFloorKind.LowerAndChange)) then
    Result := [TFloorAction.TransferSpecial, TFloorAction.ChangeTexture];
end;

class function TFloorMachine.Plan(AKind: TFloorKind; out APlan: TFloorPlan): Boolean;

  procedure Fill(ADirection, ASpeedFactor: Integer; ATarget: TFloorTarget; AOffsetUnits: Integer);
  begin
    APlan.Direction := ADirection;
    APlan.Speed := FLOOR_SPEED * ASpeedFactor;
    APlan.Target := ATarget;
    APlan.Offset := AOffsetUnits * FRACUNIT;
  end;

begin
  Result := True;
  APlan.Direction := 0;
  APlan.Speed := 0;
  APlan.Crush := False;
  APlan.Target := TFloorTarget.Relative;
  APlan.Offset := 0;
  APlan.ChangeFromLine := False;
  APlan.ChangeOldSpecialToo := False;
  APlan.CarriesModel := False;
  case AKind of
    TFloorKind.LowerFloor:
      Fill(-1, 1, TFloorTarget.HighestFloor, 0);
    // jff 02/03/30: "lowering" by 24 and by 32 add to the height, as the old code did
    TFloorKind.LowerFloor24:
      Fill(-1, 1, TFloorTarget.Relative, 24);
    TFloorKind.LowerFloor32Turbo:
      Fill(-1, 4, TFloorTarget.Relative, 32);
    TFloorKind.LowerFloorToLowest:
      Fill(-1, 1, TFloorTarget.LowestFloor, 0);
    TFloorKind.LowerFloorToNearest:
      Fill(-1, 1, TFloorTarget.NextLowestFloor, 0);
    TFloorKind.TurboLower:
      Fill(-1, 4, TFloorTarget.HighestFloor, 0);
    TFloorKind.RaiseFloorCrush:
      begin
        Fill(1, 1, TFloorTarget.LowestCeiling, 0);
        APlan.Crush := True;
      end;
    TFloorKind.RaiseFloor:
      Fill(1, 1, TFloorTarget.LowestCeiling, 0);
    TFloorKind.RaiseFloorTurbo:
      Fill(1, 4, TFloorTarget.NextHighestFloor, 0);
    TFloorKind.RaiseFloorToNearest:
      Fill(1, 1, TFloorTarget.NextHighestFloor, 0);
    TFloorKind.RaiseFloor24:
      Fill(1, 1, TFloorTarget.Relative, 24);
    TFloorKind.RaiseFloor64:
      Fill(1, 1, TFloorTarget.Relative, 64);
    TFloorKind.RaiseFloor32Turbo:
      Fill(1, 4, TFloorTarget.Relative, 32);
    TFloorKind.RaiseFloor512:
      Fill(1, 1, TFloorTarget.Relative, 512);
    TFloorKind.RaiseFloor24AndChange:
      begin
        Fill(1, 1, TFloorTarget.Relative, 24);
        APlan.ChangeFromLine := True;
        APlan.ChangeOldSpecialToo := True;
      end;
    TFloorKind.RaiseFloor512AndChange:
      begin
        Fill(1, 1, TFloorTarget.Relative, 512);
        APlan.ChangeFromLine := True;
      end;
    TFloorKind.RaiseToTexture:
      Fill(1, 1, TFloorTarget.ShortestTexture, 0);
    TFloorKind.LowerAndChange:
      begin
        Fill(-1, 1, TFloorTarget.LowestFloor, 0);
        APlan.CarriesModel := True;
      end;
  else
    Result := False;
  end;
end;

class function TFloorMachine.Destination(AKind: TFloorKind; const APlan: TFloorPlan;
  AFloorHeight, ACeilingHeight, ANeighbor: Integer; const AProfile: TFloorProfile): Integer;
begin
  case APlan.Target of
    TFloorTarget.Relative:
      Result := AFloorHeight + APlan.Offset;
    TFloorTarget.LowestCeiling:
      begin
        Result := ANeighbor;
        if Result > ACeilingHeight then
          Result := ACeilingHeight;
        if AKind = TFloorKind.RaiseFloorCrush then
          Result := Result - CRUSH_GAP;
      end;
  else
    begin
      Result := ANeighbor;
      if (AKind = TFloorKind.TurboLower) and AProfile.TurboLowerStopsAbove and
        (Result <> AFloorHeight) then
        Result := Result + CRUSH_GAP;
    end;
  end;
end;

class function TFloorMachine.TextureStartSize(AModern: Boolean): Integer;
begin
  if AModern then
    Result := FLOOR_TEXTURE_LIMIT * FRACUNIT // Don't overflow
  else
    Result := MaxInt;
end;

class function TFloorMachine.TextureDestination(AFloorHeight, ASize: Integer;
  AModern: Boolean): Integer;
begin
  if not AModern then
    Exit(AFloorHeight + ASize);
  // FixedInt of the engine: the arithmetic shift, also for a floor below zero
  Result := TFixedMath.ToInteger(AFloorHeight) + TFixedMath.ToInteger(ASize);
  if Result > FLOOR_TEXTURE_LIMIT then
    Result := FLOOR_TEXTURE_LIMIT * FRACUNIT
  else
    Result := Result * FRACUNIT;
end;

class function TFloorMachine.StairPlan(AKind: TStairKind; AModern: Boolean;
  const AProfile: TFloorProfile): TStairPlan;
begin
  Result.Speed := 0;
  Result.StepSize := 0;
  Result.Direction := 1;
  Result.FirstIsStair := not AProfile.StrifeStairs;
  Result.FirstCrush := False;
  // the steps after the first crush unless they are the slow ones; the engines of Doom up to
  // 1.15 never set the flag
  Result.NextCrush := AModern and (AKind <> TStairKind.Build8);
  Result.ClearFirstTag := AProfile.StrifeStairs;
  case AKind of
    TStairKind.Build8:
      begin
        Result.Speed := FLOOR_SPEED div 4;
        Result.StepSize := 8 * FRACUNIT;
      end;
    TStairKind.Turbo16:
      begin
        Result.Speed := FLOOR_SPEED * 4;
        Result.StepSize := 16 * FRACUNIT;
        // Strife leaves the first step as a plain floor that does not crush
        Result.FirstCrush := AModern and not AProfile.StrifeStairs;
      end;
    TStairKind.BuildDown16:
      begin
        Result.Speed := FLOOR_SPEED;
        Result.StepSize := -16 * FRACUNIT;
        Result.Direction := -1;
      end;
  else
    // a kind that the game does not have: Strife does not even move it
    if AProfile.StrifeStairs then
      Result.Direction := 0;
  end;
end;

end.
