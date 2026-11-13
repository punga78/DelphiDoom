{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclSound, the "sound" declaration       }
{                                                                              }
{  Port of the sound shader of Doom 3 (id Software, GPL v3): sound\sound.h,    }
{  snd_shader.cpp (idSoundShader). Copyright (C) 1999-2011 id Software LLC,    }
{  a ZeniMax Media company.                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Sound;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Base, DelphiDoom.Decl.Sound.Types,
  DelphiDoom.Decl.Sound.Intf;

type
  /// <summary>
  ///   <c>sound name { description "text"  mindistance 2  maxdistance 20  volume -3  looping  sound/a.wav ... }</c>:
  ///   a sound shader (idSoundShader). The samples are found through the sound catalog and only their names and
  ///   what a shader asks of them are kept; the mixing, the emitters and the portals are not here.
  ///   <c>FreeData</c> empties the lists only (as the original: the parms, the description and the lead-in volume
  ///   stay until the next parse). The shader of <c>altSound</c> is held without counting, the manager owns it.
  /// </summary>
  TDeclSound = class(TDecl, IDeclSound)
  strict private
    FData: TSoundShaderData;
    FCatalog: ISoundSampleCatalog;
    FFiles: ISoundFileProbe;
    FOptions: TSoundShaderOptions;
    [weak] FAltSound: IDecl;
  public
    /// <summary>
    ///   <c>ACatalog</c> is the sound cache, <c>AFiles</c> (may be nil) the file system the language folders are
    ///   looked for in, <c>AOptions</c> the cvars
    /// </summary>
    constructor Create(const ACatalog: ISoundSampleCatalog; const AFiles: ISoundFileProbe;
      const AOptions: TSoundShaderOptions);
    function GetDescription: AnsiString;
    function GetMinDistance: Single;
    function GetMaxDistance: Single;
    function GetAltSound: IDeclSound;
    function HasDefaultSound: Boolean;
    function GetParms: TSoundShaderParms;
    function GetSpeakerMask: Integer;
    function GetLeadinVolume: Single;
    function GetNumSounds: Integer;
    function GetSound(const AIndex: Integer): AnsiString;
    function CheckShakesAndOgg: Boolean;
    /// <summary>
    ///   A name with no text is the shader of the sample of the same name: <c>sound name // IMPLICITLY GENERATED</c>
    ///   and the name with <c>.wav</c> added if it has no extension (a <c>.ogg</c> stays)
    /// </summary>
    function SetDefaultText: Boolean; override;
    function DefaultDefinition: AnsiString; override;
    function Parse(const AText: AnsiString): Boolean; override;
    procedure FreeData; override;
    function Size: NativeInt; override;
    /// <summary>idSoundShader::List: the line of the shader, the description and each sample with its length and size</summary>
    procedure List; override;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Strings, DelphiDoom.IdLib.Text.Str,
  DelphiDoom.Decl.Sound.Parser;

const
  // char generated[2048] of SetDefaultText (it keeps 2047 characters)
  GENERATED_TEXT_SIZE = 2048;
  // PRIMARYFREQ / 1000: 44100 samples a second
  SAMPLES_PER_MILLISECOND = 44;

{ TDeclSound }

constructor TDeclSound.Create(const ACatalog: ISoundSampleCatalog; const AFiles: ISoundFileProbe;
  const AOptions: TSoundShaderOptions);
begin
  inherited Create;
  FCatalog := ACatalog;
  FFiles := AFiles;
  FOptions := AOptions;
  FData := TSoundShaderData.Init;
end;

function TDeclSound.GetDescription: AnsiString;
begin
  Result := FData.Description;
end;

function TDeclSound.GetMinDistance: Single;
begin
  Result := FData.Parms.MinDistance;
end;

function TDeclSound.GetMaxDistance: Single;
begin
  Result := FData.Parms.MaxDistance;
end;

function TDeclSound.GetAltSound: IDeclSound;
begin
  if not Supports(FAltSound, IDeclSound, Result) then
    Result := nil;
end;

function TDeclSound.HasDefaultSound: Boolean;
var
  LSample: TSoundSampleInfo;
begin
  for LSample in FData.Entries do
    if LSample.IsDefault then
      Exit(True);
  Result := False;
end;

function TDeclSound.GetParms: TSoundShaderParms;
begin
  Result := FData.Parms;
end;

function TDeclSound.GetSpeakerMask: Integer;
begin
  Result := FData.SpeakerMask;
end;

function TDeclSound.GetLeadinVolume: Single;
begin
  Result := FData.LeadinVolume;
end;

function TDeclSound.GetNumSounds: Integer;
begin
  Result := Length(FData.Leadins) + Length(FData.Entries);
end;

function TDeclSound.GetSound(const AIndex: Integer): AnsiString;
begin
  Result := '';
  if AIndex < 0 then
    Exit;
  if AIndex < Length(FData.Leadins) then
    Exit(FData.Leadins[AIndex].Name);
  if AIndex - Length(FData.Leadins) < Length(FData.Entries) then
    Result := FData.Entries[AIndex - Length(FData.Leadins)].Name;
end;

function TDeclSound.CheckShakesAndOgg: Boolean;
var
  LLog: IIdLibLog;
  LSample: TSoundSampleInfo;

  procedure Check(const ASample: TSoundSampleInfo);
  begin
    if not ASample.IsOgg then
      Exit;
    if Assigned(LLog) then
      LLog.Warning(Format('sound shader ''%s'' has shakes and uses OGG file ''%s''',
        [string(GetName), string(ASample.Name)]));
    Result := True;
  end;

begin
  Result := False;
  LLog := GetLog;
  for LSample in FData.Leadins do
    Check(LSample);
  for LSample in FData.Entries do
    Check(LSample);
end;

function TDeclSound.SetDefaultText: Boolean;
var
  LName: TIdStr;
  LGenerated: AnsiString;
  LLog: IIdLibLog;
begin
  LName := TIdStr.Create(GetName);
  // if the name has .ogg in it, that will stay
  LName.DefaultFileExtension('.wav');
  LGenerated := 'sound ' + GetName + ' // IMPLICITLY GENERATED'#10'{'#10 + LName.Text + #10'}'#10;
  // idStr::snPrintf into a char[2048]: a longer text is cut and the log is told
  if Length(LGenerated) >= GENERATED_TEXT_SIZE then
  begin
    LLog := GetLog;
    if Assigned(LLog) then
      LLog.Warning(Format('idStr::snPrintf: overflow of %d in %d'#10, [Length(LGenerated), GENERATED_TEXT_SIZE]));
    SetLength(LGenerated, GENERATED_TEXT_SIZE - 1);
  end;
  SetText(LGenerated);
  Result := True;
end;

function TDeclSound.DefaultDefinition: AnsiString;
begin
  Result := '{'#10#9'_default.wav'#10'}';
end;

function TDeclSound.Parse(const AText: AnsiString): Boolean;
var
  LSource: TIdLexer;
  LParser: TSoundShaderParser;
  LAlt: IDecl;
  LParsed: Boolean;
begin
  LSource := OpenLexer(AText);
  try
    LParser := TSoundShaderParser.Create(GetFinder, FCatalog, FFiles, FOptions);
    try
      LParsed := LParser.ParseShader(LSource, FData, LAlt);
    finally
      LParser.Free;
    end;
  finally
    LSource.Free;
  end;
  FAltSound := LAlt;
  if not LParsed then
  begin
    MakeDefault;
    Exit(False);
  end;
  if FData.Parms.Shakes > 0 then
    CheckShakesAndOgg;
  Result := True;
end;

procedure TDeclSound.FreeData;
begin
  FData.Leadins := nil;
  FData.Entries := nil;
end;

function TDeclSound.Size: NativeInt;
begin
  Result := InstanceSize;
end;

procedure TDeclSound.List;
var
  LLog: IIdLibLog;
  LSample: TSoundSampleInfo;

  procedure Line(const ASample: TSoundSampleInfo; const ASuffix: string);
  begin
    LLog.Printf(Format('      %5dms %4dKb %s%s'#10, [ASample.Length44kHzSamples div SAMPLES_PER_MILLISECOND,
      ASample.MemorySize div 1024, string(ASample.Name), ASuffix]));
  end;

begin
  LLog := GetLog;
  if not Assigned(LLog) then
    Exit;
  LLog.Printf(Format('%4d: %s'#10, [GetIndex, string(GetName)]));
  if TIdStrings.Icmp(FData.Description, SOUND_NO_DESCRIPTION) <> 0 then
    LLog.Printf(Format('      description: %s'#10, [string(FData.Description)]));
  for LSample in FData.Leadins do
    Line(LSample, ' (LEADIN)');
  for LSample in FData.Entries do
    Line(LSample, '');
end;

end.
