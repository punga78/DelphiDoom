{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the particles that a car leaves                }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of SH_SpawnParticleCheck of speed_particles.pas                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.Particles;

// Positions are 16.16 fixed point and the products wrap as in the old code
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   Sparks and smoke when the wheels spin on the asphalt, dirt on the other grounds. It
  ///   decides where and when; the game creates the objects (and chooses one of the two objects
  ///   of each kind with its random numbers)
  /// </summary>
  TRacingParticles = class(TInterfacedObject, IRacingParticles)
  strict private
    FGround: IRacingGround;
    FRace: IRacingRaceState;
    FEffects: IRacingEffects;
  public
    constructor Create(const AGround: IRacingGround; const ARace: IRacingRaceState;
      const AEffects: IRacingEffects);
    procedure Check(var ACar: TRacingCarState; AActualSpeed, AEngineSpeed: TFixed);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MathCore.Trigonometry;

const
  REAR_WHEEL_OFFSET = 32;

{ TRacingParticles }

constructor TRacingParticles.Create(const AGround: IRacingGround; const ARace: IRacingRaceState;
  const AEffects: IRacingEffects);
begin
  inherited Create;
  if not Assigned(AGround) then
    raise EArgumentNilException.Create('AGround');
  if not Assigned(ARace) then
    raise EArgumentNilException.Create('ARace');
  if not Assigned(AEffects) then
    raise EArgumentNilException.Create('AEffects');
  FGround := AGround;
  FRace := ARace;
  FEffects := AEffects;
end;

procedure TRacingParticles.Check(var ACar: TRacingCarState; AActualSpeed, AEngineSpeed: TFixed);
var
  LWheelX, LWheelY: TFixed;
  LWheelX1, LWheelY1, LWheelX2, LWheelY2: TFixed;
  LAngle: TAngle;
  LFine: Integer;
begin
  if ACar.NextParticle > FRace.LevelTime then
    Exit;

  LFine := ACar.Angle shr ANGLETOFINESHIFT;
  LWheelX := ACar.X - REAR_WHEEL_OFFSET * TTrigonometry.FineCosine(LFine);
  LWheelY := ACar.Y - REAR_WHEEL_OFFSET * TTrigonometry.FineSine(LFine);

  case FGround.GroundTypeAt(LWheelX, LWheelY) of
    TRacingGroundType.Asphalt:
      begin
        if AEngineSpeed > AActualSpeed + 4 * FIXED_ONE then
        begin
          FEffects.SpawnParticle(TRacingParticleKind.Spark, LWheelX, LWheelY, ACar.Z,
            -2 * TTrigonometry.FineCosine(LFine), -2 * TTrigonometry.FineSine(LFine));
          if AEngineSpeed > AActualSpeed + 8 * FIXED_ONE then // Spinning hard
          begin
            LAngle := ACar.Angle + 10 * ANG1;
            LFine := LAngle shr ANGLETOFINESHIFT;
            LWheelX1 := ACar.X - REAR_WHEEL_OFFSET * TTrigonometry.FineCosine(LFine);
            LWheelY1 := ACar.Y - REAR_WHEEL_OFFSET * TTrigonometry.FineSine(LFine);
            FEffects.SpawnParticle(TRacingParticleKind.Smoke, LWheelX1, LWheelY1, ACar.Z,
              -TTrigonometry.FineCosine(LFine), -TTrigonometry.FineSine(LFine));

            LAngle := ACar.Angle - 10 * ANG1;
            LFine := LAngle shr ANGLETOFINESHIFT;
            LWheelX2 := ACar.X - REAR_WHEEL_OFFSET * TTrigonometry.FineCosine(LFine);
            LWheelY2 := ACar.Y - REAR_WHEEL_OFFSET * TTrigonometry.FineSine(LFine);
            FEffects.SpawnParticle(TRacingParticleKind.Smoke, LWheelX2, LWheelY2, ACar.Z,
              -TTrigonometry.FineCosine(LFine), -TTrigonometry.FineSine(LFine));
          end;
          ACar.NextParticle := FRace.LevelTime + RACING_TICKS_PER_SECOND;
        end;
      end;
    TRacingGroundType.Grass:
      begin
        FEffects.SpawnParticle(TRacingParticleKind.GrassDirt, LWheelX, LWheelY, ACar.Z,
          -TTrigonometry.FineCosine(LFine), -TTrigonometry.FineSine(LFine));
        ACar.NextParticle := FRace.LevelTime + RACING_TICKS_PER_SECOND div 2;
      end;
    TRacingGroundType.Dirt:
      begin
        FEffects.SpawnParticle(TRacingParticleKind.Dirt, LWheelX, LWheelY, ACar.Z,
          -TTrigonometry.FineCosine(LFine), -TTrigonometry.FineSine(LFine));
        ACar.NextParticle := FRace.LevelTime + RACING_TICKS_PER_SECOND div 2;
      end;
    TRacingGroundType.Sand:
      begin
        FEffects.SpawnParticle(TRacingParticleKind.SandDirt, LWheelX, LWheelY, ACar.Z,
          -TTrigonometry.FineCosine(LFine), -TTrigonometry.FineSine(LFine));
        ACar.NextParticle := FRace.LevelTime + RACING_TICKS_PER_SECOND div 2;
      end;
  end;
end;

end.
