{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound shader declaration - fakes                   }
{                                                                              }
{  A sound cache, a file system and a finder written by hand. The sample the   }
{  cache makes for a name is the one of the C++ harness (see Tests\Data\Decl\  }
{  README.md): every call is written down as the harness writes it.            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.SoundSupport;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Intf,
  DelphiDoom.Decl.Sound.Types, DelphiDoom.Decl.Sound.Intf;

type
  /// <summary>
  ///   The sound cache of the harness: the name is made canonical, and the sample has a length of
  ///   <c>1000 + 37 * sum of the bytes</c> samples (scaled by the rate: "11k" in the name is 11025 Hz, "22k" 22050 Hz),
  ///   is OGG when ".ogg" is in the name, is the default sound when "_default" is, and takes
  ///   <c>2 * length + 1024 * (sum mod 7)</c> bytes. Each call is written down as <c>S name</c> if there are lines
  /// </summary>
  TFakeSoundCatalog = class(TInterfacedObject, ISoundSampleCatalog)
  strict private
    FLines: TStrings;
    FRequests: TStringList;
  public
    constructor Create(const ALines: TStrings = nil);
    destructor Destroy; override;
    function FindSample(const AName: AnsiString): TSoundSampleInfo;
    /// <summary>The names as the shader passed them</summary>
    property Requests: TStringList read FRequests;
  end;

  /// <summary>The files of a case with their sizes; each question is written down as <c>R name</c> if there are lines</summary>
  TFakeSoundProbe = class(TInterfacedObject, ISoundFileProbe)
  strict private
    FLines: TStrings;
    FFiles: TDictionary<string, Integer>;
  public
    constructor Create(const ALines: TStrings = nil);
    destructor Destroy; override;
    function FileSize(const AName: AnsiString): Integer;
    procedure Add(const AName: string; const ASize: Integer);
    procedure Clear;
  end;

  /// <summary>
  ///   The declaration manager of the harness: a shader that was registered, or a bare one for any other name that
  ///   is asked for (never parsed); each call is written down as <c>F type name make</c> if there are lines.
  ///   Only sound shaders (the type of <c>altSound</c>)
  /// </summary>
  TFakeSoundFinder = class(TInterfacedObject, IDeclFinder)
  strict private
    FDecls: TDictionary<string, IDecl>;
    FReplaced: TList<IDecl>;
    FLines: TStrings;
    FLog: IIdLibLog;
    FCatalog: ISoundSampleCatalog;
    FProbe: ISoundFileProbe;
    FOptions: TSoundShaderOptions;
  public
    constructor Create(const ALines: TStrings; const ALog: IIdLibLog; const ACatalog: ISoundSampleCatalog;
      const AProbe: ISoundFileProbe; const AOptions: TSoundShaderOptions);
    destructor Destroy; override;
    function FindType(const AType: Integer; const AName: AnsiString; const AMakeDefault: Boolean = True): IDecl;
    function FindDeclWithoutParsing(const AType: Integer; const AName: AnsiString;
      const AMakeDefault: Boolean = True): IDecl;
    function GetNumDecls(const AType: Integer): Integer;
    function DeclByIndex(const AType, AIndex: Integer; const AForceParse: Boolean = True): IDecl;
    procedure Add(const AName: AnsiString; const ADecl: IDecl);
    procedure Clear;
  end;

implementation

uses
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Base, DelphiDoom.Decl.Sound, DelphiDoom.Tests.Decl.EffectsSupport;

{ TFakeSoundCatalog }

constructor TFakeSoundCatalog.Create(const ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
  FRequests := TStringList.Create;
end;

destructor TFakeSoundCatalog.Destroy;
begin
  FRequests.Free;
  inherited Destroy;
end;

function TFakeSoundCatalog.FindSample(const AName: AnsiString): TSoundSampleInfo;
var
  LName: AnsiString;
  LIndex: Integer;
  LSum: Integer;
  LSize: Integer;
begin
  FRequests.Add(string(AName));
  if Assigned(FLines) then
    FLines.Add('S ' + string(AName));
  LName := AnsiString(LowerCase(StringReplace(string(AName), '\', '/', [rfReplaceAll])));
  LSum := 0;
  for LIndex := 1 to Length(LName) do
    Inc(LSum, Byte(LName[LIndex]));
  LSize := 1000 + LSum * 37;
  Result.Name := LName;
  Result.IsOgg := Pos('.ogg', string(LName)) > 0;
  Result.IsDefault := Pos('_default', string(LName)) > 0;
  if Pos('11k', string(LName)) > 0 then
    Result.Length44kHzSamples := LSize shl 2
  else if Pos('22k', string(LName)) > 0 then
    Result.Length44kHzSamples := LSize shl 1
  else
    Result.Length44kHzSamples := LSize;
  Result.MemorySize := LSize * 2 + (LSum mod 7) * 1024;
end;

{ TFakeSoundProbe }

constructor TFakeSoundProbe.Create(const ALines: TStrings);
begin
  inherited Create;
  FLines := ALines;
  FFiles := TDictionary<string, Integer>.Create;
end;

destructor TFakeSoundProbe.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

function TFakeSoundProbe.FileSize(const AName: AnsiString): Integer;
begin
  if Assigned(FLines) then
    FLines.Add('R ' + string(AName));
  if not FFiles.TryGetValue(LowerCase(string(AName)), Result) then
    Result := -1;
end;

procedure TFakeSoundProbe.Add(const AName: string; const ASize: Integer);
begin
  FFiles.AddOrSetValue(LowerCase(AName), ASize);
end;

procedure TFakeSoundProbe.Clear;
begin
  FFiles.Clear;
end;

{ TFakeSoundFinder }

constructor TFakeSoundFinder.Create(const ALines: TStrings; const ALog: IIdLibLog; const ACatalog: ISoundSampleCatalog;
  const AProbe: ISoundFileProbe; const AOptions: TSoundShaderOptions);
begin
  inherited Create;
  FDecls := TDictionary<string, IDecl>.Create;
  FReplaced := TList<IDecl>.Create;
  FLines := ALines;
  FLog := ALog;
  FCatalog := ACatalog;
  FProbe := AProbe;
  FOptions := AOptions;
end;

destructor TFakeSoundFinder.Destroy;
begin
  FReplaced.Free;
  FDecls.Free;
  inherited Destroy;
end;

procedure TFakeSoundFinder.Add(const AName: AnsiString; const ADecl: IDecl);
var
  LOld: IDecl;
begin
  // a shader that is replaced stays alive, as the one of the harness does (altSound of a shader to itself)
  if FDecls.TryGetValue(LowerCase(string(AName)), LOld) then
    FReplaced.Add(LOld);
  FDecls.AddOrSetValue(LowerCase(string(AName)), ADecl);
end;

procedure TFakeSoundFinder.Clear;
begin
  FDecls.Clear;
  FReplaced.Clear;
end;

function TFakeSoundFinder.FindType(const AType: Integer; const AName: AnsiString; const AMakeDefault: Boolean): IDecl;
var
  LDecl: TDeclSound;
begin
  if Assigned(FLines) then
    FLines.Add(Format('F %d %s %d', [AType, string(AName), Ord(AMakeDefault)]));
  if FDecls.TryGetValue(LowerCase(string(AName)), Result) then
    Exit;
  if not AMakeDefault then
    Exit(nil);
  LDecl := TDeclSound.Create(FCatalog, FProbe, FOptions);
  Result := LDecl;
  TFakeDeclMaker.Attach(LDecl, AType, AName, Self, FLog);
  FDecls.Add(LowerCase(string(AName)), Result);
end;

function TFakeSoundFinder.FindDeclWithoutParsing(const AType: Integer; const AName: AnsiString;
  const AMakeDefault: Boolean): IDecl;
begin
  Result := FindType(AType, AName, AMakeDefault);
end;

function TFakeSoundFinder.GetNumDecls(const AType: Integer): Integer;
begin
  Result := FDecls.Count;
end;

function TFakeSoundFinder.DeclByIndex(const AType, AIndex: Integer; const AForceParse: Boolean): IDecl;
begin
  Result := nil;
end;

end.
