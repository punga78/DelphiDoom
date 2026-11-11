{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the chain of providers of constants                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.ConstantChain;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostConstantChain = class(TObject)
  public
    [Test]
    procedure DovrebbeNonScrivereNullaSeNonHaProvider;
    [Test]
    procedure DovrebbeChiedereAiProviderNellOrdineDato;
    [Test]
    procedure DovrebbeChiedereOgniVoltaATuttiIProvider;
    [Test]
    procedure DovrebbeDareErroreSeUnProviderEnil;
    [Test]
    procedure DovrebbeDareLeCostantiDellaFabbricaNellOrdineDelVecchioCodice;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.ScriptHost.Constants.Chain,
  DelphiDoom.ScriptHost.Constants.Intf,
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.Tests.ScriptHost.ConstantFakes;

procedure TTestScriptHostConstantChain.DovrebbeNonScrivereNullaSeNonHaProvider;
var
  LTable: TRecordingConstantTable;
  LInterface: IScriptConstantTable;
  LChain: IScriptConstantProvider;
begin
  LTable := TRecordingConstantTable.Create;
  LInterface := LTable;
  LChain := TScriptConstantChain.Create([]);
  LChain.Describe(LInterface);
  Assert.AreEqual(0, LTable.Entries.Count);
end;

procedure TTestScriptHostConstantChain.DovrebbeChiedereAiProviderNellOrdineDato;
var
  LTable: TRecordingConstantTable;
  LInterface: IScriptConstantTable;
  LChain: IScriptConstantProvider;
begin
  LTable := TRecordingConstantTable.Create;
  LInterface := LTable;
  LChain := TScriptConstantChain.Create([TFakeConstantProvider.Create(['A', 'B']),
    TFakeConstantProvider.Create(['C']), TFakeConstantProvider.Create(['D', 'E'])]);
  LChain.Describe(LInterface);
  Assert.AreEqual('A,B,C,D,E', string.Join(',', [LTable.Entries[0].Substring(0, 1), LTable.Entries[1].Substring(0, 1),
    LTable.Entries[2].Substring(0, 1), LTable.Entries[3].Substring(0, 1), LTable.Entries[4].Substring(0, 1)]));
end;

procedure TTestScriptHostConstantChain.DovrebbeChiedereOgniVoltaATuttiIProvider;
var
  LTable: TRecordingConstantTable;
  LInterface: IScriptConstantTable;
  LFirst: TFakeConstantProvider;
  LFirstInterface: IScriptConstantProvider;
  LChain: IScriptConstantProvider;
begin
  LTable := TRecordingConstantTable.Create;
  LInterface := LTable;
  LFirst := TFakeConstantProvider.Create(['A']);
  LFirstInterface := LFirst;
  LChain := TScriptConstantChain.Create([LFirstInterface]);
  LChain.Describe(LInterface);
  LChain.Describe(LInterface);
  Assert.AreEqual(2, LFirst.Asked);
  Assert.AreEqual(2, LTable.Entries.Count);
end;

procedure TTestScriptHostConstantChain.DovrebbeDareErroreSeUnProviderEnil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptConstantChain.Create([TFakeConstantProvider.Create(['A']), nil]);
    end, EArgumentNilException);
end;

procedure TTestScriptHostConstantChain.DovrebbeDareLeCostantiDellaFabbricaNellOrdineDelVecchioCodice;
var
  LTable: TRecordingConstantTable;
  LInterface: IScriptConstantTable;
  LProvider: IScriptConstantProvider;
  LIndex: Integer;
  LNames: string;
begin
  LTable := TRecordingConstantTable.Create;
  LInterface := LTable;
  LProvider := TScriptHostFactory.CreateConstants(TFakeConstantProvider.Create(['MOBJ_X']),
    TFakeConstantProvider.Create(['GAME_X']), TFakeConstantProvider.Create(['WORLD_X']),
    TFakeConstantProvider.Create(['GROUP_X']));
  LProvider.Describe(LInterface);
  LNames := '';
  for LIndex := 0 to LTable.Entries.Count - 1 do
    LNames := LNames + '|' + Copy(LTable.Entries[LIndex], 1, Pos(':', LTable.Entries[LIndex]) - 1);
  // the basic ones, the mobjs, the game and the world, the generalized ones, the groups
  Assert.IsTrue(LNames.StartsWith('|NaN|Infinity|NegInfinity|MAXINT|MOBJ_X|GAME_X|WORLD_X|DAMAGE_MASK|'), LNames);
  Assert.IsTrue(LNames.EndsWith('|LockedSpeedShift|GROUP_X'), LNames);
end;

end.
