{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the command line library - the response files         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.CommandLine.ResponseFile;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Intf,
  DelphiDoom.CommandLine.Intf;

type
  TFakeResponseFileSource = class(TInterfacedObject, IResponseFileSource)
  strict private
    FFiles: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AFileName, AText: string);
    function TryRead(const AFileName: string; out AText: string): Boolean;
  end;

  TFakeResponseLog = class(TInterfacedObject, ILog)
  strict private
    FInfo: TStringBuilder;
  public
    constructor Create;
    destructor Destroy; override;
    function Text: string;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
  end;

  [TestFixture]
  [Category('commandline')]
  TTestCommandLineResponseFile = class(TObject)
  strict private
    FSource: TFakeResponseFileSource;
    FSourceIntf: IResponseFileSource;
    FLog: TFakeResponseLog;
    FLogIntf: ILog;
    FExpander: IResponseFileExpander;
    function Expand(const AArguments: array of string; AMaxArguments: Integer = 1024): string;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareErroreConSorgenteNil;
    [Test]
    procedure DovrebbeDareErroreConLogNil;
    [Test]
    procedure DovrebbeLasciareInvariatiGliArgomentiSenzaFileDiRisposta;
    [Test]
    procedure DovrebbeSostituireIlFileDiRispostaConIlSuoContenuto;
    [Test]
    procedure DovrebbeSeparareGliArgomentiConSpaziEACapo;
    [Test]
    procedure DovrebbeTenereIlPuntoDoveStavaIlFile;
    [Test]
    procedure DovrebbeSaltareUnFileMancanteEDirlo;
    [Test]
    procedure DovrebbeScrivereIMessaggiDelVecchioCodice;
    [Test]
    procedure DovrebbeScartareGliArgomentiVuoti;
    [Test]
    procedure DovrebbeTenereIlNomeDelProgrammaAnchePerUnaChiocciola;
    [Test]
    procedure DovrebbeFermarsiAlMassimoDegliArgomenti;
    [Test]
    procedure DovrebbeLeggereTuttiIFileDiRisposta;
    [Test]
    procedure DovrebbeUsareIlCarattereGiustoDelFile;
  end;

implementation

uses
  DelphiDoom.CommandLine.Factory;

{ TFakeResponseFileSource }

constructor TFakeResponseFileSource.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, string>.Create;
end;

destructor TFakeResponseFileSource.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TFakeResponseFileSource.Add(const AFileName, AText: string);
begin
  FFiles.AddOrSetValue(AFileName, AText);
end;

function TFakeResponseFileSource.TryRead(const AFileName: string; out AText: string): Boolean;
begin
  Result := FFiles.TryGetValue(AFileName, AText);
  if not Result then
    AText := '';
end;

{ TFakeResponseLog }

constructor TFakeResponseLog.Create;
begin
  inherited Create;
  FInfo := TStringBuilder.Create;
end;

destructor TFakeResponseLog.Destroy;
begin
  FInfo.Free;
  inherited Destroy;
end;

function TFakeResponseLog.Text: string;
begin
  Result := FInfo.ToString;
end;

procedure TFakeResponseLog.Info(const AText: string);
begin
  FInfo.Append(AText);
end;

procedure TFakeResponseLog.Warning(const AText: string);
begin
end;

procedure TFakeResponseLog.DevWarning(const AText: string);
begin
end;

procedure TFakeResponseLog.Error(const AText: string);
begin
end;

{ TTestCommandLineResponseFile }

procedure TTestCommandLineResponseFile.Setup;
begin
  FSource := TFakeResponseFileSource.Create;
  FSourceIntf := FSource;
  FLog := TFakeResponseLog.Create;
  FLogIntf := FLog;
  FExpander := TCommandLineFactory.CreateResponseFileExpander(FSourceIntf, FLogIntf);
end;

function TTestCommandLineResponseFile.Expand(const AArguments: array of string;
  AMaxArguments: Integer): string;
var
  LArguments: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LArguments, Length(AArguments));
  for LIndex := 0 to High(AArguments) do
    LArguments[LIndex] := AArguments[LIndex];
  Result := string.Join('|', FExpander.Expand(LArguments, AMaxArguments));
