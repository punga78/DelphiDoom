{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the contracts between the music backends                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Music.Intf;

interface

type
  /// <summary>
  ///   The midi stream of Windows that plays the MUS songs. The backends of the MIDI files close
  ///   it before they play, as the old I_StopMus of i_music did
  /// </summary>
  IEngineMidiStream = interface
    ['{5B0E2C71-8D34-4F6A-9C1B-7A2E64D0F385}']
    /// <summary>Stops and closes the stream; nothing if it is not open</summary>
    procedure Close;
  end;

implementation

end.
