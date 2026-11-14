{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound shader declaration - parity with the real    }
{  C++                                                                         }
{                                                                              }
{  Runs Tests\Data\Decl\sound.input.txt with TDeclSound and compares the       }
{  output with sound.golden.txt, which is what the real snd_shader.cpp of      }
{  Doom 3 printed for the same file (see Tests\Data\Decl\README.md). Every     }
{  line is the same, floats included (they are written as their 32 bits).      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.SoundGolden;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Decl.Intf, DelphiDoom.Decl.Sound.Types, DelphiDoom.Decl.Sound.Intf, DelphiDoom.Tests.Decl.SoundSupport;

type
  /// <summary>
  ///   The interpreter of the cases: the same operations and output lines as the driver of the C++ harness
  ///   (<c>@decl sound</c>, <c>@op lang|maxsounds|building|file|list|default|freedata|reparse|shakes|deftext</c>)
  /// </summary>
  TSoundGoldenRunner = class
  strict private
    FLines: TStringList;
    FLog: IInterface;
    FCatalog: ISoundSampleCatalog;
    FProbe: TFakeSoundProbe;
    FProbeIntf: ISoundFileProbe;
    FFinder: TFakeSoundFinder;
    FFinderIntf: IDeclFinder;
    FOptions: TSoundShaderOptions;
    FObjects: TDictionary<string, IDecl>;
    FTexts: TDictionary<string, string>;
    procedure Emit(const ALine: string);
    class function Bits(const AValue: Single): string; static;
    class function Words(const AText: string): TArray<string>; static;
    procedure Dump(const ADecl: IDecl);
    procedure StartCase;
    procedure FlushDeclaration(const AName, AText: string);
    procedure Execute(const AOperation: string);
    procedure DefaultText(const AName: string);
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Runs every case of the text and returns the output lines</summary>
    function RunAll(const AInput: TStrings): TStringList;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestDeclSoundGolden = class
  strict private
    function DataFolder: string;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroIdSoundShader;
  end;

implementation

uses
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Base, DelphiDoom.Decl.Sound,
  DelphiDoom.Tests.Scanner.IdFakes, DelphiDoom.Tests.Decl.EffectsSupport;

{ TSoundGoldenRunner }

constructor TSoundGoldenRunner.Create;
begin
  inherited Create;
  FObjects := TDictionary<string, IDecl>.Create;
  FTexts := TDictionary<string, string>.Create;
end;

destructor TSoundGoldenRunner.Destroy;
begin
  FTexts.Free;
  FObjects.Free;
  inherited Destroy;
end;

procedure TSoundGoldenRunner.Emit(const ALine: string);
begin
  FLines.Add(ALine);
end;

class function TSoundGoldenRunner.Bits(const AValue: Single): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := IntToHex(PCardinal(@LValue)^, 8);
end;

class function TSoundGoldenRunner.Words(const AText: string): TArray<string>;
var
  LList: TStringList;
  LIndex: Integer;
begin
  LList := TStringList.Create;
  try
    LList.Delimiter := ' ';
    LList.StrictDelimiter := True;
    LList.DelimitedText := Trim(AText);
    SetLength(Result, LList.Count);
    for LIndex := 0 to LList.Count - 1 do
      Result[LIndex] := LList[LIndex];
  finally
    LList.Free;
  end;
end;

procedure TSoundGoldenRunner.StartCase;
begin
  FObjects.Clear;
  FTexts.Clear;
  FFinder.Clear;
  FProbe.Clear;
  FOptions := TSoundShaderOptions.Standard;
end;

procedure TSoundGoldenRunner.Dump(const ADecl: IDecl);
var
  LSound: IDeclSound;
  LAlt: IDeclSound;
  LAltDecl: IDecl;
  LParms: TSoundShaderParms;
  LIndex: Integer;
  LAltName: string;
begin
  Supports(ADecl, IDeclSound, LSound);
  LParms := LSound.GetParms;
  Emit(Format('sound %s desc=[%s] min=%s max=%s vol=%s shk=%s flags=%d class=%d n=%d def=%d',
    [string(ADecl.GetName), TFakeIdLibLog.Escape(LSound.GetDescription), Bits(LParms.MinDistance),
    Bits(LParms.MaxDistance), Bits(LParms.Volume), Bits(LParms.Shakes), LParms.SoundShaderFlags, LParms.SoundClass,
    LSound.GetNumSounds, Ord(LSound.HasDefaultSound)]));
  LAlt := LSound.GetAltSound;
  LAltName := '(null)';
  if Assigned(LAlt) and Supports(LAlt, IDecl, LAltDecl) then
    LAltName := string(LAltDecl.GetName);
  Emit(Format(' alt=%s dmin=%s dmax=%s mask=%d lead=%s', [LAltName, Bits(LSound.GetMinDistance),
    Bits(LSound.GetMaxDistance), LSound.GetSpeakerMask, Bits(LSound.GetLeadinVolume)]));
  for LIndex := -1 to LSound.GetNumSounds do
    Emit(Format(' snd[%d]=[%s]', [LIndex, TFakeIdLibLog.Escape(LSound.GetSound(LIndex))]));
end;

procedure TSoundGoldenRunner.FlushDeclaration(const AName, AText: string);
var
  LDecl: TDeclSound;
  LIntf: IDecl;
  LParsed: Boolean;
begin
  Emit('> decl sound ' + AName);
  LDecl := TDeclSound.Create(FCatalog, FProbeIntf, FOptions);
  LIntf := LDecl;
  TFakeDeclMaker.Attach(LDecl, DECL_SOUND, AnsiString(AName), FFinderIntf, FLog as IIdLibLog);
  LParsed := LDecl.Parse(AnsiString(AText));
  Emit(Format('ret=%d', [Ord(LParsed)]));
  FObjects.AddOrSetValue(AName, LIntf);
  FTexts.AddOrSetValue(AName, AText);
  FFinder.Add(AnsiString(AName), LIntf);
  Dump(LIntf);
end;

procedure TSoundGoldenRunner.DefaultText(const AName: string);
var
  LDecl: TDeclSound;
  LIntf: IDecl;
  LResult: Boolean;
begin
  LDecl := TDeclSound.Create(FCatalog, FProbeIntf, FOptions);
  LIntf := LDecl;
  TFakeDeclMaker.Attach(LDecl, DECL_SOUND, AnsiString(AName), FFinderIntf, FLog as IIdLibLog);
  LResult := LDecl.SetDefaultText;
  Emit(Format('deftext ret=%d len=%d text=%s', [Ord(LResult), LIntf.GetTextLength,
    TFakeIdLibLog.Escape(LIntf.GetText)]));
end;

procedure TSoundGoldenRunner.Execute(const AOperation: string);
var
  LWords: TArray<string>;
  LDecl: IDecl;
  LText: string;
  LParsed: Boolean;
  LSound: IDeclSound;
begin
  LWords := Words(AOperation);
  Emit('> ' + string.Join(' ', LWords));
  if LWords[0] = 'lang' then
  begin
    if Length(LWords) > 1 then
      FOptions.Language := AnsiString(LWords[1])
    else
      FOptions.Language := '';
  end
  else if LWords[0] = 'maxsounds' then
    FOptions.MaxSoundsPerShader := StrToInt(LWords[1])
  else if LWords[0] = 'building' then
    FOptions.MakingBuild := LWords[1] = '1'
  else if LWords[0] = 'file' then
    FProbe.Add(LWords[1], StrToInt(LWords[2]))
  else if LWords[0] = 'deftext' then
    DefaultText(LWords[1])
  else if LWords[0] = 'deftextrep' then
    DefaultText(LWords[1] + StringOfChar('a', StrToInt(LWords[2])))
  else
  begin
    FObjects.TryGetValue(LWords[1], LDecl);
    if LWords[0] = 'list' then
      LDecl.List
    else if LWords[0] = 'default' then
    begin
      LDecl.MakeDefault;
      Dump(LDecl);
    end
    else if LWords[0] = 'freedata' then
    begin
      (LDecl as TDeclSound).FreeData;
      Dump(LDecl);
    end
    else if LWords[0] = 'reparse' then
    begin
      if Length(LWords) > 2 then
        FTexts.TryGetValue(LWords[2], LText)
      else
        FTexts.TryGetValue(LWords[1], LText);
      LParsed := (LDecl as TDeclSound).Parse(AnsiString(LText));
      Emit(Format('ret=%d', [Ord(LParsed)]));
      Dump(LDecl);
    end
    else if LWords[0] = 'shakes' then
    begin
      Supports(LDecl, IDeclSound, LSound);
      Emit(Format('shakes ret=%d', [Ord(LSound.CheckShakesAndOgg)]));
    end;
  end;
end;

function TSoundGoldenRunner.RunAll(const AInput: TStrings): TStringList;
var
  LLine, LName, LText: string;
  LInDecl: Boolean;
  LLog: TFakeIdLibLog;
  LCatalog: TFakeSoundCatalog;

  procedure Flush;
  begin
    if LInDecl then
      FlushDeclaration(LName, LText);
    LInDecl := False;
  end;

begin
  Result := TStringList.Create;
  FLines := Result;
  LLog := TFakeIdLibLog.Create(Result);
  FLog := LLog;
  LCatalog := TFakeSoundCatalog.Create(Result);
  FCatalog := LCatalog;
  FProbe := TFakeSoundProbe.Create(Result);
  FProbeIntf := FProbe;
  FOptions := TSoundShaderOptions.Standard;
  FFinderIntf := TFakeSoundFinder.Create(Result, LLog, FCatalog, FProbeIntf, FOptions);
  FFinder := TFakeSoundFinder(FFinderIntf as TObject);
  LInDecl := False;
  try
    for LLine in AInput do
    begin
      if LLine.StartsWith('@case ') then
      begin
        Flush;
        StartCase;
        Emit('## ' + Copy(LLine, 7, MaxInt));
      end
      else if LLine = '@end' then
        Flush
      else if LLine.StartsWith('@decl ') then
      begin
        Flush;
        LName := Words(Copy(LLine, 7, MaxInt))[1];
        LText := 'sound ' + LName + #10;
        LInDecl := True;
      end
      else if LLine.StartsWith('@op ') then
      begin
        Flush;
        Execute(Copy(LLine, 5, MaxInt));
      end
      else if LInDecl then
        LText := LText + LLine + #10;
    end;
    Flush;
  finally
    // the declarations refer to the finder: let them go first
    FObjects.Clear;
    FFinder.Clear;
    FFinderIntf := nil;
    FFinder := nil;
    FProbeIntf := nil;
    FProbe := nil;
    FCatalog := nil;
    FLog := nil;
    FLines := nil;
  end;
end;

{ TTestDeclSoundGolden }

function TTestDeclSoundGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Decl\');
end;

procedure TTestDeclSoundGolden.DovrebbeDareLeStesseRisposteDelVeroIdSoundShader;
var
  LInput, LGolden, LActual: TStringList;
  LRunner: TSoundGoldenRunner;
  LIndex: Integer;
begin
  LInput := TStringList.Create;
  LGolden := TStringList.Create;
  LRunner := TSoundGoldenRunner.Create;
  LActual := nil;
  try
    LInput.LoadFromFile(DataFolder + 'sound.input.txt', TEncoding.ANSI);
    LGolden.LoadFromFile(DataFolder + 'sound.golden.txt', TEncoding.ANSI);
    LActual := LRunner.RunAll(LInput);
    for LIndex := 0 to LGolden.Count - 1 do
      if (LIndex >= LActual.Count) or (LGolden[LIndex] <> LActual[LIndex]) then
      begin
        LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.sound.actual.txt'));
        if LIndex < LActual.Count then
          Assert.Fail(Format('line %d: expected [%s] but got [%s]', [LIndex + 1, LGolden[LIndex], LActual[LIndex]]))
        else
          Assert.Fail(Format('line %d: expected [%s] but the output ended', [LIndex + 1, LGolden[LIndex]]));
      end;
    Assert.AreEqual(LGolden.Count, LActual.Count);
  finally
    LActual.Free;
    LRunner.Free;
    LGolden.Free;
    LInput.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclSoundGolden);

end.
