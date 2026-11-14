{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the yaml library - parity with yaml-cpp 0.7.0          }
{                                                                              }
{  Tests\Data\Yaml\corpus.txt is read by the real yaml-cpp (Tools\Verifica\    }
{  176\yaml\harness.cpp, compiled with MinGW g++) and Tests\Data\Yaml\         }
{  parse.golden.txt is its answer: for each case the dump of the documents,    }
{  the conversions of each scalar, or the error with its position, and the     }
{  text that Emitter << node gives. The library must write the same bytes      }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Yaml.Parity;

interface

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  DUnitX.TestFramework,
  DelphiDoom.Yaml.Types;

type
  [TestFixture]
  [Category('yaml')]
  [Category('yaml-golden')]
  TTestYamlParity = class(TObject)
  strict private
    function DataFile(const AName: string): string;
    function ReadFileText(const AName: string): TYamlText;
    function Cut(const AGolden: TYamlText; out ACases: TArray<TYamlText>): Boolean;
    procedure CompareCorpus(const ACorpusName, AGoldenName: string; const ARunner: TFunc<TYamlText, TYamlText>);
  public
    [Test]
    procedure DovrebbeDareGliStessiAlberiEErroriDiYamlCppSulCorpus;
    [Test]
    procedure DovrebbeScrivereLeStringheComeYamlCpp;
    [Test]
    procedure DovrebbeScrivereNumeriBooleaniNulliEBinariComeYamlCpp;
    [Test]
    procedure DovrebbeApplicareLeImpostazioniComeYamlCpp;
    [Test]
    procedure DovrebbeSeguireLeSequenzeCasualiDiOperazioniComeYamlCpp;
    [Test]
    procedure DovrebbeAvereUnGoldenConTuttiIPresentiCasi;
  end;

implementation

uses
  DelphiDoom.Tests.Yaml.Dumper,
  DelphiDoom.Tests.Yaml.EmitScript;

// Pos on byte strings (the golden holds any byte, a Delphi Pos would convert it)
function FindBytes(const ASub, AText: TYamlText; AFrom: Integer): Integer;
var
  I, J, LLast: Integer;
  LMatch: Boolean;
begin
  LLast := Length(AText) - Length(ASub) + 1;
  for I := AFrom to LLast do
  begin
    LMatch := True;
    for J := 1 to Length(ASub) do
      if AText[I + J - 1] <> ASub[J] then
      begin
        LMatch := False;
        Break;
      end;
    if LMatch then
      Exit(I);
  end;
  Result := 0;
end;

function TTestYamlParity.DataFile(const AName: string): string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Yaml\' + AName);
end;

function TTestYamlParity.ReadFileText(const AName: string): TYamlText;
var
  LBytes: TBytes;
begin
  LBytes := TFile.ReadAllBytes(DataFile(AName));
  SetLength(Result, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], Result[1], Length(LBytes));
end;

// The golden is "#n" lines followed by the dump of the case n: cut it at the markers (a marker is at a line start and
// the numbers follow each other, so a dump line that looks like one cannot be taken for it)
function TTestYamlParity.Cut(const AGolden: TYamlText; out ACases: TArray<TYamlText>): Boolean;
var
  LNext: Integer;
  LMarker, LNextMarker: TYamlText;
  LStart, LEnd: Integer;
begin
  ACases := nil;
  LNext := 0;
  LMarker := '#0'#10;
  if Copy(AGolden, 1, Length(LMarker)) <> LMarker then
    Exit(False);
  LStart := Length(LMarker) + 1;
  while True do
  begin
    Inc(LNext);
    LNextMarker := #10'#' + TYamlText(IntToStr(LNext)) + #10;
    LEnd := FindBytes(LNextMarker, AGolden, LStart);
    SetLength(ACases, Length(ACases) + 1);
    if LEnd = 0 then
    begin
      ACases[High(ACases)] := Copy(AGolden, LStart, MaxInt);
      Break;
    end;
    ACases[High(ACases)] := Copy(AGolden, LStart, LEnd - LStart + 1);
    LStart := LEnd + Length(LNextMarker);
  end;
  Result := True;
end;

