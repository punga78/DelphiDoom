{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the cinematic calls on the  }
{  RoQ player of Framework\Cinematic (handles, the name of the file, the end of  }
{  the file, the frame handed to the renderer), with the small RoQ file of      }
{  Tests\Data\Cinematic                                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.ClientRoq;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Q3Host.ClientRoqCinematics, DelphiDoom.Tests.Q3Host.Services,
  DelphiDoom.Tests.Q3Host.Support;

type
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3RoqCinematics = class
  strict private
    FFiles: TQ3FakeGameFileSystem;
    FFilesIntf: IGameFileSystem;
    FTime: TQ3FixedTime;
    FTimeIntf: IInterface;
    FCinematics: TQ3RoqCinematics;
    FCinematicsIntf: IInterface;
    FDraws: Integer;
    FDrawn: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlNomeSenzaBarraDovrebbeEssereNellaCartellaVideo;
    [Test]
    procedure UnFileCheNonCeODatiCheNonSonoRoqDovrebberoDare1Negativo;
    [Test]
    procedure LoStessoFileDueVolteDovrebbeDareLoStessoNumero;
    [Test]
    procedure LaFineDelFileDovrebbeLiberareIlNumero;
    [Test]
    procedure UnFilmatoFermatoSullUltimoFotogrammaDovrebbeRestareFermo;
    [Test]
    procedure UnFilmatoInCicloNonDovrebbeFinire;
    [Test]
    procedure IlFotogrammaDovrebbeArrivareAlRendererConIlRettangolo;
    [Test]
    procedure UnNumeroNonValidoDovrebbeDareFineSenzaErrori;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, DelphiDoom.Cinematic.Intf, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Client.Types,
  DelphiDoom.Tests.Shared.Files;

const
  CIN_LOOP = 2;
  CIN_HOLD = 4;
  CIN_SYSTEM = 1;

procedure TTestQ3RoqCinematics.Setup;
var
  LBytes: TBytes;
begin
  FFiles := TQ3FakeGameFileSystem.Create;
  FFilesIntf := FFiles;
  LBytes := TFile.ReadAllBytes(TTestFiles.DataFile('Cinematic', 'basic.roq'));
  FFiles.Add('video/basic.roq', LBytes);
  FFiles.Add('movies/other.roq', LBytes);
  FFiles.Add('video/bad.roq', TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20));
  FTime := TQ3FixedTime.Create(1000);
  FTimeIntf := FTime;
  FCinematics := TQ3RoqCinematics.Create(FFilesIntf, FTime);
  FCinematicsIntf := FCinematics;
  FDraws := 0;
  FDrawn := '';
end;

procedure TTestQ3RoqCinematics.TearDown;
begin
  FCinematicsIntf := nil;
  FTimeIntf := nil;
  FFilesIntf := nil;
end;

procedure TTestQ3RoqCinematics.IlNomeSenzaBarraDovrebbeEssereNellaCartellaVideo;
begin
  Assert.AreEqual(0, FCinematics.Play('basic.roq', 0, 0, 640, 480, 0));
  // a name with a slash is the path: the same file under another folder is another cinematic
  Assert.AreEqual(1, FCinematics.Play('movies/other.roq', 0, 0, 640, 480, 0));
  // the same path as the first one, but a cinematic that changes the game state is always a new one
  Assert.AreEqual(2, FCinematics.Play('video/basic.roq', 0, 0, 640, 480, CIN_SYSTEM));
end;

procedure TTestQ3RoqCinematics.UnFileCheNonCeODatiCheNonSonoRoqDovrebberoDare1Negativo;
begin
  Assert.AreEqual(-1, FCinematics.Play('missing.roq', 0, 0, 640, 480, 0));
  Assert.AreEqual(-1, FCinematics.Play('bad.roq', 0, 0, 640, 480, 0));
  // the slots stay free
  Assert.AreEqual(0, FCinematics.Play('basic.roq', 0, 0, 640, 480, 0));
end;

procedure TTestQ3RoqCinematics.LoStessoFileDueVolteDovrebbeDareLoStessoNumero;
begin
  Assert.AreEqual(0, FCinematics.Play('basic.roq', 0, 0, 640, 480, 0));
  Assert.AreEqual(0, FCinematics.Play('basic.roq', 10, 10, 100, 100, 0));
  // a cinematic that changes the game state is always a new one
  Assert.AreEqual(1, FCinematics.Play('basic.roq', 0, 0, 640, 480, CIN_SYSTEM));
end;

