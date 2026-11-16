{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the sound manager                                 }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  SD_PlaySound, SD_StopSound, SD_SoundPlaying, SD_WaitSoundDone,               }
{  SD_SetSoundMode and SD_Default of id_sd.c for the PC speaker and the AdLib   }
{  card (the digitized sounds are not here)                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.SoundManager;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.PcSpeaker,
  DelphiDoom.Keen.AdLibSound, DelphiDoom.Keen.AdLibPlayer;

type
  /// <summary>
  ///   Which sound is playing and with which priority: a new sound plays only if its priority is not lower than the one
  ///   of the sound that is playing. The 28 sounds of the PC speaker are the first chunks of the audio file, the 28 of
  ///   the AdLib card the ones after them; the mode says which of the two devices plays
  /// </summary>
  TKeenSoundManager = class(TInterfacedObject, IKeenSoundManager)
  strict private
    FSounds: array[0..KEEN_NUMSOUNDS - 1] of TKeenPcSound;
    FCached: array[0..KEEN_NUMSOUNDS - 1] of Boolean;
    FAdLibSounds: array[0..KEEN_NUMSOUNDS - 1] of TKeenAdLibSound;
    FAdLibCached: array[0..KEEN_NUMSOUNDS - 1] of Boolean;
    FMode: TKeenSoundMode;
    FSpeaker: TKeenPcSpeaker;
    FSpeakerPort: IKeenSpeaker;
    FAdLib: TKeenAdLibPlayer;
    FNumber: Integer;
    FPriority: Integer;
    procedure SoundFinished;
    procedure ShutDevice;
    procedure StartDevice;
  public
    /// <param name="AChunks">The audio file: the sounds of the PC speaker are its first KEEN_NUMSOUNDS chunks (a sparse chunk is a sound that is not cached)</param>
    /// <param name="ASpeaker">What the PC speaker is; the manager does not play with the mode off</param>
    constructor Create(const AChunks: IKeenChunkSource; const ASpeaker: IKeenSpeaker); overload;
    /// <param name="AAdLib">The AdLib card; nil when there is none (AdLibPresent is false and its mode is refused)</param>
    constructor Create(const AChunks: IKeenChunkSource; const ASpeaker: IKeenSpeaker;
      const AAdLib: IKeenAdLibPort); overload;
    destructor Destroy; override;
    function GetMode: TKeenSoundMode;
    procedure SetMode(AMode: TKeenSoundMode);
    procedure PlaySound(ASound: Integer);
    procedure StopSound;
    function SoundPlaying: Integer;
    procedure Service;
    procedure WaitSoundDone;
    function AdLibPresent: Boolean;
    function TrySetMode(AMode: TKeenSoundMode): Boolean;
    procedure SetDefault(AGotIt: Boolean; AMode: TKeenSoundMode);
  end;

implementation

{ TKeenSoundManager }

constructor TKeenSoundManager.Create(const AChunks: IKeenChunkSource; const ASpeaker: IKeenSpeaker);
begin
  Create(AChunks, ASpeaker, nil);
end;

constructor TKeenSoundManager.Create(const AChunks: IKeenChunkSource; const ASpeaker: IKeenSpeaker;
  const AAdLib: IKeenAdLibPort);
var
  LSound: Integer;
  LBytes: TBytes;
begin
  inherited Create;
  if not Assigned(AChunks) then
    raise EArgumentNilException.Create('AChunks');
  FSpeaker := TKeenPcSpeaker.Create(ASpeaker);
  FSpeakerPort := ASpeaker;
  FSpeaker.OnFinished := SoundFinished;
  if Assigned(AAdLib) then
  begin
    FAdLib := TKeenAdLibPlayer.Create(AAdLib);
    FAdLib.OnFinished := SoundFinished;
  end;
  for LSound := 0 to KEEN_NUMSOUNDS - 1 do
  begin
    if (KEEN_STARTPCSOUNDS + LSound < AChunks.ChunkCount) and AChunks.HasChunk(KEEN_STARTPCSOUNDS + LSound) then
    begin
      LBytes := AChunks.Read(KEEN_STARTPCSOUNDS + LSound);
      if System.Length(LBytes) >= SizeOf(TKeenSoundCommon) then
      begin
        FSounds[LSound] := TKeenPcSoundReader.Parse(LBytes);
        FCached[LSound] := True;
      end;
    end;
    if Assigned(FAdLib) and (KEEN_STARTADLIBSOUNDS + LSound < AChunks.ChunkCount) and
      AChunks.HasChunk(KEEN_STARTADLIBSOUNDS + LSound) then
    begin
      LBytes := AChunks.Read(KEEN_STARTADLIBSOUNDS + LSound);
      if System.Length(LBytes) >= SizeOf(TKeenSoundCommon) then
      begin
        FAdLibSounds[LSound] := TKeenAdLibSoundReader.Parse(LBytes);
        FAdLibCached[LSound] := True;
      end;
    end;
  end;
  // SD_Startup leaves the mode off until SD_Default; the manager starts with the PC speaker, the device that is
  // always there, and the composition calls SetDefault
  FMode := ksmPC;
end;

destructor TKeenSoundManager.Destroy;
begin
  FAdLib.Free;
  FSpeaker.Free;
  inherited Destroy;
end;

function TKeenSoundManager.GetMode: TKeenSoundMode;
begin
  Result := FMode;
end;

function TKeenSoundManager.AdLibPresent: Boolean;
begin
  Result := Assigned(FAdLib);
end;

procedure TKeenSoundManager.ShutDevice;
begin
  case FMode of
    ksmPC:
      FSpeakerPort.Silence; // SDL_ShutPC: the speaker and its gate are turned off
    ksmAdLib:
      FAdLib.Shut;
  end;
  FMode := ksmOff;
end;

procedure TKeenSoundManager.StartDevice;
begin
  if FMode = ksmAdLib then
    FAdLib.Start;
  FNumber := 0;
  FPriority := 0;
end;

function TKeenSoundManager.TrySetMode(AMode: TKeenSoundMode): Boolean;
begin
  StopSound;
  // the C leaves the result without a value for a card that is not there: it is taken as "no"
  Result := (AMode <> ksmAdLib) or Assigned(FAdLib);
  if Result and (AMode <> FMode) then
  begin
    ShutDevice;
    FMode := AMode;
    StartDevice;
  end;
end;

procedure TKeenSoundManager.SetMode(AMode: TKeenSoundMode);
begin
  // the mode that is already set does not stop the sound (as before the AdLib was added)
  if AMode <> FMode then
    TrySetMode(AMode);
end;

procedure TKeenSoundManager.SetDefault(AGotIt: Boolean; AMode: TKeenSoundMode);
var
  LGot: Boolean;
  LMode: TKeenSoundMode;
begin
  LGot := AGotIt;
  LMode := AMode;
  if LGot and (LMode = ksmAdLib) then
    LGot := Assigned(FAdLib);
  if not LGot then
  begin
    if Assigned(FAdLib) then
      LMode := ksmAdLib
    else
      LMode := ksmPC;
  end;
  if LMode <> FMode then
    TrySetMode(LMode);
end;

procedure TKeenSoundManager.SoundFinished;
begin
  FNumber := 0;
  FPriority := 0;
end;

procedure TKeenSoundManager.PlaySound(ASound: Integer);
var
  LPriority: Integer;
begin
  if FMode = ksmOff then
    Exit;
  if (ASound < 0) or (ASound >= KEEN_NUMSOUNDS) then
    raise EKeenException.CreateFmt(SKeenSoundNotCached, [ASound]);
  if FMode = ksmAdLib then
  begin
    if not FAdLibCached[ASound] then
      raise EKeenException.CreateFmt(SKeenSoundNotCached, [ASound]);
    LPriority := FAdLibSounds[ASound].Priority;
  end
  else
  begin
    if not FCached[ASound] then
      raise EKeenException.CreateFmt(SKeenSoundNotCached, [ASound]);
    LPriority := FSounds[ASound].Priority;
  end;
  if LPriority < FPriority then
    Exit;
  if FMode = ksmAdLib then
    FAdLib.Play(FAdLibSounds[ASound])
  else
    FSpeaker.Play(FSounds[ASound]);
  FNumber := ASound;
  FPriority := LPriority;
end;

procedure TKeenSoundManager.StopSound;
begin
  case FMode of
    ksmPC:
      FSpeaker.Stop;
    ksmAdLib:
      FAdLib.Stop;
  end;
  SoundFinished;
end;

function TKeenSoundManager.SoundPlaying: Integer;
begin
  Result := 0;
  if ((FMode = ksmPC) and FSpeaker.Playing) or ((FMode = ksmAdLib) and FAdLib.Playing) then
    Result := FNumber;
end;

procedure TKeenSoundManager.Service;
begin
  case FMode of
    ksmPC:
      FSpeaker.Service;
    ksmAdLib:
      FAdLib.Service;
  end;
end;

procedure TKeenSoundManager.WaitSoundDone;
begin
  // the C spins until the timer interrupt ends the sound: here the interrupt is the loop
  while SoundPlaying <> 0 do
    Service;
end;

end.
