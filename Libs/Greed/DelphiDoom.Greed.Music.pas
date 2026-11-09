{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the music                                        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): modplay.pas                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Music;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Sound.Intf;

type
  /// <summary>
  ///   PlaySong and StopMusic. The songs are files next to the data (SONG0.S3M, ENDING.MOD...), looked for by name
  ///   in the folders of the external files (the original also looked in MUSIC\ and on the CD-ROM: give those
  ///   folders to the external files). The fade out at the end goes down 3 at a time, one tic each, unless it is
  ///   a net game
  /// </summary>
  TGreedMusic = class(TInterfacedObject, IGreedMusic)
  strict private
    FDevice: IGreedSoundDevice;
    FFiles: IGreedExternalFiles;
    FVolumes: IGreedSoundVolumes;
    FTics: IGreedTics;
    FNetGame: Boolean;
    FChannel: IGreedMusicChannel;
    procedure ApplyVolume;
  public
    constructor Create(const ADevice: IGreedSoundDevice; const AFiles: IGreedExternalFiles;
      const AVolumes: IGreedSoundVolumes; const ATics: IGreedTics; ANetGame: Boolean);
    procedure Play(const AFileName: string; APattern: Integer);
    procedure Stop;
    /// <summary>The music volume of the settings goes to the song that plays (UpdateSound, SetVolumes)</summary>
    procedure ApplyVolumes;
  end;

implementation

{ TGreedMusic }

constructor TGreedMusic.Create(const ADevice: IGreedSoundDevice; const AFiles: IGreedExternalFiles;
  const AVolumes: IGreedSoundVolumes; const ATics: IGreedTics; ANetGame: Boolean);
begin
  inherited Create;
  if not Assigned(ADevice) then
    raise EArgumentNilException.Create('ADevice');
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  if not Assigned(AVolumes) then
    raise EArgumentNilException.Create('AVolumes');
  if not Assigned(ATics) then
    raise EArgumentNilException.Create('ATics');
  FDevice := ADevice;
  FFiles := AFiles;
  FVolumes := AVolumes;
  FTics := ATics;
  FNetGame := ANetGame;
end;

procedure TGreedMusic.ApplyVolume;
begin
  if Assigned(FChannel) then
    FChannel.SetVolume(FVolumes.MusicVolume / 255);
end;

procedure TGreedMusic.ApplyVolumes;
begin
  ApplyVolume;
end;

procedure TGreedMusic.Stop;
var
  LOldVolume, LVolume: Integer;
begin
  if not Assigned(FChannel) then
    Exit;
  LOldVolume := FVolumes.MusicVolume;
  if not FNetGame then
  begin
    LVolume := LOldVolume;
    while LVolume > 0 do
    begin
      FVolumes.SetVolumes(LVolume, FVolumes.SfxVolume);
      ApplyVolume;
      FTics.Wait(1);
      Dec(LVolume, 3);
    end;
  end;
  FVolumes.SetVolumes(LOldVolume, FVolumes.SfxVolume);
  FChannel.Stop;
  FChannel := nil;
end;

procedure TGreedMusic.Play(const AFileName: string; APattern: Integer);
var
  LName: string;
begin
  Stop;
  LName := ExtractFileName(AFileName);
  if not FFiles.Exists(LName) then
    Exit;
  FChannel := FDevice.StartMusic(FFiles.ReadAll(LName), FVolumes.MusicVolume / 255);
end;

end.
