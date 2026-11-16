{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - scenes of FLIC animations: types (#199)     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Flic.Scene.Types;

interface

uses
  DelphiDoom.Cinematic.Flic.Intf;

type
  /// <summary>Where a scene is: it plays until it ends by itself or is skipped</summary>
  TFlicSceneState = (
    /// <summary>It has not been updated yet</summary>
    fssPending,
    fssPlaying,
    /// <summary>The last frame was shown and the animation does not loop</summary>
    fssEnded,
    /// <summary>The viewer asked to skip it</summary>
    fssSkipped
  );

  /// <summary>How a scene plays</summary>
  TFlicSceneOptions = record
    /// <summary>At the end the animation starts again; only a skip stops it</summary>
    Looping: Boolean;
    /// <summary>A request to skip stops the scene (a scene that cannot be skipped ignores it)</summary>
    Skippable: Boolean;
    class function Default: TFlicSceneOptions; static;
  end;

  /// <summary>What a scene gives at a time</summary>
  TFlicSceneFrame = record
    State: TFlicSceneState;
    /// <summary>The image to show; empty (Width = 0) until the first update, and the last one after a skip</summary>
    Image: TFlicPlayerImage;
    /// <summary>The frame is not the one that the previous update gave: the picture must be drawn again</summary>
    FrameChanged: Boolean;
  end;

implementation

{ TFlicSceneOptions }

class function TFlicSceneOptions.Default: TFlicSceneOptions;
begin
  Result.Looping := False;
  Result.Skippable := True;
end;

end.
