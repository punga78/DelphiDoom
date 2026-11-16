{******************************************************************************}
{                                                                              }
{  DelphiDoom: CMF - turns the events of a CMF song into standard MIDI         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Converter.CmfToMidi;

interface

uses
  System.SysUtils, DelphiDoom.Xmi.Midi.Types, DelphiDoom.Xmi.Midi.Song;

type
  /// <summary>
  ///   Gives a CMF song the events of a standard MIDI one
  /// </summary>
  /// <remarks>
  ///   CMF uses a few controllers for its own purposes: they are dropped (AM
  ///   and vibrato depth, transpose) or turned into a marker text. While the
  ///   rhythm mode is on, the notes of the channels 11 to 15 stand for drums
  ///   and are moved to the percussion channel; the tempo events count double
  /// </remarks>
  TXmiCmfToMidiConverter = class
  private
    class procedure ConvertDrum(AEvent: PXmiEvent); static;
  public
    /// <summary>
    ///   Converts every track of the song in place
    /// </summary>
    class procedure Convert(ASong: TXmiSong); static;
  end;

implementation

uses
  DelphiDoom.Xmi.Midi.Track;

const
  STATUS_NOTE_OFF = 8;
  STATUS_NOTE_ON = 9;
  STATUS_CONTROL = 11;
  STATUS_PROGRAM = 12;
  STATUS_SYSTEM = 15;

  // Controllers of CMF
  CONTROL_AM_VIBRATO = $63;
  CONTROL_MARKER = $66;
  CONTROL_RHYTHM_MODE = $67;
  CONTROL_TRANSPOSE_UP = $68;
  CONTROL_TRANSPOSE_DOWN = $69;

  PERCUSSION_CHANNEL = 9;
  FIRST_RHYTHM_CHANNEL = 11;

  // The tempo written at the beginning: one second per quarter note
  CMF_TEMPO = 1000000;

{ TXmiCmfToMidiConverter }

class procedure TXmiCmfToMidiConverter.ConvertDrum(AEvent: PXmiEvent);
var
  LNote: Byte;
begin
  case AEvent.Status and 15 of
    11: // Bass drum
      begin
        if AEvent.Param1 <= 36 then
          LNote := 35
        else
          LNote := 36;
      end;
    12: // Snare drum
      begin
        if AEvent.Param1 <= 40 then
          LNote := 38
        else
          LNote := 40;
      end;
    13: // Tom
      begin
        LNote := 45;
        if AEvent.Param1 < 39 then
          LNote := 41;
        if AEvent.Param1 = 39 then
          LNote := 43;
        if AEvent.Param1 = 40 then
          LNote := 45;
        if AEvent.Param1 = 41 then
          LNote := 47;
        if AEvent.Param1 = 42 then
          LNote := 48;
        if AEvent.Param1 > 42 then
          LNote := 50;
      end;
    14: // Cymbal
      begin
        LNote := 57;
        if AEvent.Param1 <= 50 then
          LNote := 49;
        if (AEvent.Param1 > 50) and (AEvent.Param1 <= 65) then
          LNote := 57;
        if AEvent.Param1 > 65 then
          LNote := 55;
      end;
    15: // Hi-hat
      begin
        if AEvent.Param1 <= 44 then
          LNote := 42
        else
          LNote := 44;
      end;
  else
    Exit;
  end;

  AEvent.Status := (AEvent.Status and $F0) or PERCUSSION_CHANNEL;
  AEvent.Param1 := LNote;
end;

class procedure TXmiCmfToMidiConverter.Convert(ASong: TXmiSong);
var
  LTrack: TXmiTrack;
  LTrackIndex: Integer;
  LIndex: Integer;
  LRhythm: Boolean;
  LEvent: PXmiEvent;
  LTempo: TXmiEvent;
begin
  LRhythm := False;
  for LTrackIndex := 0 to ASong.Tracks.Count - 1 do
  begin
    LTrack := ASong.Tracks[LTrackIndex];
    LIndex := 0;
    while LIndex < LTrack.Count do
    begin
      LEvent := LTrack.EventAt(LIndex);
      case LEvent.Status shr 4 of
        STATUS_NOTE_OFF, STATUS_NOTE_ON:
          if LRhythm then
            ConvertDrum(LEvent);
        STATUS_CONTROL:
          case LEvent.Param1 of
            CONTROL_AM_VIBRATO, CONTROL_TRANSPOSE_UP, CONTROL_TRANSPOSE_DOWN:
              begin
                // MIDI has nothing like these
                LTrack.Delete(LIndex, True);
                Continue;
              end;
            CONTROL_MARKER:
              begin
                // A marker for whoever reads the file
                LEvent.Status := XMI_STATUS_META;
                LEvent.Param1 := 6;
                LEvent.Text := AnsiString(IntToStr(LEvent.Param2));
                LEvent.Param2 := 0;
              end;
            CONTROL_RHYTHM_MODE:
              begin
                LRhythm := LEvent.Param2 > 0;
                LTrack.Delete(LIndex, True);
                Continue;
              end;
          end;
        STATUS_PROGRAM:
          if LRhythm and ((LEvent.Status and $F) >= FIRST_RHYTHM_CHANNEL) then
          begin
            // The instruments of the drums are not changed
            LTrack.Delete(LIndex, True);
            Continue;
          end;
        STATUS_SYSTEM:
          if (LEvent.Status = XMI_STATUS_META) and
             (LEvent.Param1 = XMI_META_TEMPO) then
            LEvent.Value := LEvent.Value * 2;
      end;
      Inc(LIndex);
    end;

    // The song starts with its tempo
    LTempo := Default(TXmiEvent);
    LTempo.Status := XMI_STATUS_META;
    LTempo.Param1 := XMI_META_TEMPO;
    LTempo.Value := CMF_TEMPO;
    LTrack.Insert(0, LTempo);
  end;

  ASong.MidiType := XMI_MIDI_TYPE_SINGLE_TRACK;
  ASong.InitialTempo := XMI_MIDI_STANDARD_TEMPO;
  ASong.Smpte := 0;
end;

end.
