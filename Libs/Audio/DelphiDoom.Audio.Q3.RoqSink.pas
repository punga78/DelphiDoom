{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound, audio of a RoQ video           }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.RoqSink;

interface

uses
  DelphiDoom.Cinematic.Intf, DelphiDoom.Audio.Q3.RawStream;

type
  /// <summary>
  ///   Connects the decoder of Libs\Cinematic to the stream of raw samples: the audio
  ///   that the decoder meets goes to S_RawSamples as the video code of Quake III does
  /// </summary>
  TQ3RoqAudioSink = class(TInterfacedObject, IRoqAudioSink)
  strict private
    FStream: TQ3RawStream;
    FVolume: Single;
  public
    /// <summary>The stream is not owned; AVolume is the volume of S_RawSamples (1.0 = the samples as they are)</summary>
    constructor Create(AStream: TQ3RawStream; AVolume: Single = 1.0);
    procedure AudioReceived(const ASamples: TArray<SmallInt>; AChannels,
      ASampleRate: Integer);
  end;

implementation

{ TQ3RoqAudioSink }

constructor TQ3RoqAudioSink.Create(AStream: TQ3RawStream; AVolume: Single);
begin
  inherited Create;
  FStream := AStream;
  FVolume := AVolume;
end;

procedure TQ3RoqAudioSink.AudioReceived(const ASamples: TArray<SmallInt>; AChannels,
  ASampleRate: Integer);
begin
  FStream.RawSamples(ASamples, ASampleRate, AChannels, FVolume);
end;

end.
