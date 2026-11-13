{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the source, the factory and the maker of the scenes    }
{  of FLIC animations (issue #199)                                             }
{                                                                              }
{  The folder source reads files of a temporary folder made by each test and   }
{  deleted by it; the files are small FLC built in memory.                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.FlicSceneFactory;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Cinematic.Flic.Scene.Intf;

type
  [TestFixture]
  [Category('cinematic')]
  TTestFlicSceneFactory = class(TObject)
  strict private
    FFolder: string;
    function Animation: TBytes;
    procedure Save(const AFileName: string; const ABytes: TBytes);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereUnaAnimazioneDallaCartellaConLEstensione;
    [Test]
    procedure DovrebbeDareFalsoPerUnaAnimazioneCheNonCe;
    [Test]
    procedure DovrebbeNonLeggereNomiCheEscono;
    [Test]
    procedure DovrebbeNonLeggereUnNomeVuoto;
    [Test]
    procedure DovrebbeCrearelaScenaDiUnaAnimazioneChePuoGiocare;
    [Test]
    procedure DovrebbeDareNilPerUnaAnimazioneMancante;
    [Test]
    procedure DovrebbeSollevareUnErroreSeIlFileNonEUnFlic;
    [Test]
    procedure DovrebbeRifiutareUnaSorgenteNulla;
    [Test]
    procedure DovrebbeFareLeScenePerNomeConIlProduttore;
    [Test]
    procedure DovrebbeFareUnaScenaDaiByte;
  end;

implementation

uses
  System.IOUtils,
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.Flic.Types,
  DelphiDoom.Cinematic.Flic.Scene.Types,
  DelphiDoom.Cinematic.Flic.SceneFactory,
  DelphiDoom.Tests.Cinematic.FlicSupport;

{ TTestFlicSceneFactory }

procedure TTestFlicSceneFactory.Setup;
begin
  FFolder := TPath.Combine(TPath.GetTempPath, 'ddflic-' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FFolder);
end;

procedure TTestFlicSceneFactory.TearDown;
begin
  if TDirectory.Exists(FFolder) then
    TDirectory.Delete(FFolder, True);
end;

function TTestFlicSceneFactory.Animation: TBytes;
var
  LBuilder: TFlicTestBuilder;
begin
  LBuilder := TFlicTestBuilder.Create(4, 2, False, 100);
  try
    LBuilder.Frame([TFlicTestBuilder.Color256(0, [0, 0, 0, 1, 0, 0]), TFlicTestBuilder.ByteRun(4, [1, 1])]);
    LBuilder.Frame([TFlicTestBuilder.ByteRun(4, [0, 0])]);
    Result := LBuilder.ToBytes;
  finally
    LBuilder.Free;
  end;
end;

procedure TTestFlicSceneFactory.Save(const AFileName: string; const ABytes: TBytes);
begin
  TFile.WriteAllBytes(TPath.Combine(FFolder, AFileName), ABytes);
end;

procedure TTestFlicSceneFactory.DovrebbeLeggereUnaAnimazioneDallaCartellaConLEstensione;
var
  LSource: IFlicSource;
  LBytes: TBytes;
begin
  Save('CAVE1.WAR', Animation);
  LSource := TFlicSceneFactory.CreateFolderSource(FFolder, '.WAR');
  Assert.IsTrue(LSource.TryRead('CAVE1', LBytes));
  Assert.AreEqual<Integer>(Length(Animation), Length(LBytes));
end;

procedure TTestFlicSceneFactory.DovrebbeDareFalsoPerUnaAnimazioneCheNonCe;
var
  LBytes: TBytes;
begin
  Assert.IsFalse(TFlicSceneFactory.CreateFolderSource(FFolder, '.WAR').TryRead('HMAP01', LBytes));
  Assert.AreEqual<Integer>(0, Length(LBytes));
end;

procedure TTestFlicSceneFactory.DovrebbeNonLeggereNomiCheEscono;
var
  LSource: IFlicSource;
  LBytes: TBytes;
  LName: string;
begin
  Save('CAVE1.WAR', Animation);
  TFile.WriteAllBytes(TPath.Combine(TPath.GetDirectoryName(FFolder), 'OUTSIDE.WAR'), Animation);
  try
    LSource := TFlicSceneFactory.CreateFolderSource(FFolder, '.WAR');
    for LName in ['..\OUTSIDE', '../OUTSIDE', '..', 'C:\CAVE1', 'SUB\CAVE1', 'CAVE1:x', 'CA*', 'CA?E1', 'A|B'] do
      Assert.IsFalse(LSource.TryRead(LName, LBytes), LName);
  finally
    TFile.Delete(TPath.Combine(TPath.GetDirectoryName(FFolder), 'OUTSIDE.WAR'));
  end;
end;

procedure TTestFlicSceneFactory.DovrebbeNonLeggereUnNomeVuoto;
var
  LBytes: TBytes;
begin
  Save('.WAR', Animation);
  Assert.IsFalse(TFlicSceneFactory.CreateFolderSource(FFolder, '.WAR').TryRead('', LBytes));
end;

procedure TTestFlicSceneFactory.DovrebbeCrearelaScenaDiUnaAnimazioneChePuoGiocare;
var
  LScene: IFlicScene;
  LFrame: TFlicSceneFrame;
begin
  Save('CAVE1.WAR', Animation);
  LScene := TFlicSceneFactory.TryCreateScene('CAVE1', TFlicSceneFactory.CreateFolderSource(FFolder, '.WAR'),
    TFlicSceneOptions.Default, nil);
  Assert.IsNotNull(LScene);
  Assert.AreEqual('CAVE1', LScene.Name);
  LFrame := LScene.Update(0, False);
  Assert.AreEqual<Integer>(4, LFrame.Image.Width);
  Assert.AreEqual<Integer>(Ord(fssPlaying), Ord(LFrame.State));
  Assert.AreEqual<Integer>(Ord(fssEnded), Ord(LScene.Update(500, False).State));
end;

procedure TTestFlicSceneFactory.DovrebbeDareNilPerUnaAnimazioneMancante;
begin
  Assert.IsNull(TFlicSceneFactory.TryCreateScene('LOSE1', TFlicSceneFactory.CreateFolderSource(FFolder, '.WAR'),
    TFlicSceneOptions.Default, nil));
end;

procedure TTestFlicSceneFactory.DovrebbeSollevareUnErroreSeIlFileNonEUnFlic;
begin
  Save('BROKEN.WAR', TFlicTestBuilder.Bytes([1, 2, 3, 4, 5, 6, 7, 8]));
  Assert.WillRaise(
    procedure
    begin
      TFlicSceneFactory.TryCreateScene('BROKEN', TFlicSceneFactory.CreateFolderSource(FFolder, '.WAR'),
        TFlicSceneOptions.Default, nil);
    end, EFlicInvalidDataException);
end;

procedure TTestFlicSceneFactory.DovrebbeRifiutareUnaSorgenteNulla;
begin
  Assert.WillRaise(
    procedure
    begin
      TFlicSceneFactory.TryCreateScene('X', nil, TFlicSceneOptions.Default, nil);
    end, ECinematicException);
  Assert.WillRaise(
    procedure
    begin
      TFlicSceneFactory.CreateMaker(nil);
    end, ECinematicException);
end;

procedure TTestFlicSceneFactory.DovrebbeFareLeScenePerNomeConIlProduttore;
var
  LMaker: IFlicSceneMaker;
begin
  Save('CAVE1.WAR', Animation);
  LMaker := TFlicSceneFactory.CreateMaker(TFlicSceneFactory.CreateFolderSource(FFolder, '.WAR'));
  Assert.IsNotNull(LMaker.TryCreateScene('CAVE1', TFlicSceneOptions.Default, nil));
  Assert.IsNull(LMaker.TryCreateScene('CAVE2', TFlicSceneOptions.Default, nil));
end;

procedure TTestFlicSceneFactory.DovrebbeFareUnaScenaDaiByte;
var
  LScene: IFlicScene;
begin
  LScene := TFlicSceneFactory.CreateSceneFromBytes('MEM', Animation, TFlicSceneOptions.Default, nil);
  Assert.AreEqual('MEM', LScene.Name);
  Assert.AreEqual<Integer>(Ord(fssPlaying), Ord(LScene.Update(0, False).State));
end;

end.
