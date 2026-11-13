{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TFlicScene (issue #199)                                }
{                                                                              }
{  Three frames of 100 ms (a FLC with speed 100): the animation is 300 ms      }
{  long. The pixel of a frame says which one it is.                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.FlicScene;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Cinematic.Flic.Scene.Types,
  DelphiDoom.Cinematic.Flic.Scene.Intf;

type
  /// <summary>An audio that counts what the scene tells it</summary>
  TCountingSceneAudio = class(TInterfacedObject, IFlicSceneAudio)
  public
    Started: Integer;
    Finished: Integer;
    FinishedSkipped: Boolean;
    procedure SceneStarted;
    procedure SceneFinished(ASkipped: Boolean);
  end;

  [TestFixture]
  [Category('cinematic')]
  TTestFlicScene = class(TObject)
  strict private
    FAudioObject: TCountingSceneAudio;
    FAudio: IFlicSceneAudio;
    function Scene(AOptions: TFlicSceneOptions; AWithAudio: Boolean = True): IFlicScene;
    function Options(ALooping, ASkippable: Boolean): TFlicSceneOptions;
  public
    [Test]
    procedure DovrebbeEssereInAttesaFinoAlPrimoAggiornamento;
    [Test]
    procedure DovrebbeIniziareELaVoceAlPrimoAggiornamento;
    [Test]
    procedure DovrebbeSegnareIlCambioDiFotogramma;
    [Test]
    procedure DovrebbeFinireDopoLUltimoFotogrammaSenzaCiclo;
    [Test]
    procedure DovrebbeDireAllaVoceCheLaScenaEFinitaDaSola;
    [Test]
    procedure DovrebbeTenerelUltimaImmagineDopoLaFine;
    [Test]
    procedure DovrebbeDireLaFineUnaSolaVolta;
    [Test]
    procedure DovrebbeSaltareSuRichiesta;
    [Test]
    procedure DovrebbeDireAllaVoceCheLaScenaESaltata;
    [Test]
    procedure DovrebbeTenerelUltimaImmagineMostrataDopoIlSalto;
    [Test]
    procedure DovrebbeIgnorareLaRichiestaDiSaltoSeLaScenaNonESaltabile;
    [Test]
    procedure DovrebbeSaltareAncheAlPrimoAggiornamento;
    [Test]
    procedure DovrebbeRestareInCicloFinoAlSalto;
    [Test]
    procedure DovrebbeLavorareSenzaVoce;
    [Test]
    procedure DovrebbeRifiutareUnPlayerNullo;
    [Test]
    procedure DovrebbeDareIlNomeDellaScena;
  end;

implementation

uses
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.Flic.Intf,
  DelphiDoom.Cinematic.Flic.Factory,
  DelphiDoom.Cinematic.Flic.Scene,
  DelphiDoom.Tests.Cinematic.FlicSupport;

{ TCountingSceneAudio }

procedure TCountingSceneAudio.SceneStarted;
begin
  Inc(Started);
end;

procedure TCountingSceneAudio.SceneFinished(ASkipped: Boolean);
begin
  Inc(Finished);
  FinishedSkipped := ASkipped;
end;

{ TTestFlicScene }

function TTestFlicScene.Options(ALooping, ASkippable: Boolean): TFlicSceneOptions;
begin
  Result.Looping := ALooping;
  Result.Skippable := ASkippable;
end;

function TTestFlicScene.Scene(AOptions: TFlicSceneOptions; AWithAudio: Boolean): IFlicScene;
var
  LBuilder: TFlicTestBuilder;
  LPlayer: IFlicPlayer;
begin
  LBuilder := TFlicTestBuilder.Create(4, 2, False, 100);
  try
    LBuilder.Frame([TFlicTestBuilder.Color256(0, [0, 0, 0, 1, 0, 0, 2, 0, 0, 3, 0, 0]),
      TFlicTestBuilder.ByteRun(4, [1, 1])]);
    LBuilder.Frame([TFlicTestBuilder.ByteRun(4, [2, 2])]);
    LBuilder.Frame([TFlicTestBuilder.ByteRun(4, [3, 3])]);
    LPlayer := TFlicFactory.CreatePlayer(TFlicFactory.CreateDecoder(LBuilder.ToBytes), AOptions.Looping);
  finally
    LBuilder.Free;
  end;
  FAudioObject := TCountingSceneAudio.Create;
  FAudio := FAudioObject;
  if AWithAudio then
    Result := TFlicScene.Create('TEST', LPlayer, AOptions, FAudio)
  else
    Result := TFlicScene.Create('TEST', LPlayer, AOptions, nil);
end;

procedure TTestFlicScene.DovrebbeEssereInAttesaFinoAlPrimoAggiornamento;
var
  LScene: IFlicScene;
begin
  LScene := Scene(Options(False, True));
  Assert.AreEqual<Integer>(Ord(fssPending), Ord(LScene.State));
  Assert.AreEqual<Integer>(0, FAudioObject.Started);
end;

procedure TTestFlicScene.DovrebbeIniziareELaVoceAlPrimoAggiornamento;
var
  LScene: IFlicScene;
  LFrame: TFlicSceneFrame;
begin
  LScene := Scene(Options(False, True));
  LFrame := LScene.Update(5000, False);
  Assert.AreEqual<Integer>(Ord(fssPlaying), Ord(LFrame.State));
  Assert.AreEqual<Integer>(Ord(fssPlaying), Ord(LScene.State));
  Assert.AreEqual<Integer>(1, FAudioObject.Started);
  LScene.Update(5010, False);
  Assert.AreEqual<Integer>(1, FAudioObject.Started, 'Only once');
  Assert.AreEqual<Integer>(0, FAudioObject.Finished);
end;

procedure TTestFlicScene.DovrebbeSegnareIlCambioDiFotogramma;
var
  LScene: IFlicScene;
begin
  LScene := Scene(Options(False, True));
  Assert.IsTrue(LScene.Update(0, False).FrameChanged, 'The first frame is new');
  Assert.IsFalse(LScene.Update(50, False).FrameChanged, 'Still the first frame');
  Assert.IsTrue(LScene.Update(100, False).FrameChanged, 'The second frame');
  Assert.IsFalse(LScene.Update(150, False).FrameChanged);
end;

procedure TTestFlicScene.DovrebbeFinireDopoLUltimoFotogrammaSenzaCiclo;
var
  LScene: IFlicScene;
begin
  LScene := Scene(Options(False, True));
  // the first time is the start
  Assert.AreEqual<Integer>(Ord(fssPlaying), Ord(LScene.Update(0, False).State));
  Assert.AreEqual<Integer>(Ord(fssPlaying), Ord(LScene.Update(299, False).State));
  Assert.AreEqual<Integer>(Ord(fssEnded), Ord(LScene.Update(300, False).State));
  Assert.AreEqual<Integer>(Ord(fssEnded), Ord(LScene.State));
end;

procedure TTestFlicScene.DovrebbeDireAllaVoceCheLaScenaEFinitaDaSola;
var
  LScene: IFlicScene;
begin
  LScene := Scene(Options(False, True));
  LScene.Update(0, False);
  LScene.Update(400, False);
  Assert.AreEqual<Integer>(1, FAudioObject.Finished);
  Assert.IsFalse(FAudioObject.FinishedSkipped);
end;

procedure TTestFlicScene.DovrebbeTenerelUltimaImmagineDopoLaFine;
var
  LScene: IFlicScene;
  LFrame: TFlicSceneFrame;
begin
  LScene := Scene(Options(False, True));
  LScene.Update(0, False);
  LScene.Update(400, False);
  LFrame := LScene.Update(1000, False);
  Assert.AreEqual<Integer>(Ord(fssEnded), Ord(LFrame.State));
  Assert.AreEqual<Integer>(2, LFrame.Image.FrameIndex);
  Assert.AreEqual<Integer>(4, LFrame.Image.Width);
  Assert.IsFalse(LFrame.FrameChanged);
end;

procedure TTestFlicScene.DovrebbeDireLaFineUnaSolaVolta;
var
  LScene: IFlicScene;
begin
  LScene := Scene(Options(False, True));
  LScene.Update(0, False);
  LScene.Update(400, False);
  LScene.Update(500, False);
  LScene.Update(600, True);
  Assert.AreEqual<Integer>(1, FAudioObject.Finished);
  Assert.AreEqual<Integer>(Ord(fssEnded), Ord(LScene.State), 'A skip after the end changes nothing');
end;

procedure TTestFlicScene.DovrebbeSaltareSuRichiesta;
var
  LScene: IFlicScene;
  LFrame: TFlicSceneFrame;
begin
  LScene := Scene(Options(False, True));
  LScene.Update(0, False);
  LFrame := LScene.Update(50, True);
  Assert.AreEqual<Integer>(Ord(fssSkipped), Ord(LFrame.State));
  Assert.AreEqual<Integer>(Ord(fssSkipped), Ord(LScene.State));
  Assert.AreEqual<Integer>(Ord(fssSkipped), Ord(LScene.Update(60, False).State));
end;

procedure TTestFlicScene.DovrebbeDireAllaVoceCheLaScenaESaltata;
var
  LScene: IFlicScene;
begin
  LScene := Scene(Options(False, True));
  LScene.Update(0, False);
  LScene.Update(50, True);
  Assert.AreEqual<Integer>(1, FAudioObject.Finished);
  Assert.IsTrue(FAudioObject.FinishedSkipped);
end;

procedure TTestFlicScene.DovrebbeTenerelUltimaImmagineMostrataDopoIlSalto;
var
  LScene: IFlicScene;
  LFrame: TFlicSceneFrame;
begin
  LScene := Scene(Options(False, True));
  LScene.Update(0, False);
  LScene.Update(150, False);
  LFrame := LScene.Update(160, True);
  Assert.AreEqual<Integer>(1, LFrame.Image.FrameIndex);
  Assert.IsFalse(LFrame.FrameChanged);
end;

procedure TTestFlicScene.DovrebbeIgnorareLaRichiestaDiSaltoSeLaScenaNonESaltabile;
var
  LScene: IFlicScene;
begin
  LScene := Scene(Options(False, False));
  LScene.Update(0, False);
  Assert.AreEqual<Integer>(Ord(fssPlaying), Ord(LScene.Update(50, True).State));
  Assert.AreEqual<Integer>(0, FAudioObject.Finished);
end;

procedure TTestFlicScene.DovrebbeSaltareAncheAlPrimoAggiornamento;
var
  LFrame: TFlicSceneFrame;
  LScene: IFlicScene;
begin
  LScene := Scene(Options(False, True));
  LFrame := LScene.Update(0, True);
  Assert.AreEqual<Integer>(Ord(fssSkipped), Ord(LFrame.State));
  Assert.AreEqual<Integer>(0, LFrame.Image.Width, 'Nothing was shown');
  // the voice starts and stops, so the audio always gets the pair
  Assert.AreEqual<Integer>(1, FAudioObject.Started);
  Assert.AreEqual<Integer>(1, FAudioObject.Finished);
end;

procedure TTestFlicScene.DovrebbeRestareInCicloFinoAlSalto;
var
  LScene: IFlicScene;
  LTime: Integer;
begin
  LScene := Scene(Options(True, True));
  for LTime := 0 to 100 do
    Assert.AreEqual<Integer>(Ord(fssPlaying), Ord(LScene.Update(LTime * 100, False).State));
  Assert.AreEqual<Integer>(Ord(fssSkipped), Ord(LScene.Update(10100, True).State));
end;

procedure TTestFlicScene.DovrebbeLavorareSenzaVoce;
var
  LScene: IFlicScene;
begin
  LScene := Scene(Options(False, True), False);
  Assert.AreEqual<Integer>(Ord(fssPlaying), Ord(LScene.Update(0, False).State));
  Assert.AreEqual<Integer>(Ord(fssSkipped), Ord(LScene.Update(10, True).State));
end;

procedure TTestFlicScene.DovrebbeRifiutareUnPlayerNullo;
begin
  Assert.WillRaise(
    procedure
    begin
      TFlicScene.Create('X', nil, TFlicSceneOptions.Default, nil);
    end, ECinematicException);
end;

procedure TTestFlicScene.DovrebbeDareIlNomeDellaScena;
begin
  Assert.AreEqual('TEST', Scene(Options(False, True)).Name);
end;

end.
