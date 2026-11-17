{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the screens that share the display and the keys  }
{  Port of xGreed (Jim Valavanis): menu.pas, intro.pas,                         }
{  playfli.pas and the screens of utils.pas                                     }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Screens;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.Settings.Intf,
  DelphiDoom.Greed.Sound.Intf, DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Display, DelphiDoom.Greed.MenuInput,
  DelphiDoom.Greed.Font, DelphiDoom.Greed.TextPrinter, DelphiDoom.Greed.FliPlayer, DelphiDoom.Greed.Menu,
  DelphiDoom.Greed.Menu.Intf, DelphiDoom.Greed.Intro, DelphiDoom.Greed.Briefing, DelphiDoom.Greed.EndGame,
  DelphiDoom.Greed.Mouse.Intf, DelphiDoom.Greed.MouseCursor;

type
  /// <summary>
  ///   The screens of the program and what they have in common: the canvas of 320 x 200 pixels (the screen of the
  ///   original), the display with its palette, the keys and the clock of the menus, the printer with the font
  ///   FONT1, the player of the movies, the menu, the introduction, the briefing and the endings. They are made
  ///   together because each of them draws on the same canvas and reads the same input; the hosts, who answer what
  ///   they ask of the game, come from outside. The object owns all of them. With a mouse the input reads it
  ///   with the keys and the picture of the pointer (the lump MCURSOR, if the archive has it) is made
  /// </summary>
  TGreedScreens = class
  strict private
    FCanvas: TGreedCanvas;
    FDisplay: TGreedDisplay;
    FInput: TGreedMenuInput;
    FFont: TGreedFont;
    FPrinter: TGreedTextPrinter;
    FPlayer: TGreedFliPlayer;
    FMenu: TGreedMenu;
    FIntro: TGreedIntro;
    FBriefing: TGreedBriefing;
    FEndGame: TGreedEndGame;
    FMouse: IGreedMouse;
    FMouseCursor: TGreedMouseCursor;
  public
    /// <summary>
    ///   EArgumentNilException for a missing dependency (AMovies may be nil: no movie is found; AMouse may be nil:
    ///   no mouse is installed). ADemo is DEMO of
    ///   the original (the help has three pages, the briefing is the one of the demo) and AVariant the game of the
    ///   family that the texts of the briefings and of the endings depend on
    /// </summary>
    constructor Create(const AArchive: IGreedArchive; const ASettings: IGreedSettings;
      const AVolumes: IGreedSoundVolumes; const ASaveGames: IGreedSaveGames; const AMovies: IGreedExternalFiles;
      const AMenuHost: IGreedMenuHost; const AIntroHost: IGreedIntroHost; const ABriefingHost: IGreedBriefingHost;
      const AEndGameHost: IGreedEndGameHost; ADemo: Boolean; AVariant: TGreedGameVariant;
      const AMouse: IGreedMouse = nil);
    destructor Destroy; override;
    property Canvas: TGreedCanvas read FCanvas;
    property Display: TGreedDisplay read FDisplay;
    property Input: TGreedMenuInput read FInput;
    property Printer: TGreedTextPrinter read FPrinter;
    property Font: TGreedFont read FFont;
    property Player: TGreedFliPlayer read FPlayer;
    property Menu: TGreedMenu read FMenu;
    property Intro: TGreedIntro read FIntro;
    property Briefing: TGreedBriefing read FBriefing;
    property EndGame: TGreedEndGame read FEndGame;
    /// <summary>The mouse of the menus; nil if none is installed</summary>
    property Mouse: IGreedMouse read FMouse;
    /// <summary>The picture of the pointer; nil without a mouse or without the lump MCURSOR</summary>
    property MouseCursor: TGreedMouseCursor read FMouseCursor;
  end;

implementation

const
  LUMP_FONT1 = 'FONT1';

{ TGreedScreens }

constructor TGreedScreens.Create(const AArchive: IGreedArchive; const ASettings: IGreedSettings;
  const AVolumes: IGreedSoundVolumes; const ASaveGames: IGreedSaveGames; const AMovies: IGreedExternalFiles;
  const AMenuHost: IGreedMenuHost; const AIntroHost: IGreedIntroHost; const ABriefingHost: IGreedBriefingHost;
  const AEndGameHost: IGreedEndGameHost; ADemo: Boolean; AVariant: TGreedGameVariant; const AMouse: IGreedMouse);
var
  LCursorLump: Integer;
begin
  inherited Create;
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  if not Assigned(ASettings) then
    raise EArgumentNilException.Create('ASettings');
  if not Assigned(AVolumes) then
    raise EArgumentNilException.Create('AVolumes');
  if not Assigned(ASaveGames) then
    raise EArgumentNilException.Create('ASaveGames');
  if not Assigned(AMenuHost) then
    raise EArgumentNilException.Create('AMenuHost');
  if not Assigned(AIntroHost) then
    raise EArgumentNilException.Create('AIntroHost');
  if not Assigned(ABriefingHost) then
    raise EArgumentNilException.Create('ABriefingHost');
  if not Assigned(AEndGameHost) then
    raise EArgumentNilException.Create('AEndGameHost');
  FCanvas := TGreedCanvas.Create;
  FDisplay := TGreedDisplay.Create(FCanvas, AArchive);
  FMouse := AMouse;
  FInput := TGreedMenuInput.Create(AMouse);
  FFont := TGreedFont.Create(AArchive.ReadLump(AArchive.RequireIndexOf(LUMP_FONT1)));
  FPrinter := TGreedTextPrinter.Create(FCanvas);
  FPrinter.Font := FFont;
  FPlayer := TGreedFliPlayer.Create(FDisplay, FInput);
  FMenu := TGreedMenu.Create(FDisplay, FInput, FPrinter, FFont, ASettings, AVolumes, ASaveGames, AMenuHost, ADemo);
  FIntro := TGreedIntro.Create(FDisplay, FInput, FPrinter, FFont, FPlayer, AMovies, FMenu, AIntroHost);
  FBriefing := TGreedBriefing.Create(FDisplay, FInput, FPrinter, FFont, FPlayer, AMovies, ABriefingHost, ADemo,
    AVariant);
  FEndGame := TGreedEndGame.Create(FDisplay, FInput, FPrinter, FFont, FPlayer, AMovies, AEndGameHost, AVariant);
  if Assigned(AMouse) then
  begin
    // M_InitMouse stops the original if the lump is missing: here the pointer is not drawn
    LCursorLump := AArchive.IndexOf(GREED_LUMP_MOUSE_CURSOR);
    if LCursorLump >= 0 then
      FMouseCursor := TGreedMouseCursor.Create(AArchive.ReadLumpRaw(LCursorLump));
  end;
end;

destructor TGreedScreens.Destroy;
begin
  FMouseCursor.Free;
  FEndGame.Free;
  FBriefing.Free;
  FIntro.Free;
  FMenu.Free;
  FPlayer.Free;
  FPrinter.Free;
  FFont.Free;
  FInput.Free;
  FDisplay.Free;
  FCanvas.Free;
  inherited Destroy;
end;

end.
