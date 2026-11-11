{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the cutscenes of the xcom menu library             }
{  (CutsceneState, SlideshowState, VideoState) with a fake catalog and files    }
{  built in memory                                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.Cutscenes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Xcom.FlcDecoder,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Music.Intf,
  DelphiDoom.XcomMod.RuleVideo, DelphiDoom.XcomMenu.CutsceneCatalog.Intf, DelphiDoom.XcomMenu.CutsceneState,
  DelphiDoom.XcomMenu.SlideshowState, DelphiDoom.XcomMenu.VideoState, DelphiDoom.Tests.XcomEngine.World,
  DelphiDoom.Tests.XcomEngine.AudioFakes, DelphiDoom.Tests.XcomEngine.FlcBuilder;

type
  /// <summary>The cutscenes and the files of a mod kept in memory (the paths without distinction of case)</summary>
  TFakeCutsceneCatalog = class(TInterfacedObject, IXcomCutsceneCatalog)
  strict private
    FRules: TObjectDictionary<string, TXcomRuleVideo>;
    FFiles: TDictionary<string, TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>A cutscene from the YAML of its rule</summary>
    procedure AddRule(const AId, AYaml: string);
    procedure AddFile(const APath: string; const ABytes: TBytes);
    function FindCutscene(const AId: string): TXcomRuleVideo;
    function FileExists(const AVirtualPath: string): Boolean;
    function LoadBytes(const AVirtualPath: string): TBytes;
  end;

  [TestFixture]
  [Category('XcomCutscenes')]
  TTestXcomCutscenes = class
  strict private
    FWorld: TTestWorld;
    FCatalog: TFakeCutsceneCatalog;
    FCatalogRef: IXcomCutsceneCatalog;
    FMusic: TFakeMusicPlayer;
    FMusicRef: IXcomMusicPlayer;
    FBase: TXcomState;
    procedure Key(AKey: Integer);
    procedure AddSlides;
    /// <summary>A video of 4 x 3 pixels with three frames filled with 1, 2 and 3; the first sets the color 1</summary>
    function ThreeFrames(AType: Word; ASpeed: Integer): TBytes;
    function Slideshow: TXcomSlideshowState;
    function Video: TXcomVideoState;
    function PictureFill: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeTogliersiSeLaCutsceneNonEsiste;
    [Test]
    procedure DovrebbeTogliersiSeLaDefinizioneEVuota;
    [Test]
    procedure DovrebbeAprireLeDiapositiveSeIlFilmatoNonCe;
    [Test]
    procedure DovrebbeAprireIlFilmatoSeEsiste;
    [Test]
    procedure DovrebbePreferireLeDiapositiveSeLeOpzioniLoChiedono;
    [Test]
    procedure DovrebbeChiamareLaFineDelGiocoSoloPerVittoriaESconfitta;
    [Test]
    procedure DovrebbeMostrareLaPrimaDiapositivaConLaSuaPaletteESenzaCursore;
    [Test]
    procedure DovrebbePassareAllaDiapositivaDopoColClicEChiudereDopoLUltima;
    [Test]
    procedure DovrebbePassareAllaDiapositivaDopoQuandoScadeIlTempo;
    [Test]
    procedure DovrebbeChiudereLeDiapositiveConIlTastoAnnulla;
    [Test]
    procedure DovrebbeAvviareLaMusicaDelleDiapositive;
    [Test]
    procedure DovrebbeMostrareIFotogrammiDelFilmatoAlLoroTempo;
    [Test]
    procedure DovrebbeDareAlloSchermoLaPaletteDelFilmato;
    [Test]
    procedure DovrebbeSfumareEChiudereAllaFineDelFilmato;
    [Test]
    procedure DovrebbeSaltareIlFilmatoConUnTastoSenzaSfumare;
    [Test]
    procedure DovrebbeSaltareIlFilmatoConUnClic;
    [Test]
    procedure DovrebbeSaltareIFilmatiCheMancano;
    [Test]
    procedure DovrebbeSuonareLaSequenzaAudioDiUfoERimettereIVolumi;
    [Test]
    procedure DovrebbeLasciarPerdereLaSequenzaAudioSenzaISuoni;
    [Test]
    procedure DovrebbeAvviareLaTracciaAudioDelFilmato;
  end;

implementation

uses
  DelphiDoom.XcomSurface.Surface;

const
  SLIDES_RULE =
    'slideshow:'#10 +
    '  musicId: GMSLIDE'#10 +
    '  transitionSeconds: 30'#10 +
    '  slides:'#10 +
    '    - imagePath: PICS/ONE.LBM'#10 +
    '      transitionSeconds: 2'#10 +
    '      caption: STR_ONE'#10 +
    '      captionSize: [320, 10]'#10 +
    '      captionPos: [0, 190]'#10 +
    '      captionColor: 5'#10 +
    '      captionAlign: 1'#10 +
    '    - imagePath: PICS/TWO.LBM'#10 +
    '      caption: STR_TWO'#10;
  VIDEO_RULE =
    'videos:'#10 +
    '  - ANIMS/A.FLC'#10;
  XCOM_KEY_RETURN_CODE = 13;
  XCOM_KEY_ESCAPE_CODE = 27;
  VIDEO_ROW = 98;

{ TFakeCutsceneCatalog }

constructor TFakeCutsceneCatalog.Create;
begin
  inherited Create;
  FRules := TObjectDictionary<string, TXcomRuleVideo>.Create([doOwnsValues]);
  FFiles := TDictionary<string, TBytes>.Create;
end;

destructor TFakeCutsceneCatalog.Destroy;
begin
  FFiles.Free;
  FRules.Free;
  inherited Destroy;
end;

procedure TFakeCutsceneCatalog.AddRule(const AId, AYaml: string);
var
  LRule: TXcomRuleVideo;
begin
  LRule := TXcomRuleVideo.Create(AId);
  FRules.AddOrSetValue(AId, LRule);
  LRule.Load(TTestWorld.Parse(AYaml));
end;

procedure TFakeCutsceneCatalog.AddFile(const APath: string; const ABytes: TBytes);
begin
  FFiles.AddOrSetValue(APath.ToUpperInvariant, ABytes);
end;

function TFakeCutsceneCatalog.FindCutscene(const AId: string): TXcomRuleVideo;
begin
  if not FRules.TryGetValue(AId, Result) then
    Result := nil;
end;

function TFakeCutsceneCatalog.FileExists(const AVirtualPath: string): Boolean;
begin
  Result := FFiles.ContainsKey(AVirtualPath.ToUpperInvariant);
end;

function TFakeCutsceneCatalog.LoadBytes(const AVirtualPath: string): TBytes;
begin
  Result := FFiles[AVirtualPath.ToUpperInvariant];
end;

{ TTestXcomCutscenes }

procedure TTestXcomCutscenes.Setup;
begin
  FWorld := TTestWorld.Create;
  FCatalog := TFakeCutsceneCatalog.Create;
  FCatalogRef := FCatalog;
  FMusic := TFakeMusicPlayer.Create;
  FMusicRef := FMusic;
  FWorld.Game.SetMusicPlayer(FMusicRef);
  FBase := TXcomState.Create(FWorld.Game);
  FWorld.Game.SetState(FBase);
  FWorld.Wait(20);
end;

procedure TTestXcomCutscenes.TearDown;
begin
  FWorld.Free;
  FCatalogRef := nil;
  FMusicRef := nil;
end;

procedure TTestXcomCutscenes.Key(AKey: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := AKey;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(5);
  LEvent.Kind := ekKeyUp;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(5);
end;

procedure TTestXcomCutscenes.AddSlides;
begin
  FCatalog.AddFile('PICS/ONE.LBM', TLbmBuilder.Solid(320, 200, 7, 10, 20, 30));
  FCatalog.AddFile('PICS/TWO.LBM', TLbmBuilder.Solid(320, 200, 8, 40, 50, 60));
end;

function TTestXcomCutscenes.ThreeFrames(AType: Word; ASpeed: Integer): TBytes;
var
  LBuilder: TFlcBuilder;
begin
  LBuilder := TFlcBuilder.Create(AType, 4, 3, 3, ASpeed);
  try
    LBuilder.BeginFrame;
    LBuilder.Chunk(FLC_COLOR_256, [1, 0, 1, 1, 200, 100, 50]);
    LBuilder.Chunk(FLC_COPY, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]);
    LBuilder.EndFrame;
    LBuilder.CopyFrame([2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);
    LBuilder.CopyFrame([3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3]);
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

function TTestXcomCutscenes.Slideshow: TXcomSlideshowState;
begin
  Assert.IsTrue(FWorld.Game.TopState is TXcomSlideshowState, 'in cima ci sono le diapositive');
  Result := TXcomSlideshowState(FWorld.Game.TopState);
end;

function TTestXcomCutscenes.Video: TXcomVideoState;
begin
  Assert.IsTrue(FWorld.Game.TopState is TXcomVideoState, 'in cima c''e'' il filmato');
  Result := TXcomVideoState(FWorld.Game.TopState);
end;

function TTestXcomCutscenes.PictureFill: Integer;
begin
  Result := Video.Picture.GetPixel(0, VIDEO_ROW);
end;

procedure TTestXcomCutscenes.DovrebbeTogliersiSeLaCutsceneNonEsiste;
begin
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(20);
  Assert.AreSame(FBase, FWorld.Game.TopState);
end;

procedure TTestXcomCutscenes.DovrebbeTogliersiSeLaDefinizioneEVuota;
begin
  // the rule is there but none of its files
  FCatalog.AddRule('intro', VIDEO_RULE + SLIDES_RULE);
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(20);
  Assert.AreSame(FBase, FWorld.Game.TopState);
end;

procedure TTestXcomCutscenes.DovrebbeAprireLeDiapositiveSeIlFilmatoNonCe;
begin
  FCatalog.AddRule('intro', VIDEO_RULE + SLIDES_RULE);
  AddSlides;
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(20);
  Assert.AreEqual(0, Slideshow.CurrentScreen);
end;

procedure TTestXcomCutscenes.DovrebbeAprireIlFilmatoSeEsiste;
begin
  FCatalog.AddRule('intro', VIDEO_RULE + SLIDES_RULE);
  AddSlides;
  FCatalog.AddFile('ANIMS/A.FLC', ThreeFrames(XCOM_FLC_TYPE_FLC, 40));
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(20);
  Assert.AreEqual(Ord(vpPlay), Ord(Video.Phase));
end;

procedure TTestXcomCutscenes.DovrebbePreferireLeDiapositiveSeLeOpzioniLoChiedono;
begin
  FCatalog.AddRule('intro', VIDEO_RULE + SLIDES_RULE);
  AddSlides;
  FCatalog.AddFile('ANIMS/A.FLC', ThreeFrames(XCOM_FLC_TYPE_FLC, 40));
  FWorld.Game.Options.PreferredVideo := XCOM_VIDEO_SLIDE;
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(20);
  Assert.AreEqual(0, Slideshow.CurrentScreen);
end;

procedure TTestXcomCutscenes.DovrebbeChiamareLaFineDelGiocoSoloPerVittoriaESconfitta;
var
  LCalls: Integer;
  LEnd: TProc;
begin
  LCalls := 0;
  LEnd :=
    procedure
    begin
      Inc(LCalls);
    end;
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, XCOM_CUTSCENE_INTRO, FCatalogRef, LEnd));
  FWorld.Wait(20);
  Assert.AreEqual(0, LCalls, 'l''introduzione non finisce il gioco');
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, XCOM_CUTSCENE_LOSE_GAME, FCatalogRef, LEnd));
  FWorld.Wait(20);
  Assert.AreEqual(1, LCalls);
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, XCOM_CUTSCENE_WIN_GAME, FCatalogRef, LEnd));
  FWorld.Wait(20);
  Assert.AreEqual(2, LCalls);
  Assert.AreSame(FBase, FWorld.Game.TopState);
