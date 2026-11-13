{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the .skin files of Quake III   }
{  (words, parser, registry, shaders of the surfaces)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Q3SkinValues;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Q3Player.Skin.Intf,
  DelphiDoom.Tests.Models.Q3PlayerSupport,
  DelphiDoom.Tests.Models.Q3SkinSupport;

type
  [TestFixture]
  [Category('models')]
  TTestModelsQ3SkinValues = class(TObject)
  strict private
    FLog: TFakeQ3Log;
    FLogKeeper: ILog;
    FFiles: TFakeQ3Files;
    FFilesKeeper: IInterface;
    FParser: IQ3SkinParser;
    FRegistry: IQ3SkinRegistry;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereLeParoleSeparateDaSpaziVirgoleECommenti;
    [Test]
    procedure DovrebbeLeggereUnaParolaTraVirgoletteConGliSpazi;
    [Test]
    procedure DovrebbeFinireConUnaParolaVuotaAllaFineDelTesto;
    [Test]
    procedure DovrebbeScartareUnaParolaDi1024CaratteriETroncareUnaTraVirgolette;
    [Test]
    procedure DovrebbeTrattareIByteSopra127ComeSpazi;
    [Test]
    procedure DovrebbeLeggereLeSuperficiDiUnaSkinInMinuscolo;
    [Test]
    procedure DovrebbeSaltareLeRigheDeiTagSoloSeInMinuscolo;
    [Test]
    procedure DovrebbeDareNilSeLaSkinNonHaSuperfici;
    [Test]
    procedure DovrebbeTroncareIlNomeDellaSuperficieA63Caratteri;
    [Test]
    procedure DovrebbeIgnorareLeSuperficiOltreLeTrentaduaConUnAvviso;
    [Test]
    procedure DovrebbeTrovareLaShaderPerNomeEsatto;
    [Test]
    procedure DovrebbeSollevareUnErroreSeLIndiceDellaSuperficieNonEsiste;
    [Test]
    procedure DovrebbeDareLaSkinPredefinitaPerLaManigliaZero;
    [Test]
    procedure DovrebbeDareLaStessaManigliaSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeTrattareUnNomeSenzaSkinComeUnaSolaShader;
    [Test]
    procedure DovrebbeDareZeroPerUnFileMancanteECiascunaVoltaSenzaRileggerlo;
    [Test]
    procedure DovrebbeRifiutareNomiVuotiETroppoLunghi;
    [Test]
    procedure DovrebbeFermarsiAlleMilleVentiquattroSkin;
    [Test]
    procedure DovrebbeSollevareUnErroreSeMancaUnaDipendenza;
    [Test]
    procedure DovrebbeSceglierLaShaderDellaSkinPerNomeDiSuperficie;
    [Test]
    procedure DovrebbeSceglierLaShaderDelModelloSenzaSkin;
    [Test]
    procedure DovrebbeSollevareUnErroreSeLoSkinNumeroENegativoOIlModelloManca;
  end;

implementation

uses
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Q3Player.Intf,
  DelphiDoom.Models.Q3Player.Skin.Types,
  DelphiDoom.Models.Q3Player.Skin.TokenReader,
  DelphiDoom.Models.Q3Player.Skin.Registry,
  DelphiDoom.Models.Q3Player.Factory;

procedure TTestModelsQ3SkinValues.Setup;
begin
  FLog := TFakeQ3Log.Create;
  FLogKeeper := FLog;
  FFiles := TFakeQ3Files.Create;
  FFilesKeeper := FFiles;
  FParser := TQ3PlayerFactory.CreateSkinParser(FLog);
  FRegistry := TQ3PlayerFactory.CreateSkinRegistry(FFiles, FLog);
end;

procedure TTestModelsQ3SkinValues.TearDown;
begin
  FRegistry := nil;
  FParser := nil;
  FFilesKeeper := nil;
  FFiles := nil;
  FLogKeeper := nil;
  FLog := nil;
end;

procedure TTestModelsQ3SkinValues.DovrebbeLeggereLeParoleSeparateDaSpaziVirgoleECommenti;
var
  LReader: TQ3SkinTokenReader;
begin
  LReader := TQ3SkinTokenReader.Create('a,b // line'#10'/* block */ c d,e');
  try
    Assert.AreEqual('a', string(LReader.Next));
    // the comma is not part of a word: it is left to the caller
    Assert.IsFalse(LReader.AtEnd);
    LReader.SkipComma;
    Assert.AreEqual('b', string(LReader.Next));
    Assert.AreEqual('c', string(LReader.Next));
    Assert.AreEqual('d', string(LReader.Next));
    LReader.SkipComma;
    Assert.AreEqual('e', string(LReader.Next));
    Assert.IsTrue(LReader.AtEnd);
    Assert.AreEqual('', string(LReader.Next));
  finally
    LReader.Free;
  end;
end;

procedure TTestModelsQ3SkinValues.DovrebbeLeggereUnaParolaTraVirgoletteConGliSpazi;
var
  LReader: TQ3SkinTokenReader;
begin
  LReader := TQ3SkinTokenReader.Create('"two words, and a comma" x "open');
  try
    Assert.AreEqual('two words, and a comma', string(LReader.Next));
    Assert.AreEqual('x', string(LReader.Next));
    // a quote that is never closed ends with the text
    Assert.AreEqual('open', string(LReader.Next));
    Assert.IsTrue(LReader.AtEnd);
  finally
    LReader.Free;
  end;
end;

procedure TTestModelsQ3SkinValues.DovrebbeFinireConUnaParolaVuotaAllaFineDelTesto;
var
  LReader: TQ3SkinTokenReader;
begin
  LReader := TQ3SkinTokenReader.Create('   // only a comment');
  try
    Assert.AreEqual('', string(LReader.Next));
    // the original leaves its pointer where it was when it finds the end: the blanks, not the NUL
    Assert.IsFalse(LReader.AtEnd);
  finally
    LReader.Free;
  end;
  LReader := TQ3SkinTokenReader.Create('/* never closed');
  try
    Assert.AreEqual('', string(LReader.Next));
  finally
    LReader.Free;
  end;
  LReader := TQ3SkinTokenReader.Create('');
  try
    Assert.IsTrue(LReader.AtEnd);
    Assert.AreEqual('', string(LReader.Next));
  finally
    LReader.Free;
  end;
end;

procedure TTestModelsQ3SkinValues.DovrebbeScartareUnaParolaDi1024CaratteriETroncareUnaTraVirgolette;
var
  LReader: TQ3SkinTokenReader;
  LWord: AnsiString;
begin
  LWord := AnsiString(StringOfChar('x', 1024));
  LReader := TQ3SkinTokenReader.Create(LWord + ' ' + AnsiString(StringOfChar('y', 1023)) + ' "' + LWord + 'zzz" ok');
  try
    // MAX_TOKEN_CHARS: the word is dropped (empty), the one of 1023 is kept, a quoted one is cut
    Assert.AreEqual('', string(LReader.Next));
    Assert.AreEqual<Integer>(1023, Length(LReader.Next));
    Assert.AreEqual<Integer>(1024, Length(LReader.Next));
    Assert.AreEqual('ok', string(LReader.Next));
  finally
    LReader.Free;
  end;
end;

procedure TTestModelsQ3SkinValues.DovrebbeTrattareIByteSopra127ComeSpazi;
var
  LReader: TQ3SkinTokenReader;
begin
  // the char of the original is signed: a byte from 128 is negative, so a blank
  LReader := TQ3SkinTokenReader.Create(AnsiChar(233) + 'ab' + AnsiChar(233) + 'cd');
  try
    Assert.AreEqual('ab', string(LReader.Next));
    Assert.AreEqual('cd', string(LReader.Next));
  finally
    LReader.Free;
  end;
end;

procedure TTestModelsQ3SkinValues.DovrebbeLeggereLeSuperficiDiUnaSkinInMinuscolo;
var
  LSkin: IQ3Skin;
begin
  LSkin := FParser.Parse('models/players/x/lower_default.skin',
    'L_Legs,models/players/x/lower.tga'#13#10'U_Body , "models/players/x/up per.tga"'#10);
  Assert.AreEqual('models/players/x/lower_default.skin', string(LSkin.Name));
  Assert.AreEqual(3, LSkin.SurfaceCount);
  Assert.AreEqual('l_legs', string(LSkin.Surfaces[0].Name));
  Assert.AreEqual('models/players/x/lower.tga', string(LSkin.Surfaces[0].Shader));
  Assert.AreEqual('u_body', string(LSkin.Surfaces[1].Name));
  // a blank between the name and the comma leaves the comma to the shader word, as the original:
  // the quoted word that follows is then a surface name with no shader
  Assert.AreEqual(',', string(LSkin.Surfaces[1].Shader));
  Assert.AreEqual('models/players/x/up per.tga', string(LSkin.Surfaces[2].Name));
  Assert.AreEqual('', string(LSkin.Surfaces[2].Shader));
end;

procedure TTestModelsQ3SkinValues.DovrebbeSaltareLeRigheDeiTagSoloSeInMinuscolo;
var
  LSkin: IQ3Skin;
begin
  // "tag_torso," names no shader, so the next word is a surface; "TAG_head" is not a tag for strstr
  LSkin := FParser.Parse('s.skin', 'tag_torso,'#10'body,sh_body'#10'TAG_head,tag_x'#10);
  Assert.AreEqual(2, LSkin.SurfaceCount);
  Assert.AreEqual('body', string(LSkin.Surfaces[0].Name));
  Assert.AreEqual('tag_head', string(LSkin.Surfaces[1].Name));
  Assert.AreEqual('tag_x', string(LSkin.Surfaces[1].Shader));
end;

procedure TTestModelsQ3SkinValues.DovrebbeDareNilSeLaSkinNonHaSuperfici;
begin
  Assert.IsNull(FParser.Parse('s.skin', ''));
  Assert.IsNull(FParser.Parse('s.skin', '// comment'));
  Assert.IsNull(FParser.Parse('s.skin', 'tag_a,'#10'tag_b,'));
end;

procedure TTestModelsQ3SkinValues.DovrebbeTroncareIlNomeDellaSuperficieA63Caratteri;
var
  LSkin: IQ3Skin;
begin
  LSkin := FParser.Parse('s.skin', AnsiString(StringOfChar('A', 70)) + ',shader');
  Assert.AreEqual(StringOfChar('a', 63), string(LSkin.Surfaces[0].Name));
end;

procedure TTestModelsQ3SkinValues.DovrebbeIgnorareLeSuperficiOltreLeTrentaduaConUnAvviso;
var
  LText: AnsiString;
  LIndex: Integer;
  LSkin: IQ3Skin;
begin
  // the original overflows the structure here
  LText := '';
  for LIndex := 1 to 40 do
    LText := LText + AnsiString(Format('s%d,shader%d'#10, [LIndex, LIndex]));
  LSkin := FParser.Parse('many.skin', LText);
  Assert.AreEqual(Q3_MD3_MAX_SURFACES, LSkin.SurfaceCount);
  Assert.AreEqual('s32', string(LSkin.Surfaces[31].Name));
  Assert.AreEqual(1, FLog.Warnings.Count);
  Assert.IsTrue(FLog.Warnings[0].Contains('many.skin'));
end;

procedure TTestModelsQ3SkinValues.DovrebbeTrovareLaShaderPerNomeEsatto;
var
  LSkin: IQ3Skin;
  LShader: AnsiString;
begin
  LSkin := FParser.Parse('s.skin', 'a,one'#10'a,two'#10'b,three');
  Assert.IsTrue(LSkin.FindShader('a', LShader));
  Assert.AreEqual('one', string(LShader));
  Assert.IsTrue(LSkin.FindShader('b', LShader));
  Assert.IsFalse(LSkin.FindShader('A', LShader));
  Assert.AreEqual('', string(LShader));
end;

procedure TTestModelsQ3SkinValues.DovrebbeSollevareUnErroreSeLIndiceDellaSuperficieNonEsiste;
var
  LSkin: IQ3Skin;
begin
  LSkin := FParser.Parse('s.skin', 'a,one');
  Assert.IsTrue(Raises(
    procedure
    begin
      LSkin.Surfaces[1];
    end, EArgumentOutOfRangeException));
  Assert.IsTrue(Raises(
    procedure
    begin
      LSkin.Surfaces[-1];
    end, EArgumentOutOfRangeException));
end;

procedure TTestModelsQ3SkinValues.DovrebbeDareLaSkinPredefinitaPerLaManigliaZero;
begin
  Assert.AreEqual(1, FRegistry.SkinCount);
  Assert.AreEqual('<default skin>', string(FRegistry.GetSkin(0).Name));
  Assert.AreEqual(1, FRegistry.GetSkin(0).SurfaceCount);
  Assert.AreEqual('<default skin>', string(FRegistry.GetSkin(-3).Name));
  Assert.AreEqual('<default skin>', string(FRegistry.GetSkin(77).Name));
end;

procedure TTestModelsQ3SkinValues.DovrebbeDareLaStessaManigliaSenzaDistinguereLeMaiuscole;
var
  LHandle: Integer;
begin
  FFiles.Add('models/a.skin', 'x,y');
  LHandle := FRegistry.RegisterSkin('models/a.skin');
  Assert.AreEqual(1, LHandle);
  Assert.AreEqual(LHandle, FRegistry.RegisterSkin('MODELS/A.SKIN'));
  Assert.AreEqual(2, FRegistry.SkinCount);
  Assert.AreEqual('x', string(FRegistry.GetSkin(LHandle).Surfaces[0].Name));
end;

procedure TTestModelsQ3SkinValues.DovrebbeTrattareUnNomeSenzaSkinComeUnaSolaShader;
var
  LHandle: Integer;
begin
  LHandle := FRegistry.RegisterSkin('models/flag/red.tga');
  Assert.AreEqual(1, LHandle);
  Assert.AreEqual(1, FRegistry.GetSkin(LHandle).SurfaceCount);
  Assert.AreEqual('', string(FRegistry.GetSkin(LHandle).Surfaces[0].Name));
  Assert.AreEqual('models/flag/red.tga', string(FRegistry.GetSkin(LHandle).Surfaces[0].Shader));
  // the extension is compared with the case: ".SKIN" is a shader name
  Assert.AreEqual(2, FRegistry.RegisterSkin('a.SKIN'));
  // a name shorter than the extension too
  Assert.AreEqual(3, FRegistry.RegisterSkin('x'));
end;

procedure TTestModelsQ3SkinValues.DovrebbeDareZeroPerUnFileMancanteECiascunaVoltaSenzaRileggerlo;
begin
  Assert.AreEqual(0, FRegistry.RegisterSkin('models/none.skin'));
  // the failed skin took a handle and stays in the list as a skin without surfaces
  Assert.AreEqual(2, FRegistry.SkinCount);
  FFiles.Add('models/none.skin', 'a,b');
  Assert.AreEqual(0, FRegistry.RegisterSkin('models/none.skin'));
  Assert.AreEqual(2, FRegistry.SkinCount);
  // a file with no surfaces
  FFiles.Add('models/tags.skin', 'tag_a,');
  Assert.AreEqual(0, FRegistry.RegisterSkin('models/tags.skin'));
  Assert.AreEqual(3, FRegistry.SkinCount);
  Assert.AreEqual('<default skin>', string(FRegistry.GetSkin(1).Name));
end;

procedure TTestModelsQ3SkinValues.DovrebbeRifiutareNomiVuotiETroppoLunghi;
begin
  Assert.AreEqual(0, FRegistry.RegisterSkin(''));
  Assert.AreEqual(0, FRegistry.RegisterSkin(AnsiString(StringOfChar('a', 64))));
  Assert.AreEqual(1, FRegistry.SkinCount);
  Assert.AreEqual(2, FLog.Warnings.Count);
  Assert.AreEqual(SQ3SkinEmptyName, FLog.Warnings[0]);
  Assert.AreEqual(SQ3SkinNameTooLong, FLog.Warnings[1]);
  // 63 characters are fine
  Assert.AreEqual(1, FRegistry.RegisterSkin(AnsiString(StringOfChar('a', 63))));
end;

procedure TTestModelsQ3SkinValues.DovrebbeFermarsiAlleMilleVentiquattroSkin;
var
  LIndex: Integer;
begin
  for LIndex := 1 to Q3_MAX_SKINS - 1 do
    Assert.AreEqual(LIndex, FRegistry.RegisterSkin(AnsiString('shader' + IntToStr(LIndex))));
  Assert.AreEqual(Q3_MAX_SKINS, FRegistry.SkinCount);
  Assert.AreEqual(0, FRegistry.RegisterSkin('one_more'));
  Assert.AreEqual(Q3_MAX_SKINS, FRegistry.SkinCount);
  Assert.AreEqual(1, FLog.Warnings.Count);
  // the ones registered before still answer
  Assert.AreEqual(5, FRegistry.RegisterSkin('shader5'));
end;

procedure TTestModelsQ3SkinValues.DovrebbeSollevareUnErroreSeMancaUnaDipendenza;
begin
  Assert.IsTrue(Raises(
    procedure
    begin
      TQ3SkinRegistry.Create(nil, FParser, nil);
    end, EArgumentNilException));
  Assert.IsTrue(Raises(
    procedure
    begin
      TQ3SkinRegistry.Create(FFiles, nil, nil);
    end, EArgumentNilException));
  // a missing log is fine
  Assert.AreEqual(0, TQ3PlayerFactory.CreateSkinRegistry(FFiles, nil).RegisterSkin(''));
  Assert.AreEqual(1, TQ3PlayerFactory.CreateSkinParser(nil).Parse('a', 'a,b').SurfaceCount);
end;

procedure TTestModelsQ3SkinValues.DovrebbeSceglierLaShaderDellaSkinPerNomeDiSuperficie;
var
  LModel: IMd3Model;
  LSkin: IQ3Skin;
  LShaders: TArray<AnsiString>;
begin
  LModel := TQ3PlayerFactory.CreateModelSource(FFiles, nil).RegisterModel('x');
  Assert.IsNull(LModel);
  FFiles.Add('m.md3', BuildSkinnedMd3(1, ['tag_a'], ['Body_1', 'head', 'arm'], ['own_body', '', 'own_arm']));
  LModel := TQ3PlayerFactory.CreateModelSource(FFiles, nil).RegisterModel('m.md3');
  Assert.AreEqual(3, LModel.NumSurfaces);
  LSkin := FParser.Parse('s.skin', 'body,skin_body'#10'head,skin_head'#10'leg,skin_leg');
  LShaders := TQ3PlayerFactory.CreateSkinShaderResolver.Resolve(LModel, LSkin, 5);
  Assert.AreEqual<Integer>(3, Length(LShaders));
  Assert.AreEqual('skin_body', string(LShaders[0]));
  Assert.AreEqual('skin_head', string(LShaders[1]));
  // no line for the surface: the default shader, and not the one of the MD3
  Assert.AreEqual('', string(LShaders[2]));
end;

procedure TTestModelsQ3SkinValues.DovrebbeSceglierLaShaderDelModelloSenzaSkin;
var
  LModel: IMd3Model;
  LShaders: TArray<AnsiString>;
begin
  FFiles.Add('m.md3', BuildSkinnedMd3(2, ['tag_a'], ['body', 'head'], ['own_body', '']));
  LModel := TQ3PlayerFactory.CreateModelSource(FFiles, nil).RegisterModel('m.md3');
  // with the shaders of the file: skin number mod the shaders (one here); the surface with none is the default
  LShaders := TQ3PlayerFactory.CreateSkinShaderResolver.Resolve(LModel, nil, 3);
  Assert.AreEqual('own_body', string(LShaders[0]));
  Assert.AreEqual('', string(LShaders[1]));
end;

procedure TTestModelsQ3SkinValues.DovrebbeSollevareUnErroreSeLoSkinNumeroENegativoOIlModelloManca;
var
  LModel: IMd3Model;
  LResolver: IQ3SkinShaderResolver;
begin
  FFiles.Add('m.md3', BuildSkinnedMd3(1, ['tag_a'], ['body'], ['own_body']));
  LModel := TQ3PlayerFactory.CreateModelSource(FFiles, nil).RegisterModel('m.md3');
  LResolver := TQ3PlayerFactory.CreateSkinShaderResolver;
  Assert.IsTrue(Raises(
    procedure
    begin
      LResolver.Resolve(LModel, nil, -1);
    end, EArgumentOutOfRangeException));
  Assert.IsTrue(Raises(
    procedure
    begin
      LResolver.Resolve(nil, nil, 0);
    end, EArgumentNilException));
end;

end.
