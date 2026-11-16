{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the totals of a level                        }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.LevelTotals;

interface

type
  /// <summary>
  ///   What the level holds to be found: the monsters to kill, the items to take and the secret
  ///   sectors (totalkills, totalitems and totalsecret of g_game), counted while the things and the
  ///   sectors are spawned and shown by the intermission and the automap
  /// </summary>
  /// <remarks>
  ///   The totals are not written in the saved games (the level is spawned again when it is
  ///   loaded). No method is virtual; the engine reads the counters once per frame at most
  /// </remarks>
  TLevelTotals = class sealed
  strict private
    FKills: Integer;
    FItems: Integer;
    FSecrets: Integer;
  public
    /// <summary>Sets every total to zero (a level begins)</summary>
    procedure Clear;

    /// <summary>A monster that counts for the kills</summary>
    procedure CountKill;
    /// <summary>An item that counts for the items</summary>
    procedure CountItem;
    /// <summary>A secret sector</summary>
    procedure CountSecret;

    /// <summary>The monsters of the level (totalkills)</summary>
    property Kills: Integer read FKills;
    /// <summary>The items of the level (totalitems)</summary>
    property Items: Integer read FItems;
    /// <summary>The secret sectors of the level (totalsecret)</summary>
    property Secrets: Integer read FSecrets;
  end;

implementation

{ TLevelTotals }

procedure TLevelTotals.Clear;
begin
  FKills := 0;
  FItems := 0;
  FSecrets := 0;
end;

procedure TLevelTotals.CountKill;
begin
  Inc(FKills);
end;

procedure TLevelTotals.CountItem;
begin
  Inc(FItems);
end;

procedure TLevelTotals.CountSecret;
begin
  Inc(FSecrets);
end;

end.
