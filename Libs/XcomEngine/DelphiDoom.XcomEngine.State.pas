{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - State of OpenXcom (a screen of the game    }
{  with the surfaces it manages) and the host it asks things to                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.State;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.LocalizedText, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Screen,
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomEngine.Resources.Intf,
  DelphiDoom.XcomEngine.LanguageProvider.Intf, DelphiDoom.XcomEngine.OptionsStore.Intf;

type
  TXcomState = class;

  /// <summary>
  ///   What a state needs from the game that runs it (the static Game pointer of the C++ State): the screen, the
  ///   cursor, the language, the data, the options and the stack of states. The game derives from it; a state never
  ///   owns the host
  /// </summary>
  TXcomStateHost = class abstract
  public
    function Screen: TXcomScreen; virtual; abstract;
    function Cursor: TXcomInteractiveSurface; virtual; abstract;
    function FpsCounter: TXcomInteractiveSurface; virtual; abstract;
    function Language: TXcomLanguage; virtual; abstract;
    function Resources: IXcomResources; virtual; abstract;
    function Options: TXcomOptions; virtual; abstract;
    function Clock: IXcomClock; virtual; abstract;
    /// <summary>Game::pushState: the state is owned by the game from now on</summary>
    procedure PushState(AState: TXcomState); virtual; abstract;
    procedure PopState; virtual; abstract;
    /// <summary>Game::setState: all the states go away and this one takes their place</summary>
    procedure SetState(AState: TXcomState); virtual; abstract;
    procedure Quit; virtual; abstract;
    /// <summary>Game::loadMods and loadLanguages ended: the game takes the data and the language (and frees the old ones)</summary>
    procedure AdoptData(const AResources: IXcomResources; ALanguage: TXcomLanguage); virtual; abstract;
    /// <summary>Game::isState: the state is the one on top</summary>
    function IsState(AState: TXcomState): Boolean; virtual; abstract;
    /// <summary>The languages that can be chosen and loaded (nil when the host has none)</summary>
    function LanguageProvider: IXcomLanguageProvider; virtual;
    /// <summary>The full screen modes of the display (nil when the host cannot list them)</summary>
    function DisplayModes: IXcomDisplayModes; virtual;
    /// <summary>Where the options are kept (nil: Options::save and load do nothing)</summary>
    function OptionsStore: IXcomOptionsStore; virtual;
    /// <summary>Game::loadLanguages: loads the language of Options::language and replaces the current one</summary>
    procedure LoadLanguages; virtual;
    /// <summary>Game::setVolume: the volumes of the sounds, the music and the interface</summary>
    procedure SetVolume(ASound, AMusic, AUi: Integer); virtual;
  end;

  /// <summary>
  ///   A screen or a window of the game: it owns the surfaces it adds (in order of drawing), the palette they use,
  ///   and passes them the events and the think calls. The states of the game derive from this class
  /// </summary>
  TXcomState = class
  strict private
    FSurfaces: TObjectList<TXcomWidget>;
    FPalette: TXcomColors;
    FScreen: Boolean;
    FModal: TXcomInteractiveSurface;
    FRuleInterface: TXcomRuleInterface;
    FRuleInterfaceParent: TXcomRuleInterface;
    FCursorColor: Integer;
    FHost: TXcomStateHost;
  protected
    /// <summary>State::_ruleInterface: the interface set by SetInterface (nil if the ruleset has none)</summary>
    property RuleInterface: TXcomRuleInterface read FRuleInterface;
    property Surfaces: TObjectList<TXcomWidget> read FSurfaces;
  public
    constructor Create(AHost: TXcomStateHost);
    destructor Destroy; override;
    /// <summary>The game that runs the state (the static Game pointer of the C++)</summary>
    property Host: TXcomStateHost read FHost;
    /// <summary>State::setInterface: takes the interface of the ruleset and sets the palette of the state</summary>
    procedure SetInterface(const ACategory: string; AAlterPalette: Boolean = False);
    /// <summary>State::add(surface): the state owns the surface from now on</summary>
    procedure Add(ASurface: TXcomWidget); overload;
    /// <summary>
    ///   State::add(surface, id, category, parent): the element of the interface gives size, position (relative to
    ///   the parent), colors and mode
    /// </summary>
    procedure Add(ASurface: TXcomWidget; const AId, ACategory: string; AParent: TXcomSurface = nil); overload;
    function IsScreen: Boolean;
    procedure ToggleScreen;
    /// <summary>State::init: every time the state comes to the front</summary>
    procedure Init; virtual;
    procedure Think; virtual;
    procedure Handle(AAction: TXcomAction); virtual;
    procedure Blit; virtual;
    procedure HideAll;
    procedure ShowAll;
    procedure ResetAll;
    function Tr(const AId: string): TXcomLocalizedText; overload;
    function Tr(const AId: string; ANumber: Cardinal): TXcomLocalizedText; overload;
    procedure CenterAllSurfaces;
    procedure LowerAllSurfaces;
    procedure RedrawText;
    procedure SetModal(ASurface: TXcomInteractiveSurface);
    /// <summary>State::setPalette(colors...): replaces colors of the palette of the state</summary>
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer; ACount: Integer; AImmediately: Boolean = True); overload;
    /// <summary>State::setPalette(name, backpals): a palette of the game, with the BACKPALS block when not -1</summary>
    procedure SetPalette(const APalette: string; ABackPalette: Integer); overload;
    function Palette: PXcomColors;
    /// <summary>State::resize</summary>
    procedure Resize(var ADX, ADY: Integer); virtual;
    procedure Recenter(ADX, ADY: Integer);
  end;

