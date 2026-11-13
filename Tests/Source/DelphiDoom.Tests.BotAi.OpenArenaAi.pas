{******************************************************************************}
{                                                                              }
{  DelphiDoom: the character, weight and weapon files of OpenArena (DUnitX)    }
{                                                                              }
{  The tests read botfiles\ of pak6-misc.pk3 of OpenArena 0.8.8 (GPL v2) where  }
{  it is (DELPHIDOOM_OPENARENA = the pk3, or Reference\openarena); without it   }
{  they are ignored. Nothing of OpenArena is in the repository.                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.OpenArenaAi;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('BotAi')]
  [Category('OpenArena')]
  TTestBotOpenArenaAi = class
  strict private
    function Pk3Path: string;
  public
    [Test]
    procedure DovrebbeLeggereTuttiIFileDeiCaratteriConOgniSkill;
    [Test]
    procedure DovrebbeSegnalareIlNumeroConDuePuntiDiSergeiCheIlCAccetta;
    [Test]
    procedure DovrebbeLeggereTuttiIFileDeiPesiSenzaErrori;
    [Test]
    procedure DovrebbeLeggereLeArmiEIPesiDelleArmi;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCSuiFileDiOpenArena;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.Exceptions, DelphiDoom.BotAi.Import.Intf,
  DelphiDoom.BotAi.Types, DelphiDoom.BotAi.LibVars.Table, DelphiDoom.BotAi.Character.Intf,
  DelphiDoom.BotAi.Character.Factory, DelphiDoom.BotAi.Weight.Config, DelphiDoom.BotAi.Weight.Intf,
  DelphiDoom.BotAi.Weight.Factory, DelphiDoom.BotAi.Weapon.Intf, DelphiDoom.BotAi.Weapon.Factory,
  DelphiDoom.BotAi.Weight.Evaluator, DelphiDoom.Tests.BotAi.Support, DelphiDoom.Tests.BotAi.AiScenarioRunner;

{ TTestBotOpenArenaAi }

function TTestBotOpenArenaAi.Pk3Path: string;
var
  LRelative: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_OPENARENA');
  if (Result <> '') and TFile.Exists(Result) then
    Exit;
  LRelative := '..\..\Reference\openarena\openarena-0.8.8\baseoa\pak6-misc.pk3';
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), LRelative));
  if not TFile.Exists(Result) then
    raise ETestIgnored.Create('pak6-misc.pk3 di OpenArena non c''e'' (DELPHIDOOM_OPENARENA o Reference\openarena): prova ignorata');
end;

procedure TTestBotOpenArenaAi.DovrebbeLeggereTuttiIFileDeiCaratteriConOgniSkill;
var
  LImport: TFakeBotImport;
  LImportRef: IBotImport;
  LLibVars: TBotLibVarTable;
  LLibVarsRef: IInterface;
  LFiles: TZipBotFiles;
  LFilesRef: IBotFileSource;
  LSystem: IBotCharacterSystem;
  LName: string;
  LSkill: Single;
  LHandle: Integer;
  LCount: Integer;
  LLine: string;
begin
  LImport := TFakeBotImport.Create;
  LImportRef := LImport;
  LLibVars := TBotLibVarTable.Create;
  LLibVarsRef := LLibVars;
  LFiles := TZipBotFiles.Create(Pk3Path);
  LFilesRef := LFiles;
  LSystem := TBotCharacterFactory.CreateCharacterSystem(LImport, LFiles, LLibVars);
  LCount := 0;
  for LName in LFiles.Names do
  begin
    // sergei_c.c has a typo (0..30): l_script.c reads it as a number, TIdLexer reports it
    if not (LName.StartsWith('botfiles/bots/') and LName.EndsWith('_c.c')) or LName.EndsWith('/sergei_c.c') then
      Continue;
    for LSkill in [1.0, 2.5, 4.0, 4.5, 5.0] do
    begin
      LHandle := LSystem.LoadCharacter(AnsiString(Copy(LName, Length('botfiles/') + 1, MaxInt)), LSkill);
      Assert.IsTrue(LHandle > 0, LName + ': ' + LImport.Lines.Text);
      // every character has its name
      Assert.IsTrue(LSystem.CharacteristicString(LHandle, 0, 40) <> '', LName);
    end;
    Inc(LCount);
    LSystem.Shutdown;
  end;
  for LLine in LImport.Lines do
    Assert.IsFalse(LLine.StartsWith('P3|') or LLine.StartsWith('P4|'), LLine);
  Assert.IsTrue(LCount >= 20, 'caratteri trovati: ' + IntToStr(LCount));
