{******************************************************************************}
{                                                                              }
{  DelphiDoom: Speed32 - what the cars make in the simulated race              }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.Sim.Effects;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   Particles and sounds for a race without the engine: nothing appears and nothing is heard, but
  ///   the requests are counted and the sounds last a fixed number of tics, like the ones of the game
  /// </summary>
  TSpeedSimEffects = class(TInterfacedObject, IRacingEffects)
  strict private
    FParticles: Integer;
    FEngineSounds: Integer;
    FBrakeSounds: Integer;
  public
    procedure SpawnParticle(AKind: TRacingParticleKind; AX, AY, AZ, AMomentumX, AMomentumY: TFixed);
    function PlayEngineSound(AFormula: Boolean; AFraction: Integer): Integer;
    function PlayBrakeSound(AX, AY, AZ: TFixed): Integer;
    property Particles: Integer read FParticles;
    property EngineSounds: Integer read FEngineSounds;
    property BrakeSounds: Integer read FBrakeSounds;
  end;

implementation

const
  ENGINE_SOUND_TICS = 8;
  BRAKE_SOUND_TICS = 12;

{ TSpeedSimEffects }

procedure TSpeedSimEffects.SpawnParticle(AKind: TRacingParticleKind; AX, AY, AZ, AMomentumX,
  AMomentumY: TFixed);
begin
  Inc(FParticles);
end;

function TSpeedSimEffects.PlayEngineSound(AFormula: Boolean; AFraction: Integer): Integer;
begin
  Inc(FEngineSounds);
  Result := ENGINE_SOUND_TICS;
end;

function TSpeedSimEffects.PlayBrakeSound(AX, AY, AZ: TFixed): Integer;
begin
  Inc(FBrakeSounds);
  Result := BRAKE_SOUND_TICS;
end;

end.