end;

procedure TTestXcomCutscenes.DovrebbeMostrareLaPrimaDiapositivaConLaSuaPaletteESenzaCursore;
var
  LShow: TXcomSlideshowState;
begin
  FCatalog.AddRule('intro', SLIDES_RULE);
  AddSlides;
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(40);
  LShow := Slideshow;
  Assert.IsTrue(LShow.Slide(0).Visible);
  Assert.IsFalse(LShow.Slide(1).Visible);
  Assert.IsTrue(LShow.Caption(0).Visible);
  Assert.AreEqual('STR_ONE', LShow.Caption(0).GetText);
  Assert.AreEqual(190, LShow.Caption(0).Y);
  Assert.AreEqual(5, Integer(LShow.Caption(0).GetColor));
  Assert.AreEqual(320, LShow.Caption(1).Width, 'una didascalia senza misure e'' grande quanto lo schermo');
  Assert.AreEqual(200, LShow.Caption(1).Height);
  Assert.IsFalse(FWorld.Game.Cursor.Visible);
  Assert.AreEqual(7, Integer(FWorld.Game.Screen.GetSurface.GetPixel(100, 100)));
  Assert.AreEqual(10, Integer(FWorld.Game.Screen.Palette^[7].Red));
  Assert.AreEqual(30, Integer(FWorld.Game.Screen.Palette^[7].Blue));
