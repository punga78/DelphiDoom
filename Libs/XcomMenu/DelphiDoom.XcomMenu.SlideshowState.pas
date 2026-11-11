{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - SlideshowState of OpenXcom (a cutscene made  }
{  of pictures with captions)                                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.SlideshowState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomMod.RuleVideo, DelphiDoom.XcomMenu.CutsceneCatalog.Intf;

type
  /// <summary>
  ///   Shows the slides one after the other, each with its own palette and its caption: a click or the OK key
  ///   goes to the next one, the timer does the same after the seconds of the slide (or of the header), the
  ///   Cancel key ends the show. The pictures (.LBM) are loaded from the catalog when the state is created
  /// </summary>
  TXcomSlideshowState = class(TXcomState)
  strict private
    FHeader: TXcomSlideshowHeader;
    FRules: TArray<TXcomSlideshowSlide>;
    FWasLetterboxed: Boolean;
    FSlides: TList<TXcomInteractiveSurface>;
    FCaptions: TList<TXcomText>;
    FCurrentScreen: Integer;
    FTransitionTimer: TXcomTimer;
    function LoadSlide(const ACatalog: IXcomCutsceneCatalog; const APath: string): TXcomInteractiveSurface;
    function TransitionSeconds(AIndex: Integer): Integer;
    procedure ScreenClick(AAction: TXcomAction);
    procedure ScreenSkip(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; const ACatalog: IXcomCutsceneCatalog;
      const AHeader: TXcomSlideshowHeader; const ASlides: TArray<TXcomSlideshowSlide>);
    destructor Destroy; override;
    procedure Think; override;
    /// <summary>The slide on the screen (-1 before the first, the count after the last)</summary>
    property CurrentScreen: Integer read FCurrentScreen;
    function Caption(AIndex: Integer): TXcomText;
    function Slide(AIndex: Integer): TXcomInteractiveSurface;
  end;

implementation

uses
  DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Intf, DelphiDoom.Xcom.Factory,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Screen,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomMenu.CutsceneState;

constructor TXcomSlideshowState.Create(AHost: TXcomStateHost; const ACatalog: IXcomCutsceneCatalog;
  const AHeader: TXcomSlideshowHeader; const ASlides: TArray<TXcomSlideshowSlide>);
var
  LRule: TXcomSlideshowSlide;
  LSlide: TXcomInteractiveSurface;
  LCaption: TXcomText;
  LPalette: TXcomPalette;
begin
  inherited Create(AHost);
  FHeader := AHeader;
  FRules := ASlides;
  FCurrentScreen := -1;
  FSlides := TList<TXcomInteractiveSurface>.Create;
  FCaptions := TList<TXcomText>.Create;
  FWasLetterboxed := TXcomCutsceneState.InitDisplay(Host);
  // pre-render and queue up all the frames
  for LRule in FRules do
  begin
    LSlide := LoadSlide(ACatalog, LRule.ImagePath);
    LSlide.OnMouseClick(ScreenClick);
    LSlide.OnKeyboardPress(ScreenClick, Host.Options.KeyOk);
    LSlide.OnKeyboardPress(ScreenSkip, Host.Options.KeyCancel);
    LSlide.Visible := False;
    FSlides.Add(LSlide);
    LPalette := LSlide.Palette;
    SetPalette(PXcomColor(@LPalette.Colors[0]), 0, 256);
    Add(LSlide);
    // initialize with default rect; may get overridden by category/id definition
    LCaption := TXcomText.Create(LRule.W, LRule.H, LRule.X, LRule.Y);
    FCaptions.Add(LCaption);
    Add(LCaption);
    LCaption.SetColor(Byte(LRule.Color));
    LCaption.SetText(Tr(LRule.Caption));
    LCaption.SetAlign(TXcomTextHAlign(LRule.Align));
    LCaption.SetWordWrap(True);
    LCaption.Visible := False;
  end;
  CenterAllSurfaces;
  FTransitionTimer := TXcomTimer.Create(Host.Clock, Cardinal(TransitionSeconds(0)) * 1000);
  FTransitionTimer.OnTimerState(
    procedure
    begin
      ScreenClick(nil);
    end);
  Host.PlayMusic(FHeader.MusicId);
  Host.Cursor.Visible := False;
  ScreenClick(nil);
end;

destructor TXcomSlideshowState.Destroy;
begin
  FTransitionTimer.Free;
  FCaptions.Free;
  FSlides.Free;
  inherited Destroy;
end;

function TXcomSlideshowState.LoadSlide(const ACatalog: IXcomCutsceneCatalog;
  const APath: string): TXcomInteractiveSurface;
var
  LPicture: TXcomLbmPicture;
  LPixels: TBytes;
begin
  // Surface::loadImage: the surface becomes the picture of the file, with its palette
  LPicture := TXcomFactory.CreateLbmReader.Read(ACatalog.LoadBytes(APath));
  Result := TXcomInteractiveSurface.Create(LPicture.Image.Width, LPicture.Image.Height, 0, 0);
  LPixels := Result.Pixels;
  if Length(LPixels) > 0 then
    Move(LPicture.Image.Pixels[0], LPixels[0], Length(LPixels));
  Result.SetColors(LPicture.Image.Palette.Colors, 0);
end;

function TXcomSlideshowState.TransitionSeconds(AIndex: Integer): Integer;
begin
  Result := FHeader.TransitionSeconds;
  if (AIndex >= 0) and (AIndex < Length(FRules)) and (FRules[AIndex].TransitionSeconds > 0) then
    Result := FRules[AIndex].TransitionSeconds;
end;

function TXcomSlideshowState.Caption(AIndex: Integer): TXcomText;
begin
  Result := FCaptions[AIndex];
end;

function TXcomSlideshowState.Slide(AIndex: Integer): TXcomInteractiveSurface;
begin
  Result := FSlides[AIndex];
end;

procedure TXcomSlideshowState.Think;
begin
  inherited Think;
  FTransitionTimer.Think(True, False);
end;

procedure TXcomSlideshowState.ScreenClick(AAction: TXcomAction);
var
  LPalette: TXcomPalette;
begin
  if (FCurrentScreen >= 0) and (FCurrentScreen < FSlides.Count) then
  begin
    FSlides[FCurrentScreen].Visible := False;
    FCaptions[FCurrentScreen].Visible := False;
  end;
  Inc(FCurrentScreen);
  // next screen
  if FCurrentScreen < FSlides.Count then
  begin
    FTransitionTimer.SetInterval(Cardinal(TransitionSeconds(FCurrentScreen)) * 1000);
    FTransitionTimer.Start;
    LPalette := FSlides[FCurrentScreen].Palette;
    SetPalette(PXcomColor(@LPalette.Colors[0]), 0, 256);
    FSlides[FCurrentScreen].Visible := True;
    FCaptions[FCurrentScreen].Visible := True;
    Init;
  end
  else
    ScreenSkip(AAction);
end;

procedure TXcomSlideshowState.ScreenSkip(AAction: TXcomAction);
begin
  // slideshow is over: restore the screen scale and pop the state
  FTransitionTimer.Stop;
  Host.Cursor.Visible := True;
  TXcomCutsceneState.ResetDisplay(Host, FWasLetterboxed);
  Host.PopState;
end;

end.
