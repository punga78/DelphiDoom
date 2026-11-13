{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the sound of an animation                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Cinematic.Audio;

interface

uses
  DelphiDoom.Cinematic.Flic.Scene.Intf, DelphiDoom.War.Level.Types, DelphiDoom.War.Audio.Intf,
  DelphiDoom.War.Sound.Intf, DelphiDoom.War.Cinematic.Types;

type
  /// <summary>
  ///   The voice that goes with a scene: it starts with the scene and stops at once if the scene is skipped (a
  ///   scene that ends by itself lets the voice finish). The sound comes from the catalog entry; the choice among
  ///   many (the victory of a race) is the picker's
  /// </summary>
  TWarCinematicAudio = class(TInterfacedObject, IFlicSceneAudio)
  strict private
    FMixer: IWarSoundMixer;
    FPicker: IWarSoundPicker;
    FEntry: TWarCinematicEntry;
    FPlayerRace: TWarRace;
    FHandle: Integer;
    function ResolveSound: Integer;
  public
    constructor Create(const AMixer: IWarSoundMixer; const APicker: IWarSoundPicker;
      const AEntry: TWarCinematicEntry; APlayerRace: TWarRace);
    procedure SceneStarted;
    procedure SceneFinished(ASkipped: Boolean);
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Sound.Ids;

{ TWarCinematicAudio }

constructor TWarCinematicAudio.Create(const AMixer: IWarSoundMixer; const APicker: IWarSoundPicker;
  const AEntry: TWarCinematicEntry; APlayerRace: TWarRace);
begin
  inherited Create;
  if not Assigned(AMixer) or not Assigned(APicker) then
    raise EWarException.Create('The mixer and the picker of the sound of an animation cannot be nil');
  FMixer := AMixer;
  FPicker := APicker;
  FEntry := AEntry;
  FPlayerRace := APlayerRace;
  FHandle := 0;
end;

function TWarCinematicAudio.ResolveSound: Integer;
var
  LRace: TWarRace;
begin
  case FEntry.SoundKind of
    wcsFixed: Result := FEntry.Sound;
    wcsEvent:
      begin
        LRace := FEntry.SoundRace;
        if LRace = wraNeutral then
          LRace := FPlayerRace;
        Result := FPicker.Pick(FEntry.SoundEvent, LRace);
      end;
  else
    Result := WAR_SND_NONE;
  end;
end;

procedure TWarCinematicAudio.SceneStarted;
var
  LSound: Integer;
begin
  LSound := ResolveSound;
  if LSound >= 0 then
    FHandle := FMixer.Play(LSound, False);
end;

procedure TWarCinematicAudio.SceneFinished(ASkipped: Boolean);
begin
  if ASkipped and (FHandle <> 0) then
  begin
    FMixer.Stop(FHandle);
    FHandle := 0;
  end;
end;

end.
