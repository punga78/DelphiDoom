{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - animations and MODELDEF        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Anim;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Anim.Intf,
  DelphiDoom.Tests.Models.AnimSupport;

type
  /// <summary>TAnimManager (idAnimManager) on a list of files in memory</summary>
  [TestFixture]
  [Category('Anim')]
  TTestAnimManager = class
  strict private
    FFiles: TFakeFiles;
    FFilesIntf: IInterface;
    FLog: TRecordingLog;
    FLogIntf: IInterface;
    FManager: IAnimManager;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCaricareUnaAnimazioneUnaSolaVolta;
    [Test]
    procedure DovrebbeRifiutareUnNomeCheNonESuMd5Anim;
    [Test]
    procedure DovrebbeRicordareIlFallimentoSenzaRipetereLAvviso;
    [Test]
    procedure DovrebbeFallireSuUnFileMalformato;
    [Test]
    procedure DovrebbeContareIRiferimentiEScartareLeAnimazioniInutilizzate;
    [Test]
    procedure DovrebbeNumerareINomiDeiGiunti;
    [Test]
    procedure DovrebbeRifiutareUnIndiceDiNomeFuoriIntervallo;
    [Test]
    procedure DovrebbeRicaricareLeAnimazioniCambiate;
    [Test]
    procedure DovrebbeControllareLaGerarchiaDelModello;
    [Test]
    procedure DovrebbeSvuotareTuttoConShutdown;
  end;

  /// <summary>TAnim (idAnim): the frame commands and the questions to the md5anims</summary>
  [TestFixture]
  [Category('Anim')]
  TTestAnim = class
  strict private
    FFiles: TFakeFiles;
    FFilesIntf: IInterface;
    FManager: IAnimManager;
    FMd5Anim: IMd5Anim;
    function NewAnim: IAnim;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeMisureDelPrimoMd5Anim;
    [Test]
    procedure DovrebbeDareValoriNeutriSenzaAnim;
    [Test]
    procedure DovrebbeDareOrigineRotazioneEBounds;
    [Test]
    procedure DovrebbeOrdinareICommandiDeiFotogrammi;
    [Test]
    procedure DovrebbeTrovareIlPrimoFotogrammaConUnComando;
    [Test]
    procedure DovrebbeRifiutareUnFotogrammaFuoriIntervallo;
    [Test]
    procedure DovrebbeClonareConIComandiELeFlag;
    [Test]
    procedure DovrebbeContareEDarePoiIRiferimenti;
  end;

  /// <summary>The frame commands of the original, one by one</summary>
  [TestFixture]
  [Category('Anim')]
  TTestFrameCommandParser = class
  strict private
    FLookup: TFakeGameLookup;
    FLookupIntf: IModelDefGameLookup;
    FLog: TRecordingLog;
    FLogIntf: IInterface;
    FDef: IModelDef;
    function ParseCommand(const AText: string; out ACommandType: Integer; out AText2: string;
      out AHasText: Boolean; out AIndex: Integer): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('call', 'call fn,0,fn,False,0')]
    [TestCase('object_call', 'object_call obj,1,obj,True,0')]
    [TestCase('event', 'event ev,2,ev,True,0')]
    [TestCase('sound chiave', 'sound snd_a,3,snd_a,True,0')]
    [TestCase('sound shader', 'sound shader_a,3,shader_a,False,0')]
    [TestCase('sound_voice2', 'sound_voice2 snd_v,5,snd_v,True,0')]
    [TestCase('sound_chatter', 'sound_chatter x,12,x,False,0')]
    [TestCase('skin', 'skin sk,13,sk,False,0')]
    [TestCase('skin none', 'skin none,13,,False,0')]
    [TestCase('trigger', 'trigger t1,14,t1,True,0')]
    [TestCase('melee', 'melee def_melee,16,def_melee,True,0')]
    [TestCase('attack_end', 'attack_end,19,,False,0')]
    [TestCase('muzzle_flash giunto', 'muzzle_flash arm,20,arm,True,0')]
    [TestCase('muzzle_flash vuoto', 'muzzle_flash "",20,,True,0')]
    [TestCase('create_missile', 'create_missile origin,21,origin,True,0')]
    [TestCase('fire_missile_at_target', 'fire_missile_at_target arm target,23,target,True,1')]
    [TestCase('footstep', 'footstep,24,,False,0')]
    [TestCase('fx', 'fx fx_a,29,fx_a,True,0')]
    [TestCase('jump', 'jump,32,,False,0')]
    [TestCase('enableLegIK', 'enableLegIK 3,37,3,False,3')]
    [TestCase('disableLegIK', 'disableLegIK 2,38,2,False,2')]
    [TestCase('recordDemo con nome', 'recordDemo demo1,39,demo1,True,0')]
    [TestCase('recordDemo senza nome', 'recordDemo,39,,False,0')]
    [TestCase('aviGame', 'aviGame film,40,film,True,0')]
    procedure DovrebbeLeggereIlComando(const ALine: string; const AType: Integer; const AText: string;
      const AHasText: Boolean; const AIndex: Integer);
    [Test]
    [TestCase('call', 'call missing,Function ''missing'' not found')]
    [TestCase('event', 'event missing,Event ''missing'' not found')]
    [TestCase('event con argomenti', 'event ev_args,Event ''ev_args'' has arguments')]
    [TestCase('skin', 'skin missing,Skin ''missing'' not found')]
    [TestCase('fx', 'fx missing,fx ''missing'' not found')]
    [TestCase('melee', 'melee missing,Unknown entityDef ''missing''')]
    [TestCase('direct_damage', 'direct_damage missing,Unknown entityDef ''missing''')]
    [TestCase('giunto', 'create_missile missing,Joint ''missing'' not found')]
    [TestCase('muzzle_flash giunto', 'muzzle_flash missing,Joint ''missing'' not found')]
    [TestCase('fire_missile_at_target giunto', 'fire_missile_at_target missing target,Joint ''missing'' not found')]
    [TestCase('comando sconosciuto', 'dance,Unknown command ''dance''')]
    [TestCase('call senza argomento', 'call,Unexpected end of line')]
    [TestCase('fire_missile_at_target senza bersaglio', 'fire_missile_at_target arm,Unexpected end of line')]
    [TestCase('enableLegIK senza numero', 'enableLegIK,Unexpected end of line')]
    procedure DovrebbeDareIlMessaggioDiErrore(const ALine, AExpected: string);
    [Test]
    procedure DovrebbeAvvisareDiUnSuonoCheNonEsiste;
    [Test]
    procedure DovrebbeDareFineRigaSenzaComando;
  end;

  /// <summary>TModelDefParser and TModelDef (idDeclModelDef) on the synthetic cube</summary>
  [TestFixture]
  [Category('Anim')]
  TTestModelDefParser = class
  strict private
    FFiles: TFakeFiles;
    FFilesIntf: IInterface;
    FSource: TFakeModelDefSource;
    FSourceIntf: IInterface;
    FLookup: TFakeGameLookup;
    FLookupIntf: IModelDefGameLookup;
    FLog: TRecordingLog;
    FLogIntf: IInterface;
    FManager: IAnimManager;
    FParser: IModelDefParser;
    FModel: IMd5Model;
    function Parse(const ABody: string): IModelDef;
    function Base: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereUnaDefinizioneCompleta;
    [Test]
    procedure DovrebbeLeggereLeAnimazioniConPiuAnimSincronizzate;
    [Test]
    procedure DovrebbeLeggereIComandiEDLeFlagDiUnaAnimazione;
    [Test]
    procedure DovrebbeDistribuireIGiuntiNeiCanali;
    [Test]
    procedure DovrebbeAvvisareDiUnGiuntoSuDueCanali;
    [Test]
    procedure DovrebbeEreditareDaUnaDefinizione;
    [Test]
    procedure DovrebbeSostituireUnAnimEreditataConLoStessoNome;
    [Test]
    procedure DovrebbeRimuovereUnAnimEreditata;
    [Test]
    procedure DovrebbeAvvisareSeLaDefinizioneEreditataNonEsiste;
    [Test]
    procedure DovrebbeUsareLaDefinizioneDiDefaultSeQuellaEreditataEDiDefault;
    [Test]
    [TestCase('mesh non md5mesh', 'mesh cube.md5anim')]
    [TestCase('mesh che non c''e', 'mesh none.md5mesh')]
    [TestCase('mesh di default', 'mesh defaulted.md5mesh')]
    [TestCase('mesh senza argomento', 'mesh')]
    [TestCase('skin che non c''e', 'skin missing')]
    [TestCase('skin senza argomento', 'skin')]
    [TestCase('anim prima della mesh', 'anim idle1 cube.md5anim')]
    [TestCase('channel prima della mesh', 'channel torso ( origin )')]
    [TestCase('remove senza argomento', 'remove')]
    [TestCase('remove senza anim', 'mesh cube.md5mesh remove walk')]
    [TestCase('offset malformato', 'offset ( 1 2 )')]
    [TestCase('token sconosciuto', 'dance')]
    [TestCase('anim senza nome', 'mesh cube.md5mesh anim')]
    [TestCase('anim nome numerico', 'mesh cube.md5mesh anim 123 cube.md5anim')]
    [TestCase('anim duplicata', 'mesh cube.md5mesh anim idle1 cube.md5anim anim idle1 cube.md5anim')]
    [TestCase('anim che non carica', 'mesh cube.md5mesh anim idle1 none.md5anim')]
    [TestCase('anim senza fine', 'mesh cube.md5mesh anim idle1')]
    [TestCase('comando sconosciuto in anim', 'mesh cube.md5mesh anim idle1 cube.md5anim { dance }')]
    [TestCase('anim con fotogramma fuori intervallo', 'mesh cube.md5mesh anim idle1 cube.md5anim { frame 9 jump }')]
    [TestCase('anim con fotogramma negativo', 'mesh cube.md5mesh anim idle1 cube.md5anim { frame - jump }')]
    [TestCase('anim con fotogramma mancante', 'mesh cube.md5mesh anim idle1 cube.md5anim { frame }')]
    [TestCase('anim con comando sconosciuto', 'mesh cube.md5mesh anim idle1 cube.md5anim { frame 1 dance }')]
    [TestCase('anim senza chiusura', 'mesh cube.md5mesh anim idle1 cube.md5anim { jump')]
    [TestCase('channel sconosciuto', 'mesh cube.md5mesh channel nose ( origin )')]
    [TestCase('channel senza parentesi', 'mesh cube.md5mesh channel torso origin')]
    [TestCase('channel senza chiusura', 'mesh cube.md5mesh channel torso ( origin')]
    [TestCase('channel senza nome', 'mesh cube.md5mesh channel')]
    procedure DovrebbeDareLaDefinizioneDiDefaultSuUnErrore(const ABody: string);
    [Test]
    procedure DovrebbeDareLaDefinizioneDiDefaultSeLeAnimSincronizzateHannoLunghezzeDiverse;
    [Test]
    procedure DovrebbeDareLaDefinizioneDiDefaultSeLeAnimSincronizzateSonoTroppe;
    [Test]
    procedure DovrebbeSollevareSeLaGerarchiaDellAnimNonCorrisponde;
    [Test]
    procedure DovrebbeSceglierLAnimPerNomeEPerNumero;
    [Test]
    procedure DovrebbeDarePosizioniEGiuntiDellaDefinizione;
    [Test]
    procedure DovrebbeCostruireLaListaDeiGiunti;
    [Test]
    procedure DovrebbeRifiutareManiglieEcanaliFuoriIntervallo;
    [Test]
    procedure DovrebbeDarePosaEBoundsDiSetupJoints;
    [Test]
    procedure DovrebbeDareListeVuoteSenzaModello;
    [Test]
    procedure DovrebbeUsareLaFabbricaConLaLookupPermissiva;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Text.Lexer,
  DelphiDoom.MathCore.Float.Quat,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Md5.Factory,
  DelphiDoom.Models.Md5.JointMat,
  DelphiDoom.Models.Anim.Types,
  DelphiDoom.Models.Anim.ModelDef,
  DelphiDoom.Models.Anim.FrameCommandParser,
  DelphiDoom.Models.Anim.Factory;

