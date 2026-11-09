{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the parser of MODELDEF         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.DefinitionParser;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Definition.Intf,
  DelphiDoom.Tests.Models.DefinitionFakes;

type
  [TestFixture]
  [Category('models')]
  TTestModelsDefinitionParser = class(TObject)
  strict private
    FLog: TModelsFakeLog;
    FLogIntf: ILog;
    FSink: TModelsFakeDefinitionSink;
    FSinkIntf: IModelDefinitionSink;
    FParser: IModelDefinitionParser;
    function Bits(const AValue: Single): string;
    function Trace(const AOld: Boolean; const AText: string): string;
    function RandomText(const ARandom: Integer): string;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareIlModelloEDefaultDiOffsetEScala;
    [Test]
    procedure DovrebbeLeggereOffsetScalaEFileUniti;
    [Test]
    procedure DovrebbeScrivereYOffsetNelloXOffset;
    [Test]
    procedure DovrebbeLegareUnoStatoAModelloTexturePEFotogrammi;
    [Test]
    procedure DovrebbeUsareIlPrimoFotogrammaComeUltimoSeManca;
    [Test]
    procedure DovrebbeAvvisareDiUnoStatoSconosciutoEUsareSNull;
    [Test]
    procedure DovrebbeAvvisareDiUnaParolaSconosciuta;
    [Test]
    procedure DovrebbeAvvisareESaltareSeManca;
    [Test]
    procedure DovrebbeDareIlModelloInSospesoAllaFineDelTesto;
    [Test]
    procedure DovrebbeDareEccezioneSeManca;
    [Test]
    procedure DovrebbeDareLeStesseChiamateEGliStessiAvvisiDelVecchioParser;
  end;

implementation

uses
  DelphiDoom.Models.Factory,
  DelphiDoom.Tests.Models.OldModelDefinition;

function TTestModelsDefinitionParser.Bits(const AValue: Single): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := IntToHex(PCardinal(@LValue)^, 8);
end;

procedure TTestModelsDefinitionParser.Setup;
begin
  FLog := TModelsFakeLog.Create;
  FLogIntf := FLog;
  FSink := TModelsFakeDefinitionSink.Create;
  FSinkIntf := FSink;
  FParser := TModelsFactory.CreateDefinitionParser(TModelsFakeDefinitionLookup.Create, FLog);
end;

procedure TTestModelsDefinitionParser.DovrebbeDareIlModelloEDefaultDiOffsetEScala;
begin
  FParser.Parse('modeldef barrel.md2', FSink);
  Assert.AreEqual(1, FSink.Lines.Count);
  Assert.AreEqual(Format('M BARREL.MD2||%s %s %s|%s %s %s| -> -1',
    [Bits(0), Bits(0), Bits(0), Bits(1), Bits(1), Bits(1)]), FSink.Lines[0]);
end;

procedure TTestModelsDefinitionParser.DovrebbeLeggereOffsetScalaEFileUniti;
begin
  FParser.Parse('MODELDEFINITION a.md2 zoffset 3 xoffset 1 scale 2 xscale 4 proc Fn framemerge b.md2 framemerge c.md2',
    FSink);
  Assert.AreEqual(1, FSink.Lines.Count);
  Assert.AreEqual(Format('M A.MD2|Fn|%s %s %s|%s %s %s|B.MD2;C.MD2; -> -1',
    [Bits(1), Bits(0), Bits(3), Bits(4), Bits(2), Bits(2)]), FSink.Lines[0]);
end;

procedure TTestModelsDefinitionParser.DovrebbeScrivereYOffsetNelloXOffset;
begin
  FParser.Parse('modeldef a.md2 yoffset 7', FSink);
  Assert.AreEqual(Format('M A.MD2||%s %s %s|%s %s %s| -> -1',
    [Bits(7), Bits(0), Bits(0), Bits(1), Bits(1), Bits(1)]), FSink.Lines[0]);
end;

procedure TTestModelsDefinitionParser.DovrebbeLegareUnoStatoAModelloTexturePEFotogrammi;
begin
  FParser.Parse('state s_play model a.md2 texture t1 frame 3 endframe 5 transparency 0.5', FSink);
  Assert.AreEqual(3, FSink.Lines.Count);
  Assert.AreEqual('T T1 -> 0', FSink.Lines[1]);
  Assert.AreEqual(Format('S 0|0|3|5|-1|1|%s', [Bits(0.5)]), FSink.Lines[2]);
end;

procedure TTestModelsDefinitionParser.DovrebbeUsareIlPrimoFotogrammaComeUltimoSeManca;
begin
  FParser.Parse('state s_play_run1 frame 4', FSink);
  Assert.AreEqual(Format('S -1|-1|4|4|-1|2|%s', [Bits(1)]), FSink.Lines[0]);
end;

procedure TTestModelsDefinitionParser.DovrebbeAvvisareDiUnoStatoSconosciutoEUsareSNull;
begin
  FParser.Parse('state s_nowhere', FSink);
  Assert.AreEqual(1, FLog.Warnings.Count);
  Assert.AreEqual('SC_ParseModelDefinition(): Unknown state "s_nowhere" at line 1'#13#10, FLog.Warnings[0]);
  Assert.AreEqual(Format('S -1|-1|-1|-1|-1|0|%s', [Bits(1)]), FSink.Lines[0]);
end;

procedure TTestModelsDefinitionParser.DovrebbeAvvisareDiUnaParolaSconosciuta;
begin
  FParser.Parse('bogus', FSink);
  Assert.AreEqual(1, FLog.Warnings.Count);
  Assert.AreEqual('SC_ParseModelDefinition(): Unknown token "BOGUS" at line 1'#13#10, FLog.Warnings[0]);
  Assert.AreEqual(0, FSink.Lines.Count);
end;

procedure TTestModelsDefinitionParser.DovrebbeAvvisareESaltareSeManca;
begin
  FParser.Parse('modeldef', FSink);
  Assert.AreEqual(1, FLog.Warnings.Count);
  Assert.AreEqual('SC_ParseModelDefinition(): Token expected at line 1'#13#10, FLog.Warnings[0]);
  // the old parser gave the model with an empty name
  Assert.AreEqual(1, FSink.Lines.Count);
  Assert.IsTrue(FSink.Lines[0].StartsWith('M |'));
end;

procedure TTestModelsDefinitionParser.DovrebbeDareIlModelloInSospesoAllaFineDelTesto;
begin
  FParser.Parse('modeldef a.md2 scale 2', FSink);
  Assert.AreEqual(1, FSink.Lines.Count);
  FSink.Lines.Clear;
  FParser.Parse('modeldef a.md2 state s_play model b.md2', FSink);
  Assert.AreEqual(3, FSink.Lines.Count);
end;

procedure TTestModelsDefinitionParser.DovrebbeDareEccezioneSeManca;
begin
  Assert.WillRaise(
    procedure
    begin
      FParser.Parse('state s_play', nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TModelsFactory.CreateDefinitionParser(nil, FLog);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TModelsFactory.CreateDefinitionParser(TModelsFakeDefinitionLookup.Create, nil);
    end, EArgumentNilException);
end;

function TTestModelsDefinitionParser.Trace(const AOld: Boolean; const AText: string): string;
var
  LLog: TModelsFakeLog;
  LLogIntf: ILog;
  LSink: TModelsFakeDefinitionSink;
  LSinkIntf: IModelDefinitionSink;
  LLookup: IModelDefinitionLookup;
begin
  LLog := TModelsFakeLog.Create;
  LLogIntf := LLog;
  LSink := TModelsFakeDefinitionSink.Create;
  LSinkIntf := LSink;
  LLookup := TModelsFakeDefinitionLookup.Create;
  if AOld then
    OldParseModelDefinition(AText, LSinkIntf, LLookup, LLogIntf)
  else
    TModelsFactory.CreateDefinitionParser(LLookup, LLogIntf).Parse(AText, LSinkIntf);
  Result := LSink.Lines.Text + '--' + LLog.Warnings.Text;
end;

function TTestModelsDefinitionParser.RandomText(const ARandom: Integer): string;
const
  WORDS: array[0..43] of string = (
    'modeldef', 'MODELDEFINITION', 'state', 'offset', 'zoffset', 'offsetz', 'scale', 'texture',
    'frame', 'frame1', 'startframe', 'frame2', 'endframe', 'nextframe', 'model', 'framemerge',
    'transparency', 'xoffset', 'offsetx', 'yoffset', 'offsety', 'xscale', 'scalex', 'yscale',
    'zscale', 'proc', 's_play', 'S_NULL', 's_play_run1', 's_unknown', 'a.md2', 'B.DDMODEL', 'c.dmx',
    '2', '-3', '0.25', '1.5', 'x', 'bogus', '"quoted name"', '// comment' + #10, '{', '}', ',');
var
  LCount, LIndex: Integer;
begin
  Result := '';
  LCount := 1 + Random(40);
  for LIndex := 1 to LCount do
  begin
    Result := Result + WORDS[Random(Length(WORDS))];
    if Random(6) = 0 then
      Result := Result + #13#10
    else
      Result := Result + ' ';
  end;
end;

procedure TTestModelsDefinitionParser.DovrebbeDareLeStesseChiamateEGliStessiAvvisiDelVecchioParser;
var
  LIndex: Integer;
  LText: string;
begin
  RandSeed := 177;
  for LIndex := 1 to 1500 do
  begin
    LText := RandomText(LIndex);
    Assert.AreEqual(Trace(True, LText), Trace(False, LText), 'testo ' + IntToStr(LIndex) + ': ' + LText);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestModelsDefinitionParser);

end.
