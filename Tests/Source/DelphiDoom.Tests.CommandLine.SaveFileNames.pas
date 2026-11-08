{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the command line library - TSaveFileNames              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.CommandLine.SaveFileNames;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DUnitX.TestFramework,
  DelphiDoom.CommandLine.Intf;

type
  [TestFixture]
  [Category('commandline')]
  TTestCommandLineSaveFileNames = class(TObject)
  strict private
    FMadeFolders: TList<string>;
    FDriveQuestions: Integer;
    function MakeCommandLine(const AArguments: array of string): ICommandLine;
    function MakeNames(const ACommandLine: ICommandLine; AProgramOnCdRom: Boolean): ISaveFileNames;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLoStessoNomeSenzaCdRom;
    [Test]
    procedure DovrebbeUsareLaCartellaDiLavoroSeIlProgrammaEsceDaUnCdRom;
    [Test]
    procedure DovrebbeUsareLaCartellaDiLavoroConIlParametroCdRom;
    [Test]
    procedure DovrebbeNonCercareIlParametroSeIlProgrammaEGiaSuCdRom;
    [Test]
    procedure DovrebbeFareLaCartellaUnaSolaVolta;
    [Test]
    procedure DovrebbeNonFareLaCartellaSenzaCdRom;
    [Test]
    procedure DovrebbeChiedereAlDiscoUnaSolaVolta;
    [Test]
    procedure DovrebbeRicordareLaPrimaRispostaAncheSeLaRigaDiComandoCambia;
    [Test]
    procedure DovrebbeRicordareIlParametroCdRomTraQuelliCercati;
    [Test]
    procedure DovrebbeSollevareEccezioneSeUnaDipendenzaMancaOppureENil;
    [Test]
    procedure DovrebbeArrivareDallaFabbrica;
  end;

implementation

uses
  DelphiDoom.CommandLine.Factory;

const
  WORKING_FOLDER = 'c:\doomdata\';

{ TTestCommandLineSaveFileNames }

procedure TTestCommandLineSaveFileNames.Setup;
begin
  FMadeFolders := TList<string>.Create;
  FDriveQuestions := 0;
end;

procedure TTestCommandLineSaveFileNames.TearDown;
begin
  FMadeFolders.Free;
end;

function TTestCommandLineSaveFileNames.MakeCommandLine(
  const AArguments: array of string): ICommandLine;
var
  LItems: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LItems, Length(AArguments) + 1);
  LItems[0] := 'doom32.exe';
  for LIndex := 0 to High(AArguments) do
    LItems[LIndex + 1] := AArguments[LIndex];
  Result := TCommandLineFactory.CreateCommandLine(LItems);
end;

function TTestCommandLineSaveFileNames.MakeNames(const ACommandLine: ICommandLine;
  AProgramOnCdRom: Boolean): ISaveFileNames;
begin
  Result := TCommandLineFactory.CreateSaveFileNames(ACommandLine,
    function: Boolean
    begin
      Inc(FDriveQuestions);
      Result := AProgramOnCdRom;
    end,
    procedure(APath: string)
    begin
      FMadeFolders.Add(APath);
    end, WORKING_FOLDER);
end;

procedure TTestCommandLineSaveFileNames.DovrebbeDareLoStessoNomeSenzaCdRom;
var
  LNames: ISaveFileNames;
