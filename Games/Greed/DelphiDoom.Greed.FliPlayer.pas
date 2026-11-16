{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - a FLI movie on the screen, one tic at a time     }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): DoPlayFLI and _PlayFLI of   }
{  playfli.pas                                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.FliPlayer;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Display, DelphiDoom.Greed.MenuInput, DelphiDoom.Greed.FliDecoder;

type
  /// <summary>
  ///   DoPlayFLI without its loop. Open does what the original does before its first wait (the level under the
  ///   screen is cleared, the screen is filled with ApproxZero, the palette goes black, the first frame is drawn)
  ///   and each Tick is a tic of the timer: when the tics of a frame (the Speed of the header) have passed the
  ///   next one is drawn straight on the canvas of the display, and its colors are shown. The movie ends after the
  ///   last frame (Completed is True) or at the first key (NewAscii of the input: the screen is cleared to 0 and
  ///   Completed is False). A movie whose frames last 0 tics is drawn whole by Open.
  ///   The palette of the movies (flipal) is kept from a movie to the next, as in the original.
  ///   Where the movie is (a file of the folder MOVIES, or a lump of the archive in the demo) is of the caller:
  ///   FindFLIFile and the path of the CD-ROM are not ported
  /// </summary>
  TGreedFliPlayer = class
  strict private
    FDisplay: TGreedDisplay;
    FInput: TGreedMenuInput;
    FPalette: TBytes;
    FDecoder: TGreedFliDecoder;
    FActive: Boolean;
    FCompleted: Boolean;
    FFrame: Integer;
    FDelay: Integer;
    procedure Advance;
    procedure Finish;
  public
    constructor Create(ADisplay: TGreedDisplay; AInput: TGreedMenuInput);
    destructor Destroy; override;
    /// <summary>
    ///   The movie that starts at AOffset of AData. No bytes at all is the movie that the original does not find:
    ///   only the level under the screen is cleared, nothing is played and Completed is False
    /// </summary>
    procedure Open(const AData: TBytes; AOffset: Integer = 0);
    /// <summary>One tic: the timer (Input.TimerTick), then Step. Nothing if no movie is playing</summary>
    procedure Tick;
    /// <summary>The same for who has already counted the tic</summary>
    procedure Step;
    /// <summary>False when DoPlayFLI would have returned</summary>
    property Active: Boolean read FActive;
    /// <summary>The result of DoPlayFLI: the movie was shown to its end</summary>
    property Completed: Boolean read FCompleted;
    /// <summary>currentfliframe: the frames whose time has passed</summary>
    property Frame: Integer read FFrame;
    /// <summary>The movie in course; nil when none was opened</summary>
    property Decoder: TGreedFliDecoder read FDecoder;
  end;

implementation

{ TGreedFliPlayer }

constructor TGreedFliPlayer.Create(ADisplay: TGreedDisplay; AInput: TGreedMenuInput);
begin
  inherited Create;
  if not Assigned(ADisplay) then
    raise EArgumentNilException.Create('ADisplay');
  if not Assigned(AInput) then
    raise EArgumentNilException.Create('AInput');
  FDisplay := ADisplay;
  FInput := AInput;
  SetLength(FPalette, GREED_FLI_PALETTE_BYTES);
end;

destructor TGreedFliPlayer.Destroy;
begin
  FDecoder.Free;
  inherited;
end;

procedure TGreedFliPlayer.Open(const AData: TBytes; AOffset: Integer);
begin
  FreeAndNil(FDecoder);
  FActive := False;
  FCompleted := False;
  FFrame := 0;
  FDisplay.ClearRender;
  if Length(AData) = 0 then
    Exit;
  FInput.NewAscii := False;
  FDisplay.FillScreen(FDisplay.Canvas.ApproxZero);
  FDisplay.FillPalette(0, 0, 0);
  FDecoder := TGreedFliDecoder.Create(AData, AOffset, FPalette);
  FDelay := FInput.TimeCount;
  FActive := True;
  Advance;
end;

procedure TGreedFliPlayer.Advance;
var
  LPixels: TBytes;
begin
  LPixels := FDisplay.Canvas.Pixels;
  while (FFrame < FDecoder.FrameCount) and not FInput.NewAscii do
  begin
    FDelay := FDelay + FDecoder.Speed;
    FDecoder.ApproxZero := FDisplay.Canvas.ApproxZero;
    FDecoder.PaletteChanged := False;
    FDecoder.DecodeFrame(LPixels);
    if FDecoder.PaletteChanged then
      FDisplay.SetPalette(FDecoder.Palette);
    // while not CheckTime(timecount, delay) do Wait(1)
    if FInput.TimeCount < FDelay then
      Exit;
    Inc(FFrame);
  end;
  Finish;
end;

procedure TGreedFliPlayer.Finish;
begin
  FCompleted := FFrame >= FDecoder.FrameCount;
  if not FCompleted then
    FDisplay.FillScreen(0);
  FActive := False;
end;

procedure TGreedFliPlayer.Tick;
begin
  if not FActive then
    Exit;
  FInput.TimerTick;
  Step;
end;

procedure TGreedFliPlayer.Step;
begin
  if not FActive or (FInput.TimeCount < FDelay) then
    Exit;
  Inc(FFrame);
  Advance;
end;

end.
