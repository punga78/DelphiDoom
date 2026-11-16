{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the settings of a championship                 }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of SH_SaveChampionShipData of speed_championship.pas                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.Championship;

interface

uses
  DelphiDoom.Racing.Types;

type
  /// <summary>Makes the settings that a championship keeps for all its races, from what the menu chose</summary>
  TRacingChampionshipSettings = class
  public
    /// <summary>
    ///   The laps are kept between the least and the most, the family of cars is a valid one
    ///   (a number out of range is the nearest one), the rest is copied
    /// </summary>
    class function Build(AGameType: TRacingGameType; ATransmission, ALaps, ACarTypeNumber,
      ADefaultFormulaCar, ADefaultStockCar, ADefaultAnyCar: Integer;
      const APilotName: string): TRacingChampionship; static;
  end;

implementation

uses
  DelphiDoom.Racing.Math;

{ TRacingChampionshipSettings }

class function TRacingChampionshipSettings.Build(AGameType: TRacingGameType; ATransmission, ALaps,
  ACarTypeNumber, ADefaultFormulaCar, ADefaultStockCar, ADefaultAnyCar: Integer;
  const APilotName: string): TRacingChampionship;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.NumLaps := TRacingMath.Clamp(ALaps, RACING_MIN_LAPS, RACING_MAX_LAPS);
  Result.RaceCarType := TRacingCarType(TRacingMath.Clamp(ACarTypeNumber, 0, Ord(TRacingCarType.Any)));
  Result.GameType := AGameType;
  Result.TransmissionType := ATransmission;
  Result.DefaultFormulaCar := ADefaultFormulaCar;
  Result.DefaultStockCar := ADefaultStockCar;
  Result.DefaultAnyCar := ADefaultAnyCar;
  Result.PilotName := Copy(APilotName, 1, RACING_PILOT_NAME_SIZE);
end;

end.
