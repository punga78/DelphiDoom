{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - the reading of a sound shader             }
{                                                                              }
{  Port of the sound shader of Doom 3 (id Software, GPL v3): sound\            }
{  snd_shader.cpp (idSoundShader::ParseShader). Copyright (C) 1999-2011 id     }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Sound.Parser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Sound.Types,
  DelphiDoom.Decl.Sound.Intf;

type
  /// <summary>
  ///   <c>idSoundShader::ParseShader</c>: the words of the body of a sound shader, from the first word after the
  ///   brace to the closing one. The lookups of the original go through what the constructor gets: the sound cache
  ///   (<c>ISoundSampleCatalog</c>), the file system (<c>ISoundFileProbe</c>, may be nil: no file exists), the cvars
  ///   (<c>TSoundShaderOptions</c>) and the declaration manager (<c>IDeclFinder</c>, for <c>altSound</c>)
  /// </summary>
  TSoundShaderParser = class
  strict private
    FFinder: IDeclFinder;
    FCatalog: ISoundSampleCatalog;
    FFiles: ISoundFileProbe;
    FOptions: TSoundShaderOptions;
    /// <summary>The sample of a word that names a .wav or an .ogg, in the language folder if there is one</summary>
    function FindSample(const AToken: AnsiString): TSoundSampleInfo;
  public
    constructor Create(const AFinder: IDeclFinder; const ACatalog: ISoundSampleCatalog;
      const AFiles: ISoundFileProbe; const AOptions: TSoundShaderOptions);
    /// <summary>
    ///   Reads the shader into <c>AData</c> (the defaults of the parms, the lists emptied; the description and the
    ///   lead-in volume keep what they had, as in the original) and sets <c>AAltSound</c> to the shader of
    ///   <c>altSound</c> or nil. False after a warning if a word is wrong or the text ends: the caller makes the
    ///   shader default
    /// </summary>
    function ParseShader(const ASource: TIdLexer; var AData: TSoundShaderData; out AAltSound: IDecl): Boolean;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Types, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.IdLib.Text.Str, DelphiDoom.Decl.Types;

{ TSoundShaderParser }

constructor TSoundShaderParser.Create(const AFinder: IDeclFinder; const ACatalog: ISoundSampleCatalog;
  const AFiles: ISoundFileProbe; const AOptions: TSoundShaderOptions);
begin
  inherited Create;
  FFinder := AFinder;
  FCatalog := ACatalog;
  FFiles := AFiles;
  FOptions := AOptions;
end;

function TSoundShaderParser.FindSample(const AToken: AnsiString): TSoundSampleInfo;
var
  LToken: TIdStr;
  LWork: TIdStr;
  LName: AnsiString;
begin
  LToken := TIdStr.Create(AToken);
  LToken.BackSlashesToSlashes;
  LName := LToken.Text;
  if (TIdStrings.Icmp(FOptions.Language, 'english') <> 0) and (LToken.Find('sound/vo/', False) >= 0) then
  begin
    LWork := LToken;
    LWork.Text := TIdStrings.ToLower(LWork.Text);
    LWork.StripLeading('sound/vo/');
    LWork := TIdStr.Create(AnsiString(Format('sound/vo/%s/%s', [string(FOptions.Language), string(LWork.Text)])));
    if Assigned(FFiles) and (FFiles.FileSize(LWork.Text) > 0) then
      LName := LWork.Text
    else
    begin
      // also try to find it with the .ogg extension
      LWork.SetFileExtension('.ogg');
      if Assigned(FFiles) and (FFiles.FileSize(LWork.Text) > 0) then
        LName := LWork.Text;
    end;
  end;
  Result := FCatalog.FindSample(LName);
end;

function TSoundShaderParser.ParseShader(const ASource: TIdLexer; var AData: TSoundShaderData;
  out AAltSound: IDecl): Boolean;
var
  LToken: TIdToken;
  LMaxSamples: Integer;
  LText: AnsiString;

  procedure AddSample(var AList: TArray<TSoundSampleInfo>; const AInfo: TSoundSampleInfo);
  begin
    // the original writes the 33rd sample over the end of the array (minSamples above 32); here it is not kept
    if Length(AList) < SOUND_MAX_LIST_WAVS then
    begin
      SetLength(AList, Length(AList) + 1);
      AList[High(AList)] := AInfo;
    end;
  end;

  function IsWord(const AWord: AnsiString): Boolean;
  begin
    Result := TIdStrings.Icmp(LToken.Text, AWord) = 0;
  end;

  procedure SetFlag(const AFlag: Integer);
  begin
    AData.Parms.SoundShaderFlags := AData.Parms.SoundShaderFlags or AFlag;
  end;

  procedure SetSpeaker(const ASpeaker: Integer);
  begin
    AData.SpeakerMask := AData.SpeakerMask or (1 shl ASpeaker);
  end;

