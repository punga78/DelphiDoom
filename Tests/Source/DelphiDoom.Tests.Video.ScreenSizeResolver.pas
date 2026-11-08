{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - the size from the command line     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.ScreenSizeResolver;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DUnitX.TestFramework,
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.Video.Types,
  DelphiDoom.Video.Intf;

type
  /// <summary>A command line that remembers the names it was asked for</summary>
  TFakeScreenCommandLine = class(TInterfacedObject, ICommandLine)
  strict private
    FItems: TArray<string>;
    FAsked: TList<string>;
  public
    constructor Create(const AItems: TArray<string>);
    destructor Destroy; override;
    function Asked: string;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): string;
    function IndexOf(const AName: string): Integer;
    function Has(const AName: string): Boolean;
    function ValuesAfter(const AName: string): TArray<string>;
    function Text: string;
  end;

  TFakeDisplayMetrics = class(TInterfacedObject, IDisplayMetrics)
  strict private
    FWidth: Integer;
    FHeight: Integer;
  public
    constructor Create(AWidth, AHeight: Integer);
    function GetWidth: Integer;
    function GetHeight: Integer;
  end;

  [TestFixture]
  [Category('video')]
  TTestVideoScreenSizeResolver = class(TObject)
  strict private
    FLimits: TScreenSizeLimits;
    FCommandLine: TFakeScreenCommandLine;
    FCommandLineIntf: ICommandLine;
    function Resolver(const AArguments: array of string; ADesktopWidth: Integer = 1920;
      ADesktopHeight: Integer = 1080): IScreenSizeResolver;
    function Size(const AArguments: array of string; AWidth, AHeight: Integer): string;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareErroreConRigaDiComandoNil;
    [Test]
    procedure DovrebbeDareErroreConMisureNil;
    [Test]
    procedure DovrebbeDareErroreConLettoreDiNumeriNil;
    [Test]
    procedure DovrebbeLasciareLaDimensioneSenzaOpzioni;
    [Test]
    procedure DovrebbeLeggereLarghezzaEAltezza;
    [Test]
    procedure DovrebbeIgnorareUnaLarghezzaSenzaValore;
    [Test]
    procedure DovrebbeLimitareAlMassimo;
    [Test]
    procedure DovrebbeLimitareAlMinimoDopoLaLettura;
    [Test]
    procedure DovrebbeLeggereLaGeometria;
    [Test]
    procedure DovrebbeLeggereLaGeometriaConLaXMinuscola;
    [Test]
    procedure DovrebbeLimitareLaGeometriaAlMinimoEAlMassimo;
    [Test]
    procedure DovrebbeTenereLAltezzaAlMinimoSeLaGeometriaNonHaLaX;
    [Test]
    procedure DovrebbeIgnorareUnaGeometriaSenzaValore;
    [Test]
    [TestCase('fullhd', '-fullhd,1920,1080')]
    [TestCase('vga', '-vga,640,480')]
    [TestCase('svga', '-svga,800,600')]
    [TestCase('cga', '-cga,320,200')]
    [TestCase('cgaX2', '-cgaX2,640,400')]
    [TestCase('cgaX3', '-cgaX3,960,600')]
    procedure DovrebbeUsareIModiPredefiniti(const AOption: string; AWidth, AHeight: Integer);
    [Test]
    procedure DovrebbeLimitareIModiPredefinitiAlMassimo;
    [Test]
    procedure DovrebbeLasciareVincereIlModoPredefinitoSuLaLarghezza;
    [Test]
    procedure DovrebbeUsareLeMisureDelDesktopSeLaDimensioneEMenoUno;
    [Test]
    procedure DovrebbeLimitareLeMisureDelDesktop;
    [Test]
    procedure DovrebbeChiedereLeOpzioniNellOrdineDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Video.Factory;

{ TFakeScreenCommandLine }

constructor TFakeScreenCommandLine.Create(const AItems: TArray<string>);
var
  LIndex: Integer;
begin
  inherited Create;
  FAsked := TList<string>.Create;
  SetLength(FItems, Length(AItems));
  for LIndex := 0 to High(AItems) do
    FItems[LIndex] := UpperCase(AItems[LIndex]);
end;

destructor TFakeScreenCommandLine.Destroy;
begin
  FAsked.Free;
  inherited Destroy;
end;

