{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the adapters of Xcom32 on Libs\GameHost: the       }
{  events of the window as the events of the game, the log and the display      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.HostAdapters;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, DUnitX.TestFramework,
  DelphiDoom.Logging.Intf, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.QueueEventSource, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf,
  DelphiDoom.GameHost.Video.Intf, DelphiDoom.GameHost.Win.MessageTranslator, DelphiDoom.Xcom.HostEventSink,
  DelphiDoom.Xcom.HostLog, DelphiDoom.Xcom.HostVideoDevice, DelphiDoom.Xcom.HostShaderLoader,
  DelphiDoom.XcomEngine.ShaderFileReader, DelphiDoom.Yaml.Factory;

type
  /// <summary>A keyboard that answers what the test says</summary>
  TFakeHostKeyboard = class(TInterfacedObject, IGameHostKeyboard)
  public
    Held: TGameHostModifiers;
    Typed: Cardinal;
    function Modifiers: TGameHostModifiers;
    function CharacterOf(AVirtualKey: Cardinal; AScanCode: Cardinal): Cardinal;
  end;

  TFakeXcomLog = class(TInterfacedObject, IXcomLog)
  public
    Lines: string;
    procedure Write(const ALevel, AMessage: string);
  end;

  /// <summary>A display of the host that only shows a picture: no window, no filter</summary>
  TFakePlainHostDisplay = class(TInterfacedObject, IGameHostVideoDevice)
  public
    Presented: Integer;
    Red: Byte;
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TGameHostPalette);
    procedure SetTitle(const ATitle: string);
  end;

  [TestFixture]
  [Category('XcomWindow')]
  TTestXcomHostAdapters = class
  strict private
    FQueue: TXcomQueueEventSource;
    FQueueRef: IXcomEventSource;
    FKeyboard: TFakeHostKeyboard;
    FTranslator: TGameHostWinMessageTranslator;
    FState: TGameHostWindowState;
    procedure Send(AMessage: UINT; AWParam: WPARAM; ALParam: LPARAM);
    function Next: TXcomInputEvent;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnTastoConNomeDovrebbeDiventareIlSuoCodiceSdl;
    [Test]
    procedure UnTastoSenzaNomeDovrebbePrendereIlCarattereMinuscolo;
    [Test]
    procedure UnTastoSenzaNomeNeCarattereNonDovrebbeDareEventi;
    [Test]
    procedure IlRilascioDiUnTastoSenzaNomeNonDovrebbeDareEventi;
    [Test]
    procedure IModificatoriDovrebberoArrivareAllaCoda;
    [Test]
    procedure IlMouseDovrebbeDareBottoneEPosizione;
    [Test]
    procedure ASchermoInteroIlMouseDovrebbeTornareNellImmagine;
    [Test]
    procedure LaRotellaASchermoInteroNonDovrebbeScalareDueVolteLaPosizione;
    [Test]
    procedure LaRotellaDovrebbeDarePressioneERilascioDelBottoneGiusto;
    [Test]
    procedure LAttivazioneDovrebbeDistinguereFuocoEMinimizzata;
    [Test]
    procedure LaChiusuraDovrebbeDareQuit;
    [Test]
    procedure IlRidimensionamentoDovrebbeDareLaMisuraSenzaToccareIModificatori;
    [Test]
    procedure IlLogDovrebbeUsareILivelliDiOpenXcom;
    [Test]
    procedure IlDispositivoSenzaFiltroDovrebbeDireCheOpenGlNonEInUso;
    [Test]
    procedure IlDispositivoDovrebbePassareLaPalette;
    [Test]
    procedure IlCaricatoreDovrebbeDareIDueProgrammiDelFile;
    [Test]
    procedure IlCaricatoreDovrebbeDireCheIlFileManca;
  end;

  /// <summary>A catalog with one shader file, or none</summary>
  TFakeShaderCatalog = class(TInterfacedObject, IXcomShaderCatalog)
  strict private
    FText: RawByteString;
  public
    constructor Create(const AText: RawByteString);
    function Files: TArray<string>;
    function TryRead(const APath: string; out ABytes: TBytes): Boolean;
  end;

