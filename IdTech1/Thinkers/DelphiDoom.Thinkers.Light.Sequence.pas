{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the sequence of phased lights                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Light.Sequence;

// The fixed point values are 32 bit and wrap as they did
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Thinkers.Light.Types, DelphiDoom.Thinkers.Light.Intf;

type
  /// <summary>
  ///   Walks the sectors that make a row of lights (P_SpawnLightSequence): from the first sector
  ///   it follows the neighbors with the special of the sequence, which alternates between two
  ///   numbers, and gives each sector a phase that starts after the one before
  /// </summary>
  TLightSequence = class
  public
    /// <summary>
    ///   Makes the phased lights of the row that starts at ASector; the thinkers are made by
    ///   ASpawner, one for each sector, in the order of the row. The sectors of the row are
    ///   marked with the start special while the row is counted
    /// </summary>
    class procedure Spawn(const ASector: ILightSector; AIndexStep: Integer;
      const AProfile: TLightSequenceProfile; const ASpawner: ILightPhaseSpawner); static;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.MathCore.FixedMath;

{ TLightSequence }

class procedure TLightSequence.Spawn(const ASector: ILightSector; AIndexStep: Integer;
  const AProfile: TLightSequenceProfile; const ASpawner: ILightPhaseSpawner);
var
  LSector: ILightSector;
  LNext: ILightSector;
  LTemp: ILightSector;
  LSequenceSpecial: Integer;
  LIndex: Integer;
  LCount: Integer;
  LBase: Integer;
  LPosition: TFixed;
  LDelta: TFixed;
begin
  // look for the Sequence special first
  LSequenceSpecial := AProfile.Sequence;
  LSector := ASector;
  LCount := 1;
  repeat
    LNext := nil;
    // make sure that the search does not go back
    LSector.Special := AProfile.SequenceStart or (LSector.Special and not AProfile.PhaseMask);
    for LIndex := 0 to LSector.NeighborCount - 1 do
    begin
      LTemp := LSector.Neighbors[LIndex];
      if not Assigned(LTemp) then
        Continue;

      if (LTemp.Special and AProfile.PhaseMask) = LSequenceSpecial then
      begin
        if LSequenceSpecial = AProfile.Sequence then
          LSequenceSpecial := AProfile.SequenceAlt
        else
          LSequenceSpecial := AProfile.Sequence;
        LNext := LTemp;
        Inc(LCount);
      end;
    end;
    LSector := LNext;
  until not Assigned(LSector);

  LSector := ASector;
  LCount := LCount * AIndexStep;
  LPosition := 0;
  LDelta := TFixedMath.Divide(64 * LIGHT_FRACUNIT, LCount * LIGHT_FRACUNIT);
  LBase := ASector.LightLevel;
  repeat
    LNext := nil;
    if LSector.LightLevel <> 0 then
      LBase := LSector.LightLevel;

    ASpawner.SpawnPhased(LSector, LBase, LPosition div LIGHT_FRACUNIT);
    LPosition := LPosition + LDelta;
    for LIndex := 0 to LSector.NeighborCount - 1 do
    begin
      LTemp := LSector.Neighbors[LIndex];
      if not Assigned(LTemp) then
        Continue;

      if (LTemp.Special and AProfile.PhaseMask) = AProfile.SequenceStart then
        LNext := LTemp;
    end;
    LSector := LNext;
  until not Assigned(LSector);
end;

end.