end;

procedure TTestCommandLineResponseFile.DovrebbeDareErroreConSorgenteNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TCommandLineFactory.CreateResponseFileExpander(nil, FLogIntf);
    end, EArgumentNilException);
end;

procedure TTestCommandLineResponseFile.DovrebbeDareErroreConLogNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TCommandLineFactory.CreateResponseFileExpander(FSourceIntf, nil);
    end, EArgumentNilException);
end;

procedure TTestCommandLineResponseFile.DovrebbeLasciareInvariatiGliArgomentiSenzaFileDiRisposta;
begin
  Assert.AreEqual('DOOM|-FILE|A.WAD|-SKILL|4', Expand(['DOOM', '-FILE', 'A.WAD', '-SKILL', '4']));
  Assert.AreEqual('', FLog.Text);
end;

procedure TTestCommandLineResponseFile.DovrebbeSostituireIlFileDiRispostaConIlSuoContenuto;
begin
  FSource.Add('R.TXT', '-WARP 1 3');
  Assert.AreEqual('DOOM|-WARP|1|3|-NOMONSTERS', Expand(['DOOM', '@R.TXT', '-NOMONSTERS']));
end;

procedure TTestCommandLineResponseFile.DovrebbeSeparareGliArgomentiConSpaziEACapo;
begin
  FSource.Add('R.TXT', '-A'#13#10'-B -C'#10'-D'#13'-E');
  Assert.AreEqual('P|-A|-B|-C|-D|-E', Expand(['P', '@R.TXT']));
end;

procedure TTestCommandLineResponseFile.DovrebbeTenereIlPuntoDoveStavaIlFile;
begin
  FSource.Add('R.TXT', 'X Y');
  Assert.AreEqual('P|1|X|Y|2', Expand(['P', '1', '@R.TXT', '2']));
end;

procedure TTestCommandLineResponseFile.DovrebbeSaltareUnFileMancanteEDirlo;
begin
  Assert.AreEqual('P|1', Expand(['P', '@NONE.TXT', '1']));
end;

procedure TTestCommandLineResponseFile.DovrebbeScrivereIMessaggiDelVecchioCodice;
begin
  FSource.Add('R.TXT', 'X');
  Expand(['P', '@R.TXT', '@NONE.TXT']);
  Assert.AreEqual('Found response file R.TXT!'#13#10#13#10'No such response file: NONE.TXT!'#13#10,
    FLog.Text);
end;

procedure TTestCommandLineResponseFile.DovrebbeScartareGliArgomentiVuoti;
begin
  FSource.Add('R.TXT', '  X   '#13#10#13#10' Y ');
  Assert.AreEqual('P|X|Y|Z', Expand(['P', '', '@R.TXT', 'Z']));
end;

procedure TTestCommandLineResponseFile.DovrebbeTenereIlNomeDelProgrammaAnchePerUnaChiocciola;
begin
  // the first argument is the program: it is never a response file
  Assert.AreEqual('@P|1', Expand(['@P', '1']));
end;

procedure TTestCommandLineResponseFile.DovrebbeFermarsiAlMassimoDegliArgomenti;
begin
  FSource.Add('R.TXT', 'A B C D E');
  Assert.AreEqual('P|A|B', Expand(['P', '@R.TXT'], 3));
end;

procedure TTestCommandLineResponseFile.DovrebbeLeggereTuttiIFileDiRisposta;
begin
  FSource.Add('A.TXT', '1 2');
  FSource.Add('B.TXT', '3');
  Assert.AreEqual('P|1|2|3', Expand(['P', '@A.TXT', '@B.TXT']));
end;

procedure TTestCommandLineResponseFile.DovrebbeUsareIlCarattereGiustoDelFile;
begin
  // regression: the old FindResponseFile copied the character at the index of the argument
  // (filename[i]) and not the one of the file, so a word was made of a single repeated letter
  FSource.Add('R.TXT', '-WARP 12 -SKILL 4');
  Assert.AreEqual('P|-WARP|12|-SKILL|4', Expand(['P', '@R.TXT']));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCommandLineResponseFile);

end.