implementation

const
  PALETTE_GEOSCAPE = 'PAL_GEOSCAPE';
  PALETTE_BACKPALS = 'BACKPALS.DAT';

{ TXcomStateHost }

function TXcomStateHost.LanguageProvider: IXcomLanguageProvider;
begin
  Result := nil;
end;

function TXcomStateHost.DisplayModes: IXcomDisplayModes;
begin
  Result := nil;
end;

function TXcomStateHost.OptionsStore: IXcomOptionsStore;
begin
  Result := nil;
end;

procedure TXcomStateHost.LoadLanguages;
begin
end;

procedure TXcomStateHost.SetVolume(ASound, AMusic, AUi: Integer);
begin
end;

{ TXcomState }

constructor TXcomState.Create(AHost: TXcomStateHost);
begin
  inherited Create;
  FHost := AHost;
  FSurfaces := TObjectList<TXcomWidget>.Create(True);
  FScreen := True;
  FillChar(FPalette, SizeOf(FPalette), 0);
  FCursorColor := Host.Cursor.GetColor;
end;

destructor TXcomState.Destroy;
begin
  FSurfaces.Free;
  inherited Destroy;
end;

procedure TXcomState.SetInterface(const ACategory: string; AAlterPalette: Boolean);
var
  LBackPalette: Integer;
  LPalette: string;
  LElement: TXcomInterfaceElement;
  LHasElement: Boolean;
  LColor: Integer;
begin
  LBackPalette := -1;
  LPalette := PALETTE_GEOSCAPE;
  FRuleInterface := Host.Resources.GetInterface(ACategory);
  if Assigned(FRuleInterface) then
  begin
    FRuleInterfaceParent := Host.Resources.GetInterface(FRuleInterface.Parent);
    LPalette := FRuleInterface.Palette;
    LHasElement := FRuleInterface.TryGetElement('palette', LElement);
    if Assigned(FRuleInterfaceParent) then
    begin
      if not LHasElement then
        LHasElement := FRuleInterfaceParent.TryGetElement('palette', LElement);
      if LPalette = '' then
        LPalette := FRuleInterfaceParent.Palette;
    end;
    if LHasElement then
    begin
      if AAlterPalette then
        LColor := LElement.Color2
      else
        LColor := LElement.Color;
      if LColor <> XCOM_UNSET then
        LBackPalette := LColor;
    end;
  end;
  if LPalette = '' then
    LPalette := PALETTE_GEOSCAPE;
  SetPalette(LPalette, LBackPalette);
