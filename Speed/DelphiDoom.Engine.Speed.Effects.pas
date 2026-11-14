{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the particles and the sounds of the cars               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Speed.Effects;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   What the cars make appear and hear. The sounds of Speed Haste are raw files of the pk3 of the
  ///   fork that SPEEDH.JCL does not have as lumps with these names yet, and the particles need
  ///   sprites: for now the effects are counted (the log of the race shows them) and not shown
  /// </summary>
  TEngineSpeedEffects = class(TInterfacedObject, IRacingEffects)
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
  // how long a sound lasts in tics: the car asks for a new one when the countdown ends
  SOUND_TICS = 35;

{ TEngineSpeedEffects }

procedure TEngineSpeedEffects.SpawnParticle(AKind: TRacingParticleKind; AX, AY, AZ, AMomentumX,
  AMomentumY: TFixed);
begin
  Inc(FParticles);
end;

function TEngineSpeedEffects.PlayEngineSound(AFormula: Boolean; AFraction: Integer): Integer;
begin
  Inc(FEngineSounds);
  Result := SOUND_TICS;
end;

function TEngineSpeedEffects.PlayBrakeSound(AX, AY, AZ: TFixed): Integer;
begin
  Inc(FBrakeSounds);
  Result := SOUND_TICS;
end;

end.