{ TTestAnimManager }

procedure TTestAnimManager.Setup;
begin
  FFiles := TFakeFiles.Create;
  FFilesIntf := FFiles;
  FLog := TRecordingLog.Create;
  FLogIntf := FLog;
  FFiles.Put('cube.md5anim', CubeAnimText);
  FManager := TAnimFactory.CreateManager(FFiles, FLog);
end;

procedure TTestAnimManager.TearDown;
begin
  FManager := nil;
  FLogIntf := nil;
  FFilesIntf := nil;
end;

procedure TTestAnimManager.DovrebbeCaricareUnaAnimazioneUnaSolaVolta;
var
  LFirst, LSecond: IMd5Anim;
begin
  LFirst := FManager.GetAnim('cube.md5anim');
  LSecond := FManager.GetAnim('cube.md5anim');
  Assert.IsNotNull(LFirst);
  Assert.IsTrue(LFirst = LSecond, 'la stessa istanza');
  Assert.AreEqual<Integer>(1, FFiles.Reads);
  Assert.AreEqual<Integer>(1, FManager.NumAnims);
  Assert.AreEqual<Integer>(3, LFirst.NumFrames);
end;

procedure TTestAnimManager.DovrebbeRifiutareUnNomeCheNonESuMd5Anim;
begin
  Assert.IsNull(FManager.GetAnim('cube.txt'));
  Assert.IsNull(FManager.GetAnim('cube'));
  Assert.IsNull(FManager.GetAnim('cube.MD5ANIM'), 'il confronto e'' esatto');
  Assert.AreEqual<Integer>(0, FFiles.Reads);
  Assert.AreEqual<Integer>(0, FLog.Count);
