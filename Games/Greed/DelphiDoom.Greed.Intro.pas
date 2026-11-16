{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the intro: title screens, then the portraits of  }
{  the five hunters until a game starts                                         }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): dointro, MainIntro,         }
{  ShowPortrait, IntroCommand, DoIntroMenu and CheckDemoExit of intro.pas       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Intro;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Font, DelphiDoom.Greed.TextPrinter,
  DelphiDoom.Greed.Display, DelphiDoom.Greed.MenuInput, DelphiDoom.Greed.FliPlayer, DelphiDoom.Greed.ScreenScript,
  DelphiDoom.Greed.Menu;

const
  GREED_INTRO_CHARACTERS = 5;
  GREED_INTRO_PROFILE_LINES = 27;

type
  /// <summary>What dointro asks to the game</summary>
  IGreedIntroHost = interface
    ['{8E2F6A1D-07B4-4C93-A5E0-D1B36C4F9A28}']
    /// <summary>PlaySong('INTRO.S3M', 0), then quitgame := false and gameloaded := false</summary>
    procedure BeginIntro;
    /// <summary>UpdateSound: once for each line of a profile and each half second of its pause</summary>
    procedure UpdateSound;
    /// <summary>quitgame: the player chose to quit in the menu</summary>
    function QuitRequested: Boolean;
    /// <summary>gameloaded: the menu started or loaded a game</summary>
    function GameLoaded: Boolean;
  end;

  TGreedIntroPhase = (gipClosed, gipTitle, gipPortraitIn, gipLines, gipHold, gipPortraitOut, gipMenu);

  /// <summary>
  ///   dointro without its loops. Start does what the original does up to its first wait; each Tick is a tic of
  ///   the timer (the keys are read, IntroCommand runs as the timer hook) followed by what the original does until
  ///   it waits again. First the title sequence (TGreedTitleScreens; skipped when ARedo is true, as after the end
  ///   of an episode), then for ever the five portraits CHAR1..CHAR5, each with its profile written line by line.
  ///   Escape or Enter leave the title sequence and, in the portraits, open the main menu (DoIntroMenu: the menu
  ///   of the game, on a black screen with the palette of the game; when it closes without a game the portrait
  ///   comes back); Space ends the pause of a portrait and makes the lines appear without waiting. The intro ends
  ///   (Active is false) when the host says that the player quit or that a game is loaded.
  ///   The profiles are the table charinfo of the original.
  ///   Not ported: keyboardDelay (a variable of the game) and the path of the movies on the CD-ROM.
  ///   Difference from the original: after the menu the clock goes back to its value of before the menu (the
  ///   original takes it from the player record, which a new or loaded game may have changed)
  /// </summary>
  TGreedIntro = class
  strict private
    FDisplay: TGreedDisplay;
    FInput: TGreedMenuInput;
    FPrinter: TGreedTextPrinter;
    FFont: TGreedFont;
    FMovies: IGreedExternalFiles;
    FMenu: TGreedMenu;
    FHost: IGreedIntroHost;
    FAssassinator: Boolean;
    FScript: TGreedScreenScript;
    FPhase: TGreedIntroPhase;
    FHook: Boolean;
    FActivateMenu: Boolean;
    FNextChar: Boolean;
    FCharacter: Integer;
    FLine: Integer;
    FColor: Integer;
    FHold: Integer;
    FWaitUntil: Integer;
    FMenuFromHold: Boolean;
    FOldColors: TBytes;
    FOldScreen: TBytes;
    FOldTime: Integer;
    procedure IntroCommand;
    function CheckDemoExit: Boolean;
    procedure BeginPortraits;
    procedure BeginPortrait(ACharacter: Integer);
    procedure ContinueLines;
    procedure BeginHold;
    procedure AfterHold;
    procedure BeginFadeOut;
    procedure EnterMenu(AFromHold: Boolean);
    procedure LeaveMenu;
    procedure Finish;
  public
    /// <summary>
    ///   EArgumentNilException for a missing dependency (AMovies may be nil: no movie is found). The intro owns
    ///   only its script; AMenu is the menu of the game, closed
    /// </summary>
    constructor Create(ADisplay: TGreedDisplay; AInput: TGreedMenuInput; APrinter: TGreedTextPrinter;
      AFont1: TGreedFont; APlayer: TGreedFliPlayer; const AMovies: IGreedExternalFiles; AMenu: TGreedMenu;
      const AHost: IGreedIntroHost; AAssassinator: Boolean = False);
    destructor Destroy; override;
    /// <summary>dointro; ARedo is the variable redo (true after the end of an episode: no title sequence)</summary>
    procedure Start(ARedo: Boolean = False);
    /// <summary>One tic</summary>
    procedure Tick;
    /// <summary>False when dointro would have returned</summary>
    function Active: Boolean;
    property Phase: TGreedIntroPhase read FPhase;
    /// <summary>The portrait shown, 1..5</summary>
    property Character: Integer read FCharacter;
    /// <summary>activatemenu and nextchar</summary>
    property ActivateMenu: Boolean read FActivateMenu;
    property NextChar: Boolean read FNextChar;
    /// <summary>charinfo[character - 1][line]: a line that is only a full stop is an empty row</summary>
    class function ProfileLine(ACharacter, ALine: Integer): string; static;
  end;

implementation

uses
  DelphiDoom.Greed.TitleScreens;

const
  CHAR_INFO: array[0..GREED_INTRO_CHARACTERS - 1, 0..GREED_INTRO_PROFILE_LINES - 1] of string = (
    (
      'CYBORG',
      '.',
      'NAME: TOBIAS LOCKE',
      '.',
      'RACE: HOMO SAPIEN',
      '.',
      'AGE: 27',
      '.',
      'HEIGHT: 6''1''''',
      '.',
      'WEIGHT: 450 LBS',
      '(INCLUDING POWERED LIMBS)',
      '.',
      'BIO: CYBERNETICALLY ENHANCED HUMAN',
      '.',
      'BACKGROUND: BORN INTO THE LOTHLOS',
      'CASTE OF HUNTERS, TOBIAS WAS',
      'REBUILT AT THE AGE OF 22 FOLLOWING',
      'HIS INITIATION RITE INTO THE ELITE',
      'LOTH MAL ESCH, OR "SCAVENGER',
      'BROOD."',
      '     HE WAS SOON RECRUITED BY THE',
      'GREEN QUARTER HUNT SQUAD AND',
      'ASSIGNED TO THE SCAVENGER VESSEL,',
      'RED HUNTER, FOR COMPETITION IN THE',
      'GAME.',
      '.'
    ),
    (
      'LIZARD MAN',
      '.',
      'NAME: XITH',
      '.',
      'RACE: SAPIOSAURUS ROBUSTUS',
      '.',
      'AGE: 43',
      '.',
      'HEIGHT: 4''11''''',
      '.',
      'WEIGHT: 100 LBS',
      '.',
      'BIO: ZOLLEESIAN LIZARD MAN',
      '.',
      'BACKGROUND: XITH WAS BORN BETWEEN',
      'LIZARD CLANS AND FROM BIRTH HAS',
      'BEEN AN OUTCAST AMONG HIS TRIBES.',
      'HE ENTERED THE GAME HOPING TO USE',
      'THE LIGHTNING QUICK SPEED INHERENT',
      'IN HIS RACE TO VINDICATE HIMSELF.',
      '     XITH WAS TRADED TO GREEN',
      'QUARTER AND SUBSEQUENTLY PLACED',
      'ABOARD THE RED HUNTER.',
      '.',
      '.',
      '.',
      '.'
    ),
    (
      'MOOMAN',
      '.',
      'NAME: ALDUS KADEN',
      '.',
      'RACE: BRAHMAN ERECTUS',
      '.',
      'AGE: 35',
      '.',
      'HEIGHT: 7''0''''',
      '.',
      'WEIGHT: 375 LBS',
      '.',
      'BIO: BORN ON ELTHO III',
      '.',
      'BACKGROUND: THE BOVINARIAN OR',
      '"MOOMEN" AS RIMWARD WORLDS CALL',
      'THEM, HAVE BEEN FASCINATED BY THE',
      'GAME FROM THE BEGINNING.  HAVING',
      'PARTICIPATED IN THE INSURRECTION',
      'AT ALPHA PRAM AND THEN IN THE',
      'FAILED COUP AT SARTUS I, ALDUS',
      'KADEN WENT INTO THE ONLY',
      'PROFESSION LEFT TO HIM.',
      '     THE GREEN QUARTER TOOK HIM',
      'IMMEDIATELY AND AFTER ONLY THREE',
      'HUNTS HE WAS TRANSFERED TO THE',
      'RED HUNTER UNDER TOBIAS''S COMMAND.'
    ),
    (
      'MUTANT',
      '.',
      'NAME: SPECIMEN 7',
      '.',
      'RACE: HOMO DEGENEROUS',
      '.',
      'AGE: ?',
      '.',
      'HEIGHT: 5''10'''' (WHEN STANDING)',
      '.',
      'WEIGHT: 250 LBS',
      '.',
      'BIO: HUMAN VARIANT ENGINEERED BY',
      'JANEX CORP. GEN-TECH DIVISION.',
      '.',
      'BACKGROUND: AN ERROR IN OXYGEN',
      'FEEDS TO THE BIRTHING TANKS',
      'RESULTED IN ABNORMAL INTELLIGENCE',
      'LEVELS IN HIS STRAIN.  ESCAPING THE',
      'STERILIZATION THAT FOLLOWED',
      'SPECIMEN 7 IS THE ONLY REMAINING',
      'MEMBER OF HIS RACE.',
      '     HE JOINED GREEN QUARTER HUNT',
      'SQUAD WHEN THEY REALIZED HIS',
      'POTENTIAL AS A HUNTER.',
      '.',
      '.'
    ),
    (
      'DOMINATRIX',
      '.',
      'NAME: THEOLA NOM',
      '.',
      'RACE: HOMO MAJESTRIX',
      '.',
      'AGE: 22',
      '.',
      'HEIGHT: 5''11''''',
      '.',
      'WEIGHT: 140 LBS',
      '.',
      'BIO: HUMAN VARIANT ENGINEERED BY',
      'JANEX CORP. GEN-TECH DIVISION.',
      '.',
      'BACKGROUND: INITIALLY ENGINEERED',
      'BY JANEX FOR SALE AS A ''HOME',
      'ENTERTAINMENT SYSTEM'', THEOLA',
      'FIRST USED HER PREVIOUSLY LATENT',
      'PSYCHIC ABILITIES ON HER FIRST',
      'OWNER.  THEY NEVER FOUND THE BODY.',
      '     SINCE THEN, SHE HAS BEEN A',
      'FUGITIVE FROM CORE LAW.  RECENTLY',
      'SHE HAS SOUGHT REFUGE WITHIN THE',
      'RED HUNTER HUNT SQUAD.',
      '.',
      '.'
    )
  );

  HOLD_STEPS = 50;
  HOLD_TICS = 35;
  LINE_TICS = 2;
  SCREEN_BYTES = 64000;

{ TGreedIntro }

constructor TGreedIntro.Create(ADisplay: TGreedDisplay; AInput: TGreedMenuInput; APrinter: TGreedTextPrinter;
  AFont1: TGreedFont; APlayer: TGreedFliPlayer; const AMovies: IGreedExternalFiles; AMenu: TGreedMenu;
  const AHost: IGreedIntroHost; AAssassinator: Boolean);
begin
  inherited Create;
  if not Assigned(AMenu) then
    raise EArgumentNilException.Create('AMenu');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  // the script checks the others
  FScript := TGreedScreenScript.Create(ADisplay, AInput, APrinter, AFont1, APlayer, AMovies);
  FDisplay := ADisplay;
  FInput := AInput;
  FPrinter := APrinter;
  FFont := AFont1;
  FMovies := AMovies;
  FMenu := AMenu;
  FHost := AHost;
  FAssassinator := AAssassinator;
  FScript.ExitCheck := CheckDemoExit;
  FPhase := gipClosed;
end;

destructor TGreedIntro.Destroy;
begin
  FScript.Free;
  inherited;
end;

class function TGreedIntro.ProfileLine(ACharacter, ALine: Integer): string;
begin
  if (ACharacter < 1) or (ACharacter > GREED_INTRO_CHARACTERS) or (ALine < 0) or
    (ALine >= GREED_INTRO_PROFILE_LINES) then
    Result := ''
  else
    Result := CHAR_INFO[ACharacter - 1, ALine];
end;

function TGreedIntro.Active: Boolean;
begin
  Result := FPhase <> gipClosed;
end;

procedure TGreedIntro.IntroCommand;
begin
  if (FInput.Keyboard[GREED_SC_ESCAPE] = 1) or (FInput.Keyboard[GREED_SC_ENTER] = 1) then
  begin
    FInput.EatKey(GREED_SC_ESCAPE);
    FInput.EatKey(GREED_SC_ENTER);
    FActivateMenu := True;
  end;
  if FInput.Keyboard[GREED_SC_SPACE] = 1 then
  begin
    FInput.EatKey(GREED_SC_SPACE);
    FNextChar := True;
  end;
end;

function TGreedIntro.CheckDemoExit: Boolean;
begin
  Result := FActivateMenu;
  if Result then
  begin
    FActivateMenu := False;
    FNextChar := False;
  end;
end;

procedure TGreedIntro.Start(ARedo: Boolean);
begin
  FHook := True;
  FHost.BeginIntro;
  FDisplay.FillPalette(0, 0, 0);
  FCharacter := 0;
  if not ARedo then
  begin
    // MainIntro
    FScript.Clear;
    TGreedTitleScreens.Build(FScript, Assigned(FMovies) and FMovies.Exists(GREED_TITLE_FIRST_MOVIE),
      FAssassinator);
    FPhase := gipTitle;
    FScript.Start;
    if FScript.Active then
      Exit;
  end;
  BeginPortraits;
end;

procedure TGreedIntro.BeginPortraits;
begin
  FDisplay.FillPalette(0, 0, 0);
  FActivateMenu := False;
  BeginPortrait(1);
end;

procedure TGreedIntro.BeginPortrait(ACharacter: Integer);
begin
  FCharacter := ACharacter;
  FScript.Clear;
  FScript.LoadScreen('CHAR' + IntToStr(ACharacter));
  FScript.FadeIn(48);
  FPhase := gipPortraitIn;
  FScript.Start;
end;

procedure TGreedIntro.ContinueLines;
var
  LText: string;
begin
  while FLine < GREED_INTRO_PROFILE_LINES do
  begin
    if FColor < 0 then
    begin
      if not FNextChar then
        FHost.UpdateSound;
      FColor := 0;
    end;
    LText := CHAR_INFO[FCharacter - 1, FLine];
    while FColor < 9 do
    begin
      FPrinter.BaseColor := FColor;
      if LText[1] <> '.' then
      begin
        FPrinter.PrintX := 144;
        FPrinter.PrintY := 19 + 6 * FLine;
        FPrinter.RawPrint3(LText);
        if not FNextChar or FActivateMenu then
        begin
          FWaitUntil := FInput.TimeCount + LINE_TICS;
          FPhase := gipLines;
          Exit;
        end;
      end;
      Inc(FColor);
    end;
    FPrinter.BaseColor := 9;
    if FActivateMenu then
    begin
      EnterMenu(False);
      Exit;
    end;
    Inc(FLine);
    FColor := -1;
  end;
  FNextChar := False;
  FHold := 0;
  BeginHold;
end;

procedure TGreedIntro.BeginHold;
begin
  if FHold >= HOLD_STEPS then
  begin
    BeginFadeOut;
    Exit;
  end;
  FHost.UpdateSound;
  FWaitUntil := FInput.TimeCount + HOLD_TICS;
  FPhase := gipHold;
end;

procedure TGreedIntro.AfterHold;
begin
  if FNextChar then
  begin
    FNextChar := False;
    BeginFadeOut;
    Exit;
  end;
  Inc(FHold);
  BeginHold;
end;

procedure TGreedIntro.BeginFadeOut;
begin
  FScript.Clear;
  FScript.FadeOut(0, 0, 0, 48);
  FPhase := gipPortraitOut;
  FScript.Start;
end;

procedure TGreedIntro.EnterMenu(AFromHold: Boolean);
begin
  // DoIntroMenu
  FMenuFromHold := AFromHold;
  FOldColors := FDisplay.Colors;
  FOldScreen := Copy(FDisplay.Canvas.Pixels, 0, SCREEN_BYTES);
  FDisplay.FillScreen(0);
  FDisplay.SetPaletteFromLump('palette');
  FOldTime := FInput.TimeCount;
  FHook := False;
  FPhase := gipMenu;
  FMenu.OpenMenu(GREED_MENU_MAIN);
end;

procedure TGreedIntro.LeaveMenu;
var
  LGameOrQuit: Boolean;
begin
  LGameOrQuit := FHost.QuitRequested or FHost.GameLoaded;
  if not LGameOrQuit then
  begin
    FDisplay.FillScreen(0);
    FDisplay.Colors := FOldColors;
    FDisplay.ShowColors;
    Move(FOldScreen[0], FDisplay.Canvas.Pixels[0], SCREEN_BYTES);
  end;
  FOldScreen := nil;
  FInput.TimeCount := FOldTime;
  FActivateMenu := False;
  FHook := True;
  if LGameOrQuit then
  begin
    Finish;
    Exit;
  end;
  if FMenuFromHold then
    AfterHold
  else
  begin
    Inc(FLine);
    FColor := -1;
    ContinueLines;
  end;
end;

procedure TGreedIntro.Finish;
begin
  FScript.Stop;
  FHook := False;
  FPhase := gipClosed;
end;

procedure TGreedIntro.Tick;
begin
  if FPhase = gipClosed then
    Exit;
  FInput.TimerTick;
  if FHook then
    IntroCommand;
  case FPhase of
    gipTitle:
      begin
        FScript.Step;
        if not FScript.Active then
          BeginPortraits;
      end;
    gipPortraitIn:
      begin
        FScript.Step;
        if not FScript.Active then
        begin
          FPrinter.Font := FFont;
          FNextChar := False;
          FLine := 0;
          FColor := -1;
          ContinueLines;
        end;
      end;
    gipLines:
      if FInput.TimeCount >= FWaitUntil then
      begin
        Inc(FColor);
        ContinueLines;
      end;
    gipHold:
      if FInput.TimeCount >= FWaitUntil then
      begin
        if FActivateMenu then
          EnterMenu(True)
        else
          AfterHold;
      end;
    gipPortraitOut:
      begin
        FScript.Step;
        if not FScript.Active then
          BeginPortrait(FCharacter mod GREED_INTRO_CHARACTERS + 1);
      end;
    gipMenu:
      begin
        FMenu.Step;
        if not FMenu.Active then
          LeaveMenu;
      end;
  end;
end;

end.
