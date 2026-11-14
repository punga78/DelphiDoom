{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixDebriefing                                }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the arithmetic of RX_StorePlayerScore and of the texts of           }
{  RX_Intermission_Drawer (radix_intermission.pas of Rad-X)                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Debriefing;

interface

type
  /// <summary>What a level that has just ended tells about the pilot</summary>
  TRadixDebriefingInput = record
    HasSecondaryObjective: Boolean;
    SecondaryObjectiveDone: Boolean;
    Kills: Integer;
    MaxKills: Integer;
    Secrets: Integer;
    MaxSecrets: Integer;
    /// <summary>The time of the level and its par time, in tics</summary>
    Tics: Integer;
    ParTics: Integer;
    /// <summary>For how many tics the craft scraped the walls (0 when nobody counts them)</summary>
    WallHitTics: Integer;
  end;

  /// <summary>The marks of a level: each one is 16.16 fixed point, 65536 = 100%</summary>
  TRadixDebriefingScore = record
    Secondary: Integer;
    KillRatio: Integer;
    FlyingTime: Integer;
    Secrets: Integer;
    ProficientFlying: Integer;
    /// <summary>The skill rating: the mean of the five marks</summary>
    function Mean: Integer;
  end;

  /// <summary>
  ///   The numbers and the texts of the screen that follows a level of Radix (the debriefing): the
  ///   five marks of the pilot and how a time and a mark are written
  /// </summary>
  TRadixDebriefing = class
  public const
    FULL_MARK = 65536;
    TICS_PER_SECOND = 35;
  public
    /// <summary>The marks of the level; a mark that has nothing to measure (no enemies, no secrets) is full</summary>
    class function Score(const AInput: TRadixDebriefingInput): TRadixDebriefingScore; static;
    /// <summary>A time as hh:mm:ss</summary>
    class function TimeText(ASeconds: Integer): string; static;
    /// <summary>A mark as a percentage of three characters, padded with blanks on the left</summary>
    class function PercentText(AMark: Integer): string; static;
    /// <summary>A count of three characters, padded with blanks on the left</summary>
    class function CountText(ACount: Integer): string; static;
    /// <summary>COMPLETE, INCOMPLETE or NOT APPLICABLE</summary>
    class function SecondaryText(const AInput: TRadixDebriefingInput): string; static;
  end;

implementation

uses
  System.SysUtils;

const
  SComplete = 'COMPLETE';
  SIncomplete = 'INCOMPLETE';
  SNotApplicable = 'NOT APPLICABLE';

{ TRadixDebriefingScore }

function TRadixDebriefingScore.Mean: Integer;
begin
  Result := Integer((Int64(Secondary) + KillRatio + FlyingTime + Secrets + ProficientFlying) div 5);
end;

{ TRadixDebriefing }

class function TRadixDebriefing.Score(const AInput: TRadixDebriefingInput): TRadixDebriefingScore;
var
  LWallSeconds: Integer;
  LParSeconds: Integer;
begin
  if not AInput.HasSecondaryObjective or AInput.SecondaryObjectiveDone then
    Result.Secondary := FULL_MARK
  else
    Result.Secondary := 0;

  if AInput.MaxKills <= 0 then
    Result.KillRatio := FULL_MARK
  else
    Result.KillRatio := Integer(Int64(AInput.Kills) * FULL_MARK div AInput.MaxKills);

  if (AInput.Tics <= AInput.ParTics) or (AInput.Tics = 0) then
    Result.FlyingTime := FULL_MARK
  else
    Result.FlyingTime := Integer(Int64(AInput.ParTics) * FULL_MARK div AInput.Tics);

  if AInput.MaxSecrets <= 0 then
    Result.Secrets := FULL_MARK
  else
    Result.Secrets := Integer(Int64(AInput.Secrets) * FULL_MARK div AInput.MaxSecrets);

  LWallSeconds := AInput.WallHitTics div TICS_PER_SECOND;
  LParSeconds := AInput.ParTics div TICS_PER_SECOND;
  if (LWallSeconds = 0) or (LParSeconds = 0) then
    Result.ProficientFlying := FULL_MARK
  else
  begin
    Result.ProficientFlying := FULL_MARK - Integer(Int64(LWallSeconds) * FULL_MARK div LParSeconds);
    if Result.ProficientFlying < 0 then
      Result.ProficientFlying := 0;
  end;
end;

class function TRadixDebriefing.TimeText(ASeconds: Integer): string;
var
  LSeconds: Integer;
begin
  LSeconds := ASeconds;
  if LSeconds < 0 then
    LSeconds := 0;
  Result := Format('%.2d:%.2d:%.2d', [LSeconds div 3600, (LSeconds mod 3600) div 60, LSeconds mod 60]);
end;

class function TRadixDebriefing.PercentText(AMark: Integer): string;
begin
  Result := Format('%3d', [Integer(Int64(AMark) * 100 div FULL_MARK)]);
end;

class function TRadixDebriefing.CountText(ACount: Integer): string;
begin
  Result := Format('%3d', [ACount]);
end;

class function TRadixDebriefing.SecondaryText(const AInput: TRadixDebriefingInput): string;
begin
  if not AInput.HasSecondaryObjective then
    Result := SNotApplicable
  else if AInput.SecondaryObjectiveDone then
    Result := SComplete
  else
    Result := SIncomplete;
end;

end.
