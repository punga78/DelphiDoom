{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the engine system library - the output and the machine }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.EngineSystem.Io;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.EngineSystem.Types,
  DelphiDoom.EngineSystem.StdoutBuffer;

type
  [TestFixture]
  [Category('enginesystem')]
  TTestStdoutBuffer = class(TObject)
  private
    FBuffer: TStdoutBuffer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeEssereVuotoAllInizio;
    [Test]
    procedure DovrebbeIgnorareUnTestoVuoto;
    [Test]
    procedure DovrebbeFareUnaRigaVuotaConUnSoloRitornoCarrello;
    [Test]
    procedure DovrebbeAggiungereUnaRigaDopoUnRitornoCarrello;
    [Test]
    procedure DovrebbeContinuareLUltimaRigaSeIlTestoPrecedenteNonFinisceConCr;
    [Test]
    procedure DovrebbeNonFarCrescerePiuLaPrimaRiga;
    [Test]
    procedure DovrebbeDividereLeRigheSuCrLfECrOLf;
    [Test]
    procedure DovrebbeFermarsiAlTerminatoreDelTesto;
    [Test]
    procedure DovrebbeDareIlTestoConCrLfInOgniRiga;
    [Test]
    procedure DovrebbeSvuotarsiEFarRipartireUnaNuovaRiga;
    [Test]
    procedure DovrebbeSalvareIlTestoComeOttoBit;
    [Test]
    procedure DovrebbeDireFalsoSeNonPuoScrivere;
    [Test]
    procedure DovrebbeDareLeStesseRigheDelVecchioCodice;
  end;

  [TestFixture]
  [Category('enginesystem')]
  TTestLogFileNames = class(TObject)
  public
    [Test]
    procedure DovrebbeDareINomiDelGiocoSoftware;
    [Test]
    procedure DovrebbeMettereGlPerOpenGl;
    [Test]
    procedure DovrebbeNumerareIlFileDiDebugConIlGiocatore;
    [Test]
    procedure DovrebbeMettereLaCartellaDelCdRomDavanti;
    [Test]
    procedure DovrebbeDareGliStessiNomiDelVecchioCodice;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.EngineSystem.LogFileNames, DelphiDoom.Tests.EngineSystem.Legacy;

function TempName(const AName: string): string;
begin
  Result := TPath.Combine(TPath.GetTempPath, AName);
end;

{ TTestStdoutBuffer }

procedure TTestStdoutBuffer.Setup;
begin
  FBuffer := TStdoutBuffer.Create;
end;

procedure TTestStdoutBuffer.TearDown;
begin
  FBuffer.Free;
end;

procedure TTestStdoutBuffer.DovrebbeEssereVuotoAllInizio;
begin
  Assert.AreEqual(0, FBuffer.Count);
  Assert.AreEqual('', FBuffer.Text);
end;

procedure TTestStdoutBuffer.DovrebbeIgnorareUnTestoVuoto;
begin
  FBuffer.Append('');
  Assert.AreEqual(0, FBuffer.Count);
end;