end;

procedure TTestBotOpenArenaAi.DovrebbeLeggereTuttiIFileDeiPesiSenzaErrori;
var
  LImport: TFakeBotImport;
  LImportRef: IBotImport;
  LLibVars: TBotLibVarTable;
  LLibVarsRef: IInterface;
  LFiles: TZipBotFiles;
  LFilesRef: IBotFileSource;
  LCache: IBotWeightCache;
  LName: string;
  LConfig: TBotWeightConfig;
  LCount: Integer;
  LLine: string;
  LEvaluator: TBotFuzzyEvaluator;
  LInventory: TArray<Integer>;
begin
  LImport := TFakeBotImport.Create;
  LImportRef := LImport;
  LLibVars := TBotLibVarTable.Create;
  LLibVarsRef := LLibVars;
  // many files: the cache keeps 128
  LLibVars.SetText('bot_reloadcharacters', '1');
  LFiles := TZipBotFiles.Create(Pk3Path);
  LFilesRef := LFiles;
  LCache := TBotWeightFactory.CreateWeightCache(LImport, LFiles, LLibVars);
  LEvaluator := TBotFuzzyEvaluator.Create(nil);
  try
    SetLength(LInventory, 1024);
    LCount := 0;
    for LName in LFiles.Names do
    begin
      // default_w.c and default_i.c are templates: their weights are macros that the bot files define
      if not (LName.StartsWith('botfiles/') and (LName.EndsWith('_w.c') or LName.EndsWith('_i.c'))) or
        LName.EndsWith('/default_w.c') or LName.EndsWith('/default_i.c') then
        Continue;
      LConfig := LCache.ReadWeightConfig(AnsiString(Copy(LName, Length('botfiles/') + 1, MaxInt)));
      Assert.IsNotNull(LConfig, LName + ': ' + LImport.Lines.Text);
      if LConfig.Count > 0 then
        LEvaluator.FuzzyWeight(LInventory, LConfig, 0);
      LCache.FreeWeightConfig(LConfig);
      Inc(LCount);
    end;
  finally
    LEvaluator.Free;
  end;
  for LLine in LImport.Lines do
    Assert.IsFalse(LLine.StartsWith('P3|') or LLine.StartsWith('P4|'), LLine);
  Assert.IsTrue(LCount >= 20, 'file dei pesi trovati: ' + IntToStr(LCount));
end;

procedure TTestBotOpenArenaAi.DovrebbeLeggereLeArmiEIPesiDelleArmi;
var
  LImport: TFakeBotImport;
  LImportRef: IBotImport;
  LLibVars: TBotLibVarTable;
  LLibVarsRef: IInterface;
  LFiles: TZipBotFiles;
  LFilesRef: IBotFileSource;
  LCache: IBotWeightCache;
  LWeapons: IBotWeaponSystem;
  LName: string;
  LState: Integer;
  LLine: string;
  LCount: Integer;
  LInventory: TArray<Integer>;
