{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the volumes of the sound                         }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): SetVolumes of modplay.pas   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SoundVolumes;

interface

uses
  DelphiDoom.Greed.Sound.Intf;

type
  /// <summary>
  ///   SC.musicvol and SC.sfxvol. The defaults are those of InitDefaults (100 and 128). A volume over 255 becomes
  ///   255; a negative one is kept (as in the original, the menu keeps them from going below 0)
  /// </summary>
  TGreedSoundVolumes = class(TInterfacedObject, IGreedSoundVolumes)
  strict private
    FMusicVolume: Integer;
    FSfxVolume: Integer;
  public
    constructor Create;
    function GetMusicVolume: Integer;
    function GetSfxVolume: Integer;
    procedure SetVolumes(AMusic, ASfx: Integer);
  end;

implementation

const
  DEFAULT_MUSIC_VOLUME = 100;
  DEFAULT_SFX_VOLUME = 128;
  MAXIMUM_VOLUME = 255;

{ TGreedSoundVolumes }

constructor TGreedSoundVolumes.Create;
begin
  inherited Create;
  FMusicVolume := DEFAULT_MUSIC_VOLUME;
  FSfxVolume := DEFAULT_SFX_VOLUME;
end;

function TGreedSoundVolumes.GetMusicVolume: Integer;
begin
  Result := FMusicVolume;
end;

function TGreedSoundVolumes.GetSfxVolume: Integer;
begin
  Result := FSfxVolume;
end;

procedure TGreedSoundVolumes.SetVolumes(AMusic, ASfx: Integer);
begin
  if AMusic > MAXIMUM_VOLUME then
    AMusic := MAXIMUM_VOLUME;
  if ASfx > MAXIMUM_VOLUME then
    ASfx := MAXIMUM_VOLUME;
  FMusicVolume := AMusic;
  FSfxVolume := ASfx;
end;

end.