procedure TTestStdoutBuffer.DovrebbeFareUnaRigaVuotaConUnSoloRitornoCarrello;
begin
  FBuffer.Append(#13);
  Assert.AreEqual(1, FBuffer.Count);
  Assert.AreEqual('', FBuffer[0]);
end;

procedure TTestStdoutBuffer.DovrebbeAggiungereUnaRigaDopoUnRitornoCarrello;
begin
  FBuffer.Append('uno'#13);
  FBuffer.Append('due');
  Assert.AreEqual(2, FBuffer.Count);
  Assert.AreEqual('due', FBuffer[1]);
end;

procedure TTestStdoutBuffer.DovrebbeContinuareLUltimaRigaSeIlTestoPrecedenteNonFinisceConCr;
begin
  // a text that ends with CR LF ends with LF: the next text goes on the same line (old behaviour)
  FBuffer.Append('x'#13);
  FBuffer.Append('uno'#13#10);
  FBuffer.Append('due');
  Assert.AreEqual(2, FBuffer.Count);
  Assert.AreEqual('unodue', FBuffer[1]);
end;

procedure TTestStdoutBuffer.DovrebbeNonFarCrescerePiuLaPrimaRiga;
begin
  // a defect of the old TDStringList.Put, kept: the text that continues line 0 is lost
  FBuffer.Append('uno'#13#10);
  FBuffer.Append('due');
  Assert.AreEqual(1, FBuffer.Count);
  Assert.AreEqual('uno', FBuffer[0]);
end;

procedure TTestStdoutBuffer.DovrebbeDividereLeRigheSuCrLfECrOLf;
begin
  FBuffer.Append('a'#13#10'b'#10'c'#13'd');
  Assert.AreEqual(4, FBuffer.Count);
  Assert.AreEqual('d', FBuffer[3]);
end;

procedure TTestStdoutBuffer.DovrebbeFermarsiAlTerminatoreDelTesto;
begin
  FBuffer.Append('ab'#0'cd');
  Assert.AreEqual(1, FBuffer.Count);
  Assert.AreEqual('ab', FBuffer[0]);
  // a text that starts with the terminator has no lines: the old code failed when it had to continue a line
  FBuffer.Append(#0'x');
  Assert.AreEqual(1, FBuffer.Count);
end;

procedure TTestStdoutBuffer.DovrebbeDareIlTestoConCrLfInOgniRiga;
begin
  FBuffer.Append('uno'#13);
  FBuffer.Append('due'#13);
  Assert.AreEqual('uno'#13#10'due'#13#10, FBuffer.Text);
end;

procedure TTestStdoutBuffer.DovrebbeSvuotarsiEFarRipartireUnaNuovaRiga;
begin
  FBuffer.Append('uno');
  FBuffer.Clear;
  Assert.AreEqual(0, FBuffer.Count);
  FBuffer.Append('x');
  Assert.AreEqual(1, FBuffer.Count);
end;

procedure TTestStdoutBuffer.DovrebbeSalvareIlTestoComeOttoBit;
var
  LFileName: string;
  LStream: TFileStream;
  LBytes: TBytes;
begin
  LFileName := TempName('enginesystem_stdout.txt');
  try
    FBuffer.Append('ab'#13);
    Assert.IsTrue(FBuffer.SaveToFile(LFileName));
    LStream := TFileStream.Create(LFileName, fmOpenRead);
    try
      SetLength(LBytes, LStream.Size);
      LStream.ReadBuffer(LBytes[0], LStream.Size);
    finally
      LStream.Free;
    end;
    Assert.AreEqual(4, Length(LBytes));
    Assert.AreEqual(Byte(Ord('a')), LBytes[0]);
    Assert.AreEqual(Byte(13), LBytes[2]);
    Assert.AreEqual(Byte(10), LBytes[3]);
  finally
    DeleteFile(LFileName);
  end;
end;

procedure TTestStdoutBuffer.DovrebbeDireFalsoSeNonPuoScrivere;
begin
  FBuffer.Append('ab'#13);
  Assert.IsFalse(FBuffer.SaveToFile(TempName('enginesystem_no_such_folder\x.txt')));
end;

procedure TTestStdoutBuffer.DovrebbeDareLeStesseRigheDelVecchioCodice;
const
  PARTS: array[0..13] of string = ('abc', #13#10, 'x'#13, #13, 'a'#10'b', #10, 'l1'#13#10'l2'#13#10,
    'q', '  ', #13#13, #10#10, 'k'#13#10, '', 'zz'#10);
var
  LCase: Integer;
  LStep: Integer;
  LCount: Integer;
  LOld: TLegacyIo;
  LNew: TStdoutBuffer;
  LIndex: Integer;
  LText: string;
begin
  RandSeed := 1854;
  for LCase := 1 to 500 do
  begin
    LOld := TLegacyIo.Create;
    LNew := TStdoutBuffer.Create;
    try
      LCount := 1 + Random(25);
      for LStep := 1 to LCount do
      begin
        LText := PARTS[Random(Length(PARTS))];
        LOld.I_IOprintf(LText);
        LNew.Append(LText);
        Assert.AreEqual(LOld.stdoutbuffer.Count, LNew.Count, Format('case %d step %d', [LCase, LStep]));
        for LIndex := 0 to LNew.Count - 1 do
          Assert.AreEqual(LOld.stdoutbuffer[LIndex], LNew[LIndex]);
      end;
      Assert.AreEqual(LOld.stdoutbuffer.Text, LNew.Text);
    finally
      LNew.Free;
      LOld.Free;
    end;
  end;
end;

{ TTestLogFileNames }

procedure TTestLogFileNames.DovrebbeDareINomiDelGiocoSoftware;
var
  LNames: TLogFileSet;
begin
  LNames := TLogFileNames.Build('Doom', False, False, 0, '');
  Assert.AreEqual('DATA\LOGS\Doom32_debug.txt', LNames.DebugFile);
  Assert.AreEqual('DATA\LOGS\Doom32_stderr.txt', LNames.ErrorFile);
  Assert.AreEqual('DATA\LOGS\Doom32_stdout.txt', LNames.StdoutFile);
end;

procedure TTestLogFileNames.DovrebbeMettereGlPerOpenGl;
var
  LNames: TLogFileSet;
begin
  LNames := TLogFileNames.Build('Hexen', True, False, 0, '');
  Assert.AreEqual('DATA\LOGS\GLHexen32_debug.txt', LNames.DebugFile);
  Assert.AreEqual('DATA\LOGS\GLHexen32_stderr.txt', LNames.ErrorFile);
  Assert.AreEqual('DATA\LOGS\GLHexen32_stdout.txt', LNames.StdoutFile);
end;

procedure TTestLogFileNames.DovrebbeNumerareIlFileDiDebugConIlGiocatore;
begin
  Assert.AreEqual('DATA\LOGS\Strife32_debug2.txt',
    TLogFileNames.Build('Strife', False, True, 2, '').DebugFile);
  // only the debug file has the number
  Assert.AreEqual('DATA\LOGS\Strife32_stderr.txt',
    TLogFileNames.Build('Strife', False, True, 2, '').ErrorFile);
end;

procedure TTestLogFileNames.DovrebbeMettereLaCartellaDelCdRomDavanti;
var
  LNames: TLogFileSet;
begin
  LNames := TLogFileNames.Build('Heretic', False, False, 0, 'c:\heretic.cd\');
  Assert.AreEqual('c:\heretic.cd\DATA\LOGS\Heretic32_debug.txt', LNames.DebugFile);
  Assert.AreEqual('c:\heretic.cd\DATA\LOGS\Heretic32_stderr.txt', LNames.ErrorFile);
  Assert.AreEqual('c:\heretic.cd\DATA\LOGS\Heretic32_stdout.txt', LNames.StdoutFile);
end;

procedure TTestLogFileNames.DovrebbeDareGliStessiNomiDelVecchioCodice;
const
  GAMES: array[0..3] of string = ('Doom', 'Heretic', 'Hexen', 'Strife');
var
  LGame: Integer;
  LGl: Integer;
  LDebug: Integer;
  LPlayer: Integer;
  LCd: Integer;
  LOld: TLogFileSet;
  LNew: TLogFileSet;
  LFolder: string;
begin
  for LGame := 0 to 3 do
    for LGl := 0 to 1 do
      for LDebug := 0 to 1 do
        for LPlayer := 0 to 3 do
          for LCd := 0 to 1 do
          begin
            LFolder := '';
            if LCd = 1 then
              LFolder := 'c:\x.cd\';
            LOld := TLegacyIo.Names(GAMES[LGame], LGl = 1, LDebug = 1, LPlayer, LCd = 1, 'c:\x.cd\');
            LNew := TLogFileNames.Build(GAMES[LGame], LGl = 1, LDebug = 1, LPlayer, LFolder);
            Assert.AreEqual(LOld.DebugFile, LNew.DebugFile);
            Assert.AreEqual(LOld.ErrorFile, LNew.ErrorFile);
            Assert.AreEqual(LOld.StdoutFile, LNew.StdoutFile);
          end;
end;

end.
