{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the articulatedFigure declaration                      }
{                                                                              }
{  The figure alone (fake base), through the real manager over files in        }
{  memory, and the small classes it is made of. The answers of the real C++    }
{  are in the golden test of this folder.                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.ArticulatedFigure;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Decl.Intf,
  DelphiDoom.Decl.ArticulatedFigure.Types, DelphiDoom.Decl.ArticulatedFigure.Intf,
  DelphiDoom.Tests.Decl.ArticulatedFigureSupport;

type
  [TestFixture]
  [Category('Decl')]
  TTestDeclArticulatedFigure = class
  strict private
    FKit: TArticulatedFigureKit;
    function Make(const ABody: AnsiString; const AName: AnsiString = 'fig'): IDeclArticulatedFigure;
    function WarningCount: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereLeImpostazioni;
    [Test]
    procedure DovrebbeUsareIValoriDiDefaultSeManca;
    [Test]
    procedure DovrebbeLeggereOgniFormaDiCorpo;
    [Test]
    procedure DovrebbeLeggereOgniTipoDiVincolo;
    [Test]
    procedure DovrebbeMettereIlCorpoDellOriginePerPrimo;
    [Test]
    procedure DovrebbeAggiungereIlClipMaskMobileAiCorpi;
    [Test]
    procedure DovrebbeDareFalsoPerUnCorpoSenzaGiunto;
    [Test]
    procedure DovrebbeRifiutareUnCorpoChiamatoWorld;
    [Test]
    procedure DovrebbeRifiutareUnaParolaSconosciuta;
    [Test]
    procedure DovrebbeTenereIlCorpoLettoFinoAlLErrore;
    [Test]
    procedure DovrebbeAvvisareDeiNomiDuplicatiEDeiCorpiMancanti;
    [Test]
    procedure DovrebbeIgnorareLeMaiuscoleDelleParole;
    [Test]
    procedure DovrebbeRisolvereIGiuntiConFinish;
    [Test]
    procedure DovrebbeAvvisareDiUnGiuntoChePreManca;
    [Test]
    procedure DovrebbeCambiareSegnoAdOgniFinish;
    [Test]
    procedure DovrebbeRifiutareFinishSenzaGiunti;
    [Test]
    procedure DovrebbeRiscrivereIlTestoComeLEditor;
    [Test]
    procedure DovrebbeRileggereIlTestoRiscritto;
    [Test]
    procedure DovrebbeNonScrivereUnVincoloSenzaTipo;
    [Test]
    procedure DovrebbeSostituireIlFileConSave;
    [Test]
    procedure DovrebbeRinominareEdEliminareCorpiEVincoli;
    [Test]
    procedure DovrebbeTenereModelloESkinDopoFreeData;
    [Test]
    procedure DovrebbeFarFallireUnIndiceFuoriIntervallo;
    [Test]
    procedure DovrebbeRifiutareUnVincoloSenzaTipoNelParser;
    [Test]
    procedure DovrebbeDareLeDimensioni;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestDeclArticulatedFigureManager = class
  public
    [Test]
    procedure DovrebbeLeggereLeFigureDalGestore;
    [Test]
    procedure DovrebbeUsareLaDefinizioneDiDefaultSeManca;
    [Test]
    procedure DovrebbeTenereLaFiguraLettaDopoUnErrore;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestAfContents = class
  public
    [TestCase('solo solid', 'solid,1')]
    [TestCase('due parole', 'solid body,257')]
    [TestCase('none cancella', 'solid none monsterclip,16')]
    [TestCase('maiuscole', 'SOLID Corpse,1025')]
    [TestCase('parola sconosciuta ferma la lettura', 'solid banana body,1')]
    [TestCase('vuoto', ',0')]
    procedure DovrebbeLeggereLeMaschere(const AText: string; const AExpected: Integer);
    [Test]
    procedure DovrebbeSaltareLeVirgole;
    [Test]
    procedure DovrebbeScrivereLeMaschere;
    [Test]
    procedure DovrebbeLeggereIModiDelGiunto;
    [Test]
    procedure DovrebbeScrivereIModiDelGiunto;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestAfVectors = class
  public
    [Test]
    procedure DovrebbeScrivereLeFormeDiUnVettore;
    [Test]
    procedure DovrebbeUsareLaPrecisioneDataPerLeCoordinate;
    [Test]
    procedure DovrebbeCrearePredefinitiDiCorpoEVincolo;
    [Test]
    procedure DovrebbeUsareWorldSeNonCiSonoCorpi;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.Angles,
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Material.Types, DelphiDoom.Decl.ArticulatedFigure,
  DelphiDoom.Decl.ArticulatedFigure.Contents, DelphiDoom.Decl.ArticulatedFigure.Writer,
  DelphiDoom.Decl.ArticulatedFigure.ConstraintParser, DelphiDoom.IdLib.Text.Lexer,
  DelphiDoom.Decl.StandardTypes, DelphiDoom.Decl.Base, DelphiDoom.Tests.Decl.Support;

const
  TWO_BODIES =
    '{'#10#9'settings { friction 0.2, 0.3, 0.4, 0.6 totalMass 80 model "m" skin "s" }'#10 +
    #9'body "top" { joint "j1" model cylinder( ( 0, 0, 0 ), ( 1, 1, 9 ), 12 ) density 2 }'#10 +
    #9'body "bottom" { joint "j2" origin joint( "j2" ) }'#10 +
    #9'hinge "h" { body1 "top" body2 "bottom" anchor ( 1, 2, 3 ) axis ( 0, 0, 1 ) limit 1, 2, 3 }'#10'}'#10;

{ TTestDeclArticulatedFigure }

procedure TTestDeclArticulatedFigure.Setup;
begin
  FKit := TArticulatedFigureKit.Create;
end;

procedure TTestDeclArticulatedFigure.TearDown;
begin
  FreeAndNil(FKit);
end;

function TTestDeclArticulatedFigure.Make(const ABody: AnsiString; const AName: AnsiString): IDeclArticulatedFigure;
begin
  Supports(FKit.Make(AName, ABody), IDeclArticulatedFigure, Result);
end;


function TTestDeclArticulatedFigure.WarningCount: Integer;
var
  LLine: string;
begin
  Result := 0;
  for LLine in FKit.Lines do
    if LLine.StartsWith('W:') then
      Inc(Result);
end;

procedure TTestDeclArticulatedFigure.DovrebbeLeggereLeImpostazioni;
var
  LFigure: IDeclArticulatedFigure;
  LSettings: TAfSettings;
begin
  LFigure := Make(TWO_BODIES);
  LSettings := LFigure.GetSettings;
  Assert.AreEqual(AnsiString('m'), LSettings.Model);
  Assert.AreEqual(AnsiString('s'), LSettings.Skin);
  Assert.AreEqual(Single(0.2), LSettings.DefaultLinearFriction);
  Assert.AreEqual(Single(0.6), LSettings.DefaultConstraintFriction);
  Assert.AreEqual(Single(80), LSettings.TotalMass);
  Assert.AreEqual(2, LFigure.GetNumBodies);
  Assert.AreEqual(1, LFigure.GetNumConstraints);
  Assert.AreEqual(0, WarningCount);
end;

procedure TTestDeclArticulatedFigure.DovrebbeUsareIValoriDiDefaultSeManca;
var
  LFigure: IDeclArticulatedFigure;
  LSettings: TAfSettings;
begin
  LFigure := Make('{ }');
  LSettings := LFigure.GetSettings;
  Assert.AreEqual(Single(0.01), LSettings.DefaultLinearFriction);
  Assert.AreEqual(Single(0.8), LSettings.DefaultContactFriction);
  Assert.AreEqual(Single(-1), LSettings.TotalMass);
  Assert.AreEqual(Single(20), LSettings.SuspendVelocity.X);
  Assert.AreEqual(Single(60), LSettings.SuspendAcceleration.Y);
  Assert.AreEqual(CONTENTS_CORPSE, LSettings.Contents);
  Assert.AreEqual(CONTENTS_SOLID or CONTENTS_CORPSE, LSettings.ClipMask);
  Assert.IsTrue(LSettings.SelfCollision);
  Assert.IsFalse(LSettings.Modified);
  Assert.AreEqual(0, LFigure.GetNumBodies);
end;

procedure TTestDeclArticulatedFigure.DovrebbeLeggereOgniFormaDiCorpo;
var
  LFigure: IDeclArticulatedFigure;
begin
  LFigure := Make('{ ' +
    'body "a" { joint "j" model box( ( 0, 0, 0 ), ( 1, 1, 1 ) ) } ' +
    'body "b" { joint "j" model octahedron( ( 0, 0, 0 ), ( 1, 1, 1 ) ) } ' +
    'body "c" { joint "j" model dodecahedron( ( 0, 0, 0 ), ( 1, 1, 1 ) ) } ' +
    'body "d" { joint "j" model cylinder( ( 0, 0, 0 ), ( 1, 1, 1 ), 7 ) } ' +
    'body "e" { joint "j" model cone( ( 0, 0, 0 ), ( 1, 1, 1 ), 5 ) } ' +
    'body "f" { joint "j" model bone( ( 0, 0, 0 ), ( 1, 1, 1 ), 2.5 ) } }');
  Assert.AreEqual(Ord(abmBox), Ord(LFigure.GetBody(0).ModelType));
  Assert.AreEqual(Ord(abmOctahedron), Ord(LFigure.GetBody(1).ModelType));
  Assert.AreEqual(Ord(abmDodecahedron), Ord(LFigure.GetBody(2).ModelType));
  Assert.AreEqual(Ord(abmCylinder), Ord(LFigure.GetBody(3).ModelType));
  Assert.AreEqual(7, LFigure.GetBody(3).NumSides);
  Assert.AreEqual(Ord(abmCone), Ord(LFigure.GetBody(4).ModelType));
  Assert.AreEqual(5, LFigure.GetBody(4).NumSides);
  Assert.AreEqual(Ord(abmBone), Ord(LFigure.GetBody(5).ModelType));
  Assert.AreEqual(Single(2.5), LFigure.GetBody(5).Width);
end;

procedure TTestDeclArticulatedFigure.DovrebbeLeggereOgniTipoDiVincolo;
var
  LFigure: IDeclArticulatedFigure;
begin
  LFigure := Make('{ body "a" { joint "j" } ' +
    'fixed "1" { } ballAndSocketJoint "2" { } universalJoint "3" { } hinge "4" { } slider "5" { } spring "6" { } }');
  Assert.AreEqual(6, LFigure.GetNumConstraints);
  Assert.AreEqual(Ord(actFixed), Ord(LFigure.GetConstraint(0).ConstraintType));
  Assert.AreEqual(Ord(actBallAndSocketJoint), Ord(LFigure.GetConstraint(1).ConstraintType));
  Assert.AreEqual(Ord(actUniversalJoint), Ord(LFigure.GetConstraint(2).ConstraintType));
  Assert.AreEqual(Ord(actHinge), Ord(LFigure.GetConstraint(3).ConstraintType));
  Assert.AreEqual(Ord(actSlider), Ord(LFigure.GetConstraint(4).ConstraintType));
  Assert.AreEqual(Ord(actSpring), Ord(LFigure.GetConstraint(5).ConstraintType));
  // the bodies of a constraint start as the first body and the world
  Assert.AreEqual(AnsiString('a'), LFigure.GetConstraint(3).Body1);
  Assert.AreEqual(AnsiString('world'), LFigure.GetConstraint(3).Body2);
end;

procedure TTestDeclArticulatedFigure.DovrebbeMettereIlCorpoDellOriginePerPrimo;
var
  LFigure: IDeclArticulatedFigure;
begin
  LFigure := Make('{ body "a" { joint "x" } body "b" { joint "y" } body "c" { joint "origin" } }');
  Assert.AreEqual(AnsiString('c'), LFigure.GetBody(0).Name);
  Assert.AreEqual(AnsiString('b'), LFigure.GetBody(1).Name);
  Assert.AreEqual(AnsiString('a'), LFigure.GetBody(2).Name);
end;

procedure TTestDeclArticulatedFigure.DovrebbeAggiungereIlClipMaskMobileAiCorpi;
var
  LFigure: IDeclArticulatedFigure;
begin
  LFigure := Make('{ body "a" { joint "x" clipMask solid } }');
  Assert.AreEqual(CONTENTS_SOLID or CONTENTS_MOVEABLECLIP, LFigure.GetBody(0).ClipMask);
end;

procedure TTestDeclArticulatedFigure.DovrebbeDareFalsoPerUnCorpoSenzaGiunto;
var
  LDecl: IDecl;
  LParsed: Boolean;
begin
  LDecl := FKit.Make('fig', '{ body "a" { density 3 } }', LParsed);
  Assert.IsFalse(LParsed);
  Assert.IsTrue(FKit.Lines.Text.Contains('W: file test.decl, line 2: no joint set for body'));
end;

procedure TTestDeclArticulatedFigure.DovrebbeRifiutareUnCorpoChiamatoWorld;
var
  LDecl: IDecl;
  LParsed: Boolean;
begin
  LDecl := FKit.Make('fig', '{ body "World" { joint "x" } }', LParsed);
  Assert.IsFalse(LParsed);
  Assert.IsTrue(FKit.Lines.Text.Contains('a body may not be named "origin" or "world"'));
  LDecl := FKit.Make('fig2', '{ body "ORIGIN" { joint "x" } }', LParsed);
  Assert.IsFalse(LParsed);
end;

procedure TTestDeclArticulatedFigure.DovrebbeRifiutareUnaParolaSconosciuta;
var
  LDecl: IDecl;
  LParsed: Boolean;
begin
  LDecl := FKit.Make('fig', '{ frobnicate }', LParsed);
  Assert.IsFalse(LParsed);
  Assert.IsTrue(FKit.Lines.Text.Contains('unknown keyword frobnicate'));
  LDecl := FKit.Make('fig2', '{ body "b" { joint "x" model custom( 1 ) } }', LParsed);
  Assert.IsFalse(LParsed);
  Assert.IsTrue(FKit.Lines.Text.Contains('custom models not yet implemented'));
  LDecl := FKit.Make('fig3', '{ body "b" { joint "x" model ball( 1 ) } }', LParsed);
  Assert.IsFalse(LParsed);
  Assert.IsTrue(FKit.Lines.Text.Contains('unkown model type ball'));
  LDecl := FKit.Make('fig4', '{ body "b" { joint "x" origin banana( 1 ) } }', LParsed);
  Assert.IsFalse(LParsed);
  Assert.IsTrue(FKit.Lines.Text.Contains('unknown token banana in vector'));
end;

procedure TTestDeclArticulatedFigure.DovrebbeTenereIlCorpoLettoFinoAlLErrore;
var
  LDecl: IDecl;
  LFigure: IDeclArticulatedFigure;
  LParsed: Boolean;
begin
  LDecl := FKit.Make('fig', '{ body "ok" { joint "j" } body "bad" { joint "j" density 4 wobble 1 } body "never" { joint "k" } }',
    LParsed);
  Supports(LDecl, IDeclArticulatedFigure, LFigure);
  Assert.IsFalse(LParsed);
  // the body that failed is in the list with what was read, the one after is not read
  Assert.AreEqual(2, LFigure.GetNumBodies);
  Assert.AreEqual(AnsiString('bad'), LFigure.GetBody(1).Name);
  Assert.AreEqual(Single(4), LFigure.GetBody(1).Density);
end;

procedure TTestDeclArticulatedFigure.DovrebbeAvvisareDeiNomiDuplicatiEDeiCorpiMancanti;
var
  LDecl: IDecl;
  LParsed: Boolean;
begin
  LDecl := FKit.Make('fig', '{ body "a" { joint "j" } body "a" { joint "k" } ' +
    'hinge "h" { body1 "a" } hinge "h" { body1 "" body2 "" } }', LParsed);
  Assert.IsTrue(LParsed);
  Assert.IsTrue(FKit.Lines.Text.Contains('two bodies with the same name "a"'));
  Assert.IsTrue(FKit.Lines.Text.Contains('two constraints with the same name "h"'));
  Assert.IsTrue(FKit.Lines.Text.Contains('no valid body1 specified for constraint ''h'''));
  Assert.IsTrue(FKit.Lines.Text.Contains('no valid body2 specified for constraint ''h'''));
  Assert.AreEqual(4, WarningCount);
end;

procedure TTestDeclArticulatedFigure.DovrebbeIgnorareLeMaiuscoleDelleParole;
var
  LFigure: IDeclArticulatedFigure;
begin
  LFigure := Make('{ SETTINGS { TotalMass 5 CONTENTS Body } BODY "a" { JOINT "j" MODEL BOX( ( 1, 1, 1 ), ( 2, 2, 2 ) ) } ' +
    'HINGE "h" { BODY1 "a" BODY2 "world" } }');
  Assert.AreEqual(Single(5), LFigure.GetSettings.TotalMass);
  Assert.AreEqual(CONTENTS_BODY, LFigure.GetSettings.Contents);
  Assert.AreEqual(Ord(abmBox), Ord(LFigure.GetBody(0).ModelType));
  Assert.AreEqual(1, LFigure.GetNumConstraints);
end;

procedure TTestDeclArticulatedFigure.DovrebbeRisolvereIGiuntiConFinish;
var
  LFigure: IDeclArticulatedFigure;
  LResolver: TFakeJointResolver;
  LResolverIntf: IAfJointResolver;
begin
  LFigure := Make('{ body "a" { joint "j" origin bonecenter( "p", "q" ) model box( joint( "p" ), bonedir( "p", "q" ) ) } ' +
    'hinge "h" { body1 "a" body2 "world" anchor -joint( "q" ) } }');
  LResolver := TFakeJointResolver.Create;
  LResolverIntf := LResolver;
  LResolver.Add('p', 1, 2, 3);
  LResolver.Add('q', 3, 6, 9);
  LFigure.Finish(LResolverIntf);
  Assert.AreEqual(Single(2), LFigure.GetBody(0).Origin.Vec.X);
  Assert.AreEqual(Single(4), LFigure.GetBody(0).Origin.Vec.Y);
  Assert.AreEqual(Single(6), LFigure.GetBody(0).Origin.Vec.Z);
  Assert.AreEqual(Single(1), LFigure.GetBody(0).V1.Vec.X);
  Assert.AreEqual(Single(4), LFigure.GetBody(0).V2.Vec.Y);
  Assert.AreEqual(Single(-3), LFigure.GetConstraint(0).Anchor.Vec.X);
  Assert.AreEqual(Single(-9), LFigure.GetConstraint(0).Anchor.Vec.Z);
  Assert.AreEqual(0, WarningCount);
end;

procedure TTestDeclArticulatedFigure.DovrebbeAvvisareDiUnGiuntoChePreManca;
var
  LFigure: IDeclArticulatedFigure;
  LResolver: TFakeJointResolver;
  LResolverIntf: IAfJointResolver;
begin
  LFigure := Make('{ body "a" { joint "j" origin bonecenter( "p", "gone" ) } }');
  LResolver := TFakeJointResolver.Create;
  LResolverIntf := LResolver;
  LResolver.Add('p', 2, 2, 2);
  LFigure.Finish(LResolverIntf);
  // the missing end counts as the origin of the model
  Assert.AreEqual(Single(1), LFigure.GetBody(0).Origin.Vec.X);
  Assert.IsTrue(FKit.Lines.Text.Contains('W: invalid joint gone in bonecenter() in ''fig'''));
end;

procedure TTestDeclArticulatedFigure.DovrebbeCambiareSegnoAdOgniFinish;
var
  LFigure: IDeclArticulatedFigure;
  LResolverIntf: IAfJointResolver;
begin
  LFigure := Make('{ body "a" { joint "j" origin -( 1, 2, 3 ) } }');
  LResolverIntf := TFakeJointResolver.Create;
  LFigure.Finish(LResolverIntf);
  Assert.AreEqual(Single(-1), LFigure.GetBody(0).Origin.Vec.X);
  // a second finish flips the coordinates again, as the original does
  LFigure.Finish(LResolverIntf);
  Assert.AreEqual(Single(1), LFigure.GetBody(0).Origin.Vec.X);
end;

procedure TTestDeclArticulatedFigure.DovrebbeRifiutareFinishSenzaGiunti;
var
  LFigure: IDeclArticulatedFigure;
begin
  LFigure := Make('{ }');
  Assert.WillRaise(procedure begin LFigure.Finish(nil); end, EDeclArticulatedFigureException);
end;

procedure TTestDeclArticulatedFigure.DovrebbeRiscrivereIlTestoComeLEditor;
var
  LDecl: IDecl;
  LEditor: IDeclArticulatedFigureEditor;
  LText: string;
begin
  LDecl := FKit.Make('fig', TWO_BODIES);
  Supports(LDecl, IDeclArticulatedFigureEditor, LEditor);
  LText := string(LEditor.RebuildTextSource);
  Assert.IsTrue(LText.Contains('Generated by the Articulated Figure Editor'));
  Assert.IsTrue(LText.Contains('articulatedFigure fig {'#10));
  Assert.IsTrue(LText.Contains(#9'model "m"'#10));
  Assert.IsTrue(LText.Contains(#9'friction 0.2000000030, 0.3000000119') or LText.Contains(#9'friction 0.200000003, 0.3000000119'));
  Assert.IsTrue(LText.Contains('body "top" {'#10#9'joint "j1"'#10#9'mod orientation'#10));
  Assert.IsTrue(LText.Contains(#9'model cylinder( ( 0, 0, 0 ), ( 1, 1, 9 ), 12 )'#10));
  Assert.IsTrue(LText.Contains('hinge "h" {'#10#9'body1 "top"'#10));
  Assert.IsTrue(LText.Contains(#9'limit 1, 2, 3'#10));
  Assert.IsTrue(LText.EndsWith(#10'}'));
  Assert.AreEqual(LText, string(LDecl.GetText));
end;

procedure TTestDeclArticulatedFigure.DovrebbeRileggereIlTestoRiscritto;
var
  LDecl: IDecl;
  LEditor: IDeclArticulatedFigureEditor;
  LAgain: IDeclArticulatedFigure;
begin
  LDecl := FKit.Make('fig', TWO_BODIES);
  Supports(LDecl, IDeclArticulatedFigureEditor, LEditor);
  Supports(FKit.Make('again', AnsiString(Copy(string(LEditor.RebuildTextSource),
    Pos('{', string(LEditor.RebuildTextSource)), MaxInt))), IDeclArticulatedFigure, LAgain);
  Assert.AreEqual(2, LAgain.GetNumBodies);
  Assert.AreEqual(AnsiString('top'), LAgain.GetBody(0).Name);
  Assert.AreEqual(12, LAgain.GetBody(0).NumSides);
  Assert.AreEqual(Single(2), LAgain.GetBody(0).Density);
  Assert.AreEqual(Single(80), LAgain.GetSettings.TotalMass);
  Assert.AreEqual(Single(3), LAgain.GetConstraint(0).LimitAngles[2]);
  Assert.AreEqual(AF_LIMIT_CONE, LAgain.GetConstraint(0).Limit);
end;

procedure TTestDeclArticulatedFigure.DovrebbeNonScrivereUnVincoloSenzaTipo;
var
  LDecl: IDecl;
  LFigure: IDeclArticulatedFigure;
  LEditor: IDeclArticulatedFigureEditor;
  LConstraint: TAfConstraint;
begin
  LDecl := FKit.Make('fig', '{ body "a" { joint "j" } hinge "h" { } }');
  Supports(LDecl, IDeclArticulatedFigure, LFigure);
  Supports(LDecl, IDeclArticulatedFigureEditor, LEditor);
  LConstraint := LFigure.GetConstraint(0);
  LConstraint.ConstraintType := actInvalid;
  LFigure.SetConstraint(0, LConstraint);
  LDecl.SetText('before');
  Assert.AreEqual(AnsiString(''), LEditor.RebuildTextSource);
  // the text of the declaration is left as it was
  Assert.AreEqual(AnsiString('before'), LDecl.GetText);
end;

procedure TTestDeclArticulatedFigure.DovrebbeSostituireIlFileConSave;
var
  LDecl: IDecl;
  LFigure: IDeclArticulatedFigure;
  LEditor: IDeclArticulatedFigureEditor;
  LSettings: TAfSettings;
begin
  LDecl := FKit.Make('fig', TWO_BODIES);
  Supports(LDecl, IDeclArticulatedFigure, LFigure);
  Supports(LDecl, IDeclArticulatedFigureEditor, LEditor);
  LSettings := LFigure.GetSettings;
  LSettings.Modified := True;
  LFigure.SetSettings(LSettings);
  Assert.IsFalse(FKit.BaseOf('fig').Replaced);
  Assert.IsTrue(LEditor.Save);
  Assert.IsTrue(FKit.BaseOf('fig').Replaced);
  Assert.IsFalse(LFigure.GetSettings.Modified);
  Assert.IsTrue(string(LDecl.GetText).Contains('articulatedFigure fig {'));
end;

procedure TTestDeclArticulatedFigure.DovrebbeRinominareEdEliminareCorpiEVincoli;
var
  LDecl: IDecl;
  LFigure: IDeclArticulatedFigure;
  LEditor: IDeclArticulatedFigureEditor;
begin
  LDecl := FKit.Make('fig', TWO_BODIES);
  Supports(LDecl, IDeclArticulatedFigure, LFigure);
  Supports(LDecl, IDeclArticulatedFigureEditor, LEditor);
  LEditor.NewBody('extra');
  Assert.AreEqual(3, LFigure.GetNumBodies);
  Assert.AreEqual(AnsiString('extra'), LFigure.GetBody(2).Name);
  Assert.AreEqual(AnsiString('origin'), LFigure.GetBody(2).JointName);
  LEditor.NewConstraint('spare');
  Assert.AreEqual(AnsiString('top'), LFigure.GetConstraint(1).Body1);
  LEditor.RenameBody('TOP', 'upper');
  Assert.AreEqual(AnsiString('upper'), LFigure.GetBody(0).Name);
  Assert.AreEqual(AnsiString('upper'), LFigure.GetConstraint(0).Body1);
  Assert.AreEqual(AnsiString('upper'), LFigure.GetConstraint(1).Body1);
  LEditor.RenameConstraint('H', 'hinge');
  Assert.AreEqual(AnsiString('hinge'), LFigure.GetConstraint(0).Name);
  LEditor.RenameConstraint('missing', 'x');
  LEditor.DeleteConstraint('spare');
  Assert.AreEqual(1, LFigure.GetNumConstraints);
  LEditor.DeleteConstraint('missing');
  Assert.AreEqual(1, LFigure.GetNumConstraints);
  // a body takes with it the constraints that use it
  LEditor.DeleteBody('bottom');
  Assert.AreEqual(2, LFigure.GetNumBodies);
  Assert.AreEqual(0, LFigure.GetNumConstraints);
  LEditor.DeleteBody('missing');
  Assert.AreEqual(2, LFigure.GetNumBodies);
end;

procedure TTestDeclArticulatedFigure.DovrebbeTenereModelloESkinDopoFreeData;
var
  LDecl: IDecl;
  LFigure: IDeclArticulatedFigure;
begin
  LDecl := FKit.Make('fig', TWO_BODIES);
  Supports(LDecl, IDeclArticulatedFigure, LFigure);
  TDeclArticulatedFigure(LDecl as TObject).FreeData;
  Assert.AreEqual(AnsiString('m'), LFigure.GetSettings.Model);
  Assert.AreEqual(AnsiString('s'), LFigure.GetSettings.Skin);
  Assert.AreEqual(Single(-1), LFigure.GetSettings.TotalMass);
  Assert.AreEqual(0, LFigure.GetNumBodies);
  Assert.AreEqual(0, LFigure.GetNumConstraints);
end;

procedure TTestDeclArticulatedFigure.DovrebbeFarFallireUnIndiceFuoriIntervallo;
var
  LFigure: IDeclArticulatedFigure;
begin
  LFigure := Make(TWO_BODIES);
  Assert.WillRaise(procedure var LIgnored: TAfBody; begin LIgnored := LFigure.GetBody(2); end,
    EDeclArticulatedFigureException);
  Assert.WillRaise(procedure var LIgnored: TAfBody; begin LIgnored := LFigure.GetBody(-1); end,
    EDeclArticulatedFigureException);
  Assert.WillRaise(procedure var LIgnored: TAfConstraint; begin LIgnored := LFigure.GetConstraint(1); end,
    EDeclArticulatedFigureException);
  Assert.WillRaise(procedure begin LFigure.SetBody(5, LFigure.GetBody(0)); end, EDeclArticulatedFigureException);
  Assert.WillRaise(procedure begin LFigure.SetConstraint(-1, LFigure.GetConstraint(0)); end,
    EDeclArticulatedFigureException);
end;

procedure TTestDeclArticulatedFigure.DovrebbeRifiutareUnVincoloSenzaTipoNelParser;
var
  LSource: TIdLexer;
  LConstraint: TAfConstraint;
  LSettings: TAfSettings;
begin
  LSettings.ResetNumbers;
  LConstraint.SetDefault(LSettings, nil);
  LSource := TIdLexer.Create;
  try
    LSource.LoadMemory('"x" { }', 7, 'test');
    Assert.WillRaise(procedure begin TAfConstraintParser.Parse(LSource, LConstraint, actInvalid); end,
      EDeclArticulatedFigureException);
  finally
    LSource.Free;
  end;
end;

procedure TTestDeclArticulatedFigure.DovrebbeDareLeDimensioni;
var
  LDecl: IDecl;
begin
  LDecl := FKit.Make('fig', '{ }');
  Assert.IsTrue(TDeclArticulatedFigure(LDecl as TObject).Size > 0);
end;

{ TTestDeclArticulatedFigureManager }

procedure TTestDeclArticulatedFigureManager.DovrebbeLeggereLeFigureDalGestore;
var
  LKit: TDeclKit;
  LFigure: IDeclArticulatedFigure;
begin
  LKit := TDeclKit.Create;
  try
    LKit.Source.Add('af/test.af', 'articulatedFigure zombie'#10 + TWO_BODIES);
    LKit.Start(True, True);
    LKit.Manager.GetRegistry.RegisterDeclFolder('af', '.af', DECL_AF);
    Assert.IsTrue(Supports(LKit.Manager.FindType(DECL_AF, 'zombie'), IDeclArticulatedFigure, LFigure));
    Assert.AreEqual(2, LFigure.GetNumBodies);
    Assert.AreEqual(AnsiString('top'), LFigure.GetBody(0).Name);
  finally
    LKit.Free;
  end;
end;

procedure TTestDeclArticulatedFigureManager.DovrebbeUsareLaDefinizioneDiDefaultSeManca;
var
  LKit: TDeclKit;
  LFigure: IDeclArticulatedFigure;
begin
  LKit := TDeclKit.Create;
  try
    LKit.Start(True, False);
    Assert.IsTrue(Supports(LKit.Manager.FindType(DECL_AF, 'nobody'), IDeclArticulatedFigure, LFigure));
    Assert.AreEqual(1, LFigure.GetNumBodies);
    Assert.AreEqual(AnsiString('body'), LFigure.GetBody(0).Name);
    Assert.AreEqual(AnsiString('origin'), LFigure.GetBody(0).JointName);
    Assert.AreEqual(Single(0.2), LFigure.GetBody(0).Density);
    Assert.AreEqual(CONTENTS_SOLID or CONTENTS_CORPSE or CONTENTS_MOVEABLECLIP, LFigure.GetBody(0).ClipMask);
  finally
    LKit.Free;
  end;
end;

procedure TTestDeclArticulatedFigureManager.DovrebbeTenereLaFiguraLettaDopoUnErrore;
var
  LKit: TDeclKit;
  LFigure: IDeclArticulatedFigure;
begin
  LKit := TDeclKit.Create;
  try
    LKit.Source.Add('af/bad.af', 'articulatedFigure broken { body "x" { density 3 } }'#10);
    LKit.Start(True, True);
    LKit.Manager.GetRegistry.RegisterDeclFolder('af', '.af', DECL_AF);
    Assert.IsTrue(Supports(LKit.Manager.FindType(DECL_AF, 'broken'), IDeclArticulatedFigure, LFigure));
    // no joint: the original does not make the figure default, the body read stays
    Assert.AreEqual(1, LFigure.GetNumBodies);
    Assert.AreEqual(AnsiString('x'), LFigure.GetBody(0).Name);
    Assert.AreEqual(Single(3), LFigure.GetBody(0).Density);
  finally
    LKit.Free;
  end;
end;

{ TTestAfContents }

procedure TTestAfContents.DovrebbeLeggereLeMaschere(const AText: string; const AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TAfContents.ContentsFromString(AnsiString(AText)));
end;

procedure TTestAfContents.DovrebbeSaltareLeVirgole;
begin
  Assert.AreEqual(CONTENTS_SOLID or CONTENTS_CORPSE, TAfContents.ContentsFromString('solid, corpse'));
  Assert.AreEqual(CONTENTS_BODY or CONTENTS_PLAYERCLIP, TAfContents.ContentsFromString(', body,, playerclip'));
end;

procedure TTestAfContents.DovrebbeScrivereLeMaschere;
begin
  Assert.AreEqual('none', string(TAfContents.ContentsToString(0)));
  Assert.AreEqual('solid', string(TAfContents.ContentsToString(CONTENTS_SOLID)));
  Assert.AreEqual('solid, body, corpse, playerclip, monsterclip',
    string(TAfContents.ContentsToString(-1)));
  // the bits that have no name are not written
  Assert.AreEqual('none', string(TAfContents.ContentsToString(CONTENTS_MOVEABLECLIP)));
end;

procedure TTestAfContents.DovrebbeLeggereIModiDelGiunto;
begin
  Assert.AreEqual(Ord(ajmAxis), Ord(TAfContents.JointModFromString('orientation')));
  Assert.AreEqual(Ord(ajmOrigin), Ord(TAfContents.JointModFromString('POSITION')));
  Assert.AreEqual(Ord(ajmBoth), Ord(TAfContents.JointModFromString('Both')));
  Assert.AreEqual(Ord(ajmAxis), Ord(TAfContents.JointModFromString('unknown')));
end;

procedure TTestAfContents.DovrebbeScrivereIModiDelGiunto;
begin
  Assert.AreEqual('orientation', string(TAfContents.JointModToString(ajmAxis)));
  Assert.AreEqual('position', string(TAfContents.JointModToString(ajmOrigin)));
  Assert.AreEqual('both', string(TAfContents.JointModToString(ajmBoth)));
end;

{ TTestAfVectors }

procedure TTestAfVectors.DovrebbeScrivereLeFormeDiUnVettore;
var
  LVector: TAfVector;
begin
  LVector := TAfVector.FromCoords(1, 2, 3);
  Assert.AreEqual('( 1.000, 2.000, 3.000 )', string(TAfWriter.VectorToString(LVector, 3)));
  LVector.Negate := True;
  Assert.AreEqual('-( 1.000, 2.000, 3.000 )', string(TAfWriter.VectorToString(LVector, 3)));
  LVector := TAfVector.Create;
  LVector.Kind := avkJoint;
  LVector.Joint1 := 'a';
  Assert.AreEqual('joint( "a" )', string(TAfWriter.VectorToString(LVector)));
  LVector.Kind := avkBoneCenter;
  LVector.Joint2 := 'b';
  Assert.AreEqual('bonecenter( "a", "b" )', string(TAfWriter.VectorToString(LVector)));
  LVector.Kind := avkBoneDir;
  Assert.AreEqual('bonedir( "a", "b" )', string(TAfWriter.VectorToString(LVector)));
end;

procedure TTestAfVectors.DovrebbeUsareLaPrecisioneDataPerLeCoordinate;
var
  LVector: TAfVector;
begin
  LVector := TAfVector.FromCoords(0.5, 2, 4);
  Assert.AreEqual('( 0.50000000, 2.00000000, 4.00000000 )', string(TAfWriter.VectorToString(LVector)));
  Assert.AreEqual('( 0.5, 2.0, 4.0 )', string(TAfWriter.VectorToString(LVector, 1)));
end;

procedure TTestAfVectors.DovrebbeCrearePredefinitiDiCorpoEVincolo;
var
  LSettings: TAfSettings;
  LBody: TAfBody;
  LConstraint: TAfConstraint;
begin
  LSettings.ResetNumbers;
  LBody.SetDefault(LSettings);
  Assert.AreEqual(AnsiString('noname'), LBody.Name);
  Assert.AreEqual(Ord(abmBox), Ord(LBody.ModelType));
  Assert.AreEqual(Single(-10), LBody.V1.Vec.X);
  Assert.AreEqual(Single(10), LBody.V2.Vec.Z);
  Assert.AreEqual(3, LBody.NumSides);
  Assert.AreEqual(Single(0.2), LBody.Density);
  Assert.AreEqual(AnsiString('*origin'), LBody.ContainedJoints);
  Assert.IsTrue(LBody.InertiaScale = TIdMat3.Identity);
  Assert.AreEqual(Single(0), LBody.Width);
  LConstraint.SetDefault(LSettings, TArray<TAfBody>.Create(LBody));
  Assert.AreEqual(AnsiString('noname'), LConstraint.Name);
  Assert.AreEqual(Ord(actUniversalJoint), Ord(LConstraint.ConstraintType));
  Assert.AreEqual(AnsiString('noname'), LConstraint.Body1);
  Assert.AreEqual(Single(1), LConstraint.Axis.Vec.X);
  Assert.AreEqual(Single(-1), LConstraint.Shaft[0].Vec.Z);
  Assert.AreEqual(Single(1), LConstraint.Shaft[1].Vec.Z);
  Assert.AreEqual(AF_LIMIT_NONE, LConstraint.Limit);
  Assert.AreEqual(Single(-1), LConstraint.LimitAxis.Vec.Z);
  Assert.AreEqual(Single(0), LConstraint.MaxLength);
end;

procedure TTestAfVectors.DovrebbeUsareWorldSeNonCiSonoCorpi;
var
  LSettings: TAfSettings;
  LConstraint: TAfConstraint;
begin
  LSettings.ResetNumbers;
  LConstraint.SetDefault(LSettings, nil);
  Assert.AreEqual(AnsiString('world'), LConstraint.Body1);
  Assert.AreEqual(AnsiString('world'), LConstraint.Body2);
  Assert.AreEqual(Single(0.5), LConstraint.Friction);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclArticulatedFigure);
  TDUnitX.RegisterTestFixture(TTestDeclArticulatedFigureManager);
  TDUnitX.RegisterTestFixture(TTestAfContents);
  TDUnitX.RegisterTestFixture(TTestAfVectors);

end.
