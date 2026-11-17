{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the corpse queues of a level                  }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.LevelCorpses;

interface

uses
  DelphiDoom.Thinkers.BodyQueue;

type
  /// <summary>
  ///   The two queues of corpses of the world: the corpses of the players left on the spawn spots (G_CheckSpot)
  ///   and the corpses of the enemies of Heretic and Hexen (A_AddPlayerCorpse)
  /// </summary>
  /// <remarks>
  ///   The original code had one queue and emptied it when a level was set up (bodyqueslot := 0 in P_SetupLevel),
  ///   because the objects of the old level are gone. Both queues are emptied together here: the queue of the
  ///   enemies was not, and after 32 corpses over several levels it handed back an object already freed
  /// </remarks>
  TLevelCorpses = class sealed
  strict private
    FPlayers: TBodyQueue;
    FEnemies: TBodyQueue;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>Forgets every corpse of both queues (to be called when a level is set up)</summary>
    procedure Clear;

    /// <summary>The corpses of the players</summary>
    property Players: TBodyQueue read FPlayers;
    /// <summary>The corpses of the enemies (Heretic and Hexen)</summary>
    property Enemies: TBodyQueue read FEnemies;
  end;

implementation

{ TLevelCorpses }

constructor TLevelCorpses.Create;
begin
  inherited Create;
  FPlayers := TBodyQueue.Create;
  FEnemies := TBodyQueue.Create;
end;

destructor TLevelCorpses.Destroy;
begin
  FEnemies.Free;
  FPlayers.Free;
  inherited;
end;

procedure TLevelCorpses.Clear;
begin
  FPlayers.Clear;
  FEnemies.Clear;
end;

end.
