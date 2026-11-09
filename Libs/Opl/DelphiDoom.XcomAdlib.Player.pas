{******************************************************************************}
{                                                                              }
{  DelphiDoom: X-COM Adlib player - the player (AdlibMusic)                     }
{                                                                              }
{  Port of AdlibMusic.cpp (OpenXcom, GPL v3 or later): see Libs\Opl\README.md   }
{  for the license. The song plays on two chips, the left and the right         }
{  channel; the caller asks for the samples (no audio device is opened here)    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAdlib.Player;

interface

uses
  System.SysUtils, DelphiDoom.Opl.Intf, DelphiDoom.XcomAdlib.Types, DelphiDoom.XcomAdlib.Intf;

type
  TXcomAdlibPlayer = class(TInterfacedObject, IXcomAdlibPlayer)
  strict private
    FLeft: IOplChip;
    FRight: IOplChip;
    FSequencer: IXcomAdlibSequencer;
    FSong: TBytes;
    /// <summary>delay: the bytes of sound that are left before the next tick of the sequencer</summary>
    FDelay: Integer;
    /// <summary>delayRates[rate]: the bytes between two ticks at the sampling rate of the chips</summary>
    FTickBytes: Integer;
    class function TickBytesOf(ARate: Integer): Integer; static;
  public
    /// <param name="ALeft">The chip of the left channel</param>
    /// <param name="ARight">The chip of the right channel</param>
    /// <param name="ASequencer">The sequencer that writes to the two chips</param>
    /// <param name="ARate">
    ///   The sampling rate of the chips; one of 8000, 11025, 16000, 22050, 32000, 44100 and 48000 (the C gives an
    ///   endless loop for any other)
    /// </param>
    constructor Create(const ALeft, ARight: IOplChip; const ASequencer: IXcomAdlibSequencer; ARate: Integer);
    procedure Load(const ASong: TBytes);
    procedure Play(AVolume: Single);
    procedure Stop;
    procedure Fade;
    function IsPlaying: Boolean;
    procedure SetTempo(AValue: Integer);
    procedure SetVolume(AValue: Integer);
    function Polyphony: Integer;
    procedure SaveState(AIndex: Integer);
    procedure LoadState(AIndex: Integer);
    function PendingBytes: Integer;
    procedure Render(const ABuffer: TArray<SmallInt>; ABytes: Integer; AVolume: Single);
  end;

implementation

{ TXcomAdlibPlayer }

constructor TXcomAdlibPlayer.Create(const ALeft, ARight: IOplChip; const ASequencer: IXcomAdlibSequencer;
  ARate: Integer);
begin
  inherited Create;
  if not Assigned(ALeft) or not Assigned(ARight) or not Assigned(ASequencer) then
    raise EXcomAdlibException.Create('The player needs two chips and a sequencer');
  FLeft := ALeft;
  FRight := ARight;
  FSequencer := ASequencer;
  FTickBytes := TickBytesOf(ARate);
end;

class function TXcomAdlibPlayer.TickBytesOf(ARate: Integer): Integer;
begin
  // magic value - length of 1 tick per samplerate
  case ARate of
    8000: Result := 114 * 4;
    11025: Result := 157 * 4;
    16000: Result := 228 * 4;
    22050: Result := 314 * 4;
    32000: Result := 456 * 4;
    44100: Result := 629 * 4;
    48000: Result := 685 * 4;
  else
    raise EXcomAdlibException.CreateFmt('The sampling rate %d has no tick length (use 8000, 11025, 16000, 22050, ' +
      '32000, 44100 or 48000)', [ARate]);
  end;
end;

procedure TXcomAdlibPlayer.Load(const ASong: TBytes);
begin
  if Length(ASong) = 0 then
    raise EXcomAdlibException.Create('The song is empty');
  FSong := Copy(ASong);
end;

procedure TXcomAdlibPlayer.Play(AVolume: Single);
var
  LLength: Integer;
  LScaled: Single;
begin
  if Length(FSong) = 0 then
    raise EXcomAdlibException.Create('No song is loaded');
  // AdlibMusic::load: a song with a name (the first byte is at most 56) counts the name twice
  LLength := Length(FSong);
  if FSong[0] <= 56 then
    Inc(LLength, FSong[0]);
  FSequencer.Setup(FSong, LLength);
  LScaled := 127;
  LScaled := LScaled * AVolume;
  FSequencer.SetVolume(Trunc(LScaled));
end;

procedure TXcomAdlibPlayer.Stop;
begin
  FSequencer.Mute;
end;

procedure TXcomAdlibPlayer.Fade;
begin
  FSequencer.Fade;
end;

function TXcomAdlibPlayer.IsPlaying: Boolean;
begin
  Result := FSequencer.IsPlaying;
end;

procedure TXcomAdlibPlayer.SetTempo(AValue: Integer);
begin
  FSequencer.SetTempo(AValue);
end;

procedure TXcomAdlibPlayer.SetVolume(AValue: Integer);
begin
  FSequencer.SetVolume(AValue);
end;

function TXcomAdlibPlayer.Polyphony: Integer;
begin
  Result := FSequencer.Polyphony;
end;

procedure TXcomAdlibPlayer.SaveState(AIndex: Integer);
begin
  FSequencer.SaveState(AIndex);
end;

procedure TXcomAdlibPlayer.LoadState(AIndex: Integer);
begin
  FSequencer.LoadState(AIndex);
end;

function TXcomAdlibPlayer.PendingBytes: Integer;
begin
  Result := FDelay;
end;

procedure TXcomAdlibPlayer.Render(const ABuffer: TArray<SmallInt>; ABytes: Integer; AVolume: Single);
var
  LLeft: Integer;
  LStep: Integer;
  LPosition: Integer;
begin
  // AdlibMusic::player: the bytes are 16 bit samples, left and right
  if (ABytes < 0) or ((ABytes and 3) <> 0) or (ABytes > Length(ABuffer) * 2) then
    raise EXcomAdlibException.CreateFmt('Cannot render %d bytes into %d samples: a whole number of stereo samples ' +
      'is needed', [ABytes, Length(ABuffer)]);
  LLeft := ABytes;
  LPosition := 0;
  while LLeft <> 0 do
  begin
    LStep := FDelay;
    if LLeft < LStep then
      LStep := LLeft;
    if LStep <> 0 then
    begin
      FLeft.GenerateSamples(ABuffer, LPosition, LStep div 2, 2, AVolume);
      FRight.GenerateSamples(ABuffer, LPosition + 1, LStep div 2, 2, AVolume);
      Inc(LPosition, LStep div 2);
      Dec(FDelay, LStep);
      Dec(LLeft, LStep);
    end;
    if LLeft = 0 then
      Exit;
    FSequencer.Tick;
    FDelay := FTickBytes;
  end;
end;

end.
