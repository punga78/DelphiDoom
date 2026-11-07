{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeCompileCommand and TIdePCodeFile }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.CompileCommand;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.CompileCommand,
  DelphiDoom.Tests.Ide.FakeFileSystem,
  DelphiDoom.Tests.Ide.FakeLog,
  DelphiDoom.Tests.Ide.FakeScriptCompiler;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeCompileCommand = class(TObject)
  strict private
    FCompiler: TFakeIdeScriptCompiler;
    FCompilerIntf: IIdeScriptCompiler;
    FLog: TFakeIdeLog;
    FLogIntf: IIdeLog;
    FCommand: TIdeCompileCommand;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereMessaggiELuogoComeIlVecchioEditorConIlCompilatoreVero;
    [Test]
    procedure DovrebbeScrivereGliAvvisiSeLaCompilazioneRiesce;
    [Test]
    procedure DovrebbeScrivereGliErroriSeLaCompilazioneFallisce;
    [Test]
    procedure DovrebbeDareIlCodiceCompilato;
    [Test]
    procedure DovrebbeDareLaPosizioneDelPrimoErrore;
    [Test]
    procedure DovrebbeDareIlGiocoEIlTestoAlCompilatore;
    [Test]
    procedure DovrebbePassareIlTestoPerUnAnsiStringComeFaceva;
    [Test]
    procedure DovrebbeDareEccezioneSeLeDipendenzeSonoNil;
  end;

  [TestFixture]
  [Category('ide')]
  TTestIdePCodeFile = class(TObject)
  public
    [Test]
    procedure DovrebbeScrivereUnByteERisultatiUgualiAlFileDelCompilatoreAReale;
    [Test]
    procedure DovrebbeScrivereUnSoloByteInFileNonDue;
    [Test]
    procedure DovrebbeTagliareIPassiAOttoBit;
    [Test]
    procedure DovrebbeDareFalsoSeIlFileNonSiScrive;
  end;

implementation

uses
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.PCodeFile,
  DelphiDoom.Tests.Ide.CompilerGolden,
  DelphiDoom.Tests.Ide.TestData;

{ TTestIdeCompileCommand }

procedure TTestIdeCompileCommand.Setup;
begin
  FCompiler := TFakeIdeScriptCompiler.Create;
  FCompilerIntf := FCompiler;
  FLog := TFakeIdeLog.Create;
  FLogIntf := FLog;
  FCommand := TIdeCompileCommand.Create(FCompilerIntf, FLogIntf);
end;

procedure TTestIdeCompileCommand.TearDown;
begin
  FCommand.Free;
  FLogIntf := nil;
  FCompilerIntf := nil;
end;

procedure TTestIdeCompileCommand.DovrebbeScrivereMessaggiELuogoComeIlVecchioEditorConIlCompilatoreVero;
var
  LGame, LScript, LLine, LExpectedLog: string;
  LGolden: TCompilerGolden;
  LResult: TIdeCompileResult;
  LIndex: Integer;
  LKind: string;
