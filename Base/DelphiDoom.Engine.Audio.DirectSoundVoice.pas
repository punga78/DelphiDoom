{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - a sound effect in a DirectSound buffer                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Audio.DirectSoundVoice;

interface

uses
  DirectX,
  DelphiDoom.Audio.Types,
  DelphiDoom.Audio.Intf;

type
  TDirectSoundVoice = class(TInterfacedObject, IAudioVoice)
  private
    FBuffer: IDirectSoundBuffer;
  public
    constructor Create(const ABuffer: IDirectSoundBuffer);
    function Load(const ASample: TSfxSample): Integer;
    procedure Play;
    procedure Stop;
    procedure Rewind;
    procedure SetPan(APan: Integer);
    procedure SetVolume(AVolume: Integer);
    function IsPlaying: Boolean;
  end;

implementation

{ TDirectSoundVoice }

constructor TDirectSoundVoice.Create(const ABuffer: IDirectSoundBuffer);
begin
  inherited Create;
  FBuffer := ABuffer;
end;

function TDirectSoundVoice.Load(const ASample: TSfxSample): Integer;
var
  LFirst: Pointer;
  LFirstSize: LongWord;
  LSecond: Pointer;
  LSecondSize: LongWord;
begin
  Result := FBuffer.Lock(0, ASample.Length - ASample.Offset, LFirst, LFirstSize, LSecond,
    LSecondSize, 0);
  if Result <> DS_OK then
    Exit;

  Move((ASample.Data + ASample.Offset)^, LFirst^, LFirstSize);
  Result := FBuffer.Unlock(LFirst, LFirstSize, LSecond, LSecondSize);
end;

procedure TDirectSoundVoice.Play;
begin
  FBuffer.Play(0, 0, 0);
end;

procedure TDirectSoundVoice.Stop;
begin
  FBuffer.Stop;
end;

procedure TDirectSoundVoice.Rewind;
begin
  FBuffer.SetCurrentPosition(0);
end;

procedure TDirectSoundVoice.SetPan(APan: Integer);
begin
  FBuffer.SetPan(APan);
end;

procedure TDirectSoundVoice.SetVolume(AVolume: Integer);
begin
  FBuffer.SetVolume(AVolume);
end;

function TDirectSoundVoice.IsPlaying: Boolean;
var
  LStatus: LongWord;
begin
  FBuffer.GetStatus(LStatus);
  Result := (LStatus and DSBSTATUS_PLAYING) <> 0;
end;

end.
