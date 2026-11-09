{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the sounds of the engine and of the brakes     }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of SH_EngineSound and SH_BrakeSound of speed_cars.pas                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.CarSounds;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   Decides which sound of the engine and of the brakes a car makes and when it makes it
  ///   again; the game plays the sound and says how long it lasts
  /// </summary>
  TRacingCarSounds = class(TInterfacedObject, IRacingCarSounds)
  strict private
    FEffects: IRacingEffects;
  public
    constructor Create(const AEffects: IRacingEffects);
    procedure EngineSound(const ACar: TRacingCarState; var ASoundCountdown: Integer);
    procedure BrakeSound(var ACar: TRacingCarState);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Racing.CarData, DelphiDoom.Racing.Math;

{ TRacingCarSounds }

constructor TRacingCarSounds.Create(const AEffects: IRacingEffects);
begin
  inherited Create;
  if not Assigned(AEffects) then
    raise EArgumentNilException.Create('AEffects');
  FEffects := AEffects;
end;

procedure TRacingCarSounds.EngineSound(const ACar: TRacingCarState; var ASoundCountdown: Integer);
var
  LFraction: Integer;
begin
  if ASoundCountdown <= 0 then
  begin
    if ACar.CarAccelerate <> 0 then
      LFraction := TRacingMath.Clamp(ACar.Rpm * 10 div RACING_MAX_RPM, 0, 9)
    else
      LFraction := 0;
    ASoundCountdown := FEffects.PlayEngineSound(
      RACING_CAR_DATA[ACar.CarInfo].CarType = TRacingCarType.Formula, LFraction);
  end;

  Dec(ASoundCountdown);
end;

procedure TRacingCarSounds.BrakeSound(var ACar: TRacingCarState);
begin
  ACar.BrakeSoundX := ACar.X;
  ACar.BrakeSoundY := ACar.Y;
  ACar.BrakeSoundZ := ACar.Z;

  if ACar.BrakeSoundCountdown <= 0 then
  begin
    if ACar.CarBrake > 0 then
      ACar.BrakeSoundCountdown := FEffects.PlayBrakeSound(ACar.BrakeSoundX, ACar.BrakeSoundY, ACar.BrakeSoundZ);
  end
  else
    Dec(ACar.BrakeSoundCountdown);
end;

end.
