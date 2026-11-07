{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the TableExport library - the owners of the states     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TableExport.StateOwnersWriter;

interface

uses
  DUnitX.TestFramework, DelphiDoom.TableExport.Intf, DelphiDoom.Tests.TableExport.Fakes;

type
  [TestFixture]
  [Category('tableexport')]
  TTestTableExportStateOwnersWriter = class(TObject)
  private
    FStates: TFakeStates;
    FStatesIntf: IExportStateSource;
    FNames: IInterface;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestDovrebbeScrivereUnaRigaPerStato;
    [Test]
    procedure TestDovrebbeElencareIProprietariTraVirgolette;
    [Test]
    procedure TestDovrebbeScrivereUnaRigaSenzaProprietari;
    [Test]
    procedure TestDovrebbeRifiutareUnaSorgenteMancante;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.TableExport.Factory;

{ TTestTableExportStateOwnersWriter }

procedure TTestTableExportStateOwnersWriter.Setup;
begin
  FStates := TFakeStates.Create;
  FStatesIntf := FStates;
  FStates.AddState('NULL', 0, 0, 0);
  FStates.AddState('TROO', 0, 4, 0);
  FStates.AddState('TROO', 1, 4, 0);
  FStates.Names.AddRange(['S_NULL', 'S_FIRST', 'S_SECOND']);
  FNames := TFakeNames.Create;
end;

procedure TTestTableExportStateOwnersWriter.TearDown;
begin
  FNames := nil;
  FStatesIntf := nil;
end;

procedure TTestTableExportStateOwnersWriter.TestDovrebbeScrivereUnaRigaPerStato;
begin
  Assert.AreEqual('S_NULL='#13#10'S_FIRST='#13#10'S_SECOND='#13#10,
    TTableExportFactory.CreateStateOwnersWriter(FStatesIntf, FNames as IExportLookups).Write);
end;

procedure TTestTableExportStateOwnersWriter.TestDovrebbeElencareIProprietariTraVirgolette;
begin
  FStates.OwnerMap.Add(1, [0, 1]);
  Assert.IsTrue(Pos('S_FIRST="Thing0" "Thing1"'#13#10,
    TTableExportFactory.CreateStateOwnersWriter(FStatesIntf, FNames as IExportLookups).Write) > 0);
end;

procedure TTestTableExportStateOwnersWriter.TestDovrebbeScrivereUnaRigaSenzaProprietari;
begin
  FStates.OwnerMap.Add(2, []);
  Assert.IsTrue(Pos('S_SECOND='#13#10,
    TTableExportFactory.CreateStateOwnersWriter(FStatesIntf, FNames as IExportLookups).Write) > 0);
end;

procedure TTestTableExportStateOwnersWriter.TestDovrebbeRifiutareUnaSorgenteMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TTableExportFactory.CreateStateOwnersWriter(nil, FNames as IExportLookups);
    end, EArgumentNilException);
end;

end.
