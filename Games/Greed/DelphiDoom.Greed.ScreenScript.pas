{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - a sequence of screens, fades, texts and movies   }
{  run one tic at a time                                                        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the statements that         }
{  DemoIntro of intro.pas and MissionBriefing and EndGame1..3 of utils.pas are  }
{  made of                                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.ScreenScript;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Font, DelphiDoom.Greed.TextPrinter,
  DelphiDoom.Greed.PaletteFader, DelphiDoom.Greed.Display, DelphiDoom.Greed.MenuInput, DelphiDoom.Greed.FliPlayer;

type
  /// <summary>What a script does when loadscreen does not find the picture</summary>
  TGreedScriptMissing = (gsmContinue, gsmStop, gsmSkip);

  /// <summary>
  ///   The title screens, the mission briefings and the endings of the original are straight runs of the same few
  ///   statements with a wait between them (loadscreen, VI_FadeIn, Wait, a text printed in nine shades, "wait for a
  ///   key", DoPlayFLI ...). Here such a run is a list of steps, added with the methods below in the order of the
  ///   original, and Start and Tick execute it: every step that does not wait runs at once, a step that waits
  ///   takes the tics that the original takes, and what is drawn or shown changes on the display at the same tic.
  ///   Active is false when the original routine would have returned.
  ///   A fade starts, as VI_FadeIn and VI_FadeOut, from the palette read back from the screen (the one shown, with
  ///   the color 0 black) and shows one step for each tic.
  ///   OnTimer is the timer hook of the original (IntroCommand) and runs at each Tick after the keys are read;
  ///   ExitCheck is CheckDemoExit. The movies are asked by name to AMovies (nil, or a name that is not there: the
  ///   movie is not played, as when the original does not find the file)
  /// </summary>
  TGreedScreenScript = class
  strict private
    type
      TOpKind = (okFillPalette, okLoadScreen, okFadeIn, okFadeOut, okWait, okShowColors, okPaletteLump,
        okFillScreen, okFont, okBaseColor, okTextFade, okClearNewAscii, okWaitKey, okWaitChecked, okExitIfChecked,
        okMovie, okJumpIfEscape, okRawPrint, okCall, okLabel);
      TOp = record
        Kind: TOpKind;
        A, B, C, D: Integer;
        Name: string;
        Texts: TArray<string>;
        Proc: TProc;
      end;
      TState = (ssIdle, ssWait, ssFade, ssTextFade, ssWaitKey, ssWaitChecked, ssMovie);
    var
      FDisplay: TGreedDisplay;
      FInput: TGreedMenuInput;
      FPrinter: TGreedTextPrinter;
      FFont: TGreedFont;
      FPlayer: TGreedFliPlayer;
      FMovies: IGreedExternalFiles;
      FFader: TGreedPaletteFader;
      FOps: TArray<TOp>;
      FIndex: Integer;
      FState: TState;
      FActive: Boolean;
      FWaitUntil: Integer;
      FCount: Integer;
      FColor: Integer;
      FOnTimer: TProc;
      FExitCheck: TFunc<Boolean>;
    function Add(AKind: TOpKind): Integer;
    function ShownPalette: TBytes;
    function Checked: Boolean;
    procedure JumpTo(ALabel: Integer);
    procedure Run;
    procedure ContinueTextFade;
    procedure Next;
  public
    /// <summary>
    ///   EArgumentNilException for a missing dependency (AMovies may be nil). Nothing is owned. AFont1 is FONT1
    /// </summary>
    constructor Create(ADisplay: TGreedDisplay; AInput: TGreedMenuInput; APrinter: TGreedTextPrinter;
      AFont1: TGreedFont; APlayer: TGreedFliPlayer; const AMovies: IGreedExternalFiles);
    destructor Destroy; override;
    /// <summary>Removes the steps (a script that is running stops)</summary>
    procedure Clear;
    /// <summary>VI_FillPalette</summary>
    procedure FillPalette(ARed, AGreen, ABlue: Integer);
    /// <summary>
    ///   loadscreen. If the picture is not there: gsmContinue goes on, gsmStop ends the script ("if not loadscreen
    ///   then exit"), gsmSkip goes on after the step Mark(ASkipLabel) ("if loadscreen then begin ... end")
    /// </summary>
    procedure LoadScreen(const AName: string; AMissing: TGreedScriptMissing = gsmContinue; ASkipLabel: Integer = 0);
    /// <summary>VI_FadeIn(0, 256, @colors, steps)</summary>
    procedure FadeIn(ASteps: Integer);
    /// <summary>VI_FadeOut(0, 256, red, green, blue, steps)</summary>
    procedure FadeOut(ARed, AGreen, ABlue, ASteps: Integer);
    /// <summary>Wait(tics)</summary>
    procedure Wait(ATics: Integer);
    /// <summary>I_SetPalette(@colors)</summary>
    procedure ShowColors;
    /// <summary>I_SetPalette(CA_CachePalette(CA_GetNamedNum(name)))</summary>
    procedure ShowPaletteLump(const AName: string);
    /// <summary>memset(screen, value, 64000)</summary>
    procedure FillScreen(AValue: Integer);
    /// <summary>font := font1</summary>
    procedure UseFont;
    /// <summary>fontbasecolor := value</summary>
    procedure BaseColor(AValue: Integer);
    /// <summary>
    ///   fontbasecolor := first; while fontbasecolor &lt; last: printy := y, FN_PrintCentered of each text,
    ///   Wait(tics) if tics is not 0, inc(fontbasecolor)
    /// </summary>
    procedure TextFade(AY: Integer; const ATexts: array of string; AFirstColor, ALastColor, AWaitTics: Integer);
    /// <summary>newascii := false</summary>
    procedure ClearNewAscii;
    /// <summary>while true: Wait(tics); if newascii then break</summary>
    procedure WaitKey(ATics: Integer = 10);
    /// <summary>for count times: Wait(tics); if ExitCheck then exit</summary>
    procedure WaitChecked(ACount, ATics: Integer);
    /// <summary>if ExitCheck then exit</summary>
    procedure ExitIfChecked;
    /// <summary>DoPlayFLI(name, 0)</summary>
    procedure Movie(const AName: string);
    /// <summary>if lastascii = #27 then goto the step Mark(label)</summary>
    procedure JumpIfEscape(ALabel: Integer);
    /// <summary>printx := x; printy := y; FN_RawPrint3(text)</summary>
    procedure RawPrint(AX, AY: Integer; const AText: string);
    /// <summary>Anything else the original does at that point (a song, the player)</summary>
    procedure Call(const AProc: TProc);
    /// <summary>A place where JumpIfEscape and LoadScreen with gsmSkip go</summary>
    procedure Mark(ALabel: Integer);
    /// <summary>Runs the steps up to the first that waits</summary>
    procedure Start;
    /// <summary>One tic: the timer (Input.TimerTick), OnTimer, then Step. Nothing if the script is not running</summary>
    procedure Tick;
    /// <summary>The same for who has already counted the tic and run its hook</summary>
    procedure Step;
    /// <summary>Ends the script where it is</summary>
    procedure Stop;
    property Active: Boolean read FActive;
    property OnTimer: TProc read FOnTimer write FOnTimer;
    property ExitCheck: TFunc<Boolean> read FExitCheck write FExitCheck;
    property Display: TGreedDisplay read FDisplay;
    property Input: TGreedMenuInput read FInput;
    property Printer: TGreedTextPrinter read FPrinter;
  end;

implementation

uses
  DelphiDoom.Greed.Types;

const
  SGreedScriptLabel = 'Greed: the screen script has no label %d after the step %d';

{ TGreedScreenScript }

constructor TGreedScreenScript.Create(ADisplay: TGreedDisplay; AInput: TGreedMenuInput;
  APrinter: TGreedTextPrinter; AFont1: TGreedFont; APlayer: TGreedFliPlayer; const AMovies: IGreedExternalFiles);
begin
  inherited Create;
  if not Assigned(ADisplay) then
    raise EArgumentNilException.Create('ADisplay');
  if not Assigned(AInput) then
    raise EArgumentNilException.Create('AInput');
  if not Assigned(APrinter) then
    raise EArgumentNilException.Create('APrinter');
  if not Assigned(AFont1) then
    raise EArgumentNilException.Create('AFont1');
  if not Assigned(APlayer) then
    raise EArgumentNilException.Create('APlayer');
  FDisplay := ADisplay;
  FInput := AInput;
  FPrinter := APrinter;
  FFont := AFont1;
  FPlayer := APlayer;
  FMovies := AMovies;
  FFader := TGreedPaletteFader.Create;
end;

destructor TGreedScreenScript.Destroy;
begin
  FFader.Free;
  inherited;
end;

procedure TGreedScreenScript.Clear;
begin
  FOps := nil;
  FIndex := 0;
  FState := ssIdle;
  FActive := False;
end;

function TGreedScreenScript.Add(AKind: TOpKind): Integer;
begin
  Result := Length(FOps);
  SetLength(FOps, Result + 1);
  FOps[Result] := Default(TOp);
  FOps[Result].Kind := AKind;
end;

procedure TGreedScreenScript.FillPalette(ARed, AGreen, ABlue: Integer);
var
  LOp: Integer;
begin
  LOp := Add(okFillPalette);
  FOps[LOp].A := ARed;
  FOps[LOp].B := AGreen;
  FOps[LOp].C := ABlue;
end;

procedure TGreedScreenScript.LoadScreen(const AName: string; AMissing: TGreedScriptMissing; ASkipLabel: Integer);
var
  LOp: Integer;
begin
  LOp := Add(okLoadScreen);
  FOps[LOp].Name := AName;
  FOps[LOp].A := Ord(AMissing);
  FOps[LOp].B := ASkipLabel;
end;

procedure TGreedScreenScript.FadeIn(ASteps: Integer);
begin
  FOps[Add(okFadeIn)].A := ASteps;
end;

procedure TGreedScreenScript.FadeOut(ARed, AGreen, ABlue, ASteps: Integer);
var
  LOp: Integer;
begin
  LOp := Add(okFadeOut);
  FOps[LOp].A := ARed;
  FOps[LOp].B := AGreen;
  FOps[LOp].C := ABlue;
  FOps[LOp].D := ASteps;
end;

procedure TGreedScreenScript.Wait(ATics: Integer);
begin
  FOps[Add(okWait)].A := ATics;
end;

procedure TGreedScreenScript.ShowColors;
begin
  Add(okShowColors);
end;

procedure TGreedScreenScript.ShowPaletteLump(const AName: string);
begin
  FOps[Add(okPaletteLump)].Name := AName;
end;

procedure TGreedScreenScript.FillScreen(AValue: Integer);
begin
  FOps[Add(okFillScreen)].A := AValue;
end;

procedure TGreedScreenScript.UseFont;
begin
  Add(okFont);
end;

procedure TGreedScreenScript.BaseColor(AValue: Integer);
begin
  FOps[Add(okBaseColor)].A := AValue;
end;

procedure TGreedScreenScript.TextFade(AY: Integer; const ATexts: array of string; AFirstColor, ALastColor,
  AWaitTics: Integer);
var
  LOp: Integer;
  LIndex: Integer;
begin
  LOp := Add(okTextFade);
  FOps[LOp].A := AY;
  FOps[LOp].B := AFirstColor;
  FOps[LOp].C := ALastColor;
  FOps[LOp].D := AWaitTics;
  SetLength(FOps[LOp].Texts, Length(ATexts));
  for LIndex := 0 to High(ATexts) do
    FOps[LOp].Texts[LIndex] := ATexts[LIndex];
end;

procedure TGreedScreenScript.ClearNewAscii;
begin
  Add(okClearNewAscii);
end;

procedure TGreedScreenScript.WaitKey(ATics: Integer);
begin
  FOps[Add(okWaitKey)].A := ATics;
end;

procedure TGreedScreenScript.WaitChecked(ACount, ATics: Integer);
var
  LOp: Integer;
begin
  LOp := Add(okWaitChecked);
  FOps[LOp].A := ACount;
  FOps[LOp].B := ATics;
end;

procedure TGreedScreenScript.ExitIfChecked;
begin
  Add(okExitIfChecked);
end;

procedure TGreedScreenScript.Movie(const AName: string);
begin
  FOps[Add(okMovie)].Name := AName;
end;

procedure TGreedScreenScript.JumpIfEscape(ALabel: Integer);
begin
  FOps[Add(okJumpIfEscape)].A := ALabel;
end;

procedure TGreedScreenScript.RawPrint(AX, AY: Integer; const AText: string);
var
  LOp: Integer;
begin
  LOp := Add(okRawPrint);
  FOps[LOp].A := AX;
  FOps[LOp].B := AY;
  FOps[LOp].Name := AText;
end;

procedure TGreedScreenScript.Call(const AProc: TProc);
begin
  FOps[Add(okCall)].Proc := AProc;
end;

procedure TGreedScreenScript.Mark(ALabel: Integer);
begin
  FOps[Add(okLabel)].A := ALabel;
end;

function TGreedScreenScript.ShownPalette: TBytes;
begin
  // I_GetPalette: what I_SetPalette has kept, where the color 0 is always black
  Result := Copy(FDisplay.Palette);
  Result[0] := 0;
  Result[1] := 0;
  Result[2] := 0;
end;

function TGreedScreenScript.Checked: Boolean;
begin
  Result := Assigned(FExitCheck) and FExitCheck();
end;

procedure TGreedScreenScript.JumpTo(ALabel: Integer);
var
  LIndex: Integer;
begin
  for LIndex := FIndex + 1 to High(FOps) do
    if (FOps[LIndex].Kind = okLabel) and (FOps[LIndex].A = ALabel) then
    begin
      FIndex := LIndex;
      Exit;
    end;
  raise EGreedException.CreateFmt(SGreedScriptLabel, [ALabel, FIndex]);
end;

procedure TGreedScreenScript.Start;
begin
  FIndex := 0;
  FState := ssIdle;
  FActive := True;
  Run;
end;

procedure TGreedScreenScript.Stop;
begin
  FState := ssIdle;
  FActive := False;
end;

procedure TGreedScreenScript.Next;
begin
  FState := ssIdle;
  Inc(FIndex);
  Run;
end;

procedure TGreedScreenScript.Run;
var
  LOp: TOp;
  LData: TBytes;
begin
  while FActive and (FIndex < Length(FOps)) do
  begin
    LOp := FOps[FIndex];
    case LOp.Kind of
      okFillPalette:
        FDisplay.FillPalette(LOp.A, LOp.B, LOp.C);
      okLoadScreen:
        if not FDisplay.LoadScreen(LOp.Name) then
          case TGreedScriptMissing(LOp.A) of
            gsmStop:
              begin
                Stop;
                Exit;
              end;
            gsmSkip:
              JumpTo(LOp.B);
          end;
      okFadeIn:
        begin
          FFader.StartFadeIn(ShownPalette, FDisplay.Colors, 0, 256, LOp.A);
          FCount := 0;
          FState := ssFade;
          Exit;
        end;
      okFadeOut:
        begin
          FFader.StartFadeOut(ShownPalette, 0, 256, LOp.A, LOp.B, LOp.C, LOp.D);
          FCount := 0;
          FState := ssFade;
          Exit;
        end;
      okWait:
        if LOp.A > 0 then
        begin
          FWaitUntil := FInput.TimeCount + LOp.A;
          FState := ssWait;
          Exit;
        end;
      okShowColors:
        FDisplay.ShowColors;
      okPaletteLump:
        FDisplay.SetPaletteFromLump(LOp.Name);
      okFillScreen:
        FDisplay.FillScreen(LOp.A);
      okFont:
        FPrinter.Font := FFont;
      okBaseColor:
        FPrinter.BaseColor := LOp.A;
      okTextFade:
        begin
          FColor := LOp.B;
          FPrinter.BaseColor := FColor;
          ContinueTextFade;
          Exit;
        end;
      okClearNewAscii:
        FInput.NewAscii := False;
      okWaitKey:
        begin
          FWaitUntil := FInput.TimeCount + LOp.A;
          FState := ssWaitKey;
          Exit;
        end;
      okWaitChecked:
        if LOp.A > 0 then
        begin
          FCount := 0;
          FWaitUntil := FInput.TimeCount + LOp.B;
          FState := ssWaitChecked;
          Exit;
        end;
      okExitIfChecked:
        if Checked then
        begin
          Stop;
          Exit;
        end;
      okMovie:
        begin
          LData := nil;
          if Assigned(FMovies) and FMovies.Exists(LOp.Name) then
            LData := FMovies.ReadAll(LOp.Name);
          FPlayer.Open(LData);
          if FPlayer.Active then
          begin
            FState := ssMovie;
            Exit;
          end;
        end;
      okJumpIfEscape:
        if FInput.LastAscii = #27 then
          JumpTo(LOp.A);
      okRawPrint:
        begin
          FPrinter.PrintX := LOp.A;
          FPrinter.PrintY := LOp.B;
          FPrinter.RawPrint3(LOp.Name);
        end;
      okCall:
        if Assigned(LOp.Proc) then
          LOp.Proc();
    end;
    Inc(FIndex);
  end;
  if FIndex >= Length(FOps) then
    Stop;
end;

procedure TGreedScreenScript.ContinueTextFade;
var
  LOp: TOp;
  LIndex: Integer;
begin
  LOp := FOps[FIndex];
  while FColor < LOp.C do
  begin
    FPrinter.PrintY := LOp.A;
    for LIndex := 0 to High(LOp.Texts) do
      FPrinter.PrintCentered(LOp.Texts[LIndex]);
    if LOp.D > 0 then
    begin
      FWaitUntil := FInput.TimeCount + LOp.D;
      FState := ssTextFade;
      Exit;
    end;
    Inc(FColor);
    FPrinter.BaseColor := FColor;
  end;
  Next;
end;

procedure TGreedScreenScript.Tick;
begin
  if not FActive then
    Exit;
  FInput.TimerTick;
  if Assigned(FOnTimer) then
    FOnTimer();
  Step;
end;

procedure TGreedScreenScript.Step;
var
  LOp: TOp;
begin
  if not FActive then
    Exit;
  LOp := FOps[FIndex];
  case FState of
    ssWait:
      if FInput.TimeCount >= FWaitUntil then
        Next;
    ssFade:
      begin
        // a step of the fade is computed, a tic passes, the palette is shown; after the last one the target
        FFader.Step;
        FDisplay.SetPalette(FFader.Current);
        Inc(FCount);
        if not FFader.Active or (FCount >= LOp.A) and (LOp.Kind = okFadeIn) or
          (FCount >= LOp.D) and (LOp.Kind = okFadeOut) then
        begin
          if FFader.Step then
            FDisplay.SetPalette(FFader.Current);
          Next;
        end;
      end;
    ssTextFade:
      if FInput.TimeCount >= FWaitUntil then
      begin
        Inc(FColor);
        FPrinter.BaseColor := FColor;
        ContinueTextFade;
      end;
    ssWaitKey:
      if FInput.TimeCount >= FWaitUntil then
      begin
        if FInput.NewAscii then
          Next
        else
          FWaitUntil := FInput.TimeCount + LOp.A;
      end;
    ssWaitChecked:
      if FInput.TimeCount >= FWaitUntil then
      begin
        if Checked then
        begin
          Stop;
          Exit;
        end;
        Inc(FCount);
        if FCount >= LOp.A then
          Next
        else
          FWaitUntil := FInput.TimeCount + LOp.B;
      end;
    ssMovie:
      begin
        FPlayer.Step;
        if not FPlayer.Active then
          Next;
      end;
  end;
end;

end.