begin
  SetLength(LInventory, 1024);
  LImport := TFakeBotImport.Create;
  LImportRef := LImport;
  LLibVars := TBotLibVarTable.Create;
  LLibVarsRef := LLibVars;
  LFiles := TZipBotFiles.Create(Pk3Path);
  LFilesRef := LFiles;
  LCache := TBotWeightFactory.CreateWeightCache(LImport, LFiles, LLibVars);
  LWeapons := TBotWeaponFactory.CreateWeaponSystem(LImport, LFiles, LLibVars, LCache);
  Assert.AreEqual(BLERR_NOERROR, LWeapons.Setup, LImport.Lines.Text);
  Assert.IsTrue(LWeapons.Config.NumProjectiles > 5);
  LCount := 0;
  for LName in LFiles.Names do
  begin
    if not (LName.StartsWith('botfiles/bots/') and LName.EndsWith('_w.c')) or LName.EndsWith('/default_w.c') then
      Continue;
    LState := LWeapons.AllocWeaponState;
    Assert.AreEqual(BLERR_NOERROR, LWeapons.LoadWeaponWeights(LState, AnsiString(Copy(LName, Length('botfiles/') + 1, MaxInt))),
      LName + ': ' + LImport.Lines.Text);
    LWeapons.ChooseBestFightWeapon(LState, LInventory);
    LWeapons.FreeWeaponState(LState);
    Inc(LCount);
  end;
  for LLine in LImport.Lines do
    Assert.IsFalse(LLine.StartsWith('P3|') or LLine.StartsWith('P4|'), LLine);
  Assert.IsTrue(LCount >= 20, 'pesi delle armi trovati: ' + IntToStr(LCount));
end;

procedure TTestBotOpenArenaAi.DovrebbeDareLeStesseRisposteDelCSuiFileDiOpenArena;
var
  LFolder: string;
  LScenario: TStringList;
  LGolden: TStringList;
  LRunner: TBotAiScenarioRunner;
  LIndex: Integer;
begin
  // the folder (DELPHIDOOM_OA_PARITY) has botfiles\ of OpenArena, oa_scenario.txt and oa_golden.txt, which the
  // C tool of Tools\Verifica\123 writes (see its LEGGIMI.md): nothing of OpenArena is in the repository
  LFolder := GetEnvironmentVariable('DELPHIDOOM_OA_PARITY');
  if (LFolder = '') or not TFile.Exists(TPath.Combine(LFolder, 'oa_golden.txt')) then
    raise ETestIgnored.Create('DELPHIDOOM_OA_PARITY non impostata: prova ignorata');
  LScenario := TStringList.Create;
  LGolden := TStringList.Create;
  LRunner := TBotAiScenarioRunner.Create(TFolderBotFiles.Create(LFolder));
  try
    LScenario.LoadFromFile(TPath.Combine(LFolder, 'oa_scenario.txt'), TEncoding.ANSI);
    LGolden.LoadFromFile(TPath.Combine(LFolder, 'oa_golden.txt'), TEncoding.ANSI);
    LRunner.Run(LScenario);
    for LIndex := 0 to LGolden.Count - 1 do
    begin
      if LIndex >= LRunner.Output.Count then
        Break;
      Assert.AreEqual(LGolden[LIndex].TrimRight, LRunner.Output[LIndex].TrimRight, 'riga ' + IntToStr(LIndex + 1));
    end;
    Assert.AreEqual(LGolden.Count, LRunner.Output.Count, 'numero di righe');
  finally
    LRunner.Free;
    LGolden.Free;
    LScenario.Free;
  end;
end;

procedure TTestBotOpenArenaAi.DovrebbeSegnalareIlNumeroConDuePuntiDiSergeiCheIlCAccetta;
var
  LImport: TFakeBotImport;
  LImportRef: IBotImport;
  LLibVars: TBotLibVarTable;
  LLibVarsRef: IInterface;
  LFiles: TZipBotFiles;
  LFilesRef: IBotFileSource;
  LSystem: IBotCharacterSystem;
begin
  LImport := TFakeBotImport.Create;
  LImportRef := LImport;
  LLibVars := TBotLibVarTable.Create;
  LLibVarsRef := LLibVars;
  LFiles := TZipBotFiles.Create(Pk3Path);
  LFilesRef := LFiles;
  LSystem := TBotCharacterFactory.CreateCharacterSystem(LImport, LFiles, LLibVars);
  // "0..30" is a number for l_script.c (a float of a strange value); TIdLexer, the lexer of the bots here, refuses
  // it, so the character is replaced by the default one (a difference of the lexers, see README.md)
  Assert.IsTrue(LSystem.LoadCharacter('bots/sergei_c.c', 1) > 0);
  Assert.Contains(LImport.Lines.Text, 'more than one dot in number');
end;

end.
