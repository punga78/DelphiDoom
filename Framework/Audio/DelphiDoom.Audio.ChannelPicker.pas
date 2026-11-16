{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - which channel of the game a new sound takes     }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.ChannelPicker;

interface

type
  /// <summary>
  ///   A channel of the game (the channel_t of s_sound.pas, same layout): the sound that it
  ///   plays (nil = free; for the library an opaque pointer), who makes it and the handle of
  ///   the player
  /// </summary>
  TSfxChannelSlot = record
    Sound: Pointer;
    Origin: Pointer;
    Handle: Integer;
  end;
  PSfxChannelSlot = ^TSfxChannelSlot;

  /// <summary>The priority of a sound (sfxinfo_t.priority of the engine)</summary>
  TSfxPriorityFunction = function(ASound: Pointer): Integer;

  /// <summary>What Pick decided</summary>
  TSfxChannelChoice = record
    /// <summary>The channel for the new sound; -1 when every channel is busy with something that matters more</summary>
    Channel: Integer;
    /// <summary>The channel plays something that the caller must stop before using it</summary>
    MustStop: Boolean;
  end;

  /// <summary>
  ///   S_GetChannel of s_sound.pas as a decision without effects: the engine stops the channel
  ///   (if asked) and writes the new sound in it. These are the channels of the game (who
  ///   plays what, by origin and priority), not the voices of the device that TSfxPlayer keeps
  /// </summary>
  TSfxChannelPicker = class sealed
  public
    /// <summary>
    ///   The first free channel, or the first one of the same origin (to stop); with all of
    ///   them busy the first one whose priority number is greater than APriority, then the
    ///   first one with the same, then (only for a sound of the listener or without origin)
    ///   the first one of another origin
    /// </summary>
    class function Pick(AChannels: PSfxChannelSlot; ACount: Integer; AOrigin, AListener: Pointer;
      APriority: Integer; APriorityOf: TSfxPriorityFunction): TSfxChannelChoice; static;
  end;

implementation

{$POINTERMATH ON}

{ TSfxChannelPicker }

class function TSfxChannelPicker.Pick(AChannels: PSfxChannelSlot; ACount: Integer; AOrigin,
  AListener: Pointer; APriority: Integer; APriorityOf: TSfxPriorityFunction): TSfxChannelChoice;
var
  LChannel: Integer;
begin
  Result.MustStop := False;

  LChannel := 0;
  while LChannel < ACount do
  begin
    if not Assigned(AChannels[LChannel].Sound) then
      Break;
    if Assigned(AOrigin) and (AChannels[LChannel].Origin = AOrigin) then
    begin
      Result.MustStop := True;
      Break;
    end;
    Inc(LChannel);
  end;

  if LChannel = ACount then
  begin
    // every channel is busy: one that matters less
    LChannel := 0;
    while LChannel < ACount do
    begin
      if APriorityOf(AChannels[LChannel].Sound) > APriority then
        Break;
      Inc(LChannel);
    end;

    if LChannel = ACount then
    begin
      LChannel := 0;
      while LChannel < ACount do
      begin
        if APriorityOf(AChannels[LChannel].Sound) = APriority then
          Break;
        Inc(LChannel);
      end;
    end;

    if (LChannel = ACount) and ((AOrigin = AListener) or not Assigned(AOrigin)) then
    begin
      LChannel := 0;
      while LChannel < ACount do
      begin
        if Assigned(AChannels[LChannel].Origin) and (AChannels[LChannel].Origin <> AListener) then
          Break;
        Inc(LChannel);
      end;
    end;

    if LChannel = ACount then
    begin
      Result.Channel := -1;
      Exit;
    end;
    Result.MustStop := True;
  end;

  Result.Channel := LChannel;
end;

end.
