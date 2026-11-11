{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - reading a list of voxels of a path    }
{  (Projectile::getPositionFromStart and getPositionFromEnd)                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Trajectory;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Types;

const
  /// <summary>Projectile::ItemDropVoxelOffset: where an item that landed is dropped, from the end of its path</summary>
  ITEM_DROP_VOXEL_OFFSET = -2;

type
  /// <summary>Position in a trajectory, with the index clipped to its ends</summary>
  TXcomTrajectory = class
  public
    /// <summary>The voxel at an offset from the start; before the start is the first, after the end the last</summary>
    class function PositionFromStart(const ATrajectory: TList<TXcomPosition>; APosition: Integer): TXcomPosition;
      static;
    /// <summary>The voxel at an offset from the end (0 is the last)</summary>
    class function PositionFromEnd(const ATrajectory: TList<TXcomPosition>; APosition: Integer): TXcomPosition;
      static;
  end;

implementation

const
  SEmptyTrajectory = 'The trajectory has no voxels';

class function TXcomTrajectory.PositionFromStart(const ATrajectory: TList<TXcomPosition>;
  APosition: Integer): TXcomPosition;
begin
  if ATrajectory.Count = 0 then
    raise EXcomBattleException.Create(SEmptyTrajectory);
  if (APosition >= 0) and (APosition < ATrajectory.Count) then
    Result := ATrajectory[APosition]
  else if APosition < 0 then
    Result := ATrajectory[0]
  else
    Result := ATrajectory[ATrajectory.Count - 1];
end;

class function TXcomTrajectory.PositionFromEnd(const ATrajectory: TList<TXcomPosition>;
  APosition: Integer): TXcomPosition;
begin
  Result := PositionFromStart(ATrajectory, ATrajectory.Count + APosition - 1);
end;

end.
