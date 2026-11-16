{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - a scene of a FLIC animation (#199)          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Flic.Scene;

interface

uses
  DelphiDoom.Cinematic.Flic.Intf,
  DelphiDoom.Cinematic.Flic.Scene.Types,
  DelphiDoom.Cinematic.Flic.Scene.Intf;

type
  /// <summary>
  ///   Plays an animation on a player and keeps the state of the scene: the first update starts it (and its
  ///   sound), a request to skip ends it at once, the end of an animation that does not loop ends it. After it
  ///   is over the scene keeps giving its last image and the audio is told only once
  /// </summary>
  TFlicScene = class(TInterfacedObject, IFlicScene)
  strict private
    FName: string;
    FPlayer: IFlicPlayer;
    FOptions: TFlicSceneOptions;
    FAudio: IFlicSceneAudio;
    FState: TFlicSceneState;
    FLast: TFlicPlayerImage;
    FLastIndex: Integer;
    procedure Finish(AState: TFlicSceneState);
    function GetName: string;
    function GetState: TFlicSceneState;
  public
    /// <param name="AAudio">The sound of the scene; nil for none</param>
    constructor Create(const AName: string; const APlayer: IFlicPlayer; const AOptions: TFlicSceneOptions;
      const AAudio: IFlicSceneAudio);
    function Update(AMilliseconds: Integer; ASkipRequested: Boolean): TFlicSceneFrame;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Types;

{ TFlicScene }

constructor TFlicScene.Create(const AName: string; const APlayer: IFlicPlayer; const AOptions: TFlicSceneOptions;
  const AAudio: IFlicSceneAudio);
begin
  inherited Create;
  if not Assigned(APlayer) then
    raise ECinematicException.Create('The player of the scene is nil');
  FName := AName;
  FPlayer := APlayer;
  FOptions := AOptions;
  FAudio := AAudio;
  FState := fssPending;
  FLastIndex := -1;
end;

function TFlicScene.GetName: string;
begin
  Result := FName;
end;

function TFlicScene.GetState: TFlicSceneState;
begin
  Result := FState;
end;

procedure TFlicScene.Finish(AState: TFlicSceneState);
begin
  FState := AState;
  if Assigned(FAudio) then
    FAudio.SceneFinished(AState = fssSkipped);
end;

function TFlicScene.Update(AMilliseconds: Integer; ASkipRequested: Boolean): TFlicSceneFrame;
begin
  Result.FrameChanged := False;
  if FState in [fssEnded, fssSkipped] then
  begin
    Result.State := FState;
    Result.Image := FLast;
    Exit;
  end;
  if FState = fssPending then
  begin
    FState := fssPlaying;
    if Assigned(FAudio) then
      FAudio.SceneStarted;
  end;
  if ASkipRequested and FOptions.Skippable then
  begin
    Finish(fssSkipped);
    Result.State := fssSkipped;
    Result.Image := FLast;
    Exit;
  end;
  FLast := FPlayer.ImageForTime(AMilliseconds);
  Result.FrameChanged := FLast.FrameIndex <> FLastIndex;
  FLastIndex := FLast.FrameIndex;
  if (FLast.Status = fpsEnded) and not FOptions.Looping then
    Finish(fssEnded);
  Result.State := FState;
  Result.Image := FLast;
end;

end.
