{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the loop of the program Warcraft32                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.App.Runner;

interface

uses
  System.SysUtils, DelphiDoom.Clock.Intf, DelphiDoom.War.Ui.Intf, DelphiDoom.War.App.Intf,
  DelphiDoom.War.App.Session;

type
  /// <summary>What the loop does with the settings of the game after each frame (the sound follows them)</summary>
  TWarSettingsSink = reference to procedure(const ASettings: IWarGameSettings);

  /// <summary>
  ///   The loop: read the window, take the time of the frame, run the game, show the picture, then do what was asked
  ///   (save or load the quick slot) between two frames. With no clock the frame is always 1/60 of a second and the
  ///   loop goes as fast as the machine can (a run with no window: the same options always give the same game); with
  ///   one the loop waits until 1/60 of a second has passed and gives the game the real time, at most a tenth of a
  ///   second so that a window that was dragged does not make the game jump
  /// </summary>
  TWarRunner = class
  strict private
    FSession: TWarSession;
    FPresenter: IWarFramePresenter;
    FClock: IClock;
    FPump: TWarPump;
    FStorage: IWarSaveStorage;
    FSettingsSink: TWarSettingsSink;
    FPixels: TArray<Cardinal>;
    FSaves: Integer;
    FLoads: Integer;
    FLoadErrors: Integer;
    procedure SaveToSlot;
    procedure LoadFromSlot;
    procedure Say(const AText: string);
    procedure Show;
  public
    /// <summary>
    ///   The session is not owned. The presenter, the clock, the pump, the storage and the sink may be nil (a run with
    ///   no window has none of the first three; with no storage the requests of saving and loading are ignored)
    /// </summary>
    constructor Create(const ASession: TWarSession; const APresenter: IWarFramePresenter; const AClock: IClock;
      const APump: TWarPump; const AStorage: IWarSaveStorage; const ASettingsSink: TWarSettingsSink);
    /// <summary>Runs until the game asks to end, the window is closed or AMaxFrames frames were run (0 = no limit); returns the frames run</summary>
    function Run(AMaxFrames: Integer): Integer;
    /// <summary>The games saved in the slot and the ones loaded from it, and the loads that failed</summary>
    property Saves: Integer read FSaves;
    property Loads: Integer read FLoads;
    property LoadErrors: Integer read FLoadErrors;
  end;

const
  /// <summary>The time of a frame of a run with no clock, and the least a real frame takes: 1/60 of a second</summary>
  WAR_FRAME_SECONDS = 1 / 60;
  /// <summary>The most time that a frame gives the game</summary>
  WAR_MAX_FRAME_SECONDS = 0.1;

implementation

uses
  System.Math, System.Classes, DelphiDoom.War.Save.Types, DelphiDoom.War.App.FrameConverter;

resourcestring
  SWarRunSaved = 'Game saved (%d frames)';
  SWarRunLoaded = 'Game loaded (%d frames)';
  SWarRunLoadFailed = 'The game cannot be loaded: %s';
  SWarRunNothingSaved = 'There is no saved game';
  SWarRunSaveFailed = 'The game cannot be saved: %s';

{ TWarRunner }

constructor TWarRunner.Create(const ASession: TWarSession; const APresenter: IWarFramePresenter;
  const AClock: IClock; const APump: TWarPump; const AStorage: IWarSaveStorage;
  const ASettingsSink: TWarSettingsSink);
begin
  inherited Create;
  if not Assigned(ASession) then
    raise EArgumentNilException.Create('ASession');
  FSession := ASession;
  FPresenter := APresenter;
  FClock := AClock;
  FPump := APump;
  FStorage := AStorage;
  FSettingsSink := ASettingsSink;
end;

procedure TWarRunner.Say(const AText: string);
begin
  if Assigned(FPresenter) then
    FPresenter.SetStatus(AText);
end;

procedure TWarRunner.Show;
begin
  if not Assigned(FPresenter) then
    Exit;
  TWarFrameConverter.ToTrueColor(FSession.Game.Pixels, FSession.Game.Width * FSession.Game.Height, FPixels);
  FPresenter.Present(FPixels, FSession.Game.Width, FSession.Game.Height);
end;

procedure TWarRunner.SaveToSlot;
begin
  if not Assigned(FStorage) then
    Exit;
  try
    FStorage.Write(FSession.Save);
    Inc(FSaves);
    Say(Format(SWarRunSaved, [FSession.FrameCount]));
  except
    on E: EInOutError do
      Say(Format(SWarRunSaveFailed, [E.Message]));
    on E: EWarSaveException do
      Say(Format(SWarRunSaveFailed, [E.Message]));
  end;
end;

procedure TWarRunner.LoadFromSlot;
var
  LBytes: TBytes;
begin
  if not Assigned(FStorage) then
    Exit;
  if not FStorage.TryRead(LBytes) then
  begin
    Inc(FLoadErrors);
    Say(SWarRunNothingSaved);
    Exit;
  end;
  try
    FSession.Load(LBytes);
    Inc(FLoads);
    Say(Format(SWarRunLoaded, [FSession.FrameCount]));
  except
    // the old frames are played again by the game itself: whatever it raises (a mission that the model cannot play,
    // a file that cannot be read) leaves the game that was running where it was
    on E: Exception do
    begin
      Inc(FLoadErrors);
      Say(Format(SWarRunLoadFailed, [E.Message]));
    end;
  end;
end;

function TWarRunner.Run(AMaxFrames: Integer): Integer;
var
  LLast: Double;
  LNow: Double;
  LElapsed: Double;
  LDelta: Single;
begin
  Result := 0;
  LLast := 0;
  if Assigned(FClock) then
    LLast := FClock.Seconds;
  while True do
  begin
    if Assigned(FPump) and not FPump() then
      Break;
    if FSession.Game.QuitRequested then
      Break;
    LDelta := Single(WAR_FRAME_SECONDS);
    if Assigned(FClock) then
    begin
      repeat
        LNow := FClock.Seconds;
        LElapsed := LNow - LLast;
        if LElapsed < WAR_FRAME_SECONDS then
          FClock.Sleep(1);
      until LElapsed >= WAR_FRAME_SECONDS;
      LLast := LNow;
      LDelta := Single(Min(LElapsed, WAR_MAX_FRAME_SECONDS));
    end;
    FSession.RunFrame(LDelta);
    Inc(Result);
    if Assigned(FSettingsSink) then
      FSettingsSink(FSession.Game.Settings);
    Show;
    if FSession.RequestsObject.TakeSave then
      SaveToSlot;
    if FSession.RequestsObject.TakeLoad then
      LoadFromSlot;
    if (AMaxFrames > 0) and (Result >= AMaxFrames) then
      Break;
  end;
end;

end.
