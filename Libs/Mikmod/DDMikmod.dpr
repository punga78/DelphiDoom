{******************************************************************************}
{                                                                              }
{  DDMikmod.dll: the tracker (module music) for DelphiDoom                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
library DDMikmod;

uses
  DelphiDoom.Mikmod.Intf in 'DelphiDoom.Mikmod.Intf.pas',
  DelphiDoom.Tracker.Types in 'DelphiDoom.Tracker.Types.pas',
  DelphiDoom.Tracker.ByteReader in 'DelphiDoom.Tracker.ByteReader.pas',
  DelphiDoom.Tracker.Loader.ProTracker in 'DelphiDoom.Tracker.Loader.ProTracker.pas',
  DelphiDoom.Tracker.Loader.S3m in 'DelphiDoom.Tracker.Loader.S3m.pas',
  DelphiDoom.Tracker.Decompressor.It in 'DelphiDoom.Tracker.Decompressor.It.pas',
  DelphiDoom.Tracker.Loader.Xm in 'DelphiDoom.Tracker.Loader.Xm.pas',
  DelphiDoom.Tracker.Loader.It in 'DelphiDoom.Tracker.Loader.It.pas',
  DelphiDoom.Tracker.Effects in 'DelphiDoom.Tracker.Effects.pas',
  DelphiDoom.Tracker.EnvelopeCursor in 'DelphiDoom.Tracker.EnvelopeCursor.pas',
  DelphiDoom.Tracker.NoteEnvelopes in 'DelphiDoom.Tracker.NoteEnvelopes.pas',
  DelphiDoom.Tracker.Voice in 'DelphiDoom.Tracker.Voice.pas',
  DelphiDoom.Tracker.Mixer in 'DelphiDoom.Tracker.Mixer.pas',
  DelphiDoom.Tracker.Ghost in 'DelphiDoom.Tracker.Ghost.pas',
  DelphiDoom.Tracker.GhostPool in 'DelphiDoom.Tracker.GhostPool.pas',
  DelphiDoom.Tracker.Channel in 'DelphiDoom.Tracker.Channel.pas',
  DelphiDoom.Tracker.Player in 'DelphiDoom.Tracker.Player.pas',
  DelphiDoom.Tracker.WaveOut in 'DelphiDoom.Tracker.WaveOut.pas',
  DelphiDoom.Mikmod.TrackerPlayer in 'DelphiDoom.Mikmod.TrackerPlayer.pas',
  DelphiDoom.Mikmod.TrackerEngine in 'DelphiDoom.Mikmod.TrackerEngine.pas';

function DDMikmodCreate(out AMikMod: IMikMod): Integer; stdcall;
begin
  AMikMod := nil;
  try
    AMikMod := TTrackerMikModEngine.Create;
    Result := MIKMOD_OK;
  except
    Result := MIKMOD_ERR_INTERNAL;
  end;
end;

exports
  DDMikmodCreate;

begin
end.