end;

procedure TXcomState.Add(ASurface: TXcomWidget);
begin
  ASurface.SetPalette(@FPalette[0], 0, 256);
  if (Host.Language <> nil) and (Host.Resources <> nil) then
    ASurface.InitText(Host.Resources.GetFont('FONT_BIG'), Host.Resources.GetFont('FONT_SMALL'), Host.Language);
  FSurfaces.Add(ASurface);
end;

procedure TXcomState.Add(ASurface: TXcomWidget; const AId, ACategory: string; AParent: TXcomSurface);
var
  LInterface: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
begin
  ASurface.SetPalette(@FPalette[0], 0, 256);
  LInterface := Host.Resources.GetInterface(ACategory);
  if Assigned(LInterface) and LInterface.TryGetElement(AId, LElement) then
  begin
    if Assigned(AParent) and (LElement.W <> XCOM_UNSET) and (LElement.H <> XCOM_UNSET) then
    begin
      ASurface.SetWidth(LElement.W);
      ASurface.SetHeight(LElement.H);
    end;
    if Assigned(AParent) and (LElement.X <> XCOM_UNSET) and (LElement.Y <> XCOM_UNSET) then
    begin
      ASurface.X := AParent.X + LElement.X;
      ASurface.Y := AParent.Y + LElement.Y;
    end;
    ASurface.TftdMode := LElement.TftdMode;
    if LElement.Color <> XCOM_UNSET then
      ASurface.SetColor(LElement.Color);
    if LElement.Color2 <> XCOM_UNSET then
      ASurface.SetSecondaryColor(LElement.Color2);
    if LElement.Border <> XCOM_UNSET then
      ASurface.SetBorderColor(LElement.Border);
  end;
  if Host.Language <> nil then
    ASurface.InitText(Host.Resources.GetFont('FONT_BIG'), Host.Resources.GetFont('FONT_SMALL'), Host.Language);
  FSurfaces.Add(ASurface);
end;

function TXcomState.IsScreen: Boolean;
begin
  Result := FScreen;
end;

procedure TXcomState.ToggleScreen;
begin
  FScreen := not FScreen;
end;

procedure TXcomState.Init;
var
  LSurface: TXcomWidget;
begin
  Host.Screen.SetPalette(@FPalette[0], 0, 256);
  Host.Cursor.SetPalette(@FPalette[0], 0, 256);
  Host.Cursor.SetColor(FCursorColor);
  Host.Cursor.Draw;
  Host.FpsCounter.SetPalette(@FPalette[0], 0, 256);
  Host.FpsCounter.SetColor(FCursorColor);
  Host.FpsCounter.Draw;
  if Host.Resources <> nil then
    Host.Resources.SetPalette(@FPalette[0], 0, 256);
  for LSurface in FSurfaces do
    LSurface.StateInitialized;
end;

procedure TXcomState.Think;
var
  LIndex: Integer;
begin
  // a copy of the count: a think can add surfaces but never removes them
  for LIndex := 0 to FSurfaces.Count - 1 do
    FSurfaces[LIndex].Think;
end;

procedure TXcomState.Handle(AAction: TXcomAction);
var
  LIndex: Integer;
  LSurface: TXcomWidget;
begin
  if not Assigned(FModal) then
  begin
    for LIndex := FSurfaces.Count - 1 downto 0 do
    begin
      LSurface := FSurfaces[LIndex];
      if LSurface is TXcomInteractiveSurface then
        TXcomInteractiveSurface(LSurface).Handle(AAction);
      // a handler can pop this state; the surfaces are freed later by the game, so the loop is safe
      if LIndex > FSurfaces.Count then
        Break;
    end;
  end
  else
    FModal.Handle(AAction);
