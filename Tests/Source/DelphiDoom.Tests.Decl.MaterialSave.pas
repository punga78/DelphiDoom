{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the material declaration - Save and ReloadImages       }
{                                                                              }
{  idMaterial::Save is ReplaceSourceFileText (checked on the memory source of  }
{  the manager); ReloadImages is the loop of idMaterial::ReloadImages with a   }
{  reloader that remembers the images it is given (no image is loaded).        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.MaterialSave;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Material.Types,
  DelphiDoom.Decl.Material.Intf, DelphiDoom.Tests.Decl.MaterialSupport;

type
  /// <summary>An IMaterialImageReloader that keeps the names it was asked to reload and the force flag</summary>
  TRecordingImageReloader = class(TInterfacedObject, IMaterialImageReloader)
  strict private
    FNames: TStringList;
    FForced: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ReloadImage(const AImage: TMaterialImageReference; const AForce: Boolean);
    property Names: TStringList read FNames;
    property Forced: Integer read FForced;
  end;

  [TestFixture]
  [Category('decl')]
  TTestDeclMaterialSave = class(TObject)
  strict private
    FKit: TMaterialTestKit;
    function Persistence(const AName: AnsiString): IMaterialPersistence;
    function Names(const AReloader: TRecordingImageReloader): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLInterfacciaDiSalvataggio;
    [Test]
    procedure DovrebbeSalvareIlTestoDelMaterialNelFile;
    [Test]
    procedure DovrebbeIgnorareIlNomeDelFile;
    [Test]
    procedure DovrebbeSalvareUnMaterialNuovo;
    [Test]
    procedure DovrebbeDareFalsoSeIlFileECambiatoFuoriDalMotore;
    [Test]
    procedure DovrebbeRicaricareLeImmaginiDegliStage;
    [Test]
    procedure DovrebbeRicaricareLeImmaginiDelProgrammaAlPostoDiQuelleDelloStage;
    [Test]
    procedure DovrebbePassareIlForceAlRicaricatore;
    [Test]
    procedure DovrebbeSaltareGliStageSenzaImmagine;
    [Test]
    procedure DovrebbeRifiutareUnRicaricatoreNil;
    [Test]
    procedure DovrebbeRicaricareLImmagineImplicitaDiUnMaterialSenzaTesto;
  end;

implementation

uses
  DelphiDoom.Decl.Types;

const
  MATERIALS =
    'm/two'#10'{'#10#9'{'#10#9#9'blend add'#10#9#9'map textures/a'#10#9'}'#10#9'{'#10#9#9'blend blend'#10#9#9'map textures/b'#10#9'}'#10'}'#10 +
    'm/prog'#10'{'#10#9'{'#10#9#9'blend add'#10#9#9'program glprogs/foo.vfp'#10#9#9'fragmentMap 0 textures/f0'#10 +
    #9#9'fragmentMap 1 textures/f1'#10#9'}'#10#9'{'#10#9#9'blend blend'#10#9#9'map textures/after'#10#9'}'#10'}'#10 +
    'm/video'#10'{'#10#9'{'#10#9#9'blend add'#10#9#9'videoMap movie.roq'#10#9'}'#10#9'{'#10#9#9'blend blend'#10#9#9'map textures/c'#10#9'}'#10'}'#10;

{ TRecordingImageReloader }

constructor TRecordingImageReloader.Create;
begin
  inherited Create;
  FNames := TStringList.Create;
end;

destructor TRecordingImageReloader.Destroy;
begin
  FNames.Free;
  inherited Destroy;
end;

procedure TRecordingImageReloader.ReloadImage(const AImage: TMaterialImageReference; const AForce: Boolean);
begin
  FNames.Add(string(AImage.Name));
  if AForce then
    Inc(FForced);
end;

{ TTestDeclMaterialSave }

procedure TTestDeclMaterialSave.Setup;
begin
  FKit := TMaterialTestKit.Create(MATERIALS);
end;

procedure TTestDeclMaterialSave.TearDown;
begin
  FKit.Free;
end;

function TTestDeclMaterialSave.Persistence(const AName: AnsiString): IMaterialPersistence;
begin
  Assert.IsTrue(Supports(FKit.Decl(AName), IMaterialPersistence, Result), 'the material has no persistence');
end;

function TTestDeclMaterialSave.Names(const AReloader: TRecordingImageReloader): string;
begin
  Result := string.Join(',', AReloader.Names.ToStringArray);
end;

procedure TTestDeclMaterialSave.DovrebbeDareLInterfacciaDiSalvataggio;
begin
  Assert.IsNotNull(Persistence('m/two'));
end;

procedure TTestDeclMaterialSave.DovrebbeSalvareIlTestoDelMaterialNelFile;
var
  LDecl: IDecl;
  LText: AnsiString;
  LTimestamp: Int64;
begin
  LDecl := FKit.Decl('m/two');
  LDecl.SetText('m/two { { blend add map textures/changed } }');
  Assert.IsTrue(Persistence('m/two').Save);
  Assert.IsTrue(FKit.Kit.Source.TryReadFile('materials/test.mtr', LText, LTimestamp));
  Assert.IsTrue(string(LText).Contains('textures/changed'), string(LText));
  // the other materials of the file stay where they were
  Assert.IsTrue(string(LText).Contains('m/prog'));
  Assert.IsTrue(string(LText).Contains('table sinTable'));
  // the old text of the material is gone (its second stage is the only place that names textures/b)
  Assert.IsFalse(string(LText).Contains('textures/b'));
end;

procedure TTestDeclMaterialSave.DovrebbeIgnorareIlNomeDelFile;
var
  LText: AnsiString;
  LTimestamp: Int64;
begin
  FKit.Decl('m/two').SetText('m/two { { blend add map textures/changed } }');
  // the file name of the original is not used: the text goes to the file the material came from
  Assert.IsTrue(Persistence('m/two').Save('materials/other.mtr'));
  Assert.IsTrue(FKit.Kit.Source.TryReadFile('materials/test.mtr', LText, LTimestamp));
  Assert.IsTrue(string(LText).Contains('textures/changed'));
  Assert.IsFalse(FKit.Kit.Source.TryReadFile('materials/other.mtr', LText, LTimestamp));
end;

procedure TTestDeclMaterialSave.DovrebbeSalvareUnMaterialNuovo;
var
  LDecl: IDecl;
  LText: AnsiString;
  LTimestamp: Int64;
begin
  LDecl := FKit.Kit.Manager.CreateNewDecl(DECL_MATERIAL, 'm/created', 'materials/created.mtr');
  Assert.IsTrue(Supports(LDecl, IMaterialPersistence));
  Assert.IsTrue((LDecl as IMaterialPersistence).Save);
  Assert.IsTrue(FKit.Kit.Source.TryReadFile('materials/created.mtr', LText, LTimestamp));
  Assert.IsTrue(string(LText).Contains('material m/created'), string(LText));
end;

procedure TTestDeclMaterialSave.DovrebbeDareFalsoSeIlFileECambiatoFuoriDalMotore;
var
  LText: AnsiString;
  LTimestamp: Int64;
begin
  FKit.Decl('m/two');
  FKit.Kit.Source.TryReadFile('materials/test.mtr', LText, LTimestamp);
  FKit.Kit.Source.Add('materials/test.mtr', LText + #10'// someone else wrote this'#10);
  FKit.Decl('m/two').SetText('m/two { }');
  Assert.IsFalse(Persistence('m/two').Save);
  Assert.IsTrue(FKit.LogText.Contains('has been modified outside of the engine'), FKit.LogText);
end;

procedure TTestDeclMaterialSave.DovrebbeRicaricareLeImmaginiDegliStage;
var
  LReloader: TRecordingImageReloader;
  LIntf: IMaterialImageReloader;
begin
  LReloader := TRecordingImageReloader.Create;
  LIntf := LReloader;
  Persistence('m/two').ReloadImages(LIntf, False);
  Assert.AreEqual('textures/a,textures/b', Names(LReloader));
  Assert.AreEqual(0, LReloader.Forced);
end;

procedure TTestDeclMaterialSave.DovrebbeRicaricareLeImmaginiDelProgrammaAlPostoDiQuelleDelloStage;
var
  LReloader: TRecordingImageReloader;
  LIntf: IMaterialImageReloader;
begin
  LReloader := TRecordingImageReloader.Create;
  LIntf := LReloader;
  Persistence('m/prog').ReloadImages(LIntf, False);
  // the stage with a program gives its fragment images, then the plain stage its map
  Assert.AreEqual('textures/f0,textures/f1,textures/after', Names(LReloader));
end;

procedure TTestDeclMaterialSave.DovrebbePassareIlForceAlRicaricatore;
var
  LReloader: TRecordingImageReloader;
  LIntf: IMaterialImageReloader;
begin
  LReloader := TRecordingImageReloader.Create;
  LIntf := LReloader;
  Persistence('m/two').ReloadImages(LIntf, True);
  Assert.AreEqual(2, LReloader.Forced);
end;

procedure TTestDeclMaterialSave.DovrebbeSaltareGliStageSenzaImmagine;
var
  LReloader: TRecordingImageReloader;
  LIntf: IMaterialImageReloader;
begin
  LReloader := TRecordingImageReloader.Create;
  LIntf := LReloader;
  Persistence('m/video').ReloadImages(LIntf, False);
  // the video stage has no image, only the second stage has
  Assert.AreEqual('textures/c', Names(LReloader));
end;

procedure TTestDeclMaterialSave.DovrebbeRifiutareUnRicaricatoreNil;
var
  LPersistence: IMaterialPersistence;
begin
  LPersistence := Persistence('m/two');
  Assert.WillRaise(procedure begin LPersistence.ReloadImages(nil, False); end, EArgumentNilException);
end;

procedure TTestDeclMaterialSave.DovrebbeRicaricareLImmagineImplicitaDiUnMaterialSenzaTesto;
var
  LReloader: TRecordingImageReloader;
  LIntf: IMaterialImageReloader;
begin
  LReloader := TRecordingImageReloader.Create;
  LIntf := LReloader;
  // a name with no definition gets the implicit material that blends the image of the same name
  Persistence('textures/implicit/wall').ReloadImages(LIntf, False);
  Assert.AreEqual('textures/implicit/wall', Names(LReloader));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclMaterialSave);

end.
