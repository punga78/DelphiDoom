{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - a synth that makes no sound                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Music.SilentSynth;

interface

uses
  DelphiDoom.War.Music.Intf;

type
  /// <summary>
  ///   What the game gets until a real synth is chosen (the SoundFont of the original has no declared license, so
  ///   none is ported): it takes every call and adds nothing to the samples. The songs advance, fade and end as
  ///   with a synth that sounds
  /// </summary>
  TWarSilentMusicSynth = class(TInterfacedObject, IWarMusicSynth)
  public
    procedure ProgramChange(AChannel, AProgram: Integer; AIsDrums: Boolean);
    procedure NoteOn(AChannel, AKey: Integer; AVelocity: Single);
    procedure NoteOff(AChannel, AKey: Integer);
    procedure PitchBend(AChannel, AValue: Integer);
    procedure ControlChange(AChannel, AController, AValue: Integer);
    procedure AllNotesOff;
    procedure Render(ABuffer: PSmallInt; ASampleCount: Integer);
  end;

implementation

{ TWarSilentMusicSynth }

procedure TWarSilentMusicSynth.ProgramChange(AChannel, AProgram: Integer; AIsDrums: Boolean);
begin
end;

procedure TWarSilentMusicSynth.NoteOn(AChannel, AKey: Integer; AVelocity: Single);
begin
end;

procedure TWarSilentMusicSynth.NoteOff(AChannel, AKey: Integer);
begin
end;

procedure TWarSilentMusicSynth.PitchBend(AChannel, AValue: Integer);
begin
end;

procedure TWarSilentMusicSynth.ControlChange(AChannel, AController, AValue: Integer);
begin
end;

procedure TWarSilentMusicSynth.AllNotesOff;
begin
end;

procedure TWarSilentMusicSynth.Render(ABuffer: PSmallInt; ASampleCount: Integer);
begin
  // it adds silence: the buffer stays as it is
end;

end.
