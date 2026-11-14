{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the material declaration - parity with the real C++    }
{                                                                              }
{  Runs Tests\Data\Decl\material.input.txt with TDeclMaterial and compares     }
{  the output with material.golden.txt, which is what the real Material.cpp    }
{  and Image_program.cpp of Doom 3 printed for the same file (see              }
{  Tests\Data\Decl\README.md).                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.MaterialGolden;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Decl.Intf,
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Material.Types, DelphiDoom.Decl.Material.Intf,
  DelphiDoom.Tests.Decl.Support;

type
  /// <summary>
  ///   The interpreter of the cases: the same operations and output lines as the driver of the C++ harness
  ///   (<c>dump</c>, <c>find</c>, <c>print</c>, <c>eval</c>, <c>remap</c>, <c>settext</c>)
  /// </summary>
  TMaterialGoldenRunner = class
  strict private
    FKit: TDeclKit;
    procedure Emit(const ALine: string);
    function Esc(const AText: AnsiString): string;
    class function Bits(const AValue: Single): string; static;
    function ImageText(const AReference: TMaterialImageReference): string;
    procedure DumpMaterial(const ADecl: IDecl);
    procedure Execute(const AOperation: string);
    class function Words(const AText: string): TArray<string>; static;
  public
    /// <summary>Runs every case of the text and returns the output lines</summary>
    function RunAll(const AInput: TStrings): TStringList;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestDeclMaterialGolden = class
  strict private
    function DataFolder: string;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroIdMaterial;
  end;

implementation

uses
  System.IOUtils, System.Math, System.StrUtils, DelphiDoom.Decl.Skin, DelphiDoom.Decl.Material.ImageNames,
  DelphiDoom.Tests.Scanner.IdFakes;

{ TMaterialGoldenRunner }

procedure TMaterialGoldenRunner.Emit(const ALine: string);
begin
  FKit.Lines.Add(ALine);
end;

function TMaterialGoldenRunner.Esc(const AText: AnsiString): string;
begin
  Result := TFakeIdLibLog.Escape(AText);
end;

class function TMaterialGoldenRunner.Bits(const AValue: Single): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := IntToHex(PCardinal(@LValue)^, 8);
end;

class function TMaterialGoldenRunner.Words(const AText: string): TArray<string>;
var
  LList: TStringList;
  LIndex: Integer;
begin
  LList := TStringList.Create;
  try
    LList.Delimiter := ' ';
    LList.StrictDelimiter := True;
    LList.DelimitedText := Trim(AText);
    for LIndex := LList.Count - 1 downto 0 do
      if LList[LIndex] = '' then
        LList.Delete(LIndex);
    Result := LList.ToStringArray;
  finally
    LList.Free;
  end;
end;

function TMaterialGoldenRunner.ImageText(const AReference: TMaterialImageReference): string;
var
  LName: AnsiString;
begin
  if TMaterialImageNames.IsDefault(AReference.Name) then
    Exit('[_default]');
  if TMaterialImageNames.IsCurrentRender(AReference.Name) then
    Exit('[_currentRender]');
  LName := TMaterialImageNames.Canonicalize(AReference.Name);
  Result := Format('[%s] f=%d r=%d d=%d c=%d p=%d', [Esc(LName), Ord(AReference.Filter), Ord(AReference.RepeatMode),
    Ord(AReference.Depth), Ord(AReference.CubeMap), Ord(AReference.AllowPicmip)]);
end;

procedure TMaterialGoldenRunner.DumpMaterial(const ADecl: IDecl);
var
  LMaterial: IDeclMaterial;
  LRegisters: IMaterialRegisters;
  LCount, LIndex, LParm: Integer;
  LStage: TMaterialStage;
  LDecal: TMaterialDecalInfo;
  LText, LDeformName, LGui, LFalloff, LImage: string;
  LWobble: Boolean;
  LConstants: TArray<Single>;

  function Flag(const AValue: Boolean): Integer;
  begin
    Result := Ord(AValue);
  end;

begin
  Supports(ADecl, IDeclMaterial, LMaterial);
  Supports(ADecl, IMaterialRegisters, LRegisters);
  LCount := LMaterial.GetNumStages;
  Emit(Format('M %s state=%d stages=%d ambient=%d regs=%d', [Esc(ADecl.GetName), Ord(ADecl.GetState), LCount,
    Flag(LMaterial.HasAmbient), LRegisters.GetNumRegisters]));
  if ADecl.GetState <> dsParsed then
    Exit;

  LWobble := False;
  for LIndex := 0 to LCount - 1 do
    if LMaterial.GetStage(LIndex).Texture.Texgen = TMaterialTexgen.WobbleSkyCube then
      LWobble := True;
  LDeformName := '-';
  if (LMaterial.Deform in [TMaterialDeform.Turbulent, TMaterialDeform.Particle, TMaterialDeform.Particle2])
    and Assigned(LMaterial.GetDeformDecl) then
    LDeformName := Esc(LMaterial.GetDeformDecl.GetName);

  LText := Format('  gen surf=%d content=%d mflags=%d cover=%d sort=%s cull=%d deform=%d dreg=%d,%d,%d,%d dname=[%s]',
    [LMaterial.GetSurfaceFlags, LMaterial.GetContentFlags, 0, Ord(LMaterial.Coverage), Bits(LMaterial.GetSort),
     Ord(LMaterial.GetCullType), Ord(LMaterial.Deform), LMaterial.GetDeformRegister(0),
     LMaterial.GetDeformRegister(1), LMaterial.GetDeformRegister(2), LMaterial.GetDeformRegister(3), LDeformName]);
  if LWobble then
    LText := LText + Format(' texgenregs=%d,%d,%d', [LMaterial.GetTexGenRegister(0), LMaterial.GetTexGenRegister(1),
      LMaterial.GetTexGenRegister(2)]);
  Emit(LText);

  Emit(Format('  flags polyoff=%d noshadows=%d forceshadows=%d noselfshadow=%d noportalfog=%d',
    [Flag(LMaterial.TestMaterialFlag(MF_POLYGONOFFSET)), Flag(LMaterial.TestMaterialFlag(MF_NOSHADOWS)),
     Flag(LMaterial.TestMaterialFlag(MF_FORCESHADOWS)), Flag(LMaterial.TestMaterialFlag(MF_NOSELFSHADOW)),
     Flag(LMaterial.TestMaterialFlag(MF_NOPORTALFOG))]));

  if LMaterial.GetGuiName <> '' then
    LGui := Esc(LMaterial.GetGuiName)
  else if LMaterial.HasGui and (LMaterial.GetEntityGui = 0) then
    LGui := ''
  else
    LGui := '-';
  Emit(Format('  misc desc=[%s] rb=[%s] egui=%d gui=[%s] spec=%d poff=%s fog=%d blend=%d amb=%d unsm=%d subv=%d ' +
    'overl=%d back=%d ealpha=%s supp=%d psky=%d eimg=%s img=[%s]',
    [Esc(LMaterial.GetDescription), Esc(LMaterial.GetRenderBump), LMaterial.GetEntityGui, LGui,
     LMaterial.Spectrum, Bits(LMaterial.GetPolygonOffset), Flag(LMaterial.IsFogLight), Flag(LMaterial.IsBlendLight),
     Flag(LMaterial.IsAmbientLight), Flag(LMaterial.UseUnsmoothedTangents), Flag(LMaterial.HasSubview),
     Flag(LMaterial.AllowOverlays), Flag(LMaterial.ShouldCreateBackSides), Bits(LMaterial.GetEditorAlpha),
     Flag(LMaterial.SuppressInSubview), Flag(LMaterial.IsPortalSky), Esc(LMaterial.GetEditorImageName),
     Esc(LMaterial.ImageName)]));

  if LMaterial.GetLightFalloffImageName <> '' then
    LFalloff := Esc(TMaterialImageNames.ResolvedName(LMaterial.GetLightFalloffImageName))
  else
    LFalloff := '-';
  Emit('  falloff=' + LFalloff);

  LDecal := LMaterial.GetDecalInfo;
  Emit(Format('  decal stay=%d fade=%d start=%s,%s,%s,%s end=%s,%s,%s,%s',
    [LDecal.StayTime, LDecal.FadeTime, Bits(LDecal.Start[0]), Bits(LDecal.Start[1]), Bits(LDecal.Start[2]),
     Bits(LDecal.Start[3]), Bits(LDecal.Finish[0]), Bits(LDecal.Finish[1]), Bits(LDecal.Finish[2]),
     Bits(LDecal.Finish[3])]));

  Emit(Format('  q drawn=%d gui=%d subview=%d casts=%d fog=%d lit=%d litback=%d discrete=%d nofrag=%d lcast=%d ' +
    'leffect=%d texgen=%d stype=%d bump=%d',
    [Flag(LMaterial.IsDrawn), Flag(LMaterial.HasGui), Flag(LMaterial.HasSubview), Flag(LMaterial.SurfaceCastsShadow),
     Flag(LMaterial.ReceivesFog), Flag(LMaterial.ReceivesLighting), Flag(LMaterial.ReceivesLightingOnBackSides),
     Flag(LMaterial.IsDiscrete), Flag(LMaterial.NoFragment), Flag(LMaterial.LightCastsShadows),
     Flag(LMaterial.LightEffectsBackSides), Ord(LMaterial.Texgen), LMaterial.GetSurfaceType,
     LMaterial.GetBumpStageIndex]));

  for LIndex := 0 to LCount - 1 do
  begin
    LStage := LMaterial.GetStage(LIndex);
    LText := Format('  stage %d cond=%d light=%d bits=%s color=%d,%d,%d,%d atest=%d,%d vcol=%d iat=%d poff=%s ' +
      'texgen=%d dyn=%d wh=%d,%d',
      [LIndex, LStage.ConditionRegister, Ord(LStage.Lighting), IntToHex(LStage.DrawStateBits, 8),
       LStage.ColorRegisters[0], LStage.ColorRegisters[1], LStage.ColorRegisters[2], LStage.ColorRegisters[3],
       Flag(LStage.HasAlphaTest), IfThen(LStage.HasAlphaTest, LStage.AlphaTestRegister, 0),
       Ord(LStage.VertexColor), Flag(LStage.IgnoreAlphaTest), Bits(LStage.PrivatePolygonOffset),
       Ord(LStage.Texture.Texgen), Ord(LStage.Texture.Dynamic), LStage.Texture.Width, LStage.Texture.Height]);
    LText := LText + Format(' matrix=%d', [Flag(LStage.Texture.HasMatrix)]);
    if LStage.Texture.HasMatrix then
      LText := LText + Format(':%d,%d,%d,%d,%d,%d', [LStage.Texture.Matrix[0][0], LStage.Texture.Matrix[0][1],
        LStage.Texture.Matrix[0][2], LStage.Texture.Matrix[1][0], LStage.Texture.Matrix[1][1],
        LStage.Texture.Matrix[1][2]]);
    if LStage.Texture.HasCinematic then
      LText := LText + Format(' cin=[%s] loop=%d snd=%d', [Esc(LStage.Texture.CinematicName),
        Flag(LStage.Texture.CinematicLoop), Flag(LStage.Texture.IsSoundMap)]);
    if LStage.Texture.HasImage then
      LImage := ImageText(LStage.Texture.Image)
    else
      LImage := '-';
    LText := LText + ' img=' + LImage;
    if LStage.HasNewStage then
    begin
      LText := LText + Format(' new vp=%s fp=%s nvp=%d nfi=%d mega=%d',
        [Esc(AnsiString(IfThen(LStage.NewStage.VertexProgram <> '', string(LStage.NewStage.VertexProgram), '-'))),
         Esc(AnsiString(IfThen(LStage.NewStage.FragmentProgram <> '', string(LStage.NewStage.FragmentProgram), '-'))),
         LStage.NewStage.NumVertexParms, LStage.NewStage.NumFragmentImages,
         Flag(LStage.NewStage.MegaTexture <> '')]);
      for LParm := 0 to LStage.NewStage.NumVertexParms - 1 do
        LText := LText + Format(' vparm%d=%d,%d,%d,%d', [LParm, LStage.NewStage.VertexParms[LParm][0],
          LStage.NewStage.VertexParms[LParm][1], LStage.NewStage.VertexParms[LParm][2],
          LStage.NewStage.VertexParms[LParm][3]]);
      for LParm := 0 to LStage.NewStage.NumFragmentImages - 1 do
        if LStage.NewStage.FragmentImages[LParm].Name = '' then
          LText := LText + Format(' fimg%d=-', [LParm])
        else
          LText := LText + Format(' fimg%d=%s', [LParm, ImageText(LStage.NewStage.FragmentImages[LParm])]);
    end;
    Emit(LText);
  end;

  LConstants := LRegisters.ConstantRegisters;
  LText := Format('  const=%d', [Flag(Assigned(LConstants))]);
  if Assigned(LConstants) then
    for LIndex := 0 to LRegisters.GetNumRegisters - 1 do
      LText := LText + ' ' + Bits(LConstants[LIndex]);
  Emit(LText);
end;

procedure TMaterialGoldenRunner.Execute(const AOperation: string);
var
  LSpace, LPair: Integer;
  LCommand, LArgument, LKey, LText: string;
  LWords: TArray<string>;
  LCount, LIndex, LWord: Integer;
  LDecl: IDecl;
  LSkin: IDeclSkin;
  LRegisters: IMaterialRegisters;
  LRemapped: IDecl;
  LInput: TMaterialEvaluationInput;
  LValues: TArray<Single>;
  LFormat: TFormatSettings;
  LValue: Single;
  LOther: IDecl;
begin
  LFormat := TFormatSettings.Invariant;
  LSpace := Pos(' ', AOperation);
  if LSpace > 0 then
  begin
    LCommand := Copy(AOperation, 1, LSpace - 1);
    LArgument := Copy(AOperation, LSpace + 1, MaxInt);
  end
  else
  begin
    LCommand := AOperation;
    LArgument := '';
  end;
  LWords := Words(LArgument);
  Emit('> ' + AOperation);
  try
    if LCommand = 'dump' then
    begin
      LCount := FKit.Manager.GetNumDecls(DECL_MATERIAL);
      Emit('n=' + IntToStr(LCount));
      for LIndex := 0 to LCount - 1 do
        DumpMaterial(FKit.Manager.DeclByIndex(DECL_MATERIAL, LIndex, True));
    end
    else if LCommand = 'find' then
      DumpMaterial(FKit.Manager.FindType(DECL_MATERIAL, AnsiString(LWords[0]), True))
    else if LCommand = 'print' then
      FKit.Manager.FindType(DECL_MATERIAL, AnsiString(LWords[0]), True).Print
    else if LCommand = 'eval' then
    begin
      LDecl := FKit.Manager.FindType(DECL_MATERIAL, AnsiString(LWords[0]), True);
      Supports(LDecl, IMaterialRegisters, LRegisters);
      LInput := Default(TMaterialEvaluationInput);
      for LWord := 1 to High(LWords) do
      begin
        LPair := Pos('=', LWords[LWord]);
        LKey := Copy(LWords[LWord], 1, LPair - 1);
        LValue := StrToFloat(Copy(LWords[LWord], LPair + 1, MaxInt), LFormat);
        if LKey = 'time' then
          LInput.Time := LValue
        else if LKey = 'snd' then
        begin
          LInput.SoundAmplitude := LValue;
          LInput.HasSoundEmitter := True;
        end
        else if LKey[1] = 'p' then
          LInput.Parms[StrToInt(Copy(LKey, 2, MaxInt))] := LValue
        else if LKey[1] = 'g' then
          LInput.GlobalParms[StrToInt(Copy(LKey, 2, MaxInt))] := LValue;
      end;
      LRegisters.EvaluateRegisters(LValues, LInput);
      LText := 'eval';
      for LIndex := 0 to LRegisters.GetNumRegisters - 1 do
        LText := LText + ' ' + Bits(LValues[LIndex]);
      Emit(LText);
    end
    else if LCommand = 'remap' then
    begin
      Supports(FKit.Manager.FindType(DECL_SKIN, AnsiString(LWords[0]), True), IDeclSkin, LSkin);
      LOther := FKit.Manager.FindType(DECL_MATERIAL, AnsiString(LWords[1]), True);
      LRemapped := LSkin.RemapShaderBySkin(LOther);
      if Assigned(LRemapped) then
        Emit(Format('remap %s -> %s', [Esc(LOther.GetName), Esc(LRemapped.GetName)]))
      else
        Emit(Format('remap %s -> null', [Esc(LOther.GetName)]));
    end
    else if LCommand = 'settext' then
    begin
      LDecl := FKit.Manager.FindType(DECL_MATERIAL, AnsiString(LWords[0]), False);
      LText := Copy(LArgument, Pos(' ', LArgument) + 1, MaxInt);
      LText := StringReplace(LText, '\n', #10, [rfReplaceAll]);
      LDecl.SetText(AnsiString(LText));
      LDecl.Invalidate;
    end
    else
      Emit('unknown op');
  except
    on LError: EDeclException do
      Emit('ERR ' + Esc(AnsiString(LError.Message)));
  end;
end;

function TMaterialGoldenRunner.RunAll(const AInput: TStrings): TStringList;
var
  LIndex, LFileCount: Integer;
  LLine, LCurrentFile: string;
  LOperations: TStringList;
  LFiles: TDictionary<string, string>;
  LFileOrder: TStringList;
  LName: string;
begin
  Result := TStringList.Create;
  LOperations := TStringList.Create;
  LFiles := TDictionary<string, string>.Create;
  LFileOrder := TStringList.Create;
  try
    LIndex := 0;
    while LIndex < AInput.Count do
    begin
      if Copy(AInput[LIndex], 1, 6) <> '@case ' then
      begin
        Inc(LIndex);
        Continue;
      end;
      LName := Copy(AInput[LIndex], 7, MaxInt);
      Inc(LIndex);
      LOperations.Clear;
      LFiles.Clear;
      LFileOrder.Clear;
      LCurrentFile := '';
      while (LIndex < AInput.Count) and (AInput[LIndex] <> '@end') do
      begin
        LLine := AInput[LIndex];
        if Copy(LLine, 1, 4) = '@op ' then
        begin
          LOperations.Add(Copy(LLine, 5, MaxInt));
          LCurrentFile := '';
        end
        else if Copy(LLine, 1, 6) = '@file ' then
        begin
          LCurrentFile := LowerCase(Copy(LLine, 7, MaxInt));
          LFiles.AddOrSetValue(LCurrentFile, '');
          LFileOrder.Add(LCurrentFile);
        end
        else if LCurrentFile <> '' then
          LFiles[LCurrentFile] := LFiles[LCurrentFile] + LLine + #10;
        Inc(LIndex);
      end;
      Inc(LIndex);

      FKit := TDeclKit.Create;
      try
        for LFileCount := 0 to LFileOrder.Count - 1 do
          FKit.Source.Add(AnsiString(LFileOrder[LFileCount]), AnsiString(LFiles[LFileOrder[LFileCount]]));
        FKit.Start(True, True);
        FKit.Lines.Insert(0, '## ' + LName);
        for LFileCount := 0 to LOperations.Count - 1 do
          Execute(LOperations[LFileCount]);
        Result.AddStrings(FKit.Lines);
      finally
        FreeAndNil(FKit);
      end;
    end;
  finally
    LFileOrder.Free;
    LFiles.Free;
    LOperations.Free;
  end;
end;

{ TTestDeclMaterialGolden }

function TTestDeclMaterialGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Decl\');
end;

procedure TTestDeclMaterialGolden.DovrebbeDareLeStesseRisposteDelVeroIdMaterial;
var
  LInput, LGolden, LActual: TStringList;
  LRunner: TMaterialGoldenRunner;
  LIndex: Integer;
begin
  LInput := TStringList.Create;
  LGolden := TStringList.Create;
  LRunner := TMaterialGoldenRunner.Create;
  LActual := nil;
  try
    LInput.LoadFromFile(DataFolder + 'material.input.txt', TEncoding.ANSI);
    LGolden.LoadFromFile(DataFolder + 'material.golden.txt', TEncoding.ANSI);
    LActual := LRunner.RunAll(LInput);
    for LIndex := 0 to LGolden.Count - 1 do
      if (LIndex >= LActual.Count) or (LActual[LIndex] <> LGolden[LIndex]) then
      begin
        LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.material.actual.txt'));
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
  TDUnitX.RegisterTestFixture(TTestDeclMaterialGolden);

end.
