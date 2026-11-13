{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - TIdDictLister                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.IdDictLister;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Scanner.IdDict,
  DelphiDoom.Scanner.IdDictLister, DelphiDoom.Tests.Scanner.IdFakes;

type
  [TestFixture]
  [Category('IdDict')]
  TTestIdDictLister = class
  strict private
    FLog: TFakeIdLibLog;
    FLogIntf: IIdLibLog;
    FLister: TIdDictLister;
    FFirst: TIdDict;
    FSecond: TIdDict;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeElencareLeChiaviDistinteSenzaMaiuscoleEOrdinate;
    [Test]
    procedure DovrebbeElencareIValoriDistintiConLeMaiuscole;
    [Test]
    procedure DovrebbeContareZeroStringheSenzaDizionari;
    [Test]
    procedure DovrebbeTenereLOrdineDiIncontroPerIValoriUgualiSenzaMaiuscole;
    [Test]
    procedure DovrebbeEssereMutoSenzaLog;
  end;

implementation

procedure TTestIdDictLister.Setup;
begin
  FLog := TFakeIdLibLog.Create;
  FLogIntf := FLog;
  FLister := TIdDictLister.Create(FLogIntf);
  FFirst := TIdDict.Create;
  FSecond := TIdDict.Create;
  FFirst.SetValue('Zeta', 'one');
  FFirst.SetValue('alpha', 'Two');
  FSecond.SetValue('ZETA', 'one');
  FSecond.SetValue('Beta', 'two');
  FSecond.SetValue('gamma', '');
end;

procedure TTestIdDictLister.TearDown;
begin
  FSecond.Free;
  FFirst.Free;
  FLister.Free;
  FLogIntf := nil;
end;

procedure TTestIdDictLister.DovrebbeElencareLeChiaviDistinteSenzaMaiuscoleEOrdinate;
begin
  FLister.ListKeys([FFirst, FSecond]);
  Assert.AreEqual(5, FLog.Lines.Count);
  Assert.AreEqual('P: alpha\n', FLog.Lines[0]);
  Assert.AreEqual('P: Beta\n', FLog.Lines[1]);
  Assert.AreEqual('P: gamma\n', FLog.Lines[2]);
  // the first spelling of a key is the one the pool keeps
  Assert.AreEqual('P: Zeta\n', FLog.Lines[3]);
  Assert.AreEqual('P:     4 keys\n', FLog.Lines[4]);
end;

procedure TTestIdDictLister.DovrebbeElencareIValoriDistintiConLeMaiuscole;
begin
  FLister.ListValues([FFirst, FSecond]);
  Assert.AreEqual(5, FLog.Lines.Count);
  Assert.AreEqual('P: \n', FLog.Lines[0]);
  Assert.AreEqual('P: one\n', FLog.Lines[1]);
  Assert.AreEqual('P: Two\n', FLog.Lines[2]);
  Assert.AreEqual('P: two\n', FLog.Lines[3]);
  Assert.AreEqual('P:     4 values\n', FLog.Lines[4]);
end;

procedure TTestIdDictLister.DovrebbeContareZeroStringheSenzaDizionari;
begin
  FLister.ListKeys([]);
  FLister.ListValues([]);
  Assert.AreEqual(2, FLog.Lines.Count);
  Assert.AreEqual('P:     0 keys\n', FLog.Lines[0]);
  Assert.AreEqual('P:     0 values\n', FLog.Lines[1]);
end;

procedure TTestIdDictLister.DovrebbeTenereLOrdineDiIncontroPerIValoriUgualiSenzaMaiuscole;
var
  LDict: TIdDict;
begin
  LDict := TIdDict.Create;
  try
    LDict.SetValue('a', 'Ab');
    LDict.SetValue('b', 'aB');
    LDict.SetValue('c', 'AB');
    FLister.ListValues([LDict]);
    Assert.AreEqual('P: Ab\n', FLog.Lines[0]);
    Assert.AreEqual('P: aB\n', FLog.Lines[1]);
    Assert.AreEqual('P: AB\n', FLog.Lines[2]);
    Assert.AreEqual('P:     3 values\n', FLog.Lines[3]);
  finally
    LDict.Free;
  end;
end;

procedure TTestIdDictLister.DovrebbeEssereMutoSenzaLog;
var
  LSilent: TIdDictLister;
begin
  LSilent := TIdDictLister.Create(nil);
  try
    LSilent.ListKeys([FFirst]);
    LSilent.ListValues([FFirst]);
    Assert.AreEqual(0, FLog.Lines.Count);
  finally
    LSilent.Free;
  end;
end;

end.
