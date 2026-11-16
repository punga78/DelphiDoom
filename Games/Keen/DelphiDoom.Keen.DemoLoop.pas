{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the start screens and the games one after the     }
{  other                                                                        }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  DemoLoop of kd_demo.c                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.DemoLoop;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf,
  DelphiDoom.Keen.Shape;

const
  /// <summary>The tics that the title, the title again (the credits of other versions) and the scores stay on the screen</summary>
  KEEN_TITLE_TICS = KEEN_TICKBASE * 4;
  KEEN_TITLE_AGAIN_TICS = KEEN_TICKBASE * 3;
  KEEN_SCORES_TICS = KEEN_TICKBASE * 6;

type
  /// <summary>
  ///   What the program does from its start to its end: the title picture and the scores take turns until a key
  ///   is pressed, then the control panel; when the panel starts or loads a game the game is played, and after it
  ///   the title comes back. Keen Dreams has no recorded demos, whatever the name of the function says. The loop
  ///   never ends by itself: leaving is the EKeenQuitException of the control panel (or of the program)
  /// </summary>
  TKeenDemoLoop = class
  strict private
    FTitle: TKeenShape;
    FWindows: IKeenUserWindows;
    FVideo: IKeenBufferedVideo;
    FInput: IKeenInput;
    FScores: IKeenHighScores;
    FPanel: IKeenControlPanel;
    FState: IKeenUserState;
    FGame: IKeenGame;
    FSavedOffsets: Boolean;
    FBufferSave: Integer;
    FDisplaySave: Integer;
    procedure ShowTitle;
  public
    /// <param name="ATitle">TITLESCR.LBM of KDREAMS.CMP</param>
    constructor Create(const ATitle: TKeenShape; const AWindows: IKeenUserWindows; const AInput: IKeenInput;
      const AScores: IKeenHighScores; const APanel: IKeenControlPanel; const AState: IKeenUserState;
      const AGame: IKeenGame);
    /// <summary>The title and the scores until a key, then the control panel, until a game is started or loaded</summary>
    procedure RunAttract;
    /// <summary>DemoLoop</summary>
    procedure Run;
  end;

implementation

{ TKeenDemoLoop }

constructor TKeenDemoLoop.Create(const ATitle: TKeenShape; const AWindows: IKeenUserWindows; const AInput: IKeenInput;
  const AScores: IKeenHighScores; const APanel: IKeenControlPanel; const AState: IKeenUserState;
  const AGame: IKeenGame);
begin
  inherited Create;
  if not Assigned(AWindows) then
    raise EArgumentNilException.Create('AWindows');
  if not Assigned(AInput) then
    raise EArgumentNilException.Create('AInput');
  if not Assigned(AScores) then
    raise EArgumentNilException.Create('AScores');
  if not Assigned(APanel) then
    raise EArgumentNilException.Create('APanel');
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  FTitle := ATitle;
  FWindows := AWindows;
  FVideo := AWindows.Video;
  FInput := AInput;
  FScores := AScores;
  FPanel := APanel;
  FState := AState;
  FGame := AGame;
end;

procedure TKeenDemoLoop.ShowTitle;
var
  LRaw: IKeenVideo;
begin
  // the picture is unpacked 200 rows down, where it is not seen, and then copied to the top of the memory
  LRaw := FVideo.Video;
  TKeenShapeReader.MoveGfxDst(LRaw, 0, 200);
  TKeenShapeReader.UnpackToScreen(LRaw, FTitle, 0, 0);
  LRaw.ScreenToScreen(64 * 200, 0, 40, 200);
end;

procedure TKeenDemoLoop.RunAttract;
var
  LRaw: IKeenVideo;
begin
  LRaw := FVideo.Video;
  // bufsave and dissave of the C: the pages as they were when the loop started, once
  if not FSavedOffsets then
  begin
    FSavedOffsets := True;
    FBufferSave := LRaw.BufferOfs;
    FDisplaySave := LRaw.DisplayOfs;
  end;
  while (FState.RestartGame = kgdContinue) and not FState.LoadedGame do
  begin
    FVideo.InitDoubleBuffer;
    FInput.ClearKeysDown;
    while True do
    begin
      LRaw.SetScreen(0, 0);
      ShowTitle;
      if FInput.UserInput(KEEN_TITLE_TICS, False) then
        Break;
      // the versions with the credits show them here; this one shows the title again
      ShowTitle;
      if FInput.UserInput(KEEN_TITLE_AGAIN_TICS, False) then
        Break;
      LRaw.DisplayOfs := 0;
      FVideo.Bar(0, 0, KEEN_MAX_X, KEEN_MAX_Y, KEEN_FIRSTCOLOR);
      FScores.Display(-1);
      if FInput.UserInput(KEEN_SCORES_TICS, False) then
        Break;
    end;
    LRaw.BufferOfs := FBufferSave;
    LRaw.DisplayOfs := FDisplaySave;
    FVideo.FixRefreshBuffer;
    FPanel.Run;
  end;
end;

procedure TKeenDemoLoop.Run;
begin
  FState.RestartGame := kgdContinue;
  while True do
  begin
    FState.LoadedGame := False;
    RunAttract;
    if not FState.LoadedGame then
      FGame.NewGame;
    FGame.GameLoop;
  end;
end;

end.
