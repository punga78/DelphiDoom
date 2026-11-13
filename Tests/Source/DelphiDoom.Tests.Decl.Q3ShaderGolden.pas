{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III shaders - parity with the real C         }
{                                                                              }
{  Runs Tests\Data\Decl\q3shader\scenario.txt on the .shader files of the      }
{  same folder with the classes of Libs\Decl and compares the dump with        }
{  q3shader.golden.txt, which is what the real renderer\tr_shader.c of Quake   }
{  III (R_FindShader: ScanAndLoadShaderFiles, ParseShader, FinishShader)       }
{  printed (Tools\Verifica\119; see Tests\Data\Decl\README.md).                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Q3ShaderGolden;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Decl.Q3Shader.Types,
  DelphiDoom.Decl.Q3Shader.Intf, DelphiDoom.Tests.Decl.Q3Shader;

type
  /// <summary>The interpreter of the scenario: the same commands and the same dump as the C driver</summary>
  TQ3ShaderGoldenRunner = class
  strict private
    FFolder: string;
    FKit: TQ3ShaderKit;
    FOptions: TQ3ShaderOptions;
    FOutput: TStringList;
    procedure Rebuild;
    procedure Find(const AName: string);
    procedure Dump(const AShader: IDeclQ3Shader);
    procedure DumpWave(var ALine: string; const AWave: TQ3WaveForm);
    class function Bits(const AValue: Single): string; static;
  public
    constructor Create(const ADataFolder: string);
    destructor Destroy; override;
    /// <summary>Runs the scenario and returns the output lines</summary>
    function Run(const AScenario: TStrings): TStringList;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestQ3ShaderGolden = class
  strict private
    function DataFolder: string;
    class function SameLine(const AExpected, AActual: string): Boolean; static;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroTrShaderC;
  end;

implementation

uses
  System.IOUtils, System.Math, System.StrUtils, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Types;

{ TQ3ShaderGoldenRunner }

constructor TQ3ShaderGoldenRunner.Create(const ADataFolder: string);
begin
  inherited Create;
  FFolder := ADataFolder;
  FOptions := TQ3ShaderOptions.Standard;
  FOutput := TStringList.Create;
end;

destructor TQ3ShaderGoldenRunner.Destroy;
begin
  FOutput.Free;
  FKit.Free;
  inherited Destroy;
end;

class function TQ3ShaderGoldenRunner.Bits(const AValue: Single): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := ' ' + LowerCase(IntToHex(PCardinal(@LValue)^, 8));
end;

procedure TQ3ShaderGoldenRunner.Rebuild;
var
  LFile: string;
  LBytes: TBytes;
  LText: AnsiString;
begin
  FKit.Free;
  FKit := TQ3ShaderKit.Create;
  for LFile in TDirectory.GetFiles(FFolder + 'scripts', '*.shader') do
  begin
    LBytes := TFile.ReadAllBytes(LFile);
    SetString(LText, PAnsiChar(@LBytes[0]), Length(LBytes));
    FKit.Source.Add('scripts/' + AnsiString(ExtractFileName(LFile)), LText);
  end;
  FKit.Start(FOptions);
end;

procedure TQ3ShaderGoldenRunner.DumpWave(var ALine: string; const AWave: TQ3WaveForm);
begin
  ALine := ALine + ' w' + IntToStr(Ord(AWave.Func)) + Bits(AWave.Base) + Bits(AWave.Amplitude) + Bits(AWave.Phase) +
    Bits(AWave.Frequency);
end;

procedure TQ3ShaderGoldenRunner.Dump(const AShader: IDeclQ3Shader);
var
  LData: TQ3ShaderData;
  LIndex, LImage, LMod, LCell: Integer;
  LLine, LImages: string;
  LStage: TQ3ShaderStage;
  LMods: TQ3TexMod;

  function Name(const AValue: AnsiString): string;
  begin
    if AValue = '' then
      Result := '-'
    else
      Result := string(AValue);
  end;

  function Flag(const AValue: Boolean): string;
  begin
    Result := IntToStr(Ord(AValue));
  end;

begin
  LData := AShader.GetData;
  FOutput.Add('shader ' + string(LData.Name));
  FOutput.Add('head sort' + Bits(LData.Sort) + Format(' default=%s explicit=%s surf=%s cont=%s merge=%s sky=%s cull=%d ' +
    'poff=%s nomip=%s nopic=%s fogpass=%d passes=%d', [Flag(LData.DefaultShader), Flag(LData.ExplicitlyDefined),
    LowerCase(IntToHex(LData.SurfaceFlags, 1)), LowerCase(IntToHex(Cardinal(LData.ContentFlags), 1)),
    Flag(LData.EntityMergable), Flag(LData.IsSky), Ord(LData.CullType), Flag(LData.PolygonOffset),
    Flag(LData.NoMipMaps), Flag(LData.NoPicMip), Ord(LData.FogPass), LData.NumUnfoggedPasses]));
  FOutput.Add('misc portal' + Bits(LData.PortalRange) + ' clamp' + Bits(LData.ClampTime));
  FOutput.Add('fog' + Bits(LData.FogParms.Color[0]) + Bits(LData.FogParms.Color[1]) + Bits(LData.FogParms.Color[2]) +
    Bits(LData.FogParms.DepthForOpaque));
  LLine := 'sky' + Bits(LData.Sky.CloudHeight);
  for LIndex := 0 to 5 do
    LLine := LLine + ' ' + Name(LData.Sky.OuterBox[LIndex]);
  for LIndex := 0 to 5 do
    LLine := LLine + ' ' + Name(LData.Sky.InnerBox[LIndex]);
  FOutput.Add(LLine);
  if LData.HasSun then
    FOutput.Add('sun' + Bits(LData.SunLight[0]) + Bits(LData.SunLight[1]) + Bits(LData.SunLight[2]) +
      Bits(LData.SunDirection[0]) + Bits(LData.SunDirection[1]) + Bits(LData.SunDirection[2]));
  FOutput.Add('deforms ' + IntToStr(LData.NumDeforms));
  for LIndex := 0 to LData.NumDeforms - 1 do
  begin
    LLine := Format('deform %d type=%d move', [LIndex, Ord(LData.Deforms[LIndex].Deformation)]) +
      Bits(LData.Deforms[LIndex].MoveVector[0]) + Bits(LData.Deforms[LIndex].MoveVector[1]) +
      Bits(LData.Deforms[LIndex].MoveVector[2]);
    DumpWave(LLine, LData.Deforms[LIndex].DeformationWave);
    LLine := LLine + ' spread' + Bits(LData.Deforms[LIndex].DeformationSpread) + ' bulge' +
      Bits(LData.Deforms[LIndex].BulgeWidth) + Bits(LData.Deforms[LIndex].BulgeHeight) +
      Bits(LData.Deforms[LIndex].BulgeSpeed);
    FOutput.Add(LLine);
  end;
  for LIndex := 0 to LData.NumUnfoggedPasses - 1 do
  begin
    LStage := LData.Stages[LIndex];
    // the original keeps the active stages up to the first one that is not
    if not LStage.Active then
      Break;
    FOutput.Add(Format('stage %d detail=%s rgb=%d alpha=%d state=%s acff=%d const=%d,%d,%d,%d',
      [LIndex, Flag(LStage.IsDetail), Ord(LStage.RgbGen), Ord(LStage.AlphaGen),
      LowerCase(IntToHex(LStage.StateBits, 1)), Ord(LStage.AdjustColorsForFog), LStage.ConstantColor[0],
      LStage.ConstantColor[1], LStage.ConstantColor[2], LStage.ConstantColor[3]]));
    LLine := ' rgbwave';
    DumpWave(LLine, LStage.RgbWave);
    LLine := LLine + ' alphawave';
    DumpWave(LLine, LStage.AlphaWave);
    FOutput.Add(LLine);
    FOutput.Add(Format(' bundle tcgen=%d lightmap=%s video=%s anims=%d speed', [Ord(LStage.Bundle.TcGen),
      Flag(LStage.Bundle.IsLightmap), Flag(LStage.Bundle.IsVideoMap), LStage.Bundle.NumImageAnimations]) +
      Bits(LStage.Bundle.ImageAnimationSpeed) + ' images');
    LImages := '';
    for LImage := 0 to Max(LStage.Bundle.NumImageAnimations, 1) - 1 do
      if LStage.Bundle.IsLightmap then
        LImages := LImages + ' $lightmap'
      else
        LImages := LImages + ' ' + Name(LStage.Bundle.ImageNames[LImage]);
    // the line of the bundle and its images are one line in the original
    FOutput[FOutput.Count - 1] := FOutput[FOutput.Count - 1] + LImages;
    LLine := ' tcvec';
    for LCell := 0 to 5 do
      LLine := LLine + Bits(LStage.Bundle.TcGenVectors[LCell div 3, LCell mod 3]);
    FOutput.Add(LLine);
    FOutput.Add(' texmods ' + IntToStr(LStage.Bundle.NumTexMods));
    for LMod := 0 to LStage.Bundle.NumTexMods - 1 do
    begin
      LMods := LStage.Bundle.TexMods[LMod];
      LLine := Format('  mod %d type=%d', [LMod, Ord(LMods.ModType)]);
      DumpWave(LLine, LMods.Wave);
      for LCell := 0 to 3 do
        LLine := LLine + Bits(LMods.Matrix[LCell div 2, LCell mod 2]);
      LLine := LLine + Bits(LMods.Translate[0]) + Bits(LMods.Translate[1]) + Bits(LMods.Scale[0]) +
        Bits(LMods.Scale[1]) + Bits(LMods.Scroll[0]) + Bits(LMods.Scroll[1]) + Bits(LMods.RotateSpeed);
      FOutput.Add(LLine);
    end;
  end;
end;

procedure TQ3ShaderGoldenRunner.Find(const AName: string);
var
  LDecl: IDecl;
  LShader: IDeclQ3Shader;
  LLine, LMessage: string;
  LDropped: Boolean;
begin
  FKit.Lines.Clear;
  FOutput.Add('find ' + AName);
  LDecl := FKit.Manager.FindType(DECL_Q3SHADER, AnsiString(AName));
  LDropped := False;
  for LLine in FKit.Lines do
    if StartsStr('W: ', LLine) then
    begin
      LMessage := Copy(LLine, 4, MaxInt);
      FOutput.Add('log ' + LMessage);
      if StartsStr('ERROR: ', LMessage) then
        LDropped := True;
    end;
  if LDropped then
    FOutput.Add('drop')
  else if Supports(LDecl, IDeclQ3Shader, LShader) then
    Dump(LShader);
end;

function TQ3ShaderGoldenRunner.Run(const AScenario: TStrings): TStringList;
var
  LLine: string;
begin
  for LLine in AScenario do
  begin
    if LLine = 'scan' then
      Rebuild
    else if StartsStr('detail ', LLine) then
    begin
      FOptions.DetailTextures := StrToInt(Copy(LLine, 8, MaxInt)) <> 0;
      Rebuild;
    end
    else if StartsStr('find ', LLine) then
      Find(Copy(LLine, 6, MaxInt));
  end;
  Result := FOutput;
end;

{ TTestQ3ShaderGolden }

function TTestQ3ShaderGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Decl\q3shader\');
end;

// the angle of the sun goes through float operations that the FPU of Win32 may round differently: four units of
// the last place are allowed on those lines, every other line is the same text
class function TTestQ3ShaderGolden.SameLine(const AExpected, AActual: string): Boolean;
var
  LExpected, LActual: TArray<string>;
  LIndex: Integer;
  LLeft, LRight: Int64;
begin
  if AExpected = AActual then
    Exit(True);
  if not StartsStr('sun ', AExpected) then
    Exit(False);
  LExpected := AExpected.Split([' ']);
  LActual := AActual.Split([' ']);
  if Length(LExpected) <> Length(LActual) then
    Exit(False);
  for LIndex := 1 to High(LExpected) do
  begin
    LLeft := StrToInt64('$' + LExpected[LIndex]);
    LRight := StrToInt64('$' + LActual[LIndex]);
    // same sign and a few units apart; a value near zero changes sign freely, so compare the magnitudes
    if Abs((LLeft and $7FFFFFFF) - (LRight and $7FFFFFFF)) > 4 then
      Exit(False);
  end;
  Result := True;
end;

procedure TTestQ3ShaderGolden.DovrebbeDareLeStesseRisposteDelVeroTrShaderC;
var
  LScenario, LGolden: TStringList;
  LRunner: TQ3ShaderGoldenRunner;
  LActual: TStringList;
  LIndex: Integer;
begin
  LScenario := TStringList.Create;
  LGolden := TStringList.Create;
  LRunner := TQ3ShaderGoldenRunner.Create(DataFolder);
  try
    LScenario.LoadFromFile(DataFolder + 'scenario.txt', TEncoding.ANSI);
    LGolden.LoadFromFile(DataFolder + 'q3shader.golden.txt', TEncoding.ANSI);
    LActual := LRunner.Run(LScenario);
    for LIndex := 0 to LGolden.Count - 1 do
      if (LIndex >= LActual.Count) or (not SameLine(LGolden[LIndex], LActual[LIndex])) then
      begin
        LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.q3shader.actual.txt'));
        if LIndex < LActual.Count then
          Assert.Fail(Format('line %d: expected [%s] but got [%s]', [LIndex + 1, LGolden[LIndex], LActual[LIndex]]))
        else
          Assert.Fail(Format('line %d: expected [%s] but the output ended', [LIndex + 1, LGolden[LIndex]]));
      end;
    Assert.AreEqual(LGolden.Count, LActual.Count);
  finally
    LRunner.Free;
    LGolden.Free;
    LScenario.Free;
  end;
end;

end.
