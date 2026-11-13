{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the mixer as a source of the PCM output           }
{                                                                              }
{  Port of the buffer handling of audioDataCallback (war_audio.c), war1        }
{  (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib License (see        }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Audio.PcmSource;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Audio.Intf, DelphiDoom.War.Audio.Intf;

type
  /// <summary>
  ///   What IGameHostPcmOutput asks for: 16 bit stereo at the rate of the output, which must be WAR_PLAYBACK_RATE.
  ///   The mixer is mono (the original opens a mono stream): each sample goes to both channels. The mixed block
  ///   is as long as the original callback allows (AUDIO_MIX_BUFFER_MAX_SAMPLES, 8192); a longer request is
  ///   served in blocks
  /// </summary>
  TWarPcmSource = class(TInterfacedObject, IGameHostPcmSource)
  strict private
    FMixer: IWarSoundMixer;
    FMono: array[0..8191] of SmallInt;
  public
    constructor Create(const AMixer: IWarSoundMixer);
    procedure Render(ABuffer: PByte; AByteCount: Integer);
  end;

implementation

uses
  DelphiDoom.War.Types;

{ TWarPcmSource }

constructor TWarPcmSource.Create(const AMixer: IWarSoundMixer);
begin
  inherited Create;
  if not Assigned(AMixer) then
    raise EWarException.Create('The mixer of the PCM source is nil');
  FMixer := AMixer;
end;

procedure TWarPcmSource.Render(ABuffer: PByte; AByteCount: Integer);
var
  LFrames, LBlock, LIndex: Integer;
  LTarget: PSmallInt;
begin
  LTarget := PSmallInt(ABuffer);
  LFrames := AByteCount div 4;
  while LFrames > 0 do
  begin
    LBlock := LFrames;
    if LBlock > Length(FMono) then
      LBlock := Length(FMono);
    FillChar(FMono, LBlock * SizeOf(SmallInt), 0);
    FMixer.Mix(@FMono[0], LBlock);
    for LIndex := 0 to LBlock - 1 do
    begin
      LTarget^ := FMono[LIndex];
      Inc(LTarget);
      LTarget^ := FMono[LIndex];
      Inc(LTarget);
    end;
    Dec(LFrames, LBlock);
  end;
end;

end.
