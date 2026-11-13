{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the notifications done between two frames              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.DeferredNotifications;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Video.Intf;

type
  /// <summary>Writes what it is asked to do</summary>
  TRecordingApplier = class(TInterfacedObject, IDisplayModeApplier)
  private
    FLog: TStringList;
  public
    constructor Create(ALog: TStringList);
    procedure ApplyDisplayMode(AWidth, AHeight: Integer);
    procedure ApplyGLDisplayMode;
  end;

  [TestFixture]
  [Category('video')]
  TTestVideoDeferredNotifications = class(TObject)
  private
    FLog: TStringList;
    FNotifications: IDeferredNotifications;
    function Joined: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnApplicatoreNil;
    [Test]
    procedure DovrebbeNonFareNienteSenzaRichieste;
    [Test]
    procedure DovrebbeCambiareIlModoSoloAlRun;
    [Test]
    procedure DovrebbeUsareLUltimaRichiestaDelModo;
    [Test]
    procedure DovrebbeDimenticareLaRichiestaDopoIlRun;
    [Test]
    procedure DovrebbeFareIlModoPrimaDellaFinestraOpenGl;
    [Test]
    procedure DovrebbeAvvisareLaFinestraOpenGlUnaVoltaSola;
  end;

implementation

uses
  DelphiDoom.Video.Factory, DelphiDoom.Video.DeferredNotifications;

{ TRecordingApplier }

constructor TRecordingApplier.Create(ALog: TStringList);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TRecordingApplier.ApplyDisplayMode(AWidth, AHeight: Integer);
begin
  FLog.Add(Format('mode %dx%d', [AWidth, AHeight]));
end;

procedure TRecordingApplier.ApplyGLDisplayMode;
begin
  FLog.Add('gl');
end;

{ TTestVideoDeferredNotifications }

function TTestVideoDeferredNotifications.Joined: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FLog.Count - 1 do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + FLog[LIndex];
  end;
end;

procedure TTestVideoDeferredNotifications.Setup;
begin
  FLog := TStringList.Create;
  FNotifications := TVideoFactory.CreateDeferredNotifications(TRecordingApplier.Create(FLog));
end;

procedure TTestVideoDeferredNotifications.TearDown;
begin
  FNotifications := nil;
  FLog.Free;
end;

procedure TTestVideoDeferredNotifications.DovrebbeRifiutareUnApplicatoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TDeferredNotifications.Create(nil);
    end,
    EArgumentNilException);
end;

procedure TTestVideoDeferredNotifications.DovrebbeNonFareNienteSenzaRichieste;
begin
  FNotifications.Run;
  Assert.AreEqual(0, FLog.Count);
end;

procedure TTestVideoDeferredNotifications.DovrebbeCambiareIlModoSoloAlRun;
begin
  FNotifications.NotifyVideoModeChange(800, 600);
  Assert.AreEqual(0, FLog.Count);
  FNotifications.Run;
  Assert.AreEqual('mode 800x600', Joined);
end;

procedure TTestVideoDeferredNotifications.DovrebbeUsareLUltimaRichiestaDelModo;
begin
  FNotifications.NotifyVideoModeChange(800, 600);
  FNotifications.NotifyVideoModeChange(1024, 768);
  FNotifications.Run;
  Assert.AreEqual('mode 1024x768', Joined);
end;

procedure TTestVideoDeferredNotifications.DovrebbeDimenticareLaRichiestaDopoIlRun;
begin
  FNotifications.NotifyVideoModeChange(640, 480);
  FNotifications.Run;
  FNotifications.Run;
  Assert.AreEqual(1, FLog.Count);
end;

procedure TTestVideoDeferredNotifications.DovrebbeFareIlModoPrimaDellaFinestraOpenGl;
begin
  FNotifications.NotifyGLDisplayMode;
  FNotifications.NotifyVideoModeChange(640, 480);
  FNotifications.Run;
  Assert.AreEqual('mode 640x480,gl', Joined);
end;

procedure TTestVideoDeferredNotifications.DovrebbeAvvisareLaFinestraOpenGlUnaVoltaSola;
begin
  FNotifications.NotifyGLDisplayMode;
  FNotifications.NotifyGLDisplayMode;
  FNotifications.Run;
  FNotifications.Run;
  Assert.AreEqual('gl', Joined);
end;

end.
