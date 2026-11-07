{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TScreenshotTargets                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Screenshot.Targets;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Screenshot.Types,
  DelphiDoom.Screenshot.Intf, DelphiDoom.Screenshot.Targets,
  DelphiDoom.Tests.Screenshot.Fakes;

type
  [TestFixture]
  [Category('screenshot')]
  TTestScreenshotTargets = class(TObject)
  private
    FTargets: IScreenshotTargets;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeRifiutareCartelleNil;
    [Test]
    procedure DovrebbeDareUnNomeConDataPerOgniFormato;
    [Test]
    procedure DovrebbeLeggereIlFormatoDallEstensioneTga;
    [Test]
    procedure DovrebbeLeggereIlFormatoDallEstensioneJpgMaiuscola;
    [Test]
    procedure DovrebbeLeggereIlFormatoDallEstensionePng;
    [Test]
    procedure DovrebbeUsarePngSenzaEstensione;
    [Test]
    procedure DovrebbeUsarePngConUnaEstensioneSconosciuta;
    [Test]
    procedure DovrebbeLasciareUnNomeConCartellaCosiComeE;
    [Test]
    procedure DovrebbeMettereOgniNomeNellaCartellaDelSuoFormato;
  end;

implementation

procedure TTestScreenshotTargets.Setup;
begin
  FTargets := TScreenshotTargets.Create(TFakeFolders.Create);
end;

procedure TTestScreenshotTargets.DovrebbeRifiutareCartelleNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScreenshotTargets.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestScreenshotTargets.DovrebbeDareUnNomeConDataPerOgniFormato;
var
  LTarget: TScreenshotTarget;
begin
  LTarget := FTargets.ForGenerated('DOOM', '20240102_030405006', TScreenshotFormat.Jpg);
  Assert.AreEqual(Ord(TScreenshotFormat.Jpg), Ord(LTarget.Format));
  Assert.AreEqual('C:\Game\DATA\SCREENSHOTS\TGA\SSHOT_DOOM_20240102_030405006.tga', LTarget.TgaPath);
  Assert.AreEqual('C:\Game\DATA\SCREENSHOTS\JPG\SSHOT_DOOM_20240102_030405006.jpg', LTarget.JpgPath);
  Assert.AreEqual('C:\Game\DATA\SCREENSHOTS\PNG\SSHOT_DOOM_20240102_030405006.png', LTarget.PngPath);
end;

procedure TTestScreenshotTargets.DovrebbeLeggereIlFormatoDallEstensioneTga;
var
  LTarget: TScreenshotTarget;
begin
  LTarget := FTargets.ForFileName('C:\Shots\a.TGA');
  Assert.AreEqual(Ord(TScreenshotFormat.Tga), Ord(LTarget.Format));
  Assert.AreEqual('C:\Shots\a.TGA', LTarget.TgaPath, 'il nome dato resta com''è');
  Assert.AreEqual('C:\Shots\a.jpg', LTarget.JpgPath);
  Assert.AreEqual('C:\Shots\a.png', LTarget.PngPath);
end;

procedure TTestScreenshotTargets.DovrebbeLeggereIlFormatoDallEstensioneJpgMaiuscola;
var
  LTarget: TScreenshotTarget;
begin
  LTarget := FTargets.ForFileName('C:\Shots\a.JPG');
  Assert.AreEqual(Ord(TScreenshotFormat.Jpg), Ord(LTarget.Format));
  Assert.AreEqual('C:\Shots\a.JPG', LTarget.JpgPath);
  Assert.AreEqual('C:\Shots\a.tga', LTarget.TgaPath);
  Assert.AreEqual('C:\Shots\a.png', LTarget.PngPath);
end;

procedure TTestScreenshotTargets.DovrebbeLeggereIlFormatoDallEstensionePng;
var
  LTarget: TScreenshotTarget;
begin
  LTarget := FTargets.ForFileName('C:\Shots\a.png');
  Assert.AreEqual(Ord(TScreenshotFormat.Png), Ord(LTarget.Format));
  Assert.AreEqual('C:\Shots\a.png', LTarget.PngPath);
  Assert.AreEqual('C:\Shots\a.tga', LTarget.TgaPath);
  Assert.AreEqual('C:\Shots\a.jpg', LTarget.JpgPath);
end;

procedure TTestScreenshotTargets.DovrebbeUsarePngSenzaEstensione;
var
  LTarget: TScreenshotTarget;
begin
  LTarget := FTargets.ForFileName('C:\Shots\a');
  Assert.AreEqual(Ord(TScreenshotFormat.Png), Ord(LTarget.Format));
  Assert.AreEqual('C:\Shots\a.png', LTarget.PngPath);
  Assert.AreEqual('C:\Shots\a.tga', LTarget.TgaPath);
  Assert.AreEqual('C:\Shots\a.jpg', LTarget.JpgPath);
end;

procedure TTestScreenshotTargets.DovrebbeUsarePngConUnaEstensioneSconosciuta;
var
  LTarget: TScreenshotTarget;
begin
  LTarget := FTargets.ForFileName('C:\Shots\a.bmp');
  Assert.AreEqual(Ord(TScreenshotFormat.Png), Ord(LTarget.Format));
  Assert.AreEqual('C:\Shots\a.bmp.png', LTarget.PngPath);
end;

procedure TTestScreenshotTargets.DovrebbeLasciareUnNomeConCartellaCosiComeE;
var
  LTarget: TScreenshotTarget;
begin
  LTarget := FTargets.ForFileName('shots/a.png');
  Assert.AreEqual('shots/a.png', LTarget.PngPath);
  Assert.AreEqual('shots/a.tga', LTarget.TgaPath);
end;

procedure TTestScreenshotTargets.DovrebbeMettereOgniNomeNellaCartellaDelSuoFormato;
var
  LTarget: TScreenshotTarget;
begin
  // regressione: il nome del PNG riceveva la cartella dei PNG ma veniva assegnato al JPG
  LTarget := FTargets.ForFileName('00000012');
  Assert.AreEqual('C:\Game\DATA\SCREENSHOTS\PNG\00000012.png', LTarget.PngPath);
  Assert.AreEqual('C:\Game\DATA\SCREENSHOTS\JPG\00000012.jpg', LTarget.JpgPath);
  Assert.AreEqual('C:\Game\DATA\SCREENSHOTS\TGA\00000012.tga', LTarget.TgaPath);
end;

end.
