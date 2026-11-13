{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - FLIC animations: the frame at a time        }
{  (issue #199)                                                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Flic.Player;

interface

uses
  DelphiDoom.Imaging.Types,
  DelphiDoom.Cinematic.Flic.Types,
  DelphiDoom.Cinematic.Flic.Intf;

type
  /// <summary>
  ///   Chooses the frame to show from a time that the caller gives. The first time it is asked
  ///   is the start; every frame stays for its own delay (the sum of the delays of the frames
  ///   before it is when it starts). A time that goes back rewinds; at the end an animation in
  ///   a loop starts again, otherwise the last frame stays and the status is fpsEnded
  /// </summary>
  TFlicPlayer = class(TInterfacedObject, IFlicPlayer)
  strict private
    FDecoder: IFlicDecoder;
    FLooping: Boolean;
    FStarted: Boolean;
    FEnded: Boolean;
    FStartTime: Int64;
    FShownStart: Int64;
    FShownEnd: Int64;
    FCachedIndex: Integer;
    FCachedPixels: TImagingPixels;
    procedure Restart;
    function Advance: Boolean;
    function CurrentImage: TFlicPlayerImage;
  public
    /// <param name="ALooping">At the end the animation starts again; otherwise the last frame stays</param>
    constructor Create(const ADecoder: IFlicDecoder; ALooping: Boolean);
    function ImageForTime(AMilliseconds: Integer): TFlicPlayerImage;
    procedure ResetTime;
  end;

implementation

{ TFlicPlayer }

constructor TFlicPlayer.Create(const ADecoder: IFlicDecoder; ALooping: Boolean);
begin
  inherited Create;
  FDecoder := ADecoder;
  FLooping := ALooping;
  FCachedIndex := -1;
end;

procedure TFlicPlayer.Restart;
begin
  FDecoder.Reset;
  FShownStart := 0;
  FShownEnd := 0;
  FCachedIndex := -1;
end;

function TFlicPlayer.Advance: Boolean;
begin
  Result := FDecoder.NextFrame;
  if Result then
  begin
    FShownStart := FShownEnd;
    FShownEnd := FShownStart + FDecoder.FrameDelay;
  end;
end;

function TFlicPlayer.CurrentImage: TFlicPlayerImage;
begin
  Result.Width := FDecoder.Width;
  Result.Height := FDecoder.Height;
  Result.FrameIndex := FDecoder.FrameIndex;
  if FEnded then
    Result.Status := fpsEnded
  else
    Result.Status := fpsPlaying;
  if FCachedIndex <> FDecoder.FrameIndex then
  begin
    FCachedPixels := FDecoder.Frame;
    FCachedIndex := FDecoder.FrameIndex;
  end;
  Result.Pixels := FCachedPixels;
end;

function TFlicPlayer.ImageForTime(AMilliseconds: Integer): TFlicPlayerImage;
var
  LElapsed, LTotal: Int64;
begin
  if AMilliseconds < 0 then
    AMilliseconds := 0;
  if not FStarted then
  begin
    FStarted := True;
    FStartTime := AMilliseconds;
    Restart;
  end;
  if FEnded then
    Exit(CurrentImage);
  LElapsed := Int64(AMilliseconds) - FStartTime;
  if LElapsed < 0 then
    LElapsed := 0;
  if LElapsed < FShownStart then
    Restart;
  while LElapsed >= FShownEnd do
    if not Advance then
    begin
      if not FLooping then
      begin
        FEnded := True;
        Break;
      end;
      // the sum of the delays is the length of one turn
      LTotal := FShownEnd;
      Inc(FStartTime, (LElapsed div LTotal) * LTotal);
      LElapsed := LElapsed mod LTotal;
      Restart;
    end;
  Result := CurrentImage;
end;

procedure TFlicPlayer.ResetTime;
begin
  FStarted := False;
  FEnded := False;
  Restart;
end;

end.
