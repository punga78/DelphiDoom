{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - a music made of a Standard MIDI file (the   }
{  MIDI music of GM.CAT and the .mid files of a mod)                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.MidiTrack;

interface

uses
  System.SysUtils, DelphiDoom.Midi.Types, DelphiDoom.XcomAudio.Intf;

type
  /// <summary>
  ///   A MIDI music. The file is read by the loader of Libs\Midi (reader and merger of the tracks of Libs\M2m); the
  ///   events go to the synthesizer at their time, counted in samples of the mixer
  /// </summary>
  TXcomMidiTrack = class(TInterfacedObject, IXcomMusicTrack, IXcomMusicPreparation)
  strict private
    const
      DEFAULT_TEMPO = 500000;
      // a pause after the last event so that the last notes can die away
      TAIL_SECONDS = 1;
    var
      FMidi: TBytes;
      FRate: Integer;
      FSynth: IXcomMidiSynth;
      FEvents: TArray<TMidiSequenceEvent>;
      FDivision: Word;
      FPrepared: Boolean;
      FNext: Integer;
      FTickPosition: Double;
      FTempo: Cardinal;
      FTailFrames: Integer;
      FRemaining: Integer;
      FLoopForever: Boolean;
      FActive: Boolean;
    function TicksPerFrame: Double;
    procedure Rewind;
    procedure Apply(const AEvent: TMidiSequenceEvent);
  public
    /// <param name="AMidi">The bytes of the MIDI file</param>
    /// <param name="ARate">The rate of the mixer</param>
    /// <param name="ASynth">Plays the notes; EArgumentNilException when nil</param>
    constructor Create(const AMidi: TBytes; ARate: Integer; const ASynth: IXcomMidiSynth);
    /// <summary>True when the bytes start like a MIDI file (SDL_mixer detects it by "MThd")</summary>
    class function Accepts(const AData: TBytes): Boolean; static;
    function Format: string;
    /// <summary>Reads the file; a file that cannot be read is a silent track</summary>
    procedure Prepare;
    procedure Start(ALoop: Integer);
    procedure Stop;
    function IsPlaying: Boolean;
    procedure Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
  end;

implementation

uses
  System.Math, DelphiDoom.Midi.SequenceLoader, DelphiDoom.XcomAudio.Types;

constructor TXcomMidiTrack.Create(const AMidi: TBytes; ARate: Integer; const ASynth: IXcomMidiSynth);
begin
  inherited Create;
  if not Assigned(ASynth) then
    raise EArgumentNilException.Create('ASynth');
  FMidi := AMidi;
  FRate := ARate;
  FSynth := ASynth;
end;

class function TXcomMidiTrack.Accepts(const AData: TBytes): Boolean;
begin
  Result := (Length(AData) >= 14) and (AData[0] = $4D) and (AData[1] = $54) and (AData[2] = $68) and
    (AData[3] = $64);
end;

function TXcomMidiTrack.Format: string;
begin
  Result := 'MIDI';
end;

procedure TXcomMidiTrack.Prepare;
begin
  if FPrepared then
    Exit;
  FPrepared := True;
  if (Length(FMidi) = 0) or
    not TMidiSequenceLoader.TryLoad(@FMidi[0], Length(FMidi), nil, FEvents, FDivision) then
    FEvents := nil;
end;

function TXcomMidiTrack.TicksPerFrame: Double;
var
  LTicksPerSecond: Double;
begin
  if (FDivision and $8000) <> 0 then
    // SMPTE: frames per second (negative, in the high byte) times ticks per frame
    LTicksPerSecond := (256 - (FDivision shr 8)) * (FDivision and $FF)
  else if FDivision = 0 then
    LTicksPerSecond := 96 * 1000000 / FTempo
  else
    LTicksPerSecond := FDivision * 1000000 / FTempo;
  Result := LTicksPerSecond / FRate;
end;

procedure TXcomMidiTrack.Rewind;
begin
  FNext := 0;
  FTickPosition := 0;
  FTempo := DEFAULT_TEMPO;
  FTailFrames := 0;
  FSynth.Reset;
end;

procedure TXcomMidiTrack.Start(ALoop: Integer);
begin
  Prepare;
  FLoopForever := ALoop < 0;
  if ALoop <= 1 then
    FRemaining := 1
  else
    FRemaining := ALoop;
  Rewind;
  FActive := Length(FEvents) > 0;
end;

procedure TXcomMidiTrack.Stop;
begin
  FActive := False;
  FSynth.Reset;
  FEvents := nil;
  FPrepared := False;
end;

function TXcomMidiTrack.IsPlaying: Boolean;
begin
  Result := FActive;
end;

procedure TXcomMidiTrack.Apply(const AEvent: TMidiSequenceEvent);
begin
  case AEvent.Kind of
    mskChannel:
      FSynth.Send(AEvent.Status, AEvent.Data1, AEvent.Data2);
    mskTempo:
      FTempo := AEvent.Tempo;
  end;
end;

procedure TXcomMidiTrack.Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
var
  LFrames: Integer;
  LChunk: Integer;
  LToEvent: Double;
  LIndex: Integer;
  LStart: PSmallInt;
  LSum: Integer;
  LTemp: TArray<SmallInt>;
begin
  if (ABytes <= 0) or ((ABytes and 3) <> 0) then
    raise EXcomAudioException.Create(SXcomBufferNotWhole);
  if not FActive then
    Exit;
  LFrames := ABytes div 4;
  SetLength(LTemp, LFrames * 2);
  LStart := ABuffer;
  FillChar(LTemp[0], ABytes, 0);
  LIndex := 0;
  while FActive and (LFrames > 0) do
  begin
    // the events that are due
    while (FNext < Length(FEvents)) and (FEvents[FNext].Time <= FTickPosition) do
    begin
      Apply(FEvents[FNext]);
      Inc(FNext);
    end;
    if FNext >= Length(FEvents) then
    begin
      // after the last event: the tail, then the end or the next turn
      if FTailFrames = 0 then
        FTailFrames := TAIL_SECONDS * FRate;
      LChunk := Min(LFrames, FTailFrames);
      FSynth.Render(@LTemp[LIndex * 2], LChunk * 4);
      Inc(LIndex, LChunk);
      Dec(LFrames, LChunk);
      Dec(FTailFrames, LChunk);
      if FTailFrames <= 0 then
      begin
        if FRemaining > 0 then
          Dec(FRemaining);
        if (not FLoopForever) and (FRemaining = 0) then
          FActive := False
        else
          Rewind;
      end;
      Continue;
    end;
    LToEvent := (FEvents[FNext].Time - FTickPosition) / TicksPerFrame;
    LChunk := Min(LFrames, Max(1, Ceil(LToEvent)));
    FSynth.Render(@LTemp[LIndex * 2], LChunk * 4);
    FTickPosition := FTickPosition + LChunk * TicksPerFrame;
    Inc(LIndex, LChunk);
    Dec(LFrames, LChunk);
  end;
  for LIndex := 0 to ABytes div 2 - 1 do
  begin
    LSum := Integer(LStart^) + Trunc(LTemp[LIndex] * AVolume);
    LStart^ := SmallInt(EnsureRange(LSum, -32768, 32767));
    Inc(LStart);
  end;
end;

end.
