{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the thinker of a phased light                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Light.PhaseSpawner;

interface

uses
  DelphiDoom.Thinkers.Light.Intf;

type
  /// <summary>
  ///   Makes the thinker (phase_t in the zone memory) of each light of a sequence: the one that
  ///   the savegames know. It is separate from the facade because the facade needs the spawner
  ///   to walk a sequence and the spawner needs the facade to make a thinker
  /// </summary>
  TEngineLightPhaseSpawner = class(TInterfacedObject, ILightPhaseSpawner)
  public
    procedure SpawnPhased(const ASector: ILightSector; ABase, AIndex: Integer);
  end;

implementation

uses
  r_defs,
  udmf_lights;

{ TEngineLightPhaseSpawner }

procedure TEngineLightPhaseSpawner.SpawnPhased(const ASector: ILightSector; ABase, AIndex: Integer);
begin
  P_SpawnPhasedLight(Psector_t(ASector.Handle), ABase, AIndex);
end;

end.