end;

procedure TTestAnimManager.DovrebbeRicordareIlFallimentoSenzaRipetereLAvviso;
begin
  Assert.IsNull(FManager.GetAnim('none.md5anim'));
  Assert.IsNull(FManager.GetAnim('none.md5anim'));
  Assert.AreEqual<Integer>(1, FFiles.Reads);
  Assert.AreEqual<Integer>(1, FLog.Count);
  Assert.IsTrue(Pos('none.md5anim', FLog.Text) > 0);
  Assert.AreEqual<Integer>(0, FManager.NumAnims);
end;

procedure TTestAnimManager.DovrebbeFallireSuUnFileMalformato;
begin
  FFiles.Put('bad.md5anim', 'MD5Version 10 numFrames x');
  Assert.IsNull(FManager.GetAnim('bad.md5anim'));
  FFiles.Put('empty.md5anim', 'MD5Version 10' + #10 + 'numFrames 0 numJoints 0 frameRate 0 numAnimatedComponents 0');
  Assert.IsNull(FManager.GetAnim('empty.md5anim'));
  Assert.AreEqual<Integer>(2, FLog.Count);
end;

procedure TTestAnimManager.DovrebbeContareIRiferimentiEScartareLeAnimazioniInutilizzate;
var
  LAnim: IMd5Anim;
begin
  LAnim := FManager.GetAnim('cube.md5anim');
  Assert.AreEqual<Integer>(0, FManager.NumRefs(LAnim));
  FManager.IncreaseRefs(LAnim);
  FManager.IncreaseRefs(LAnim);
  Assert.AreEqual<Integer>(2, FManager.NumRefs(LAnim));
  Assert.IsFalse(FManager.FlushUnusedAnims, 'in uso');
  FManager.DecreaseRefs(LAnim);
  FManager.DecreaseRefs(LAnim);
  Assert.IsTrue(FManager.FlushUnusedAnims);
  Assert.AreEqual<Integer>(0, FManager.NumAnims);
  FManager.IncreaseRefs(nil);
  Assert.AreEqual<Integer>(0, FManager.NumRefs(LAnim), 'sconosciuta');
  Assert.AreEqual<Integer>(0, FManager.NumRefs(nil));
end;

procedure TTestAnimManager.DovrebbeNumerareINomiDeiGiunti;
begin
  Assert.AreEqual<Integer>(0, FManager.JointIndex('origin'));
  Assert.AreEqual<Integer>(1, FManager.JointIndex('arm'));
  Assert.AreEqual<Integer>(0, FManager.JointIndex('origin'));
  Assert.AreEqual<Integer>(2, FManager.JointIndex('Origin'), 'il confronto distingue le maiuscole');
  Assert.AreEqual('arm', string(FManager.JointName(1)));
  Assert.AreEqual<Integer>(3, FManager.NumJointNames);
end;

procedure TTestAnimManager.DovrebbeRifiutareUnIndiceDiNomeFuoriIntervallo;
begin
  Assert.WillRaise(
    procedure
    begin
      FManager.JointName(0);
    end, EAnimException);
end;

procedure TTestAnimManager.DovrebbeRicaricareLeAnimazioniCambiate;
var
  LOld: IMd5Anim;
begin
  LOld := FManager.GetAnim('cube.md5anim');
  FManager.GetAnim('none.md5anim');
  FFiles.Put('cube.md5anim', ShortAnimText);
  FFiles.Put('none.md5anim', CubeAnimText);
  FManager.ReloadAnims;
  Assert.AreEqual<Integer>(3, LOld.NumFrames, 'quella vecchia non cambia');
  Assert.AreEqual<Integer>(2, FManager.GetAnim('cube.md5anim').NumFrames);
  Assert.IsNull(FManager.GetAnim('none.md5anim'), 'un fallimento non si ritenta');
  FFiles.Put('cube.md5anim', 'rotto');
  FManager.ReloadAnims;
  Assert.AreEqual<Integer>(2, FManager.GetAnim('cube.md5anim').NumFrames, 'se non si rilegge resta quella buona');
end;

procedure TTestAnimManager.DovrebbeControllareLaGerarchiaDelModello;
var
  LModel: IMd5Model;
begin
  LModel := TMd5Factory.CreateModelParser.Parse(CubeModelText, 'cube.md5mesh');
  FManager.CheckModelHierarchy(FManager.GetAnim('cube.md5anim'), LModel);
  FFiles.Put('renamed.md5anim', RenamedJointAnimText);
  Assert.WillRaise(
    procedure
    begin
      FManager.CheckModelHierarchy(FManager.GetAnim('renamed.md5anim'), LModel);
    end, EAnimException);
end;

procedure TTestAnimManager.DovrebbeSvuotareTuttoConShutdown;
begin
  FManager.GetAnim('cube.md5anim');
  FManager.JointIndex('a');
  FManager.Shutdown;
  Assert.AreEqual<Integer>(0, FManager.NumAnims);
  Assert.AreEqual<Integer>(0, FManager.NumJointNames);
end;

{ TTestAnim }

procedure TTestAnim.Setup;
begin
  FFiles := TFakeFiles.Create;
  FFilesIntf := FFiles;
  FFiles.Put('cube.md5anim', CubeAnimText);
  FManager := TAnimFactory.CreateManager(FFiles, nil);
  FMd5Anim := FManager.GetAnim('cube.md5anim');
end;

procedure TTestAnim.TearDown;
begin
  FMd5Anim := nil;
  FManager := nil;
  FFilesIntf := nil;
end;

function TTestAnim.NewAnim: IAnim;
begin
  Result := TAnimFactory.CreateAnim(FManager, 'idle1', 'idle', [FMd5Anim]);
end;

procedure TTestAnim.DovrebbeDareLeMisureDelPrimoMd5Anim;
var
  LAnim: IAnim;
begin
  LAnim := NewAnim;
  Assert.AreEqual('idle', string(LAnim.Name));
  Assert.AreEqual('idle1', string(LAnim.FullName));
  Assert.AreEqual<Integer>(1, LAnim.NumAnims);
  Assert.AreEqual<Integer>(FMd5Anim.Length, LAnim.Length);
  Assert.AreEqual<Integer>(3, LAnim.NumFrames);
  Assert.AreEqual(FMd5Anim.TotalMovementDelta.X, LAnim.TotalMovementDelta.X, 0.0);
  Assert.IsTrue(LAnim.GetMd5Anim(0) = FMd5Anim);
  Assert.IsNull(LAnim.GetMd5Anim(1));
  Assert.IsNull(LAnim.GetMd5Anim(-1));
end;

procedure TTestAnim.DovrebbeDareValoriNeutriSenzaAnim;
var
  LAnim: IAnim;
  LOffset: TIdVec3;
  LRotation: TIdQuat;
  LBounds: TGeoBounds;
  LFound: TAnimFrameCommand;
begin
  LAnim := TAnimFactory.CreateAnim(FManager, 'a1', 'a', nil);
  Assert.AreEqual<Integer>(0, LAnim.Length);
  Assert.AreEqual<Integer>(0, LAnim.NumFrames);
  Assert.AreEqual(0.0, LAnim.TotalMovementDelta.Length, 0.0);
  Assert.IsFalse(LAnim.GetOrigin(0, 0, 0, LOffset));
  Assert.AreEqual(0.0, LOffset.Length, 0.0);
  Assert.IsFalse(LAnim.GetOriginRotation(0, 0, 0, LRotation));
  Assert.AreEqual(1.0, LRotation.W, 0.0);
  Assert.IsFalse(LAnim.GetBounds(0, 0, 0, LBounds));
  Assert.AreEqual<Integer>(-1, LAnim.FindFrameForFrameCommand(fcJump, LFound));
end;

procedure TTestAnim.DovrebbeDareOrigineRotazioneEBounds;
var
  LAnim: IAnim;
  LOffset: TIdVec3;
  LRotation: TIdQuat;
  LBounds: TGeoBounds;
begin
  LAnim := NewAnim;
  Assert.IsTrue(LAnim.GetOrigin(0, 0, 0, LOffset));
  Assert.AreEqual(FMd5Anim.GetOrigin(0, 0).X, LOffset.X, 0.0);
  Assert.IsTrue(LAnim.GetOriginRotation(0, 40, 0, LRotation));
  Assert.AreEqual(FMd5Anim.GetOriginRotation(40, 0).Z, LRotation.Z, 0.0);
  Assert.IsTrue(LAnim.GetBounds(0, 40, 0, LBounds));
  Assert.AreEqual(FMd5Anim.GetBounds(40, 0).Mins.X, LBounds.Mins.X, 0.0);
end;

procedure TTestAnim.DovrebbeOrdinareICommandiDeiFotogrammi;
var
  LAnim: IAnim;
  LCommand: TAnimFrameCommand;
  LCommands: TArray<TAnimFrameCommand>;
begin
  LAnim := NewAnim;
  Assert.IsFalse(LAnim.HasFrameCommands);
  LCommand.CommandType := fcJump;
  LAnim.AddFrameCommand(2, LCommand);
  LCommand.CommandType := fcFootstep;
  LAnim.AddFrameCommand(0, LCommand);
  LCommand.CommandType := fcLeftFoot;
  LAnim.AddFrameCommand(2, LCommand);
  LCommand.CommandType := fcRightFoot;
  LAnim.AddFrameCommand(1, LCommand);
  Assert.AreEqual<Integer>(4, LAnim.FrameCommandCount);
  Assert.IsTrue(LAnim.HasFrameCommands);
  LCommands := LAnim.GetFrameCommands(2);
  Assert.AreEqual<Integer>(2, Length(LCommands));
  Assert.AreEqual<Integer>(Ord(fcJump), Ord(LCommands[0].CommandType), 'in ordine di aggiunta');
  Assert.AreEqual<Integer>(Ord(fcLeftFoot), Ord(LCommands[1].CommandType));
  Assert.AreEqual<Integer>(Ord(fcFootstep), Ord(LAnim.GetFrameCommands(0)[0].CommandType));
  Assert.AreEqual<Integer>(Ord(fcRightFoot), Ord(LAnim.GetFrameCommands(1)[0].CommandType));
  Assert.AreEqual<Integer>(0, Length(LAnim.GetFrameCommands(3)), 'fotogramma che non c''e''');
  Assert.AreEqual<Integer>(0, Length(LAnim.GetFrameCommands(-1)));
end;

procedure TTestAnim.DovrebbeTrovareIlPrimoFotogrammaConUnComando;
var
  LAnim: IAnim;
  LCommand, LFound: TAnimFrameCommand;
begin
  LAnim := NewAnim;
  Assert.AreEqual<Integer>(-1, LAnim.FindFrameForFrameCommand(fcJump, LFound), 'senza comandi');
  LCommand.CommandType := fcJump;
  LCommand.Text := 'b';
  LAnim.AddFrameCommand(2, LCommand);
  LCommand.Text := 'a';
  LAnim.AddFrameCommand(1, LCommand);
  Assert.AreEqual<Integer>(1, LAnim.FindFrameForFrameCommand(fcJump, LFound));
  Assert.AreEqual('a', string(LFound.Text));
  Assert.AreEqual<Integer>(-1, LAnim.FindFrameForFrameCommand(fcFootstep, LFound));
end;

procedure TTestAnim.DovrebbeRifiutareUnFotogrammaFuoriIntervallo;
var
  LAnim: IAnim;
  LCommand: TAnimFrameCommand;
begin
  LAnim := NewAnim;
  LCommand.CommandType := fcJump;
  Assert.WillRaise(
    procedure
    begin
      LAnim.AddFrameCommand(3, LCommand);
    end, EModelsException);
  Assert.WillRaise(
    procedure
    begin
      LAnim.AddFrameCommand(-1, LCommand);
    end, EModelsException);
end;

procedure TTestAnim.DovrebbeClonareConIComandiELeFlag;
var
  LAnim, LCopy: IAnim;
  LCommand: TAnimFrameCommand;
  LFlags: TAnimFlags;
begin
  LAnim := NewAnim;
  LCommand.CommandType := fcJump;
  LAnim.AddFrameCommand(1, LCommand);
  LFlags := Default(TAnimFlags);
  LFlags.AnimTurn := True;
  LAnim.Flags := LFlags;
  LCopy := LAnim.Clone;
  Assert.AreEqual('idle1', string(LCopy.FullName));
  Assert.IsTrue(LCopy.Flags.AnimTurn);
  Assert.AreEqual<Integer>(1, LCopy.FrameCommandCount);
  LCommand.CommandType := fcFootstep;
  LCopy.AddFrameCommand(1, LCommand);
  Assert.AreEqual<Integer>(1, LAnim.FrameCommandCount, 'le liste sono separate');
end;

procedure TTestAnim.DovrebbeContareEDarePoiIRiferimenti;
var
  LAnim, LCopy: IAnim;
begin
  LAnim := NewAnim;
  Assert.AreEqual<Integer>(1, FManager.NumRefs(FMd5Anim));
  LCopy := LAnim.Clone;
  Assert.AreEqual<Integer>(2, FManager.NumRefs(FMd5Anim));
  LCopy := nil;
  Assert.AreEqual<Integer>(1, FManager.NumRefs(FMd5Anim));
  LAnim := nil;
  Assert.AreEqual<Integer>(0, FManager.NumRefs(FMd5Anim));
end;

{ TTestFrameCommandParser }

procedure TTestFrameCommandParser.Setup;
var
  LModelDef: TModelDef;
  LModel: IMd5Model;
begin
  FLookup := TFakeGameLookup.Create;
  FLookupIntf := FLookup;
  FLog := TRecordingLog.Create;
  FLogIntf := FLog;
  FLookup.AddFunction('fn');
  FLookup.AddEvent('ev', 0);
  FLookup.AddEvent('ev_args', 2);
  FLookup.AddSkin('sk');
  FLookup.AddFx('fx_a');
  FLookup.AddEntityDef('def_melee');
  FLookup.AddSound('shader_a');
  LModel := TMd5Factory.CreateModelParser.Parse(CubeModelText, 'cube.md5mesh');
  LModelDef := TModelDef.Create('def');
  LModelDef.SetModel(LModel);
  FDef := LModelDef;
end;

procedure TTestFrameCommandParser.TearDown;
begin
  FDef := nil;
  FLogIntf := nil;
  FLookupIntf := nil;
end;

function TTestFrameCommandParser.ParseCommand(const AText: string; out ACommandType: Integer;
  out AText2: string; out AHasText: Boolean; out AIndex: Integer): string;
var
  LLexer: TIdLexer;
  LParser: TAnimFrameCommandParser;
  LCommand: TAnimFrameCommand;
begin
  LLexer := TIdLexer.Create(MODELDEF_LEXER_FLAGS, FLog);
  LParser := TAnimFrameCommandParser.Create(FLookup, FLog);
  try
    LLexer.LoadMemory(AnsiString(AText), Length(AText), 'test', 1);
    Result := LParser.Parse(LLexer, FDef, LCommand);
    ACommandType := Ord(LCommand.CommandType);
    AText2 := string(LCommand.Text);
    AHasText := LCommand.HasText;
    AIndex := LCommand.Index;
  finally
    LParser.Free;
    LLexer.Free;
  end;
end;

procedure TTestFrameCommandParser.DovrebbeLeggereIlComando(const ALine: string; const AType: Integer;
  const AText: string; const AHasText: Boolean; const AIndex: Integer);
var
  LType, LIndex: Integer;
  LText: string;
  LHasText: Boolean;
begin
  Assert.AreEqual('', ParseCommand(ALine, LType, LText, LHasText, LIndex));
  Assert.AreEqual(AType, LType, 'tipo');
  Assert.AreEqual(AText, LText, 'testo');
  Assert.AreEqual(AHasText, LHasText, 'ha il testo');
  Assert.AreEqual(AIndex, LIndex, 'indice');
end;

procedure TTestFrameCommandParser.DovrebbeDareIlMessaggioDiErrore(const ALine, AExpected: string);
var
  LType, LIndex: Integer;
  LText: string;
  LHasText: Boolean;
begin
  Assert.AreEqual(AExpected, ParseCommand(ALine, LType, LText, LHasText, LIndex));
end;

procedure TTestFrameCommandParser.DovrebbeAvvisareDiUnSuonoCheNonEsiste;
var
  LType, LIndex: Integer;
  LText: string;
  LHasText: Boolean;
begin
  Assert.AreEqual('', ParseCommand('sound nowhere', LType, LText, LHasText, LIndex));
  Assert.AreEqual<Integer>(1, FLog.Count);
  Assert.IsTrue(Pos('nowhere', FLog.Text) > 0);
end;

procedure TTestFrameCommandParser.DovrebbeDareFineRigaSenzaComando;
var
  LType, LIndex: Integer;
  LText: string;
  LHasText: Boolean;
begin
  Assert.AreEqual('Unexpected end of line', ParseCommand('', LType, LText, LHasText, LIndex));
end;

{ TTestModelDefParser }

procedure TTestModelDefParser.Setup;
begin
  FFiles := TFakeFiles.Create;
  FFilesIntf := FFiles;
  FFiles.Put('cube.md5anim', CubeAnimText);
  FFiles.Put('cube2.md5anim', CubeAnimText);
  FFiles.Put('short.md5anim', ShortAnimText);
  FFiles.Put('renamed.md5anim', RenamedJointAnimText);
  FLog := TRecordingLog.Create;
  FLogIntf := FLog;
  FLookup := TFakeGameLookup.Create;
  FLookupIntf := FLookup;
  FLookup.AddSkin('skin_a');
  FLookup.AddEvent('e1', 0);
  FModel := TMd5Factory.CreateModelParser.Parse(CubeModelText, 'cube.md5mesh');
  FSource := TFakeModelDefSource.Create;
  FSourceIntf := FSource;
  FSource.AddModel('cube.md5mesh', FModel);
  FSource.AddDefaultedModel('defaulted.md5mesh');
  FManager := TAnimFactory.CreateManager(FFiles, FLog);
  FParser := TAnimFactory.CreateModelDefParser(FSource, FManager, FLookup, FLog);
end;

procedure TTestModelDefParser.TearDown;
begin
  FParser := nil;
  FManager := nil;
  FSourceIntf := nil;
  FLookupIntf := nil;
  FLogIntf := nil;
  FFilesIntf := nil;
end;

function TTestModelDefParser.Parse(const ABody: string): IModelDef;
begin
  Result := FParser.Parse('monster', AnsiString('model monster { ' + ABody + ' }'));
end;

function TTestModelDefParser.Base: string;
begin
  Result := 'mesh cube.md5mesh skin skin_a offset ( 1 2 3 ) ' +
    'channel torso ( origin ) channel legs ( *arm ) ' +
    'anim idle1 cube.md5anim { prevent_idle_override frame 1 sound snd_foo frame 2 event e1 frame 2 leftfoot } ' +
    'anim idle2 cube.md5anim anim walk cube.md5anim, cube2.md5anim';
end;

procedure TTestModelDefParser.DovrebbeLeggereUnaDefinizioneCompleta;
var
  LDef: IModelDef;
begin
  LDef := Parse(Base);
  Assert.IsFalse(LDef.Defaulted);
  Assert.AreEqual<Integer>(0, FLog.Count, FLog.Text);
  Assert.AreEqual('monster', string(LDef.Name));
  Assert.AreEqual('cube.md5mesh', string(LDef.GetModelName));
  Assert.AreEqual('skin_a', string(LDef.SkinName));
  Assert.AreEqual(1.0, LDef.Offset.X, 0.0);
  Assert.AreEqual(3.0, LDef.Offset.Z, 0.0);
  Assert.AreEqual<Integer>(2, LDef.NumJoints);
  Assert.AreEqual<Integer>(4, LDef.NumAnims, 'tre anim e la numero zero');
  Assert.IsNotNull(LDef.Model);
  Assert.IsTrue(LDef.HasAnim('idle'));
  Assert.IsTrue(LDef.HasAnim('walk'));
  Assert.IsFalse(LDef.HasAnim('run'));
  Assert.IsNull(LDef.GetAnimByIndex(0));
  Assert.IsNull(LDef.GetAnimByIndex(4));
  Assert.AreEqual('idle2', string(LDef.GetAnimByIndex(2).FullName));
  Assert.AreEqual('idle', string(LDef.GetAnimByIndex(2).Name), 'senza il numero');
end;

procedure TTestModelDefParser.DovrebbeLeggereLeAnimazioniConPiuAnimSincronizzate;
var
  LDef: IModelDef;
begin
  LDef := Parse(Base);
  Assert.AreEqual<Integer>(2, LDef.GetAnimByIndex(3).NumAnims);
  Assert.AreEqual('walk', string(LDef.GetAnimByIndex(3).FullName), 'un nome senza numero resta com''e''');
  Assert.AreEqual<Integer>(1, LDef.GetAnimByIndex(1).NumAnims);
end;

procedure TTestModelDefParser.DovrebbeLeggereIComandiEDLeFlagDiUnaAnimazione;
var
  LAnim: IAnim;
  LCommand: TAnimFrameCommand;
begin
  LAnim := Parse(Base).GetAnimByIndex(1);
  Assert.IsTrue(LAnim.Flags.PreventIdleOverride);
  Assert.IsFalse(LAnim.Flags.RandomCycleStart);
  Assert.AreEqual<Integer>(3, LAnim.FrameCommandCount);
  Assert.AreEqual<Integer>(0, LAnim.FindFrameForFrameCommand(fcSound, LCommand));
  Assert.AreEqual('snd_foo', string(LCommand.Text));
  Assert.AreEqual<Integer>(1, LAnim.FindFrameForFrameCommand(fcLeftFoot, LCommand));
  Assert.AreEqual<Integer>(Ord(fcEventFunction), Ord(LAnim.GetFrameCommands(1)[0].CommandType));
  LAnim := Parse('mesh cube.md5mesh anim idle1 cube.md5anim { random_cycle_start ai_no_turn anim_turn }').GetAnimByIndex(1);
  Assert.IsTrue(LAnim.Flags.RandomCycleStart and LAnim.Flags.AiNoTurn and LAnim.Flags.AnimTurn);
end;

procedure TTestModelDefParser.DovrebbeDistribuireIGiuntiNeiCanali;
var
  LDef: IModelDef;
begin
  LDef := Parse(Base);
  Assert.AreEqual<Integer>(2, LDef.NumJointsOnChannel(ANIMCHANNEL_ALL));
  Assert.AreEqual<Integer>(1, LDef.NumJointsOnChannel(ANIMCHANNEL_TORSO));
  Assert.AreEqual<Integer>(1, LDef.NumJointsOnChannel(ANIMCHANNEL_LEGS));
  Assert.AreEqual<Integer>(0, LDef.NumJointsOnChannel(ANIMCHANNEL_HEAD));
  Assert.AreEqual<Integer>(0, LDef.GetChannelJoints(ANIMCHANNEL_TORSO)[0]);
  Assert.AreEqual<Integer>(1, LDef.GetChannelJoints(ANIMCHANNEL_LEGS)[0]);
  Assert.AreEqual<Integer>(ANIMCHANNEL_TORSO, LDef.JointInfo[0].Channel);
  Assert.AreEqual<Integer>(ANIMCHANNEL_LEGS, LDef.JointInfo[1].Channel);
  Assert.AreEqual<Integer>(0, LDef.JointInfo[1].ParentNum);
  Assert.AreEqual<Integer>(-1, LDef.JointParents[0]);
end;

procedure TTestModelDefParser.DovrebbeAvvisareDiUnGiuntoSuDueCanali;
var
  LDef: IModelDef;
begin
  LDef := Parse('mesh cube.md5mesh channel torso ( origin ) channel legs ( *origin )');
  Assert.IsFalse(LDef.Defaulted);
  Assert.IsTrue(Pos('assigned to multiple channels', FLog.Text) > 0);
  Assert.AreEqual<Integer>(1, LDef.NumJointsOnChannel(ANIMCHANNEL_LEGS), 'resta solo il giunto figlio');
  Assert.AreEqual<Integer>(1, LDef.GetChannelJoints(ANIMCHANNEL_LEGS)[0]);
end;

procedure TTestModelDefParser.DovrebbeEreditareDaUnaDefinizione;
var
  LBase, LDerived: IModelDef;
begin
  LBase := Parse(Base);
  FSource.AddDef('base', LBase);
  LDerived := FParser.Parse('derived', 'model derived { inherit base anim run1 cube.md5anim offset ( 4 5 6 ) }');
  Assert.IsFalse(LDerived.Defaulted, FLog.Text);
  Assert.AreEqual<Integer>(5, LDerived.NumAnims);
  Assert.AreEqual('skin_a', string(LDerived.SkinName));
  Assert.AreEqual<Integer>(2, LDerived.NumJoints);
  Assert.AreEqual<Integer>(1, LDerived.NumJointsOnChannel(ANIMCHANNEL_TORSO));
  Assert.AreEqual(4.0, LDerived.Offset.X, 0.0);
  Assert.AreEqual(1.0, LBase.Offset.X, 0.0, 'la base non cambia');
  Assert.AreEqual<Integer>(4, LBase.NumAnims);
  Assert.IsTrue(LDerived.GetAnimByIndex(1).Flags.PreventIdleOverride, 'anche le flag');
  Assert.AreEqual<Integer>(3, LDerived.GetAnimByIndex(1).FrameCommandCount);
end;

procedure TTestModelDefParser.DovrebbeSostituireUnAnimEreditataConLoStessoNome;
var
  LDerived: IModelDef;
begin
  FSource.AddDef('base', Parse(Base));
  LDerived := FParser.Parse('derived', 'model derived { inherit base anim idle1 cube.md5anim { frame 3 footstep } }');
  Assert.IsFalse(LDerived.Defaulted, FLog.Text);
  Assert.AreEqual<Integer>(4, LDerived.NumAnims);
  Assert.AreEqual<Integer>(1, LDerived.GetAnimByIndex(1).FrameCommandCount);
  Assert.IsFalse(LDerived.GetAnimByIndex(1).Flags.PreventIdleOverride);
end;

procedure TTestModelDefParser.DovrebbeRimuovereUnAnimEreditata;
var
  LDerived: IModelDef;
begin
  FSource.AddDef('base', Parse(Base));
  LDerived := FParser.Parse('derived', 'model derived { inherit base remove idle1 remove walk }');
  Assert.IsFalse(LDerived.Defaulted, FLog.Text);
  Assert.AreEqual<Integer>(2, LDerived.NumAnims);
  Assert.AreEqual('idle2', string(LDerived.GetAnimByIndex(1).FullName));
  LDerived := FParser.Parse('derived', 'model derived { inherit base remove idle }');
  Assert.AreEqual<Integer>(2, LDerived.NumAnims, 'per nome senza numero cadono entrambe');
  LDerived := FParser.Parse('derived', 'model derived { inherit base anim extra1 cube.md5anim remove extra1 }');
  Assert.IsTrue(LDerived.Defaulted, 'si toglie solo cio'' che e'' stato ereditato');
end;

procedure TTestModelDefParser.DovrebbeAvvisareSeLaDefinizioneEreditataNonEsiste;
var
  LDef: IModelDef;
begin
  LDef := FParser.Parse('derived', 'model derived { inherit nothing mesh cube.md5mesh }');
  Assert.IsFalse(LDef.Defaulted);
  Assert.IsTrue(Pos('Unknown model definition', FLog.Text) > 0);
  Assert.AreEqual<Integer>(2, LDef.NumJoints);
end;

procedure TTestModelDefParser.DovrebbeUsareLaDefinizioneDiDefaultSeQuellaEreditataEDiDefault;
var
  LBroken, LDerived: IModelDef;
begin
  LBroken := Parse('dance');
  Assert.IsTrue(LBroken.Defaulted);
  FSource.AddDef('broken', LBroken);
  LDerived := FParser.Parse('derived', 'model derived { inherit broken }');
  Assert.IsTrue(LDerived.Defaulted);
  Assert.IsTrue(Pos('defaulted', FLog.Text) > 0);
end;

procedure TTestModelDefParser.DovrebbeDareLaDefinizioneDiDefaultSuUnErrore(const ABody: string);
var
  LDef: IModelDef;
begin
  LDef := Parse(ABody);
  Assert.IsTrue(LDef.Defaulted, 'definizione di default');
  Assert.IsTrue(FLog.Count > 0, 'un avviso');
  Assert.AreEqual<Integer>(1, LDef.NumAnims, 'vuota');
  Assert.AreEqual<Integer>(0, LDef.NumJoints);
  Assert.IsNull(LDef.Model);
end;

procedure TTestModelDefParser.DovrebbeDareLaDefinizioneDiDefaultSeLeAnimSincronizzateHannoLunghezzeDiverse;
begin
  Assert.IsTrue(Parse('mesh cube.md5mesh anim idle1 cube.md5anim, short.md5anim').Defaulted);
  Assert.IsTrue(Pos('does not match length', FLog.Text) > 0);
end;

procedure TTestModelDefParser.DovrebbeDareLaDefinizioneDiDefaultSeLeAnimSincronizzateSonoTroppe;
begin
  Assert.IsTrue(Parse('mesh cube.md5mesh anim idle1 cube.md5anim, cube.md5anim, cube.md5anim, cube.md5anim').Defaulted);
  Assert.IsTrue(Pos('Exceeded max synced anims', FLog.Text) > 0);
end;

procedure TTestModelDefParser.DovrebbeSollevareSeLaGerarchiaDellAnimNonCorrisponde;
begin
  Assert.WillRaise(
    procedure
    begin
      Parse('mesh cube.md5mesh anim idle1 renamed.md5anim');
    end, EAnimException);
end;

procedure TTestModelDefParser.DovrebbeSceglierLAnimPerNomeEPerNumero;
var
  LDef: IModelDef;
  LAsked: Integer;
begin
  LDef := Parse(Base);
  LAsked := -1;
  Assert.AreEqual<Integer>(1, LDef.GetAnim('idle1', nil), 'con il numero e'' esatta, nessun caso');
  Assert.AreEqual<Integer>(0, LDef.GetAnim('idle3', nil));
  Assert.AreEqual<Integer>(3, LDef.GetAnim('walk',
    function(const AMax: Integer): Integer
    begin
      LAsked := AMax;
      Result := 0;
    end));
  Assert.AreEqual<Integer>(1, LAsked);
  Assert.AreEqual<Integer>(2, LDef.GetAnim('idle',
    function(const AMax: Integer): Integer
    begin
      LAsked := AMax;
      Result := 1;
    end), 'la seconda delle due');
  Assert.AreEqual<Integer>(2, LAsked);
  Assert.AreEqual<Integer>(0, LDef.GetAnim('run', nil));
  Assert.AreEqual<Integer>(0, LDef.GetAnim('', nil));
  Assert.AreEqual<Integer>(2, LDef.GetSpecificAnim('idle2'));
  Assert.AreEqual<Integer>(0, LDef.GetSpecificAnim('idle'));
end;

procedure TTestModelDefParser.DovrebbeDarePosizioniEGiuntiDellaDefinizione;
var
  LDef: IModelDef;
begin
  LDef := Parse(Base);
  Assert.AreEqual<Integer>(0, LDef.FindJoint('ORIGIN'), 'senza distinguere le maiuscole');
  Assert.AreEqual<Integer>(1, LDef.FindJoint('arm'));
  Assert.AreEqual<Integer>(-1, LDef.FindJoint('leg'));
  Assert.AreEqual('arm', string(LDef.GetJointName(1)));
end;

procedure TTestModelDefParser.DovrebbeCostruireLaListaDeiGiunti;
var
  LDef: IModelDef;
  LList: TArray<Integer>;
begin
  LDef := Parse(Base);
  LList := LDef.GetJointList('origin arm origin', FLog);
  Assert.AreEqual<Integer>(2, Length(LList), 'senza doppioni');
  LList := LDef.GetJointList('*origin', FLog);
  Assert.AreEqual<Integer>(2, Length(LList), 'con i figli');
  LList := LDef.GetJointList('*origin -arm', FLog);
  Assert.AreEqual<Integer>(1, Length(LList));
  Assert.AreEqual<Integer>(0, LList[0]);
  LList := LDef.GetJointList('  ', FLog);
  Assert.AreEqual<Integer>(0, Length(LList));
  LList := LDef.GetJointList('nowhere arm', FLog);
  Assert.AreEqual<Integer>(1, Length(LList));
  Assert.IsTrue(Pos('Unknown joint ''nowhere''', FLog.Text) > 0);
  LList := LDef.GetJointList('nowhere', nil);
  Assert.AreEqual<Integer>(0, Length(LList), 'senza log non si avvisa');
end;

procedure TTestModelDefParser.DovrebbeRifiutareManiglieEcanaliFuoriIntervallo;
var
  LDef: IModelDef;
begin
  LDef := Parse(Base);
  Assert.WillRaise(
    procedure
    begin
      LDef.JointInfo[2];
    end, EAnimException);
  Assert.WillRaise(
    procedure
    begin
      LDef.GetJointName(-1);
    end, EAnimException);
  Assert.WillRaise(
    procedure
    begin
      LDef.NumJointsOnChannel(5);
    end, EAnimException);
  Assert.WillRaise(
    procedure
    begin
      LDef.GetChannelJoints(-1);
    end, EAnimException);
end;

procedure TTestModelDefParser.DovrebbeDarePosaEBoundsDiSetupJoints;
var
  LDef: IModelDef;
  LBounds: TGeoBounds;
  LJoints, LReference: TArray<TMd5JointMat>;
begin
  LDef := Parse(Base);
  LReference := FModel.Skeleton.ToAbsolute(FModel.DefaultPose);
  LJoints := LDef.SetupJoints(False, LBounds);
  Assert.AreEqual<Integer>(2, Length(LJoints));
  Assert.AreEqual(LReference[0].ToVec3.X + 1.0, LJoints[0].ToVec3.X, 0.0001, 'con l''offset');
  Assert.AreEqual(FModel.Bounds.Mins.X, LBounds.Mins.X, 0.0);
  LJoints := LDef.SetupJoints(True, LBounds);
  Assert.AreEqual(1.0, LJoints[0].ToVec3.X, 0.0001, 'al posto dell''origine');
  Assert.AreEqual(2.0, LJoints[0].ToVec3.Y, 0.0001);
end;

procedure TTestModelDefParser.DovrebbeDareListeVuoteSenzaModello;
var
  LDef: IModelDef;
  LBounds: TGeoBounds;
begin
  LDef := Parse('offset ( 1 1 1 )');
  Assert.IsFalse(LDef.Defaulted);
  Assert.AreEqual('', string(LDef.GetModelName));
  Assert.AreEqual('', string(LDef.GetJointName(0)));
  Assert.AreEqual<Integer>(-1, LDef.FindJoint('origin'));
  Assert.AreEqual<Integer>(0, Length(LDef.GetJointList('origin', FLog)));
  Assert.AreEqual<Integer>(0, Length(LDef.SetupJoints(False, LBounds)));
end;

procedure TTestModelDefParser.DovrebbeUsareLaFabbricaConLaLookupPermissiva;
var
  LParser: IModelDefParser;
  LDef: IModelDef;
begin
  LParser := TAnimFactory.CreateModelDefParser(FSource, FManager, nil, nil);
  LDef := LParser.Parse('m', 'm { mesh cube.md5mesh skin whatever anim idle1 cube.md5anim { frame 1 call anything frame 1 fx x frame 1 melee y } }');
  Assert.IsFalse(LDef.Defaulted);
  Assert.AreEqual<Integer>(3, LDef.GetAnimByIndex(1).FrameCommandCount);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAnimManager);
  TDUnitX.RegisterTestFixture(TTestAnim);
  TDUnitX.RegisterTestFixture(TTestFrameCommandParser);
  TDUnitX.RegisterTestFixture(TTestModelDefParser);

end.
