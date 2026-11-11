{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - StartState of OpenXcom (the DOS style start  }
{  screen that shows the loading)                                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.StartState;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Font, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.Timer,
  DelphiDoom.XcomEngine.GameLoadTask, DelphiDoom.XcomUi.Text;

type
  /// <summary>
  ///   The first screen: a black terminal with the lines of a DOS startup ("Loading OpenXcom 1.0 Dev...") while the
  ///   data loads in the task. When the loading ends it goes to the main menu; if it fails it shows the error and
  ///   waits for a key. The intro movie that follows a change of master mod is not ported
  /// </summary>
  TXcomStartState = class(TXcomState)
  strict private
    FTask: TXcomGameLoadTask;
    FFont: TXcomFont;
    FLanguage: TXcomLanguage;
    FText: TXcomText;
    FCursor: TXcomText;
    FTimer: TXcomTimer;
    FDosPath: string;
    FVersionText: string;
    FOutput: string;
    FAnimation: Integer;
    FDone: Boolean;
    FStarted: Boolean;
    procedure Animate;
    procedure AddLine(const ALine: string);
  public
    /// <param name="ATask">The loading; the state owns it</param>
    /// <param name="ADosPath">What CrossPlatform::getDosPath gives, for the first line</param>
    /// <param name="AVersionText">OPENXCOM_VERSION_SHORT and OPENXCOM_VERSION_GIT, as they are written on the screen</param>
    constructor Create(AHost: TXcomStateHost; ATask: TXcomGameLoadTask; const ADosPath, AVersionText: string);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
    procedure Handle(AAction: TXcomAction); override;
  end;

implementation

uses
  System.Classes, DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.Screen,
  DelphiDoom.XcomEngine.TerminalFont, DelphiDoom.XcomMenu.GoToMainMenuState, DelphiDoom.XcomMenu.CutsceneState;

constructor TXcomStartState.Create(AHost: TXcomStateHost; ATask: TXcomGameLoadTask; const ADosPath,
  AVersionText: string);
var
  LColors: TArray<TXcomColor>;
begin
  inherited Create(AHost);
  FTask := ATask;
  FDosPath := ADosPath;
  FVersionText := AVersionText;
  // updateScale() uses newDisplayWidth/Height
  Host.Options.NewDisplayWidth := Host.Options.DisplayWidth;
  Host.Options.NewDisplayHeight := Host.Options.DisplayHeight;
  TXcomScreen.UpdateScale(Host.Options, Host.Options.GeoscapeScale, Host.Options.BaseXGeoscape,
    Host.Options.BaseYGeoscape, False);
  TXcomScreen.UpdateScale(Host.Options, Host.Options.BattlescapeScale, Host.Options.BaseXBattlescape,
    Host.Options.BaseYBattlescape, False);
  Host.Options.BaseXResolution := Host.Options.DisplayWidth;
  Host.Options.BaseYResolution := Host.Options.DisplayHeight;
  Host.Screen.ResetDisplay(False);
  FFont := TXcomTerminalFont.Create;
  FLanguage := TXcomLanguage.Create(Host.Options.Language, Host.Options.Wordwrap, nil, nil);
  FText := TXcomText.Create(Host.Options.BaseXResolution, Host.Options.BaseYResolution, 0, 0);
  FCursor := TXcomText.Create(FFont.Width, FFont.Height, 0, 0);
  FTimer := TXcomTimer.Create(Host.Clock, 150);
  LColors := TXcomTerminalFont.Colors;
  SetPalette(@LColors[0], 0, 2);
  Add(FText);
  Add(FCursor);
  FText.InitText(FFont, FFont, FLanguage);
  FText.SetColor(0);
  FText.SetWordWrap(True);
  FCursor.InitText(FFont, FFont, FLanguage);
  FCursor.SetColor(0);
  FCursor.SetText('_');
  FTimer.OnTimerState(
    procedure
    begin
      Animate;
    end);
  FTimer.Start;
  Host.Cursor.Visible := False;
  Host.FpsCounter.Visible := False;
  if Host.Options.Reload then
  begin
    AddLine('Restarting...');
    AddLine('');
  end
  else
    AddLine(FDosPath + '>openxcom');
end;

destructor TXcomStartState.Destroy;
begin
  FTask.Free;
  FTimer.Free;
  // the text surfaces are owned by the state (freed by the inherited destructor) and use the font and the language
  inherited Destroy;
  FLanguage.Free;
  FFont.Free;
end;

procedure TXcomStartState.Init;
begin
  inherited Init;
  if not FStarted then
  begin
    FStarted := True;
    FTask.Start;
  end;
end;

procedure TXcomStartState.Think;
var
  LResources: IXcomResources;
  LLanguage: TXcomLanguage;
begin
  inherited Think;
  FTimer.Think(True, False, function: Boolean
    begin
      Result := Host.IsState(Self);
    end);
  if FDone then
    Exit;
  case FTask.Status of
    lsFailed:
      begin
        AddLine('');
        AddLine('ERROR: ' + FTask.Error);
        AddLine('');
        AddLine('More details here: openxcom.log');
        AddLine('Make sure OpenXcom and any mods are installed correctly.');
        AddLine('');
        AddLine('Press any key to continue.');
        FDone := True;
      end;
    lsSuccessful:
      begin
        FDone := True;
        FTask.TakeResult(LResources, LLanguage);
        Host.AdoptData(LResources, LLanguage);
        if Host.Options.Reload then
          Host.Options.Reload := False;
        Host.Cursor.Visible := True;
        Host.FpsCounter.Visible := Host.Options.FpsCounter;
        // SetState frees this state at the start of the next turn
        Host.SetState(TXcomGoToMainMenuState.Create(Host, FVersionText));
        // the master is new for this run (there is no reload of the mods): the introduction plays over the menu
        if Host.Options.PlayIntro then
          Host.PushState(TXcomCutsceneState.Create(Host, XCOM_CUTSCENE_INTRO));
      end;
  end;
end;

procedure TXcomStartState.Handle(AAction: TXcomAction);
begin
  inherited Handle(AAction);
  if FDone and (FTask.Status = lsFailed) and (AAction.Details^.Kind = ekKeyDown) then
    Host.Quit;
end;

procedure TXcomStartState.Animate;
var
  LLine: string;
begin
  FCursor.Visible := not FCursor.Visible;
  Inc(FAnimation);
  if FTask.Status in [lsNotStarted, lsRunning] then
  begin
    LLine := 'Loading OpenXcom ' + FVersionText + '...';
    if Host.Options.Reload then
    begin
      if FAnimation = 2 then
        AddLine(LLine);
    end
    else
      case FAnimation of
        1:
          begin
            AddLine('DOS/4GW Protected Mode Run-time  Version 1.9');
            AddLine('Copyright (c) Rational Systems, Inc. 1990-1993');
          end;
        6:
          begin
            AddLine('');
            AddLine('OpenXcom initialisation');
          end;
        7:
          begin
            AddLine('');
            if Host.Options.Mute then
              AddLine('No Sound Detected')
            else
            begin
              AddLine('SoundBlaster Sound Effects');
              AddLine('SoundBlaster Music');
              AddLine('Base Port 220  Irq 7  Dma 1');
            end;
            AddLine('');
          end;
        9:
          AddLine(LLine);
      end;
  end;
end;

procedure TXcomStartState.AddLine(const ALine: string);
var
  LY: Integer;
  LX: Integer;
begin
  FOutput := FOutput + #10 + ALine;
  FText.SetText(FOutput);
  LY := FText.GetTextHeight - FFont.Height;
  LX := FText.GetTextWidth(LY div FFont.Height);
  FCursor.X := LX;
  FCursor.Y := LY;
end;

end.
