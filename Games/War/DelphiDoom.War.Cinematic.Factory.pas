{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the factory of the animations                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Cinematic.Factory;

interface

uses
  DelphiDoom.Cinematic.Flic.Scene.Intf, DelphiDoom.War.Audio.Intf, DelphiDoom.War.Sound.Intf,
  DelphiDoom.War.Cinematic.Intf;

type
  /// <summary>The only place that knows the concrete classes of the animations of the game</summary>
  TWarCinematicFactory = class
  public
    class function CreateCatalog: IWarCinematicCatalog; static;
    /// <summary>The director with the maker it is given (the one that reads the files, or a fake in a test)</summary>
    class function CreateDirector(const AMaker: IFlicSceneMaker; const AMixer: IWarSoundMixer;
      const APicker: IWarSoundPicker): IWarCinematicDirector; static;
  end;

implementation

uses
  DelphiDoom.War.Cinematic.Catalog, DelphiDoom.War.Cinematic.Director;

{ TWarCinematicFactory }

class function TWarCinematicFactory.CreateCatalog: IWarCinematicCatalog;
begin
  Result := TWarCinematicCatalog.Create;
end;

class function TWarCinematicFactory.CreateDirector(const AMaker: IFlicSceneMaker; const AMixer: IWarSoundMixer;
  const APicker: IWarSoundPicker): IWarCinematicDirector;
begin
  Result := TWarCinematicDirector.Create(CreateCatalog, AMaker, AMixer, APicker);
end;

end.
