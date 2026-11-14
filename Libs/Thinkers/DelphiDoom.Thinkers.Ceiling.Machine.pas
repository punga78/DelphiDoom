{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the classic ceilings (T_MoveCeiling)         }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Ceiling.Machine;

// The heights are 16.16 fixed point and the old code let the sums wrap
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Thinkers.Plane.Types, DelphiDoom.Thinkers.Ceiling.Types;

type
  /// <summary>
  ///   The decisions of the classic ceilings of Doom, Heretic and Strife: what happens after a
  ///   step (the three old copies of T_MoveCeiling were the same code on the kinds that each game
  ///   has) and the values of a new ceiling (EV_DoCeiling, with the profile of the game)
  /// </summary>
  /// <remarks>
  ///   The tic runs for every moving ceiling: no state, no allocation, no call. The step itself is
  ///   TPlaneMover and the game does what the returned actions say (sounds, sector, removal)
  /// </remarks>
  TCeilingMachine = class sealed
  public
    /// <summary>
    ///   What follows a step of a ceiling that goes up (AState.Direction = 1) or down (-1); any
    ///   other direction (in stasis) does nothing: the caller does not even move the plane
    /// </summary>
    /// <param name="AKind">The kind of the ceiling</param>
    /// <param name="AState">Direction and speeds of the thinker, changed in place</param>
    /// <param name="AResult">What the step did</param>
    /// <param name="ASoundTic">True on the tics when a moving ceiling makes its sound (one in eight)</param>
    class function AfterMove(AKind: TCeilingKind; var AState: TCeilingState;
      AResult: TPlaneMoveResult; ASoundTic: Boolean): TCeilingActions; static;
    /// <summary>
    ///   The values of a new ceiling. Only the fields that the kind sets are written (the old code
    ///   left the others as they were); the result says which height around the sector the caller
    ///   still has to put in TopHeight or BottomHeight
    /// </summary>
    class function Configure(AKind: TCeilingKind; AFloorHeight, ACeilingHeight: Integer;
      const AProfile: TCeilingProfile; var ASpawn: TCeilingSpawn): TCeilingNeighbor; static;
    /// <summary>True for the kinds whose line first wakes up the stopped ceilings of its tag</summary>
    class function WakesUpStopped(AKind: TCeilingKind): Boolean; static; inline;
  end;

implementation

const
  SILENT_KINDS = [TCeilingKind.SilentCrushAndRaise, TCeilingKind.GenSilentCrusher];
  CHANGER_KINDS = [TCeilingKind.GenCeilingChg, TCeilingKind.GenCeilingChg0,
    TCeilingKind.GenCeilingChgT];
  GENERALIZED_CRUSHERS = [TCeilingKind.GenCrusher, TCeilingKind.GenSilentCrusher];
  // a generalized crusher this fast is not slowed by an obstacle
  FAST_CRUSHER_SPEED = CEILING_SPEED * 3;
  SLOWED_SPEED = CEILING_SPEED div 8;

{ TCeilingMachine }

class function TCeilingMachine.AfterMove(AKind: TCeilingKind; var AState: TCeilingState;
  AResult: TPlaneMoveResult; ASoundTic: Boolean): TCeilingActions;
