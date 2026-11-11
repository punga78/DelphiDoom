{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the basic constants of the scripts                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.ConstantsBasic;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Constants.Intf,
  DelphiDoom.Tests.ScriptHost.ConstantFakes;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostConstantsBasic = class(TObject)
  private
    FTable: TRecordingConstantTable;
    FInterface: IScriptConstantTable;
    FProvider: IScriptConstantProvider;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareQuattroCostantiNellOrdineDelVecchioCodice;
    [Test]
    procedure DovrebbeDareNaNEInfiniti;
    [Test]
    procedure DovrebbeDareMaxIntCheEIlMassimoDeiNumeriInteri;
    [Test]
    procedure DovrebbeDareLeTreCostantiRealiComeExtended;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.ScriptHost.Constants.Basic;

procedure TTestScriptHostConstantsBasic.Setup;
begin
  FTable := TRecordingConstantTable.Create;
  FInterface := FTable;
  FProvider := TScriptBasicConstants.Create;
  FProvider.Describe(FInterface);
end;

procedure TTestScriptHostConstantsBasic.TearDown;
begin
  FProvider := nil;
  FInterface := nil;
  FTable := nil;
end;

procedure TTestScriptHostConstantsBasic.DovrebbeDareQuattroCostantiNellOrdineDelVecchioCodice;
begin
  Assert.AreEqual(4, FTable.Entries.Count);
  Assert.IsTrue(FTable.Entries[0].StartsWith('NaN:'));
  Assert.IsTrue(FTable.Entries[1].StartsWith('Infinity:'));
  Assert.IsTrue(FTable.Entries[2].StartsWith('NegInfinity:'));
  Assert.IsTrue(FTable.Entries[3].StartsWith('MAXINT:'));
end;

procedure TTestScriptHostConstantsBasic.DovrebbeDareNaNEInfiniti;
begin
  Assert.AreEqual('NaN:extended=NAN', FTable.Entries[0]);
  Assert.AreEqual('Infinity:extended=INF', FTable.Entries[1]);
  Assert.AreEqual('NegInfinity:extended=-INF', FTable.Entries[2]);
end;

procedure TTestScriptHostConstantsBasic.DovrebbeDareMaxIntCheEIlMassimoDeiNumeriInteri;
begin
  Assert.AreEqual('MAXINT:integer=2147483647', FTable.Entries[3]);
end;

procedure TTestScriptHostConstantsBasic.DovrebbeDareLeTreCostantiRealiComeExtended;
begin
  Assert.IsTrue(FTable.Entries[0].Contains(':extended='));
  Assert.IsTrue(FTable.Entries[1].Contains(':extended='));
  Assert.IsTrue(FTable.Entries[2].Contains(':extended='));
end;

end.