begin
  for LGame in TCompilerGolden.Games do
    for LScript in TCompilerGolden.Scripts do
    begin
      LGolden := TCompilerGolden.Load(LScript, LGame);
      FCompiler.Succeeds := LGolden.Succeeded;
      FCompiler.PCode := LGolden.PCode;
      FCompiler.Messages := LGolden.Messages;
      FLog.Clear;
      LResult := FCommand.Execute(LGame, LScript + '.ddscript', 'source');

      Assert.AreEqual(LGolden.Succeeded, LResult.Success, LScript + ' ' + LGame);
      // a failed compilation hands back some bytes too (the old editor ignored them)
      if LGolden.Succeeded then
        Assert.AreEqual(LGolden.PCodeLength, Length(LResult.PCode), LScript + ' ' + LGame);
      Assert.AreEqual(Pos(',', LGolden.Location) > 0, LResult.HasErrorLocation, LScript + ' ' + LGame);
      if LResult.HasErrorLocation then
        Assert.AreEqual(LGolden.Location, Format('%d,%d', [LResult.ErrorLocation.Line,
          LResult.ErrorLocation.Column]), LScript + ' ' + LGame);

      // the first line says what is compiled, then one line per line of the messages
      Assert.AreEqual(Format('NORMAL|Compiling %s script "%s.ddscript"', [LGame, LScript]), FLog.Lines[0]);
      if LGolden.Succeeded then
        LKind := 'WARNING|'
      else
        LKind := 'ERROR|';
      LIndex := 1;
      with TStringList.Create do
      try
        Text := LGolden.Messages;
        for LLine in ToStringArray do
        begin
          LExpectedLog := LKind + StringReplace(LLine, #13, '\r', [rfReplaceAll]);
          Assert.AreEqual(LExpectedLog, FLog.Lines[LIndex], LScript + ' ' + LGame);
          Inc(LIndex);
        end;
      finally
        Free;
      end;
      if LGolden.Succeeded then
      begin
        Assert.AreEqual('NORMAL|Compile successful', FLog.Lines[LIndex]);
        Inc(LIndex);
      end;
      Assert.AreEqual(LIndex, FLog.Lines.Count, LScript + ' ' + LGame);
    end;
end;

procedure TTestIdeCompileCommand.DovrebbeScrivereGliAvvisiSeLaCompilazioneRiesce;
begin
  FCompiler.Succeeds := True;
  FCompiler.Messages := 'warning one'#13#10'warning two';
  FCommand.Execute('doom', 'a.ddscript', 'x');
  Assert.AreEqual(4, FLog.Lines.Count);
  Assert.AreEqual('WARNING|warning one', FLog.Lines[1]);
  Assert.AreEqual('WARNING|warning two', FLog.Lines[2]);
  Assert.AreEqual('NORMAL|Compile successful', FLog.Lines[3]);
end;

procedure TTestIdeCompileCommand.DovrebbeScrivereGliErroriSeLaCompilazioneFallisce;
begin
  FCompiler.Succeeds := False;
  FCompiler.Messages := 'error one';
  FCommand.Execute('doom', 'a.ddscript', 'x');
  Assert.AreEqual(2, FLog.Lines.Count);
  Assert.AreEqual('ERROR|error one', FLog.Lines[1]);
end;

procedure TTestIdeCompileCommand.DovrebbeDareIlCodiceCompilato;
var
  LResult: TIdeCompileResult;
begin
  FCompiler.Succeeds := True;
  FCompiler.PCode := 'ABC';
  LResult := FCommand.Execute('doom', 'a.ddscript', 'x');
  Assert.AreEqual('ABC', LResult.PCode);
end;

procedure TTestIdeCompileCommand.DovrebbeDareLaPosizioneDelPrimoErrore;
var
  LResult: TIdeCompileResult;
begin
  FCompiler.Succeeds := False;
  FCompiler.Messages := ' Pos: 000046 Compiler: [Error] (12:7): Unknown identifier';
  LResult := FCommand.Execute('doom', 'a.ddscript', 'x');
  Assert.IsTrue(LResult.HasErrorLocation);
  Assert.AreEqual(12, LResult.ErrorLocation.Line);
  Assert.AreEqual(7, LResult.ErrorLocation.Column);
end;

procedure TTestIdeCompileCommand.DovrebbeDareIlGiocoEIlTestoAlCompilatore;
begin
  FCommand.Execute('hexen', 'a.ddscript', 'uses all;');
  Assert.AreEqual('hexen', FCompiler.LastGame);
  Assert.AreEqual('uses all;', FCompiler.LastSource);
  Assert.AreEqual(1, FCompiler.CompileCount);
end;

procedure TTestIdeCompileCommand.DovrebbePassareIlTestoPerUnAnsiStringComeFaceva;
var
  LSource: string;
begin
  LSource := 'a' + Char($0416) + 'b';
  FCommand.Execute('doom', 'a.ddscript', LSource);
  Assert.AreEqual(string(AnsiString(LSource)), FCompiler.LastSource);
end;

procedure TTestIdeCompileCommand.DovrebbeDareEccezioneSeLeDipendenzeSonoNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TIdeCompileCommand.Create(nil, FLogIntf).Free;
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TIdeCompileCommand.Create(FCompilerIntf, nil).Free;
    end, EArgumentNilException);
end;

{ TTestIdePCodeFile }

procedure TTestIdePCodeFile.DovrebbeScrivereUnByteERisultatiUgualiAlFileDelCompilatoreAReale;
var
  LGame, LScript: string;
  LGolden: TCompilerGolden;
  LBytes: AnsiString;
  LChecked: Integer;
begin
  LChecked := 0;
  for LGame in TCompilerGolden.Games do
    for LScript in TCompilerGolden.Scripts do
    begin
      LGolden := TCompilerGolden.Load(LScript, LGame);
      if not LGolden.Succeeded then
        Continue;
      // ddc.exe wrote one byte for each character: the file is the reference
      LBytes := TIdeTestData.ReadBytes('Compiler\' + LScript + '.' + LGame + '.ddout');
      Assert.AreEqual(string(LBytes), string(TIdePCodeFile.ToBytes(LGolden.PCode)), LScript + ' ' + LGame);
      Assert.AreEqual(Length(LBytes), Length(TIdePCodeFile.ToBytes(LGolden.PCode)));
      Inc(LChecked);
    end;
  Assert.IsTrue(LChecked >= 8);
end;

procedure TTestIdePCodeFile.DovrebbeScrivereUnSoloByteInFileNonDue;
var
  LFileSystem: TFakeIdeFileSystem;
  LFileSystemIntf: IIdeFileSystem;
begin
  // regression: the old editor wrote SizeOf(Char) = 2 bytes for each character
  LFileSystem := TFakeIdeFileSystem.Create('C:\prj');
  LFileSystemIntf := LFileSystem;
  Assert.IsTrue(TIdePCodeFile.Save(LFileSystemIntf, 'C:\prj\a.ddout', #1#2#3#$FE));
  Assert.AreEqual(4, Length(LFileSystem.Content('C:\prj\a.ddout')));
  Assert.AreEqual(string(AnsiString(#1#2#3#$FE)), string(LFileSystem.Content('C:\prj\a.ddout')));
end;

procedure TTestIdePCodeFile.DovrebbeTagliareIPassiAOttoBit;
begin
  Assert.AreEqual(65, Integer(Ord(TIdePCodeFile.ToBytes(Char($0141))[1])));
end;

procedure TTestIdePCodeFile.DovrebbeDareFalsoSeIlFileNonSiScrive;
var
  LFileSystem: TFakeIdeFileSystem;
  LFileSystemIntf: IIdeFileSystem;
begin
  LFileSystem := TFakeIdeFileSystem.Create('C:\prj');
  LFileSystemIntf := LFileSystem;
  Assert.IsFalse(TIdePCodeFile.Save(LFileSystemIntf, 'C:\nowhere\a.ddout', 'x'));
end;

end.
