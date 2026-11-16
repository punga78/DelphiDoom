{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the queue of the player corpses              }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.BodyQueue;

interface

const
  /// <summary>The slots of the queue (BODYQUESIZE of g_game)</summary>
  BODY_QUEUE_SIZE = 32;

type
  /// <summary>
  ///   The ring of the last corpses of the players (bodyque and bodyqueslot of g_game and, in
  ///   Heretic and Hexen, of the actions of the enemies): when it is full the oldest corpse is
  ///   handed back to the caller, who removes it from the world
  /// </summary>
  /// <remarks>
  ///   The queue does not own the objects and is not written in the saved games. The item is an
  ///   opaque pointer: the library does not know the objects of the engine. No method is virtual
  /// </remarks>
  TBodyQueue = class sealed
  strict private
    FSlot: Integer;
    FItems: array[0..BODY_QUEUE_SIZE - 1] of Pointer;
  public
    /// <summary>Forgets every corpse (the objects are not touched)</summary>
    procedure Clear; inline;

    /// <summary>
    ///   Puts a corpse in the queue
    /// </summary>
    /// <param name="AItem">The corpse</param>
    /// <returns>The oldest corpse if the queue was full (to be removed), nil otherwise</returns>
    function Add(const AItem: Pointer): Pointer; inline;

    /// <summary>The corpses added since the last Clear (it does not stop at the size)</summary>
    property Count: Integer read FSlot;
  end;

implementation

{ TBodyQueue }

procedure TBodyQueue.Clear;
begin
  FSlot := 0;
end;

function TBodyQueue.Add(const AItem: Pointer): Pointer;
begin
  Result := nil;
  if FSlot >= BODY_QUEUE_SIZE then
    Result := FItems[FSlot mod BODY_QUEUE_SIZE];
  FItems[FSlot mod BODY_QUEUE_SIZE] := AItem;
  Inc(FSlot);
end;

end.
