{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the ground of the track                        }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of SH_GroundTypeAtXY, SH_SlipperFactorAtXY and SH_SlipCalculation      }
{  of speed_race.pas                                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.Ground;

// The product of the slip is a 32 bit integer that wraps, as in the old code
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.MathCore.Intf, DelphiDoom.Racing.Types,
  DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   What the wheels find on the ground. The map of the ground is a picture of 4096 x 4096
  ///   pixels (two map units for a pixel, the first line at the top of the track) and the
  ///   colour of the pixel says what the ground is
  /// </summary>
  TRacingGround = class(TInterfacedObject, IRacingGround)
  strict private
    FRandom: IGameRandom;
    FMap: PByte;
    FSize: Integer;
  public
    /// <summary>The system random numbers are the ones that decide how well the tires hold the ground</summary>
    constructor Create(const ARandom: IGameRandom);
    procedure SetMap(AMap: PByte; ASize: Integer);
    function GroundTypeAt(AX, AY: TFixed): TRacingGroundType;
    function SlipperFactorAt(AX, AY: TFixed): Byte;
    /// <summary>The least and the most that the tires hold on a kind of ground (the old slipperinessinfo)</summary>
    class procedure SlipRange(AGround: TRacingGroundType; out AMinimum, AMaximum: Byte); static;
    /// <summary>A force that the ground lets through: ASlip / 255 of it (the old SH_SlipCalculation)</summary>
    class function SlipCalculation(AForce: TFixed; ASlip: Byte): TFixed; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Racing.Math;

{ TRacingGround }

constructor TRacingGround.Create(const ARandom: IGameRandom);
begin
  inherited Create;
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  FRandom := ARandom;
end;

procedure TRacingGround.SetMap(AMap: PByte; ASize: Integer);
begin
  FMap := AMap;
  FSize := ASize;
end;

function TRacingGround.GroundTypeAt(AX, AY: TFixed): TRacingGroundType;
var
  LColumn, LRow: Integer;
  LValue: Byte;
begin
  if (FSize <> RACING_GROUND_BYTES) or not Assigned(FMap) then
  begin
    Result := TRacingGroundType.Asphalt;
    Exit;
  end;

  LColumn := TRacingMath.Clamp((AX div FIXED_ONE) div RACING_LEVEL_SCALE, 0, RACING_GROUND_SIZE - 1);
  LRow := TRacingMath.Clamp((AY div FIXED_ONE) div RACING_LEVEL_SCALE, 0, RACING_GROUND_SIZE - 1);
  LValue := (FMap + (RACING_GROUND_SIZE - 1 - LRow) * RACING_GROUND_SIZE + LColumn)^;
  if TRacingMath.IsInRange(LValue, 160, 191) then
    Result := TRacingGroundType.Asphalt
  else if TRacingMath.IsInRange(LValue, 48, 63) then
    Result := TRacingGroundType.Sand
  else if TRacingMath.IsInRange(LValue, 64, 79) then
    Result := TRacingGroundType.Grass
  else if TRacingMath.IsInRange(LValue, 128, 143) then
    Result := TRacingGroundType.Dirt
  else
    Result := TRacingGroundType.Unknown;
end;

function TRacingGround.SlipperFactorAt(AX, AY: TFixed): Byte;
var
  LMinimum, LMaximum: Byte;
begin
  SlipRange(GroundTypeAt(AX, AY), LMinimum, LMaximum);
  Result := LMinimum + FRandom.NextSystem mod (LMaximum - LMinimum + 1);
end;

class procedure TRacingGround.SlipRange(AGround: TRacingGroundType; out AMinimum, AMaximum: Byte);
begin
  case AGround of
    TRacingGroundType.Asphalt:
      begin
        AMinimum := 224;
        AMaximum := 255;
      end;
    TRacingGroundType.Grass:
      begin
        AMinimum := 150;
        AMaximum := 220;
      end;
    TRacingGroundType.Dirt:
      begin
        AMinimum := 100;
        AMaximum := 180;
      end;
    TRacingGroundType.Sand:
      begin
        AMinimum := 80;
        AMaximum := 150;
      end;
  else
    AMinimum := 100;
    AMaximum := 200;
  end;
end;

class function TRacingGround.SlipCalculation(AForce: TFixed; ASlip: Byte): TFixed;
var
  LProduct: Int64;
begin
  // The old code multiplied two 32 bit integers and only then widened the result
  LProduct := AForce * ASlip;
  LProduct := LProduct div RACING_MAX_SLIP_FACTOR;
  Result := LProduct;
end;

end.
