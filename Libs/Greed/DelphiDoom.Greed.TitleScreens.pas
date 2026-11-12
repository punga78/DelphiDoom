{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the title screens and the movies of the intro    }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): DemoIntro and DemoIntroFlis }
{  of intro.pas                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.TitleScreens;

interface

uses
  System.SysUtils, DelphiDoom.Greed.ScreenScript;

const
  /// <summary>The movie that DemoIntro looks for: if it is there the intro is the movies, otherwise the screens</summary>
  GREED_TITLE_FIRST_MOVIE = 'TEXT.FLI';

type
  /// <summary>
  ///   The steps of DemoIntro. With the movies (FindFLIFile finds TEXT.FLI): the 23 movies of the CD-ROM in their
  ///   order, each one stopped by any key, the whole intro left when the menu is asked (ExitCheck of the script).
  ///   Without: the pictures SOFTLOGO, C7LOGO, LOGO and INTRO00..INTRO08 of the archive with their fades and
  ///   texts; the first picture that is not in the archive ends the intro, as in the original
  /// </summary>
  TGreedTitleScreens = class
  public
    /// <summary>Adds the steps to the script (which the caller has cleared); AAssassinator: no LOGOFLY movie</summary>
    class procedure Build(AScript: TGreedScreenScript; AWithMovies, AAssassinator: Boolean); static;
    /// <summary>The movies of DemoIntroFlis in their order (LOGOFLY.FLI is the last)</summary>
    class function MovieNames: TArray<string>; static;
  end;

implementation

const
  TIC_RATE = 70;

  MOVIES: array[0..22] of string = ('TEXT.FLI', 'WARP01.FLI', 'WARP02.FLI', 'INSHIP01.FLI', 'ARBITER.FLI',
    'INSHIP02.FLI', 'CHAR1.FLI', 'CHAR2.FLI', 'CHAR3.FLI', 'CHAR4.FLI', 'CHAR5.FLI', 'INSHIP03.FLI', 'DROPPOD.FLI',
    'SHP1.FLI', 'CITYBURN.FLI', 'RUBBLE.FLI', 'THF1.FLI', 'THF2.FLI', 'THF3.FLI', 'THF4.FLI', 'INSHIP04.FLI',
    'WARP05.FLI', 'LOGOFLY.FLI');
  // the movie after which the original waits two seconds
  MOVIE_WITH_PAUSE = 5;

  SIntro00 =
    'IT IS THE YEAR 15392 DURING THE THIRD AGE OF MAN.'#13#10 +
    'SCAVENGER HUNTS MEAN BIG MONEY FOR THE CRIMINAL'#13#10 +
    'ELITE.  COVERTLY RECRUITED BY AN ENIGMATIC FACTION'#13#10 +
    'OF THE A.V.C. YOU ARE A MEMBER OF THE RED HUNTER'#13#10 +
    'ELITE ACQUISITION SQUAD.';
  SIntro01 =
    'USING YOUR NEEDLING SHIP, THE RED HUNTER, IT IS YOUR'#13#10 +
    'JOB TO WARP THROUGH TO UNSUSPECTING FRINGE WORLDS...';
  SIntro02 =
    '...PLUMMET FROM ORBIT IN YOUR DROP SHIP, SUPPRESSING'#13#10 +
    'NONCOOPERATIVE ENTITIES (NOPS) AS BEST YOU CAN IN'#13#10 +
    'ORDER TO ACQUIRE YOUR PRIMARY TARGET ITEMS.';
  SIntro03 =
    'THE SIZE AND SPEED OF THE DROP SHIP SHOULD BE SUFFICIENT'#13#10 +
    'TO DRIVE NONCOOPERATIVES FROM THE DROP ZONE UPON IMPACT.';
  SIntro06 = 'IN SHORT, IF IT''S MOVING AROUND, KILL IT...';
  SIntro07 = '...AND IF IT''S NOT NAILED DOWN, STEAL IT.';
  SIntro08 =
    'YOU''RE A SCAVENGER.  YOU''VE GOT A GUN.'#13#10 +
    'LET''S GET SOME.';

{ TGreedTitleScreens }

class function TGreedTitleScreens.MovieNames: TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(MOVIES));
  for LIndex := 0 to High(MOVIES) do
    Result[LIndex] := MOVIES[LIndex];
end;

class procedure TGreedTitleScreens.Build(AScript: TGreedScreenScript; AWithMovies, AAssassinator: Boolean);
var
  LIndex: Integer;

  procedure Logo(const AName: string; AFlash: Boolean);
  begin
    AScript.LoadScreen(AName, gsmStop);
    AScript.FadeIn(48);
    AScript.Wait(3 * TIC_RATE);
    if AFlash then
      AScript.FillPalette(255, 255, 255);
    AScript.FadeOut(0, 0, 0, 48);
    AScript.ExitIfChecked;
  end;

  procedure Slide(const AName, AText: string; AWaits: Integer);
  begin
    AScript.LoadScreen(AName, gsmStop);
    AScript.FadeIn(48);
    AScript.TextFade(160, [AText], 0, 9, 5);
    AScript.WaitChecked(AWaits, 10);
    AScript.ExitIfChecked;
    AScript.FadeOut(0, 0, 0, 48);
    AScript.ExitIfChecked;
  end;

begin
  if not Assigned(AScript) then
    raise EArgumentNilException.Create('AScript');
  AScript.BaseColor(0);
  AScript.UseFont;
  if AWithMovies then
  begin
    for LIndex := 0 to High(MOVIES) do
    begin
      if (LIndex = High(MOVIES)) and AAssassinator then
        Break;
      AScript.Movie(MOVIES[LIndex]);
      AScript.ExitIfChecked;
      if LIndex = MOVIE_WITH_PAUSE then
        AScript.Wait(2 * TIC_RATE);
    end;
    AScript.Wait(3 * TIC_RATE);
    Exit;
  end;

  AScript.FillPalette(0, 0, 0);
  Logo('SOFTLOGO', False);
  Logo('C7LOGO', False);
  Logo('LOGO', True);

  Slide('INTRO00', SIntro00, 70);
  Slide('INTRO01', SIntro01, 42);
  Slide('INTRO02', SIntro02, 42);

  AScript.LoadScreen('INTRO03', gsmStop);
  AScript.FadeIn(48);
  AScript.TextFade(160, [SIntro03], 0, 9, 5);
  AScript.WaitChecked(42, 10);
  AScript.ExitIfChecked;
  AScript.FillPalette(0, 0, 0);
  AScript.ExitIfChecked;

  AScript.LoadScreen('INTRO04', gsmStop);
  AScript.ShowColors;
  AScript.WaitChecked(21, 10);
  AScript.ExitIfChecked;
  AScript.FadeOut(255, 255, 255, 48);
  AScript.ExitIfChecked;

  AScript.LoadScreen('INTRO05', gsmStop);
  AScript.FadeIn(48);
  AScript.WaitChecked(21, 10);
  AScript.ExitIfChecked;
  AScript.FadeOut(0, 0, 0, 48);
  AScript.ExitIfChecked;

  Slide('INTRO06', SIntro06, 28);
  Slide('INTRO07', SIntro07, 28);
  Slide('INTRO08', SIntro08, 28);
end;

end.