end;

procedure TTestXcomCutscenes.DovrebbePassareAllaDiapositivaDopoColClicEChiudereDopoLUltima;
begin
  FCatalog.AddRule('intro', SLIDES_RULE);
  AddSlides;
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(40);
  FWorld.Click(100, 100);
  Assert.AreEqual(1, Slideshow.CurrentScreen);
  Assert.IsFalse(Slideshow.Slide(0).Visible);
  Assert.IsTrue(Slideshow.Slide(1).Visible);
  Assert.AreEqual(40, Integer(FWorld.Game.Screen.Palette^[8].Red), 'la palette e'' quella della seconda');
  Key(XCOM_KEY_RETURN_CODE);
  FWorld.Wait(20);
  Assert.AreSame(FBase, FWorld.Game.TopState);
  Assert.IsTrue(FWorld.Game.Cursor.Visible);
end;

procedure TTestXcomCutscenes.DovrebbePassareAllaDiapositivaDopoQuandoScadeIlTempo;
begin
  FCatalog.AddRule('intro', SLIDES_RULE);
  AddSlides;
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(1900);
  Assert.AreEqual(0, Slideshow.CurrentScreen);
  FWorld.Wait(200);
  Assert.AreEqual(1, Slideshow.CurrentScreen, 'la prima dura due secondi');
  FWorld.Wait(5000);
  Assert.AreEqual(1, Slideshow.CurrentScreen, 'la seconda i trenta dell''intestazione');
