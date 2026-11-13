{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - MD5 animations                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Md5Anim;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Models.Md5.Intf;

type
  /// <summary>The reader of md5anim and TMd5Anim with small animations written here</summary>
  [TestFixture]
  [Category('Md5')]
  TTestMd5Anim = class
  strict private
    FParser: IMd5AnimParser;
    function Parse(const AText: AnsiString): IMd5Anim;
    /// <summary>
    ///   Two joints, 3 frames at 10 per second. The root moves in x (bit 1, component 0) and the
    ///   child turns around z (bit 32, component 1); optional replacements adjust the text.
    /// </summary>
    function AnimText: AnsiString;
    procedure CheckError(const AText: AnsiString; const AFragment: string);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeCalcolareLaLunghezzaSenzaContareLUltimoFotogramma;
    [Test]
    procedure DovrebbeConvertireUnTempoACavalloDiDueFotogrammi;
    [Test]
    procedure DovrebbeConvertireUnTempoDopoUnGiro;
    [Test]
    procedure DovrebbeFermarsiAlUltimoFotogrammaDopoIGiriRichiesti;
    [Test]
    procedure DovrebbeUsareIlFotogrammoZeroPerUnTempoNonPositivo;
    [Test]
    procedure DovrebbeUsareUnSoloFotogrammaSeLAnimazioneNeHaUno;
    [Test]
    procedure DovrebbeDareLOrigineInterpolataDellaRadice;
    [Test]
    procedure DovrebbeAggiungereLoSpostamentoTotaleOgniGiro;
    [Test]
    procedure DovrebbeSottrarreLaBaseDallaTraslazioneDellaRadice;
    [Test]
    procedure DovrebbeUsareLaBaseSeLaRadiceNonHaTraslazioni;
    [Test]
    procedure DovrebbeInterpolareLaRotazioneDellaRadice;
    [Test]
    procedure DovrebbeUsareLaRotazioneDellaBaseSeLaRadiceNonRuota;
    [Test]
    procedure DovrebbeDareLeBoundsRelativeAllOrigine;
    [Test]
    procedure DovrebbeInterpolareUnGiuntoAMetaStrada;
    [Test]
    procedure DovrebbeLasciareLaBaseAIGiuntiFuoriDallIndice;
    [Test]
    procedure DovrebbeDareLaBaseSenzaComponentiAnimate;
    [Test]
    procedure DovrebbeDareUnFotogrammaSingolo;
    [Test]
    procedure DovrebbeRifiutareUnFotogrammaCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnIndiceDiGiuntoFuoriDallIntervallo;
    [Test]
    procedure DovrebbeLimitareIlNumeroDelFotogrammaDiGetFrameBlend;
    [Test]
    procedure DovrebbeDareUnaCopiaDellaBase;
    [Test]
    procedure DovrebbeRifiutareUnaVersioneDiversa;
    [Test]
    procedure DovrebbeRifiutareUnaFrequenzaZero;
    [Test]
    procedure DovrebbeRifiutareZeroFotogrammi;
    [Test]
    procedure DovrebbeRifiutareZeroGiunti;
    [Test]
    procedure DovrebbeRifiutareTroppeComponentiAnimate;
    [Test]
    procedure DovrebbeRifiutareUnGenitoreNonPrecedente;
    [Test]
    procedure DovrebbeRifiutareDueRadici;
    [Test]
    procedure DovrebbeRifiutareBitDiAnimazioneNonValidi;
    [Test]
    procedure DovrebbeRifiutareUnaPrimaComponenteFuoriDallIntervallo;
    [Test]
    procedure DovrebbeRifiutareComponentiCheSuperanoIlFotogramma;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiFotogrammaSbagliato;
    [Test]
    procedure DovrebbeRifiutareLaCreazioneConDatiIncoerenti;
  end;

implementation

uses
  DelphiDoom.Tests.Models.Md5Golden,
  System.StrUtils,
  DelphiDoom.IdLib.Core.Exceptions,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Quat,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Geometry.Vec3,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Md5.Types,
  DelphiDoom.Models.Md5.JointQuat,
  DelphiDoom.Models.Md5.Anim,
  DelphiDoom.Models.Md5.Factory;

const
  EPSILON = 1E-5;

{ TTestMd5Anim }

procedure TTestMd5Anim.Setup;
begin
  FParser := TMd5Factory.CreateAnimParser;
end;

function TTestMd5Anim.Parse(const AText: AnsiString): IMd5Anim;
begin
  Result := FParser.Parse(AText, 'test.md5anim');
end;

function TTestMd5Anim.AnimText: AnsiString;
begin
  // the root x of the base frame is 1: the frames hold 3, 5 and 9, so the animation moves by 2, 4 and 8
  Result :=
    'MD5Version 10'#10 +
    'commandline ""'#10 +
    'numFrames 3'#10 +
    'numJoints 2'#10 +
    'frameRate 10'#10 +
    'numAnimatedComponents 2'#10 +
    'hierarchy {'#10 +
    '  "root" -1 1 0'#10 +
    '  "arm" 0 32 1'#10 +
    '}'#10 +
    'bounds {'#10 +
    '  ( -1 -1 -1 ) ( 1 1 1 )'#10 +
    '  ( -2 -2 -2 ) ( 2 2 2 )'#10 +
    '  ( -4 -4 -4 ) ( 4 4 4 )'#10 +
    '}'#10 +
    'baseframe {'#10 +
    '  ( 1 0 0 ) ( 0 0 0 )'#10 +
    '  ( 0 5 0 ) ( 0 0 0 )'#10 +
    '}'#10 +
    'frame 0 {'#10 + '  3 0'#10 + '}'#10 +
    'frame 1 {'#10 + '  5 0.5'#10 + '}'#10 +
    'frame 2 {'#10 + '  9 0.0'#10 + '}'#10;
end;

procedure TTestMd5Anim.CheckError(const AText: AnsiString; const AFragment: string);
var
  LMessage: string;
begin
  LMessage := '';
  try
    Parse(AText);
  except
    on E: EIdLexerException do
      LMessage := E.Message;
  end;
  Assert.IsTrue((LMessage <> '') and ContainsText(LMessage, AFragment),
    'messaggio atteso con "' + AFragment + '", ottenuto "' + LMessage + '"');
end;

procedure TTestMd5Anim.DovrebbeCalcolareLaLunghezzaSenzaContareLUltimoFotogramma;
begin
  // ((3 - 1) * 1000 + 10 - 1) / 10
  Assert.AreEqual<Integer>(200, Parse(AnimText).Length);
  Assert.AreEqual<Integer>(3, Parse(AnimText).NumFrames);
  Assert.AreEqual<Integer>(2, Parse(AnimText).NumJoints);
  Assert.AreEqual<Integer>(10, Parse(AnimText).FrameRate);
  Assert.AreEqual('test.md5anim', string(Parse(AnimText).Name));
  Assert.AreEqual('arm', string(Parse(AnimText).JointInfo[1].Name));
  Assert.AreEqual<Integer>(32, Parse(AnimText).JointInfo[1].AnimBits);
end;

procedure TTestMd5Anim.DovrebbeConvertireUnTempoACavalloDiDueFotogrammi;
var
  LBlend: TMd5FrameBlend;
begin
  // 150 ms at 10 per second: 1.5 frames
  LBlend := Parse(AnimText).ConvertTimeToFrame(150, 0);
  Assert.AreEqual<Integer>(0, LBlend.CycleCount);
  Assert.AreEqual<Integer>(1, LBlend.Frame1);
  Assert.AreEqual<Integer>(2, LBlend.Frame2);
  CheckNear(0.5, LBlend.BackLerp, EPSILON);
  CheckNear(0.5, LBlend.FrontLerp, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeConvertireUnTempoDopoUnGiro;
var
  LBlend: TMd5FrameBlend;
begin
  // 250 ms: frame 2.5, that is one turn (2 frames) and 0.5: back to frame 0 and 1
  LBlend := Parse(AnimText).ConvertTimeToFrame(250, 0);
  Assert.AreEqual<Integer>(1, LBlend.CycleCount);
  Assert.AreEqual<Integer>(0, LBlend.Frame1);
  Assert.AreEqual<Integer>(1, LBlend.Frame2);
  CheckNear(0.5, LBlend.BackLerp, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeFermarsiAlUltimoFotogrammaDopoIGiriRichiesti;
var
  LBlend: TMd5FrameBlend;
begin
  LBlend := Parse(AnimText).ConvertTimeToFrame(250, 1);
  Assert.AreEqual<Integer>(0, LBlend.CycleCount);
  Assert.AreEqual<Integer>(2, LBlend.Frame1);
  Assert.AreEqual<Integer>(2, LBlend.Frame2);
  CheckNear(0, LBlend.BackLerp, EPSILON);
  CheckNear(1, LBlend.FrontLerp, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeUsareIlFotogrammoZeroPerUnTempoNonPositivo;
var
  LBlend: TMd5FrameBlend;
begin
  LBlend := Parse(AnimText).ConvertTimeToFrame(-10, 0);
  Assert.AreEqual<Integer>(0, LBlend.Frame1);
  Assert.AreEqual<Integer>(1, LBlend.Frame2);
  CheckNear(1, LBlend.FrontLerp, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeUsareUnSoloFotogrammaSeLAnimazioneNeHaUno;
var
  LAnim: IMd5Anim;
  LBlend: TMd5FrameBlend;
begin
  LAnim := Parse(
    'MD5Version 10'#10'commandline ""'#10'numFrames 1'#10'numJoints 1'#10'frameRate 24'#10 +
    'numAnimatedComponents 0'#10'hierarchy {'#10'  "root" -1 0 0'#10'}'#10 +
    'bounds {'#10'  ( 0 0 0 ) ( 1 1 1 )'#10'}'#10'baseframe {'#10'  ( 0 0 0 ) ( 0 0 0 )'#10'}'#10 +
    'frame 0 {'#10'}'#10);
  LBlend := LAnim.ConvertTimeToFrame(5000, 0);
  Assert.AreEqual<Integer>(0, LBlend.Frame1);
  Assert.AreEqual<Integer>(0, LBlend.Frame2);
  Assert.AreEqual<Integer>(0, LBlend.CycleCount);
  Assert.AreEqual<Integer>(0, LAnim.Length);
end;

procedure TTestMd5Anim.DovrebbeDareLOrigineInterpolataDellaRadice;
begin
  // the animation moves by 2 (frame 0), 4 and 8: at 150 ms the middle of 4 and 8
  CheckNear(6, Parse(AnimText).GetOrigin(150, 0).X, EPSILON);
  CheckNear(0, Parse(AnimText).GetOrigin(150, 0).Y, EPSILON);
  CheckNear(2, Parse(AnimText).GetOrigin(0, 0).X, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeAggiungereLoSpostamentoTotaleOgniGiro;
begin
  // the total delta is the movement of the last frame: 8; at 250 ms one turn is done: half of 2 and 4, plus 8
  CheckNear(8, Parse(AnimText).TotalMovementDelta.X, EPSILON);
  CheckNear(3 + 8, Parse(AnimText).GetOrigin(250, 0).X, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeSottrarreLaBaseDallaTraslazioneDellaRadice;
var
  LAnim: IMd5Anim;
  LBlend: TMd5FrameBlend;
  LJoints: TArray<TMd5JointQuat>;
begin
  LAnim := Parse(AnimText);
  LBlend := LAnim.GetFrameBlend(1);
  LJoints := LAnim.GetInterpolatedFrame(LBlend, nil);
  // the base frame of the root has no translation, the frame holds the movement from the base (3 - 1)
  CheckNear(2, LJoints[0].T.X, EPSILON);
  CheckNear(0, LAnim.BaseFrame[0].T.X, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeUsareLaBaseSeLaRadiceNonHaTraslazioni;
var
  LAnim: IMd5Anim;
begin
  LAnim := Parse(Replace8(AnimText, '"root" -1 1 0', '"root" -1 0 0'));
  CheckNear(0, LAnim.GetOrigin(150, 0).X, EPSILON);
  CheckNear(0, LAnim.TotalMovementDelta.X, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeInterpolareLaRotazioneDellaRadice;
var
  LAnim: IMd5Anim;
  LRotation: TIdQuat;
begin
  // the root turns around z (bit 32): the component 0 is z
  LAnim := Parse(Replace8(Replace8(Replace8(Replace8(Replace8(AnimText, '"root" -1 1 0', '"root" -1 32 0'),
    '"arm" 0 32 1', '"arm" 0 0 0'), '  5 0.5', '  0.5 0.5'), '  3 0', '  0.0 0'), '  9 0.0', '  0.0 0.0'));
  LRotation := LAnim.GetOriginRotation(150, 0);
  // frame 1 has z = 0.5 and frame 2 has z = 0: half way the rotation is between the two
  Assert.IsTrue((LRotation.Z > 0.1) and (LRotation.Z < 0.5));
  CheckNear(1, LRotation.Length, 1E-4);
end;

procedure TTestMd5Anim.DovrebbeUsareLaRotazioneDellaBaseSeLaRadiceNonRuota;
var
  LRotation: TIdQuat;
begin
  LRotation := Parse(AnimText).GetOriginRotation(150, 0);
  CheckNear(0, LRotation.X, EPSILON);
  CheckNear(1, LRotation.W, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeDareLeBoundsRelativeAllOrigine;
var
  LBounds: TGeoBounds;
begin
  // frames 1 and 2 merged (-4..4) minus the origin of the root at 150 ms (x = 6)
  LBounds := Parse(AnimText).GetBounds(150, 0);
  CheckNear(-4 - 6, LBounds.Mins.X, EPSILON);
  CheckNear(4 - 6, LBounds.Maxs.X, EPSILON);
  CheckNear(-4, LBounds.Mins.Y, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeInterpolareUnGiuntoAMetaStrada;
var
  LAnim: IMd5Anim;
  LJoints: TArray<TMd5JointQuat>;
begin
  LAnim := Parse(AnimText);
  // the arm (bit 32 = QZ, component 1): 0.5 at frame 1, 0 at frame 2; at 150 ms the middle
  LJoints := LAnim.GetInterpolatedFrame(LAnim.ConvertTimeToFrame(150, 0), nil);
  Assert.IsTrue(LJoints[1].Q.Z > 0.1);
  Assert.IsTrue(LJoints[1].Q.Z < 0.5);
  // unit quaternion: W is rebuilt
  CheckNear(1, LJoints[1].Q.Length, 1E-4);
  CheckNear(5, LJoints[1].T.Y, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeLasciareLaBaseAIGiuntiFuoriDallIndice;
var
  LAnim: IMd5Anim;
  LJoints: TArray<TMd5JointQuat>;
begin
  LAnim := Parse(AnimText);
  LJoints := LAnim.GetInterpolatedFrame(LAnim.ConvertTimeToFrame(150, 0), [0]);
  CheckNear(0, LJoints[1].Q.Z, EPSILON);
  CheckNear(1, LJoints[1].Q.W, EPSILON);
  LJoints := LAnim.GetSingleFrame(1, [0]);
  CheckNear(0, LJoints[1].Q.Z, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeDareLaBaseSenzaComponentiAnimate;
var
  LAnim: IMd5Anim;
  LJoints: TArray<TMd5JointQuat>;
begin
  LAnim := Parse(
    'MD5Version 10'#10'commandline ""'#10'numFrames 2'#10'numJoints 1'#10'frameRate 24'#10 +
    'numAnimatedComponents 0'#10'hierarchy {'#10'  "root" -1 0 0'#10'}'#10 +
    'bounds {'#10'  ( 0 0 0 ) ( 1 1 1 )'#10'  ( 0 0 0 ) ( 2 2 2 )'#10'}'#10 +
    'baseframe {'#10'  ( 7 8 9 ) ( 0 0 0 )'#10'}'#10 +
    'frame 0 {'#10'}'#10'frame 1 {'#10'}'#10);
  LJoints := LAnim.GetInterpolatedFrame(LAnim.ConvertTimeToFrame(20, 0), nil);
  CheckNear(0, LJoints[0].T.X, EPSILON, 'la traslazione della radice e'' zero');
  LJoints := LAnim.GetSingleFrame(1, nil);
  CheckNear(1, LJoints[0].Q.W, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeDareUnFotogrammaSingolo;
var
  LAnim: IMd5Anim;
  LJoints: TArray<TMd5JointQuat>;
begin
  LAnim := Parse(AnimText);
  LJoints := LAnim.GetSingleFrame(2, nil);
  CheckNear(8, LJoints[0].T.X, EPSILON);
  LJoints := LAnim.GetSingleFrame(0, nil);
  CheckNear(0, LJoints[0].T.X, EPSILON);
  CheckNear(4, LAnim.GetSingleFrame(1, nil)[0].T.X, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeRifiutareUnFotogrammaCheNonEsiste;
var
  LAnim: IMd5Anim;
begin
  LAnim := Parse(AnimText);
  Assert.WillRaise(
    procedure
    begin
      LAnim.GetSingleFrame(3, nil);
    end, EModelsException);
  Assert.WillRaise(
    procedure
    begin
      LAnim.FrameBounds[-1];
    end, EModelsException);
end;

procedure TTestMd5Anim.DovrebbeRifiutareUnIndiceDiGiuntoFuoriDallIntervallo;
var
  LAnim: IMd5Anim;
begin
  LAnim := Parse(AnimText);
  Assert.WillRaise(
    procedure
    begin
      LAnim.GetSingleFrame(1, [5]);
    end, EModelsException);
  Assert.WillRaise(
    procedure
    begin
      LAnim.GetInterpolatedFrame(LAnim.ConvertTimeToFrame(100, 0), [-1]);
    end, EModelsException);
end;

procedure TTestMd5Anim.DovrebbeLimitareIlNumeroDelFotogrammaDiGetFrameBlend;
var
  LAnim: IMd5Anim;
begin
  LAnim := Parse(AnimText);
  Assert.AreEqual<Integer>(0, LAnim.GetFrameBlend(-5).Frame1);
  Assert.AreEqual<Integer>(0, LAnim.GetFrameBlend(1).Frame1);
  Assert.AreEqual<Integer>(2, LAnim.GetFrameBlend(3).Frame2);
  Assert.AreEqual<Integer>(2, LAnim.GetFrameBlend(99).Frame1);
  CheckNear(0, LAnim.GetFrameBlend(2).BackLerp, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeDareUnaCopiaDellaBase;
var
  LAnim: IMd5Anim;
  LBase: TArray<TMd5JointQuat>;
begin
  LAnim := Parse(AnimText);
  LBase := LAnim.BaseFrame;
  LBase[1].T.Y := 99;
  CheckNear(5, LAnim.BaseFrame[1].T.Y, EPSILON);
end;

procedure TTestMd5Anim.DovrebbeRifiutareUnaVersioneDiversa;
begin
  CheckError(Replace8(AnimText, 'MD5Version 10', 'MD5Version 9'), 'Invalid version 9');
end;

procedure TTestMd5Anim.DovrebbeRifiutareUnaFrequenzaZero;
begin
  CheckError(Replace8(AnimText, 'frameRate 10', 'frameRate 0'), 'Invalid frame rate: 0');
end;

procedure TTestMd5Anim.DovrebbeRifiutareZeroFotogrammi;
begin
  CheckError(Replace8(AnimText, 'numFrames 3', 'numFrames 0'), 'Invalid number of frames: 0');
end;

procedure TTestMd5Anim.DovrebbeRifiutareZeroGiunti;
begin
  CheckError(Replace8(AnimText, 'numJoints 2', 'numJoints 0'), 'Invalid number of joints: 0');
end;

procedure TTestMd5Anim.DovrebbeRifiutareTroppeComponentiAnimate;
begin
  CheckError(Replace8(AnimText, 'numAnimatedComponents 2', 'numAnimatedComponents 13'), 'Invalid number of animated components: 13');
end;

procedure TTestMd5Anim.DovrebbeRifiutareUnGenitoreNonPrecedente;
begin
  CheckError(Replace8(AnimText, '"arm" 0 32 1', '"arm" 1 32 1'), 'Invalid parent num: 1');
end;

procedure TTestMd5Anim.DovrebbeRifiutareDueRadici;
begin
  CheckError(Replace8(AnimText, '"arm" 0 32 1', '"arm" -1 32 1'), 'only one root joint');
end;

procedure TTestMd5Anim.DovrebbeRifiutareBitDiAnimazioneNonValidi;
begin
  CheckError(Replace8(AnimText, '"arm" 0 32 1', '"arm" 0 64 1'), 'Invalid anim bits: 64');
end;

procedure TTestMd5Anim.DovrebbeRifiutareUnaPrimaComponenteFuoriDallIntervallo;
begin
  CheckError(Replace8(AnimText, '"arm" 0 32 1', '"arm" 0 32 2'), 'Invalid first component: 2');
end;

procedure TTestMd5Anim.DovrebbeRifiutareComponentiCheSuperanoIlFotogramma;
begin
  CheckError(Replace8(AnimText, '"arm" 0 32 1', '"arm" 0 56 1'), 'go beyond the 2 of a frame');
end;

procedure TTestMd5Anim.DovrebbeRifiutareUnNumeroDiFotogrammaSbagliato;
begin
  CheckError(Replace8(AnimText, 'frame 1 {', 'frame 2 {'), 'Expected frame number 1');
end;

procedure TTestMd5Anim.DovrebbeRifiutareLaCreazioneConDatiIncoerenti;
var
  LInfo: TArray<TMd5AnimJointInfo>;
  LBase: TArray<TMd5JointQuat>;
begin
  SetLength(LInfo, 1);
  LInfo[0].ParentNum := -1;
  SetLength(LBase, 1);
  Assert.WillRaise(
    procedure
    begin
      // a frame rate of zero would divide by zero in the length
      TMd5Anim.Create('x', 0, 0, LInfo, [TGeoBounds.Cleared], LBase, nil, TIdVec3.Create(0, 0, 0));
    end, EModelsException);
  Assert.WillRaise(
    procedure
    begin
      // the components do not make 2 frames of 1
      TMd5Anim.Create('x', 24, 1, LInfo, [TGeoBounds.Cleared, TGeoBounds.Cleared], LBase, [1.0], TIdVec3.Create(0, 0, 0));
    end, EModelsException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMd5Anim);

end.
