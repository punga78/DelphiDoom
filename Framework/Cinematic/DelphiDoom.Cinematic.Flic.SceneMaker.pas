{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - the maker of the scenes of a source (#199)  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Flic.SceneMaker;

interface

uses
  DelphiDoom.Cinematic.Flic.Scene.Types,
  DelphiDoom.Cinematic.Flic.Scene.Intf;

type
  /// <summary>IFlicSceneMaker that reads the animations from an IFlicSource and decodes them with the FLIC decoder</summary>
  TFlicSceneMaker = class(TInterfacedObject, IFlicSceneMaker)
  strict private
    FSource: IFlicSource;
  public
    constructor Create(const ASource: IFlicSource);
    function TryCreateScene(const AName: string; const AOptions: TFlicSceneOptions;
      const AAudio: IFlicSceneAudio): IFlicScene;
  end;

implementation

uses
  DelphiDoom.Cinematic.Types, DelphiDoom.Cinematic.Flic.SceneFactory;

{ TFlicSceneMaker }

constructor TFlicSceneMaker.Create(const ASource: IFlicSource);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise ECinematicException.Create('The source of the scene maker is nil');
  FSource := ASource;
end;

function TFlicSceneMaker.TryCreateScene(const AName: string; const AOptions: TFlicSceneOptions;
  const AAudio: IFlicSceneAudio): IFlicScene;
begin
  Result := TFlicSceneFactory.TryCreateScene(AName, FSource, AOptions, AAudio);
end;

end.
