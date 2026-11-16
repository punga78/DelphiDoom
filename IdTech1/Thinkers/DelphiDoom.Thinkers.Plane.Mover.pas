{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the step of a moving plane (T_MovePlane)     }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Plane.Mover;

// The heights are 16.16 fixed point and the old code let the sums wrap
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Thinkers.Plane.Types, DelphiDoom.Thinkers.Plane.Intf;

type
  /// <summary>
  ///   The move of a floor or of a ceiling by one step, shared by floors, ceilings, doors,
  ///   platforms and pillars (the four old copies of T_MovePlane in one)
  /// </summary>
  /// <remarks>
  ///   It runs for every moving sector at every tic: it has no state, makes no allocation and
  ///   asks the host at most twice per step (once when the step is blocked and has to be undone)
  /// </remarks>
  TPlaneMover = class
  public
    /// <summary>
    ///   Moves a plane towards ADestination by ASpeed in ADirection (-1 down, 1 up, anything else
    ///   does nothing but ends as Ok). The height is written first, then the host is asked: when
    ///   the host says that something blocks it the step is undone, as the rules say
    /// </summary>
    /// <param name="APlaneHeight">The height of the plane that moves (the field of the sector, changed in place)</param>
    /// <param name="AOtherHeight">The height of the other plane of the sector (only read, for the clamp)</param>
    /// <param name="ASpeed">How much the plane moves in a step</param>
    /// <param name="ADestination">The height where the plane stops</param>
    /// <param name="ACrush">True when the plane may crush what is in its way</param>
    /// <param name="AKind">Which plane moves</param>
    /// <param name="ADirection">-1 down, 1 up</param>
    /// <param name="ARules">The rules of the game</param>
    /// <param name="AHost">What the game does when a plane moved</param>
    /// <param name="ASector">The sector, given back to the host as it is</param>
    class function Move(var APlaneHeight: Integer; AOtherHeight, ASpeed, ADestination: Integer;
      ACrush: Boolean; AKind: TPlaneKind; ADirection: Integer; const ARules: TPlaneMoveRules;
      const AHost: IPlaneSectorHost; ASector: Pointer): TPlaneMoveResult; static;
  end;

implementation

{ TPlaneMover }

class function TPlaneMover.Move(var APlaneHeight: Integer; AOtherHeight, ASpeed,
  ADestination: Integer; ACrush: Boolean; AKind: TPlaneKind; ADirection: Integer;
  const ARules: TPlaneMoveRules; const AHost: IPlaneSectorHost; ASector: Pointer): TPlaneMoveResult;
var
  LLast: Integer;
begin
  if AKind = TPlaneKind.Floor then
  begin
    if ADirection = -1 then
    begin
      if APlaneHeight - ASpeed < ADestination then
      begin
        LLast := APlaneHeight;
        APlaneHeight := ADestination;
        if AHost.ChangeSector(ASector, ACrush) then
          if ARules.FloorLowerRestores then
          begin
            APlaneHeight := LLast;
            AHost.ChangeSector(ASector, ACrush);
          end;
        Exit(TPlaneMoveResult.PastDest);
      end;
      LLast := APlaneHeight;
      APlaneHeight := APlaneHeight - ASpeed;
      if AHost.ChangeSector(ASector, ACrush) then
        if ARules.FloorLowerRestores then
        begin
          APlaneHeight := LLast;
          AHost.ChangeSector(ASector, ACrush);
          Exit(TPlaneMoveResult.Crushed);
        end;
    end
    else if ADirection = 1 then
    begin
      if ARules.ClampFloorRaiseToCeiling and (ADestination > AOtherHeight) then
        ADestination := AOtherHeight;
      if APlaneHeight + ASpeed > ADestination then
      begin
        LLast := APlaneHeight;
        APlaneHeight := ADestination;
        if AHost.ChangeSector(ASector, ACrush) then
        begin
          APlaneHeight := LLast;
          AHost.ChangeSector(ASector, ACrush);
        end;
        Exit(TPlaneMoveResult.PastDest);
      end;
      LLast := APlaneHeight;
      APlaneHeight := APlaneHeight + ASpeed;
      if AHost.ChangeSector(ASector, ACrush) then
      begin
        if ARules.FloorRaiseCrushKeeps and ACrush then
          Exit(TPlaneMoveResult.Crushed);
        APlaneHeight := LLast;
        AHost.ChangeSector(ASector, ACrush);
        Exit(TPlaneMoveResult.Crushed);
      end;
    end;
  end
  else
  begin
    if ADirection = -1 then
    begin
      if ARules.ClampCeilingLowerToFloor and (ADestination < AOtherHeight) then
        ADestination := AOtherHeight;
      if APlaneHeight - ASpeed < ADestination then
      begin
        LLast := APlaneHeight;
        APlaneHeight := ADestination;
        if AHost.ChangeSector(ASector, ACrush) then
        begin
          APlaneHeight := LLast;
          AHost.ChangeSector(ASector, ACrush);
        end;
        Exit(TPlaneMoveResult.PastDest);
      end;
      LLast := APlaneHeight;
      APlaneHeight := APlaneHeight - ASpeed;
      if AHost.ChangeSector(ASector, ACrush) then
      begin
        if ARules.CeilingLowerCrushKeeps and ACrush then
          Exit(TPlaneMoveResult.Crushed);
        APlaneHeight := LLast;
        AHost.ChangeSector(ASector, ACrush);
        Exit(TPlaneMoveResult.Crushed);
      end;
    end
    else if ADirection = 1 then
    begin
      if APlaneHeight + ASpeed > ADestination then
      begin
        LLast := APlaneHeight;
        APlaneHeight := ADestination;
        if AHost.ChangeSector(ASector, ACrush) then
        begin
          APlaneHeight := LLast;
          AHost.ChangeSector(ASector, ACrush);
        end;
        Exit(TPlaneMoveResult.PastDest);
      end;
      // a ceiling that goes up is never blocked: the answer of the host does not matter
      APlaneHeight := APlaneHeight + ASpeed;
      AHost.ChangeSector(ASector, ACrush);
    end;
  end;
  AHost.PlaneMoved(ASector);
  Result := TPlaneMoveResult.Ok;
end;

end.