procedure TTestYamlParity.DovrebbeAvereUnGoldenConTuttiIPresentiCasi;
var
  LCorpus: TArray<TYamlText>;
  LGolden: TArray<TYamlText>;
begin
  LCorpus := TYamlParityDumper.SplitCases(TFile.ReadAllBytes(DataFile('corpus.txt')));
  Assert.IsTrue(Cut(ReadFileText('parse.golden.txt'), LGolden), 'il golden non comincia con #0');
  Assert.AreEqual(Integer(Length(LCorpus)), Integer(Length(LGolden)), 'casi del corpus e casi del golden');
end;

procedure TTestYamlParity.CompareCorpus(const ACorpusName, AGoldenName: string; const ARunner: TFunc<TYamlText, TYamlText>);
var
  LCorpus: TArray<TYamlText>;
  LGolden: TArray<TYamlText>;
  I, LDifferent: Integer;
  LActual: TYamlText;
  LReport: string;
begin
  LCorpus := TYamlParityDumper.SplitCases(TFile.ReadAllBytes(DataFile(ACorpusName)));
  Assert.IsTrue(Cut(ReadFileText(AGoldenName), LGolden), 'il golden non comincia con #0');
  Assert.AreEqual(Integer(Length(LCorpus)), Integer(Length(LGolden)), 'casi del corpus e casi del golden');
  LDifferent := 0;
  LReport := '';
  for I := 0 to High(LCorpus) do
  begin
    try
      LActual := ARunner(LCorpus[I]);
    except
      on E: Exception do
        LActual := TYamlText('EXCEPTION ' + AnsiString(E.ClassName + ': ' + E.Message));
    end;
    if LActual <> LGolden[I] then
    begin
      Inc(LDifferent);
      if LDifferent <= 3 then
        LReport := LReport + Format(#13#10'--- caso %d: testo [%s]'#13#10'atteso:'#13#10'%s'#13#10'ottenuto:'#13#10'%s',
          [I, Copy(YamlTextToString(TYamlParityDumper.Esc(LCorpus[I])), 1, 600),
          Copy(YamlTextToString(TYamlParityDumper.Esc(LGolden[I])), 1, 1500),
          Copy(YamlTextToString(TYamlParityDumper.Esc(LActual)), 1, 1500)]);
    end;
  end;
  Assert.AreEqual(0, LDifferent, Format('%d casi su %d diversi da yaml-cpp%s', [LDifferent, Length(LCorpus), LReport]));
end;

procedure TTestYamlParity.DovrebbeDareGliStessiAlberiEErroriDiYamlCppSulCorpus;
begin
  CompareCorpus('corpus.txt', 'parse.golden.txt',
    function(AText: TYamlText): TYamlText
    begin
      Result := TYamlParityDumper.RunCase(AText);
    end);
end;

procedure TTestYamlParity.DovrebbeScrivereLeStringheComeYamlCpp;
begin
  CompareCorpus('emit_strings.corpus.txt', 'emit_strings.golden.txt',
    function(AText: TYamlText): TYamlText
    begin
      Result := TYamlEmitScript.Run(AText);
    end);
end;

procedure TTestYamlParity.DovrebbeScrivereNumeriBooleaniNulliEBinariComeYamlCpp;
begin
  CompareCorpus('emit_values.corpus.txt', 'emit_values.golden.txt',
    function(AText: TYamlText): TYamlText
    begin
      Result := TYamlEmitScript.Run(AText);
    end);
end;

procedure TTestYamlParity.DovrebbeApplicareLeImpostazioniComeYamlCpp;
begin
  CompareCorpus('emit_settings.corpus.txt', 'emit_settings.golden.txt',
    function(AText: TYamlText): TYamlText
    begin
      Result := TYamlEmitScript.Run(AText);
    end);
end;

procedure TTestYamlParity.DovrebbeSeguireLeSequenzeCasualiDiOperazioniComeYamlCpp;
begin
  CompareCorpus('emit_random.corpus.txt', 'emit_random.golden.txt',
    function(AText: TYamlText): TYamlText
    begin
      Result := TYamlEmitScript.Run(AText);
    end);
end;

end.
