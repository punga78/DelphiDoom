{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the sounds of the widgets of the xcom interface    }
{  (the click of a TextButton, the popup of a Window) and of TXcomHostUiSounds  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.UiSounds;

interface

uses
  DelphiDoom.Clock.Intf,
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.InteractiveSurface,
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Screen,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.UiSounds.Intf, DelphiDoom.XcomEngine.HostUiSounds,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.ToggleTextButton,
  DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.ComboBox, DelphiDoom.Tests.XcomEngine.World;

type
  /// <summary>Counts the sounds the widgets ask for</summary>
  TFakeUiSounds = class(TInterfacedObject, IXcomUiSounds)
  public
    Presses: Integer;
    Popups: Integer;
    procedure PlayButtonPress;
    procedure PlayWindowPopup;
  end;

  /// <summary>A host that only has resources and records the sounds it is asked to play</summary>
  TSoundRecordingHost = class(TXcomStateHost)
  strict private
    FResources: IXcomResources;
  public
    Played: TStringList;
    constructor Create(const AResources: IXcomResources);
    destructor Destroy; override;
    function Screen: TXcomScreen; override;
    function Cursor: TXcomInteractiveSurface; override;
    function FpsCounter: TXcomInteractiveSurface; override;
    function Language: TXcomLanguage; override;
    function Resources: IXcomResources; override;
    function Options: TXcomOptions; override;
    function Clock: IClock; override;
    procedure PushState(AState: TXcomState); override;
    procedure PopState; override;
    procedure SetState(AState: TXcomState); override;
    procedure Quit; override;
    procedure AdoptData(const AResources: IXcomResources; ALanguage: TXcomLanguage); override;
    function IsState(AState: TXcomState): Boolean; override;
    procedure PlaySound(const ASet: string; AIndex: Integer; AInterface: Boolean = False); override;
  end;

  [TestFixture]
  [Category('XcomUiSounds')]
  TTestXcomUiSounds = class
  strict private
    FWorld: TTestWorld;
    FSounds: TFakeUiSounds;
    FSoundsRef: IXcomUiSounds;
    FState: TXcomState;
    FGroup: TXcomButtonGroup;
    procedure Show;
    procedure Press(AX, AY, AButton: Integer);
    function NewButton(AHandled: Boolean): TXcomTextButton;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSuonareQuandoSiPremeUnPulsanteConUnGestore;
    [Test]
    procedure NonDovrebbeSuonareUnPulsanteSenzaGestore;
    [Test]
    procedure NonDovrebbeSuonareUnPulsanteDiUnGruppo;
    [Test]
    procedure NonDovrebbeSuonareConLaRotella;
    [Test]
    procedure NonDovrebbeSuonareUnPulsanteAInterruttore;
    [Test]
    procedure DovrebbeSuonareIlPulsanteDiUnaListaATendina;
    [Test]
    procedure DovrebbeSuonareUnaVoltaQuandoUnaFinestraSiApre;
    [Test]
    procedure NonDovrebbeSuonareUnaFinestraSenzaAnimazione;
    [Test]
    procedure IlGiocoDaISuoniAiWidgetDeiSuoiStati;
    [Test]
    procedure IlPulsanteSuonaIlSuonoZeroDiGeoCatAlVolumeDellInterfaccia;
    [Test]
    [TestCase('primo', '0,GEO.CAT:1:ui')]
    [TestCase('secondo', '1,GEO.CAT:2:ui')]
    [TestCase('terzo', '2,GEO.CAT:3:ui')]
    procedure LaFinestraSuonaUnoDeiTreSuoni(AChoice: Integer; const AExpected: string);
  end;

implementation

{ TFakeUiSounds }

procedure TFakeUiSounds.PlayButtonPress;
begin
  Inc(Presses);
end;

procedure TFakeUiSounds.PlayWindowPopup;
begin
  Inc(Popups);
end;

{ TSoundRecordingHost }

constructor TSoundRecordingHost.Create(const AResources: IXcomResources);
begin
  inherited Create;
  FResources := AResources;
  Played := TStringList.Create;
end;

destructor TSoundRecordingHost.Destroy;
begin
  Played.Free;
  inherited Destroy;
end;

function TSoundRecordingHost.Screen: TXcomScreen;
begin
  Result := nil;
end;

function TSoundRecordingHost.Cursor: TXcomInteractiveSurface;
begin
  Result := nil;
end;

function TSoundRecordingHost.FpsCounter: TXcomInteractiveSurface;
begin
  Result := nil;
end;

function TSoundRecordingHost.Language: TXcomLanguage;
begin
  Result := nil;
end;

function TSoundRecordingHost.Resources: IXcomResources;
begin
  Result := FResources;
end;

function TSoundRecordingHost.Options: TXcomOptions;
begin
  Result := nil;
end;

function TSoundRecordingHost.Clock: IClock;
begin
  Result := nil;
end;

procedure TSoundRecordingHost.PushState(AState: TXcomState);
begin
end;

procedure TSoundRecordingHost.PopState;
begin
end;

procedure TSoundRecordingHost.SetState(AState: TXcomState);
begin
end;

procedure TSoundRecordingHost.Quit;
begin
end;

procedure TSoundRecordingHost.AdoptData(const AResources: IXcomResources; ALanguage: TXcomLanguage);
begin
end;

function TSoundRecordingHost.IsState(AState: TXcomState): Boolean;
begin
  Result := False;
end;

procedure TSoundRecordingHost.PlaySound(const ASet: string; AIndex: Integer; AInterface: Boolean);
const
  KIND: array[Boolean] of string = ('sound', 'ui');
begin
  Played.Add(Format('%s:%d:%s', [ASet, AIndex, KIND[AInterface]]));
end;

{ TTestXcomUiSounds }

procedure TTestXcomUiSounds.Setup;
begin
  FWorld := TTestWorld.Create;
  FSounds := TFakeUiSounds.Create;
  FSoundsRef := FSounds;
  FWorld.Game.SetUiSounds(FSoundsRef);
  FGroup := TXcomButtonGroup.Create;
  FState := TXcomState.Create(FWorld.Game);
end;

procedure TTestXcomUiSounds.TearDown;
begin
  FWorld.Free;
  FGroup.Free;
  FSoundsRef := nil;
end;

procedure TTestXcomUiSounds.Show;
begin
  FWorld.Game.SetState(FState);
  FWorld.Wait(20);
end;

procedure TTestXcomUiSounds.Press(AX, AY, AButton: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  // the display is twice the picture of the game
  LEvent.X := AX * 2;
  LEvent.Y := AY * 2;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(5);
  LEvent.Kind := ekMouseDown;
  LEvent.Button := AButton;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(5);
  LEvent.Kind := ekMouseUp;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(5);
end;

function TTestXcomUiSounds.NewButton(AHandled: Boolean): TXcomTextButton;
begin
  Result := TXcomTextButton.Create(60, 20, 10, 10);
  FState.Add(Result);
  if AHandled then
    Result.OnMouseClick(
      procedure(AAction: TXcomAction)
      begin
      end);
end;

procedure TTestXcomUiSounds.DovrebbeSuonareQuandoSiPremeUnPulsanteConUnGestore;
begin
  NewButton(True);
  Show;
  Press(20, 20, XCOM_BUTTON_LEFT);
  Assert.AreEqual(1, FSounds.Presses);
  Press(200, 150, XCOM_BUTTON_LEFT);
  Assert.AreEqual(1, FSounds.Presses, 'un clic fuori dal pulsante non suona');
end;

procedure TTestXcomUiSounds.NonDovrebbeSuonareUnPulsanteSenzaGestore;
begin
  NewButton(False);
  Show;
  Press(20, 20, XCOM_BUTTON_LEFT);
  Assert.AreEqual(0, FSounds.Presses);
end;

procedure TTestXcomUiSounds.NonDovrebbeSuonareUnPulsanteDiUnGruppo;
var
  LButton: TXcomTextButton;
begin
  LButton := NewButton(True);
  LButton.SetGroup(FGroup);
  Show;
  Press(20, 20, XCOM_BUTTON_LEFT);
  Assert.AreSame(LButton, FGroup.Selected, 'il clic e'' arrivato');
  Assert.AreEqual(0, FSounds.Presses);
end;

procedure TTestXcomUiSounds.NonDovrebbeSuonareConLaRotella;
var
  LButton: TXcomTextButton;
begin
  LButton := NewButton(False);
  LButton.OnMousePress(
    procedure(AAction: TXcomAction)
    begin
    end);
  Show;
  Press(20, 20, XCOM_BUTTON_WHEELUP);
  Press(20, 20, XCOM_BUTTON_WHEELDOWN);
  Assert.AreEqual(0, FSounds.Presses);
  Press(20, 20, XCOM_BUTTON_RIGHT);
  Assert.AreEqual(1, FSounds.Presses, 'ogni altro pulsante del mouse suona');
end;

procedure TTestXcomUiSounds.NonDovrebbeSuonareUnPulsanteAInterruttore;
var
  LButton: TXcomToggleTextButton;
begin
  LButton := TXcomToggleTextButton.Create(60, 20, 10, 10);
  FState.Add(LButton);
  LButton.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
    end);
  Show;
  Press(20, 20, XCOM_BUTTON_LEFT);
  Assert.AreEqual(0, FSounds.Presses);
end;

procedure TTestXcomUiSounds.DovrebbeSuonareIlPulsanteDiUnaListaATendina;
var
  LCombo: TXcomComboBox;
begin
  LCombo := TXcomComboBox.Create(FState, 100, 16, 10, 10);
  FState.Add(LCombo);
  LCombo.SetOptions(['ONE', 'TWO']);
  Show;
  Press(20, 15, XCOM_BUTTON_LEFT);
  Assert.AreEqual(1, FSounds.Presses);
end;

procedure TTestXcomUiSounds.DovrebbeSuonareUnaVoltaQuandoUnaFinestraSiApre;
begin
  FState.Add(TXcomWindow.Create(FState, 200, 100, 20, 20, wpBoth));
  FWorld.Game.SetState(FState);
  FWorld.Wait(15);
  Assert.AreEqual(1, FSounds.Popups, 'al primo passo dell''animazione');
  FWorld.Wait(500);
  Assert.AreEqual(1, FSounds.Popups);
end;

procedure TTestXcomUiSounds.NonDovrebbeSuonareUnaFinestraSenzaAnimazione;
begin
  FState.Add(TXcomWindow.Create(FState, 200, 100, 20, 20, wpNone));
  FWorld.Game.SetState(FState);
  FWorld.Wait(300);
  Assert.AreEqual(0, FSounds.Popups);
end;

procedure TTestXcomUiSounds.IlGiocoDaISuoniAiWidgetDeiSuoiStati;
var
  LWorld: TTestWorld;
begin
  LWorld := TTestWorld.Create;
  try
    Assert.IsNotNull(LWorld.Game.UiSounds, 'il gioco nasce con i suoni dell''interfaccia');
    LWorld.Game.SetUiSounds(nil);
    Assert.IsNull(LWorld.Game.UiSounds);
  finally
    LWorld.Free;
  end;
end;

procedure TTestXcomUiSounds.IlPulsanteSuonaIlSuonoZeroDiGeoCatAlVolumeDellInterfaccia;
var
  LHost: TSoundRecordingHost;
  LSounds: IXcomUiSounds;
begin
  LHost := TSoundRecordingHost.Create(TFakeResources.Create);
  try
    LSounds := TXcomHostUiSounds.Create(LHost);
    LSounds.PlayButtonPress;
    Assert.AreEqual('GEO.CAT:0:ui', LHost.Played.CommaText);
    LSounds := nil;
  finally
    LHost.Free;
  end;
end;

procedure TTestXcomUiSounds.LaFinestraSuonaUnoDeiTreSuoni(AChoice: Integer; const AExpected: string);
var
  LHost: TSoundRecordingHost;
  LSounds: IXcomUiSounds;
begin
  LHost := TSoundRecordingHost.Create(TFakeResources.Create);
  try
    LSounds := TXcomHostUiSounds.Create(LHost,
      function(ACount: Integer): Integer
      begin
        Assert.AreEqual(3, ACount);
        Result := AChoice;
      end);
    LSounds.PlayWindowPopup;
    Assert.AreEqual(AExpected, LHost.Played.CommaText);
    LSounds := nil;
  finally
    LHost.Free;
  end;
end;

end.