implementation

{ TFakeHostKeyboard }

function TFakeHostKeyboard.Modifiers: TGameHostModifiers;
begin
  Result := Held;
end;

function TFakeHostKeyboard.CharacterOf(AVirtualKey: Cardinal; AScanCode: Cardinal): Cardinal;
begin
  Result := Typed;
end;

{ TFakeXcomLog }

procedure TFakeXcomLog.Write(const ALevel, AMessage: string);
begin
  Lines := Lines + ALevel + ':' + AMessage + '|';
end;

{ TFakePlainHostDisplay }

procedure TFakePlainHostDisplay.SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
begin
end;

procedure TFakePlainHostDisplay.Present(const APixels: TBytes; AWidth, AHeight: Integer;
  const APalette: TGameHostPalette);
begin
  Inc(Presented);
  Red := APalette[7].Red;
end;

procedure TFakePlainHostDisplay.SetTitle(const ATitle: string);
begin
end;

{ TTestXcomHostAdapters }

procedure TTestXcomHostAdapters.Setup;
begin
  FQueue := TXcomQueueEventSource.Create;
  FQueueRef := FQueue;
  FKeyboard := TFakeHostKeyboard.Create;
  FTranslator := TGameHostWinMessageTranslator.Create(TXcomHostEventSink.Create(FQueue), FKeyboard);
  // a window of 640 x 400
  FState := Default(TGameHostWindowState);
  FState.Width := 640;
  FState.Height := 400;
  FState.ClientWidth := 640;
  FState.ClientHeight := 400;
end;

procedure TTestXcomHostAdapters.TearDown;
begin
  FTranslator.Free;
  FQueueRef := nil;
end;

procedure TTestXcomHostAdapters.Send(AMessage: UINT; AWParam: WPARAM; ALParam: LPARAM);
var
  LAnswer: LRESULT;
begin
  FTranslator.Translate(AMessage, AWParam, ALParam, FState, LAnswer);
end;

function TTestXcomHostAdapters.Next: TXcomInputEvent;
begin
  Assert.IsTrue(FQueue.Poll(Result), 'manca un evento nella coda');
end;

procedure TTestXcomHostAdapters.UnTastoConNomeDovrebbeDiventareIlSuoCodiceSdl;
begin
  Send(WM_KEYDOWN, VK_F12, 0);
  Send(WM_KEYDOWN, VK_LEFT, 0);
  Send(WM_KEYDOWN, Ord('A'), 0);
  Send(WM_KEYUP, VK_ESCAPE, 0);
  Assert.AreEqual(293, Next.Key);
  Assert.AreEqual(276, Next.Key);
  Assert.AreEqual(Ord('a'), Next.Key);
  Assert.AreEqual(27, Next.Key);
  Assert.AreEqual(0, FQueue.Pending);
end;

procedure TTestXcomHostAdapters.UnTastoSenzaNomeDovrebbePrendereIlCarattereMinuscolo;
var
  LEvent: TXcomInputEvent;
begin
  FKeyboard.Typed := Ord('?');
  Send(WM_KEYDOWN, VK_OEM_2, 0);
  LEvent := Next;
  Assert.IsTrue(LEvent.Kind = ekKeyDown);
  Assert.AreEqual(Ord('?'), LEvent.Key);
  Assert.AreEqual(Cardinal(Ord('?')), LEvent.Character);
  FKeyboard.Typed := Ord('A');
  Send(WM_KEYDOWN, Ord('A'), 0);
  LEvent := Next;
  Assert.AreEqual(Ord('a'), LEvent.Key);
  Assert.AreEqual(Cardinal(Ord('A')), LEvent.Character, 'il carattere resta quello battuto');
end;

procedure TTestXcomHostAdapters.UnTastoSenzaNomeNeCarattereNonDovrebbeDareEventi;
begin
  Send(WM_KEYDOWN, VK_SHIFT, 0);
  Assert.AreEqual(0, FQueue.Pending);
end;

