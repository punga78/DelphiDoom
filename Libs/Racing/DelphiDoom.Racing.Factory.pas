{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the factory                                    }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.Factory;

interface

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the racing library</summary>
  TRacingFactory = class
  public
    /// <summary>The state of the race, that the game writes and the cars read</summary>
    class function CreateRaceState: IRacingRaceSettings; static;
    class function CreateGround(const ARandom: IGameRandom): IRacingGround; static;
    class function CreateTrack(const ARace: IRacingRaceState; const AGeometry: IRacingGeometry): IRacingTrack; static;
    class function CreateParticles(const AGround: IRacingGround; const ARace: IRacingRaceState;
      const AEffects: IRacingEffects): IRacingParticles; static;
    class function CreateCarSounds(const AEffects: IRacingEffects): IRacingCarSounds; static;
    class function CreatePhysics(const ARace: IRacingRaceState; const AGround: IRacingGround;
      const AGeometry: IRacingGeometry; const AParticles: IRacingParticles;
      const ASounds: IRacingCarSounds; const ATrack: IRacingTrack): IRacingPhysics; static;
    class function CreateAiDriver(const ARace: IRacingRaceState; const ATrack: IRacingTrack;
      const AGeometry: IRacingGeometry): IRacingDriver; static;
    class function CreatePlayerDriver(const ARace: IRacingRaceState; const ATrack: IRacingTrack;
      const AComputerDriver: IRacingDriver; const AEvents: IRacingPlayerEvents): IRacingPlayerDriver; static;
    class function CreateGridAssigner(const ARandom: IGameRandom): IRacingGridAssigner; static;
    class function CreateScoreTable: IRacingScoreTable; static;
  end;

implementation

uses
  DelphiDoom.Racing.RaceState, DelphiDoom.Racing.Ground, DelphiDoom.Racing.Track, DelphiDoom.Racing.Particles,
  DelphiDoom.Racing.CarSounds, DelphiDoom.Racing.Physics, DelphiDoom.Racing.AiDriver,
  DelphiDoom.Racing.PlayerDriver, DelphiDoom.Racing.GridAssigner, DelphiDoom.Racing.ScoreTable;

{ TRacingFactory }

class function TRacingFactory.CreateRaceState: IRacingRaceSettings;
begin
  Result := TRacingRaceState.Create;
end;

class function TRacingFactory.CreateGround(const ARandom: IGameRandom): IRacingGround;
begin
  Result := TRacingGround.Create(ARandom);
end;

class function TRacingFactory.CreateTrack(const ARace: IRacingRaceState;
  const AGeometry: IRacingGeometry): IRacingTrack;
begin
  Result := TRacingTrack.Create(ARace, AGeometry);
end;

class function TRacingFactory.CreateParticles(const AGround: IRacingGround;
  const ARace: IRacingRaceState; const AEffects: IRacingEffects): IRacingParticles;
begin
  Result := TRacingParticles.Create(AGround, ARace, AEffects);
end;

class function TRacingFactory.CreateCarSounds(const AEffects: IRacingEffects): IRacingCarSounds;
begin
  Result := TRacingCarSounds.Create(AEffects);
end;

class function TRacingFactory.CreatePhysics(const ARace: IRacingRaceState; const AGround: IRacingGround;
  const AGeometry: IRacingGeometry; const AParticles: IRacingParticles;
  const ASounds: IRacingCarSounds; const ATrack: IRacingTrack): IRacingPhysics;
begin
  Result := TRacingPhysics.Create(ARace, AGround, AGeometry, AParticles, ASounds, ATrack);
end;

class function TRacingFactory.CreateAiDriver(const ARace: IRacingRaceState; const ATrack: IRacingTrack;
  const AGeometry: IRacingGeometry): IRacingDriver;
begin
  Result := TRacingAiDriver.Create(ARace, ATrack, AGeometry);
end;

class function TRacingFactory.CreatePlayerDriver(const ARace: IRacingRaceState; const ATrack: IRacingTrack;
  const AComputerDriver: IRacingDriver; const AEvents: IRacingPlayerEvents): IRacingPlayerDriver;
begin
  Result := TRacingPlayerDriver.Create(ARace, ATrack, AComputerDriver, AEvents);
end;

class function TRacingFactory.CreateGridAssigner(const ARandom: IGameRandom): IRacingGridAssigner;
begin
  Result := TRacingGridAssigner.Create(ARandom);
end;

class function TRacingFactory.CreateScoreTable: IRacingScoreTable;
begin
  Result := TRacingScoreTableStore.Create;
end;

end.
