{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library - reads a Standard MIDI file as one list of events  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Midi.SequenceLoader;

{$Q-}
{$R-}
// The times of the events are unsigned numbers that wrap around, as in the old player

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Midi.Types;

type
  /// <summary>
  ///   Reads the bytes of a Standard MIDI file with the reader of the m2m library and joins its
  ///   tracks with the merger of the same library: the result is the single list of events, with
  ///   absolute times, that the sequencer of the midi stream walks
  /// </summary>
  /// <remarks>
  ///   The old player read a track as long as its length said, and kept the running status
  ///   across meta events; the reader is asked to do the same. A file with a type or a number of
  ///   tracks that the format does not know is read as it is (the tracks are merged anyway). The
  ///   end of track events are not in the result. A tempo event that does not have three bytes,
  ///   or that is zero, is read as a meta event of no use (the old player stopped the game, or
  ///   divided by zero)
  /// </remarks>
  TMidiSequenceLoader = class
  public
    /// <summary>
    ///   False, with a warning to ALog (that may be nil), if the bytes are not a file that can be
    ///   read; AEvents is then empty
    /// </summary>
    /// <param name="AData">The bytes of the file</param>
    /// <param name="ASize">Their number</param>
    /// <param name="ALog">Where the warnings go; nil for nowhere</param>
    /// <param name="AEvents">The events in the order of their time</param>
    /// <param name="ADivision">The division word of the header, as it is in the file</param>
    class function TryLoad(AData: Pointer; ASize: Integer; const ALog: ILog;
      out AEvents: TArray<TMidiSequenceEvent>; out ADivision: Word): Boolean; static;
  end;

implementation

uses
  DelphiDoom.M2m.Intf,
  DelphiDoom.M2m.Types,
  DelphiDoom.M2m.MidiFile,
  DelphiDoom.M2m.MidiReader,
  DelphiDoom.M2m.TrackMerger;

const
  READER_OPTIONS: TMidiReaderOptions = [mroRunningStatusAcrossMeta, mroTrackLengths, mroAnyHeader];
  TEMPO_DATA_LENGTH = 3;

  SNoData = 'MIDI: no data';
  SNotReadable = 'MIDI: the file cannot be read (%s)';
  SBadTempo = 'MIDI: a tempo event that is not valid is skipped';

function ChannelStatus(AType: TMidiEventType; AChannel: Integer): Byte;
begin
  case AType of
    metNoteOff: Result := $80;
    metNoteOn: Result := $90;
    metNoteAftertouch: Result := $A0;
    metController: Result := MIDI_CONTROL_CHANGE;
    metProgramChange: Result := $C0;
    metChannelAftertouch: Result := $D0;
    metPitchBend: Result := $E0;
  else
    Result := 0;
  end;
  Result := Result or Byte(AChannel and $0F);
end;

procedure FillEvent(const ASource: TMidiEvent; ATime: Cardinal; const ALog: ILog;
  out ATarget: TMidiSequenceEvent);
begin
  ATarget := Default(TMidiSequenceEvent);
  ATarget.Time := ATime;
  case ASource.EventType of
    metMeta:
      begin
        ATarget.Kind := mskOtherMeta;
        if ASource.Param1 = META_TEMPO then
        begin
          if Length(ASource.Data) = TEMPO_DATA_LENGTH then
          begin
            ATarget.Tempo := (Cardinal(ASource.Data[0]) shl 16) or (Cardinal(ASource.Data[1]) shl 8) or
              ASource.Data[2];
            if ATarget.Tempo <> 0 then
              ATarget.Kind := mskTempo;
          end;
          if (ATarget.Kind <> mskTempo) and Assigned(ALog) then
            ALog.DevWarning(SBadTempo);
        end;
      end;
    metSysEx, metSysExContinuation:
      ATarget.Kind := mskSystemExclusive;
  else
    ATarget.Kind := mskChannel;
    ATarget.Status := ChannelStatus(ASource.EventType, ASource.Channel);
    ATarget.Data1 := Byte(ASource.Param1);
    ATarget.Data2 := Byte(ASource.Param2);
  end;
end;

{ TMidiSequenceLoader }

class function TMidiSequenceLoader.TryLoad(AData: Pointer; ASize: Integer; const ALog: ILog;
  out AEvents: TArray<TMidiSequenceEvent>; out ADivision: Word): Boolean;
var
  LFile: TMidiFile;
  LMerged: TMidiFile;
  LTrack: TArray<TMidiEvent>;
  LCount: Integer;
  LIndex: Integer;
  LTime: Cardinal;
begin
  AEvents := nil;
  ADivision := 0;
  Result := False;
  if (AData = nil) or (ASize <= 0) then
  begin
    if Assigned(ALog) then
      ALog.Warning(SNoData);
    Exit;
  end;

  LFile := nil;
  LMerged := nil;
  try
    try
      LFile := TMidiReader.Parse(AData, ASize, READER_OPTIONS);
    except
      on E: EM2mException do
      begin
        if Assigned(ALog) then
          ALog.Warning(Format(SNotReadable, [E.Message]));
        Exit;
      end;
    end;

    ADivision := Word(LFile.RawDivision);
    if Length(LFile.Tracks) = 1 then
      LTrack := LFile.Tracks[0].Events
    else
    begin
      // the old player played the tracks of any file type together
      LFile.Mode := 1;
      LMerged := TMidiTrackMerger.Merge(LFile, True);
      LTrack := LMerged.Tracks[0].Events;
    end;

    SetLength(AEvents, Length(LTrack));
    LCount := 0;
    LTime := 0;
    for LIndex := 0 to High(LTrack) do
    begin
      Inc(LTime, LTrack[LIndex].Delta);
      if (LTrack[LIndex].EventType = metMeta) and (LTrack[LIndex].Param1 = META_ENDTRACK) then
        Continue;
      FillEvent(LTrack[LIndex], LTime, ALog, AEvents[LCount]);
      Inc(LCount);
    end;
    SetLength(AEvents, LCount);
    Result := True;
  finally
    LMerged.Free;
    LFile.Free;
  end;
end;

end.