end;

procedure TTestXcomCutscenes.DovrebbeChiudereLeDiapositiveConIlTastoAnnulla;
begin
  FCatalog.AddRule('intro', SLIDES_RULE);
  AddSlides;
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(40);
  Key(XCOM_KEY_ESCAPE_CODE);
  FWorld.Wait(20);
  Assert.AreSame(FBase, FWorld.Game.TopState);
  Assert.IsTrue(FWorld.Game.Cursor.Visible);
end;

procedure TTestXcomCutscenes.DovrebbeAvviareLaMusicaDelleDiapositive;
begin
  FCatalog.AddRule('intro', SLIDES_RULE);
  AddSlides;
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(40);
  Assert.IsTrue(FMusic.Names.IndexOf('GMSLIDE:0') >= 0);
end;

procedure TTestXcomCutscenes.DovrebbeMostrareIFotogrammiDelFilmatoAlLoroTempo;
begin
  FCatalog.AddRule('intro', VIDEO_RULE);
  FCatalog.AddFile('ANIMS/A.FLC', ThreeFrames(XCOM_FLC_TYPE_FLC, 40));
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(10);
  Assert.AreEqual(1, PictureFill, 'il primo fotogramma non aspetta');
  Assert.AreEqual(0, Integer(Video.Picture.GetPixel(0, VIDEO_ROW - 1)), 'il filmato e'' centrato in altezza');
  Assert.AreEqual(0, Integer(Video.Picture.GetPixel(4, VIDEO_ROW)));
  FWorld.Wait(20);
  Assert.AreEqual(1, Integer(FWorld.Game.Screen.GetSurface.GetPixel(3, VIDEO_ROW + 2)),
    'il quadro arriva sullo schermo');
  Assert.AreEqual(0, Integer(FWorld.Game.Screen.GetSurface.GetPixel(4, VIDEO_ROW + 2)));
  FWorld.Wait(5);
  Assert.AreEqual(1, PictureFill, 'il secondo arriva dopo 40 ms');
  FWorld.Wait(20);
  Assert.AreEqual(2, PictureFill);
  FWorld.Wait(40);
  Assert.AreEqual(3, PictureFill, 'l''ultimo fotogramma si vede');
  Assert.AreEqual(3, Video.FramesShown);
