{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the phased light                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Light.Phase;

// The light level is 16 bit and the old code let the values wrap when they were stored
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Thinkers.Light.Types, DelphiDoom.Thinkers.Light.Intf;

type
  /// <summary>
  ///   The light that follows a table of 64 levels (TH_Phase and P_SpawnPhasedLight): the lights
  ///   of a sequence start one step after the other
  /// </summary>
  TLightPhase = class
  public
    /// <summary>The value of the table for a step (0..63)</summary>
    class function TableValue(AIndex: Integer): Integer; static;
    /// <summary>
    ///   Starts the phase of a sector: the step is AIndex (or, with -1, the light level of the
    ///   sector) and the base AIndex and 255. The sector takes its first level and loses the
    ///   bits of its special that the profile says are the phased light
    /// </summary>
    class procedure Initialize(const ASector: ILightSector; ABase, AIndex: Integer;
      const AProfile: TLightSequenceProfile; out APhaseIndex, APhaseBase: Integer); static;
    /// <summary>One tic: the next step of the table</summary>
    class procedure Tick(var AIndex: Integer; ABase: Integer; var ALightLevel: SmallInt); static;
  end;

implementation

const
  PHASE_TABLE: array[0..63] of Integer = (
    128, 112,  96,  80,  64,  48,  32,  32,
     16,  16,  16,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,  16,  16,  16,
     32,  32,  48,  64,  80,  96, 112, 128
  );

{ TLightPhase }

class function TLightPhase.TableValue(AIndex: Integer): Integer;
begin
  Result := PHASE_TABLE[AIndex and (LIGHT_PHASE_STEPS - 1)];
end;

class procedure TLightPhase.Initialize(const ASector: ILightSector; ABase, AIndex: Integer;
  const AProfile: TLightSequenceProfile; out APhaseIndex, APhaseBase: Integer);
begin
  if AIndex = -1 then
    // the light level of the sector as the index
    APhaseIndex := ASector.LightLevel and (LIGHT_PHASE_STEPS - 1)
  else
    APhaseIndex := AIndex and (LIGHT_PHASE_STEPS - 1);

  APhaseBase := ABase and 255;
  ASector.LightLevel := APhaseBase + PHASE_TABLE[APhaseIndex];

  ASector.Special := ASector.Special and not AProfile.PhaseMask;
end;

class procedure TLightPhase.Tick(var AIndex: Integer; ABase: Integer; var ALightLevel: SmallInt);
begin
  AIndex := (AIndex + 1) and (LIGHT_PHASE_STEPS - 1);
  ALightLevel := SmallInt(ABase + PHASE_TABLE[AIndex]);
end;

end.
