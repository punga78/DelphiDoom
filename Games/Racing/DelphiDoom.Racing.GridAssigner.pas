{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the cars of the starting grid                  }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the choice of the cars of SH_InitLevelCars of speed_cars.pas        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.GridAssigner;

{$Q-}
{$R-}

interface

uses
  System.Generics.Collections, DelphiDoom.MathCore.Intf, DelphiDoom.Racing.Types,
  DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   Gives a car of the family of the race to every starting position that is not the player:
  ///   a random one among the cars that nobody has yet, so that two cars are never the same
  ///   while there are enough of them
  /// </summary>
  TRacingGridAssigner = class(TInterfacedObject, IRacingGridAssigner)
  strict private
    FRandom: IGameRandom;
  public
    /// <summary>The system random numbers choose the cars (the old Sys_Random)</summary>
    constructor Create(const ARandom: IGameRandom);
    function Assign(AStartCount: Integer; ARaceCarType: TRacingCarType;
      const APlayerCarIds: array of Integer): TArray<Integer>;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Racing.CarData;

const
  STooManyCars = 'Too many cars (%d)';

{ TRacingGridAssigner }

constructor TRacingGridAssigner.Create(const ARandom: IGameRandom);
begin
  inherited Create;
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  FRandom := ARandom;
end;

function TRacingGridAssigner.Assign(AStartCount: Integer; ARaceCarType: TRacingCarType;
  const APlayerCarIds: array of Integer): TArray<Integer>;
var
  LAvailable: TList<Integer>;
  LIndex, LPosition: Integer;
begin
  if AStartCount >= RACING_MAX_CARS then // One car is left for the player
    raise ERacingException.CreateFmt(STooManyCars, [AStartCount]);

  LAvailable := TList<Integer>.Create;
  try
    for LIndex := 0 to RACING_CAR_COUNT - 1 do
      if (ARaceCarType = RACING_CAR_DATA[LIndex].CarType) or (ARaceCarType = TRacingCarType.Any) or
         (RACING_CAR_DATA[LIndex].CarType = TRacingCarType.Any) then
        LAvailable.Add(LIndex);

    for LIndex := 0 to High(APlayerCarIds) do
    begin
      LPosition := LAvailable.IndexOf(APlayerCarIds[LIndex]);
      if LPosition >= 0 then
        LAvailable.Delete(LPosition);
    end;

    SetLength(Result, AStartCount);
    for LIndex := 0 to AStartCount - 1 do
      if LAvailable.Count > 0 then
      begin
        LPosition := FRandom.NextSystem mod LAvailable.Count;
        Result[LIndex] := LAvailable[LPosition];
        LAvailable.Delete(LPosition);
      end
      else
        Result[LIndex] := LIndex mod RACING_CAR_COUNT;
  finally
    LAvailable.Free;
  end;
end;

end.
