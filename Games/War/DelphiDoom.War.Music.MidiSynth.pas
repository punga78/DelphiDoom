{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the music on the MIDI output of the machine       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Music.MidiSynth;

interface

uses
  System.SysUtils, DelphiDoom.Midi.Output.Intf, DelphiDoom.War.Music.Intf;

type
  /// <summary>
  ///   The synth that needs no SoundFont: the events of the song are sent as MIDI messages to the device of the machine
  ///   (on Windows the General MIDI synth of the system), which makes the sound itself, so Render adds nothing to the
  ///   samples. The player keeps the time of the song and sends each event when it is due. As the device does not pass
  ///   through the samples, the fade is done on the volume controller (7) of the channels: the volume the song gives is
  ///   kept and multiplied by the gain that the player tells (IWarMusicDevice)
  /// </summary>
  TWarMidiMusicSynth = class(TInterfacedObject, IWarMusicSynth, IWarMusicDevice)
  strict private
    const
      CHANNEL_COUNT = 16;
      CONTROLLER_VOLUME = 7;
      CONTROLLER_ALL_SOUND_OFF = 120;
      CONTROLLER_RESET_ALL = 121;
      CONTROLLER_ALL_NOTES_OFF = 123;
      // the volume a channel has until the song sets it (General MIDI)
      DEFAULT_VOLUME = 100;
      PITCH_BEND_CENTER = 8192;
    var
      FOutput: IMidiShortOutput;
      FVolumes: array[0..CHANNEL_COUNT - 1] of Integer;
      FGain: Integer;
    procedure SendVolume(AChannel: Integer);
    procedure SendAllVolumes;
  public
    constructor Create(const AOutput: IMidiShortOutput);
    procedure ProgramChange(AChannel, AProgram: Integer; AIsDrums: Boolean);
    procedure NoteOn(AChannel, AKey: Integer; AVelocity: Single);
    procedure NoteOff(AChannel, AKey: Integer);
    procedure PitchBend(AChannel, AValue: Integer);
    procedure ControlChange(AChannel, AController, AValue: Integer);
    procedure AllNotesOff;
    procedure Render(ABuffer: PSmallInt; ASampleCount: Integer);
    procedure SetGain(AGain: Integer);
    procedure ResetChannels;
  end;

implementation

uses
  System.Math, DelphiDoom.War.Music.Types;

const
  STATUS_NOTE_OFF = $80;
  STATUS_NOTE_ON = $90;
  STATUS_CONTROL_CHANGE = $B0;
  STATUS_PROGRAM_CHANGE = $C0;
  STATUS_PITCH_BEND = $E0;
  // the release velocity of a note off: the original does not give one
  NOTE_OFF_VELOCITY = 64;

{ TWarMidiMusicSynth }

constructor TWarMidiMusicSynth.Create(const AOutput: IMidiShortOutput);
var
  LChannel: Integer;
begin
  inherited Create;
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  FOutput := AOutput;
  FGain := WAR_MUSIC_GAIN_FULL;
  for LChannel := 0 to CHANNEL_COUNT - 1 do
    FVolumes[LChannel] := DEFAULT_VOLUME;
end;

procedure TWarMidiMusicSynth.SendVolume(AChannel: Integer);
begin
  FOutput.Send(STATUS_CONTROL_CHANGE or Byte(AChannel), CONTROLLER_VOLUME,
    Byte((Int64(FVolumes[AChannel]) * FGain) div WAR_MUSIC_GAIN_FULL));
end;

procedure TWarMidiMusicSynth.SendAllVolumes;
var
  LChannel: Integer;
begin
  for LChannel := 0 to CHANNEL_COUNT - 1 do
    SendVolume(LChannel);
end;

procedure TWarMidiMusicSynth.ProgramChange(AChannel, AProgram: Integer; AIsDrums: Boolean);
begin
  // the drums of General MIDI are the channel 10 whatever its program: the device knows it from the channel
  FOutput.Send(STATUS_PROGRAM_CHANGE or Byte(AChannel and $0F), Byte(AProgram and $7F), 0);
end;

procedure TWarMidiMusicSynth.NoteOn(AChannel, AKey: Integer; AVelocity: Single);
var
  LVelocity: Integer;
begin
  // the player gives velocity / 127 already scaled by the volume of the music; a velocity of 0 would be a note off
  LVelocity := EnsureRange(Round(AVelocity * 127), 0, 127);
  if LVelocity = 0 then
    Exit;
  FOutput.Send(STATUS_NOTE_ON or Byte(AChannel and $0F), Byte(AKey and $7F), Byte(LVelocity));
end;

procedure TWarMidiMusicSynth.NoteOff(AChannel, AKey: Integer);
begin
  FOutput.Send(STATUS_NOTE_OFF or Byte(AChannel and $0F), Byte(AKey and $7F), NOTE_OFF_VELOCITY);
end;

procedure TWarMidiMusicSynth.PitchBend(AChannel, AValue: Integer);
var
  LValue: Integer;
begin
  LValue := EnsureRange(AValue, 0, $3FFF);
  FOutput.Send(STATUS_PITCH_BEND or Byte(AChannel and $0F), Byte(LValue and $7F), Byte(LValue shr 7));
end;

procedure TWarMidiMusicSynth.ControlChange(AChannel, AController, AValue: Integer);
var
  LChannel: Integer;
begin
  LChannel := AChannel and $0F;
  if (AController and $7F) = CONTROLLER_VOLUME then
  begin
    FVolumes[LChannel] := EnsureRange(AValue, 0, 127);
    SendVolume(LChannel);
    Exit;
  end;
  FOutput.Send(STATUS_CONTROL_CHANGE or Byte(LChannel), Byte(AController and $7F), Byte(EnsureRange(AValue, 0, 127)));
end;

procedure TWarMidiMusicSynth.AllNotesOff;
var
  LChannel: Integer;
begin
  for LChannel := 0 to CHANNEL_COUNT - 1 do
  begin
    FOutput.Send(STATUS_CONTROL_CHANGE or Byte(LChannel), CONTROLLER_ALL_NOTES_OFF, 0);
    FOutput.Send(STATUS_CONTROL_CHANGE or Byte(LChannel), CONTROLLER_ALL_SOUND_OFF, 0);
  end;
end;

procedure TWarMidiMusicSynth.Render(ABuffer: PSmallInt; ASampleCount: Integer);
begin
  // the device plays by itself: nothing is added to the samples
end;

procedure TWarMidiMusicSynth.SetGain(AGain: Integer);
begin
  AGain := EnsureRange(AGain, 0, WAR_MUSIC_GAIN_FULL);
  if AGain = FGain then
    Exit;
  FGain := AGain;
  SendAllVolumes;
end;

procedure TWarMidiMusicSynth.ResetChannels;
var
  LChannel: Integer;
begin
  for LChannel := 0 to CHANNEL_COUNT - 1 do
  begin
    FVolumes[LChannel] := DEFAULT_VOLUME;
    FOutput.Send(STATUS_CONTROL_CHANGE or Byte(LChannel), CONTROLLER_RESET_ALL, 0);
    FOutput.Send(STATUS_PITCH_BEND or Byte(LChannel), PITCH_BEND_CENTER and $7F, PITCH_BEND_CENTER shr 7);
    SendVolume(LChannel);
  end;
end;

end.
