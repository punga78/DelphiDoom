{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - TEfxEffectsFile, the reader of .efx files       }
{                                                                              }
{  Port of the EFX file of Doom 3 (id Software, GPL v3): sound\snd_efxfile.cpp }
{  (idEFXFile). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Efx.EffectsFile;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Audio.Efx.Types;

type
  /// <summary>
  ///   An <c>.efx</c> file: <c>Version 1</c> and then <c>reverb name { "room" -1000 "decay time" 1.49 ... }</c> blocks, the
  ///   keys quoted (many have a space in them). Only reverb effects exist. The file comes from the
  ///   <c>IIdLibFileSystem</c> given to the constructor (the game folders or a path of the operating system).
  ///   <para>A word the reader does not expect is an error of the lexer, and as in the original (it is
  ///   <c>common->Error</c>, the flag <c>LEXFL_NOERRORS</c> is not set) it is an <c>EIdLexerException</c> with the file
  ///   name and the line: the effects read before it stay in the list, the one it was reading is lost.</para>
  /// </summary>
  TEfxEffectsFile = class
  strict private
    FFileSystem: IIdLibFileSystem;
    FLog: IIdLibLog;
    FEffects: TArray<TEfxEffect>;
    function ReadParameter(const ASource: TIdLexer; const AKey: AnsiString; var AReverb: TEfxReverbProperties): Boolean;
    function GetCount: Integer;
    function GetEffect(const AIndex: Integer): TEfxEffect;
  public
    constructor Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog);
    /// <summary>
    ///   idEFXFile::LoadFile: false if the file is not there or empty of a version; the effects are added to the ones
    ///   already loaded (call <c>UnloadFile</c> first to start again)
    /// </summary>
    function LoadFile(const AFileName: AnsiString; const AIsOsPath: Boolean = False): Boolean;
    /// <summary>
    ///   idEFXFile::ReadEffect: the next effect of the lexer. False if the text ends (or, with a lexer that does
    ///   not raise its errors, if the effect is wrong: the original goes on reading from a block it has freed)
    /// </summary>
    function ReadEffect(const ASource: TIdLexer; out AEffect: TEfxEffect): Boolean;
    /// <summary>idEFXFile::FindEffect: the first effect with the name (case sensitive); false if there is none</summary>
    function FindEffect(const AName: AnsiString; out AEffect: TEfxEffect; out AIndex: Integer): Boolean;
    /// <summary>idEFXFile::UnloadFile (and Clear): forgets the effects</summary>
    procedure UnloadFile;
    property Count: Integer read GetCount;
    property Effects[const AIndex: Integer]: TEfxEffect read GetEffect; default;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types;

const
  SEfxVersion = 'Version';
  SEfxUnknownVersion = 'idEFXFile::LoadFile: Unknown file version';
  SEfxNoBrace = 'idEFXFile::ReadEffect: { not found, found %s';
  SEfxNoEnd = 'idEFXFile::ReadEffect: EOF without closing brace';
  SEfxInvalidParameter = 'idEFXFile::ReadEffect: Invalid parameter in reverb definition';
  SEfxUnknownEffect = 'idEFXFile::ReadEffect: Unknown effect definition';

{ TEfxEffectsFile }

constructor TEfxEffectsFile.Create(const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  FLog := ALog;
end;

function TEfxEffectsFile.GetCount: Integer;
begin
  Result := Length(FEffects);
end;

function TEfxEffectsFile.GetEffect(const AIndex: Integer): TEfxEffect;
begin
  Result := FEffects[AIndex];
end;

procedure TEfxEffectsFile.UnloadFile;
begin
  FEffects := nil;
end;

function TEfxEffectsFile.FindEffect(const AName: AnsiString; out AEffect: TEfxEffect; out AIndex: Integer): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FEffects) do
    if FEffects[LIndex].Name = AName then
    begin
      AEffect := FEffects[LIndex];
      AIndex := LIndex;
      Exit(True);
    end;
  AEffect := Default(TEfxEffect);
  AIndex := -1;
  Result := False;
end;

function TEfxEffectsFile.ReadParameter(const ASource: TIdLexer; const AKey: AnsiString;
  var AReverb: TEfxReverbProperties): Boolean;
var
  LToken: TIdToken;

  function IsKey(const AWord: AnsiString): Boolean;
  begin
    Result := AKey = AWord;
  end;

  procedure ReadVector(var AVector: TEfxVector);
  begin
    AVector.X := ASource.ParseFloat;
    AVector.Y := ASource.ParseFloat;
    AVector.Z := ASource.ParseFloat;
  end;