function TFakeScreenCommandLine.Asked: string;
begin
  Result := string.Join(' ', FAsked.ToArray);
end;

function TFakeScreenCommandLine.GetCount: Integer;
begin
  Result := Length(FItems);
end;

function TFakeScreenCommandLine.GetItem(AIndex: Integer): string;
begin
  Result := FItems[AIndex];
end;

function TFakeScreenCommandLine.IndexOf(const AName: string): Integer;
var
  LName: string;
begin
  LName := UpperCase(AName);
  FAsked.Add(LName);
  for Result := 1 to High(FItems) do
    if FItems[Result] = LName then
      Exit;
  Result := 0;
end;

function TFakeScreenCommandLine.Has(const AName: string): Boolean;
begin
  Result := IndexOf(AName) > 0;
end;

function TFakeScreenCommandLine.ValuesAfter(const AName: string): TArray<string>;
begin
  Result := nil;
end;

function TFakeScreenCommandLine.Text: string;
begin
  Result := string.Join(' ', FItems);
end;

{ TFakeDisplayMetrics }

constructor TFakeDisplayMetrics.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  FWidth := AWidth;
  FHeight := AHeight;
end;

function TFakeDisplayMetrics.GetWidth: Integer;
begin
  Result := FWidth;
end;

function TFakeDisplayMetrics.GetHeight: Integer;
begin
  Result := FHeight;
end;

{ TTestVideoScreenSizeResolver }

procedure TTestVideoScreenSizeResolver.Setup;
begin
  FLimits.MinWidth := 160;
  FLimits.MinHeight := 100;
  FLimits.MaxWidth := 4096;
  FLimits.MaxHeight := 3072;
  FCommandLine := nil;
  FCommandLineIntf := nil;
end;

function TTestVideoScreenSizeResolver.Resolver(const AArguments: array of string;
  ADesktopWidth, ADesktopHeight: Integer): IScreenSizeResolver;
var
  LItems: TArray<string>;
  LIndex: Integer;
begin
  // the first argument is the name of the program
  SetLength(LItems, Length(AArguments) + 1);
  LItems[0] := 'DOOM';
  for LIndex := 0 to High(AArguments) do
    LItems[LIndex + 1] := AArguments[LIndex];
  FCommandLine := TFakeScreenCommandLine.Create(LItems);
  FCommandLineIntf := FCommandLine;
  Result := TVideoFactory.CreateScreenSizeResolver(FCommandLineIntf,
    TFakeDisplayMetrics.Create(ADesktopWidth, ADesktopHeight), FLimits,
    function(AText: string): Integer
    begin
      Result := StrToIntDef(AText, 0);
    end);
end;

function TTestVideoScreenSizeResolver.Size(const AArguments: array of string; AWidth,
  AHeight: Integer): string;
begin
  Resolver(AArguments).Resolve(AWidth, AHeight);
  Result := Format('%dx%d', [AWidth, AHeight]);
end;

procedure TTestVideoScreenSizeResolver.DovrebbeDareErroreConRigaDiComandoNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TVideoFactory.CreateScreenSizeResolver(nil, TFakeDisplayMetrics.Create(1, 1), FLimits,
        function(AText: string): Integer
        begin
          Result := 0;
        end);
    end, EArgumentNilException);
end;

procedure TTestVideoScreenSizeResolver.DovrebbeDareErroreConMisureNil;
begin
  Resolver([]);
  Assert.WillRaise(
    procedure
    begin
      TVideoFactory.CreateScreenSizeResolver(FCommandLineIntf, nil, FLimits,
        function(AText: string): Integer
        begin
          Result := 0;
        end);
    end, EArgumentNilException);
end;

procedure TTestVideoScreenSizeResolver.DovrebbeDareErroreConLettoreDiNumeriNil;
begin
  Resolver([]);
  Assert.WillRaise(
    procedure
    begin
      TVideoFactory.CreateScreenSizeResolver(FCommandLineIntf, TFakeDisplayMetrics.Create(1, 1),
        FLimits, nil);
    end, EArgumentNilException);
end;

procedure TTestVideoScreenSizeResolver.DovrebbeLasciareLaDimensioneSenzaOpzioni;
begin
  Assert.AreEqual('640x400', Size([], 640, 400));
end;

