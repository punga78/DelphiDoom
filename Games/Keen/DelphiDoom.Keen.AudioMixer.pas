{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the timer interrupt of the sound manager as a     }
{  stream of samples                                                            }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  what SDL_t0Service of id_sd.c does for the sound effects, 140 times a second }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.AudioMixer;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   Makes the sound of the game. The timer 0 of the original calls the service of the sound manager 140 times a
  ///   second, and between two calls the devices play what the service programmed: here the stream of samples is
  ///   cut in pieces of 1/140 of a second, the service runs at the start of each piece and the devices give the
  ///   samples of the piece. The time of the sound is the number of samples, not the clock of the machine
  /// </summary>
  TKeenAudioMixer = class(TInterfacedObject, IKeenAudioMixer)
  strict private
    FSound: IKeenSoundManager;
    FSources: TArray<IKeenSampleSource>;
    FLock: IKeenAudioLock;
    FRate: Integer;
    FMix: TArray<Integer>;
    FFramesToService: Integer;
    FAccumulator: Integer;
    FStatistics: TKeenAudioStatistics;
  public
    /// <param name="ASound">The manager whose Service is the timer interrupt</param>
    /// <param name="ASources">The devices that the manager programs</param>
    /// <param name="ALock">Held while a block is rendered; the game holds it while it talks to the manager</param>
    /// <param name="ARate">Samples per second of the output</param>
    constructor Create(const ASound: IKeenSoundManager; const ASources: array of IKeenSampleSource;
      const ALock: IKeenAudioLock; ARate: Integer);
    function GetRate: Integer;
    procedure Render(ABuffer: PByte; AByteCount: Integer);
    function Statistics: TKeenAudioStatistics;
  end;

implementation

uses
  DelphiDoom.Keen.PcSpeaker;

{ TKeenAudioMixer }

constructor TKeenAudioMixer.Create(const ASound: IKeenSoundManager; const ASources: array of IKeenSampleSource;
  const ALock: IKeenAudioLock; ARate: Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(ASound) then
    raise EArgumentNilException.Create('ASound');
  if not Assigned(ALock) then
    raise EArgumentNilException.Create('ALock');
  if ARate < KEEN_PC_SERVICE_RATE then
    raise EArgumentOutOfRangeException.Create('ARate');
  FSound := ASound;
  FLock := ALock;
  FRate := ARate;
  SetLength(FSources, Length(ASources));
  for LIndex := 0 to High(ASources) do
  begin
    if not Assigned(ASources[LIndex]) then
      raise EArgumentNilException.Create('ASources');
    FSources[LIndex] := ASources[LIndex];
  end;
end;

function TKeenAudioMixer.GetRate: Integer;
begin
  Result := FRate;
end;

function TKeenAudioMixer.Statistics: TKeenAudioStatistics;
begin
  FLock.Enter;
  try
    Result := FStatistics;
  finally
    FLock.Leave;
  end;
end;

procedure TKeenAudioMixer.Render(ABuffer: PByte; AByteCount: Integer);
var
  LFrames: Integer;
  LChunk: Integer;
  LIndex: Integer;
  LSource: IKeenSampleSource;
  LSample: Integer;
  LOut: PSmallInt;
begin
  LFrames := AByteCount div 4;
  LOut := PSmallInt(ABuffer);
  FLock.Enter;
  try
    while LFrames > 0 do
    begin
      if FFramesToService <= 0 then
      begin
        FSound.Service;
        Inc(FStatistics.Services);
        // the samples of 1/140 of a second; what the division leaves goes to the next piece
        Inc(FAccumulator, FRate);
        FFramesToService := FAccumulator div KEEN_PC_SERVICE_RATE;
        FAccumulator := FAccumulator mod KEEN_PC_SERVICE_RATE;
      end;
      LChunk := FFramesToService;
      if LChunk > LFrames then
        LChunk := LFrames;
      if Length(FMix) < LChunk then
        SetLength(FMix, LChunk);
      for LIndex := 0 to LChunk - 1 do
        FMix[LIndex] := 0;
      for LSource in FSources do
        LSource.AddSamples(FMix, LChunk);
      for LIndex := 0 to LChunk - 1 do
      begin
        LSample := FMix[LIndex];
        if LSample > 32767 then
          LSample := 32767
        else if LSample < -32768 then
          LSample := -32768;
        if LSample <> 0 then
        begin
          Inc(FStatistics.AudibleFrames);
          if Abs(LSample) > FStatistics.Peak then
            FStatistics.Peak := Abs(LSample);
        end;
        LOut^ := SmallInt(LSample);
        Inc(LOut);
        LOut^ := SmallInt(LSample);
        Inc(LOut);
      end;
      Inc(FStatistics.Frames, LChunk);
      Dec(FFramesToService, LChunk);
      Dec(LFrames, LChunk);
    end;
  finally
    FLock.Leave;
  end;
end;

end.
