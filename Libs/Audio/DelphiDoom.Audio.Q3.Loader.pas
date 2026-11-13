{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound, S_LoadSound                    }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.Loader;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf;

type
  /// <summary>
  ///   S_LoadSound: the bytes of a file become the 16 bit mono samples of an effect at the
  ///   rate of the device. The container is read by an ISndfile (Libs\Sound), not by the
  ///   RIFF scanner of snd_mem.c
  /// </summary>
  TQ3SoundLoader = class
  strict private
    FSndfile: ISndfile;
  public
    constructor Create(const ASndfile: ISndfile);
    /// <summary>
    ///   False if the bytes are not a sound or it is not mono (Quake III refuses stereo
    ///   files). 8 bit files give (byte - 128) shl 8, 16 bit files the samples themselves
    /// </summary>
    function Load(const ABytes: TBytes; ADmaSpeed: Integer;
      out ASamples: TArray<SmallInt>): Boolean;
  end;

implementation

uses
  DelphiDoom.Audio.Q3.Resampler;

const
  MAX_FRAMES = $4000000;

{ TQ3SoundLoader }

constructor TQ3SoundLoader.Create(const ASndfile: ISndfile);
begin
  inherited Create;
  FSndfile := ASndfile;
end;

function TQ3SoundLoader.Load(const ABytes: TBytes; ADmaSpeed: Integer;
  out ASamples: TArray<SmallInt>): Boolean;
var
  LSound: ISoundFile;
  LInfo: TSoundFileInfo;
  LRaw: TArray<SmallInt>;
  LRead: Int64;
begin
  ASamples := nil;
  Result := False;
  if Length(ABytes) = 0 then
    Exit;
  if FSndfile.OpenMemory(@ABytes[0], Length(ABytes), LSound) <> SNDFILE_OK then
    Exit;
  if (LSound.GetInfo(LInfo) <> SNDFILE_OK) or (LInfo.Channels <> 1) or
    (LInfo.Frames < 0) or (LInfo.Frames > MAX_FRAMES) or (LInfo.SampleRate <= 0) then
    Exit;
  SetLength(LRaw, LInfo.Frames);
  LRead := 0;
  if LInfo.Frames > 0 then
    if LSound.ReadShort(@LRaw[0], LInfo.Frames, LRead) <> SNDFILE_OK then
      Exit;
  ASamples := TQ3Resampler.ResampleShorts(LRaw, Integer(LRead), LInfo.SampleRate, ADmaSpeed);
  Result := True;
end;

end.