begin
  LNames := MakeNames(MakeCommandLine([]), False);
  Assert.IsFalse(LNames.IsCdRomMode);
  Assert.AreEqual('DATA\', LNames.ResolveName('DATA\'));
  Assert.AreEqual('', LNames.ResolveName(''));
end;

procedure TTestCommandLineSaveFileNames.DovrebbeUsareLaCartellaDiLavoroSeIlProgrammaEsceDaUnCdRom;
var
  LNames: ISaveFileNames;
begin
  LNames := MakeNames(MakeCommandLine([]), True);
  Assert.IsTrue(LNames.IsCdRomMode);
  Assert.AreEqual(WORKING_FOLDER + 'DATA\', LNames.ResolveName('DATA\'));
end;

procedure TTestCommandLineSaveFileNames.DovrebbeUsareLaCartellaDiLavoroConIlParametroCdRom;
var
  LNames: ISaveFileNames;
begin
  LNames := MakeNames(MakeCommandLine(['-warp', '-cdrom']), False);
  Assert.IsTrue(LNames.IsCdRomMode);
  Assert.AreEqual(WORKING_FOLDER + 'doom32.ini', LNames.ResolveName('doom32.ini'));
end;

procedure TTestCommandLineSaveFileNames.DovrebbeNonCercareIlParametroSeIlProgrammaEGiaSuCdRom;
var
  LQueried: IQueriedCommandLine;
  LNames: ISaveFileNames;
begin
  LQueried := TCommandLineFactory.CreateQueriedCommandLine;
  LNames := MakeNames(LQueried, True);
  Assert.IsTrue(LNames.IsCdRomMode);
  Assert.AreEqual(0, Length(LQueried.QueriedNames));
end;

procedure TTestCommandLineSaveFileNames.DovrebbeFareLaCartellaUnaSolaVolta;
var
  LNames: ISaveFileNames;
begin
  LNames := MakeNames(MakeCommandLine([]), True);
  LNames.ResolveName('a');
  LNames.ResolveName('b');
  LNames.IsCdRomMode;
  Assert.AreEqual(1, FMadeFolders.Count);
  Assert.AreEqual(WORKING_FOLDER, FMadeFolders[0]);
end;

procedure TTestCommandLineSaveFileNames.DovrebbeNonFareLaCartellaSenzaCdRom;
var
  LNames: ISaveFileNames;
begin
  LNames := MakeNames(MakeCommandLine([]), False);
  LNames.ResolveName('a');
  Assert.AreEqual(0, FMadeFolders.Count);
end;

procedure TTestCommandLineSaveFileNames.DovrebbeChiedereAlDiscoUnaSolaVolta;
var
  LNames: ISaveFileNames;
begin
  LNames := MakeNames(MakeCommandLine([]), False);
  LNames.ResolveName('a');
  LNames.ResolveName('b');
  LNames.IsCdRomMode;
  Assert.AreEqual(1, FDriveQuestions);
end;

procedure TTestCommandLineSaveFileNames.DovrebbeRicordareLaPrimaRispostaAncheSeLaRigaDiComandoCambia;
var
  LQueried: IQueriedCommandLine;
  LNames: ISaveFileNames;
begin
  // as the old cdchecked: asked before the arguments are read, it stays false
  LQueried := TCommandLineFactory.CreateQueriedCommandLine;
  LNames := MakeNames(LQueried, False);
  Assert.IsFalse(LNames.IsCdRomMode);
  LQueried.Attach(MakeCommandLine(['-cdrom']));
  Assert.IsFalse(LNames.IsCdRomMode);
  Assert.AreEqual('x', LNames.ResolveName('x'));
end;

procedure TTestCommandLineSaveFileNames.DovrebbeRicordareIlParametroCdRomTraQuelliCercati;
var
  LQueried: IQueriedCommandLine;
  LNames: ISaveFileNames;
begin
  LQueried := TCommandLineFactory.CreateQueriedCommandLine;
  LQueried.Attach(MakeCommandLine([]));
  LNames := MakeNames(LQueried, False);
  LNames.IsCdRomMode;
  Assert.AreEqual(1, Length(LQueried.QueriedNames));
  Assert.AreEqual('-cdrom', LQueried.QueriedNames[0]);
end;

procedure TTestCommandLineSaveFileNames.DovrebbeSollevareEccezioneSeUnaDipendenzaMancaOppureENil;
begin
  Assert.WillRaise(
    procedure
    begin
      TCommandLineFactory.CreateSaveFileNames(nil, nil, nil, WORKING_FOLDER);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TCommandLineFactory.CreateSaveFileNames(MakeCommandLine([]), nil,
        procedure(APath: string)
        begin
        end, WORKING_FOLDER);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TCommandLineFactory.CreateSaveFileNames(MakeCommandLine([]),
        function: Boolean
        begin
          Result := False;
        end, nil, WORKING_FOLDER);
    end, EArgumentNilException);
end;

procedure TTestCommandLineSaveFileNames.DovrebbeArrivareDallaFabbrica;
begin
  Assert.IsTrue(Assigned(MakeNames(MakeCommandLine([]), False)));
end;

end.