begin
  LToken := TIdToken.Create;
  AAltSound := nil;
  AData.Parms.MinDistance := 1;
  AData.Parms.MaxDistance := 10;
  AData.Parms.Volume := 1;
  AData.Parms.Shakes := 0;
  AData.Parms.SoundShaderFlags := 0;
  AData.Parms.SoundClass := 0;
  AData.SpeakerMask := 0;
  AData.Leadins := nil;
  AData.Entries := nil;

  LMaxSamples := FOptions.MaxSoundsPerShader;
  if FOptions.MakingBuild or (LMaxSamples <= 0) or (LMaxSamples > SOUND_MAX_LIST_WAVS) then
    LMaxSamples := SOUND_MAX_LIST_WAVS;

  while True do
  begin
    if not ASource.ExpectAnyToken(LToken) then
      Exit(False);
    // end of definition
    if LToken.IsText('}') then
      Break
    // minimum number of sounds
    else if IsWord('minSamples') then
      LMaxSamples := TIdMath.ClampInt(ASource.ParseInt, SOUND_MAX_LIST_WAVS, LMaxSamples)
    else if IsWord('description') then
    begin
      ASource.ReadTokenOnLine(LToken);
      AData.Description := LToken.Text;
    end
    else if IsWord('mindistance') then
      AData.Parms.MinDistance := ASource.ParseFloat
    else if IsWord('maxdistance') then
      AData.Parms.MaxDistance := ASource.ParseFloat
    // shakes screen
    else if IsWord('shakes') then
    begin
      ASource.ExpectAnyToken(LToken);
      if LToken.TokenType = TT_NUMBER then
        AData.Parms.Shakes := LToken.GetFloatValue
      else
      begin
        ASource.UnreadToken(LToken);
        AData.Parms.Shakes := 1.0;
      end;
    end
    // reverb: two numbers separated by a comma, no longer supported
    else if IsWord('reverb') then
    begin
      ASource.ParseFloat;
      if not ASource.ExpectTokenString(',') then
      begin
        ASource.FreeSource;
        Exit(False);
      end;
      ASource.ParseFloat;
    end
    else if IsWord('volume') then
      AData.Parms.Volume := ASource.ParseFloat
    // leadinVolume allows light breaking leadin sounds to be much louder than the broken loop
    else if IsWord('leadinVolume') then
      AData.LeadinVolume := ASource.ParseFloat
    else if IsWord('mask_center') then
      SetSpeaker(SPEAKER_CENTER)
    else if IsWord('mask_left') then
      SetSpeaker(SPEAKER_LEFT)
    else if IsWord('mask_right') then
      SetSpeaker(SPEAKER_RIGHT)
    else if IsWord('mask_backright') then
      SetSpeaker(SPEAKER_BACKRIGHT)
    else if IsWord('mask_backleft') then
      SetSpeaker(SPEAKER_BACKLEFT)
    else if IsWord('mask_lfe') then
      SetSpeaker(SPEAKER_LFE)
    else if IsWord('soundClass') then
    begin
      AData.Parms.SoundClass := ASource.ParseInt;
      if (AData.Parms.SoundClass < 0) or (AData.Parms.SoundClass >= SOUND_MAX_CLASSES) then
      begin
        ASource.Warning('SoundClass out of range', []);
        Exit(False);
      end;
    end
    else if IsWord('altSound') then
    begin
      if not ASource.ExpectAnyToken(LToken) then
        Exit(False);
      AAltSound := FFinder.FindType(DECL_SOUND, LToken.Text);
    end
    // no longer supported: ordered, plain, onDemand
    else if IsWord('ordered') or IsWord('plain') or IsWord('onDemand') then
    begin
    end
    else if IsWord('no_dups') then
      SetFlag(SSF_NO_DUPS)
    else if IsWord('no_flicker') then
      SetFlag(SSF_NO_FLICKER)
    else if IsWord('looping') then
      SetFlag(SSF_LOOPING)
    else if IsWord('no_occlusion') then
      SetFlag(SSF_NO_OCCLUSION)
    else if IsWord('private') then
      SetFlag(SSF_PRIVATE_SOUND)
    else if IsWord('antiPrivate') then
      SetFlag(SSF_ANTI_PRIVATE_SOUND)
    else if IsWord('playonce') then
      SetFlag(SSF_PLAY_ONCE)
    else if IsWord('global') then
      SetFlag(SSF_GLOBAL)
    else if IsWord('unclamped') then
      SetFlag(SSF_UNCLAMPED)
    else if IsWord('omnidirectional') then
      SetFlag(SSF_OMNIDIRECTIONAL)
    // the wave files
    else if IsWord('leadin') then
    begin
      // add to the leadin list
      if not ASource.ReadToken(LToken) then
      begin
        ASource.Warning('Expected sound after leadin', []);
        Exit(False);
      end;
      if Length(AData.Leadins) < LMaxSamples then
        AddSample(AData.Leadins, FCatalog.FindSample(LToken.Text));
    end
    else
    begin
      LText := LToken.Text;
      if (TIdStr.Create(LText).Find('.wav', False) >= 0) or (TIdStr.Create(LText).Find('.ogg', False) >= 0) then
      begin
        // add to the wav list
        if Length(AData.Entries) < LMaxSamples then
          AddSample(AData.Entries, FindSample(LText));
      end
      else
      begin
        ASource.Warning('unknown token ''%s''', [string(LText)]);
        Exit(False);
      end;
    end;
  end;
  Result := True;
end;

end.
