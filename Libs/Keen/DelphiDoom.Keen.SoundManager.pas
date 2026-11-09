{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the sound manager                                 }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  SD_PlaySound, SD_StopSound, SD_SoundPlaying and SD_WaitSoundDone of id_sd.c  }
{  for the PC speaker (the AdLib and the digitized sounds are not here)         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.SoundManager;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.PcSpeaker;

type
  /// <summary>
  ///   Which sound is playing and with which priority: a new sound plays only if its priority is not lower than the one
  ///   of the sound that is playing. The sounds are the 28 of the PC speaker of the audio file (the first 28 chunks)
  /// </summary>
  TKeenSoundManager = class(TInterfacedObject, IKeenSoundManager)
  strict private
    FSounds: array[0..KEEN_NUMSOUNDS - 1] of TKeenPcSound;
    FCached: array[0..KEEN_NUMSOUNDS - 1] of Boolean;
    FMode: TKeenSoundMode;
    FSpeaker: TKeenPcSpeaker;
    FNumber: Integer;
    FPriority: Integer;
    procedure SoundFinished;
  public
    /// <param name="AChunks">The audio file: the sounds of the PC speaker are its first KEEN_NUMSOUNDS chunks (a sparse chunk is a sound that is not cached)</param>
    /// <param name="ASpeaker">What the PC speaker is; the manager does not play with the mode off</param>
    constructor Create(const AChunks: IKeenChunkSource; const ASpeaker: IKeenSpeaker);
    destructor Destroy; override;
    function GetMode: TKeenSoundMode;
    procedure SetMode(AMode: TKeenSoundMode);
    procedure PlaySound(ASound: Integer);
    procedure StopSound;
    function SoundPlaying: Integer;
    procedure Service;
    procedure WaitSoundDone;
  end;

implementation

{ TKeenSoundManager }

constructor TKeenSoundManager.Create(const AChunks: IKeenChunkSource; const ASpeaker: IKeenSpeaker);
var
  LSound: Integer;
  LBytes: TBytes;
begin
  inherited Create;
  if not Assigned(AChunks) then
    raise EArgumentNilException.Create('AChunks');
  FSpeaker := TKeenPcSpeaker.Create(ASpeaker);
  FSpeaker.OnFinished := SoundFinished;
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
  end;
  FMode := ksmPC;
end;

destructor TKeenSoundManager.Destroy;
begin
  FSpeaker.Free;
  inherited Destroy;
end;

function TKeenSoundManager.GetMode: TKeenSoundMode;
begin
  Result := FMode;
end;

procedure TKeenSoundManager.SetMode(AMode: TKeenSoundMode);
begin
  if AMode = FMode then
    Exit;
  StopSound;
  FMode := AMode;
end;

procedure TKeenSoundManager.SoundFinished;
begin
  FNumber := 0;
  FPriority := 0;
end;

procedure TKeenSoundManager.PlaySound(ASound: Integer);
begin
  if FMode = ksmOff then
    Exit;
  if (ASound < 0) or (ASound >= KEEN_NUMSOUNDS) or not FCached[ASound] then
    raise EKeenException.CreateFmt(SKeenSoundNotCached, [ASound]);
  if FSounds[ASound].Priority < FPriority then
    Exit;
  FSpeaker.Play(FSounds[ASound]);
  FNumber := ASound;
  FPriority := FSounds[ASound].Priority;
end;

procedure TKeenSoundManager.StopSound;
begin
  if FMode = ksmPC then
    FSpeaker.Stop;
  SoundFinished;
end;

function TKeenSoundManager.SoundPlaying: Integer;
begin
  Result := 0;
  if (FMode = ksmPC) and FSpeaker.Playing then
    Result := FNumber;
end;

procedure TKeenSoundManager.Service;
begin
  if FMode = ksmPC then
    FSpeaker.Service;
end;

procedure TKeenSoundManager.WaitSoundDone;
begin
  // the C spins until the timer interrupt ends the sound: here the interrupt is the loop
  while SoundPlaying <> 0 do
    Service;
end;

end.
