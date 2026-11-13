{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the setting of the composition in true color       }
{  (issue 183): the row of the advanced options and the screen that takes its   }
{  composer again when the display is reset                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.TrueColorOption;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomEngine.ExtraOptions.Intf,
  DelphiDoom.XcomEngine.TrueColor.Intf, DelphiDoom.XcomEngine.TrueColorComposer,
  DelphiDoom.XcomEngine.MemoryTrueColorVideoDevice, DelphiDoom.Xcom.TrueColorOption;

type
  [TestFixture]
  [Category('XcomTrueColor')]
  TTestXcomTrueColorOption = class
  strict private
    FOptions: TXcomOptions;
    FDevice: TXcomMemoryTrueColorVideoDevice;
    FDeviceRef: IXcomVideoDevice;
    FScreen: TXcomScreen;
    function SourceOf(AOptions: TXcomOptions; ADevice: TXcomMemoryTrueColorVideoDevice): TXcomFrameComposerSource;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure SenzaLaChiaveDovrebbeEssereSpenta;
    [Test]
    [TestCase('true', 'true,True')]
    [TestCase('True', 'True,True')]
    [TestCase('false', 'false,False')]
    [TestCase('altro', 'yes,False')]
    procedure DovrebbeLeggereLaChiaveDelFileDelleOpzioni(const AValue: string; AExpected: Boolean);
    [Test]
    procedure AccenderlaDovrebbeScrivereLaChiave;
    [Test]
    procedure DovrebbeAvereUnaRigaConTitoloEDescrizione;
    [Test]
    procedure SenzaOpzioniDovrebbeSollevare;
    [Test]
    procedure LoSchermoDovrebbePrendereIlCompositoreAlResetDelDisplay;
    [Test]
    procedure LoSchermoDovrebbeTornareAOttoBitQuandoLaSorgenteNonDaNulla;
    [Test]
    procedure SenzaSorgenteLoSchermoDovrebbeTenereIlCompositoreDelCostruttore;
    [Test]
    procedure LaFotografiaDovrebbeEssereIlFotogrammaDelCompositore;
    [Test]
    procedure SenzaCompositoreLaFotografiaDovrebbeEssereGliIndiciConLaPaletta;
  end;

implementation

procedure TTestXcomTrueColorOption.Setup;
begin
  FOptions := TXcomOptions.Create;
  FOptions.DisplayWidth := 640;
  FOptions.DisplayHeight := 400;
  FDevice := TXcomMemoryTrueColorVideoDevice.Create;
  FDeviceRef := FDevice;
end;

procedure TTestXcomTrueColorOption.TearDown;
begin
  FScreen.Free;
  FScreen := nil;
  FDeviceRef := nil;
  FOptions.Free;
end;

function TTestXcomTrueColorOption.SourceOf(AOptions: TXcomOptions;
  ADevice: TXcomMemoryTrueColorVideoDevice): TXcomFrameComposerSource;
begin
  // what the composition root of the game does: a composer as long as the options want one
  Result :=
    function: IXcomFrameComposer
    begin
      if TXcomTrueColorOption.Wanted(AOptions) then
        Result := TXcomTrueColorComposer.Create(ADevice)
      else
        Result := nil;
    end;
end;

procedure TTestXcomTrueColorOption.SenzaLaChiaveDovrebbeEssereSpenta;
var
  LOption: IXcomExtraOptions;
begin
  LOption := TXcomTrueColorOption.Create(FOptions);
  Assert.IsFalse(LOption.IsOn(0));
  Assert.IsFalse(TXcomTrueColorOption.Wanted(FOptions));
end;

procedure TTestXcomTrueColorOption.DovrebbeLeggereLaChiaveDelFileDelleOpzioni(const AValue: string;
  AExpected: Boolean);
var
  LOption: IXcomExtraOptions;
begin
  FOptions.UnknownOptions.AddOrSetValue('trueColor', AValue);
  LOption := TXcomTrueColorOption.Create(FOptions);
  Assert.AreEqual(AExpected, LOption.IsOn(0));
end;

procedure TTestXcomTrueColorOption.AccenderlaDovrebbeScrivereLaChiave;
var
  LOption: IXcomExtraOptions;
begin
  LOption := TXcomTrueColorOption.Create(FOptions);
  LOption.SetOn(0, True);
  Assert.AreEqual('true', FOptions.UnknownOptions['trueColor']);
  Assert.IsTrue(LOption.IsOn(0));
  LOption.SetOn(0, False);
  Assert.AreEqual('false', FOptions.UnknownOptions['trueColor']);
  Assert.IsFalse(LOption.IsOn(0));
end;

procedure TTestXcomTrueColorOption.DovrebbeAvereUnaRigaConTitoloEDescrizione;
var
  LOption: IXcomExtraOptions;
begin
  LOption := TXcomTrueColorOption.Create(FOptions);
  Assert.AreEqual(1, LOption.Count);
  Assert.IsTrue(LOption.Heading <> '');
  Assert.IsTrue(LOption.Title(0) <> '');
  Assert.IsTrue(LOption.Description(0) <> '');
end;

procedure TTestXcomTrueColorOption.SenzaOpzioniDovrebbeSollevare;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomTrueColorOption.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestXcomTrueColorOption.LoSchermoDovrebbePrendereIlCompositoreAlResetDelDisplay;
begin
  FScreen := TXcomScreen.Create(FOptions, FDeviceRef);
  FScreen.ComposerSource := SourceOf(FOptions, FDevice);
  FScreen.Flip;
  Assert.AreEqual(0, FDevice.TrueColorPresented);
  Assert.IsTrue(FScreen.DetailLayers = nil);
  // the options are confirmed with the setting on
  FOptions.UnknownOptions.AddOrSetValue('trueColor', 'true');
  FScreen.ResetDisplay;
  FScreen.Flip;
  Assert.AreEqual(1, FDevice.TrueColorPresented);
  Assert.AreEqual(2, FScreen.DetailLayers.DetailScale);
end;

procedure TTestXcomTrueColorOption.LoSchermoDovrebbeTornareAOttoBitQuandoLaSorgenteNonDaNulla;
var
  LPresented: Integer;
begin
  FOptions.UnknownOptions.AddOrSetValue('trueColor', 'true');
  FScreen := TXcomScreen.Create(FOptions, FDeviceRef);
  FScreen.ComposerSource := SourceOf(FOptions, FDevice);
  FScreen.ResetDisplay;
  FScreen.Flip;
  Assert.AreEqual(1, FDevice.TrueColorPresented);
  LPresented := FDevice.Presented;
  FOptions.UnknownOptions.AddOrSetValue('trueColor', 'false');
  FScreen.ResetDisplay;
  FScreen.Flip;
  Assert.AreEqual(1, FDevice.TrueColorPresented);
  Assert.AreEqual(LPresented + 1, FDevice.Presented, 'il fotogramma a 8 bit');
  Assert.IsTrue(FScreen.DetailLayers = nil);
  Assert.AreEqual<Integer>(640 * 400, Length(FScreen.DisplayPixels));
end;

procedure TTestXcomTrueColorOption.SenzaSorgenteLoSchermoDovrebbeTenereIlCompositoreDelCostruttore;
var
  LComposer: IXcomFrameComposer;
begin
  LComposer := TXcomTrueColorComposer.Create(FDevice);
  FScreen := TXcomScreen.Create(FOptions, FDeviceRef, LComposer);
  FScreen.ResetDisplay;
  FScreen.Flip;
  Assert.AreEqual(1, FDevice.TrueColorPresented);
end;

procedure TTestXcomTrueColorOption.LaFotografiaDovrebbeEssereIlFotogrammaDelCompositore;
var
  LPixels: TXcomTrueColorPixels;
  LWidth: Integer;
  LHeight: Integer;
  LIndex: Integer;
begin
  FOptions.UnknownOptions.AddOrSetValue('trueColor', 'true');
  FScreen := TXcomScreen.Create(FOptions, FDeviceRef);
  FScreen.ComposerSource := SourceOf(FOptions, FDevice);
  FScreen.ResetDisplay;
  FScreen.GetSurface.DrawRect(0, 0, 320, 200, 5);
  FScreen.Flip;
  Assert.IsTrue(FScreen.Snapshot(LPixels, LWidth, LHeight));
  Assert.AreEqual(640, LWidth);
  Assert.AreEqual(400, LHeight);
  for LIndex := 0 to High(LPixels) do
    if LPixels[LIndex] <> FDevice.TrueColorPixels[LIndex] then
      Assert.Fail(Format('pixel %d', [LIndex]));
end;

procedure TTestXcomTrueColorOption.SenzaCompositoreLaFotografiaDovrebbeEssereGliIndiciConLaPaletta;
var
  LPixels: TXcomTrueColorPixels;
  LWidth: Integer;
  LHeight: Integer;
  LColors: TXcomColors;
begin
  FScreen := TXcomScreen.Create(FOptions, FDeviceRef);
  FillChar(LColors, SizeOf(LColors), 0);
  LColors[5].Red := 10;
  LColors[5].Green := 20;
  LColors[5].Blue := 30;
  FScreen.SetPalette(@LColors[0], 0, 256);
  FScreen.GetSurface.DrawRect(0, 0, 320, 200, 5);
  FScreen.Flip;
  Assert.IsTrue(FScreen.Snapshot(LPixels, LWidth, LHeight));
  Assert.AreEqual<Integer>(640 * 400, Length(LPixels));
  Assert.AreEqual(Cardinal($FF0A141E), LPixels[1000]);
end;

end.
