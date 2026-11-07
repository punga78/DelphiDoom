{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - message list, project tree, events   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.SmallModels;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.MessageLog;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeMessageLog = class(TObject)
  strict private
    FLog: TIdeMessageLog;
    FLogIntf: IInterface;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeFareUnMessaggioPerOgniRiga;
    [Test]
    procedure DovrebbeTenereIlTipoDiOgniMessaggio;
    [Test]
    procedure DovrebbeNonContareLInvioFinale;
    [Test]
    procedure DovrebbeTenereSoloGliUltimi256Messaggi;
    [Test]
    procedure DovrebbeTogliereLePrimeRigheAncheSeIlTestoENuovoEVuoto;
    [Test]
    procedure DovrebbeAvvisareLaFinestraAdOgniCambio;
    [Test]
    procedure DovrebbeFormattareIlTesto;
    [Test]
    procedure DovrebbeDareTutteLeRigheComeTesto;
    [Test]
    procedure DovrebbeSvuotarsi;
  end;

  [TestFixture]
  [Category('ide')]
  TTestIdeProjectOutline = class(TObject)
  public
    [Test]
    procedure DovrebbeAvereSempreIRamiActorsScriptsECompiledScripts;
    [Test]
    procedure DovrebbeMettereOgniFileNelRamoDelSuoTipoInOrdine;
    [Test]
    procedure DovrebbeNonMostrareGliElementiDiAltriTipi;
    [Test]
    procedure DovrebbeUsareIlPercorsoRelativoAlProgetto;
    [Test]
    procedure DovrebbeDareSoloIRamiSeNonCeProgetto;
  end;

  [TestFixture]
  [Category('ide')]
  TTestIdeEventSnippets = class(TObject)
  public
    [Test]
    procedure DovrebbeSeparareNomeEDichiarazione;
    [Test]
    procedure DovrebbeScrivereLEventoDopoDueRigheVuote;
    [Test]
    procedure DovrebbeMettereUsesAllInUnoScriptVuoto;
    [Test]
    procedure DovrebbeMettereUsesAllAncheSeCiSonoSoloSpazi;
    [Test]
    procedure DovrebbePorreIlCursoreTreCaratteriPrimaDiEnd;
    [Test]
    procedure DovrebbePorreIlCursoreAZeroSenzaEnd;
    [Test]
    procedure DovrebbeContareDallaFineDelTestoEsistente;
  end;

implementation

uses
  DelphiDoom.Ide.Intf,
  DelphiDoom.Ide.Project,
  DelphiDoom.Ide.Outline,
  DelphiDoom.Ide.ProjectOutline,
  DelphiDoom.Ide.EventSnippets,
  DelphiDoom.Tests.Ide.FakeFileSystem,
  DelphiDoom.Tests.Ide.FakeLog,
  DelphiDoom.Tests.Ide.FakeClock;

{ TTestIdeMessageLog }

procedure TTestIdeMessageLog.Setup;
begin
  FLog := TIdeMessageLog.Create;
  FLogIntf := FLog;
end;

procedure TTestIdeMessageLog.TearDown;
begin
  FLogIntf := nil;
end;

procedure TTestIdeMessageLog.DovrebbeFareUnMessaggioPerOgniRiga;
begin
  FLog.Write(mkNormal, 'one'#13#10'two'#13#10'three');
  Assert.AreEqual(3, FLog.Count);
  Assert.AreEqual('two', FLog[1].Text);
end;

procedure TTestIdeMessageLog.DovrebbeTenereIlTipoDiOgniMessaggio;
begin
  FLog.Write(mkError, 'bad');
  FLog.Write(mkWarning, 'careful');
  Assert.AreEqual(Ord(mkError), Ord(FLog[0].Kind));
  Assert.AreEqual(Ord(mkWarning), Ord(FLog[1].Kind));
end;

procedure TTestIdeMessageLog.DovrebbeNonContareLInvioFinale;
begin
  FLog.Write(mkNormal, 'Loading "x"'#13#10);
  Assert.AreEqual(1, FLog.Count);
end;

procedure TTestIdeMessageLog.DovrebbeTenereSoloGliUltimi256Messaggi;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 300 do
    FLog.Write(mkNormal, 'm' + IntToStr(LIndex));
  Assert.AreEqual(256, FLog.Count);
  Assert.AreEqual('m45', FLog[0].Text);
  Assert.AreEqual('m300', FLog[255].Text);
end;

procedure TTestIdeMessageLog.DovrebbeTogliereLePrimeRigheAncheSeIlTestoENuovoEVuoto;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 256 do
    FLog.Write(mkNormal, 'm' + IntToStr(LIndex));
  // as the old list did: the room is made before the lines are counted
  FLog.Write(mkNormal, '');
  Assert.AreEqual(255, FLog.Count);
  Assert.AreEqual('m2', FLog[0].Text);
end;

procedure TTestIdeMessageLog.DovrebbeAvvisareLaFinestraAdOgniCambio;
var
  LCount: Integer;
begin
  LCount := 0;
  FLog.OnChanged :=
    procedure
    begin
      Inc(LCount);
    end;
  FLog.Write(mkNormal, 'a');
  FLog.Clear;
  Assert.AreEqual(2, LCount);
end;

procedure TTestIdeMessageLog.DovrebbeFormattareIlTesto;
begin
  FLog.WriteFormat(mkInfo, 'File "%s" is %d bytes', ['a.txt', 12]);
  Assert.AreEqual('File "a.txt" is 12 bytes', FLog[0].Text);
end;

procedure TTestIdeMessageLog.DovrebbeDareTutteLeRigheComeTesto;
begin
  FLog.Write(mkNormal, 'a'#13#10'b');
  Assert.AreEqual('a'#13#10'b'#13#10, FLog.AsText);
end;

procedure TTestIdeMessageLog.DovrebbeSvuotarsi;
begin
  FLog.Write(mkNormal, 'a');
  FLog.Clear;
  Assert.AreEqual(0, FLog.Count);
  Assert.AreEqual('', FLog.AsText);
end;

{ TTestIdeProjectOutline }

procedure TTestIdeProjectOutline.DovrebbeAvereSempreIRamiActorsScriptsECompiledScripts;
var
  LOutline: TIdeOutline;
begin
  LOutline := TIdeProjectOutline.Build(nil);
  try
    Assert.AreEqual(3, LOutline.Roots.Count);
    Assert.AreEqual('Actors', LOutline.Roots[0].Text);
    Assert.AreEqual('Scripts', LOutline.Roots[1].Text);
    Assert.AreEqual('Compiled Scripts', LOutline.Roots[2].Text);
  finally
    LOutline.Free;
  end;
end;

procedure TTestIdeProjectOutline.DovrebbeMettereOgniFileNelRamoDelSuoTipoInOrdine;
var
  LFileSystem: TFakeIdeFileSystem;
  LFileSystemIntf: IIdeFileSystem;
  LLog: IIdeLog;
  LClock: IIdeClock;
  LProject: TIdeProject;
  LOutline: TIdeOutline;
begin
  LFileSystem := TFakeIdeFileSystem.Create('C:\prj');
  LFileSystemIntf := LFileSystem;
  LLog := TFakeIdeLog.Create;
  LClock := TFakeIdeClock.Create;
  LFileSystem.AddFile('C:\prj\p.ddide',
    'version|1.0'#13#10'game|doom'#13#10'script|b.ddscript'#13#10'actor|x.txt'#13#10'script|a.ddscript'#13#10'compiledscript|c.ddout'#13#10);
  LProject := TIdeProject.Create(LFileSystemIntf, LLog, LClock, 'C:\prj\p.ddide');
  try
    LOutline := TIdeProjectOutline.Build(LProject);
    try
      Assert.AreEqual(1, LOutline.Roots[0].Children.Count);
      Assert.AreEqual('x.txt', LOutline.Roots[0].Children[0].Text);
      Assert.AreEqual('b.ddscript', LOutline.Roots[1].Children[0].Text);
      Assert.AreEqual('a.ddscript', LOutline.Roots[1].Children[1].Text);
      Assert.AreEqual('c.ddout', LOutline.Roots[2].Children[0].Text);
    finally
      LOutline.Free;
    end;
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProjectOutline.DovrebbeNonMostrareGliElementiDiAltriTipi;
var
  LFileSystem: TFakeIdeFileSystem;
  LFileSystemIntf: IIdeFileSystem;
  LLog: IIdeLog;
  LClock: IIdeClock;
  LProject: TIdeProject;
  LOutline: TIdeOutline;
begin
  LFileSystem := TFakeIdeFileSystem.Create('C:\prj');
  LFileSystemIntf := LFileSystem;
  LLog := TFakeIdeLog.Create;
  LClock := TFakeIdeClock.Create;
  LFileSystem.AddFile('C:\prj\p.ddide', 'version|1.0'#13#10'game|doom'#13#10'foo|x.bin'#13#10'project|n.ddide'#13#10);
  LProject := TIdeProject.Create(LFileSystemIntf, LLog, LClock, 'C:\prj\p.ddide');
  try
    Assert.AreEqual(2, LProject.Count);
    LOutline := TIdeProjectOutline.Build(LProject);
    try
      Assert.AreEqual(3, Length(LOutline.ToLines));
    finally
      LOutline.Free;
    end;
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProjectOutline.DovrebbeUsareIlPercorsoRelativoAlProgetto;
var
  LFileSystem: TFakeIdeFileSystem;
  LFileSystemIntf: IIdeFileSystem;
  LLog: IIdeLog;
  LClock: IIdeClock;
  LProject: TIdeProject;
  LOutline: TIdeOutline;
begin
  LFileSystem := TFakeIdeFileSystem.Create('C:\prj');
  LFileSystemIntf := LFileSystem;
  LLog := TFakeIdeLog.Create;
  LClock := TFakeIdeClock.Create;
  LFileSystem.AddFolder('C:\prj\sub');
  LFileSystem.AddFile('C:\prj\p.ddide', 'version|1.0'#13#10'game|doom'#13#10'script|sub\a.ddscript'#13#10);
  LProject := TIdeProject.Create(LFileSystemIntf, LLog, LClock, 'C:\prj\p.ddide');
  try
    LOutline := TIdeProjectOutline.Build(LProject);
    try
      Assert.AreEqual('sub\a.ddscript', LOutline.Roots[1].Children[0].Text);
    finally
      LOutline.Free;
    end;
  finally
    LProject.Free;
  end;
end;

procedure TTestIdeProjectOutline.DovrebbeDareSoloIRamiSeNonCeProgetto;
var
  LOutline: TIdeOutline;
begin
  LOutline := TIdeProjectOutline.Build(nil);
  try
    Assert.AreEqual(3, Length(LOutline.ToLines));
  finally
    LOutline.Free;
  end;
end;

{ TTestIdeEventSnippets }

procedure TTestIdeEventSnippets.DovrebbeSeparareNomeEDichiarazione;
var
  LEntries: TArray<TIdeEventEntry>;
begin
  LEntries := TIdeEventSnippets.Parse(TArray<string>.Create('ONTICK|event OnTick;|begin|end;', 'NODECL'));
  Assert.AreEqual(2, Length(LEntries));
  Assert.AreEqual('ONTICK', LEntries[0].Name);
  Assert.AreEqual('event OnTick;|begin|end;', LEntries[0].Declaration);
  Assert.AreEqual('NODECL', LEntries[1].Name);
  Assert.AreEqual('', LEntries[1].Declaration);
end;

procedure TTestIdeEventSnippets.DovrebbeScrivereLEventoDopoDueRigheVuote;
var
  LCaret: Integer;
begin
  Assert.AreEqual('uses all;'#13#10#13#10'event E;'#13#10'begin'#13#10'end;',
    TIdeEventSnippets.Append('event E;|begin|end;', 'uses all;', LCaret));
end;

procedure TTestIdeEventSnippets.DovrebbeMettereUsesAllInUnoScriptVuoto;
var
  LCaret: Integer;
begin
  Assert.AreEqual('uses'#13#10'  all;'#13#10#13#10#13#10'event E;',
    TIdeEventSnippets.Append('event E;', '', LCaret));
end;

procedure TTestIdeEventSnippets.DovrebbeMettereUsesAllAncheSeCiSonoSoloSpazi;
var
  LCaret: Integer;
  LText: string;
begin
  LText := TIdeEventSnippets.Append('event E;', '  '#13#10' ', LCaret);
  Assert.IsTrue(LText.StartsWith('  '#13#10' uses'));
end;

procedure TTestIdeEventSnippets.DovrebbePorreIlCursoreTreCaratteriPrimaDiEnd;
var
  LCaret: Integer;
  LText: string;
begin
  LText := TIdeEventSnippets.Append('event E;|begin|  |end;', 'x', LCaret);
  Assert.AreEqual(Pos('end;', LText) - 3, LCaret);
end;

procedure TTestIdeEventSnippets.DovrebbePorreIlCursoreAZeroSenzaEnd;
var
  LCaret: Integer;
begin
  TIdeEventSnippets.Append('event E;', 'x', LCaret);
  // no "end;": the caret goes to the end of the old text
  Assert.AreEqual(1, LCaret);
end;

procedure TTestIdeEventSnippets.DovrebbeContareDallaFineDelTestoEsistente;
var
  LCaret: Integer;
begin
  TIdeEventSnippets.Append('event E;|begin|end;', 'abcde', LCaret);
  Assert.AreEqual(5 + Pos('end;', #13#10#13#10'event E;'#13#10'begin'#13#10'end;') - 3, LCaret);
end;

end.
