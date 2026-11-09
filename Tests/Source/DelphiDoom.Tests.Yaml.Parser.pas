{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the yaml library - the parser, the encodings and the   }
{  files                                                                       }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Yaml.Parser;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf;

type
  /// <summary>A file source with files in memory</summary>
  TFakeYamlFiles = class(TInterfacedObject, IYamlFileSource)
  strict private
    FName: string;
    FBytes: TBytes;
  public
    constructor Create(const AName: string; const ABytes: TBytes);
    function TryReadAllBytes(const AFileName: string; out ABytes: TBytes): Boolean;
  end;

  [TestFixture]
  [Category('yaml')]
  TTestYamlParser = class(TObject)
  strict private
    FParser: IYamlParser;
    function Bytes(const AValues: array of Byte): TBytes;
    function Utf16(const AText: string; ABigEndian, AWithBom: Boolean): TBytes;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeLeggereUnaMappaConSequenzeAnnidate;
    [Test]
    procedure DovrebbeDareUnNodoNullPerUnTestoVuoto;
    [Test]
    procedure DovrebbeLeggerePiuDocumenti;
    [Test]
    procedure DovrebbeSaltareLaBomUtf8;
    [Test]
    procedure DovrebbeLeggereUtf16ConEsenzaBom;
    [Test]
    procedure DovrebbeLeggereUtf32;
    [Test]
    procedure DovrebbeRiconoscereGliATestaACapoDiWindows;
    [Test]
    procedure DovrebbeSegnalareGliErroriConLaPosizione;
    [Test]
    procedure DovrebbeTradurreLeSequenzeDiEscapeInUtf8;
    [Test]
    procedure DovrebbeLasciareInvariatiIByteNonUtf8;
    [Test]
    procedure DovrebbeUsareITagEIlTagDirective;
    [Test]
    procedure DovrebbeRifiutareUnAliasSenzaAncora;
    [Test]
    procedure DovrebbeFermareUnDocumentoAnnidatoTroppoInProfondita;
    [Test]
    procedure DovrebbeSegnalareLaSequenzaInfinitaDiDocumentiVuoti;
    [Test]
    procedure DovrebbeLeggereUnFileDaUnaSorgente;
    [Test]
    procedure DovrebbeSegnalareUnFileMancante;
    [Test]
    procedure DovrebbeLeggereUnFileDalDisco;
  end;

implementation

uses
  System.IOUtils,
  DelphiDoom.Tests.Yaml.Dumper,
  DelphiDoom.Yaml.Factory;

{ TFakeYamlFiles }

constructor TFakeYamlFiles.Create(const AName: string; const ABytes: TBytes);
begin
  inherited Create;
  FName := AName;
  FBytes := ABytes;
end;

function TFakeYamlFiles.TryReadAllBytes(const AFileName: string; out ABytes: TBytes): Boolean;
begin
  Result := SameText(AFileName, FName);
  if Result then
    ABytes := FBytes
  else
    ABytes := nil;
end;

{ TTestYamlParser }

procedure TTestYamlParser.Setup;
begin
  FParser := TYamlFactory.CreateParser;
end;

function TTestYamlParser.Bytes(const AValues: array of Byte): TBytes;
var
  I: Integer;
begin
  SetLength(Result, Length(AValues));
  for I := 0 to High(AValues) do
    Result[I] := AValues[I];
end;

function TTestYamlParser.Utf16(const AText: string; ABigEndian, AWithBom: Boolean): TBytes;
var
  I, N: Integer;
  C: Word;
begin
  N := 0;
  SetLength(Result, (Length(AText) + 1) * 2);
  if AWithBom then
  begin
    if ABigEndian then
    begin
      Result[0] := $FE;
      Result[1] := $FF;
    end
    else
    begin
      Result[0] := $FF;
      Result[1] := $FE;
    end;
    N := 2;
  end;
  for I := 1 to Length(AText) do
  begin
    C := Word(AText[I]);
    if ABigEndian then
    begin
      Result[N] := C shr 8;
      Result[N + 1] := C and $FF;
    end
    else
    begin
      Result[N] := C and $FF;
      Result[N + 1] := C shr 8;
    end;
    Inc(N, 2);
  end;
  SetLength(Result, N);
end;

procedure TTestYamlParser.DovrebbeLeggereUnaMappaConSequenzeAnnidate;
var
  LNode: IYamlNode;
