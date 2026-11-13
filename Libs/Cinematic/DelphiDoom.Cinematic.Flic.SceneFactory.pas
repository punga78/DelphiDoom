{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - where the scenes are made (#199)            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Flic.SceneFactory;

interface

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Flic.Scene.Types,
  DelphiDoom.Cinematic.Flic.Scene.Intf;

type
  /// <summary>The composition root of the scenes</summary>
  TFlicSceneFactory = class
  public
    /// <summary>
    ///   The scene of the animation AName, or nil if the source has no such animation (the caller skips it: some
    ///   animations of a game are not on the disk). A file that is there but is not a FLIC raises
    ///   EFlicInvalidDataException: a missing file and a broken one are not the same thing
    /// </summary>
    class function TryCreateScene(const AName: string; const ASource: IFlicSource; const AOptions: TFlicSceneOptions;
      const AAudio: IFlicSceneAudio): IFlicScene; static;
    /// <summary>The scene of the bytes of an animation</summary>
    class function CreateSceneFromBytes(const AName: string; const ABytes: TBytes; const AOptions: TFlicSceneOptions;
      const AAudio: IFlicSceneAudio): IFlicScene; static;
    class function CreateFolderSource(const AFolder, AExtension: string): IFlicSource; static;
    /// <summary>The maker of the scenes of a source</summary>
    class function CreateMaker(const ASource: IFlicSource): IFlicSceneMaker; static;
  end;

implementation

uses
  DelphiDoom.Cinematic.Types, DelphiDoom.Cinematic.Flic.Factory, DelphiDoom.Cinematic.Flic.Scene,
  DelphiDoom.Cinematic.Flic.FolderSource, DelphiDoom.Cinematic.Flic.SceneMaker;

{ TFlicSceneFactory }

class function TFlicSceneFactory.CreateSceneFromBytes(const AName: string; const ABytes: TBytes;
  const AOptions: TFlicSceneOptions; const AAudio: IFlicSceneAudio): IFlicScene;
begin
  Result := TFlicScene.Create(AName, TFlicFactory.CreatePlayer(TFlicFactory.CreateDecoder(ABytes), AOptions.Looping),
    AOptions, AAudio);
end;

class function TFlicSceneFactory.TryCreateScene(const AName: string; const ASource: IFlicSource;
  const AOptions: TFlicSceneOptions; const AAudio: IFlicSceneAudio): IFlicScene;
var
  LBytes: TBytes;
begin
  if not Assigned(ASource) then
    raise ECinematicException.Create('The source of the scenes is nil');
  if not ASource.TryRead(AName, LBytes) then
    Exit(nil);
  Result := CreateSceneFromBytes(AName, LBytes, AOptions, AAudio);
end;

class function TFlicSceneFactory.CreateFolderSource(const AFolder, AExtension: string): IFlicSource;
begin
  Result := TFlicFolderSource.Create(AFolder, AExtension);
end;

class function TFlicSceneFactory.CreateMaker(const ASource: IFlicSource): IFlicSceneMaker;
begin
  Result := TFlicSceneMaker.Create(ASource);
end;

end.