procedure TTestXcomHostAdapters.IlRilascioDiUnTastoSenzaNomeNonDovrebbeDareEventi;
begin
  FKeyboard.Typed := Ord('?');
  Send(WM_KEYUP, VK_OEM_2, 0);
  Assert.AreEqual(0, FQueue.Pending);
end;

procedure TTestXcomHostAdapters.IModificatoriDovrebberoArrivareAllaCoda;
var
  LEvent: TXcomInputEvent;
begin
  FKeyboard.Held := [hmShift, hmAlt];
  Send(WM_KEYDOWN, VK_RETURN, 0);
  LEvent := Next;
  Assert.AreEqual(XCOM_KMOD_SHIFT or XCOM_KMOD_ALT, LEvent.Modifiers);
  Assert.AreEqual(XCOM_KMOD_SHIFT or XCOM_KMOD_ALT, FQueue.ModifierState);
  FKeyboard.Held := [hmControl];
  Send(WM_MOUSEMOVE, 0, MakeLParam(1, 1));
  Assert.AreEqual(XCOM_KMOD_CTRL, FQueue.ModifierState);
end;

procedure TTestXcomHostAdapters.IlMouseDovrebbeDareBottoneEPosizione;
var
  LEvent: TXcomInputEvent;
begin
  Send(WM_RBUTTONDOWN, 0, MakeLParam(100, 50));
  Send(WM_MBUTTONUP, 0, MakeLParam(101, 51));
  Send(WM_LBUTTONDOWN, 0, MakeLParam(Word(-3), 7));
  LEvent := Next;
  Assert.IsTrue(LEvent.Kind = ekMouseDown);
  Assert.AreEqual(XCOM_BUTTON_RIGHT, LEvent.Button);
  Assert.AreEqual(100, LEvent.X);
  Assert.AreEqual(50, LEvent.Y);
  LEvent := Next;
  Assert.IsTrue(LEvent.Kind = ekMouseUp);
  Assert.AreEqual(XCOM_BUTTON_MIDDLE, LEvent.Button);
  LEvent := Next;
  Assert.AreEqual(XCOM_BUTTON_LEFT, LEvent.Button);
  Assert.AreEqual(-3, LEvent.X, 'il mouse catturato puo'' uscire dalla finestra');
end;

procedure TTestXcomHostAdapters.ASchermoInteroIlMouseDovrebbeTornareNellImmagine;
var
  LEvent: TXcomInputEvent;
begin
  // 640 x 400 on a monitor of 1920 x 1080: the picture is 1728 x 1080, with a band of 96 pixels on each side
  FState.Fullscreen := True;
  FState.ClientWidth := 1920;
  FState.ClientHeight := 1080;
  Send(WM_MOUSEMOVE, 0, MakeLParam(960, 540));
  LEvent := Next;
  Assert.AreEqual(320, LEvent.X);
  Assert.AreEqual(200, LEvent.Y);
  Send(WM_MOUSEMOVE, 0, MakeLParam(96, 0));
  LEvent := Next;
  Assert.AreEqual(0, LEvent.X);
  Assert.AreEqual(0, LEvent.Y);
end;

procedure TTestXcomHostAdapters.LaRotellaASchermoInteroNonDovrebbeScalareDueVolteLaPosizione;
var
  LEvent: TXcomInputEvent;
begin
  // The old window gave the position of the game (already in the picture) to the scaling of the full screen
  // again: the wheel turned at (83, 74) instead of (320, 200)
  FState.Fullscreen := True;
  FState.ClientWidth := 1920;
  FState.ClientHeight := 1080;
  Send(WM_MOUSEMOVE, 0, MakeLParam(960, 540));
  Next;
  Send(WM_MOUSEWHEEL, MakeWParam(0, Word(-120)), MakeLParam(5, 5));
  LEvent := Next;
  Assert.IsTrue(LEvent.Kind = ekMouseDown);
  Assert.AreEqual(XCOM_BUTTON_WHEELDOWN, LEvent.Button);
  Assert.AreEqual(320, LEvent.X);
  Assert.AreEqual(200, LEvent.Y);
  LEvent := Next;
  Assert.IsTrue(LEvent.Kind = ekMouseUp);
  Assert.AreEqual(320, LEvent.X);
  Assert.AreEqual(200, LEvent.Y);
