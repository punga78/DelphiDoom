{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the files of a Quake III       }
{  player (finder, MD3 source, loader of a whole player)                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Q3LoaderValues;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Q3Player.Intf,
  DelphiDoom.Models.Q3Player.Skin.Types,
  DelphiDoom.Models.Q3Player.Skin.Intf,
  DelphiDoom.Tests.Models.Q3PlayerSupport,
  DelphiDoom.Tests.Models.Q3SkinSupport;

type
  [TestFixture]
  [Category('models')]
  TTestModelsQ3LoaderValues = class(TObject)
  strict private
    FLog: TFakeQ3Log;
    FLogKeeper: ILog;
    FFiles: TFakeQ3Files;
    FFilesKeeper: IInterface;
    FLoader: IQ3PlayerModelLoader;
    FRequest: TQ3PlayerModelRequest;
    procedure AddPlayer(const AFolder: string);
    procedure AddSkins(const AFolder, ATeamFolder: string);
    function WarningsText: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeTrovareIFileDelleSkinSecondoLaSquadraEIlTipoDiPartita;
    [Test]
    procedure DovrebbeUsareLaCartellaDeiPersonaggiEQuellaDelleTeste;
    [Test]
    procedure DovrebbeTroncareIPercorsiA63CaratteriConUnAvviso;
    [Test]
    procedure DovrebbeIgnorareUnFileLungoZero;
    [Test]
    procedure DovrebbeSollevareUnErroreSeLaSondaManca;
    [Test]
    procedure DovrebbeLeggereUnMd3DaUnaSorgente;
    [Test]
    procedure DovrebbeDareNilPerUnMd3VuotoMancanteOCorrotto;
    [Test]
    procedure DovrebbeCaricareUnGiocatoreCompleto;
    [Test]
    procedure DovrebbeCaricareUnGiocatoreDallaCartellaDeiPersonaggi;
    [Test]
    procedure DovrebbeCaricareLaTestaDallaCartellaDelleTeste;
    [Test]
    procedure DovrebbeFallireSeUnModelloMancaConLoStessoAvvisoDelCodiceVero;
    [Test]
    procedure DovrebbeFallireSeUnaSkinMancaESenzaSquadra;
    [Test]
    procedure DovrebbeRiprovareLaSkinDellaSquadraPredefinitaTenendoQuelloTrovato;
    [Test]
    procedure DovrebbeFallireSeNemmenoLaSquadraPredefinitaHaLeSkin;
    [Test]
    procedure DovrebbeFallireSeManca1AnimazioneOLIcona;
    [Test]
    procedure DovrebbeSollevareUnErroreSeLAnimazioneEMalformata;
    [Test]
    procedure DovrebbeSollevareUnErroreSeMancaUnaDipendenza;
  end;

implementation

uses
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Models.Q3Player.FileFinder,
  DelphiDoom.Models.Q3Player.Md3ModelSource,
  DelphiDoom.Models.Q3Player.ModelLoader,
  DelphiDoom.Models.Q3Player.Factory;

procedure TTestModelsQ3LoaderValues.Setup;
begin
  FLog := TFakeQ3Log.Create;
  FLogKeeper := FLog;
  FFiles := TFakeQ3Files.Create;
  FFilesKeeper := FFiles;
  FLoader := TQ3PlayerFactory.CreateModelLoader(FFiles, FFiles, FLog);
  FRequest.Context.TeamGame := False;
  FRequest.Context.Team := qtFree;
  FRequest.ModelName := 'bob';
  FRequest.SkinName := 'default';
  FRequest.HeadModelName := '';
  FRequest.HeadSkinName := 'default';
  FRequest.TeamName := '';
end;

procedure TTestModelsQ3LoaderValues.TearDown;
begin
  FLoader := nil;
  FFilesKeeper := nil;
  FFiles := nil;
  FLogKeeper := nil;
  FLog := nil;
end;

function TTestModelsQ3LoaderValues.WarningsText: string;
begin
  Result := StringReplace(Trim(FLog.Warnings.Text), sLineBreak, ' | ', [rfReplaceAll]);
end;

// the three models of a player (one folder: models/players/bob or models/players/characters/bob) and its animation
procedure TTestModelsQ3LoaderValues.AddPlayer(const AFolder: string);
begin
  FFiles.Add(AFolder + '/lower.md3', BuildSkinnedMd3(2, ['tag_torso'], ['l_legs'], ['']));
  FFiles.Add(AFolder + '/upper.md3', BuildSkinnedMd3(2, ['tag_head', 'tag_weapon'], ['u_torso'], ['']));
  FFiles.Add(AFolder + '/head.md3', BuildSkinnedMd3(1, [], ['h_head'], ['']));
  FFiles.Add(AFolder + '/animation.cfg', ReadAnsiFile(Q3SkinDataPath('..\files\full.cfg')));
end;

// the skin and icon files of the default skin; ATeamFolder is "" or "Stroggs/"
procedure TTestModelsQ3LoaderValues.AddSkins(const AFolder, ATeamFolder: string);
begin
  FFiles.Add(AFolder + '/' + ATeamFolder + 'lower_default.skin', 'l_legs,models/bob/lower.tga');
  FFiles.Add(AFolder + '/' + ATeamFolder + 'upper_default.skin', 'u_torso,models/bob/upper.tga');
  FFiles.Add(AFolder + '/default/' + ATeamFolder + 'head_default.skin', 'h_head,models/bob/head.tga');
end;

procedure TTestModelsQ3LoaderValues.DovrebbeTrovareIFileDelleSkinSecondoLaSquadraEIlTipoDiPartita;
var
  LFinder: IQ3PlayerFileFinder;
  LContext: TQ3TeamContext;
  LFileName: AnsiString;
begin
  FFiles.Add('models/players/bob/lower_default_blue.skin', 'x');
  FFiles.Add('models/players/bob/lower_red.skin', 'x');
  FFiles.Add('models/players/bob/lower_default.skin', 'x');
  LFinder := TQ3PlayerFactory.CreateFileFinder(FFiles, FLog);
  LContext.TeamGame := True;
  LContext.Team := qtBlue;
  Assert.IsTrue(LFinder.FindModelFile(LContext, '', 'bob', 'default', 'lower', 'skin', LFileName));
  Assert.AreEqual('models/players/bob/lower_default_blue.skin', string(LFileName));
  // red, and the spectators too, are "red"
  LContext.Team := qtSpectator;
  Assert.IsTrue(LFinder.FindModelFile(LContext, '', 'bob', 'default', 'lower', 'skin', LFileName));
  Assert.AreEqual('models/players/bob/lower_red.skin', string(LFileName));
  // not a team game: "default" and the skin name, whatever the team
  LContext.TeamGame := False;
  LContext.Team := qtBlue;
  Assert.IsTrue(LFinder.FindModelFile(LContext, '', 'bob', 'default', 'lower', 'skin', LFileName));
  Assert.AreEqual('models/players/bob/lower_default.skin', string(LFileName));
  // nothing: the name left is the last that was tried
  Assert.IsFalse(LFinder.FindModelFile(LContext, '', 'bob', 'none', 'upper', 'skin', LFileName));
  Assert.AreEqual('models/players/characters/bob/upper_none.skin', string(LFileName));
  // with a folder of the team it is tried first
  FFiles.Add('models/players/bob/Stroggs/lower_default.skin', 'x');
  Assert.IsTrue(LFinder.FindModelFile(LContext, 'Stroggs/', 'bob', 'default', 'lower', 'skin', LFileName));
  Assert.AreEqual('models/players/bob/Stroggs/lower_default.skin', string(LFileName));
end;

procedure TTestModelsQ3LoaderValues.DovrebbeUsareLaCartellaDeiPersonaggiEQuellaDelleTeste;
var
  LFinder: IQ3PlayerFileFinder;
  LContext: TQ3TeamContext;
  LFileName: AnsiString;
begin
  FFiles.Add('models/players/characters/bob/upper_default.skin', 'x');
  FFiles.Add('models/players/heads/kate/default/icon_default.tga', 'x');
  FFiles.Add('models/players/heads/ann/head_default.skin', 'x');
  LContext.TeamGame := False;
  LContext.Team := qtFree;
  LFinder := TQ3PlayerFactory.CreateFileFinder(FFiles, FLog);
  Assert.IsTrue(LFinder.FindModelFile(LContext, '', 'bob', 'default', 'upper', 'skin', LFileName));
  Assert.AreEqual('models/players/characters/bob/upper_default.skin', string(LFileName));
  // the star: only the folder of the heads, the star is not part of the name
  Assert.IsTrue(LFinder.FindHeadFile(LContext, '', '*kate', 'default', 'icon', 'tga', LFileName));
  Assert.AreEqual('models/players/heads/kate/default/icon_default.tga', string(LFileName));
  // no star: the folder of the player first, then the one of the heads
  Assert.IsTrue(LFinder.FindHeadFile(LContext, '', 'ann', 'default', 'head', 'skin', LFileName));
  Assert.AreEqual('models/players/heads/ann/head_default.skin', string(LFileName));
  Assert.IsFalse(LFinder.FindHeadFile(LContext, '', '*kate', 'default', 'head', 'skin', LFileName));
end;

procedure TTestModelsQ3LoaderValues.DovrebbeTroncareIPercorsiA63CaratteriConUnAvviso;
var
  LFinder: IQ3PlayerFileFinder;
  LContext: TQ3TeamContext;
  LFileName: AnsiString;
begin
  LContext.TeamGame := False;
  LContext.Team := qtFree;
  LFinder := TQ3PlayerFactory.CreateFileFinder(FFiles, FLog);
  Assert.IsFalse(LFinder.FindModelFile(LContext, '', AnsiString(StringOfChar('m', 50)), 'default', 'lower', 'skin',
    LFileName));
  Assert.AreEqual<Integer>(63, Length(LFileName));
  Assert.IsTrue(FLog.Warnings.Count > 0);
  Assert.IsTrue(FLog.Warnings[0].StartsWith('Com_sprintf: overflow of'));
  // and a log is not required
  Assert.IsFalse(TQ3PlayerFactory.CreateFileFinder(FFiles, nil).FindModelFile(LContext, '',
    AnsiString(StringOfChar('m', 50)), 'default', 'lower', 'skin', LFileName));
end;

procedure TTestModelsQ3LoaderValues.DovrebbeIgnorareUnFileLungoZero;
var
  LContext: TQ3TeamContext;
  LFileName: AnsiString;
begin
  FFiles.Add('models/players/bob/lower_default.skin', '');
  LContext.TeamGame := False;
  LContext.Team := qtFree;
  // trap_FS_FOpenFile > 0: an empty file does not exist for CG_FileExists
  Assert.IsFalse(TQ3PlayerFactory.CreateFileFinder(FFiles, FLog).FindModelFile(LContext, '', 'bob', 'default',
    'lower', 'skin', LFileName));
end;

procedure TTestModelsQ3LoaderValues.DovrebbeSollevareUnErroreSeLaSondaManca;
begin
  Assert.IsTrue(Raises(
    procedure
    begin
      TQ3PlayerFileFinder.Create(nil, nil);
    end, EArgumentNilException));
end;

procedure TTestModelsQ3LoaderValues.DovrebbeLeggereUnMd3DaUnaSorgente;
var
  LModel: IMd3Model;
begin
  FFiles.Add('models/a.md3', BuildSkinnedMd3(3, ['tag_a', 'tag_b'], ['one', 'two'], ['sh', '']));
  LModel := TQ3PlayerFactory.CreateModelSource(FFiles, FLog).RegisterModel('models/a.md3');
  Assert.AreEqual(3, LModel.NumFrames);
  Assert.AreEqual(2, LModel.NumTags);
  Assert.AreEqual(2, LModel.NumSurfaces);
  Assert.AreEqual(0, FLog.Warnings.Count);
end;

procedure TTestModelsQ3LoaderValues.DovrebbeDareNilPerUnMd3VuotoMancanteOCorrotto;
var
  LSource: IQ3ModelSource;
begin
  FFiles.Add('models/bad.md3', 'not a model, but long enough to have a header, so the magic is wrong' +
    AnsiString(StringOfChar(' ', 100)));
  LSource := TQ3PlayerFactory.CreateModelSource(FFiles, FLog);
  Assert.IsNull(LSource.RegisterModel(''));
  Assert.IsNull(LSource.RegisterModel(AnsiString(StringOfChar('a', 64))));
  Assert.IsNull(LSource.RegisterModel('models/missing.md3'));
  Assert.IsNull(LSource.RegisterModel('models/bad.md3'));
  Assert.AreEqual(4, FLog.Warnings.Count);
  Assert.AreEqual(SQ3ModelEmptyName, FLog.Warnings[0]);
  Assert.AreEqual(SQ3ModelNameTooLong, FLog.Warnings[1]);
  Assert.IsTrue(FLog.Warnings[3].StartsWith('RE_RegisterModel: couldn''t load models/bad.md3'));
  Assert.IsNull(TQ3PlayerFactory.CreateModelSource(FFiles, nil).RegisterModel(''));
  Assert.IsTrue(Raises(
    procedure
    begin
      TQ3Md3ModelSource.Create(nil, nil, nil);
    end, EArgumentNilException));
end;

procedure TTestModelsQ3LoaderValues.DovrebbeCaricareUnGiocatoreCompleto;
var
  LPlayer: IQ3PlayerModel;
begin
  AddPlayer('models/players/bob');
  AddSkins('models/players/bob', '');
  FFiles.Add('models/players/bob/default/icon_default.tga', 'icon');
  Assert.IsTrue(FLoader.Load(FRequest, LPlayer), WarningsText);
  Assert.AreEqual(2, LPlayer.LegsModel.NumFrames);
  Assert.AreEqual(2, LPlayer.TorsoModel.NumTags);
  Assert.AreEqual(1, LPlayer.HeadModel.NumFrames);
  Assert.AreEqual('models/players/bob/lower_default.skin', string(LPlayer.LegsSkin.Name));
  Assert.AreEqual('models/players/bob/upper_default.skin', string(LPlayer.TorsoSkin.Name));
  Assert.AreEqual('models/players/bob/default/head_default.skin', string(LPlayer.HeadSkin.Name));
  Assert.AreEqual('models/bob/head.tga', string(LPlayer.HeadSkin.Surfaces[0].Shader));
  Assert.AreEqual('models/players/bob/default/icon_default.tga', string(LPlayer.IconFile));
  Assert.AreEqual(Ord(qgMale), Ord(LPlayer.Animation.Gender));
  Assert.AreEqual(0, FLog.Warnings.Count);
end;

procedure TTestModelsQ3LoaderValues.DovrebbeCaricareUnGiocatoreDallaCartellaDeiPersonaggi;
var
  LPlayer: IQ3PlayerModel;
begin
  // the legs, the torso, their skins and the animation are looked for in "characters/", the head never is
  AddPlayer('models/players/characters/bob');
  FFiles.Add('models/players/bob/head.md3', BuildSkinnedMd3(1, [], ['h_head'], ['']));
  FFiles.Add('models/players/characters/bob/lower_default.skin', 'l_legs,a');
  FFiles.Add('models/players/characters/bob/upper_default.skin', 'u_torso,b');
  FFiles.Add('models/players/bob/default/head_default.skin', 'h_head,c');
  FFiles.Add('models/players/bob/default/icon_default.tga', 'icon');
  Assert.IsTrue(FLoader.Load(FRequest, LPlayer), WarningsText);
  Assert.AreEqual('models/players/characters/bob/lower_default.skin', string(LPlayer.LegsSkin.Name));
  Assert.AreEqual('models/players/bob/default/icon_default.tga', string(LPlayer.IconFile));
end;

procedure TTestModelsQ3LoaderValues.DovrebbeCaricareLaTestaDallaCartellaDelleTeste;
var
  LPlayer: IQ3PlayerModel;
begin
  AddPlayer('models/players/bob');
  FFiles.Add('models/players/bob/head.md3', '');
  // the head "kate" is its own model in the folder of the heads, with the star or not
  FFiles.Add('models/players/heads/kate/kate.md3', BuildSkinnedMd3(1, [], ['h_head'], ['']));
  FFiles.Add('models/players/bob/lower_default.skin', 'l_legs,a');
  FFiles.Add('models/players/bob/upper_default.skin', 'u_torso,b');
  FFiles.Add('models/players/heads/kate/default/head_default.skin', 'h_head,c');
  FFiles.Add('models/players/heads/kate/default/icon_default.tga', 'icon');
  FRequest.HeadModelName := '*kate';
  Assert.IsTrue(FLoader.Load(FRequest, LPlayer), WarningsText);
  Assert.AreEqual('c', string(LPlayer.HeadSkin.Surfaces[0].Shader));
  // without the star the head of the player is looked for first, then the folder of the heads
  FRequest.HeadModelName := 'kate';
  Assert.IsTrue(FLoader.Load(FRequest, LPlayer), WarningsText);
  Assert.AreEqual(1, LPlayer.HeadModel.NumFrames);
end;

procedure TTestModelsQ3LoaderValues.DovrebbeFallireSeUnModelloMancaConLoStessoAvvisoDelCodiceVero;
var
  LPlayer: IQ3PlayerModel;
begin
  Assert.IsFalse(FLoader.Load(FRequest, LPlayer));
  Assert.IsNull(LPlayer);
  Assert.AreEqual('Failed to load model file models/players/characters/bob/lower.md3',
    FLog.Warnings[FLog.Warnings.Count - 1]);
  FFiles.Add('models/players/bob/lower.md3', BuildSkinnedMd3(1, ['tag_torso'], ['a'], ['']));
  FLog.Warnings.Clear;
  Assert.IsFalse(FLoader.Load(FRequest, LPlayer));
  Assert.AreEqual('Failed to load model file models/players/characters/bob/upper.md3',
    FLog.Warnings[FLog.Warnings.Count - 1]);
  FFiles.Add('models/players/bob/upper.md3', BuildSkinnedMd3(1, ['tag_torso'], ['a'], ['']));
  FLog.Warnings.Clear;
  Assert.IsFalse(FLoader.Load(FRequest, LPlayer));
  // the second try uses the head model of the request, which is empty: the original names "heads//.md3"
  Assert.AreEqual('Failed to load model file models/players/heads//.md3', FLog.Warnings[FLog.Warnings.Count - 1]);
end;

procedure TTestModelsQ3LoaderValues.DovrebbeFallireSeUnaSkinMancaESenzaSquadra;
var
  LPlayer: IQ3PlayerModel;
begin
  AddPlayer('models/players/bob');
  FFiles.Add('models/players/bob/lower_default.skin', 'l_legs,a');
  Assert.IsFalse(FLoader.Load(FRequest, LPlayer));
  Assert.IsTrue(FLog.Warnings.Text.Contains('Torso skin load failure: models/players/characters/bob/upper_default.skin'));
  Assert.IsTrue(FLog.Warnings.Text.Contains('Head skin load failure: models/players/heads/bob/head_default.skin'));
  Assert.AreEqual('Failed to load skin file: bob : default, bob : default', FLog.Warnings[FLog.Warnings.Count - 1]);
end;

procedure TTestModelsQ3LoaderValues.DovrebbeRiprovareLaSkinDellaSquadraPredefinitaTenendoQuelloTrovato;
var
  LPlayer: IQ3PlayerModel;
begin
  AddPlayer('models/players/bob');
  FFiles.Add('models/players/bob/default/icon_default.tga', 'icon');
  // the team folder "alpha/" has only the legs, "Pagans/" the torso and the head: the legs found at
  // the first try stay (the clientInfo_t keeps them), a skin found again would take their place
  FFiles.Add('models/players/bob/alpha/lower_default.skin', 'l_legs,first');
  FFiles.Add('models/players/bob/Pagans/upper_default.skin', 'u_torso,t');
  FFiles.Add('models/players/bob/default/Pagans/head_default.skin', 'h_head,h');
  FRequest.TeamName := 'alpha/';
  FRequest.Context.TeamGame := False;
  FRequest.Context.Team := qtBlue;
  Assert.IsTrue(FLoader.Load(FRequest, LPlayer), WarningsText);
  Assert.AreEqual('first', string(LPlayer.LegsSkin.Surfaces[0].Shader));
  Assert.AreEqual('t', string(LPlayer.TorsoSkin.Surfaces[0].Shader));
  Assert.IsTrue(FLog.Warnings.Text.Contains('Failed to load skin file: alpha/ : bob : default, bob : default'));
end;

procedure TTestModelsQ3LoaderValues.DovrebbeFallireSeNemmenoLaSquadraPredefinitaHaLeSkin;
var
  LPlayer: IQ3PlayerModel;
begin
  AddPlayer('models/players/bob');
  FRequest.TeamName := 'alpha/';
  Assert.IsFalse(FLoader.Load(FRequest, LPlayer));
  Assert.AreEqual('Failed to load skin file: Stroggs/ : bob : default, bob : default',
    FLog.Warnings[FLog.Warnings.Count - 1]);
  FRequest.Context.Team := qtBlue;
  FLog.Warnings.Clear;
  Assert.IsFalse(FLoader.Load(FRequest, LPlayer));
  Assert.AreEqual('Failed to load skin file: Pagans/ : bob : default, bob : default',
    FLog.Warnings[FLog.Warnings.Count - 1]);
end;

procedure TTestModelsQ3LoaderValues.DovrebbeFallireSeManca1AnimazioneOLIcona;
var
  LPlayer: IQ3PlayerModel;
begin
  AddPlayer('models/players/bob');
  AddSkins('models/players/bob', '');
  // no icon: the original fails without a message
  FLog.Warnings.Clear;
  Assert.IsFalse(FLoader.Load(FRequest, LPlayer));
  Assert.AreEqual(0, FLog.Warnings.Count);
  FFiles.Add('models/players/bob/default/icon_default.tga', 'icon');
  FFiles.Add('models/players/bob/animation.cfg', '');
  Assert.IsFalse(FLoader.Load(FRequest, LPlayer));
  Assert.AreEqual('Failed to load animation file models/players/characters/bob/animation.cfg',
    FLog.Warnings[FLog.Warnings.Count - 1]);
end;

procedure TTestModelsQ3LoaderValues.DovrebbeSollevareUnErroreSeLAnimazioneEMalformata;
var
  LPlayer: IQ3PlayerModel;
begin
  AddPlayer('models/players/bob');
  AddSkins('models/players/bob', '');
  FFiles.Add('models/players/bob/default/icon_default.tga', 'icon');
  // a fatal error in the game (CG_Error)
  FFiles.Add('models/players/bob/animation.cfg', 'sex m'#10'0 1 0 15'#10);
  Assert.IsTrue(Raises(
    procedure
    begin
      FLoader.Load(FRequest, LPlayer);
    end, EQ3PlayerException));
end;

procedure TTestModelsQ3LoaderValues.DovrebbeSollevareUnErroreSeMancaUnaDipendenza;
begin
  Assert.IsTrue(Raises(
    procedure
    begin
      TQ3PlayerModelLoader.Create(nil, TQ3PlayerFactory.CreateSkinRegistry(FFiles, nil),
        TQ3PlayerFactory.CreateFileFinder(FFiles, nil), TQ3PlayerFactory.CreateLoader(FFiles, nil), nil);
    end, EArgumentNilException));
  Assert.IsTrue(Raises(
    procedure
    begin
      TQ3PlayerModelLoader.Create(TQ3PlayerFactory.CreateModelSource(FFiles, nil), nil,
        TQ3PlayerFactory.CreateFileFinder(FFiles, nil), TQ3PlayerFactory.CreateLoader(FFiles, nil), nil);
    end, EArgumentNilException));
  Assert.IsTrue(Raises(
    procedure
    begin
      TQ3PlayerModelLoader.Create(TQ3PlayerFactory.CreateModelSource(FFiles, nil),
        TQ3PlayerFactory.CreateSkinRegistry(FFiles, nil), nil, TQ3PlayerFactory.CreateLoader(FFiles, nil), nil);
    end, EArgumentNilException));
  Assert.IsTrue(Raises(
    procedure
    begin
      TQ3PlayerModelLoader.Create(TQ3PlayerFactory.CreateModelSource(FFiles, nil),
        TQ3PlayerFactory.CreateSkinRegistry(FFiles, nil), TQ3PlayerFactory.CreateFileFinder(FFiles, nil), nil, nil);
    end, EArgumentNilException));
end;

end.
