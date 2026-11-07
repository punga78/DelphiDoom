{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - the defines of the game           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.GameDefines;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Scanner.Preprocessor.Intf;

type
  [TestFixture]
  [Category('scanner')]
  TTestScannerGameDefines = class(TObject)
  private
    FDefines: IScriptGameDefines;
    function Joined: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeEssereVuotoAllaCreazione;
    [Test]
    procedure DovrebbeScrivereINomiInMaiuscolo;
    [Test]
    procedure DovrebbeTenereLOrdineDiAggiunta;
    [Test]
    procedure DovrebbeIgnorareUnNomeGiaPresenteAncheInMinuscolo;
    [Test]
    procedure DovrebbeDimenticareTuttoConClear;
    [Test]
    procedure DovrebbeDareUnaCopiaCheNonCambiaDopo;
    [Test]
    procedure DovrebbeEssereUnaSorgenteDeiDefinePerIlPreprocessore;
    [Test]
    procedure DovrebbeEssereVistoDalPreprocessoreDopoLaCreazione;
  end;

implementation

uses
  DelphiDoom.Scanner.GameDefines,
  DelphiDoom.Scanner.TextPreprocessor;

type
  TEmptyIncludeSource = class(TInterfacedObject, IScriptIncludeSource)
  public
    function ReadFile(const AName: string): string;
    function ReadAllFiles(const AName: string): string;
    function ReadLump(const AName: string): string;
  end;

{ TEmptyIncludeSource }

function TEmptyIncludeSource.ReadAllFiles(const AName: string): string;
begin
  Result := '';
end;

function TEmptyIncludeSource.ReadFile(const AName: string): string;
begin
  Result := '';
end;

function TEmptyIncludeSource.ReadLump(const AName: string): string;
begin
  Result := '';
end;

{ TTestScannerGameDefines }

function TTestScannerGameDefines.Joined: string;
begin
  Result := string.Join(',', FDefines.Defines);
end;

procedure TTestScannerGameDefines.Setup;
begin
  FDefines := TScriptGameDefines.Create;
end;

procedure TTestScannerGameDefines.TearDown;
begin
  FDefines := nil;
end;

procedure TTestScannerGameDefines.DovrebbeEssereVuotoAllaCreazione;
begin
  Assert.AreEqual(0, Integer(Length(FDefines.Defines)));
end;

procedure TTestScannerGameDefines.DovrebbeScrivereINomiInMaiuscolo;
begin
  FDefines.Add('doom');
  FDefines.Add('OpenGL');
  Assert.AreEqual('DOOM,OPENGL', Joined);
end;

procedure TTestScannerGameDefines.DovrebbeTenereLOrdineDiAggiunta;
begin
  FDefines.Add('shareware');
  FDefines.Add('doom1');
  FDefines.Add('chex');
  Assert.AreEqual('SHAREWARE,DOOM1,CHEX', Joined);
end;

procedure TTestScannerGameDefines.DovrebbeIgnorareUnNomeGiaPresenteAncheInMinuscolo;
begin
  // D_FillGameDefines of Doom adds DOOM2 twice for a commercial game of the mission doom2
  FDefines.Add('doom2');
  FDefines.Add('commercial');
  FDefines.Add('DOOM2');
  Assert.AreEqual('DOOM2,COMMERCIAL', Joined);
end;

procedure TTestScannerGameDefines.DovrebbeDimenticareTuttoConClear;
begin
  FDefines.Add('heretic');
  FDefines.Clear;
  Assert.AreEqual('', Joined);
  FDefines.Add('hexen');
  Assert.AreEqual('HEXEN', Joined);
end;

procedure TTestScannerGameDefines.DovrebbeDareUnaCopiaCheNonCambiaDopo;
var
  LCopy: TArray<string>;
begin
  FDefines.Add('strife');
  LCopy := FDefines.Defines;
  FDefines.Add('registered');
  Assert.AreEqual(1, Integer(Length(LCopy)));
  Assert.AreEqual('STRIFE', LCopy[0]);
end;

procedure TTestScannerGameDefines.DovrebbeEssereUnaSorgenteDeiDefinePerIlPreprocessore;
var
  LSource: IScriptDefinesSource;
begin
  FDefines.Add('doom');
  Assert.IsTrue(Supports(FDefines, IScriptDefinesSource, LSource));
  Assert.AreEqual('DOOM', LSource.Defines[0]);
end;

procedure TTestScannerGameDefines.DovrebbeEssereVistoDalPreprocessoreDopoLaCreazione;
var
  LPreprocessor: IScriptTextPreprocessor;
  LText: string;
begin
  // the preprocessor is made by the composition root before the game knows its defines
  LPreprocessor := TScriptTextPreprocessor.Create(TEmptyIncludeSource.Create, nil, FDefines, nil);
  LText := '#IFDEF DOOM'#13#10'yes doom'#13#10'#ELSE'#13#10'no doom'#13#10'#ENDIF'#13#10;
  Assert.Contains(LPreprocessor.Preprocess(LText, False), 'no doom');
  FDefines.Add('doom');
  LText := LPreprocessor.Preprocess(LText, False);
  Assert.Contains(LText, 'yes doom');
  Assert.DoesNotContain(LText, 'no doom');
end;

end.