end;

procedure TTestXcomHostAdapters.LaRotellaDovrebbeDarePressioneERilascioDelBottoneGiusto;
var
  LEvent: TXcomInputEvent;
begin
  Send(WM_MOUSEMOVE, 0, MakeLParam(40, 30));
  Next;
  Send(WM_MOUSEWHEEL, MakeWParam(0, 120), 0);
  LEvent := Next;
  Assert.IsTrue(LEvent.Kind = ekMouseDown);
  Assert.AreEqual(XCOM_BUTTON_WHEELUP, LEvent.Button);
  Assert.AreEqual(40, LEvent.X);
  Assert.AreEqual(30, LEvent.Y);
  LEvent := Next;
  Assert.IsTrue(LEvent.Kind = ekMouseUp);
  Assert.AreEqual(XCOM_BUTTON_WHEELUP, LEvent.Button);
  Assert.AreEqual(0, FQueue.Pending);
end;

procedure TTestXcomHostAdapters.LAttivazioneDovrebbeDistinguereFuocoEMinimizzata;
var
  LEvent: TXcomInputEvent;
begin
  Send(WM_ACTIVATE, MakeWParam(WA_ACTIVE, 0), 0);
  Send(WM_ACTIVATE, MakeWParam(WA_INACTIVE, 0), 0);
  Send(WM_ACTIVATE, MakeWParam(WA_INACTIVE, 1), 0);
  LEvent := Next;
  Assert.IsTrue(LEvent.Kind = ekActive);
  Assert.AreEqual(1, LEvent.Key);
  Assert.AreEqual(0, LEvent.Button);
  LEvent := Next;
  Assert.AreEqual(0, LEvent.Key);
  Assert.AreEqual(0, LEvent.Button);
  LEvent := Next;
  Assert.AreEqual(0, LEvent.Key);
  Assert.AreEqual(1, LEvent.Button);
end;

procedure TTestXcomHostAdapters.LaChiusuraDovrebbeDareQuit;
begin
  Send(WM_CLOSE, 0, 0);
  Assert.IsTrue(Next.Kind = ekQuit);
end;

procedure TTestXcomHostAdapters.IlRidimensionamentoDovrebbeDareLaMisuraSenzaToccareIModificatori;
var
  LEvent: TXcomInputEvent;
begin
  FQueue.SetModifiers(XCOM_KMOD_CTRL);
  FState.Resizable := True;
  Send(WM_SIZE, SIZE_RESTORED, MakeLParam(800, 500));
  LEvent := Next;
  Assert.IsTrue(LEvent.Kind = ekResize);
  Assert.AreEqual(800, LEvent.X);
  Assert.AreEqual(500, LEvent.Y);
  Assert.AreEqual(XCOM_KMOD_CTRL, FQueue.ModifierState);
end;

procedure TTestXcomHostAdapters.IlLogDovrebbeUsareILivelliDiOpenXcom;
var
  LLog: TFakeXcomLog;
  LLogRef: IXcomLog;
  LHost: ILog;