begin
  LNode := FParser.Load('weapons:'#10'  - name: A'#10'    cost: 5'#10'  - name: B'#10'items: [x, y]'#10);
  Assert.AreEqual(2, LNode.Size);
  Assert.AreEqual(2, LNode.Find('weapons').Size);
  Assert.AreEqual(5, LNode.Find('weapons').Items[0].Find('cost').AsInteger);
  Assert.AreEqual('B', LNode.Find('weapons').Items[1].Find('name').ScalarString);
  Assert.AreEqual(esFlow, LNode.Find('items').Style);
  Assert.AreEqual(esBlock, LNode.Find('weapons').Style);
end;

procedure TTestYamlParser.DovrebbeDareUnNodoNullPerUnTestoVuoto;
var
  LNode: IYamlNode;
begin
  LNode := FParser.Load('');
  Assert.IsTrue(LNode.IsNull);
  Assert.AreEqual(0, Integer(Length(FParser.LoadAll(''))));
end;

procedure TTestYamlParser.DovrebbeLeggerePiuDocumenti;
var
  LDocs: TArray<IYamlNode>;
begin
  LDocs := FParser.LoadAll('---'#10'a: 1'#10'---'#10'- 2'#10'...'#10'--- text'#10);
  Assert.AreEqual(3, Integer(Length(LDocs)));
  Assert.IsTrue(LDocs[0].IsMap);
  Assert.IsTrue(LDocs[1].IsSequence);
  Assert.AreEqual('text', LDocs[2].ScalarString);
end;

procedure TTestYamlParser.DovrebbeSaltareLaBomUtf8;
var
  LNode: IYamlNode;
begin
  LNode := FParser.Load(Bytes([$EF, $BB, $BF, Ord('a'), Ord(':'), Ord(' '), Ord('1')]));
  Assert.AreEqual(1, LNode.Find('a').AsInteger);
end;

procedure TTestYamlParser.DovrebbeLeggereUtf16ConEsenzaBom;
var
  LNode: IYamlNode;
  LText: string;
begin
  LText := 'k: caf' + #$00E9 + ' ' + #$65E5 + #$D83D + #$DE00;
  LNode := FParser.Load(Utf16(LText, False, True));
  Assert.AreEqual(LText.Substring(3), YamlTextToString(LNode.Find('k').Scalar));
  LNode := FParser.Load(Utf16(LText, True, True));
  Assert.AreEqual(LText.Substring(3), YamlTextToString(LNode.Find('k').Scalar));
  // without a BOM it is found by the zero bytes of the ASCII letters
  LNode := FParser.Load(Utf16('a: 1', False, False));
  Assert.AreEqual(1, LNode.Find('a').AsInteger);
  LNode := FParser.Load(Utf16('a: 1', True, False));
  Assert.AreEqual(1, LNode.Find('a').AsInteger);
end;

procedure TTestYamlParser.DovrebbeLeggereUtf32;
var
  LNode: IYamlNode;
begin
  // BOM + "a: ??" in UTF-32 little endian
  LNode := FParser.Load(Bytes([$FF, $FE, 0, 0, Ord('a'), 0, 0, 0, Ord(':'), 0, 0, 0, Ord(' '), 0, 0, 0, $E9, 0, 0, 0]));
  Assert.AreEqual(YamlTextToString(YamlBytes([$C3, $A9])), YamlTextToString(LNode.Find('a').Scalar));
  // big endian
  LNode := FParser.Load(Bytes([0, 0, $FE, $FF, 0, 0, 0, Ord('a'), 0, 0, 0, Ord(':'), 0, 0, 0, Ord(' '), 0, 0, 0, Ord('1')]));
  Assert.AreEqual(1, LNode.Find('a').AsInteger);
end;

procedure TTestYamlParser.DovrebbeRiconoscereGliATestaACapoDiWindows;
var
  LNode: IYamlNode;
begin
  LNode := FParser.Load('a: 1'#13#10'b: |'#13#10'  x'#13#10'  y'#13#10);
  Assert.AreEqual(1, LNode.Find('a').AsInteger);
  Assert.AreEqual('x'#10'y'#10, YamlTextToString(LNode.Find('b').Scalar).Replace(#13, ''));
end;

procedure TTestYamlParser.DovrebbeSegnalareGliErroriConLaPosizione;
var
  LCaught: Boolean;
begin
  LCaught := False;
  try
    FParser.Load('a: [1, 2'#10);
  except
    on E: EYamlParserException do
    begin
      LCaught := True;
      Assert.AreEqual('end of sequence flow not found', YamlTextToString(E.Msg));
      Assert.AreEqual(1, E.Mark.Line);
      Assert.AreEqual(0, E.Mark.Column);
      Assert.AreEqual('yaml-cpp: error at line 2, column 1: end of sequence flow not found', E.Message);
    end;
  end;
  Assert.IsTrue(LCaught);
end;

procedure TTestYamlParser.DovrebbeTradurreLeSequenzeDiEscapeInUtf8;
var
  LNode: IYamlNode;
begin
  LNode := FParser.Load('a: "\x41' + '\' + 'u00e9' + '\' + 'u65e5' + '\' + 'U0001F600\n\t\"\\"');
  Assert.AreEqual('A\xc3\xa9\xe6\x97\xa5\xf0\x9f\x98\x80\n\t"\\', string(TYamlParityDumper.Esc(LNode.Find('a').Scalar)));
end;

procedure TTestYamlParser.DovrebbeLasciareInvariatiIByteNonUtf8;
var
  LNode: IYamlNode;
begin
  LNode := FParser.Load(Bytes([Ord('a'), Ord(':'), Ord(' '), $FF, $FE, Ord('x')]));
  Assert.AreEqual(3, Integer(Length(LNode.Find('a').Scalar)));
  Assert.AreEqual(255, Integer(Byte(LNode.Find('a').Scalar[1])));
end;

procedure TTestYamlParser.DovrebbeUsareITagEIlTagDirective;
var
  LNode: IYamlNode;
begin
  LNode := FParser.Load('%TAG !e! tag:example.com,2000:'#10'---'#10'a: !e!foo bar'#10'b: !!str 1'#10'c: !local x'#10);
  Assert.AreEqual('tag:example.com,2000:foo', YamlTextToString(LNode.Find('a').Tag));
  Assert.AreEqual('tag:yaml.org,2002:str', YamlTextToString(LNode.Find('b').Tag));
  Assert.AreEqual('!local', YamlTextToString(LNode.Find('c').Tag));
  Assert.AreEqual('?', YamlTextToString(FParser.Load('a: 1').Find('a').Tag));
end;

procedure TTestYamlParser.DovrebbeRifiutareUnAliasSenzaAncora;
begin
  Assert.WillRaise(procedure begin FParser.Load('a: *nothing') end, EYamlParserException);
end;

procedure TTestYamlParser.DovrebbeFermareUnDocumentoAnnidatoTroppoInProfondita;
var
  LText: string;
begin
  LText := StringOfChar('[', 600) + StringOfChar(']', 600);
  Assert.WillRaise(procedure begin FParser.Load(YamlStringToText(LText)) end, EYamlDeepRecursion);
end;

procedure TTestYamlParser.DovrebbeSegnalareLaSequenzaInfinitaDiDocumentiVuoti;
begin
  Assert.WillRaise(procedure begin FParser.LoadAll(',- x'#10) end, EYamlEndlessDocumentsException);
  // Load only reads the first document
  Assert.IsNotNull(FParser.Load(',- x'#10));
end;

procedure TTestYamlParser.DovrebbeLeggereUnFileDaUnaSorgente;
var
  LParser: IYamlParser;
begin
  LParser := TYamlFactory.CreateParser(TFakeYamlFiles.Create('rules.yml', Bytes([Ord('a'), Ord(':'), Ord(' '), Ord('7')])));
  Assert.AreEqual(7, LParser.LoadFile('rules.yml').Find('a').AsInteger);
  Assert.AreEqual(1, Integer(Length(LParser.LoadAllFromFile('RULES.yml'))));
end;

procedure TTestYamlParser.DovrebbeSegnalareUnFileMancante;
var
  LMessage: string;
begin
  LMessage := '';
  try
    TYamlFactory.CreateParser(TFakeYamlFiles.Create('x.yml', nil)).LoadFile('missing.yml');
  except
    on E: EYamlBadFile do
      LMessage := E.Message;
  end;
  Assert.AreEqual('bad file: missing.yml', LMessage);
  Assert.WillRaise(procedure begin FParser.LoadFile('x.yml') end, EYamlBadFile, 'senza sorgente nessun file si legge');
end;

procedure TTestYamlParser.DovrebbeLeggereUnFileDalDisco;
var
  LFile: string;
begin
  LFile := TPath.Combine(TPath.GetTempPath, 'DelphiDoomYamlTest.yml');
  TFile.WriteAllBytes(LFile, Bytes([Ord('k'), Ord(':'), Ord(' '), Ord('v'), 10]));
  try
    Assert.AreEqual('v', TYamlFactory.CreateDiskParser.LoadFile(LFile).Find('k').ScalarString);
  finally
    TFile.Delete(LFile);
  end;
end;

end.