end;

procedure TTestXcomCutscenes.DovrebbeDareAlloSchermoLaPaletteDelFilmato;
begin
  FCatalog.AddRule('intro', VIDEO_RULE);
  FCatalog.AddFile('ANIMS/A.FLC', ThreeFrames(XCOM_FLC_TYPE_FLC, 40));
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(10);
  Assert.AreEqual(200, Integer(FWorld.Game.Screen.Palette^[1].Red));
  Assert.AreEqual(100, Integer(FWorld.Game.Screen.Palette^[1].Green));
  Assert.AreEqual(50, Integer(FWorld.Game.Screen.Palette^[1].Blue));
  Assert.IsFalse(FWorld.Game.Cursor.Visible);
end;

procedure TTestXcomCutscenes.DovrebbeSfumareEChiudereAllaFineDelFilmato;
var
  LRed: Integer;
begin
  FCatalog.AddRule('intro', VIDEO_RULE);
  FCatalog.AddFile('ANIMS/A.FLC', ThreeFrames(XCOM_FLC_TYPE_FLC, 40));
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(100);
  Assert.AreEqual(Ord(vpFade), Ord(Video.Phase));
  FWorld.Wait(400);
  LRed := FWorld.Game.Screen.Palette^[1].Red;
  Assert.IsTrue((LRed < 150) and (LRed > 50), Format('a meta'' della sfumatura il rosso e'' %d', [LRed]));
  FWorld.Wait(600);
  Assert.AreSame(FBase, FWorld.Game.TopState, 'venti passi da 45 ms');
  Assert.IsTrue(FWorld.Game.Cursor.Visible);
end;

procedure TTestXcomCutscenes.DovrebbeSaltareIlFilmatoConUnTastoSenzaSfumare;
begin
  FCatalog.AddRule('intro', VIDEO_RULE);
  FCatalog.AddFile('ANIMS/A.FLC', ThreeFrames(XCOM_FLC_TYPE_FLC, 1000));
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(10);
  Key(XCOM_KEY_ESCAPE_CODE);
  FWorld.Wait(5);
  Assert.AreSame(FBase, FWorld.Game.TopState);
  Assert.IsTrue(FWorld.Game.Cursor.Visible);
  Assert.IsTrue(FMusic.Stops > 0, 'la musica si ferma');
end;

procedure TTestXcomCutscenes.DovrebbeSaltareIlFilmatoConUnClic;
begin
  FCatalog.AddRule('intro', VIDEO_RULE);
  FCatalog.AddFile('ANIMS/A.FLC', ThreeFrames(XCOM_FLC_TYPE_FLC, 1000));
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(10);
  FWorld.Click(10, 10);
  Assert.AreSame(FBase, FWorld.Game.TopState);
end;

