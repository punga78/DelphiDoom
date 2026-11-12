{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the hash of a frame               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.FrameHashWriter;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Parity.FrameHashWriter,
  DelphiDoom.Parity.Intf,
  DelphiDoom.Parity.Types,
  DelphiDoom.Tests.Parity.Fakes;

type
  [TestFixture]
  [Category('parity')]
  TTestParityFrameHashWriter = class(TObject)
  strict private
    FLog: TFakeParityLog;
    FLogRef: IParityLog;
    FWriter: TFrameHashWriter;
    FPixels: TBytes;
    FLayout: TParityFrameLayout;
    function Parts(ALine: Integer): TArray<string>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnLogNil;
    [Test]
    procedure DovrebbeScrivereUnaRigaConTicETreImpronte;
    [Test]
    procedure LostessoFotogrammaDovrebbeDareLaStessaRiga;
    [Test]
    procedure UnPixelDellaVistaDovrebbeCambiareVistaETotaleMaNonIlResto;
    [Test]
    procedure UnPixelFuoriDallaVistaDovrebbeCambiareRestoETotaleMaNonLaVista;
    [Test]
    procedure LaTavolozzaDovrebbeCambiareSoloIlTotale;
    [Test]
    procedure DovrebbeFunzionareConPixelDa32Bit;
    [Test]
    procedure UnaVistaChePienaTuttoLoSchermoDovrebbeAvereIlRestoVuoto;
    [Test]
    procedure UnaVistaFuoriDalFotogrammaDovrebbeDareEccezione;
    [Test]
    procedure UnaDimensioneDelPixelSbagliataDovrebbeDareEccezione;
    [Test]
    procedure UnFotogrammaSenzaPixelDovrebbeDareEccezione;
  end;

implementation

procedure TTestParityFrameHashWriter.Setup;
begin
  FLog := TFakeParityLog.Create;
  FLogRef := FLog;
  FWriter := TFrameHashWriter.Create(FLogRef);
  FLayout.Width := 10;
  FLayout.Height := 8;
  FLayout.ViewX := 2;
  FLayout.ViewY := 1;
  FLayout.ViewWidth := 5;
  FLayout.ViewHeight := 4;
  SetLength(FPixels, 10 * 8);
end;

procedure TTestParityFrameHashWriter.TearDown;
begin
  FWriter.Free;
  FLog := nil;
  FLogRef := nil;
end;

function TTestParityFrameHashWriter.Parts(ALine: Integer): TArray<string>;
begin
  Result := FLog.Lines[ALine].Split([' ']);
end;

procedure TTestParityFrameHashWriter.DovrebbeRifiutareUnLogNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TFrameHashWriter.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestParityFrameHashWriter.DovrebbeScrivereUnaRigaConTicETreImpronte;
begin
  FWriter.WriteFrame(12, FLayout, @FPixels[0], 1, 0);
  Assert.AreEqual(1, FLog.Lines.Count);
  Assert.AreEqual(5, Length(Parts(0)));
  Assert.AreEqual('F', Parts(0)[0]);
  Assert.AreEqual('12', Parts(0)[1]);
  Assert.AreEqual(16, Length(Parts(0)[2]));
  Assert.AreEqual(16, Length(Parts(0)[3]));
  Assert.AreEqual(16, Length(Parts(0)[4]));
end;

procedure TTestParityFrameHashWriter.LostessoFotogrammaDovrebbeDareLaStessaRiga;
begin
  FWriter.WriteFrame(1, FLayout, @FPixels[0], 1, 0);
  FWriter.WriteFrame(1, FLayout, @FPixels[0], 1, 0);
  Assert.AreEqual(FLog.Lines[0], FLog.Lines[1]);
end;

procedure TTestParityFrameHashWriter.UnPixelDellaVistaDovrebbeCambiareVistaETotaleMaNonIlResto;
begin
  FWriter.WriteFrame(1, FLayout, @FPixels[0], 1, 0);
  // x = 3, y = 2 is inside the view (columns 2..6, rows 1..4)
  FPixels[2 * 10 + 3] := 200;
  FWriter.WriteFrame(1, FLayout, @FPixels[0], 1, 0);
  Assert.AreNotEqual(Parts(0)[2], Parts(1)[2], 'full');
  Assert.AreNotEqual(Parts(0)[3], Parts(1)[3], 'view');
  Assert.AreEqual(Parts(0)[4], Parts(1)[4], 'hud');
end;

procedure TTestParityFrameHashWriter.UnPixelFuoriDallaVistaDovrebbeCambiareRestoETotaleMaNonLaVista;
begin
  FWriter.WriteFrame(1, FLayout, @FPixels[0], 1, 0);
  // the last column of a row of the view, just outside it (x = 7, y = 2)
  FPixels[2 * 10 + 7] := 200;
  FWriter.WriteFrame(1, FLayout, @FPixels[0], 1, 0);
  // the first pixel of the frame
  FPixels[2 * 10 + 7] := 0;
  FPixels[0] := 9;
  FWriter.WriteFrame(1, FLayout, @FPixels[0], 1, 0);
  Assert.AreNotEqual(Parts(0)[2], Parts(1)[2], 'full 1');
  Assert.AreEqual(Parts(0)[3], Parts(1)[3], 'view 1');
  Assert.AreNotEqual(Parts(0)[4], Parts(1)[4], 'hud 1');
  Assert.AreNotEqual(Parts(0)[2], Parts(2)[2], 'full 2');
  Assert.AreEqual(Parts(0)[3], Parts(2)[3], 'view 2');
  Assert.AreNotEqual(Parts(0)[4], Parts(2)[4], 'hud 2');
end;

procedure TTestParityFrameHashWriter.LaTavolozzaDovrebbeCambiareSoloIlTotale;
begin
  FWriter.WriteFrame(1, FLayout, @FPixels[0], 1, 111);
  FWriter.WriteFrame(1, FLayout, @FPixels[0], 1, 222);
  Assert.AreNotEqual(Parts(0)[2], Parts(1)[2], 'full');
  Assert.AreEqual(Parts(0)[3], Parts(1)[3], 'view');
  Assert.AreEqual(Parts(0)[4], Parts(1)[4], 'hud');
end;

procedure TTestParityFrameHashWriter.DovrebbeFunzionareConPixelDa32Bit;
var
  LPixels: TArray<Cardinal>;
begin
  SetLength(LPixels, 10 * 8);
  FWriter.WriteFrame(1, FLayout, @LPixels[0], 4, 0);
  LPixels[2 * 10 + 3] := $00FF0000;
  FWriter.WriteFrame(1, FLayout, @LPixels[0], 4, 0);
  Assert.AreNotEqual(Parts(0)[3], Parts(1)[3], 'view');
  Assert.AreEqual(Parts(0)[4], Parts(1)[4], 'hud');
end;

procedure TTestParityFrameHashWriter.UnaVistaChePienaTuttoLoSchermoDovrebbeAvereIlRestoVuoto;
begin
  FLayout.ViewX := 0;
  FLayout.ViewY := 0;
  FLayout.ViewWidth := 10;
  FLayout.ViewHeight := 8;
  FWriter.WriteFrame(1, FLayout, @FPixels[0], 1, 0);
  FPixels[5] := 77;
  FWriter.WriteFrame(1, FLayout, @FPixels[0], 1, 0);
  // all of the frame is the view: the hud does not change
  Assert.AreEqual(Parts(0)[4], Parts(1)[4], 'hud');
  Assert.AreNotEqual(Parts(0)[3], Parts(1)[3], 'view');
end;

procedure TTestParityFrameHashWriter.UnaVistaFuoriDalFotogrammaDovrebbeDareEccezione;
begin
  FLayout.ViewWidth := 20;
  Assert.WillRaise(
    procedure
    begin
      FWriter.WriteFrame(1, FLayout, @FPixels[0], 1, 0);
    end, EParityException);
end;

procedure TTestParityFrameHashWriter.UnaDimensioneDelPixelSbagliataDovrebbeDareEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      FWriter.WriteFrame(1, FLayout, @FPixels[0], 3, 0);
    end, EParityException);
end;

procedure TTestParityFrameHashWriter.UnFotogrammaSenzaPixelDovrebbeDareEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      FWriter.WriteFrame(1, FLayout, nil, 1, 0);
    end, EParityException);
end;

end.
