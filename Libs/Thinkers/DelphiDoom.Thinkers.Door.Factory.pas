{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the factory of the doors                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Door.Factory;

interface

uses
  DelphiDoom.Thinkers.Door.Types, DelphiDoom.Thinkers.Door.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the doors</summary>
  TDoorFactory = class
  public
    /// <summary>The runner of the tics of the doors of a profile</summary>
    class function CreateRunner(const AProfile: TDoorProfile; const AMover: IDoorPlaneMover;
      const ASounds: IDoorSounds; const AOptions: IDoorOptions): IDoorRunner; static;
    /// <summary>The maker of the new doors of a profile</summary>
    class function CreateSpawner(const AProfile: TDoorProfile; const ASounds: IDoorSounds;
      const AQueries: IDoorSectorQueries): IDoorSpawner; static;
  end;

implementation

uses
  DelphiDoom.Thinkers.Door.Runner, DelphiDoom.Thinkers.Door.Spawner;

{ TDoorFactory }

class function TDoorFactory.CreateRunner(const AProfile: TDoorProfile;
  const AMover: IDoorPlaneMover; const ASounds: IDoorSounds;
  const AOptions: IDoorOptions): IDoorRunner;
begin
  Result := TDoorRunner.Create(AProfile, AMover, ASounds, AOptions);
end;

class function TDoorFactory.CreateSpawner(const AProfile: TDoorProfile;
  const ASounds: IDoorSounds; const AQueries: IDoorSectorQueries): IDoorSpawner;
begin
  Result := TDoorSpawner.Create(AProfile, ASounds, AQueries);
end;

end.
