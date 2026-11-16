{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the waggling floor (Hexen)                   }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Plane.Waggle;

// Heights and accumulator are 16.16 fixed point and the old code let the sums wrap
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Thinkers.Plane.Types, DelphiDoom.Thinkers.Plane.Intf;

type
  /// <summary>The floor that moves up and down like a wave (TH_FloorWaggle)</summary>
  TPlaneWaggle = class
  public
    /// <summary>
    ///   One tic of a waggle: the scale grows, stays or shrinks according to the state, and the
    ///   floor is put at the original height plus the bobbing offset times the scale. It gives
    ///   True when the waggle ended (the floor is back at its original height): the game then
    ///   frees the sector and removes the thinker
    /// </summary>
    /// <param name="AWaggle">The state of the waggle, changed in place</param>
    /// <param name="AFloorHeight">The floor height of the sector (changed in place)</param>
    /// <param name="ABobOffsets">The table of the bobbing offsets, at least PLANE_BOB_TABLE_SIZE entries</param>
    /// <param name="AHost">What the game does when a floor moved (it is always asked with the crush flag)</param>
    /// <param name="ASector">The sector, given back to the host as it is</param>
    class function Tick(var AWaggle: TPlaneWaggleState; var AFloorHeight: Integer;
      const ABobOffsets: array of Integer; const AHost: IPlaneSectorHost;
      ASector: Pointer): Boolean; static;
  end;

implementation

uses
  DelphiDoom.MathCore.FixedMath;

const
  SPlaneBobTableTooShort = 'The table of the bobbing offsets has %d entries, %d are needed';

{ TPlaneWaggle }

class function TPlaneWaggle.Tick(var AWaggle: TPlaneWaggleState; var AFloorHeight: Integer;
  const ABobOffsets: array of Integer; const AHost: IPlaneSectorHost;
  ASector: Pointer): Boolean;
begin
  if Length(ABobOffsets) < PLANE_BOB_TABLE_SIZE then
    raise EPlaneException.CreateFmt(SPlaneBobTableTooShort,
      [Length(ABobOffsets), PLANE_BOB_TABLE_SIZE]);

  case AWaggle.State of
    PLANE_WAGGLE_EXPAND:
      begin
        AWaggle.Scale := AWaggle.Scale + AWaggle.ScaleDelta;
        if AWaggle.Scale >= AWaggle.TargetScale then
        begin
          AWaggle.Scale := AWaggle.TargetScale;
          AWaggle.State := PLANE_WAGGLE_STABLE;
        end;
      end;
    PLANE_WAGGLE_REDUCE:
      begin
        AWaggle.Scale := AWaggle.Scale - AWaggle.ScaleDelta;
        if AWaggle.Scale <= 0 then
        begin
          AFloorHeight := AWaggle.OriginalHeight;
          AHost.ChangeSector(ASector, True);
          Exit(True);
        end;
      end;
    PLANE_WAGGLE_STABLE:
      begin
        if AWaggle.Ticker <> -1 then
        begin
          // as the old code: the ticker is decremented and any value but 0 starts the reduction
          Dec(AWaggle.Ticker);
          if AWaggle.Ticker <> 0 then
            AWaggle.State := PLANE_WAGGLE_REDUCE;
        end;
      end;
  end;

  AWaggle.Accumulator := AWaggle.Accumulator + AWaggle.AccDelta;
  AFloorHeight := AWaggle.OriginalHeight +
    TFixedMath.Mul(ABobOffsets[(AWaggle.Accumulator shr 16) and 63], AWaggle.Scale);
  AHost.ChangeSector(ASector, True);
  Result := False;
end;

end.
