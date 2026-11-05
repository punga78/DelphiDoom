{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI to MUS - reads a Standard MIDI file                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from m2m by Colin Phipps (BSD licence)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.M2m.MidiReader;

interface

uses
  DelphiDoom.M2m.MidiFile,
  DelphiDoom.M2m.Types;

type
  /// <summary>
  ///   Reads the header and the tracks of a Standard MIDI file from memory
  /// </summary>
  /// <remarks>
  ///   It is as strict as the C reader it replaces: a track that ends before
  ///   its length, or an unknown event, is an error. A track that has more
  ///   bytes after its end of track event is read as far as that event, and
  ///   the next track is looked for right after it
  /// </remarks>
  TMidiReader = class
  private
    FData: PByte;
    FSize: Integer;
    FPosition: Integer;
    function ReadByte: Byte;
    function ReadWord: Word;
    function ReadCardinal: Cardinal;
    function ReadVariableLength(var ABytes: Cardinal): Cardinal;
    procedure UnreadByte;
    procedure ReadSignature(const ASignature: AnsiString);
    function ReadEvent(var ABytes: Cardinal; const APreviousType: TMidiEventType;
      const APreviousChannel: Integer): TMidiEvent;
    function ReadTrack: TMidiTrack;
    function ReadFile: TMidiFile;
  public
    /// <param name="AData">The bytes of the file; they must stay alive while the reader works</param>
    /// <param name="ASize">Their number</param>
    constructor Create(const AData: Pointer; const ASize: Integer);

    /// <summary>Reads the whole file</summary>
    /// <exception cref="EM2mException">the file is not readable</exception>
    class function Parse(const AData: Pointer; const ASize: Integer): TMidiFile; static;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.M2m.Intf;

const
  HEADER_LENGTH = 6;
  HIGHEST_MODE = 2;
  TIMING_SMPTE = $8000;
  CONTINUATION_BIT = $80;
  VARIABLE_LENGTH_BYTES = 4;
  EVENTS_GROWTH = 100;
  STATUS_META = $FF;
  STATUS_SYSEX = $F0;
  STATUS_SYSEX_CONTINUATION = $F7;

{ TMidiReader }

constructor TMidiReader.Create(const AData: Pointer; const ASize: Integer);
begin
  inherited Create;
  FData := AData;
  FSize := ASize;
end;

class function TMidiReader.Parse(const AData: Pointer; const ASize: Integer): TMidiFile;
var
  LReader: TMidiReader;
begin
  LReader := TMidiReader.Create(AData, ASize);
  try
    Result := LReader.ReadFile;
  finally
    LReader.Free;
  end;
end;

function TMidiReader.ReadByte: Byte;
begin
  if FPosition >= FSize then
    raise EM2mException.CreateCode(M2M_ERROR_MIDI);
  Result := FData[FPosition];
  Inc(FPosition);
end;

procedure TMidiReader.UnreadByte;
begin
  if FPosition = 0 then
    raise EM2mException.CreateCode(M2M_ERROR_MIDI);
  Dec(FPosition);
end;

function TMidiReader.ReadWord: Word;
var
  LHigh, LLow: Byte;
begin
  LHigh := ReadByte;
  LLow := ReadByte;
  Result := Word(LHigh shl 8) or LLow;
end;

function TMidiReader.ReadCardinal: Cardinal;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 1 to 4 do
    Result := (Result shl 8) + ReadByte;
end;

function TMidiReader.ReadVariableLength(var ABytes: Cardinal): Cardinal;
var
  LIndex: Integer;
  LByte: Byte;
begin
  Result := 0;
  for LIndex := 1 to VARIABLE_LENGTH_BYTES do
  begin
    LByte := ReadByte;
    Inc(ABytes);
    Result := (Result shl 7) + Cardinal(LByte and $7F);
    if (LByte and CONTINUATION_BIT) = 0 then
      Exit;
  end;
  // Four bytes and still one more to come
  raise EM2mException.CreateCode(M2M_ERROR_MIDI);
end;

procedure TMidiReader.ReadSignature(const ASignature: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(ASignature) do
  begin
    if ReadByte <> Ord(ASignature[LIndex]) then
      raise EM2mException.CreateCode(M2M_ERROR_MIDI);
  end;
end;

function TMidiReader.ReadEvent(var ABytes: Cardinal; const APreviousType: TMidiEventType;
  const APreviousChannel: Integer): TMidiEvent;
var
  LStatus: Byte;
  LLength: Cardinal;
begin
  Result := Default(TMidiEvent);
  Result.Delta := ReadVariableLength(ABytes);

  LStatus := ReadByte;
  Inc(ABytes);
  if (LStatus and CONTINUATION_BIT) = 0 then
  begin
    // Running status: the event is of the kind of the one before
    UnreadByte;
    Dec(ABytes);
    Result.EventType := APreviousType;
    Result.Channel := APreviousChannel;
  end
  else
  begin
    Result.Channel := LStatus and $0F;
    case LStatus and $F0 of
      $80: Result.EventType := metNoteOff;
      $90: Result.EventType := metNoteOn;
      $A0: Result.EventType := metNoteAftertouch;
      $B0: Result.EventType := metController;
      $C0: Result.EventType := metProgramChange;
      $D0: Result.EventType := metChannelAftertouch;
      $E0: Result.EventType := metPitchBend;
      $F0:
        case LStatus of
          STATUS_META: Result.EventType := metMeta;
          STATUS_SYSEX: Result.EventType := metSysEx;
          STATUS_SYSEX_CONTINUATION: Result.EventType := metSysExContinuation;
        else
          raise EM2mException.CreateCode(M2M_ERROR_MIDI);
        end;
    end;
  end;

  case Result.EventType of
    metNoteOff, metNoteOn, metNoteAftertouch, metController, metPitchBend:
      begin
        Result.Param1 := ReadByte and $7F;
        Inc(ABytes);
        Result.Param2 := ReadByte and $7F;
        Inc(ABytes);
      end;
    metProgramChange, metChannelAftertouch:
      begin
        Result.Param1 := ReadByte and $7F;
        Inc(ABytes);
      end;
    metMeta, metSysEx, metSysExContinuation:
      begin
        if Result.EventType = metMeta then
        begin
          Result.Param1 := ReadByte;
          Inc(ABytes);
        end;
        LLength := ReadVariableLength(ABytes);
        // A length of zero is legal, at least for a meta event
        if LLength > 0 then
        begin
          if LLength > Cardinal(FSize - FPosition) then
            raise EM2mException.CreateCode(M2M_ERROR_MIDI);
          SetLength(Result.Data, LLength);
          Move(FData[FPosition], Result.Data[0], LLength);
          Inc(FPosition, Integer(LLength));
          Inc(ABytes, LLength);
        end;
      end;
  else
    raise EM2mException.CreateCode(M2M_ERROR_MIDI);
  end;
end;

function TMidiReader.ReadTrack: TMidiTrack;
var
  LTotalBytes, LReadBytes: Cardinal;
  LCount: Integer;
  LPreviousType: TMidiEventType;
  LPreviousChannel: Integer;
  LEvent: TMidiEvent;
begin
  Result := Default(TMidiTrack);
  ReadSignature('MTrk');
  LTotalBytes := ReadCardinal;
  LReadBytes := 0;
  LCount := 0;
  LPreviousType := metNone;
  LPreviousChannel := 0;

  while LReadBytes < LTotalBytes do
  begin
    LEvent := ReadEvent(LReadBytes, LPreviousType, LPreviousChannel);
    LPreviousType := LEvent.EventType;
    LPreviousChannel := LEvent.Channel;

    if LCount = Length(Result.Events) then
      SetLength(Result.Events, LCount + EVENTS_GROWTH);
    Result.Events[LCount] := LEvent;
    Inc(LCount);

    if (LEvent.EventType = metMeta) and (LEvent.Param1 = META_ENDTRACK) then
    begin
      SetLength(Result.Events, LCount);
      Exit;
    end;
  end;

  // The track is as long as it said and has no end of track event
  raise EM2mException.CreateCode(M2M_ERROR_MIDI);
end;

function TMidiReader.ReadFile: TMidiFile;
var
  LValue: Word;
  LIndex: Integer;
begin
  ReadSignature('MThd');
  if ReadCardinal <> HEADER_LENGTH then
    raise EM2mException.CreateCode(M2M_ERROR_MIDI);

  Result := TMidiFile.Create;
  try
    LValue := ReadWord;
    if LValue > HIGHEST_MODE then
      raise EM2mException.CreateCode(M2M_ERROR_MIDI);
    Result.Mode := LValue;

    LValue := ReadWord;
    if LValue = 0 then
      raise EM2mException.CreateCode(M2M_ERROR_MIDI);
    SetLength(Result.Tracks, LValue);

    LValue := ReadWord;
    if (LValue and TIMING_SMPTE) <> 0 then
    begin
      // The upper byte is the frames per second, as a negative number
      Result.SmpteFps := -ShortInt(LValue shr 8);
      Result.Timing := LValue and $FF;
    end
    else
    begin
      Result.SmpteFps := 0;
      Result.Timing := LValue;
    end;

    for LIndex := 0 to High(Result.Tracks) do
      Result.Tracks[LIndex] := ReadTrack;
  except
    Result.Free;
    raise;
  end;
end;

end.
