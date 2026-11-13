{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotConsoleMessageHeap, the heap of console messages   }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): InitConsoleMessage  }
{  Heap, AllocConsoleMessage and FreeConsoleMessage of code\botlib\            }
{  be_ai_chat.c. Based on the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.ConsoleHeap;

interface

type
  /// <summary>
  ///   The fixed number of console messages all the chat states share (the library variable
  ///   max_messages): the messages themselves are kept by the states, the heap counts the free ones.
  /// </summary>
  TBotConsoleMessageHeap = class
  strict private
    FSize: Integer;
    FFree: Integer;
  public
    /// <summary>InitConsoleMessageHeap: all the messages are free; before it there are none</summary>
    procedure Init(const ASize: Integer);
    /// <summary>AllocConsoleMessage: false if the heap is empty</summary>
    function TryAllocate: Boolean;
    /// <summary>FreeConsoleMessage</summary>
    procedure Release;
    property FreeCount: Integer read FFree;
  end;

implementation

{ TBotConsoleMessageHeap }

procedure TBotConsoleMessageHeap.Init(const ASize: Integer);
begin
  FSize := ASize;
  FFree := ASize;
end;

function TBotConsoleMessageHeap.TryAllocate: Boolean;
begin
  Result := FFree > 0;
  if Result then
    Dec(FFree);
end;

procedure TBotConsoleMessageHeap.Release;
begin
  if FFree < FSize then
    Inc(FFree);
end;

end.