begin
  LLog := TFakeXcomLog.Create;
  LLogRef := LLog;
  LHost := TXcomHostLog.Create(LLogRef);
  LHost.Info('a');
  LHost.Warning('b');
  LHost.Error('c');
  Assert.AreEqual('INFO:a|WARN:b|ERROR:c|', LLog.Lines);
  Assert.WillRaise(
    procedure
    begin
      TXcomHostLog.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestXcomHostAdapters.IlDispositivoSenzaFiltroDovrebbeDireCheOpenGlNonEInUso;
var
  LDevice: IXcomVideoDevice;
  LFiltered: IXcomFilteredDisplay;
  LFilter: TXcomDisplayFilter;
  LPixels: TBytes;
  LPalette: TXcomColors;
begin
  LDevice := TXcomHostVideoDevice.Create(TFakePlainHostDisplay.Create);
  LFiltered := LDevice as IXcomFilteredDisplay;
  LFilter := Default(TXcomDisplayFilter);
  LFilter.UseOpenGL := True;
  LFilter.Shader := 'Shaders/Raw.OpenGL.shader';
  LFilter.Smoothing := True;
  LFiltered.SetDisplayFilter(LFilter);
  Assert.IsFalse(LFiltered.DisplayFilter.UseOpenGL);
  Assert.AreEqual('', LFiltered.DisplayFilter.Shader);
  Assert.IsTrue(LFiltered.DisplayFilter.Smoothing);
  SetLength(LPixels, 4);
  FillChar(LPalette, SizeOf(LPalette), 0);
  Assert.IsFalse(LFiltered.PresentUnscaled(LPixels, 2, 2, LPalette, 2, 2, Default(TXcomBlackBands)));
  // a display that is not a window ignores the style and the place
  (LDevice as IXcomWindowStyle).SetWindowStyle(True, True);
  (LDevice as IXcomWindowPlacement).SetWindowPlacement(True, 1, 2, False);
  Assert.WillRaise(
    procedure
    begin
      TXcomHostVideoDevice.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestXcomHostAdapters.IlDispositivoDovrebbePassareLaPalette;
var
  LHost: TFakePlainHostDisplay;
  LDevice: IXcomVideoDevice;
  LPixels: TBytes;
  LPalette: TXcomColors;
begin
  LHost := TFakePlainHostDisplay.Create;
  LDevice := TXcomHostVideoDevice.Create(LHost);
  SetLength(LPixels, 4);
  FillChar(LPalette, SizeOf(LPalette), 0);
  LPalette[7].Red := 201;
  LDevice.Present(LPixels, 2, 2, LPalette);
  Assert.AreEqual(1, LHost.Presented);
  Assert.AreEqual(201, Integer(LHost.Red));
end;

procedure TTestXcomHostAdapters.IlCaricatoreDovrebbeDareIDueProgrammiDelFile;
var
  LLoader: IGameHostShaderLoader;
  LSource: TGameHostShaderSource;
begin
  LLoader := TXcomHostShaderLoader.Create(
    TFakeShaderCatalog.Create('language: GLSL'#10'linear: true'#10'fragment: |'#10'  void main() {}'#10),
    TXcomShaderFileReader.Create(TYamlFactory.CreateParser));
  Assert.IsTrue(LLoader.TryLoad('Shaders/test.opengl.shader', LSource));
  Assert.IsTrue(LSource.IsGlsl);
  Assert.IsTrue(LSource.Linear);
  Assert.IsTrue(Pos(RawByteString('void main() {}'), LSource.Fragment) > 0);
  Assert.AreEqual(0, Length(LSource.Vertex));
end;

procedure TTestXcomHostAdapters.IlCaricatoreDovrebbeDireCheIlFileManca;
var
  LLog: TFakeXcomLog;
  LLogRef: IXcomLog;
  LLoader: IGameHostShaderLoader;
  LSource: TGameHostShaderSource;
begin
  LLog := TFakeXcomLog.Create;
  LLogRef := LLog;
  LLoader := TXcomHostShaderLoader.Create(TFakeShaderCatalog.Create(''),
    TXcomShaderFileReader.Create(TYamlFactory.CreateParser), LLogRef);
  Assert.IsFalse(LLoader.TryLoad('Shaders/none.opengl.shader', LSource));
  Assert.AreEqual('ERROR:requested file not found: Shaders/none.opengl.shader|', LLog.Lines);
end;

{ TFakeShaderCatalog }

constructor TFakeShaderCatalog.Create(const AText: RawByteString);
begin
  inherited Create;
  FText := AText;
end;

function TFakeShaderCatalog.Files: TArray<string>;
begin
  Result := nil;
end;

function TFakeShaderCatalog.TryRead(const APath: string; out ABytes: TBytes): Boolean;
begin
  Result := FText <> '';
  if Result then
    ABytes := BytesOf(FText);
end;

end.
