{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - the sound cache for the sound shaders     }
{                                                                              }
{  Not derived from Doom 3 code: written for this repository (GPL v2 or       }
{  later). It connects the sound shader (ISoundSampleCatalog) to the sound     }
{  cache of Framework\Audio and the sound file probe to the file system.       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Sound.CacheCatalog;

interface

uses
  System.SysUtils, DelphiDoom.Decl.Sound.Types, DelphiDoom.Decl.Sound.Intf, DelphiDoom.Audio.SoundSample.Types,
  DelphiDoom.Audio.SoundSample.Cache,
  DelphiDoom.Audio.WaveFile.Intf;

type
  /// <summary>
  ///   <c>ISoundSampleCatalog</c> on the sound cache (<c>idSoundCache::FindSound</c>): the sample a shader names is
  ///   loaded (or becomes the default sound, with the warning of the original) and the shader gets its snapshot:
  ///   name, OGG or not, default or not, length in 44 kHz samples and memory size. The cache is not owned
  /// </summary>
  TSoundCacheCatalog = class(TInterfacedObject, ISoundSampleCatalog)
  strict private
    FCache: TSoundSampleCache;
  public
    constructor Create(ACache: TSoundSampleCache);
    function FindSample(const AName: AnsiString): TSoundSampleInfo;
  end;

  /// <summary>
  ///   <c>ISoundFileProbe</c> on the file system of a wave file: the size of a file, -1 if there is none
  ///   (<c>idFileSystem::ReadFile(name, NULL, NULL)</c>)
  /// </summary>
  TSoundFileSystemProbe = class(TInterfacedObject, ISoundFileProbe)
  strict private
    FFileSystem: IWaveFileSystem;
  public
    constructor Create(const AFileSystem: IWaveFileSystem);
    function FileSize(const AName: AnsiString): Integer;
  end;

implementation

{ TSoundCacheCatalog }

constructor TSoundCacheCatalog.Create(ACache: TSoundSampleCache);
begin
  inherited Create;
  FCache := ACache;
end;

function TSoundCacheCatalog.FindSample(const AName: AnsiString): TSoundSampleInfo;
var
  LSample: TSoundSample;
begin
  LSample := FCache.FindSound(string(AName));
  Result := Default(TSoundSampleInfo);
  Result.Name := AnsiString(LSample.Name);
  Result.IsOgg := LSample.IsOgg;
  Result.IsDefault := LSample.IsDefault;
  Result.Length44kHzSamples := LSample.Length44kHzSamples;
  Result.MemorySize := LSample.MemorySize;
end;

{ TSoundFileSystemProbe }

constructor TSoundFileSystemProbe.Create(const AFileSystem: IWaveFileSystem);
begin
  inherited Create;
  FFileSystem := AFileSystem;
end;

function TSoundFileSystemProbe.FileSize(const AName: AnsiString): Integer;
begin
  Result := FFileSystem.FileLength(string(AName));
end;

end.
