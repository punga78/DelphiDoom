{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the parser of VOXELDEF
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.DefinitionParser;
interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.Voxel.Intf,
  DelphiDoom.Tests.Voxel.Fakes;

type
  [TestFixture]
  [Category('voxel')]
  TTestVoxelDefinitionParser = class(TObject)
  strict private
    FLog: TVoxelFakeLog;
    FLogIntf: ILog;
    FSink: TVoxelFakeSink;
    FSinkIntf: IVoxelDefinitionSink;
    FParser: IVoxelDefinitionParser;
    function Bits(const AValue: Single): Integer;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareIlVoxelELeSueOpzioni;
    [Test]
    procedure DovrebbeNonDareUnaScalaMinoreDiUnCentesimo;
    [Test]
    procedure DovrebbeLegareIlVoxelAgliStatiDelloSpriteCheSostituisce;
    [Test]
    procedure DovrebbeLegareUnoStatoAUnVoxelEAUnFotogramma;
    [Test]
    procedure DovrebbeAvvisareDiUnoStatoSconosciutoEUsareSNull;
    [Test]
    procedure DovrebbeAvvisareDiUnaParolaSconosciuta;
    [Test]
    procedure DovrebbeAvvisareSeMancaUnaParola;
    [Test]
    procedure DovrebbeLeggereLaFormaCortaConLoSprite;
    [Test]
    procedure DovrebbeIgnorareIlSegnoUguale;
    [Test]
    procedure DovrebbeDareEccezioneSeManca;
  end;

implementation

uses
  DelphiDoom.Voxel.Types, DelphiDoom.Voxel.Factory;

function TTestVoxelDefinitionParser.Bits(const AValue: Single): Integer;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := PInteger(@LValue)^;
end;

procedure TTestVoxelDefinitionParser.Setup;
begin
  FLog := TVoxelFakeLog.Create;
  FLogIntf := FLog;
  FSink := TVoxelFakeSink.Create;
  FSinkIntf := FSink;
  FParser := TVoxelFactory.CreateDefinitionParser(TVoxelFakeLookup.Create, FLog);
end;

procedure TTestVoxelDefinitionParser.DovrebbeDareIlVoxelELeSueOpzioni;
begin
  FParser.Parse('voxeldef barrel offset 1.5 scale 2 anglEoffset 45 spin 3 clipped', FSink);
  Assert.AreEqual(1, FSink.Lines.Count);
  Assert.AreEqual(Format('V BARREL|%d|%d|45|3|3|1 -> 0', [Bits(1.5), Bits(2)]), FSink.Lines[0]);
end;

procedure TTestVoxelDefinitionParser.DovrebbeNonDareUnaScalaMinoreDiUnCentesimo;
begin
  FParser.Parse('voxeldef a scale 0.001', FSink);
  Assert.AreEqual(Format('V A|%d|%d|0|0|0|0 -> 0', [Bits(0), Bits(0.01)]), FSink.Lines[0]);
end;

procedure TTestVoxelDefinitionParser.DovrebbeLegareIlVoxelAgliStatiDelloSpriteCheSostituisce;
begin
  FParser.Parse('voxeldef b replace sprite TROO', FSink);
  Assert.AreEqual(5, FSink.Lines.Count);
  Assert.AreEqual('C TROO|B', FSink.Lines[0]);
  Assert.AreEqual('S 0|0|10', FSink.Lines[2]);
  Assert.AreEqual('S 0|0|12', FSink.Lines[4]);
  Assert.AreEqual(0, FLog.Warnings.Count);
end;

procedure TTestVoxelDefinitionParser.DovrebbeLegareUnoStatoAUnVoxelEAUnFotogramma;
begin
  FParser.Parse('STATE S_TWO VOXEL x FRAME 3', FSink);
  Assert.AreEqual(2, FSink.Lines.Count);
  Assert.AreEqual('S 0|3|2', FSink.Lines[1]);
end;

procedure TTestVoxelDefinitionParser.DovrebbeAvvisareDiUnoStatoSconosciutoEUsareSNull;
begin
  FParser.Parse('STATE S_NONE', FSink);
  Assert.AreEqual('S -1|0|0', FSink.Lines[0]);
  Assert.AreEqual(1, FLog.Warnings.Count);
  Assert.AreEqual('SC_ParseVoxelDefinition(): Unknown state "S_NONE" at line 1'#13#10, FLog.Warnings[0]);
end;

procedure TTestVoxelDefinitionParser.DovrebbeAvvisareDiUnaParolaSconosciuta;
begin
  FParser.Parse('XXXX', FSink);
  Assert.AreEqual(0, FSink.Lines.Count);
  Assert.AreEqual('SC_ParseVoxelDefinition(): Unknown token "XXXX" at line 1'#13#10, FLog.Warnings[0]);
end;

procedure TTestVoxelDefinitionParser.DovrebbeAvvisareSeMancaUnaParola;
begin
  FParser.Parse('VOXELDEF', FSink);
  Assert.AreEqual('SC_ParseVoxelDefinition(): Token expected at line 1'#13#10, FLog.Warnings[0]);
  FLog.Warnings.Clear;
  FParser.Parse('VOXELDEF a REPLACE TROO', FSink);
  Assert.AreEqual('SC_ParseVoxelDefinition(): "SPRITE" expected at line 1'#13#10, FLog.Warnings[0]);
end;

procedure TTestVoxelDefinitionParser.DovrebbeLeggereLaFormaCortaConLoSprite;
begin
  FParser.Parse('POSS cacodemon.kvx scale 0.5', FSink);
  Assert.AreEqual(2, FSink.Lines.Count);
  Assert.AreEqual(Format('V cacodemon.kvx|%d|%d|0|0|0|0 -> 0', [Bits(0), Bits(0.5)]), FSink.Lines[0]);
  Assert.AreEqual('S 0|0|20', FSink.Lines[1]);
end;

procedure TTestVoxelDefinitionParser.DovrebbeIgnorareIlSegnoUguale;
begin
  FParser.Parse('VOXELDEF = a = offset = 4', FSink);
  Assert.AreEqual(Format('V A|%d|%d|0|0|0|0 -> 0', [Bits(4), Bits(1)]), FSink.Lines[0]);
end;

procedure TTestVoxelDefinitionParser.DovrebbeDareEccezioneSeManca;
begin
  Assert.WillRaise(
    procedure
    begin
      FParser.Parse('a', nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TVoxelFactory.CreateDefinitionParser(nil, FLog);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelDefinitionParser);

end.