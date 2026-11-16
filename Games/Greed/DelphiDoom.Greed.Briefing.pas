{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the briefing before a mission                    }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): MissionBriefing of          }
{  utils.pas                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Briefing;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.Font,
  DelphiDoom.Greed.TextPrinter, DelphiDoom.Greed.Display, DelphiDoom.Greed.MenuInput, DelphiDoom.Greed.FliPlayer,
  DelphiDoom.Greed.ScreenScript;

type
  /// <summary>The numbers of the "mission successful" screen: the player and the goals of the level just left</summary>
  TGreedBriefingStats = record
    /// <summary>player.primaries[0] + player.primaries[1] and pcount[0] + pcount[1]</summary>
    PrimariesTaken: Integer;
    PrimariesTotal: Integer;
    /// <summary>The sums of player.secondaries[0..6] and of scount[0..6]</summary>
    SecondariesTaken: Integer;
    SecondariesTotal: Integer;
    /// <summary>player.score and player.bodycount</summary>
    Score: Integer;
    BodyCount: Integer;
  end;

  /// <summary>What MissionBriefing asks to the game</summary>
  IGreedBriefingHost = interface
    ['{C5A1E7D2-9F36-48B0-B4D7-2E60A9C3F815}']
    /// <summary>
    ///   The start of the second and of the third episode (maps 8 and 16): player.levelscore := levelscore, only
    ///   the first two weapons, the inventory of a new hunter, full ammunition, angst and shield
    /// </summary>
    procedure StartEpisode(AMap: Integer);
    /// <summary>selectsong(n): 99 before the movies of an episode, then the map</summary>
    procedure SelectSong(ASong: Integer);
  end;

  /// <summary>
  ///   MissionBriefing without its loops: Start does what the original does up to its first wait, each Tick is a
  ///   tic of the timer, Active is false when the original would have returned. Before the map 0: the screens
  ///   BRIEF3 (not in the demo), BRIEF1 and BRIEF2 with their texts, a key for each, Escape leaves. Before the maps
  ///   8 and 16 of a game that goes on: the movies of the episode and BRIEF4, BRIEF5 or BRIEF6, BRIEF7. Before
  ///   every other map of the episode: the screen TRANS, TRANS2 or TRANS3 with the results of the level just left
  ///   and the three texts of the mission (TGreedGameTables.MissionInfo). At the end the screen is black (the
  ///   original copies the saved screen back and then clears it), the palette is the one of the game and the clock
  ///   has the value it had at the start.
  ///   The caller does not start it in a net game or with -nobriefing
  /// </summary>
  TGreedBriefing = class
  strict private
    FScript: TGreedScreenScript;
    FInput: TGreedMenuInput;
    FHost: IGreedBriefingHost;
    FDemo: Boolean;
    FVariant: TGreedGameVariant;
    FOldTime: Integer;
    procedure Page(const AScreen: string; AFadeIn: Boolean; AY: Integer; const AText: string; AFadeOut: Boolean);
    procedure BuildFirstMap;
    procedure BuildEpisode(AMap: Integer);
    procedure BuildResults(AMap: Integer; const AStats: TGreedBriefingStats);
  public
    /// <summary>EArgumentNilException for a missing dependency (AMovies may be nil). ADemo is DEMO</summary>
    constructor Create(ADisplay: TGreedDisplay; AInput: TGreedMenuInput; APrinter: TGreedTextPrinter;
      AFont1: TGreedFont; APlayer: TGreedFliPlayer; const AMovies: IGreedExternalFiles;
      const AHost: IGreedBriefingHost; ADemo: Boolean; AVariant: TGreedGameVariant);
    destructor Destroy; override;
    /// <summary>MissionBriefing(map)</summary>
    procedure Start(AMap: Integer; const AStats: TGreedBriefingStats);
    procedure Tick;
    function Active: Boolean;
  end;

implementation

uses
  DelphiDoom.Greed.Game.Tables;

const
  TIC_RATE = 70;
  LABEL_FINALE = 1;

  SWelcome =
    'WELCOME ABOARD HUNTER.'#13#10 +
    'DUE TO INCREASED FUNDING FROM THE AVC YOU''LL BE EQUIPPED WITH THE'#13#10 +
    'LATEST IN HUNTER HARDWARE.  ALONG WITH YOUR EXISTING AUTO MAPPER,'#13#10 +
    'HEAT AND MOTION SENSORS HAVE BEEN ADDED TO YOUR VISUAL ARRAY AS'#13#10 +
    'WELL AS AN AFT SENSORY SYSTEM, OR A.S.S. CAM, FOR CONTINUOUS'#13#10 +
    'REAR VIEW.';
  SMenuing =
    'A MENUING SYSTEM HAS ALSO BEEN INSTALLED ALLOWING YOU TO'#13#10 +
    'FINE TUNE YOUR HARDWARE SETTINGS.  STAY ALERT THOUGH, YOUR MENU'#13#10 +
    'OVERLAY CANCELS INPUT FROM YOUR VISUAL ARRAY SO DON''T EXPECT TO'#13#10 +
    'SEE THINGS COMING WHILE YOU''RE ADJUSTING YOUR SETTINGS.';
  SColony =
    'BUILT FROM A HOLLOWED ASTEROID, THE DESARIAN PENAL COLONY'#13#10 +
    'HOUSES THE DREGS OF IMPERIAL SOCIETY.  A RIOT IS IN PROGRESS'#13#10 +
    'WHICH SHOULD MAKE ITEM RETRIEVAL INTERESTING.'#13#10 +
    'THE PRIMARY ITEM TO BE LOCATED HERE IS THE BYZANTIUM BRASS RING,'#13#10 +
    'AN ANCIENT ARTIFACT NOW USED AS THE POWER CORE FOR THE COMPLEX.'#13#10 +
    'SUCH AN ENIGMATIC ENERGY SOURCE IS OF OBVIOUS INTEREST TO A.V.C.'#13#10 +
    'RESEARCH, SO ACQUIRING IT UNDAMAGED IS ESSENTIAL.'#13#10 +
    'YOUR ENTRY POINT WILL BE AT THE BASE OF THE COMPLEX.'#13#10;
  SObjectives =
    'EACH SUBLEVEL WILL HAVE A MANDATORY PRIMARY OBJECTIVE, AS WELL'#13#10 +
    'AS OPTIONAL SECONDARY OBJECTIVES, ALL OF WHICH HELP YOU TO'#13#10 +
    'ACHIEVE A STATED POINT TOTAL NEEDED TO ADVANCE TO THE NEXT LEVEL.'#13#10 +
    'POINTS ARE ALSO AWARDED FOR KILLS AS WELL AS ACQUIRING RANDOMLY'#13#10 +
    'PLACED OBJECTS TAKEN FROM THE SHIP''S INVENTORY. EXPECT'#13#10 +
    'NON-COOPERATIVES (NOPS) FROM OTHER PARTS OF THE COLONY TO BE'#13#10 +
    'BROUGHT IN AT REGULAR INTERVALS TO REPLACE CASUALTIES OF THE HUNT.'#13#10;
  SProcessing =
    'THIS MISSION WILL BEGIN IN THE INMATE PROCESSING AREA, WHERE'#13#10 +
    'YOU ARE TO SEARCH FOR AN EXPERIMENTAL EXPLOSIVE HIDDEN'#13#10 +
    'IN THE SUBLEVEL.'#13#10 +
    'SECONDARY GOALS ARE PHOSPHER PELLETS AND DELOUSING KITS.'#13#10;
  // the "\n \n" is written so in the original (a C escape left in a Pascal string) and is printed as it is
  SMonitored =
    'YOU WILL BE MONITORED.  POINTS WILL BE AWARDED FOR PRIMARY,'#13#10 +
    'SECONDARY, AND RANDOM ITEMS, AS WELL AS FOR KILLING NOPS.'#13#10 +
    'WHEN YOU''VE ACQUIRED THE PRIMARY ITEM AND YOUR POINT TOTAL'#13#10 +
    'MEETS OR EXCEEDS 50000 WE''LL OPEN A TRANSLATION NEXUS.  WATCH'#13#10 +
    'FOR THE FLASHING EXIT SIGN.  ENTER THE NEXUS AND WE''LL'#13#10 +
    'TRANSLATE YOU TO THE NEXT AREA OF THE BASE.\n \nGOOD LUCK.';
  STemple =
    'THIS IS THE CITY-TEMPLE OF RISTANAK, ANCIENT HOME TO THE'#13#10 +
    'PRIESTHOOD OF YRKTAREL.  THE PRIESTHOOD HAS WORSHIPPED THEIR'#13#10 +
    'PAGAN DEITY FOR CENTURIES IN PEACE... UNTIL NOW.'#13#10;
  SMatrix =
    'THE PRIMARY OBJECTIVE FOR THE TEMPLE IS THE ENCODED'#13#10 +
    'PERSONALITY MATRIX OF THE DEMON-SAINT B''RNOURD.  THIS IS,'#13#10 +
    'OF COURSE, AN ITEM WHOSE POSSESSION, IF KNOWN, WOULD BRING'#13#10 +
    'INSTANT DESTRUCTION.  THE IMPERIAL COUNCIL WOULD ORDER THE'#13#10 +
    'SECTOR STERILIZED IF IT KNEW OF ITS EXISTENCE.'#13#10 +
    'THE A.V.C. BELIEVES THE ENCODE TO CONTAIN FORGOTTEN'#13#10 +
    'TECHNOLOGIES WHICH WOULD BE PRICELESS ON THE BLACK MARKET.'#13#10 +
    'IT IS YOUR MISSION TO ACQUIRE IT.'#13#10;
  SJumpBase =
    'DURING THE INSURRECTION AT ALPHA PRAM,  THE FOURTH PLANET IN'#13#10 +
    'THE SYSTEM, WHICH WAS BASE TO THE ELITE GALACTIC CORPS, WAS'#13#10 +
    'DESTROYED BY A BOVINARIAN VIOLATOR SHIP.  THE SHIELDING'#13#10 +
    'SURROUNDING THE MOUNTAIN WHERE THE CORPS WAS BASED WAS SO'#13#10 +
    'STRONG, HOWEVER, THAT THE MOUNTAIN SURVIVED.  THE BASE WAS'#13#10 +
    'THEN MOUNTED TO A TROJAN GATE JUMP POINT AND TO THIS DAY IT'#13#10 +
    'REMAINS AS A WAY POINT BETWEEN THE RIM WORLDS AND THE CORE'#13#10 +
    'QUARTER, AS WELL AS HOUSING MILITARY MIGHT IN THIS SECTOR.'#13#10;
  SSigil =
    'THE PRIMARY OBJECTIVE FOR THIS WORLD IS THE IMPERIAL SIGIL.'#13#10 +
    'IT IS THE SYMBOL OF POWER WHICH MAINTAINS THE CHANCELLOR'#13#10 +
    'IN HIS POSITION OF DOMINANCE WITHIN THE SECTOR.  YOU HAVE BUT'#13#10 +
    'TO TAKE THE SIGIL FROM THE CHANCELLOR HIMSELF.  UNFORTUNATELY'#13#10 +
    'FOR YOU, THE DESPOTIC CHANCELLOR HAD HIS FLESH REPLACED'#13#10 +
    'BY A CYBERNETIC SYMBIOTE IN ORDER TO INSURE HIS IMMORTALITY'#13#10 +
    'AND SUBSEQUENT ETERNAL RULE OF THE CORPS.  OVER 30 ATTEMPTS'#13#10 +
    'HAVE BEEN MADE TO WREST THE SIGIL FROM THE CHANCELLOR''S GRASP.'#13#10 +
    'THEY ALL FAILED.'#13#10;

{ TGreedBriefing }

constructor TGreedBriefing.Create(ADisplay: TGreedDisplay; AInput: TGreedMenuInput; APrinter: TGreedTextPrinter;
  AFont1: TGreedFont; APlayer: TGreedFliPlayer; const AMovies: IGreedExternalFiles;
  const AHost: IGreedBriefingHost; ADemo: Boolean; AVariant: TGreedGameVariant);
begin
  inherited Create;
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  // the script checks the others
  FScript := TGreedScreenScript.Create(ADisplay, AInput, APrinter, AFont1, APlayer, AMovies);
  FInput := AInput;
  FHost := AHost;
  FDemo := ADemo;
  FVariant := AVariant;
end;

destructor TGreedBriefing.Destroy;
begin
  FScript.Free;
  inherited;
end;

function TGreedBriefing.Active: Boolean;
begin
  Result := FScript.Active;
end;

procedure TGreedBriefing.Tick;
begin
  FScript.Tick;
end;

procedure TGreedBriefing.Page(const AScreen: string; AFadeIn: Boolean; AY: Integer; const AText: string;
  AFadeOut: Boolean);
begin
  FScript.LoadScreen(AScreen);
  if AFadeIn then
  begin
    FScript.FadeIn(64);
    FScript.Wait(TIC_RATE);
  end;
  FScript.ClearNewAscii;
  FScript.TextFade(AY, [AText], 0, 9, 3);
  FScript.WaitKey;
  FScript.JumpIfEscape(LABEL_FINALE);
  if AFadeOut then
    FScript.FadeOut(0, 0, 0, 64);
end;

procedure TGreedBriefing.BuildFirstMap;
begin
  FScript.FillPalette(0, 0, 0);
  if not FDemo then
  begin
    Page('BRIEF3', True, 149, SWelcome, True);
    Page('BRIEF3', False, 149, SMenuing, True);
  end;
  Page('BRIEF1', True, 139, SColony, True);
  Page('BRIEF2', True, 139, SObjectives, False);
  Page('BRIEF2', False, 139, SProcessing, False);
  Page('BRIEF2', False, 139, SMonitored, False);
end;

procedure TGreedBriefing.BuildEpisode(AMap: Integer);
var
  LHost: IGreedBriefingHost;
begin
  LHost := FHost;
  FScript.Call(
    procedure
    begin
      LHost.StartEpisode(AMap);
      LHost.SelectSong(99);
    end);
  if AMap = 8 then
  begin
    if FVariant <> ggvGame2 then
      FScript.Movie('PRISON1.FLI');
    FScript.Movie('TEMPLE1.FLI');
  end
  else
  begin
    if FVariant <> ggvGame3 then
      FScript.Movie('TEMPLE2.FLI');
    FScript.Movie('JUMPBAS1.FLI');
    FScript.Movie('JUMPBAS2.FLI');
  end;
  FScript.Call(
    procedure
    begin
      LHost.SelectSong(AMap);
    end);
  FScript.FillPalette(0, 0, 0);
  if AMap = 8 then
  begin
    Page('BRIEF4', True, 139, STemple, True);
    Page('BRIEF5', True, 139, SMatrix, True);
  end
  else
  begin
    Page('BRIEF6', True, 139, SJumpBase, True);
    Page('BRIEF7', True, 139, SSigil, True);
  end;
end;

procedure TGreedBriefing.BuildResults(AMap: Integer; const AStats: TGreedBriefingStats);
begin
  FScript.FillPalette(0, 0, 0);
  if AMap < 8 then
    FScript.LoadScreen('TRANS')
  else if AMap < 16 then
    FScript.LoadScreen('TRANS2')
  else
    FScript.LoadScreen('TRANS3');
  FScript.FadeIn(64);
  FScript.ClearNewAscii;
  FScript.BaseColor(8);
  FScript.RawPrint(20, 30, 'MISSION SUCCESSFUL!');
  FScript.RawPrint(25, 40, Format('PRIMARY GOALS STOLEN: %d of %d', [AStats.PrimariesTaken,
    AStats.PrimariesTotal]));
  FScript.RawPrint(25, 50, Format('SECONDARY GOALS STOLEN: %d of %d', [AStats.SecondariesTaken,
    AStats.SecondariesTotal]));
  FScript.RawPrint(25, 65, Format('POINT TOTAL: %d', [AStats.Score]));
  FScript.RawPrint(25, 75, Format('TOTAL KILLS: %d', [AStats.BodyCount]));
  FScript.TextFade(85, [TGreedGameTables.MissionInfo(AMap, 0, FDemo), TGreedGameTables.MissionInfo(AMap, 1, FDemo),
    TGreedGameTables.MissionInfo(AMap, 2, FDemo)], 0, 9, 3);
  FScript.WaitKey;
  FScript.FadeOut(0, 0, 0, 64);
end;

procedure TGreedBriefing.Start(AMap: Integer; const AStats: TGreedBriefingStats);
var
  LInput: TGreedMenuInput;
  LOldTime: Integer;
begin
  FOldTime := FInput.TimeCount;
  FScript.Clear;
  FScript.UseFont;
  if AMap = 0 then
    BuildFirstMap
  else if ((FVariant in [ggvDefault, ggvGame1]) and (AMap < 8)) or ((FVariant = ggvGame2) and (AMap < 16)) or
    ((FVariant = ggvGame3) and (AMap < 22)) then
  begin
    if (AMap = 8) or (AMap = 16) then
      BuildEpisode(AMap);
    BuildResults(AMap, AStats);
  end;
  FScript.Mark(LABEL_FINALE);
  FScript.FillScreen(0);
  FScript.ShowPaletteLump('palette');
  LInput := FInput;
  LOldTime := FOldTime;
  FScript.Call(
    procedure
    begin
      LInput.TimeCount := LOldTime;
    end);
  FScript.Start;
end;

end.