begin
  Result := True;
  LToken := TIdToken.Create;
  if IsKey('environment') then
  begin
    ASource.ReadTokenOnLine(LToken);
    AReverb.Environment := LToken.GetUnsignedLongValue;
  end
  else if IsKey('environment size') then
    AReverb.EnvironmentSize := ASource.ParseFloat
  else if IsKey('environment diffusion') then
    AReverb.EnvironmentDiffusion := ASource.ParseFloat
  else if IsKey('room') then
    AReverb.Room := ASource.ParseInt
  else if IsKey('room hf') then
    AReverb.RoomHF := ASource.ParseInt
  else if IsKey('room lf') then
    AReverb.RoomLF := ASource.ParseInt
  else if IsKey('decay time') then
    AReverb.DecayTime := ASource.ParseFloat
  else if IsKey('decay hf ratio') then
    AReverb.DecayHFRatio := ASource.ParseFloat
  else if IsKey('decay lf ratio') then
    AReverb.DecayLFRatio := ASource.ParseFloat
  else if IsKey('reflections') then
    AReverb.Reflections := ASource.ParseInt
  else if IsKey('reflections delay') then
    AReverb.ReflectionsDelay := ASource.ParseFloat
  else if IsKey('reflections pan') then
    ReadVector(AReverb.ReflectionsPan)
  else if IsKey('reverb') then
    AReverb.Reverb := ASource.ParseInt
  else if IsKey('reverb delay') then
    AReverb.ReverbDelay := ASource.ParseFloat
  else if IsKey('reverb pan') then
    ReadVector(AReverb.ReverbPan)
  else if IsKey('echo time') then
    AReverb.EchoTime := ASource.ParseFloat
  else if IsKey('echo depth') then
    AReverb.EchoDepth := ASource.ParseFloat
  else if IsKey('modulation time') then
    AReverb.ModulationTime := ASource.ParseFloat
  else if IsKey('modulation depth') then
    AReverb.ModulationDepth := ASource.ParseFloat
  else if IsKey('air absorption hf') then
    AReverb.AirAbsorptionHF := ASource.ParseFloat
  else if IsKey('hf reference') then
    AReverb.HFReference := ASource.ParseFloat
  else if IsKey('lf reference') then
    AReverb.LFReference := ASource.ParseFloat
  else if IsKey('room rolloff factor') then
    AReverb.RoomRolloffFactor := ASource.ParseFloat
  else if IsKey('flags') then
  begin
    ASource.ReadTokenOnLine(LToken);
    AReverb.Flags := LToken.GetUnsignedLongValue;
  end
  else
  begin
    ASource.ReadTokenOnLine(LToken);
    ASource.Error(SEfxInvalidParameter, []);
    Result := False;
  end;
end;

function TEfxEffectsFile.ReadEffect(const ASource: TIdLexer; out AEffect: TEfxEffect): Boolean;
var
  LToken: TIdToken;
  LName: AnsiString;
  LReverb: TEfxReverbProperties;
begin
  AEffect := Default(TEfxEffect);
  LToken := TIdToken.Create;
  if not ASource.ReadToken(LToken) then
    Exit(False);

  // reverb effect
  if LToken.IsText('reverb') then
  begin
    ASource.ReadTokenOnLine(LToken);
    LName := LToken.Text;

    if not ASource.ReadToken(LToken) then
      Exit(False);

    if not LToken.IsText('{') then
    begin
      ASource.Error(SEfxNoBrace, [string(LToken.Text)]);
      Exit(False);
    end;

    LReverb := Default(TEfxReverbProperties);
    while True do
    begin
      if not ASource.ReadToken(LToken) then
      begin
        ASource.Error(SEfxNoEnd, []);
        Exit(False);
      end;

      if LToken.IsText('}') then
      begin
        AEffect.Name := LName;
        AEffect.Reverb := LReverb;
        Exit(True);
      end;

      if not ReadParameter(ASource, LToken.Text, LReverb) then
        Exit(False);
    end;
  end;

  // other effect (not supported at the moment)
  ASource.Error(SEfxUnknownEffect, []);
  Result := False;
end;

function TEfxEffectsFile.LoadFile(const AFileName: AnsiString; const AIsOsPath: Boolean): Boolean;
var
  LSource: TIdLexer;
  LEffect: TEfxEffect;
begin
  LSource := TIdLexer.Create(LEXFL_NOSTRINGCONCAT, FLog, FFileSystem);
  try
    if not LSource.LoadFile(AFileName, AIsOsPath) then
      Exit(False);

    if not LSource.ExpectTokenString(SEfxVersion) then
      Exit(False);

    if LSource.ParseInt <> 1 then
    begin
      LSource.Error(SEfxUnknownVersion, []);
      Exit(False);
    end;

    while not LSource.EndOfFile do
      if ReadEffect(LSource, LEffect) then
      begin
        SetLength(FEffects, Length(FEffects) + 1);
        FEffects[High(FEffects)] := LEffect;
      end;
  finally
    LSource.Free;
  end;
  Result := True;
end;

end.
