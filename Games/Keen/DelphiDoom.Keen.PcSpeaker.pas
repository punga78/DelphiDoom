{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the PC speaker                                    }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  SDL_PCPlaySound, SDL_PCStopSound and SDL_PCService of id_sd.c                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.PcSpeaker;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

const
  /// <summary>Times per second that the sound service runs for the PC speaker (the timer 0 goes at 2 * TickBase)</summary>
  KEEN_PC_SERVICE_RATE = 140;
  /// <summary>pcSoundLookup[i] = i * 60: the divisor of the timer for a byte of a sound</summary>
  KEEN_PC_DIVISOR_STEP = 60;
  /// <summary>The clock of the timer of the PC (Hz): the frequency of a tone is this over its divisor</summary>
  KEEN_PC_TIMER_CLOCK = 1193181;

type
  /// <summary>
  ///   A sound for the PC speaker (PCSound): the length in service ticks, the priority and a byte for each tick: 0 is
  ///   silence, any other number is a tone whose divisor of the timer is the number times 60
  /// </summary>
  TKeenPcSound = record
    Length: Cardinal;
    Priority: Word;
    Data: TBytes;
  end;

  /// <summary>Reads the chunk of a sound of the audio file</summary>
  TKeenPcSoundReader = class
  public
    /// <summary>
    ///   The sound of a chunk: the 6 bytes of SoundCommon and the data. A chunk shorter than its length gives silence
    ///   for the ticks that it does not have (the C reads what is after the chunk)
    /// </summary>
    class function Parse(const AChunk: TBytes): TKeenPcSound; static;
    /// <summary>The frequency of a tone byte, in Hz</summary>
    class function Frequency(ATone: Byte): Double; static;
  end;

  /// <summary>
  ///   Plays a PC sound one byte at each service: a new tone programs the timer of the speaker and turns it on, a 0
  ///   turns it off, the same byte again does nothing. At the end of the sound the speaker is stopped and the manager is
  ///   told
  /// </summary>
  TKeenPcSpeaker = class
  strict private
    FSpeaker: IKeenSpeaker;
    FSound: TKeenPcSound;
    FPlaying: Boolean;
    FPosition: Integer;
    FLengthLeft: Cardinal;
    FLastSample: Byte;
    FOnFinished: TProc;
  public
    constructor Create(const ASpeaker: IKeenSpeaker);
    /// <summary>SDL_PCPlaySound</summary>
    procedure Play(const ASound: TKeenPcSound);
    /// <summary>SDL_PCStopSound</summary>
    procedure Stop;
    /// <summary>SDL_PCService: what the timer interrupt does</summary>
    procedure Service;
    property Playing: Boolean read FPlaying;
    /// <summary>SDL_SoundFinished: called when a sound ends by itself (not with Stop)</summary>
    property OnFinished: TProc read FOnFinished write FOnFinished;
  end;

implementation

{ TKeenPcSoundReader }

class function TKeenPcSoundReader.Parse(const AChunk: TBytes): TKeenPcSound;
var
  LAvailable: Integer;
begin
  if System.Length(AChunk) < SizeOf(TKeenSoundCommon) then
    raise EKeenDataException.CreateFmt(SKeenSoundChunkShort, [System.Length(AChunk)]);
  Result.Length := Cardinal(AChunk[0]) or (Cardinal(AChunk[1]) shl 8) or (Cardinal(AChunk[2]) shl 16) or
    (Cardinal(AChunk[3]) shl 24);
  Result.Priority := Word(AChunk[4]) or (Word(AChunk[5]) shl 8);
  LAvailable := System.Length(AChunk) - SizeOf(TKeenSoundCommon);
  SetLength(Result.Data, LAvailable);
  if LAvailable > 0 then
    Move(AChunk[SizeOf(TKeenSoundCommon)], Result.Data[0], LAvailable);
end;

class function TKeenPcSoundReader.Frequency(ATone: Byte): Double;
begin
  if ATone = 0 then
    Exit(0);
  Result := KEEN_PC_TIMER_CLOCK / (ATone * KEEN_PC_DIVISOR_STEP);
end;

{ TKeenPcSpeaker }

constructor TKeenPcSpeaker.Create(const ASpeaker: IKeenSpeaker);
begin
  inherited Create;
  if not Assigned(ASpeaker) then
    raise EArgumentNilException.Create('ASpeaker');
  FSpeaker := ASpeaker;
end;

procedure TKeenPcSpeaker.Play(const ASound: TKeenPcSound);
begin
  FLastSample := Byte(-1);
  FLengthLeft := ASound.Length;
  FSound := ASound;
  FPosition := 0;
  FPlaying := True;
end;

procedure TKeenPcSpeaker.Stop;
begin
  FPlaying := False;
  FSpeaker.Stop;
end;

procedure TKeenPcSpeaker.Service;
var
  LSample: Byte;
begin
  if not FPlaying then
    Exit;
  // the bytes after the end of the data are silence
  if FPosition < System.Length(FSound.Data) then
    LSample := FSound.Data[FPosition]
  else
    LSample := 0;
  Inc(FPosition);
  if LSample <> FLastSample then
  begin
    FLastSample := LSample;
    if LSample <> 0 then
      FSpeaker.Tone(Word(LSample * KEEN_PC_DIVISOR_STEP)) // we have a frequency!
    else
      FSpeaker.Silence; // time for some silence
  end;
  // a length of 0 would count down from 4 billion in the C, playing what is after the sound: here it ends at once
  if FLengthLeft > 0 then
    Dec(FLengthLeft);
  if FLengthLeft = 0 then
  begin
    Stop;
    if Assigned(FOnFinished) then
      FOnFinished();
  end;
end;

end.
