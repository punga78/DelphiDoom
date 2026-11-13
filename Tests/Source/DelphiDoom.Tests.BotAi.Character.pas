{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the characters of the bots (DUnitX)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.Character;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.LibVars.Table,
  DelphiDoom.BotAi.Character.Intf, DelphiDoom.Tests.BotAi.Support;

type
  [TestFixture]
  [Category('BotAi')]
  TTestBotCharacter = class
  strict private
    FImport: TFakeBotImport;
    FImportRef: IBotImport;
    FFiles: TMemoryBotFiles;
    FFilesRef: IBotFileSource;
    FLibVars: TBotLibVarTable;
    FLibVarsRef: IInterface;
    FSystem: IBotCharacterSystem;
    function Printed: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereLeCaratteristicheDelLivelloRichiesto;
    [Test]
    procedure DovrebbeCompletareConLeCaratteristicheDelDefault;
    [Test]
    procedure DovrebbeInterpolareFraDueLivelli;
    [Test]
    procedure DovrebbeDareLaStessaInterpolazioneDaCache;
    [Test]
    procedure DovrebbeLimitareLaSkillTraUnoECinque;
    [Test]
    procedure DovrebbeAccettareUnLivelloSenzaParentesiGraffaDiChiusura;
    [Test]
    procedure DovrebbeDareZeroSeNessunFileHaLivelli;
    [Test]
    procedure DovrebbeDareZeroConUnaCaratteristicaDiTipoDiverso;
    [Test]
    procedure DovrebbeLimitareLeCaratteristicheTraMinimoEMassimo;
    [Test]
    procedure DovrebbeTagliareLaStringaAllaDimensioneDelBuffer;
    [Test]
    procedure DovrebbeSegnalareUnHandleFuoriIntervalloOInesistente;
    [Test]
    procedure DovrebbeLiberareIlCarattereSoloConBotReloadCharacters;
    [Test]
    procedure DovrebbeFinireLeCaratteristicheConShutdown;
    [Test]
    procedure DovrebbeDareNanSeIDueLivelliHannoLaStessaSkill;
    [Test]
    procedure DovrebbeLasciareInalteratoLAmbienteInVirgolaMobile;
    [Test]
    procedure DovrebbeDareIlMinimoDegliIntPerUnNan;
    [Test]
    procedure DovrebbeDareNilPerUnHandleFuoriIntervalloConFindCharacter;
    [Test]
    procedure DovrebbeScrivereNelLogLeCaratteristicheInterpolate;
  end;

implementation

uses
  System.Math, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Character.Types, DelphiDoom.BotAi.Character.Data,
  DelphiDoom.BotAi.Character.Interpolator, DelphiDoom.BotAi.Character.Factory;

const
  DEFAULT_FILE =
    'skill 1 { 0 "Def" 1 1 2 0.5 3 7 4 "text" } skill 4 { 0 "Def" 1 4 2 1.5 3 7 4 "text" } ' +
    'skill 5 { 0 "Def" 1 5 2 2.5 3 7 4 "text" 5 0.25 }';
  BOT_FILE =
    'skill 1 { 0 "Bot" 1 1 2 0.0 } skill 4 { 0 "Bot" 1 4 2 3.0 } skill 5 { 0 "Bot" 1 5 2 4.0 }';

{ TTestBotCharacter }

procedure TTestBotCharacter.Setup;
begin
  FImport := TFakeBotImport.Create;
  FImportRef := FImport;
  FFiles := TMemoryBotFiles.Create;
  FFilesRef := FFiles;
  FLibVars := TBotLibVarTable.Create;
  FLibVarsRef := FLibVars;
  FFiles.Add('botfiles/bots/default_c.c', DEFAULT_FILE);
  FFiles.Add('botfiles/bots/bot_c.c', BOT_FILE);
  FSystem := TBotCharacterFactory.CreateCharacterSystem(FImport, FFiles, FLibVars);
end;

procedure TTestBotCharacter.TearDown;
begin
  FSystem := nil;
  FLibVarsRef := nil;
  FFilesRef := nil;
  FImportRef := nil;
end;

function TTestBotCharacter.Printed: string;
begin
  Result := FImport.Lines.Text;
end;

procedure TTestBotCharacter.DovrebbeLeggereLeCaratteristicheDelLivelloRichiesto;
var
  LHandle: Integer;
begin
  LHandle := FSystem.LoadCharacter('bots/bot_c.c', 4);
  Assert.IsTrue(LHandle > 0);
  Assert.AreEqual(Double(3.0), Double(FSystem.CharacteristicFloat(LHandle, 2)));
  Assert.AreEqual(4, FSystem.CharacteristicInteger(LHandle, 1));
  Assert.AreEqual('Bot', string(FSystem.CharacteristicString(LHandle, 0, 40)));
end;

procedure TTestBotCharacter.DovrebbeCompletareConLeCaratteristicheDelDefault;
var
  LHandle: Integer;
begin
  LHandle := FSystem.LoadCharacter('bots/bot_c.c', 5);
  Assert.AreEqual(7, FSystem.CharacteristicInteger(LHandle, 3));
  Assert.AreEqual('text', string(FSystem.CharacteristicString(LHandle, 4, 40)));
  Assert.AreEqual(Double(0.25), Double(FSystem.CharacteristicFloat(LHandle, 5)));
end;

procedure TTestBotCharacter.DovrebbeInterpolareFraDueLivelli;
var
  LHandle: Integer;
begin
  // between skill 1 (0.0) and skill 4 (3.0): 2.5 is at 1.5 / 3
  LHandle := FSystem.LoadCharacter('bots/bot_c.c', 2.5);
  Assert.AreEqual(Double(1.5), Double(FSystem.CharacteristicFloat(LHandle, 2)), 0.00001);
  // the integers and the strings are the ones of the first level
  Assert.AreEqual(1, FSystem.CharacteristicInteger(LHandle, 1));
  // between skill 4 (3.0) and skill 5 (4.0)
  LHandle := FSystem.LoadCharacter('bots/bot_c.c', 4.5);
  Assert.AreEqual(Double(3.5), Double(FSystem.CharacteristicFloat(LHandle, 2)), 0.00001);
end;

procedure TTestBotCharacter.DovrebbeDareLaStessaInterpolazioneDaCache;
var
  LFirst: Integer;
begin
  LFirst := FSystem.LoadCharacter('bots/bot_c.c', 2.5);
  Assert.AreEqual(LFirst, FSystem.LoadCharacter('bots/bot_c.c', 2.5));
  Assert.Contains(Printed, 'loaded cached skill 2.500000 from bots/bot_c.c');
end;

procedure TTestBotCharacter.DovrebbeLimitareLaSkillTraUnoECinque;
begin
  Assert.AreEqual(Double(0.0), Double(FSystem.CharacteristicFloat(FSystem.LoadCharacter('bots/bot_c.c', 0.2), 2)));
  Assert.AreEqual(Double(4.0), Double(FSystem.CharacteristicFloat(FSystem.LoadCharacter('bots/bot_c.c', 9), 2)));
end;

procedure TTestBotCharacter.DovrebbeAccettareUnLivelloSenzaParentesiGraffaDiChiusura;
var
  LHandle: Integer;
begin
  FFiles.Add('botfiles/bots/open_c.c', 'skill 1 { 1 5');
  LHandle := FSystem.LoadCharacter('bots/open_c.c', 1);
  Assert.AreEqual(5, FSystem.CharacteristicInteger(LHandle, 1));
  Assert.Contains(Printed, 'couldn''t read expected token');
end;

procedure TTestBotCharacter.DovrebbeDareZeroSeNessunFileHaLivelli;
var
  LFiles: TMemoryBotFiles;
  LSystem: IBotCharacterSystem;
begin
  LFiles := TMemoryBotFiles.Create;
  LSystem := TBotCharacterFactory.CreateCharacterSystem(FImport, LFiles, FLibVars);
  Assert.AreEqual(0, LSystem.LoadCharacter('bots/none_c.c', 1));
  Assert.Contains(Printed, 'couldn''t load any skill from bots/none_c.c');
end;

procedure TTestBotCharacter.DovrebbeDareZeroConUnaCaratteristicaDiTipoDiverso;
var
  LHandle: Integer;
begin
  LHandle := FSystem.LoadCharacter('bots/bot_c.c', 1);
  Assert.AreEqual(Double(0.0), Double(FSystem.CharacteristicFloat(LHandle, 0)));
  Assert.Contains(Printed, 'characteristic 0 is not a float');
  Assert.AreEqual(0, FSystem.CharacteristicInteger(LHandle, 0));
  Assert.Contains(Printed, 'characteristic 0 is not a integer');
  Assert.AreEqual('', string(FSystem.CharacteristicString(LHandle, 1, 10)));
  Assert.Contains(Printed, 'characteristic 1 is not a string');
  Assert.AreEqual(Double(0.0), Double(FSystem.CharacteristicFloat(LHandle, 70)));
  Assert.Contains(Printed, 'characteristic 70 is not initialized');
  Assert.AreEqual(Double(0.0), Double(FSystem.CharacteristicFloat(LHandle, 80)));
  Assert.Contains(Printed, 'characteristic 80 does not exist');
end;

procedure TTestBotCharacter.DovrebbeLimitareLeCaratteristicheTraMinimoEMassimo;
var
  LHandle: Integer;
begin
  LHandle := FSystem.LoadCharacter('bots/bot_c.c', 4);
  Assert.AreEqual(Double(2.0), Double(FSystem.CharacteristicBoundedFloat(LHandle, 2, 0, 2)));
  Assert.AreEqual(Double(3.5), Double(FSystem.CharacteristicBoundedFloat(LHandle, 2, 3.5, 9)));
  Assert.AreEqual(Double(3.0), Double(FSystem.CharacteristicBoundedFloat(LHandle, 2, 0, 9)));
  Assert.AreEqual(Double(0.0), Double(FSystem.CharacteristicBoundedFloat(LHandle, 2, 5, 1)));
  Assert.Contains(Printed, 'cannot bound characteristic 2 between 5.000000 and 1.000000');
  Assert.AreEqual(3, FSystem.CharacteristicBoundedInteger(LHandle, 2, 0, 9));
  Assert.AreEqual(2, FSystem.CharacteristicBoundedInteger(LHandle, 2, 0, 2));
  Assert.AreEqual(5, FSystem.CharacteristicBoundedInteger(LHandle, 2, 5, 9));
  Assert.AreEqual(0, FSystem.CharacteristicBoundedInteger(LHandle, 2, 5, 1));
  Assert.Contains(Printed, 'cannot bound characteristic 2 between 5 and 1');
end;

procedure TTestBotCharacter.DovrebbeTagliareLaStringaAllaDimensioneDelBuffer;
var
  LHandle: Integer;
begin
  LHandle := FSystem.LoadCharacter('bots/bot_c.c', 1);
  Assert.AreEqual('Bo', string(FSystem.CharacteristicString(LHandle, 0, 3)));
  Assert.AreEqual('', string(FSystem.CharacteristicString(LHandle, 0, 0)));
end;

procedure TTestBotCharacter.DovrebbeSegnalareUnHandleFuoriIntervalloOInesistente;
begin
  Assert.AreEqual(Double(0.0), Double(FSystem.CharacteristicFloat(0, 1)));
  Assert.Contains(Printed, 'character handle 0 out of range');
  Assert.AreEqual(Double(0.0), Double(FSystem.CharacteristicBoundedFloat(65, 1, 0, 1)));
  Assert.AreEqual(0, FSystem.CharacteristicBoundedInteger(30, 1, 0, 1));
  Assert.Contains(Printed, 'invalid character 30');
  Assert.AreEqual('', string(FSystem.CharacteristicString(30, 1, 10)));
end;

procedure TTestBotCharacter.DovrebbeLiberareIlCarattereSoloConBotReloadCharacters;
var
  LHandle: Integer;
begin
  LHandle := FSystem.LoadCharacter('bots/bot_c.c', 1);
  FSystem.FreeCharacter(LHandle);
  Assert.IsNotNull(FSystem.FindCharacter(LHandle));
  FLibVars.SetText('bot_reloadcharacters', '1');
  FSystem.FreeCharacter(LHandle);
  Assert.IsNull(FSystem.FindCharacter(LHandle));
  FSystem.FreeCharacter(LHandle);
  Assert.Contains(Printed, 'invalid character ' + IntToStr(LHandle));
  FSystem.FreeCharacter(99);
  Assert.Contains(Printed, 'character handle 99 out of range');
end;

procedure TTestBotCharacter.DovrebbeFinireLeCaratteristicheConShutdown;
var
  LHandle: Integer;
begin
  LHandle := FSystem.LoadCharacter('bots/bot_c.c', 1);
  FSystem.Shutdown;
  Assert.IsNull(FSystem.FindCharacter(LHandle));
end;

procedure TTestBotCharacter.DovrebbeDareNanSeIDueLivelliHannoLaStessaSkill;
var
  LFirst: TBotCharacter;
  LSecond: TBotCharacter;
  LResult: TBotCharacter;
begin
  LFirst := TBotCharacter.Create;
  LSecond := TBotCharacter.Create;
  try
    LFirst.Skill := 2;
    LSecond.Skill := 2;
    LFirst.Characteristics[3].CharType := CT_FLOAT;
    LFirst.Characteristics[3].FloatValue := 1;
    LSecond.Characteristics[3].CharType := CT_FLOAT;
    LSecond.Characteristics[3].FloatValue := 1;
    LResult := TBotCharacterInterpolator.Interpolate(LFirst, LSecond, 3);
    try
      // 1 / 0 is not an error in the original (it gives an infinity: 0 * infinity is a NaN)
      Assert.IsTrue(IsNan(LResult.Characteristics[3].FloatValue));
      Assert.AreEqual(Double(3.0), Double(LResult.Skill));
    finally
      LResult.Free;
    end;
  finally
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestBotCharacter.DovrebbeLasciareInalteratoLAmbienteInVirgolaMobile;
var
  LBefore: TArithmeticExceptionMask;
  LFirst: TBotCharacter;
  LSecond: TBotCharacter;
begin
  LBefore := GetExceptionMask;
  LFirst := TBotCharacter.Create;
  LSecond := TBotCharacter.Create;
  try
    TBotCharacterInterpolator.Interpolate(LFirst, LSecond, 3).Free;
    Assert.IsTrue(LBefore = GetExceptionMask);
  finally
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestBotCharacter.DovrebbeDareIlMinimoDegliIntPerUnNan;
begin
  // the interpolation of two levels of the same skill (the file has only skill 2) gives a NaN
  FFiles.Add('botfiles/bots/two_c.c', 'skill 2 { 1 0.5 2 1 }');
  FFiles.Add('botfiles/bots/default_c.c', '// nothing');
  FSystem := TBotCharacterFactory.CreateCharacterSystem(FImport, FFiles, FLibVars);
  Assert.AreEqual(Low(Integer), FSystem.CharacteristicInteger(FSystem.LoadCharacter('bots/two_c.c', 2.5), 1));
end;

procedure TTestBotCharacter.DovrebbeDareNilPerUnHandleFuoriIntervalloConFindCharacter;
begin
  Assert.IsNull(FSystem.FindCharacter(0));
  Assert.IsNull(FSystem.FindCharacter(65));
end;

procedure TTestBotCharacter.DovrebbeScrivereNelLogLeCaratteristicheInterpolate;
begin
  FSystem.LoadCharacter('bots/bot_c.c', 2.5);
  Assert.Contains(FImport.Lines.Text, 'L|bots/bot_c.c');
  Assert.Contains(FImport.Lines.Text, 'L|    2 1.500000\x0A');
  Assert.Contains(FImport.Lines.Text, 'L|    0 Bot\x0A');
  Assert.Contains(FImport.Lines.Text, 'L|}\x0A');
end;

end.
