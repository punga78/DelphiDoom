{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - opening the animations of the game                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Cinematic.Director;

interface

uses
  DelphiDoom.Cinematic.Flic.Scene.Intf, DelphiDoom.War.Level.Types, DelphiDoom.War.Audio.Intf,
  DelphiDoom.War.Sound.Intf, DelphiDoom.War.Cinematic.Intf;

type
  /// <summary>
  ///   Puts together what the scene of an animation needs: the entry of the catalog (loop or not), the sound of
  ///   the scene and the scene itself, made by the maker that knows the files. A scene without mixer or picker
  ///   plays without sound
  /// </summary>
  TWarCinematicDirector = class(TInterfacedObject, IWarCinematicDirector)
  strict private
    FCatalog: IWarCinematicCatalog;
    FMaker: IFlicSceneMaker;
    FMixer: IWarSoundMixer;
    FPicker: IWarSoundPicker;
  public
    /// <param name="AMixer">Where the voices play; nil for scenes without sound</param>
    /// <param name="APicker">Chooses among the sounds of an event; nil for scenes without sound</param>
    constructor Create(const ACatalog: IWarCinematicCatalog; const AMaker: IFlicSceneMaker;
      const AMixer: IWarSoundMixer; const APicker: IWarSoundPicker);
    function TryOpen(const AName: string; APlayerRace: TWarRace): IFlicScene;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.Cinematic.Flic.Scene.Types, DelphiDoom.War.Cinematic.Types,
  DelphiDoom.War.Cinematic.Audio;

{ TWarCinematicDirector }

constructor TWarCinematicDirector.Create(const ACatalog: IWarCinematicCatalog; const AMaker: IFlicSceneMaker;
  const AMixer: IWarSoundMixer; const APicker: IWarSoundPicker);
begin
  inherited Create;
  if not Assigned(ACatalog) or not Assigned(AMaker) then
    raise EWarException.Create('The catalog and the scene maker of the cinematic director cannot be nil');
  FCatalog := ACatalog;
  FMaker := AMaker;
  FMixer := AMixer;
  FPicker := APicker;
end;

function TWarCinematicDirector.TryOpen(const AName: string; APlayerRace: TWarRace): IFlicScene;
var
  LEntry: TWarCinematicEntry;
  LOptions: TFlicSceneOptions;
  LAudio: IFlicSceneAudio;
begin
  if not FCatalog.TryFind(AName, LEntry) then
    Exit(nil);
  LOptions := TFlicSceneOptions.Default;
  LOptions.Looping := LEntry.Looping;
  LAudio := nil;
  if Assigned(FMixer) and Assigned(FPicker) and (LEntry.SoundKind <> wcsNone) then
    LAudio := TWarCinematicAudio.Create(FMixer, FPicker, LEntry, APlayerRace);
  Result := FMaker.TryCreateScene(LEntry.Name, LOptions, LAudio);
end;

end.