procedure TTestQ3RoqCinematics.LaFineDelFileDovrebbeLiberareIlNumero;
var
  LHandle: Integer;
begin
  LHandle := FCinematics.Play('basic.roq', 0, 0, 640, 480, 0);
  Assert.AreEqual(Q3_FMV_PLAY, FCinematics.Run(LHandle));
  FTime.Value := 1000 + 10 * 60 * 1000;
  Assert.AreEqual(Q3_FMV_EOF, FCinematics.Run(LHandle));
  // finished: nothing to draw, nothing to stop, and the number is free again
  Assert.AreEqual(Q3_FMV_EOF, FCinematics.Run(LHandle));
  Assert.AreEqual(Q3_FMV_EOF, FCinematics.Stop(LHandle));
  Assert.AreEqual(LHandle, FCinematics.Play('basic.roq', 0, 0, 640, 480, 0));
end;

procedure TTestQ3RoqCinematics.UnFilmatoFermatoSullUltimoFotogrammaDovrebbeRestareFermo;
var
  LHandle: Integer;
begin
  LHandle := FCinematics.Play('basic.roq', 0, 0, 640, 480, CIN_HOLD);
  // the player takes the time of its first image as the start
  Assert.AreEqual(Q3_FMV_PLAY, FCinematics.Run(LHandle));
  FTime.Value := 1000 + 10 * 60 * 1000;
  // FMV_IDLE: held at the end
  Assert.AreEqual(Q3_FMV_IDLE, FCinematics.Run(LHandle));
  Assert.AreEqual(Q3_FMV_IDLE, FCinematics.Run(LHandle));
  Assert.AreEqual(Q3_FMV_EOF, FCinematics.Stop(LHandle));
  Assert.AreEqual(Q3_FMV_EOF, FCinematics.Run(LHandle));
end;

procedure TTestQ3RoqCinematics.UnFilmatoInCicloNonDovrebbeFinire;
var
  LHandle: Integer;
begin
  LHandle := FCinematics.Play('basic.roq', 0, 0, 640, 480, CIN_LOOP);
  Assert.AreEqual(Q3_FMV_PLAY, FCinematics.Run(LHandle));
  FTime.Value := 1000 + 10 * 60 * 1000;
  Assert.AreEqual(Q3_FMV_PLAY, FCinematics.Run(LHandle));
  FTime.Value := FTime.Value + 12345;
  Assert.AreEqual(Q3_FMV_PLAY, FCinematics.Run(LHandle));
end;

procedure TTestQ3RoqCinematics.IlFotogrammaDovrebbeArrivareAlRendererConIlRettangolo;
var
  LHandle: Integer;
begin
  FCinematics.OnDraw :=
    procedure(AHandle, AX, AY, AWidth, AHeight: Integer; const AImage: TRoqPlayerImage)
    begin
      Inc(FDraws);
      FDrawn := Format('%d %d %d %d %d %d', [AHandle, AX, AY, AWidth, AHeight, Integer(AImage.Width > 0)]);
      Assert.AreEqual<Integer>(AImage.Width * AImage.Height, Length(AImage.Pixels));
    end;
  LHandle := FCinematics.Play('basic.roq', 10, 20, 300, 200, 0);
  FCinematics.Run(LHandle);
  FCinematics.Draw(LHandle);
  Assert.AreEqual(1, FDraws);
  Assert.AreEqual('0 10 20 300 200 1', FDrawn);
  FCinematics.SetExtents(LHandle, 1, 2, 3, 4);
  FCinematics.Draw(LHandle);
  Assert.AreEqual('0 1 2 3 4 1', FDrawn);
  // an extent of a handle that is not there changes nothing, and nothing is drawn for it
  FCinematics.SetExtents(9, 1, 2, 3, 4);
  FCinematics.Draw(9);
  Assert.AreEqual(2, FDraws);
  FCinematics.OnDraw := nil;
end;

procedure TTestQ3RoqCinematics.UnNumeroNonValidoDovrebbeDareFineSenzaErrori;
begin
  Assert.AreEqual(Q3_FMV_EOF, FCinematics.Run(-1));
  Assert.AreEqual(Q3_FMV_EOF, FCinematics.Run(16));
  Assert.AreEqual(Q3_FMV_EOF, FCinematics.Run(3));
  Assert.AreEqual(Q3_FMV_EOF, FCinematics.Stop(-5));
  FCinematics.Draw(100);
  FCinematics.SetExtents(-1, 0, 0, 0, 0);
end;

end.
