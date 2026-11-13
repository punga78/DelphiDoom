{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - scenes of FLIC animations: contracts (#199) }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Flic.Scene.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Flic.Scene.Types;

type
  /// <summary>Where the files of the animations are: by name, not by path</summary>
  IFlicSource = interface
    ['{2F83B1D6-9A47-4C05-8E1B-D5C0763A9E48}']
    /// <summary>The bytes of the animation called AName; False if there is no such animation</summary>
    function TryRead(const AName: string; out ABytes: TBytes): Boolean;
  end;

  /// <summary>
  ///   The sound that goes with a scene (the voice of an introduction, the music of an ending). The scene says
  ///   when it starts and when it is over; what plays and how is the audio's own business
  /// </summary>
  IFlicSceneAudio = interface
    ['{7C0E5A92-31D8-4B76-A4F9-186BD2E3C507}']
    /// <summary>The first update of the scene</summary>
    procedure SceneStarted;
    /// <summary>The scene ended by itself (ASkipped False) or was skipped: the sound stops</summary>
    procedure SceneFinished(ASkipped: Boolean);
  end;

  /// <summary>
  ///   An animation that a viewer can skip. The caller gives the time on its own clock and whether the viewer
  ///   asked to skip (a key): the scene reads no clock and no keyboard
  /// </summary>
  IFlicScene = interface
    ['{A94D6E13-5B2F-4807-93C1-E80F47D2B6A5}']
    function GetName: string;
    function GetState: TFlicSceneState;
    /// <summary>The scene at AMilliseconds; ASkipRequested True ends it now if it can be skipped</summary>
    function Update(AMilliseconds: Integer; ASkipRequested: Boolean): TFlicSceneFrame;
    property Name: string read GetName;
    property State: TFlicSceneState read GetState;
  end;

  /// <summary>Makes the scene of an animation by name: the part of a game that knows nothing of files and decoders</summary>
  IFlicSceneMaker = interface
    ['{5E1B8C37-D402-49A6-B7F3-0C96A4E5D218}']
    /// <summary>The scene, or nil if there is no such animation (it is skipped)</summary>
    function TryCreateScene(const AName: string; const AOptions: TFlicSceneOptions;
      const AAudio: IFlicSceneAudio): IFlicScene;
  end;

implementation

end.
