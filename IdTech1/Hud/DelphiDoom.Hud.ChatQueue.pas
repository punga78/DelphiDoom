{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - the queue of the chat characters     }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.ChatQueue;

interface

uses
  DelphiDoom.Hud.Types;

type
  /// <summary>
  ///   The characters the player typed and the network did not send yet (the old chatchars):
  ///   a ring of HUD_CHAT_QUEUE_SIZE - 1 places, one is kept free to tell empty from full
  /// </summary>
  THudChatQueue = class sealed
  strict private
    FChars: array[0..HUD_CHAT_QUEUE_SIZE - 1] of Char;
    FHead: Integer;
    FTail: Integer;
  public
    /// <summary>Puts a character in the queue, false if the queue is full (HU_queueChatChar)</summary>
    function Enqueue(const AChar: Char): Boolean;
    /// <summary>Takes the oldest character out, #0 if the queue is empty (HU_dequeueChatChar)</summary>
    function Dequeue: Char;
    /// <summary>Characters waiting</summary>
    function Count: Integer;
  end;

implementation

{ THudChatQueue }

function THudChatQueue.Enqueue(const AChar: Char): Boolean;
begin
  Result := ((FHead + 1) and (HUD_CHAT_QUEUE_SIZE - 1)) <> FTail;
  if not Result then
    Exit;
  FChars[FHead] := AChar;
  FHead := (FHead + 1) and (HUD_CHAT_QUEUE_SIZE - 1);
end;

function THudChatQueue.Dequeue: Char;
begin
  if FHead = FTail then
    Exit(#0);
  Result := FChars[FTail];
  FTail := (FTail + 1) and (HUD_CHAT_QUEUE_SIZE - 1);
end;

function THudChatQueue.Count: Integer;
begin
  Result := (FHead - FTail) and (HUD_CHAT_QUEUE_SIZE - 1);
end;

end.