procedure TTestVideoScreenSizeResolver.DovrebbeLeggereLarghezzaEAltezza;
begin
  Assert.AreEqual('800x600', Size(['-screenwidth', '800', '-screenheight', '600'], 640, 400));
end;

procedure TTestVideoScreenSizeResolver.DovrebbeIgnorareUnaLarghezzaSenzaValore;
begin
  Assert.AreEqual('640x400', Size(['-screenwidth'], 640, 400));
end;

procedure TTestVideoScreenSizeResolver.DovrebbeLimitareAlMassimo;
begin
  Assert.AreEqual('4096x3072', Size(['-screenwidth', '9000', '-screenheight', '9000'], 640, 400));
end;

procedure TTestVideoScreenSizeResolver.DovrebbeLimitareAlMinimoDopoLaLettura;
begin
  Assert.AreEqual('160x100', Size(['-screenwidth', '10', '-screenheight', '10'], 640, 400));
end;

procedure TTestVideoScreenSizeResolver.DovrebbeLeggereLaGeometria;
begin
  Assert.AreEqual('1280x720', Size(['-geom', '1280X720'], 640, 400));
end;

procedure TTestVideoScreenSizeResolver.DovrebbeLeggereLaGeometriaConLaXMinuscola;
begin
  Assert.AreEqual('1280x720', Size(['-geom', '1280x720'], 640, 400));
end;

procedure TTestVideoScreenSizeResolver.DovrebbeLimitareLaGeometriaAlMinimoEAlMassimo;
begin
  Assert.AreEqual('4096x100', Size(['-geom', '5000x50'], 640, 400));
  Assert.AreEqual('160x3072', Size(['-geom', '10x5000'], 640, 400));
end;

procedure TTestVideoScreenSizeResolver.DovrebbeTenereLAltezzaAlMinimoSeLaGeometriaNonHaLaX;
begin
  Assert.AreEqual('800x100', Size(['-geom', '800'], 640, 400));
end;

procedure TTestVideoScreenSizeResolver.DovrebbeIgnorareUnaGeometriaSenzaValore;
begin
  Assert.AreEqual('640x400', Size(['-geom'], 640, 400));
end;

procedure TTestVideoScreenSizeResolver.DovrebbeUsareIModiPredefiniti(const AOption: string;
  AWidth, AHeight: Integer);
begin
  Assert.AreEqual(Format('%dx%d', [AWidth, AHeight]), Size([AOption], 1, 1));
end;

procedure TTestVideoScreenSizeResolver.DovrebbeLimitareIModiPredefinitiAlMassimo;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  FLimits.MaxWidth := 1024;
  FLimits.MaxHeight := 768;
  LWidth := 1;
  LHeight := 1;
  Resolver(['-fullhd']).Resolve(LWidth, LHeight);
  Assert.AreEqual(1024, LWidth);
  Assert.AreEqual(768, LHeight);
end;

procedure TTestVideoScreenSizeResolver.DovrebbeLasciareVincereIlModoPredefinitoSuLaLarghezza;
begin
  Assert.AreEqual('640x480', Size(['-screenwidth', '800', '-vga'], 1, 1));
end;

procedure TTestVideoScreenSizeResolver.DovrebbeUsareLeMisureDelDesktopSeLaDimensioneEMenoUno;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  LWidth := -1;
  LHeight := -1;
  Resolver([], 1366, 768).Resolve(LWidth, LHeight);
  Assert.AreEqual(1366, LWidth);
  Assert.AreEqual(768, LHeight);
end;

procedure TTestVideoScreenSizeResolver.DovrebbeLimitareLeMisureDelDesktop;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  LWidth := -1;
  LHeight := -1;
  Resolver([], 8000, 50).Resolve(LWidth, LHeight);
  Assert.AreEqual(4096, LWidth);
  Assert.AreEqual(100, LHeight);
end;

procedure TTestVideoScreenSizeResolver.DovrebbeChiedereLeOpzioniNellOrdineDelVecchioCodice;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  // the command line remembers the names asked (the console lists them in this order)
  LWidth := 640;
  LHeight := 400;
  Resolver([]).Resolve(LWidth, LHeight);
  Assert.AreEqual('-SCREENWIDTH -SCREENHEIGHT -GEOM -FULLHD -VGA -SVGA -CGA -CGAX2 -CGAX3',
    FCommandLine.Asked);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVideoScreenSizeResolver);

end.
