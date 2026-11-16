{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the time of a game: tics, pictures, the window   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the timer of d_ints.pas     }
{  (dStartTimer at TICRATE) and I_FinishUpdate at the end of PlayLoop           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.GameLoop;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Frame.Intf, DelphiDoom.Clock.Intf,
  DelphiDoom.Greed.Game;

const
  /// <summary>TICRATE: the game runs at 70 tics a second</summary>
  GREED_LOOP_TIC_RATE = 70;
  /// <summary>Tics that the loop catches up at most in one picture (a slow window must not freeze the game)</summary>
  GREED_LOOP_MAX_CATCH_UP = 10;
  /// <summary>Tics between two pictures when the loop does not follow the clock</summary>
  GREED_LOOP_FREE_TICS = 2;

type
  /// <summary>
  ///   Runs a TGreedGame in time: the tics that the clock says must have run (Steps(GREED_LOOP_TIC_RATE)) are
  ///   played with TGreedGame.Tic, then one turn of the game is made (TGreedGame.Frame) and its picture is given
  ///   to the presenter. The original has a timer thread for the tics and draws as fast as it can: here the tics
  ///   are caught up between two pictures. With FreeRunning the clock is not read: every picture comes after
  ///   TicsPerFrame tics, as fast as the machine goes (for the tests and for a game without a window, where the
  ///   same commands always give the same game). The loop ends when the window closes, when the game is over
  ///   (TGreedGame.QuitGame) or after the tics asked for
  /// </summary>
  TGreedGameLoop = class
  strict private
    FGame: TGreedGame;
    FPresenter: IGreedFramePresenter;
    FInput: IGreedInput;
    FClock: IClock;
    FColors: TGreedColors;
    FFrame: TGreedFrame;
    FTics: Integer;
    FFrames: Integer;
    FFreeRunning: Boolean;
    FTicsPerFrame: Integer;
  public
    /// <summary>
    ///   AGame is not owned. The pictures are AFrameWidth x AFrameHeight. EArgumentNilException if the game, the
    ///   presenter, the input or the clock are nil
    /// </summary>
    constructor Create(AGame: TGreedGame; const APresenter: IGreedFramePresenter; const AInput: IGreedInput;
      const AClock: IClock; const AColors: TGreedColors; AFrameWidth, AFrameHeight: Integer);
    /// <summary>One tic of the game</summary>
    procedure Tick;
    /// <summary>One turn of the game and its picture to the presenter</summary>
    procedure Frame;
    /// <summary>Plays until the end (see the class); AMaxTics 0 is no limit. Returns the tics played</summary>
    function Run(AMaxTics: Integer): Integer;
    property FreeRunning: Boolean read FFreeRunning write FFreeRunning;
    property TicsPerFrame: Integer read FTicsPerFrame write FTicsPerFrame;
    /// <summary>The tics and the pictures of this loop (the clock of the game starts again at every map)</summary>
    property Tics: Integer read FTics;
    property Frames: Integer read FFrames;
    property FrameBuffer: TGreedFrame read FFrame;
  end;

implementation

{ TGreedGameLoop }

constructor TGreedGameLoop.Create(AGame: TGreedGame; const APresenter: IGreedFramePresenter;
  const AInput: IGreedInput; const AClock: IClock; const AColors: TGreedColors; AFrameWidth, AFrameHeight: Integer);
begin
  inherited Create;
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  if not Assigned(APresenter) then
    raise EArgumentNilException.Create('APresenter');
  if not Assigned(AInput) then
    raise EArgumentNilException.Create('AInput');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FGame := AGame;
  FPresenter := APresenter;
  FInput := AInput;
  FClock := AClock;
  FColors := AColors;
  FFrame := TGreedFrame.Make(AFrameWidth, AFrameHeight);
  FTicsPerFrame := GREED_LOOP_FREE_TICS;
end;

procedure TGreedGameLoop.Tick;
begin
  FGame.Tic;
  Inc(FTics);
end;

procedure TGreedGameLoop.Frame;
begin
  FGame.Frame(FFrame);
  Inc(FFrames);
  FPresenter.Present(FFrame, FColors);
end;

function TGreedGameLoop.Run(AMaxTics: Integer): Integer;
var
  LTarget, LBehind, LPlayed: Integer;
begin
  Result := 0;
  while FInput.Pump and not FGame.QuitGame do
  begin
    if FFreeRunning then
      LBehind := FTicsPerFrame
    else
    begin
      LTarget := FClock.Steps(GREED_LOOP_TIC_RATE);
      LBehind := LTarget - FTics;
      if LBehind > GREED_LOOP_MAX_CATCH_UP then
      begin
        // the window was too slow: the game does not run all the tics it lost
        FTics := LTarget - GREED_LOOP_MAX_CATCH_UP;
        LBehind := GREED_LOOP_MAX_CATCH_UP;
      end;
    end;
    LPlayed := 0;
    while (LPlayed < LBehind) and ((AMaxTics = 0) or (Result < AMaxTics)) do
    begin
      Tick;
      Inc(LPlayed);
      Inc(Result);
    end;
    Frame;
    if (AMaxTics > 0) and (Result >= AMaxTics) then
      Break;
    if (LPlayed = 0) and not FFreeRunning then
      FClock.Wait(1);
  end;
end;

end.
