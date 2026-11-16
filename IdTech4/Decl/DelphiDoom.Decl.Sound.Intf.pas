{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - interfaces of the "sound" declaration     }
{                                                                              }
{  Not derived from Doom 3 code: written for this repository (GPL v2 or        }
{  later). The data it describes is that of sound\sound.h of Doom 3.           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Sound.Intf;

interface

uses
  DelphiDoom.Decl.Sound.Types;

type
  /// <summary>The data of a sound shader declaration (idSoundShader)</summary>
  IDeclSound = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A1120}']
    function GetDescription: AnsiString;
    /// <summary>In meters, like the shader says</summary>
    function GetMinDistance: Single;
    function GetMaxDistance: Single;
    /// <summary>The shader of <c>altSound</c>, nil if the shader has none</summary>
    function GetAltSound: IDeclSound;
    /// <summary>One of the samples is the default sound</summary>
    function HasDefaultSound: Boolean;
    function GetParms: TSoundShaderParms;
    function GetSpeakerMask: Integer;
    function GetLeadinVolume: Single;
    /// <summary>Lead-ins and samples</summary>
    function GetNumSounds: Integer;
    /// <summary>
    ///   The name of a sound: the lead-ins first, then the samples; '' outside the range
    /// </summary>
    function GetSound(const AIndex: Integer): AnsiString;
    /// <summary>
    ///   True, with a warning in the log for each one, if a sound of the shader is an OGG file (a shake needs the
    ///   amplitude of a PCM sample: the parse calls this when the shader shakes)
    /// </summary>
    function CheckShakesAndOgg: Boolean;
  end;

  /// <summary>
  ///   The sound cache as far as a shader needs it (<c>idSoundCache::FindSound</c>): finds the sample of a
  ///   name, loading it if the cache has to, and says what it is
  /// </summary>
  ISoundSampleCatalog = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A1121}']
    function FindSample(const AName: AnsiString): TSoundSampleInfo;
  end;

  /// <summary>The game file system as far as a shader needs it: does a file exist (<c>idFileSystem::ReadFile</c>)</summary>
  ISoundFileProbe = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A1122}']
    /// <summary>The size of the file in bytes, -1 if there is none</summary>
    function FileSize(const AName: AnsiString): Integer;
  end;

implementation

end.