begin
  Result := [];
  if (AState.Direction <> 1) and (AState.Direction <> -1) then
    Exit;

  if ASoundTic and not (AKind in SILENT_KINDS) then
    Include(Result, TCeilingAction.MoveSound);

  if AResult = TPlaneMoveResult.PastDest then
  begin
    if AKind in CHANGER_KINDS then
    begin
      // jff 3/14/98: the plain changer keeps the special of the sector
      if AKind <> TCeilingKind.GenCeilingChg then
        Include(Result, TCeilingAction.TransferSpecial);
      Result := Result + [TCeilingAction.ChangeTexture, TCeilingAction.Remove];
    end
    else if AState.Direction = 1 then
    begin
      case AKind of
        TCeilingKind.RaiseToHighest,
        TCeilingKind.GenCeiling:
          Include(Result, TCeilingAction.Remove);
        TCeilingKind.SilentCrushAndRaise:
          begin
            Include(Result, TCeilingAction.StopSound);
            AState.Direction := -1;
          end;
        TCeilingKind.FastCrushAndRaise,
        TCeilingKind.CrushAndRaise,
        TCeilingKind.GenSilentCrusher,
        TCeilingKind.GenCrusher:
          AState.Direction := -1;
      end;
    end
    else
    begin
      case AKind of
        // 02/09/98 jff: change slow crushers' speed back to normal and start back up
        TCeilingKind.GenSilentCrusher,
        TCeilingKind.GenCrusher:
          begin
            if AState.OldSpeed < FAST_CRUSHER_SPEED then
              AState.Speed := AState.OldSpeed;
            AState.Direction := 1;
          end;
        TCeilingKind.SilentCrushAndRaise:
          begin
            Include(Result, TCeilingAction.StopSound);
            AState.Speed := CEILING_SPEED;
            AState.Direction := 1;
          end;
        TCeilingKind.CrushAndRaise:
          begin
            AState.Speed := CEILING_SPEED;
            AState.Direction := 1;
          end;
        TCeilingKind.FastCrushAndRaise:
          AState.Direction := 1;
        TCeilingKind.LowerAndCrush,
        TCeilingKind.LowerToFloor,
        TCeilingKind.LowerToLowest,
        TCeilingKind.LowerToMaxFloor,
        TCeilingKind.GenCeiling:
          Include(Result, TCeilingAction.Remove);
      end;
    end;
  end
  else if (AResult = TPlaneMoveResult.Crushed) and (AState.Direction = -1) then
  begin
    // jff 02/08/98: slow down slow crushers on obstacle
    if AKind in GENERALIZED_CRUSHERS then
    begin
      if AState.OldSpeed < FAST_CRUSHER_SPEED then
        AState.Speed := SLOWED_SPEED;
    end
    else if AKind in [TCeilingKind.SilentCrushAndRaise, TCeilingKind.CrushAndRaise,
      TCeilingKind.LowerAndCrush] then
      AState.Speed := SLOWED_SPEED;
  end;
end;

class function TCeilingMachine.Configure(AKind: TCeilingKind; AFloorHeight,
  ACeilingHeight: Integer; const AProfile: TCeilingProfile;
  var ASpawn: TCeilingSpawn): TCeilingNeighbor;
begin
  Result := TCeilingNeighbor.None;
  case AKind of
    TCeilingKind.FastCrushAndRaise:
      begin
        ASpawn.Crush := True;
        ASpawn.TopHeight := ACeilingHeight;
        ASpawn.BottomHeight := AFloorHeight + CEILING_CRUSH_GAP;
        ASpawn.Direction := -1;
        ASpawn.Speed := CEILING_SPEED * AProfile.FastCrushSpeedFactor;
      end;
    TCeilingKind.SilentCrushAndRaise,
    TCeilingKind.CrushAndRaise:
      begin
        if AProfile.CrushAndRaiseCrushes then
          ASpawn.Crush := True;
        ASpawn.TopHeight := ACeilingHeight;
        ASpawn.BottomHeight := AFloorHeight + CEILING_CRUSH_GAP;
        ASpawn.Direction := -1;
        ASpawn.Speed := CEILING_SPEED;
      end;
    TCeilingKind.LowerAndCrush:
      begin
        if AProfile.LowerAndCrushReachesFloor then
        begin
          ASpawn.Crush := True;
          ASpawn.BottomHeight := AFloorHeight;
        end
        else
          ASpawn.BottomHeight := AFloorHeight + CEILING_CRUSH_GAP;
        ASpawn.Direction := -1;
        ASpawn.Speed := CEILING_SPEED;
      end;
    TCeilingKind.LowerToFloor:
      begin
        ASpawn.BottomHeight := AFloorHeight;
        ASpawn.Direction := -1;
        ASpawn.Speed := CEILING_SPEED;
      end;
    TCeilingKind.RaiseToHighest:
      begin
        Result := TCeilingNeighbor.TopHighestCeiling;
        ASpawn.Direction := 1;
        ASpawn.Speed := CEILING_SPEED;
      end;
    TCeilingKind.LowerToLowest:
      begin
        Result := TCeilingNeighbor.BottomLowestCeiling;
        ASpawn.Direction := -1;
        ASpawn.Speed := CEILING_SPEED;
      end;
    TCeilingKind.LowerToMaxFloor:
      begin
        Result := TCeilingNeighbor.BottomHighestFloor;
        ASpawn.Direction := -1;
        ASpawn.Speed := CEILING_SPEED;
      end;
  end;
end;

class function TCeilingMachine.WakesUpStopped(AKind: TCeilingKind): Boolean;
begin
  Result := AKind in [TCeilingKind.FastCrushAndRaise, TCeilingKind.SilentCrushAndRaise,
    TCeilingKind.CrushAndRaise];
end;

end.
