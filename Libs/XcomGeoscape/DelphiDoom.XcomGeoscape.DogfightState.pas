{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - DogfightState of OpenXcom (the window   }
{  of an interception: radar, weapons, damage and the attitude buttons)         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.DogfightState;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.Timer,
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.ImageButton,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomSave.CraftWeaponProjectile,
  DelphiDoom.XcomStrategy.Dogfight.Listener.Intf, DelphiDoom.XcomStrategy.DogfightEngine,
  DelphiDoom.XcomGeoscape.Control.Intf, DelphiDoom.XcomEngine.RuleInterface;

type
  /// <summary>
  ///   The window of one interception. It is not a screen of the game stack: the geoscape owns the dogfights, draws
  ///   them over the globe and gives them the events and the think (as GeoscapeState does). The combat itself is
  ///   TXcomDogfightEngine; this class draws what it reports and passes the clicks to it
  /// </summary>
  TXcomDogfightState = class(TXcomState)
  strict private
    type
      TWindowListener = class(TInterfacedObject, IXcomDogfightListener)
      strict private
        FOwner: TXcomDogfightState;
      public
        constructor Create(AOwner: TXcomDogfightState);
        procedure Detach;
        procedure StatusChanged(const AKey: string);
        procedure SoundPlayed(ASound: TXcomDogfightSound; AWeaponSound: Integer);
        procedure CraftDamaged;
        procedure AmmoChanged(AWeapon, AAmmo: Integer);
        procedure CannotEngage(const AReason: string);
        procedure Animating;
      end;
    const
      COLOR_CRAFT_MIN = 0;
      COLOR_CRAFT_MAX = 1;
      COLOR_RADAR_MIN = 2;
      COLOR_RADAR_MAX = 3;
      COLOR_DAMAGE_MIN = 4;
      COLOR_DAMAGE_MAX = 5;
      COLOR_BLOB_MIN = 6;
      COLOR_RANGE_METER = 7;
      COLOR_DISABLED_WEAPON = 8;
      COLOR_DISABLED_RANGE = 9;
      COLOR_DISABLED_AMMO = 10;
    var
      FControl: IXcomGeoscapeControl;
      FCraft: TXcomCraft;
      FUfo: TXcomUfo;
      FEngine: TXcomDogfightEngine;
      FListener: IXcomDogfightListener;
      FLand: IInterface;
      FColors: array[0..10] of Integer;
      FX: Integer;
      FY: Integer;
      FMinimizedIconX: Integer;
      FMinimizedIconY: Integer;
      FInterceptionsCount: Integer;
      FCurrentCraftDamageColor: Integer;
      FCraftHeight: Integer;
      FWindow: TXcomWidget;
      FBattle: TXcomWidget;
      FWeapon: array[0..1] of TXcomInteractiveSurface;
      FRange: array[0..1] of TXcomWidget;
      FAmmo: array[0..1] of TXcomText;
      FDamage: TXcomWidget;
      FBtnMinimize: TXcomInteractiveSurface;
      FPreview: TXcomInteractiveSurface;
      FBtnStandoff: TXcomImageButton;
      FBtnCautious: TXcomImageButton;
      FBtnStandard: TXcomImageButton;
      FBtnAggressive: TXcomImageButton;
      FBtnDisengage: TXcomImageButton;
      FBtnUfo: TXcomImageButton;
      FTxtDistance: TXcomText;
      FTxtStatus: TXcomText;
      FBtnMinimizedIcon: TXcomInteractiveSurface;
      FTxtInterceptionNumber: TXcomText;
      FMode: TXcomImageButtonGroup;
      FCraftDamageTimer: TXcomTimer;
    function Element(const AId: string; out AElement: TXcomInterfaceElement): Boolean;
    procedure DrawRange(AWeapon: Integer);
    procedure DrawCraftDamage;
    procedure AnimateCraftDamage;
    procedure AnimateWindow;
    procedure DrawUfo;
    procedure DrawProjectile(const AProjectile: TXcomCraftWeaponProjectile);
    procedure Recolor(AWeapon: Integer; AEnabled: Boolean);
    procedure ApplyMinimized;
    procedure CalculateWindowPosition;
    procedure MoveWindow;
    procedure PressMode(AMode: TXcomDogfightMode);
    procedure UfoClick(AAction: TXcomAction);
    procedure PreviewClick(AAction: TXcomAction);
    procedure MinimizeClick(AAction: TXcomAction);
    procedure MinimizedIconClick(AAction: TXcomAction);
    procedure WeaponClick(AIndex: Integer);
  public
    /// <param name="AControl">The geoscape (the popup of the errors, the globe)</param>
    /// <param name="ACraft">The craft that intercepts (not owned)</param>
    /// <param name="AUfo">The UFO (not owned)</param>
    constructor Create(AHost: TXcomStateHost; const AControl: IXcomGeoscapeControl; ACraft: TXcomCraft;
      AUfo: TXcomUfo);
    destructor Destroy; override;
    /// <summary>DogfightState::think</summary>
    procedure Think; override;
    /// <summary>setMinimized: also shows or hides the window</summary>
    procedure SetMinimized(AMinimized: Boolean);
    procedure SetInterceptionNumber(ANumber: Integer);
    /// <summary>setInterceptionsCount: the window goes to its place</summary>
    procedure SetInterceptionsCount(ACount: Integer);
    property Engine: TXcomDogfightEngine read FEngine;
    property Craft: TXcomCraft read FCraft;
    property Ufo: TXcomUfo read FUfo;
    property Window: TXcomWidget read FWindow;
    property Distance: TXcomText read FTxtDistance;
    property Status: TXcomText read FTxtStatus;
  end;

implementation

uses
  DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomSurface.Types,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomGeoscape.GlobeLandMap, DelphiDoom.XcomGeoscape.DogfightErrorState,
  DelphiDoom.XcomGeoscape.TargetNames, DelphiDoom.XcomStrategy.LandMap.Intf, DelphiDoom.XcomMod.RuleCraftWeapon,
  DelphiDoom.XcomSave.CraftWeapon;

type
  TUfoBlob = array[0..12, 0..12] of Byte;
  TProjectileBlob = array[0..5, 0..2] of Byte;

const
  // UFO blobs graphics: the UFO of the radar by size (0 STR_VERY_SMALL ... 7 STR_ENORMOUS)
  UFO_BLOBS: array[0..7] of TUfoBlob = (
    ((0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
     (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0), (0, 0, 0, 0, 1, 2, 3, 2, 1, 0, 0, 0, 0),
     (0, 0, 0, 0, 1, 3, 5, 3, 1, 0, 0, 0, 0), (0, 0, 0, 0, 1, 2, 3, 2, 1, 0, 0, 0, 0), (0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0),
     (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
     (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
    ((0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
     (0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0), (0, 0, 0, 0, 1, 2, 2, 2, 1, 0, 0, 0, 0), (0, 0, 0, 1, 2, 3, 4, 3, 2, 1, 0, 0, 0),
     (0, 0, 0, 1, 2, 4, 5, 4, 2, 1, 0, 0, 0), (0, 0, 0, 1, 2, 3, 4, 3, 2, 1, 0, 0, 0), (0, 0, 0, 0, 1, 2, 2, 2, 1, 0, 0, 0, 0),
     (0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
     (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
    ((0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0),
     (0, 0, 0, 1, 1, 2, 2, 2, 1, 1, 0, 0, 0), (0, 0, 0, 1, 2, 3, 3, 3, 2, 1, 0, 0, 0), (0, 0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 0, 0),
     (0, 0, 1, 2, 3, 5, 5, 5, 3, 2, 1, 0, 0), (0, 0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 0, 0), (0, 0, 0, 1, 2, 3, 3, 3, 2, 1, 0, 0, 0),
     (0, 0, 0, 1, 1, 2, 2, 2, 1, 1, 0, 0, 0), (0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
     (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
    ((0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), (0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0), (0, 0, 0, 1, 1, 2, 2, 2, 1, 1, 0, 0, 0),
     (0, 0, 1, 2, 2, 3, 3, 3, 2, 2, 1, 0, 0), (0, 0, 1, 2, 3, 4, 4, 4, 3, 2, 1, 0, 0), (0, 1, 2, 3, 4, 5, 5, 5, 4, 3, 2, 1, 0),
     (0, 1, 2, 3, 4, 5, 5, 5, 4, 3, 2, 1, 0), (0, 1, 2, 3, 4, 5, 5, 5, 4, 3, 2, 1, 0), (0, 0, 1, 2, 3, 4, 4, 4, 3, 2, 1, 0, 0),
     (0, 0, 1, 2, 2, 3, 3, 3, 2, 2, 1, 0, 0), (0, 0, 0, 1, 1, 2, 2, 2, 1, 1, 0, 0, 0), (0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0),
     (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
    ((0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0), (0, 0, 0, 1, 1, 2, 2, 2, 1, 1, 0, 0, 0), (0, 0, 1, 2, 2, 3, 3, 3, 2, 2, 1, 0, 0),
     (0, 1, 2, 3, 3, 4, 4, 4, 3, 3, 2, 1, 0), (0, 1, 2, 3, 4, 5, 5, 5, 4, 3, 2, 1, 0), (1, 2, 3, 4, 5, 5, 5, 5, 5, 4, 3, 2, 1),
     (1, 2, 3, 4, 5, 5, 5, 5, 5, 4, 3, 2, 1), (1, 2, 3, 4, 5, 5, 5, 5, 5, 4, 3, 2, 1), (0, 1, 2, 3, 4, 5, 5, 5, 4, 3, 2, 1, 0),
     (0, 1, 2, 3, 3, 4, 4, 4, 3, 3, 2, 1, 0), (0, 0, 1, 2, 2, 3, 3, 3, 2, 2, 1, 0, 0), (0, 0, 0, 1, 1, 2, 2, 2, 1, 1, 0, 0, 0),
     (0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0)),
    ((0, 0, 0, 1, 1, 2, 2, 2, 1, 1, 0, 0, 0), (0, 0, 1, 2, 2, 3, 3, 3, 2, 2, 1, 0, 0), (0, 1, 2, 3, 3, 4, 4, 4, 3, 3, 2, 1, 0),
     (1, 2, 3, 4, 4, 5, 5, 5, 4, 4, 3, 2, 1), (1, 2, 3, 4, 5, 5, 5, 5, 5, 4, 3, 2, 1), (2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3, 2),
     (2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3, 2), (2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3, 2), (1, 2, 3, 4, 5, 5, 5, 5, 5, 4, 3, 2, 1),
     (1, 2, 3, 4, 4, 5, 5, 5, 4, 4, 3, 2, 1), (0, 1, 2, 3, 3, 4, 4, 4, 3, 3, 2, 1, 0), (0, 0, 1, 2, 2, 3, 3, 3, 2, 2, 1, 0, 0),
     (0, 0, 0, 1, 1, 2, 2, 2, 1, 1, 0, 0, 0)),
    ((0, 0, 0, 2, 2, 3, 3, 3, 2, 2, 0, 0, 0), (0, 0, 2, 3, 3, 4, 4, 4, 3, 3, 2, 0, 0), (0, 2, 3, 4, 4, 5, 5, 5, 4, 4, 3, 2, 0),
     (2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3, 2), (2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3, 2), (3, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 3),
     (3, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 3), (3, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 3), (2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3, 2),
     (2, 3, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3, 2), (0, 2, 3, 4, 4, 5, 5, 5, 4, 4, 3, 2, 0), (0, 0, 2, 3, 3, 4, 4, 4, 3, 3, 2, 0, 0),
     (0, 0, 0, 2, 2, 3, 3, 3, 2, 2, 0, 0, 0)),
    ((0, 0, 0, 3, 3, 4, 4, 4, 3, 3, 0, 0, 0), (0, 0, 3, 4, 4, 5, 5, 5, 4, 4, 3, 0, 0), (0, 3, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3, 0),
     (3, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 3), (3, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 3), (4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4),
     (4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4), (4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4), (3, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 3),
     (3, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 3), (0, 3, 4, 5, 5, 5, 5, 5, 5, 5, 4, 3, 0), (0, 0, 3, 4, 4, 5, 5, 5, 4, 4, 3, 0, 0),
     (0, 0, 0, 3, 3, 4, 4, 4, 3, 3, 0, 0, 0)));

  // projectile blobs (0 STR_STINGRAY_MISSILE, 1 STR_AVALANCHE_MISSILE, 2 STR_CANNON_ROUND, 3 STR_FUSION_BALL)
  PROJECTILE_BLOBS: array[0..3] of TProjectileBlob = (
    ((0, 1, 0), (1, 9, 1), (1, 4, 1), (0, 3, 0), (0, 2, 0), (0, 1, 0)),
    ((1, 2, 1), (2, 9, 2), (2, 5, 2), (1, 3, 1), (0, 2, 0), (0, 1, 0)),
    ((0, 0, 0), (0, 7, 0), (0, 2, 0), (0, 1, 0), (0, 0, 0), (0, 0, 0)),
    ((2, 4, 2), (4, 9, 4), (2, 4, 2), (0, 0, 0), (0, 0, 0), (0, 0, 0)));

{ TXcomDogfightState.TWindowListener }

constructor TXcomDogfightState.TWindowListener.Create(AOwner: TXcomDogfightState);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TXcomDogfightState.TWindowListener.Detach;
begin
  FOwner := nil;
end;

procedure TXcomDogfightState.TWindowListener.StatusChanged(const AKey: string);
begin
  if FOwner = nil then
    Exit;
  if AKey = '' then
    FOwner.FTxtStatus.SetText('')
  else
    FOwner.FTxtStatus.SetText(FOwner.Tr(AKey));
end;

procedure TXcomDogfightState.TWindowListener.SoundPlayed(ASound: TXcomDogfightSound; AWeaponSound: Integer);
begin
  if FOwner = nil then
    Exit;
  with FOwner.Host do
    case ASound of
      dsUfoFire: PlaySound('GEO.CAT', Resources.Constant('ufoFire', 8));
      dsUfoHit: PlaySound('GEO.CAT', Resources.Constant('ufoHit', 12));
      dsUfoCrash: PlaySound('GEO.CAT', Resources.Constant('ufoCrash', 10));
      dsUfoExplode: PlaySound('GEO.CAT', Resources.Constant('ufoExplode', 11));
      dsInterceptorHit: PlaySound('GEO.CAT', Resources.Constant('interceptorHit', 10));
      dsInterceptorExplode: PlaySound('GEO.CAT', Resources.Constant('interceptorExplode', 13));
      dsWeapon: PlaySound('GEO.CAT', AWeaponSound);
    end;
end;

procedure TXcomDogfightState.TWindowListener.CraftDamaged;
begin
  if FOwner <> nil then
    FOwner.DrawCraftDamage;
end;

procedure TXcomDogfightState.TWindowListener.AmmoChanged(AWeapon, AAmmo: Integer);
begin
  if FOwner <> nil then
    FOwner.FAmmo[AWeapon].SetText(IntToStr(AAmmo));
end;

procedure TXcomDogfightState.TWindowListener.CannotEngage(const AReason: string);
begin
  if FOwner <> nil then
    FOwner.FControl.Popup(TXcomDogfightErrorState.Create(FOwner.Host, FOwner.FCraft,
      TXcomTargetNames.Name(FOwner.FCraft, FOwner.Host.Language), FOwner.Tr(AReason).Text));
end;

procedure TXcomDogfightState.TWindowListener.Animating;
begin
  if FOwner <> nil then
    FOwner.AnimateWindow;
end;

{ TXcomDogfightState }

function TXcomDogfightState.Element(const AId: string; out AElement: TXcomInterfaceElement): Boolean;
var
  LInterface: TXcomRuleInterface;
begin
  LInterface := Host.Resources.GetInterface('dogfight');
  Result := Assigned(LInterface) and LInterface.TryGetElement(AId, AElement);
  if not Result then
    AElement := Default(TXcomInterfaceElement);
end;

constructor TXcomDogfightState.Create(AHost: TXcomStateHost; const AControl: IXcomGeoscapeControl;
  ACraft: TXcomCraft; AUfo: TXcomUfo);
var
  LGraphic, LFrame: TXcomSurface;
  LSet: TXcomSurfaceSet;
  LElement, LTop, LMid, LBot: TXcomInterfaceElement;
  LCrop: TXcomRect;
  LIndex, LY, LX, LWeaponCount: Integer;
  LWeapon: TXcomCraftWeapon;
begin
  inherited Create(AHost);
  FControl := AControl;
  FCraft := ACraft;
  FUfo := AUfo;
  FCurrentCraftDamageColor := 0;
  ToggleScreen;
  FListener := TWindowListener.Create(Self);
  FLand := TXcomGlobeLandMap.Create(AControl.Globe);
  FEngine := TXcomDogfightEngine.Create(TXcomStrategy.SavedGame(AHost), TXcomStrategy.Ruleset(AHost),
    TXcomStrategy.Random(AHost), FLand as IXcomLandMap, FListener, ACraft, AUfo);
  // objects
  FWindow := TXcomWidget.Create(160, 96, FX, FY);
  FBattle := TXcomWidget.Create(77, 74, FX + 3, FY + 3);
  FWeapon[0] := TXcomInteractiveSurface.Create(15, 17, FX + 4, FY + 52);
  FRange[0] := TXcomWidget.Create(21, 74, FX + 19, FY + 3);
  FWeapon[1] := TXcomInteractiveSurface.Create(15, 17, FX + 64, FY + 52);
  FRange[1] := TXcomWidget.Create(21, 74, FX + 43, FY + 3);
  FDamage := TXcomWidget.Create(22, 25, FX + 93, FY + 40);
  FBtnMinimize := TXcomInteractiveSurface.Create(12, 12, FX, FY);
  FPreview := TXcomInteractiveSurface.Create(160, 96, FX, FY);
  FBtnStandoff := TXcomImageButton.Create(36, 15, FX + 83, FY + 4);
  FBtnCautious := TXcomImageButton.Create(36, 15, FX + 120, FY + 4);
  FBtnStandard := TXcomImageButton.Create(36, 15, FX + 83, FY + 20);
  FBtnAggressive := TXcomImageButton.Create(36, 15, FX + 120, FY + 20);
  FBtnDisengage := TXcomImageButton.Create(36, 15, FX + 120, FY + 36);
  FBtnUfo := TXcomImageButton.Create(36, 17, FX + 120, FY + 52);
  FAmmo[0] := TXcomText.Create(16, 9, FX + 4, FY + 70);
  FAmmo[1] := TXcomText.Create(16, 9, FX + 64, FY + 70);
  FTxtDistance := TXcomText.Create(40, 9, FX + 116, FY + 72);
  FTxtStatus := TXcomText.Create(150, 9, FX + 4, FY + 85);
  FBtnMinimizedIcon := TXcomInteractiveSurface.Create(32, 20, FMinimizedIconX, FMinimizedIconY);
  FTxtInterceptionNumber := TXcomText.Create(16, 9, FMinimizedIconX + 18, FMinimizedIconY + 6);
  FMode := TXcomImageButtonGroup.Create;
  FMode.Selected := FBtnStandoff;
  FCraftDamageTimer := TXcomTimer.Create(AHost.Clock, 500);
  SetInterface('dogfight');
  Add(FWindow);
  Add(FBattle);
  Add(FWeapon[0]);
  Add(FRange[0]);
  Add(FWeapon[1]);
  Add(FRange[1]);
  Add(FDamage);
  Add(FBtnMinimize);
  Add(FBtnStandoff, 'standoffButton', 'dogfight', FWindow);
  Add(FBtnCautious, 'cautiousButton', 'dogfight', FWindow);
  Add(FBtnStandard, 'standardButton', 'dogfight', FWindow);
  Add(FBtnAggressive, 'aggressiveButton', 'dogfight', FWindow);
  Add(FBtnDisengage, 'disengageButton', 'dogfight', FWindow);
  Add(FBtnUfo, 'ufoButton', 'dogfight', FWindow);
  Add(FAmmo[0], 'numbers', 'dogfight', FWindow);
  Add(FAmmo[1], 'numbers', 'dogfight', FWindow);
  Add(FTxtDistance, 'distance', 'dogfight', FWindow);
  Add(FPreview);
  Add(FTxtStatus, 'text', 'dogfight', FWindow);
  Add(FBtnMinimizedIcon);
  Add(FTxtInterceptionNumber, 'minimizedNumber', 'dogfight');
  FBtnStandoff.Invalidate(False);
  FBtnCautious.Invalidate(False);
  FBtnStandard.Invalidate(False);
  FBtnAggressive.Invalidate(False);
  FBtnDisengage.Invalidate(False);
  FBtnUfo.Invalidate(False);
  // the window and the front view of the UFO come from INTERWIN.DAT
  LGraphic := Host.Resources.GetSurface('INTERWIN.DAT');
  LGraphic.X := 0;
  LGraphic.Y := 0;
  LCrop := TXcomRect.Make(0, 0, FWindow.Width, FWindow.Height);
  LGraphic.Crop := LCrop;
  FWindow.DrawRect(LCrop, 15);
  LGraphic.Blit(FWindow);
  Element('previewTop', LTop);
  Element('previewMid', LMid);
  Element('previewBot', LBot);
  FPreview.DrawRect(LCrop, 15);
  LGraphic.Crop := TXcomRect.Make(0, LTop.Y, FWindow.Width, LTop.H);
  LGraphic.Blit(FPreview);
  LGraphic.Y := FWindow.Height - LBot.H;
  LGraphic.Crop := TXcomRect.Make(0, LBot.Y, FWindow.Width, LBot.H);
  LGraphic.Blit(FPreview);
  if FUfo.Rules.ModSprite = '' then
  begin
    LGraphic.Crop := TXcomRect.Make(0, LMid.Y + LMid.H * FUfo.Rules.Sprite, FWindow.Width, LMid.H);
    LGraphic.X := LTop.X;
    LGraphic.Y := LTop.H;
    LGraphic.Blit(FPreview);
  end
  else
  begin
    LGraphic := Host.Resources.GetSurface(FUfo.Rules.ModSprite);
    LGraphic.X := LTop.X;
    LGraphic.Y := LTop.H;
    LGraphic.Blit(FPreview);
  end;
  FPreview.Visible := False;
  FPreview.OnMouseClick(PreviewClick);
  FBtnMinimize.OnMouseClick(MinimizeClick);
  FBtnStandoff.Copy(FWindow);
  FBtnStandoff.SetGroup(FMode);
  FBtnStandoff.OnMousePress(
    procedure(AAction: TXcomAction)
    begin
      PressMode(dmStandoff);
    end);
  FBtnCautious.Copy(FWindow);
  FBtnCautious.SetGroup(FMode);
  FBtnCautious.OnMousePress(
    procedure(AAction: TXcomAction)
    begin
      PressMode(dmCautious);
    end);
  FBtnStandard.Copy(FWindow);
  FBtnStandard.SetGroup(FMode);
  FBtnStandard.OnMousePress(
    procedure(AAction: TXcomAction)
    begin
      PressMode(dmStandard);
    end);
  FBtnAggressive.Copy(FWindow);
  FBtnAggressive.SetGroup(FMode);
  FBtnAggressive.OnMousePress(
    procedure(AAction: TXcomAction)
    begin
      PressMode(dmAggressive);
    end);
  FBtnDisengage.Copy(FWindow);
  FBtnDisengage.SetGroup(FMode);
  FBtnDisengage.OnMousePress(
    procedure(AAction: TXcomAction)
    begin
      PressMode(dmDisengage);
    end);
  FBtnUfo.Copy(FWindow);
  FBtnUfo.OnMouseClick(UfoClick);
  FTxtDistance.SetText('640');
  FTxtStatus.SetText(Tr('STR_STANDOFF'));
  LSet := TXcomStrategy.Rules(AHost).GetSurfaceSet('INTICON.PCK');
  // the minimized dogfight icon
  LFrame := LSet.GetFrame(FCraft.Rules.Sprite);
  LFrame.X := 0;
  LFrame.Y := 0;
  LFrame.Blit(FBtnMinimizedIcon);
  FBtnMinimizedIcon.OnMouseClick(MinimizedIconClick);
  FBtnMinimizedIcon.Visible := False;
  FTxtInterceptionNumber.SetText(IntToStr(FCraft.InterceptionOrder));
  FTxtInterceptionNumber.Visible := False;
  // the colors
  Element('craftRange', LElement);
  FColors[COLOR_CRAFT_MIN] := LElement.Color;
  FColors[COLOR_CRAFT_MAX] := LElement.Color2;
  Element('radarRange', LElement);
  FColors[COLOR_RADAR_MIN] := LElement.Color;
  FColors[COLOR_RADAR_MAX] := LElement.Color2;
  Element('damageRange', LElement);
  FColors[COLOR_DAMAGE_MIN] := LElement.Color;
  FColors[COLOR_DAMAGE_MAX] := LElement.Color2;
  Element('radarDetail', LElement);
  FColors[COLOR_BLOB_MIN] := LElement.Color;
  FColors[COLOR_RANGE_METER] := LElement.Color2;
  Element('disabledWeapon', LElement);
  FColors[COLOR_DISABLED_WEAPON] := LElement.Color;
  FColors[COLOR_DISABLED_RANGE] := LElement.Color2;
  Element('disabledAmmo', LElement);
  FColors[COLOR_DISABLED_AMMO] := LElement.Color;
  LWeaponCount := FCraft.Rules.Weapons;
  for LIndex := 0 to Min(LWeaponCount, 2) - 1 do
  begin
    if (LIndex >= FCraft.Weapons.Count) or (FCraft.Weapons[LIndex] = nil) then
      Continue;
    LWeapon := FCraft.Weapons[LIndex];
    // the weapon icon and the ammunition
    LFrame := LSet.GetFrame(TXcomStrategy.Ruleset(AHost).CraftWeapons.Find(LWeapon.Rules.WeaponType).Sprite + 5);
    LFrame.X := 0;
    LFrame.Y := 0;
    LFrame.Blit(FWeapon[LIndex]);
    FAmmo[LIndex].SetText(IntToStr(LWeapon.Ammo));
    DrawRange(LIndex);
  end;
  if not ((LWeaponCount > 0) and (FCraft.Weapons.Count > 0) and (FCraft.Weapons[0] <> nil)) then
  begin
    FWeapon[0].Visible := False;
    FRange[0].Visible := False;
    FAmmo[0].Visible := False;
  end;
  if not ((LWeaponCount > 1) and (FCraft.Weapons.Count > 1) and (FCraft.Weapons[1] <> nil)) then
  begin
    FWeapon[1].Visible := False;
    FRange[1].Visible := False;
    FAmmo[1].Visible := False;
  end;
  // the damage indicator
  LFrame := LSet.GetFrame(FCraft.Rules.Sprite + 11);
  LFrame.X := 0;
  LFrame.Y := 0;
  LFrame.Blit(FDamage);
  FCraftDamageTimer.OnTimerState(AnimateCraftDamage);
  // the height of the craft, for the damage indication
  LX := FDamage.Width div 2;
  FCraftHeight := 0;
  for LY := 0 to FDamage.Height - 1 do
    if (FDamage.GetPixel(LX, LY) >= FColors[COLOR_CRAFT_MIN]) and (FDamage.GetPixel(LX, LY) < FColors[COLOR_CRAFT_MAX]) then
      Inc(FCraftHeight);
  DrawCraftDamage;
  FWeapon[0].OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      WeaponClick(0);
    end);
  FWeapon[1].OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      WeaponClick(1);
    end);
end;

destructor TXcomDogfightState.Destroy;
begin
  // the engine can still tell the window something while it ends: the listener goes first
  TWindowListener(FListener as TObject).Detach;
  FEngine.Free;
  FCraftDamageTimer.Free;
  FMode.Free;
  inherited Destroy;
end;

procedure TXcomDogfightState.DrawRange(AWeapon: Integer);
var
  LRange, LX1, LX2, LRangeY, LConnectY, LMinY, LMaxY, LX, LY: Integer;
  LColor: Byte;
begin
  LRange := TXcomStrategy.Ruleset(Host).CraftWeapons.Find(FCraft.Weapons[AWeapon].Rules.WeaponType).Range;
  if AWeapon = 0 then
  begin
    LX1 := 2;
    LX2 := 0;
  end
  else
  begin
    LX1 := 0;
    LX2 := 18;
  end;
  // the range, 1 km is 1 pixel
  LColor := Byte(FColors[COLOR_RANGE_METER]);
  LRangeY := FRange[AWeapon].Height - LRange;
  LConnectY := 57;
  LX := LX1;
  while LX <= LX1 + 18 do
  begin
    FRange[AWeapon].SetPixel(LX, LRangeY, LColor);
    Inc(LX, 2);
  end;
  LMinY := 0;
  LMaxY := 0;
  if LRangeY < LConnectY then
  begin
    LMinY := LRangeY;
    LMaxY := LConnectY;
  end
  else if LRangeY > LConnectY then
  begin
    LMinY := LConnectY;
    LMaxY := LRangeY;
  end;
  for LY := LMinY to LMaxY do
    FRange[AWeapon].SetPixel(LX1 + LX2, LY, LColor);
  for LX := LX2 to LX2 + 2 do
    FRange[AWeapon].SetPixel(LX, LConnectY, LColor);
end;

procedure TXcomDogfightState.DrawCraftDamage;
var
  LPercentage, LRowsToColor, LRowsColored, LX, LY, LPixel: Integer;
  LRowColored: Boolean;
begin
  if FCraft.DamagePercentage = 0 then
    Exit;
  if not FCraftDamageTimer.IsRunning then
  begin
    FCraftDamageTimer.Start;
    if FCurrentCraftDamageColor < FColors[COLOR_DAMAGE_MIN] then
      FCurrentCraftDamageColor := FColors[COLOR_DAMAGE_MIN];
  end;
  LPercentage := FCraft.DamagePercentage;
  LRowsToColor := Floor(Double(FCraftHeight) * Double(LPercentage / 100.0));
  if LRowsToColor = 0 then
    Exit;
  LRowsColored := 0;
  for LY := 0 to FDamage.Height - 1 do
  begin
    LRowColored := False;
    for LX := 0 to FDamage.Width - 1 do
    begin
      LPixel := FDamage.GetPixel(LX, LY);
      if (LPixel >= FColors[COLOR_DAMAGE_MIN]) and (LPixel <= FColors[COLOR_DAMAGE_MAX]) then
      begin
        FDamage.SetPixel(LX, LY, Byte(FCurrentCraftDamageColor));
        LRowColored := True;
      end;
      if (LPixel >= FColors[COLOR_CRAFT_MIN]) and (LPixel < FColors[COLOR_CRAFT_MAX]) then
      begin
        FDamage.SetPixel(LX, LY, Byte(FCurrentCraftDamageColor));
        LRowColored := True;
      end;
    end;
    if LRowColored then
      Inc(LRowsColored);
    if LRowsColored = LRowsToColor then
      Break;
  end;
end;

procedure TXcomDogfightState.AnimateCraftDamage;
begin
  if FEngine.Minimized then
    Exit;
  Dec(FCurrentCraftDamageColor);
  if FCurrentCraftDamageColor < FColors[COLOR_DAMAGE_MIN] then
    FCurrentCraftDamageColor := FColors[COLOR_DAMAGE_MAX];
  DrawCraftDamage;
end;

procedure TXcomDogfightState.AnimateWindow;
var
  LX, LY: Integer;
  LPixel: Byte;
  LProjectile: TXcomCraftWeaponProjectile;
begin
  // the radar waves and the other palette effects
  for LX := 0 to FWindow.Width - 1 do
    for LY := 0 to FWindow.Height - 1 do
    begin
      LPixel := FWindow.GetPixel(LX, LY);
      if (LPixel >= FColors[COLOR_RADAR_MIN]) and (LPixel < FColors[COLOR_RADAR_MAX]) then
      begin
        Inc(LPixel);
        if LPixel >= FColors[COLOR_RADAR_MAX] then
          LPixel := Byte(FColors[COLOR_RADAR_MIN]);
        FWindow.SetPixel(LX, LY, LPixel);
      end;
    end;
  FBattle.Clear;
  if not FUfo.IsDestroyed then
    DrawUfo;
  for LProjectile in FEngine.Projectiles do
    DrawProjectile(LProjectile);
end;

procedure TXcomDogfightState.DrawUfo;
var
  LPositionX, LPositionY, LX, LY, LOffset: Integer;
  LRadar, LColor: Integer;
begin
  if (FEngine.UfoSize < 0) or FUfo.IsDestroyed then
    Exit;
  LPositionX := FBattle.Width div 2 - 6;
  LPositionY := FBattle.Height - (FEngine.CurrentDistance div 8) - 6;
  for LY := 0 to 12 do
    for LX := 0 to 12 do
    begin
      LOffset := UFO_BLOBS[FEngine.UfoSize + FUfo.HitFrame][LY][LX];
      if LOffset = 0 then
        Continue;
      if FUfo.IsCrashed or (FUfo.HitFrame > 0) then
        LOffset := Byte(LOffset * 2);
      // + 3 because of the frame of the window
      LRadar := FWindow.GetPixel(LPositionX + LX + 3, LPositionY + LY + 3);
      LColor := Byte(LRadar - LOffset);
      if LColor < FColors[COLOR_BLOB_MIN] then
        LColor := FColors[COLOR_BLOB_MIN];
      FBattle.SetPixel(LPositionX + LX, LPositionY + LY, Byte(LColor));
    end;
end;

procedure TXcomDogfightState.DrawProjectile(const AProjectile: TXcomCraftWeaponProjectile);
var
  LXPosition, LYPosition, LX, LY, LOffset, LColor, LYStart, LYEnd: Integer;
begin
  LXPosition := FBattle.Width div 2 + AProjectile.HorizontalPosition;
  if AProjectile.Kind = pkMissile then
  begin
    Dec(LXPosition);
    LYPosition := FBattle.Height - AProjectile.Position div 8;
    for LX := 0 to 2 do
      for LY := 0 to 5 do
      begin
        LOffset := PROJECTILE_BLOBS[Ord(AProjectile.ProjectileType)][LY][LX];
        if LOffset = 0 then
          Continue;
        LColor := Byte(FWindow.GetPixel(LXPosition + LX + 3, LYPosition + LY + 3) - LOffset);
        if LColor < FColors[COLOR_BLOB_MIN] then
          LColor := FColors[COLOR_BLOB_MIN];
        FBattle.SetPixel(LXPosition + LX, LYPosition + LY, Byte(LColor));
      end;
  end
  else
  begin
    LYStart := FBattle.Height - 2;
    LYEnd := FBattle.Height - (FEngine.CurrentDistance div 8);
    LOffset := Byte(AProjectile.State);
    LY := LYStart;
    while LY > LYEnd do
    begin
      LColor := Byte(FWindow.GetPixel(LXPosition + 3, LY + 3) - LOffset);
      if LColor < FColors[COLOR_BLOB_MIN] then
        LColor := FColors[COLOR_BLOB_MIN];
      FBattle.SetPixel(LXPosition, LY, Byte(LColor));
      Dec(LY);
    end;
  end;
end;

procedure TXcomDogfightState.Think;
var
  LWasEnded: Boolean;
begin
  LWasEnded := FEngine.Ended;
  FEngine.Think;
  if not LWasEnded then
    FCraftDamageTimer.Think(True, False);
  FTxtDistance.SetText(IntToStr(FEngine.CurrentDistance));
end;

procedure TXcomDogfightState.PressMode(AMode: TXcomDogfightMode);
begin
  FEngine.PressMode(AMode);
end;

procedure TXcomDogfightState.UfoClick(AAction: TXcomAction);
begin
  FPreview.Visible := True;
  // all the other buttons are disabled to prevent misclicks
  FBtnStandoff.Visible := False;
  FBtnCautious.Visible := False;
  FBtnStandard.Visible := False;
  FBtnAggressive.Visible := False;
  FBtnDisengage.Visible := False;
  FBtnUfo.Visible := False;
  FBtnMinimize.Visible := False;
  FWeapon[0].Visible := False;
  FWeapon[1].Visible := False;
end;

procedure TXcomDogfightState.PreviewClick(AAction: TXcomAction);
begin
  FPreview.Visible := False;
  FBtnStandoff.Visible := True;
  FBtnCautious.Visible := True;
  FBtnStandard.Visible := True;
  FBtnAggressive.Visible := True;
  FBtnDisengage.Visible := True;
  FBtnUfo.Visible := True;
  FBtnMinimize.Visible := True;
  FWeapon[0].Visible := True;
  FWeapon[1].Visible := True;
end;

procedure TXcomDogfightState.MinimizeClick(AAction: TXcomAction);
begin
  FEngine.MinimizeClick;
  ApplyMinimized;
end;

procedure TXcomDogfightState.MinimizedIconClick(AAction: TXcomAction);
begin
  FEngine.MinimizedIconClick;
  ApplyMinimized;
end;

procedure TXcomDogfightState.WeaponClick(AIndex: Integer);
begin
  FEngine.ToggleWeapon(AIndex);
  Recolor(AIndex, FEngine.WeaponEnabled(AIndex));
end;

procedure TXcomDogfightState.Recolor(AWeapon: Integer; AEnabled: Boolean);
begin
  if AEnabled then
  begin
    FWeapon[AWeapon].Offset(-FColors[COLOR_DISABLED_WEAPON]);
    FAmmo[AWeapon].Offset(-FColors[COLOR_DISABLED_AMMO]);
    FRange[AWeapon].Offset(-FColors[COLOR_DISABLED_RANGE]);
  end
  else
  begin
    FWeapon[AWeapon].Offset(FColors[COLOR_DISABLED_WEAPON]);
    FAmmo[AWeapon].Offset(FColors[COLOR_DISABLED_AMMO]);
    FRange[AWeapon].Offset(FColors[COLOR_DISABLED_RANGE]);
  end;
end;

procedure TXcomDogfightState.ApplyMinimized;
var
  LMinimized: Boolean;
begin
  LMinimized := FEngine.Minimized;
  FBtnMinimizedIcon.Visible := LMinimized;
  FTxtInterceptionNumber.Visible := LMinimized;
  FWindow.Visible := not LMinimized;
  FBtnStandoff.Visible := not LMinimized;
  FBtnCautious.Visible := not LMinimized;
  FBtnStandard.Visible := not LMinimized;
  FBtnAggressive.Visible := not LMinimized;
  FBtnDisengage.Visible := not LMinimized;
  FBtnUfo.Visible := not LMinimized;
  FBtnMinimize.Visible := not LMinimized;
  FBattle.Visible := not LMinimized;
  FWeapon[0].Visible := (not LMinimized) and (FCraft.Weapons.Count > 0) and (FCraft.Weapons[0] <> nil);
  FRange[0].Visible := FWeapon[0].Visible;
  FWeapon[1].Visible := (not LMinimized) and (FCraft.Weapons.Count > 1) and (FCraft.Weapons[1] <> nil);
  FRange[1].Visible := FWeapon[1].Visible;
  FDamage.Visible := not LMinimized;
  FAmmo[0].Visible := FWeapon[0].Visible;
  FAmmo[1].Visible := FWeapon[1].Visible;
  FTxtDistance.Visible := not LMinimized;
  FTxtStatus.Visible := not LMinimized;
  // set to false regardless
  FPreview.Visible := False;
end;

procedure TXcomDogfightState.SetMinimized(AMinimized: Boolean);
begin
  FEngine.SetMinimized(AMinimized);
  ApplyMinimized;
end;

procedure TXcomDogfightState.SetInterceptionNumber(ANumber: Integer);
begin
  FEngine.SetInterceptionNumber(ANumber);
end;

procedure TXcomDogfightState.SetInterceptionsCount(ACount: Integer);
begin
  FInterceptionsCount := ACount;
  CalculateWindowPosition;
  MoveWindow;
end;

procedure TXcomDogfightState.CalculateWindowPosition;
var
  LNumber: Integer;
begin
  LNumber := FEngine.InterceptionNumber;
  FMinimizedIconX := 5;
  FMinimizedIconY := (5 * LNumber) + (16 * (LNumber - 1));
  if FInterceptionsCount = 1 then
  begin
    FX := 80;
    FY := 52;
  end
  else if FInterceptionsCount = 2 then
  begin
    FX := 80;
    if LNumber = 1 then
      FY := 0
    else
      FY := 200 - FWindow.Height;
  end
  else if FInterceptionsCount = 3 then
  begin
    if LNumber = 1 then
    begin
      FX := 80;
      FY := 0;
    end
    else if LNumber = 2 then
    begin
      FX := 0;
      FY := 200 - FWindow.Height;
    end
    else
    begin
      FX := 320 - FWindow.Width;
      FY := 200 - FWindow.Height;
    end;
  end
  else
  begin
    if LNumber = 1 then
    begin
      FX := 0;
      FY := 0;
    end
    else if LNumber = 2 then
    begin
      FX := 320 - FWindow.Width;
      FY := 0;
    end
    else if LNumber = 3 then
    begin
      FX := 0;
      FY := 200 - FWindow.Height;
    end
    else
    begin
      FX := 320 - FWindow.Width;
      FY := 200 - FWindow.Height;
    end;
  end;
  Inc(FX, Host.Screen.DX);
  Inc(FY, Host.Screen.DY);
end;

procedure TXcomDogfightState.MoveWindow;
var
  LDX, LDY, LIndex: Integer;
begin
  LDX := FWindow.X - FX;
  LDY := FWindow.Y - FY;
  for LIndex := 0 to Surfaces.Count - 1 do
  begin
    Surfaces[LIndex].X := Surfaces[LIndex].X - LDX;
    Surfaces[LIndex].Y := Surfaces[LIndex].Y - LDY;
  end;
  FBtnMinimizedIcon.X := FMinimizedIconX;
  FBtnMinimizedIcon.Y := FMinimizedIconY;
  FTxtInterceptionNumber.X := FMinimizedIconX + 18;
  FTxtInterceptionNumber.Y := FMinimizedIconY + 6;
end;

end.
