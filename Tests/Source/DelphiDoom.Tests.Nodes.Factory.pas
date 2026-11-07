{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - the factory                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.Factory;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Nodes.Types, DelphiDoom.Nodes.Intf,
  DelphiDoom.Nodes.Factory, DelphiDoom.Tests.Nodes.Fakes;

type
  [TestFixture]
  [Category('nodes')]
  TTestNodesFactory = class(TObject)
  public
    [Test]
    procedure TestDovrebbeCreareIlRilevatoreDellaVersione;
    [Test]
    procedure TestDovrebbeCreareIlCercatoreDelleEtichetteGl;
    [Test]
    procedure TestDovrebbeCreareIlCostruttoreDelWadPerGlbsp;
    [Test]
    procedure TestDovrebbeLeggereUnGwa;
    [Test]
    procedure TestDovrebbeRifiutareUnaSorgenteMancante;
  end;

implementation

{ TTestNodesFactory }

procedure TTestNodesFactory.TestDovrebbeCreareIlRilevatoreDellaVersione;
var
  LSource: INodesLumpSource;
begin
  LSource := TFakeLumpSource.Create;
  Assert.IsNotNull(TNodesFactory.CreateGlDetector(LSource));
  Assert.AreEqual(0, TNodesFactory.CreateGlDetector(LSource).DetectVersion(0));
end;

procedure TTestNodesFactory.TestDovrebbeCreareIlCercatoreDelleEtichetteGl;
var
  LSource: INodesLumpSource;
begin
  LSource := TFakeLumpSource.Create;
  Assert.IsNotNull(TNodesFactory.CreateGlMapFinder(LSource));
end;

procedure TTestNodesFactory.TestDovrebbeCreareIlCostruttoreDelWadPerGlbsp;
var
  LSource: TFakeLumpSource;
  LRef: INodesLumpSource;
begin
  LSource := TFakeLumpSource.Create;
  LRef := LSource;
  LSource.Add('MAP01');
  Assert.IsNotNull(TNodesFactory.CreateGlbspInputBuilder(LRef, False));
  Assert.IsTrue(Length(TNodesFactory.CreateGlbspInputBuilder(LRef, False).BuildForMap(0)) > 12);
end;

procedure TTestNodesFactory.TestDovrebbeLeggereUnGwa;
begin
  Assert.AreEqual(2, TNodesFactory.ReadGwa(TNodesTestData.ReadFile('glbsp_map01.gwa')).Version);
end;

procedure TTestNodesFactory.TestDovrebbeRifiutareUnaSorgenteMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TNodesFactory.CreateGlDetector(nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TNodesFactory.CreateGlMapFinder(nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TNodesFactory.CreateGlbspInputBuilder(nil, False);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNodesFactory);

end.