end;

procedure TXcomState.Blit;
var
  LSurface: TXcomWidget;
begin
  for LSurface in FSurfaces do
    LSurface.Blit(Host.Screen.GetSurface);
end;

procedure TXcomState.HideAll;
var
  LSurface: TXcomWidget;
begin
  for LSurface in FSurfaces do
    LSurface.Hidden := True;
end;

procedure TXcomState.ShowAll;
var
  LSurface: TXcomWidget;
begin
  for LSurface in FSurfaces do
    LSurface.Hidden := False;
end;

procedure TXcomState.ResetAll;
var
  LSurface: TXcomWidget;
begin
  for LSurface in FSurfaces do
    if LSurface is TXcomInteractiveSurface then
      TXcomInteractiveSurface(LSurface).Unpress;
end;

function TXcomState.Tr(const AId: string): TXcomLocalizedText;
begin
  Result := Host.Language.GetString(AId);
end;

function TXcomState.Tr(const AId: string; ANumber: Cardinal): TXcomLocalizedText;
begin
  Result := Host.Language.GetString(AId, ANumber);
end;

procedure TXcomState.CenterAllSurfaces;
var
  LSurface: TXcomWidget;
begin
  for LSurface in FSurfaces do
  begin
    LSurface.X := LSurface.X + Host.Screen.DX;
    LSurface.Y := LSurface.Y + Host.Screen.DY;
  end;
end;

procedure TXcomState.LowerAllSurfaces;
var
  LSurface: TXcomWidget;
begin
  for LSurface in FSurfaces do
    LSurface.Y := LSurface.Y + Host.Screen.DY div 2;
end;

procedure TXcomState.RedrawText;
var
  LSurface: TXcomWidget;
begin
  for LSurface in FSurfaces do
    LSurface.RedrawText;
end;

procedure TXcomState.SetModal(ASurface: TXcomInteractiveSurface);
begin
  FModal := ASurface;
end;

procedure TXcomState.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer; AImmediately: Boolean);
begin
  if Assigned(AColors) then
    Move(AColors^, FPalette[AFirst], ACount * SizeOf(TXcomColor));
  if AImmediately then
  begin
    Host.Cursor.SetPalette(@FPalette[0], 0, 256);
    Host.Cursor.Draw;
    Host.FpsCounter.SetPalette(@FPalette[0], 0, 256);
    Host.FpsCounter.Draw;
    if Host.Resources <> nil then
      Host.Resources.SetPalette(@FPalette[0], 0, 256);
  end;
end;

procedure TXcomState.SetPalette(const APalette: string; ABackPalette: Integer);
var
  LBack: PXcomColor;
begin
  SetPalette(Host.Resources.GetPalette(APalette), 0, 256, False);
  FCursorColor := Host.Resources.CursorColor(APalette);
  if ABackPalette <> -1 then
  begin
    LBack := Host.Resources.GetPalette(PALETTE_BACKPALS);
    // Palette::blockOffset: blocks of 16 colors
    Inc(LBack, ABackPalette * 16);
    SetPalette(LBack, XCOM_BACKPOS, 16, False);
  end;
  // the update of the cursor and of the data waits for Init
  SetPalette(nil, 0, 0, True);
end;

function TXcomState.Palette: PXcomColors;
begin
  Result := @FPalette;
end;

procedure TXcomState.Resize(var ADX, ADY: Integer);
begin
  Recenter(ADX, ADY);
end;

procedure TXcomState.Recenter(ADX, ADY: Integer);
var
  LSurface: TXcomWidget;
begin
  for LSurface in FSurfaces do
  begin
    LSurface.X := LSurface.X + ADX div 2;
    LSurface.Y := LSurface.Y + ADY div 2;
  end;
end;

end.
