{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - the frame of a cinematic at a time          }
{                                                                              }
{  Port of idCinematicLocal::ImageForTime of Doom 3 (renderer\Cinematic.cpp,   }
{  GPL v3 with the additional terms of the Doom 3 Source Code License,         }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company). Based    }
{  on the Doom 3 GPL Source Code (id Software).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Player;

interface

uses
  DelphiDoom.Cinematic.Intf;

type
  /// <summary>
  ///   Chooses the frame to show from a time that the caller gives. The first time it is
  ///   asked is the start of the cinematic; the frame shown is the one with the number
  ///   (time * frames per second) div 1000, so a time that goes back rewinds the file
  /// </summary>
  /// <remarks>
  ///   Difference from Doom 3: there the frame shown lags one behind (it advances when the
  ///   counter of the quads is past the target) and a chunk of information in the middle of
  ///   the file restarts that counter; here the frame number is the one of the frames
  ///   decoded since the start of the file
  /// </remarks>
  TRoqPlayer = class(TInterfacedObject, IRoqPlayer)
  strict private
    FDecoder: IRoqDecoder;
    FLooping: Boolean;
    FStarted: Boolean;
    FEnded: Boolean;
    FStartTime: Integer;
    function CurrentImage: TRoqPlayerImage;
    function DecodeTo(ATarget: Integer): Boolean;
  public
    /// <param name="ALooping">At the end of the file it starts again; otherwise the last frame stays</param>
    constructor Create(const ADecoder: IRoqDecoder; ALooping: Boolean);
    function ImageForTime(AMilliseconds: Integer): TRoqPlayerImage;
    procedure ResetTime;
  end;

implementation

{ TRoqPlayer }

constructor TRoqPlayer.Create(const ADecoder: IRoqDecoder; ALooping: Boolean);
begin
  inherited Create;
  FDecoder := ADecoder;
  FLooping := ALooping;
end;

function TRoqPlayer.CurrentImage: TRoqPlayerImage;
begin
  Result.Width := FDecoder.Width;
  Result.Height := FDecoder.Height;
  Result.FrameIndex := FDecoder.FrameIndex;
  Result.Pixels := FDecoder.Frame;
  if FEnded then
    Result.Status := rpsEnded
  else
    Result.Status := rpsPlaying;
end;

function TRoqPlayer.DecodeTo(ATarget: Integer): Boolean;
begin
  Result := True;
  while FDecoder.FrameIndex < ATarget do
    if not FDecoder.NextFrame then
      Exit(False);
end;

function TRoqPlayer.ImageForTime(AMilliseconds: Integer): TRoqPlayerImage;
var
  LTarget: Int64;
begin
  if AMilliseconds < 0 then
    AMilliseconds := 0;
  if not FStarted then
  begin
    FStarted := True;
    FStartTime := AMilliseconds;
  end;
  if FEnded then
  begin
    Result := CurrentImage;
    Exit;
  end;
  LTarget := (Int64(AMilliseconds) - FStartTime) * FDecoder.FramesPerSecond div 1000;
  if LTarget < 0 then
    LTarget := 0;
  if LTarget < FDecoder.FrameIndex then
    FDecoder.Reset;
  if not DecodeTo(Integer(LTarget)) then
  begin
    if FLooping then
    begin
      FDecoder.Reset;
      FStartTime := AMilliseconds;
      FEnded := not DecodeTo(0);
    end
    else
      FEnded := True;
  end;
  Result := CurrentImage;
end;

procedure TRoqPlayer.ResetTime;
begin
  FStarted := False;
  FEnded := False;
  FDecoder.Reset;
end;

end.
