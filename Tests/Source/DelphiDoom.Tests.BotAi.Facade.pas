{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the facade of the bot AI (TBotAiFactory)               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.Facade;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('BotAi.Facade')]
  TTestBotAiFacade = class
  public
    [Test]
    procedure DovrebbeCrearePerOgniSistemaUnOggetto;
    [Test]
    procedure DovrebbeDareGliHandleDelC;
    [Test]
    procedure DovrebbeDareUnaFacciataPerOgniChiamata;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.LibVars.Intf, DelphiDoom.BotAi.LibVars.Table,
  DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.World.AasWorld, DelphiDoom.BotAi.Facade.Intf,
  DelphiDoom.BotAi.Facade.Factory, DelphiDoom.Tests.BotAi.Support;

function CreateAi: IBotAi;
var
  LImport: IBotImport;
  LFiles: IBotFileSource;
  LVars: IBotLibVarStore;
  LRandom: IBotRandom;
  LWorld: IBotAasWorld;
begin
  LImport := TFakeBotImport.Create;
  LFiles := TMemoryBotFiles.Create;
  LVars := TBotLibVarTable.Create;
  LRandom := TSequenceRandom.Create([0.5]);
  LWorld := TBotAasWorld.Create(nil, nil, nil);
  Result := TBotAiFactory.CreateAi(LImport, LFiles, LVars, LRandom, LWorld, 8, False);
end;

{ TTestBotAiFacade }

procedure TTestBotAiFacade.DovrebbeCrearePerOgniSistemaUnOggetto;
var
  LAi: IBotAi;
begin
  LAi := CreateAi;
  Assert.IsTrue(Assigned(LAi.Characters), 'caratteri');
  Assert.IsTrue(Assigned(LAi.Chat), 'chat');
  Assert.IsTrue(Assigned(LAi.Weights), 'pesi');
  Assert.IsTrue(Assigned(LAi.Weapons), 'armi');
  Assert.IsTrue(Assigned(LAi.Goals), 'obiettivi');
  Assert.IsTrue(Assigned(LAi.Moves), 'movimento');
  Assert.IsTrue(Assigned(LAi.Genetics), 'selezione genetica');
  Assert.IsTrue(Assigned(LAi.Actions), 'azioni elementari');
end;

procedure TTestBotAiFacade.DovrebbeDareGliHandleDelC;
var
  LAi: IBotAi;
begin
  LAi := CreateAi;
  // the handles of the C go from 1
  Assert.AreEqual(1, LAi.Moves.AllocMoveState);
  Assert.AreEqual(2, LAi.Moves.AllocMoveState);
  Assert.AreEqual(1, LAi.Goals.AllocGoalState(3));
  Assert.AreEqual(1, LAi.Weapons.AllocWeaponState);
  Assert.AreEqual(1, LAi.Chat.AllocChatState);
end;

procedure TTestBotAiFacade.DovrebbeDareUnaFacciataPerOgniChiamata;
var
  LFirst: IBotAi;
  LSecond: IBotAi;
begin
  LFirst := CreateAi;
  LSecond := CreateAi;
  Assert.AreEqual(1, LFirst.Moves.AllocMoveState);
  // nothing is shared: the second one starts from the first handle too
  Assert.AreEqual(1, LSecond.Moves.AllocMoveState);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBotAiFacade);

end.
