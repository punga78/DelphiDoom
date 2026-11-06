{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the consistency check of the commands             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.ConsistencyTracker;

interface

uses
  System.SysUtils, DelphiDoom.Net.Types, DelphiDoom.Net.Intf;

type
  /// <summary>
  ///   Keeps, for every player and for the last BACKUPTICS tics, the value that the game computed
  ///   (the x of the player's mobj, or the random index if the player has no mobj). A command
  ///   that comes from the net carries the value that its sender had: if it is not the same the
  ///   games are not in sync any more. Replaces the consistency array of g_game and the check in
  ///   G_Ticker; the value itself is read from the game by the engine
  /// </summary>
  TNetConsistencyTracker = class(TInterfacedObject, INetConsistency)
  private
    FValues: array of array of SmallInt;
    FMaxPlayers: Integer;
    FTicDup: Integer;
    procedure CheckPlayer(APlayer: Integer);
  public
    constructor Create(AMaxPlayers, ATicDup: Integer);
    function Expected(APlayer, ATic: Integer): SmallInt;
    procedure Verify(APlayer, AGameTic: Integer; AReceived: SmallInt; ALocalValue: Integer);
  end;

implementation

const
  SBadPlayer = 'Net player %d does not exist (%d players).';
  SBadTracker = 'The consistency tracker needs at least one player and a ticdup of at least 1.';
  SFailure = 'G_Ticker(): consistency failure (%d should be %d)';

{ TNetConsistencyTracker }

constructor TNetConsistencyTracker.Create(AMaxPlayers, ATicDup: Integer);
begin
  inherited Create;
  if (AMaxPlayers < 1) or (ATicDup < 1) then
    raise ENetException.Create(SBadTracker);
  FMaxPlayers := AMaxPlayers;
  FTicDup := ATicDup;
  SetLength(FValues, AMaxPlayers, NET_BACKUPTICS);
end;

procedure TNetConsistencyTracker.CheckPlayer(APlayer: Integer);
begin
  if (APlayer < 0) or (APlayer >= FMaxPlayers) then
    raise ENetException.CreateFmt(SBadPlayer, [APlayer, FMaxPlayers]);
end;

function TNetConsistencyTracker.Expected(APlayer, ATic: Integer): SmallInt;
begin
  CheckPlayer(APlayer);
  Result := FValues[APlayer][ATic mod NET_BACKUPTICS];
end;

procedure TNetConsistencyTracker.Verify(APlayer, AGameTic: Integer; AReceived: SmallInt;
  ALocalValue: Integer);
var
  LSlot: Integer;
begin
  CheckPlayer(APlayer);
  LSlot := (AGameTic div FTicDup) mod NET_BACKUPTICS;
  if (AGameTic > NET_BACKUPTICS) and (FValues[APlayer][LSlot] <> AReceived) then
    raise ENetConsistencyException.CreateFmt(SFailure, [AReceived, FValues[APlayer][LSlot]]);
  // the game keeps a 32 bit value in a 16 bit slot: the low half
  FValues[APlayer][LSlot] := SmallInt(Word(ALocalValue and $FFFF));
end;

end.
