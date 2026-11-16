{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI to MUS - writes a type 0 MIDI file as a MUS file           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from m2m by Colin Phipps (BSD licence)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.M2m.Converter;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  DelphiDoom.M2m.MidiFile,
  DelphiDoom.M2m.MusTrack,
  DelphiDoom.M2m.Types;

type
  /// <summary>
  ///   Turns the single track of a MIDI file into a MUS file: the channels
  ///   are numbered again from zero (the percussion is 15), the events that
  ///   MUS does not have are dropped, and the times are counted in the 140
  ///   clocks per second of MUS
  /// </summary>
  TMidiToMusConverter = class
  private
    FMidi: TMidiFile;
    FTrack: TMusTrack;
    FPatches: TList<Integer>;
    FVelocityCache: array[0..15] of Integer;
    FChannelMap: array[0..15] of Integer;
    FNextChannel: Integer;
    FSamplesPerClock: Double;
    FFoundEnd: Boolean;
    constructor Create(const AMidi: TMidiFile);
    class function SamplesPerClockNormal(const AClocksPerQuarter, ATempo: Cardinal): Double; static;
    class function SamplesPerClockSmpte(const AFramesPerSecond, AClocksPerFrame: Cardinal): Double; static;
    procedure AddPatch(const APatch: Integer);
    procedure Translate(const AEvent: TMidiEvent; const AOutChannel: Integer;
      var AData: array of Byte; out ALength: Integer);
    procedure TranslateController(const AEvent: TMidiEvent; const AOutChannel: Integer;
      var AData: array of Byte; out ALength: Integer);
    procedure TranslateMeta(const AEvent: TMidiEvent; var AData: array of Byte; out ALength: Integer);
    function Run: TBytes;
  public
    destructor Destroy; override;

    /// <param name="AMidi">A file of type 0</param>
    /// <returns>The MUS file</returns>
    /// <exception cref="EM2mException">AMidi has several tracks, or the song does not fit in MUS</exception>
    class function Convert(const AMidi: TMidiFile): TBytes; static;
  end;

implementation

uses
  System.Math,
  DelphiDoom.M2m.Intf;

const
  // MUS counts 140 clocks in a second
  MUS_CLOCKS_PER_SECOND = 140;
  // The tempo that a file has until it says otherwise: 120 beats per minute
  DEFAULT_TEMPO = 500000;
  MICROSECONDS_PER_SECOND = 1000000;
  PERCUSSION_MIDI_CHANNEL = 9;
  PERCUSSION_MUS_CHANNEL = 15;
  MIDI_CHANNELS = 16;
  UNUSED = -1;
  // The percussion patches come after the instruments
  PERCUSSION_PATCH_BASE = 100;
  SCORE_EVENT_END = $60;
  MUS_EVENT_RELEASE = $00;
  MUS_EVENT_PLAY = $10;
  MUS_EVENT_PITCHBEND = $20;
  MUS_EVENT_SYSTEM = $30;
  MUS_EVENT_CONTROLLER = $40;
  KEY_WITH_VELOCITY = $80;
  HEADER_LENGTH = 16;
  PRIMARY_CHANNELS = 15;
  UNSIGNED_LIMIT = $100000000;
  MUS_SIGNATURE: array[0..3] of Byte = (Ord('M'), Ord('U'), Ord('S'), $1A);

  // The numbers that MUS gives to the controllers that it has
  MUS_CONTROLLER_PROGRAM = 0;
  MUS_CONTROLLER_BANK = 1;
  MUS_CONTROLLER_MODULATION = 2;
  MUS_CONTROLLER_VOLUME = 3;
  MUS_CONTROLLER_PAN = 4;
  MUS_CONTROLLER_EXPRESSION = 5;
  MUS_CONTROLLER_REVERB = 6;
  MUS_CONTROLLER_CHORUS = 7;
  MUS_CONTROLLER_SUSTAIN = 8;
  MUS_CONTROLLER_SOFT = 9;
  MUS_SYSTEM_SOUNDS_OFF = 10;
  MUS_SYSTEM_NOTES_OFF = 11;
  MUS_SYSTEM_MONO = 12;
  MUS_SYSTEM_POLY = 13;
  MUS_SYSTEM_RESET = 14;

{ TMidiToMusConverter }

constructor TMidiToMusConverter.Create(const AMidi: TMidiFile);
var
  LChannel: Integer;
begin
  inherited Create;
  FMidi := AMidi;
  FTrack := TMusTrack.Create;
  FPatches := TList<Integer>.Create;
  for LChannel := 0 to MIDI_CHANNELS - 1 do
    FChannelMap[LChannel] := UNUSED;
  FChannelMap[PERCUSSION_MIDI_CHANNEL] := PERCUSSION_MUS_CHANNEL;
end;

destructor TMidiToMusConverter.Destroy;
begin
  FPatches.Free;
  FTrack.Free;
  inherited Destroy;
end;

class function TMidiToMusConverter.Convert(const AMidi: TMidiFile): TBytes;
var
  LConverter: TMidiToMusConverter;
begin
  LConverter := TMidiToMusConverter.Create(AMidi);
  try
    Result := LConverter.Run;
  finally
    LConverter.Free;
  end;
end;

// Samples (here MUS clocks) per MIDI clock, for a file counted in quarter notes
class function TMidiToMusConverter.SamplesPerClockNormal(const AClocksPerQuarter, ATempo: Cardinal): Double;
begin
  // One expression: the steps are not rounded to a double one by one, only the result
  Result := ATempo / MICROSECONDS_PER_SECOND * MUS_CLOCKS_PER_SECOND / AClocksPerQuarter;
end;

// The same for a file counted in SMPTE frames: the tempo does not matter
class function TMidiToMusConverter.SamplesPerClockSmpte(const AFramesPerSecond, AClocksPerFrame: Cardinal): Double;
var
  LFrames: Double;
begin
  case AFramesPerSecond of
    24, 25, 30:
      LFrames := AFramesPerSecond;
    29:
      LFrames := AFramesPerSecond * 1000.0 / 1001.0;
  else
    LFrames := 30.0;
  end;
  Result := MUS_CLOCKS_PER_SECOND / LFrames / AClocksPerFrame;
end;

procedure TMidiToMusConverter.AddPatch(const APatch: Integer);
begin
  if not FPatches.Contains(APatch) then
    FPatches.Add(APatch);
end;

procedure TMidiToMusConverter.TranslateController(const AEvent: TMidiEvent; const AOutChannel: Integer;
  var AData: array of Byte; out ALength: Integer);

  procedure ControllerMessage(const AMusController: Integer);
  begin
    AData[0] := Byte(AOutChannel or MUS_EVENT_CONTROLLER);
    AData[1] := Byte(AMusController);
    AData[2] := Byte(AEvent.Param2);
    ALength := 3;
  end;

  procedure SystemMessage(const AMusSystem: Integer);
  begin
    AData[0] := Byte(AOutChannel or MUS_EVENT_SYSTEM);
    AData[1] := Byte(AMusSystem);
    ALength := 2;
  end;

begin
  ALength := 0;
  case AEvent.Param1 of
    CONTROLLER_BANKSELECT + CONTROLLER_LSB_OFFSET: ControllerMessage(MUS_CONTROLLER_BANK);
    CONTROLLER_MODWHEEL: ControllerMessage(MUS_CONTROLLER_MODULATION);
    CONTROLLER_CHANNELVOLUME: ControllerMessage(MUS_CONTROLLER_VOLUME);
    CONTROLLER_PAN: ControllerMessage(MUS_CONTROLLER_PAN);
    CONTROLLER_EXPRESSION: ControllerMessage(MUS_CONTROLLER_EXPRESSION);
    CONTROLLER_REVERB: ControllerMessage(MUS_CONTROLLER_REVERB);
    CONTROLLER_CHORUS: ControllerMessage(MUS_CONTROLLER_CHORUS);
    CONTROLLER_SUSTAIN: ControllerMessage(MUS_CONTROLLER_SUSTAIN);
    CONTROLLER_SOFTPEDAL: ControllerMessage(MUS_CONTROLLER_SOFT);
    CONTROLLER_ALL_SOUND_OFF: SystemMessage(MUS_SYSTEM_SOUNDS_OFF);
    CONTROLLER_ALL_NOTES_OFF: SystemMessage(MUS_SYSTEM_NOTES_OFF);
    CONTROLLER_MONO_ON: SystemMessage(MUS_SYSTEM_MONO);
    CONTROLLER_POLY_ON: SystemMessage(MUS_SYSTEM_POLY);
    CONTROLLER_RESET_ALL: SystemMessage(MUS_SYSTEM_RESET);
  end;
end;

procedure TMidiToMusConverter.TranslateMeta(const AEvent: TMidiEvent; var AData: array of Byte;
  out ALength: Integer);
var
  LTempo: Cardinal;
begin
  ALength := 0;
  case AEvent.Param1 of
    META_TEMPO:
      // A tempo means nothing in a file counted in SMPTE frames, and it has three bytes
      if (FMidi.SmpteFps = 0) and (Length(AEvent.Data) = 3) then
      begin
        LTempo := (Cardinal(AEvent.Data[0]) shl 16) or (Cardinal(AEvent.Data[1]) shl 8) or AEvent.Data[2];
        FSamplesPerClock := SamplesPerClockNormal(Cardinal(FMidi.Timing), LTempo);
      end;
    META_ENDTRACK:
      begin
        AData[0] := SCORE_EVENT_END;
        ALength := 1;
        FFoundEnd := True;
      end;
  end;
end;

procedure TMidiToMusConverter.Translate(const AEvent: TMidiEvent; const AOutChannel: Integer;
  var AData: array of Byte; out ALength: Integer);
begin
  ALength := 0;
  case AEvent.EventType of
    metNoteOn, metNoteOff:
      if (AEvent.EventType = metNoteOn) and (AEvent.Param2 <> 0) then
      begin
        // The percussion is a patch of its own for each key
        if AEvent.Channel = PERCUSSION_MIDI_CHANNEL then
          AddPatch(AEvent.Param1 + PERCUSSION_PATCH_BASE);

        AData[0] := Byte(AOutChannel or MUS_EVENT_PLAY);
        if AEvent.Param2 = FVelocityCache[AOutChannel] then
        begin
          // The velocity is the one of the last note of the channel: it is not written
          AData[1] := Byte(AEvent.Param1);
          ALength := 2;
        end
        else
        begin
          AData[1] := Byte(AEvent.Param1 or KEY_WITH_VELOCITY);
          FVelocityCache[AOutChannel] := AEvent.Param2;
          AData[2] := Byte(AEvent.Param2);
          ALength := 3;
        end;
      end
      else
      begin
        // A note on with velocity zero is a note off, and the velocity of a note off is lost
        AData[0] := Byte(AOutChannel or MUS_EVENT_RELEASE);
        AData[1] := Byte(AEvent.Param1);
        ALength := 2;
      end;
    metController:
      TranslateController(AEvent, AOutChannel, AData, ALength);
    metProgramChange:
      begin
        AData[0] := Byte(AOutChannel or MUS_EVENT_CONTROLLER);
        AData[1] := MUS_CONTROLLER_PROGRAM;
        AData[2] := Byte(AEvent.Param1);
        ALength := 3;
        if AOutChannel <> PERCUSSION_MUS_CHANNEL then
          AddPatch(AEvent.Param1);
      end;
    metPitchBend:
      begin
        AData[0] := Byte(AOutChannel or MUS_EVENT_PITCHBEND);
        // The 14 bits of the bend become 8
        AData[1] := Byte((AEvent.Param1 or (AEvent.Param2 shl 7)) shr 6);
        ALength := 2;
      end;
    metMeta:
      TranslateMeta(AEvent, AData, ALength);
  end;
end;

function TMidiToMusConverter.Run: TBytes;
var
  LTrack: TMidiTrack;
  LEvent: TMidiEvent;
  LData: array[0..3] of Byte;
  LLength, LEventNumber, LOutChannel, LUnusedChannel, LIndex: Integer;
  LEventDelta, LError, LSum: Double;
  LClocks: Cardinal;
  LPrimary: Integer;
  LOffset: Integer;

  procedure PutWord(const AValue: Integer);
  begin
    Result[LOffset] := Byte(AValue and $FF);
    Result[LOffset + 1] := Byte((AValue shr 8) and $FF);
    Inc(LOffset, 2);
  end;

var
  LScore: TBytes;
begin
  if FMidi.Mode <> 0 then
    raise EM2mException.CreateCode(M2M_ERROR_CONVERT);

  // The time of the first event of the track; Timing zero would divide by zero
  if FMidi.Timing = 0 then
    raise EM2mException.CreateCode(M2M_ERROR_CONVERT);
  if FMidi.SmpteFps <> 0 then
    FSamplesPerClock := SamplesPerClockSmpte(Cardinal(FMidi.SmpteFps), Cardinal(FMidi.Timing))
  else
    FSamplesPerClock := SamplesPerClockNormal(Cardinal(FMidi.Timing), DEFAULT_TEMPO);

  LTrack := FMidi.Tracks[0];
  LError := 0.0;
  LEventNumber := 0;

  while not FFoundEnd and (LEventNumber < Length(LTrack.Events)) do
  begin
    LEvent := LTrack.Events[LEventNumber];

    // How many MUS clocks away the event is, and how many of them are going to go by now
    LEventDelta := LEvent.Delta * FSamplesPerClock;
    // The sum is a double before it is cut, as in the C code
    LSum := LEventDelta + LError;
    if LSum >= UNSIGNED_LIMIT then
      raise EM2mException.CreateCode(M2M_ERROR_CONVERT);
    LClocks := Cardinal(Trunc(LSum));
    if LClocks <> 0 then
    begin
      FTrack.WriteDelay(LClocks);
      LError := LError - LClocks;
    end;

    // The channel gets its number the first time that it is used
    if FChannelMap[LEvent.Channel] = UNUSED then
    begin
      FChannelMap[LEvent.Channel] := FNextChannel;
      LUnusedChannel := FNextChannel;
      Inc(FNextChannel);
    end
    else
      LUnusedChannel := UNUSED;
    LOutChannel := FChannelMap[LEvent.Channel];

    Translate(LEvent, LOutChannel, LData, LLength);

    if LLength > 0 then
      FTrack.WriteEvent(LData, LLength)
    else if (LUnusedChannel <> UNUSED) and (LEvent.Channel <> PERCUSSION_MIDI_CHANNEL) then
    begin
      // The event was dropped: the number of the channel is given back
      FChannelMap[LEvent.Channel] := UNUSED;
      Dec(FNextChannel);
    end;

    LError := LError + LEventDelta;
    Inc(LEventNumber);
  end;

  // The song ran out of events without an end of track
  if not FFoundEnd then
    raise EM2mException.CreateCode(M2M_ERROR_CONVERT);

  FPatches.Sort;
  LScore := FTrack.ToBytes;

  // The channels that sounded a note, not counting the percussion
  LPrimary := 0;
  for LIndex := 0 to PRIMARY_CHANNELS - 1 do
  begin
    if FVelocityCache[LIndex] <> 0 then
      Inc(LPrimary);
  end;

  SetLength(Result, HEADER_LENGTH + FPatches.Count * 2 + Length(LScore));
  LOffset := 0;
  for LIndex := 0 to High(MUS_SIGNATURE) do
  begin
    Result[LOffset] := MUS_SIGNATURE[LIndex];
    Inc(LOffset);
  end;
  PutWord(Length(LScore));
  PutWord(FPatches.Count * 2 + HEADER_LENGTH);
  PutWord(LPrimary);
  PutWord(0);
  PutWord(FPatches.Count);
  PutWord(0);
  for LIndex := 0 to FPatches.Count - 1 do
    PutWord(FPatches[LIndex]);
  if Length(LScore) > 0 then
    Move(LScore[0], Result[LOffset], Length(LScore));
end;

end.
