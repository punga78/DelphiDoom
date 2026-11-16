{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - the sample catalog that only names        }
{                                                                              }
{  Not derived from Doom 3 code: written for this repository (GPL v2 or        }
{  later). The name it makes is that of idSoundCache::FindSound.               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Sound.NameCatalog;

interface

uses
  DelphiDoom.Decl.Sound.Types, DelphiDoom.Decl.Sound.Intf;

type
  /// <summary>
  ///   The catalog a sound shader gets when nobody gives it the real sound cache: it canonicalizes the name as
  ///   <c>idSoundCache::FindSound</c> does (backslashes to slashes, lower case) and knows nothing else about the
  ///   sample: not OGG, not the default sound, no length
  /// </summary>
  TSoundSampleNameCatalog = class(TInterfacedObject, ISoundSampleCatalog)
  public
    function FindSample(const AName: AnsiString): TSoundSampleInfo;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Str, DelphiDoom.IdLib.Text.Strings;

{ TSoundSampleNameCatalog }

function TSoundSampleNameCatalog.FindSample(const AName: AnsiString): TSoundSampleInfo;
var
  LName: TIdStr;
begin
  LName := TIdStr.Create(AName);
  LName.BackSlashesToSlashes;
  Result := Default(TSoundSampleInfo);
  Result.Name := TIdStrings.ToLower(LName.Text);
end;

end.
