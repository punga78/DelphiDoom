{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the platform library - the folder of the data           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Platform.DataFolder;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework,
  DelphiDoom.Platform.DataFolder.Intf;

type
  /// <summary>A disk that is a list of folders; the ones in FWithGameFiles have the files of a game</summary>
  TFakeDataFolderProbe = class(TInterfacedObject, IDataFolderProbe)
  public
    Folders: TStringList;
    WithGameFiles: TStringList;
    constructor Create;
    destructor Destroy; override;
    function FolderExists(const AFolder: string): Boolean;
    function HasGameFiles(const AFolder: string): Boolean;
    function FullPath(const AFolder: string): string;
  end;

  [TestFixture]
  [Category('platform')]
  TTestPlatformDataFolder = class(TObject)
  private
    FProbe: TFakeDataFolderProbe;
    FProbeIntf: IDataFolderProbe;
    FLocator: IDataFolderLocator;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeUsareLaCartellaChiestaConData;
    [Test]
    procedure DovrebbeSollevareSeLaCartellaChiestaManca;
    [Test]
    procedure DovrebbeUsareLaCartellaDellExeSeHaIDatiDelGioco;
    [Test]
    procedure DovrebbeTrovareBinGiocoDaBinPiattaformaConfigurazioneGioco;
    [Test]
    procedure DovrebbeTrovareBinPerUnProgrammaSenzaArea;
    [Test]
    procedure DovrebbeFunzionareConWin64EDebug;
    [Test]
    procedure DovrebbeFunzionareAQualsiasiProfondita;
    [Test]
    procedure DovrebbeTenereLaCartellaDellExeSeLaCartellaDeiDatiManca;
    [Test]
    procedure DovrebbeTenereLaCartellaDellExeFuoriDalLayout;
    [Test]
    procedure NonDovrebbeAccettareUnaSondaNil;
  end;

implementation

uses
  DelphiDoom.Platform.DataFolder.Factory;

{ TFakeDataFolderProbe }

constructor TFakeDataFolderProbe.Create;
begin
  inherited Create;
  Folders := TStringList.Create;
  WithGameFiles := TStringList.Create;
end;

destructor TFakeDataFolderProbe.Destroy;
begin
  Folders.Free;
  WithGameFiles.Free;
  inherited Destroy;
end;

function TFakeDataFolderProbe.FolderExists(const AFolder: string): Boolean;
begin
  Result := Folders.IndexOf(AFolder) >= 0;
end;

function TFakeDataFolderProbe.HasGameFiles(const AFolder: string): Boolean;
begin
  Result := WithGameFiles.IndexOf(AFolder) >= 0;
end;

function TFakeDataFolderProbe.FullPath(const AFolder: string): string;
begin
  Result := 'C:\work\' + AFolder;
end;

{ TTestPlatformDataFolder }

procedure TTestPlatformDataFolder.Setup;
begin
  FProbe := TFakeDataFolderProbe.Create;
  FProbeIntf := FProbe;
  FLocator := TDataFolderFactory.CreateLocatorOn(FProbeIntf);
end;

procedure TTestPlatformDataFolder.TearDown;
begin
  FLocator := nil;
  FProbeIntf := nil;
  FProbe := nil;
end;

procedure TTestPlatformDataFolder.DovrebbeUsareLaCartellaChiestaConData;
begin
  FProbe.Folders.Add('C:\work\dati\');
  Assert.AreEqual('C:\work\dati\', FLocator.Locate('C:\r\bin\Win32\Release\Doom\', 'dati'));
end;

procedure TTestPlatformDataFolder.DovrebbeSollevareSeLaCartellaChiestaManca;
begin
  Assert.WillRaise(
    procedure
    begin
      FLocator.Locate('C:\r\bin\Win32\Release\Doom\', 'manca');
    end, EDataFolderException);
end;

procedure TTestPlatformDataFolder.DovrebbeUsareLaCartellaDellExeSeHaIDatiDelGioco;
begin
  FProbe.WithGameFiles.Add('C:\r\bin\Doom\');
  FProbe.Folders.Add('C:\r\bin\Doom\');
  Assert.AreEqual('C:\r\bin\Doom\', FLocator.Locate('C:\r\bin\Doom\', ''));
end;

procedure TTestPlatformDataFolder.DovrebbeTrovareBinGiocoDaBinPiattaformaConfigurazioneGioco;
begin
  FProbe.Folders.Add('C:\r\bin\Doom\');
  Assert.AreEqual('C:\r\bin\Doom\', FLocator.Locate('C:\r\bin\Win32\Release\Doom', ''));
end;

procedure TTestPlatformDataFolder.DovrebbeTrovareBinPerUnProgrammaSenzaArea;
begin
  FProbe.Folders.Add('C:\r\bin\');
  Assert.AreEqual('C:\r\bin\', FLocator.Locate('C:\r\bin\Win64\Debug\', ''));
end;

procedure TTestPlatformDataFolder.DovrebbeFunzionareConWin64EDebug;
begin
  FProbe.Folders.Add('C:\r\bin\Heretic\');
  Assert.AreEqual('C:\r\bin\Heretic\', FLocator.Locate('C:\r\bin\Win64\Debug\Heretic\', ''));
end;

procedure TTestPlatformDataFolder.DovrebbeFunzionareAQualsiasiProfondita;
begin
  FProbe.Folders.Add('C:\a\b\c\d\bin\Strife\');
  Assert.AreEqual('C:\a\b\c\d\bin\Strife\', FLocator.Locate('C:\a\b\c\d\bin\Win32\Release\Strife\', ''));
end;

procedure TTestPlatformDataFolder.DovrebbeTenereLaCartellaDellExeSeLaCartellaDeiDatiManca;
begin
  Assert.AreEqual('C:\r\bin\Win32\Release\Doom\', FLocator.Locate('C:\r\bin\Win32\Release\Doom\', ''));
end;

procedure TTestPlatformDataFolder.DovrebbeTenereLaCartellaDellExeFuoriDalLayout;
begin
  FProbe.Folders.Add('C:\giochi\');
  Assert.AreEqual('C:\giochi\Doom\', FLocator.Locate('C:\giochi\Doom', ''));
end;

procedure TTestPlatformDataFolder.NonDovrebbeAccettareUnaSondaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TDataFolderFactory.CreateLocatorOn(nil);
    end, EArgumentNilException);
end;

end.
