{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - types of the "sound" declaration          }
{                                                                              }
{  Port of the sound shader of Doom 3 (id Software, GPL v3): sound\sound.h     }
{  (soundShaderParms_t, SSF_*), sound\snd_local.h (speakerLabel) and the data  }
{  of idSoundShader. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media  }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Sound.Types;

interface

const
  // sound shader flags (SSF_*)
  /// <summary>only plays for the current listener</summary>
  SSF_PRIVATE_SOUND = 1 shl 0;
  /// <summary>plays for everyone but the current listener</summary>
  SSF_ANTI_PRIVATE_SOUND = 1 shl 1;
  /// <summary>does not flow through portals, only uses the straight line</summary>
  SSF_NO_OCCLUSION = 1 shl 2;
  /// <summary>plays at full volume to all speakers and all listeners</summary>
  SSF_GLOBAL = 1 shl 3;
  /// <summary>falls off with distance but plays the same volume in all speakers</summary>
  SSF_OMNIDIRECTIONAL = 1 shl 4;
  /// <summary>repeats the sound continuously</summary>
  SSF_LOOPING = 1 shl 5;
  /// <summary>never restarts if already playing on any channel of a given emitter</summary>
  SSF_PLAY_ONCE = 1 shl 6;
  /// <summary>does not clamp calculated volumes at 1.0</summary>
  SSF_UNCLAMPED = 1 shl 7;
  /// <summary>always returns 1.0 for volume queries</summary>
  SSF_NO_FLICKER = 1 shl 8;
  /// <summary>tries not to play the same sound twice in a row</summary>
  SSF_NO_DUPS = 1 shl 9;

  /// <summary>The most samples (and leadins) a shader keeps</summary>
  SOUND_MAX_LIST_WAVS = 32;
  /// <summary>The sound classes used for the global fading of sounds</summary>
  SOUND_MAX_CLASSES = 4;

  // speakerLabel: the bits of the speaker mask are 1 shl label
  SPEAKER_LEFT = 0;
  SPEAKER_RIGHT = 1;
  SPEAKER_CENTER = 2;
  SPEAKER_LFE = 3;
  SPEAKER_BACKLEFT = 4;
  SPEAKER_BACKRIGHT = 5;

  /// <summary>The description of a shader that has none</summary>
  SOUND_NO_DESCRIPTION = '<no description>';

type
  /// <summary>soundShaderParms_t: the options a shader sets and an emitter or a channel can override</summary>
  TSoundShaderParms = record
    /// <summary>In meters</summary>
    MinDistance: Single;
    /// <summary>In meters</summary>
    MaxDistance: Single;
    /// <summary>"in dB, unfortunately": negative values get quieter (the shader's own number, no conversion)</summary>
    Volume: Single;
    Shakes: Single;
    /// <summary>SSF_* bits</summary>
    SoundShaderFlags: Integer;
    SoundClass: Integer;
  end;

  /// <summary>
  ///   What a shader keeps of an <c>idSoundSample</c> (the cache entry the shader found): the name the cache gave it
  ///   and what <c>CheckShakesAndOgg</c>, <c>HasDefaultSound</c> and <c>List</c> read. A snapshot taken when the
  ///   sample is found (the original reads the live entry, which a purge can change)
  /// </summary>
  TSoundSampleInfo = record
    /// <summary>The canonical name: slashes forward, lower case (<c>idSoundCache::FindSound</c>)</summary>
    Name: AnsiString;
    /// <summary>objectInfo.wFormatTag = WAVE_FORMAT_TAG_OGG</summary>
    IsOgg: Boolean;
    /// <summary>The sample could not be loaded and is the default sound</summary>
    IsDefault: Boolean;
    /// <summary>LengthIn44kHzSamples</summary>
    Length44kHzSamples: Integer;
    /// <summary>objectMemSize, in bytes</summary>
    MemorySize: Integer;
  end;

  /// <summary>
  ///   What the cvars and the game folder change in the reading of a shader: <c>s_maxSoundsPerShader</c>,
  ///   <c>com_makingBuild</c> and <c>sys_lang</c>
  /// </summary>
  TSoundShaderOptions = record
    /// <summary>s_maxSoundsPerShader (default 0): the most samples of a shader; 0, or more than 32, is 32</summary>
    MaxSoundsPerShader: Integer;
    /// <summary>com_makingBuild (default false): true keeps all 32 samples whatever the cvar says</summary>
    MakingBuild: Boolean;
    /// <summary>sys_lang (default "english"): a sound of <c>sound/vo/</c> is looked for in another language folder</summary>
    Language: AnsiString;
    class function Standard: TSoundShaderOptions; static;
  end;

  /// <summary>
  ///   The data of an <c>idSoundShader</c> that a parse fills. <c>Init</c> is what the constructor does: the
  ///   description, the lead-in volume and the lists are the only fields it sets (the rest is set by the parse)
  /// </summary>
  TSoundShaderData = record
    Description: AnsiString;
    Parms: TSoundShaderParms;
    /// <summary>1 shl SPEAKER_* for each <c>mask_*</c> word</summary>
    SpeakerMask: Integer;
    /// <summary>Allows the light breaking lead-in sounds to be much louder than the broken loop</summary>
    LeadinVolume: Single;
    Leadins: TArray<TSoundSampleInfo>;
    Entries: TArray<TSoundSampleInfo>;
    class function Init: TSoundShaderData; static;
  end;

implementation

{ TSoundShaderOptions }

class function TSoundShaderOptions.Standard: TSoundShaderOptions;
begin
  Result.MaxSoundsPerShader := 0;
  Result.MakingBuild := False;
  Result.Language := 'english';
end;

{ TSoundShaderData }

class function TSoundShaderData.Init: TSoundShaderData;
begin
  Result := Default(TSoundShaderData);
  Result.Description := SOUND_NO_DESCRIPTION;
end;

end.
