{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the queue of the items that respawn          }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.RespawnQueue;

interface

uses
  System.SysUtils;

resourcestring
  SRespawnQueueEmpty = 'The respawn queue is empty';

const
  /// <summary>The slots of the queue (ITEMQUESIZE of p_mobj): a power of two, the indexes wrap with a mask</summary>
  RESPAWN_QUEUE_SIZE = 128;

type
  /// <summary>
  ///   The ring of the items taken or destroyed in a deathmatch 2 game, which come back after a
  ///   while (iquehead, iquetail, itemrespawnque and itemrespawntime of p_mobj). The slot is the
  ///   spawn point of the engine, a record the queue copies and does not interpret
  /// </summary>
  /// <remarks>
  ///   The queue is not written in the saved games. When it is full the oldest item is lost, as
  ///   in the old code. No method is virtual
  /// </remarks>
  TRespawnQueue<T: record> = class sealed
  public
    type
      PSlot = ^T;
  strict private
    FHead: Integer;
    FTail: Integer;
    FSlots: array[0..RESPAWN_QUEUE_SIZE - 1] of T;
    FTimes: array[0..RESPAWN_QUEUE_SIZE - 1] of Integer;
  public
    /// <summary>Empties the queue (the slots are forgotten)</summary>
    procedure Clear; inline;

    /// <summary>Whether no item waits to respawn</summary>
    function IsEmpty: Boolean; inline;

    /// <summary>
    ///   Writes an item in the slot of the head and gives the slot; the head does not move until
    ///   Commit, so the caller may still change the slot or swap it with the oldest one
    /// </summary>
    /// <param name="AItem">The spawn point of the item</param>
    /// <param name="ATime">The tic from which the item may respawn</param>
    function Reserve(const AItem: T; const ATime: Integer): PSlot; inline;

    /// <summary>Moves the head after the slot of Reserve; if the queue is full the oldest item is lost</summary>
    procedure Commit; inline;

    /// <summary>Reserve and Commit</summary>
    procedure Add(const AItem: T; const ATime: Integer); inline;

    /// <summary>The slot of the oldest item</summary>
    /// <exception cref="EInvalidOpException">The queue is empty</exception>
    function Oldest: PSlot; inline;

    /// <summary>The tic stored with the oldest item</summary>
    /// <exception cref="EInvalidOpException">The queue is empty</exception>
    function OldestTime: Integer; inline;

    /// <summary>Takes the oldest item out of the queue</summary>
    /// <exception cref="EInvalidOpException">The queue is empty</exception>
    procedure DropOldest; inline;

    /// <summary>The index of the head slot (iquehead): for the tests</summary>
    property Head: Integer read FHead;
    /// <summary>The index of the oldest slot (iquetail): for the tests</summary>
    property Tail: Integer read FTail;
  end;

implementation


{ TRespawnQueue<T> }

procedure TRespawnQueue<T>.Clear;
begin
  FHead := 0;
  FTail := 0;
end;

function TRespawnQueue<T>.IsEmpty: Boolean;
begin
  Result := FHead = FTail;
end;

function TRespawnQueue<T>.Reserve(const AItem: T; const ATime: Integer): PSlot;
begin
  FSlots[FHead] := AItem;
  FTimes[FHead] := ATime;
  Result := @FSlots[FHead];
end;

procedure TRespawnQueue<T>.Commit;
begin
  FHead := (FHead + 1) and (RESPAWN_QUEUE_SIZE - 1);
  // lose one off the end?
  if FHead = FTail then
    FTail := (FTail + 1) and (RESPAWN_QUEUE_SIZE - 1);
end;

procedure TRespawnQueue<T>.Add(const AItem: T; const ATime: Integer);
begin
  Reserve(AItem, ATime);
  Commit;
end;

function TRespawnQueue<T>.Oldest: PSlot;
begin
  if FHead = FTail then
    raise EInvalidOpException.Create(SRespawnQueueEmpty);
  Result := @FSlots[FTail];
end;

function TRespawnQueue<T>.OldestTime: Integer;
begin
  if FHead = FTail then
    raise EInvalidOpException.Create(SRespawnQueueEmpty);
  Result := FTimes[FTail];
end;

procedure TRespawnQueue<T>.DropOldest;
begin
  if FHead = FTail then
    raise EInvalidOpException.Create(SRespawnQueueEmpty);
  FTail := (FTail + 1) and (RESPAWN_QUEUE_SIZE - 1);
end;

end.
