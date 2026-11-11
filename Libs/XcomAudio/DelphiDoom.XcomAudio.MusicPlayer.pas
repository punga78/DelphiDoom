{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - the music of the game (the music part of    }
{  Mod: loadExtraResources, getMusic, getRandomMusic and playMusic)             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.MusicPlayer;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Resources.Intf,
  DelphiDoom.XcomEngine.Music.Intf, DelphiDoom.XcomAudio.Intf;

type
  /// <summary>A number from 0 to AMaximum (RNG::seedless)</summary>
  TXcomMusicRandom = reference to function(AMaximum: Integer): Integer;

  /// <summary>
  ///   The musics of the rulesets and which one plays. Mod::loadExtraResources tries, for each music, the preferred
  ///   format and then FLAC, OGG, MP3, MOD, WAV, Adlib, GM and MIDI, and keeps the first that loads: each format is an
  ///   IXcomMusicFormatLoader that gives the track or nil (a file that is not there or is not readable), so that the
  ///   next one is tried. A format with no loader gives nothing
  /// </summary>
  TXcomMusicPlayer = class(TInterfacedObject, IXcomMusicPlayer)
  strict private
    type
      TEntry = record
        MusicType: string;
        Track: IXcomMusicTrack;
      end;
    var
      FSink: IXcomMusicSink;
      FSettings: IXcomMusicSettings;
      FLoaders: TArray<IXcomMusicFormatLoader>;
      FRandom: TXcomMusicRandom;
      FEntries: TList<TEntry>;
      FPlayingMusic: string;
    function LoadMusic(AFormat: Integer; const ARule: TXcomMusicRule): IXcomMusicTrack;
    function Find(const AType: string): IXcomMusicTrack;
  public
    /// <param name="ALoaders">One for each format the player can load, in any order</param>
    constructor Create(const ASink: IXcomMusicSink; const ASettings: IXcomMusicSettings;
      const ALoaders: TArray<IXcomMusicFormatLoader>; const ARandom: TXcomMusicRandom = nil);
    destructor Destroy; override;
    procedure Reload(const AResources: IXcomResources);
    procedure PlayMusic(const AName: string; AId: Integer = 0);
    procedure Stop;
    procedure Pause;
    procedure Resume;
    function IsPlaying: Boolean;
    function CurrentFormat: string;
    function LoadedCount: Integer;
    /// <summary>The types of the musics that loaded, in order</summary>
    function Types: TArray<string>;
  end;

implementation

uses
  DelphiDoom.XcomAudio.Types;

{ TXcomMusicPlayer }

constructor TXcomMusicPlayer.Create(const ASink: IXcomMusicSink; const ASettings: IXcomMusicSettings;
  const ALoaders: TArray<IXcomMusicFormatLoader>; const ARandom: TXcomMusicRandom);
begin
  inherited Create;
  if not Assigned(ASink) then
    raise EArgumentNilException.Create('ASink');
  if not Assigned(ASettings) then
    raise EArgumentNilException.Create('ASettings');
  FSink := ASink;
  FSettings := ASettings;
  FLoaders := ALoaders;
  FRandom := ARandom;
  if not Assigned(FRandom) then
    FRandom := function(AMaximum: Integer): Integer
      begin
        Result := Random(AMaximum + 1);
      end;
  FEntries := TList<TEntry>.Create;
end;

destructor TXcomMusicPlayer.Destroy;
begin
  Stop;
  FEntries.Free;
  inherited Destroy;
end;

function TXcomMusicPlayer.LoadMusic(AFormat: Integer; const ARule: TXcomMusicRule): IXcomMusicTrack;
var
  LLoader: IXcomMusicFormatLoader;
begin
  Result := nil;
  for LLoader in FLoaders do
    if Ord(LLoader.Format) = AFormat then
      Exit(LLoader.Load(ARule));
end;

procedure TXcomMusicPlayer.Reload(const AResources: IXcomResources);
var
  LRule: TXcomMusicRule;
  LLoader: IXcomMusicFormatLoader;
  LPriority: array[0..8] of Integer;
  LIndex: Integer;
  LTrack: IXcomMusicTrack;
  LEntry: TEntry;
begin
  Stop;
  FEntries.Clear;
  FPlayingMusic := '';
  if FSettings.Mute then
    Exit;
  for LLoader in FLoaders do
    LLoader.Reload(AResources);
  // the preferred format first, then the default order
  LPriority[0] := FSettings.PreferredFormat;
  LPriority[1] := Ord(mfFlac);
  LPriority[2] := Ord(mfOgg);
  LPriority[3] := Ord(mfMp3);
  LPriority[4] := Ord(mfMod);
  LPriority[5] := Ord(mfWav);
  LPriority[6] := Ord(mfAdlib);
  LPriority[7] := Ord(mfGm);
  LPriority[8] := Ord(mfMidi);
  for LRule in AResources.MusicRules do
  begin
    LTrack := nil;
    LIndex := 0;
    while (LTrack = nil) and (LIndex <= High(LPriority)) do
    begin
      LTrack := LoadMusic(LPriority[LIndex], LRule);
      Inc(LIndex);
    end;
    if LTrack <> nil then
    begin
      LEntry.MusicType := LRule.MusicType;
      LEntry.Track := LTrack;
      FEntries.Add(LEntry);
    end;
  end;
end;

function TXcomMusicPlayer.Find(const AType: string): IXcomMusicTrack;
var
  LEntry: TEntry;
begin
  for LEntry in FEntries do
    if LEntry.MusicType = AType then
      Exit(LEntry.Track);
  Result := nil;
end;

procedure TXcomMusicPlayer.PlayMusic(const AName: string; AId: Integer);
var
  LLoop: Integer;
  LTrack: IXcomMusicTrack;
  LMatches: TList<IXcomMusicTrack>;
  LEntry: TEntry;
  LPreparation: IXcomMusicPreparation;
begin
  if FSettings.Mute or (FPlayingMusic = AName) then
    Exit;
  LLoop := -1;
  // hacks
  if (not FSettings.AlwaysLoop) and ((AName = 'GMSTORY') or (AName = 'GMWIN') or (AName = 'GMLOSE')) then
    LLoop := 0;
  LTrack := nil;
  if AId = 0 then
  begin
    // getRandomMusic: the tracks whose type contains the name
    LMatches := TList<IXcomMusicTrack>.Create;
    try
      for LEntry in FEntries do
        if Pos(AName, LEntry.MusicType) > 0 then
          LMatches.Add(LEntry.Track);
      if LMatches.Count > 0 then
        LTrack := LMatches[FRandom(LMatches.Count - 1)];
    finally
      LMatches.Free;
    end;
  end
  else
    // getMusic(name + id): the C++ throws when there is none; here nothing plays
    LTrack := Find(AName + IntToStr(AId));
  if LTrack = nil then
    Exit;
  // the decoding of a file takes its time: it is done here, not while the mixer holds its lock
  if Supports(LTrack, IXcomMusicPreparation, LPreparation) then
    LPreparation.Prepare;
  FSink.PlayTrack(LTrack, LLoop);
  FPlayingMusic := AName;
end;

procedure TXcomMusicPlayer.Stop;
begin
  if FSink <> nil then
    FSink.StopTrack;
end;

procedure TXcomMusicPlayer.Pause;
begin
  FSink.PauseTrack(True);
end;

procedure TXcomMusicPlayer.Resume;
begin
  FSink.PauseTrack(False);
end;

function TXcomMusicPlayer.IsPlaying: Boolean;
var
  LTrack: IXcomMusicTrack;
begin
  LTrack := FSink.CurrentTrack;
  Result := (LTrack <> nil) and LTrack.IsPlaying;
end;

function TXcomMusicPlayer.CurrentFormat: string;
var
  LTrack: IXcomMusicTrack;
begin
  LTrack := FSink.CurrentTrack;
  if LTrack = nil then
    Result := 'Adlib'
  else
    Result := LTrack.Format;
end;

function TXcomMusicPlayer.LoadedCount: Integer;
begin
  Result := FEntries.Count;
end;

function TXcomMusicPlayer.Types: TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, FEntries.Count);
  for LIndex := 0 to FEntries.Count - 1 do
    Result[LIndex] := FEntries[LIndex].MusicType;
end;

end.