procedure TTestXcomCutscenes.DovrebbeSaltareIFilmatiCheMancano;
begin
  FCatalog.AddRule('intro', 'videos:'#10'  - ANIMS/A.FLC'#10'  - ANIMS/MISSING.FLC'#10'  - ANIMS/B.FLC'#10);
  FCatalog.AddFile('ANIMS/A.FLC', ThreeFrames(XCOM_FLC_TYPE_FLC, 10));
  FCatalog.AddFile('ANIMS/B.FLC', ThreeFrames(XCOM_FLC_TYPE_FLC, 10));
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(100);
  Assert.AreEqual(Ord(vpFade), Ord(Video.Phase));
  Assert.AreEqual(3, Video.FramesShown);
  Assert.AreEqual(3, PictureFill, 'anche il secondo filmato e'' arrivato in fondo');
end;

procedure TTestXcomCutscenes.DovrebbeSuonareLaSequenzaAudioDiUfoERimettereIVolumi;
begin
  FCatalog.AddRule('intro', 'useUfoAudioSequence: true'#10 + VIDEO_RULE);
  FCatalog.AddFile('ANIMS/A.FLC', ThreeFrames(XCOM_FLC_TYPE_FLI, 1));
  FCatalog.AddFile('SOUND/INTRO.CAT', TBytes.Create(0));
  FWorld.Game.Options.MusicVolume := 30;
  FWorld.Game.Options.SoundVolume := 90;
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(100);
  Assert.AreEqual(90, FWorld.Game.Options.MusicVolume, 'musica e suoni al piu'' alto dei due');
  Assert.AreEqual(90, FWorld.Game.Options.SoundVolume);
  Assert.IsTrue(FMusic.Names.IndexOf('GMINTRO1:0') >= 0, 'il comando del fotogramma 0');
  Assert.AreEqual(2, PictureFill, 'con la sequenza audio l''ultimo fotogramma non si disegna');
  Assert.AreEqual(Ord(vpTail), Ord(Video.Phase));
  FWorld.Wait(5000);
  Assert.AreEqual(Ord(vpTail), Ord(Video.Phase), 'dieci secondi di attesa alla fine');
  Key(XCOM_KEY_ESCAPE_CODE);
  FWorld.Wait(5);
  Assert.AreSame(FBase, FWorld.Game.TopState);
  Assert.AreEqual(30, FWorld.Game.Options.MusicVolume);
  Assert.AreEqual(90, FWorld.Game.Options.SoundVolume);
end;

procedure TTestXcomCutscenes.DovrebbeLasciarPerdereLaSequenzaAudioSenzaISuoni;
begin
  FCatalog.AddRule('intro', 'useUfoAudioSequence: true'#10 + VIDEO_RULE);
  FCatalog.AddFile('ANIMS/A.FLC', ThreeFrames(XCOM_FLC_TYPE_FLI, 1));
  FWorld.Game.Options.MusicVolume := 30;
  FWorld.Game.Options.SoundVolume := 90;
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(100);
  Assert.AreEqual(30, FWorld.Game.Options.MusicVolume);
  Assert.AreEqual(-1, FMusic.Names.IndexOf('GMINTRO1:0'));
  Assert.AreEqual(Ord(vpFade), Ord(Video.Phase), 'senza INTRO.CAT ne'' SAMPLE3.CAT e'' un filmato come gli altri');
  Assert.AreEqual(3, PictureFill);
end;

procedure TTestXcomCutscenes.DovrebbeAvviareLaTracciaAudioDelFilmato;
begin
  FCatalog.AddRule('intro', VIDEO_RULE + 'audioTracks:'#10'  - GMTRACK'#10);
  FCatalog.AddFile('ANIMS/A.FLC', ThreeFrames(XCOM_FLC_TYPE_FLC, 40));
  FWorld.Game.PushState(TXcomCutsceneState.Create(FWorld.Game, 'intro', FCatalogRef));
  FWorld.Wait(10);
  Assert.IsTrue(FMusic.Names.IndexOf('GMTRACK:0') >= 0);
end;

end.
