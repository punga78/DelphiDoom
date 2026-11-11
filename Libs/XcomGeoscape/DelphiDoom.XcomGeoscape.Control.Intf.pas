{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - what the popups ask of the geoscape      }
{  (GeoscapeState::timerReset, getGlobe, popup)                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.Control.Intf;

interface

uses
  System.Generics.Collections, DelphiDoom.XcomEngine.State, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomSave.Target, DelphiDoom.XcomSave.Waypoint,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomGeoscape.Globe,
  DelphiDoom.XcomBasescape.Navigator.Intf, DelphiDoom.XcomEngine.Types;

type
  /// <summary>
  ///   The screens over the globe and how they lead to one another (what each state of the geoscape pushes next).
  ///   The Make functions give a state that is not shown yet (the geoscape queues it as a popup); the Open procedures
  ///   push it. The object lives as long as the geoscape, which owns it
  /// </summary>
  IXcomGeoscapeScreens = interface
    ['{3C71D9A4-5E20-4B86-9F13-176000000203}']
    /// <summary>InterceptState (ABase nil: all the crafts; ATarget nil: the target is chosen afterwards)</summary>
    procedure OpenIntercept(ABase: TXcomBase; ATarget: TXcomTarget);
    procedure OpenSelectDestination(ACraft: TXcomCraft);
    procedure OpenConfirmDestination(ACraft: TXcomCraft; ATarget: TXcomTarget);
    /// <summary>MultipleTargetsState: takes the list (not the targets)</summary>
    procedure OpenMultipleTargets(const ATargets: TList<TXcomTarget>; ACraft: TXcomCraft);
    /// <summary>MultipleTargetsState::popupTarget: the screen of one target (for a craft that is being sent: the confirmation)</summary>
    procedure OpenTarget(ATarget: TXcomTarget; ACraft: TXcomCraft);
    procedure OpenTargetInfo(ATarget: TXcomTarget);
    function MakeUfoDetected(AUfo: TXcomUfo; ADetected, AHyperwave: Boolean): TXcomState;
    function MakeMissionDetected(ASite: TXcomMissionSite): TXcomState;
    /// <summary>GeoscapeCraftState: it owns the waypoint</summary>
    function MakeGeoscapeCraft(ACraft: TXcomCraft; AWaypoint: TXcomWaypoint): TXcomState;
    function MakeCraftPatrol(ACraft: TXcomCraft): TXcomState;
  end;

  /// <summary>
  ///   What a popup of the geoscape does to the geoscape that opened it. The popups never see the geoscape state:
  ///   the state gives this object, the tests give a fake
  /// </summary>
  IXcomGeoscapeControl = interface
    ['{3C71D9A4-5E20-4B86-9F13-176000000201}']
    /// <summary>GeoscapeState::timerReset: the speed of the time goes back to 5 seconds</summary>
    procedure TimerReset;
    /// <summary>The globe of the geoscape (not owned)</summary>
    function Globe: TXcomGlobe;
    /// <summary>GeoscapeState::popup: the state is shown at the next think and the time stops; it is owned by the game then</summary>
    procedure Popup(AState: TXcomState);
    /// <summary>The basescape of a base (BasescapeState with the globe)</summary>
    procedure OpenBase(ABase: TXcomBase);
    /// <summary>A screen of the basescape for a base (ManufactureState, ResearchState...), through the navigator</summary>
    procedure OpenBaseScreen(AScreen: TXcomBaseScreen; ABase: TXcomBase);
    /// <summary>PlaceLiftState: the screen where the access lift of a new base is placed (the base is not owned)</summary>
    procedure PlaceLift(ABase: TXcomBase; AFirst: Boolean);
    /// <summary>The way the screens over the globe lead to one another</summary>
    function Screens: IXcomGeoscapeScreens;
    /// <summary>The palette of the geoscape (the popups of messages take it, as the C++ passes _palette)</summary>
    function Palette: PXcomColors;
  end;

  /// <summary>
  ///   What the events of the simulation ask of the geoscape about the dogfights (the geoscape owns them). A second
  ///   interface of the control, so that the popups and their fakes do not change
  /// </summary>
  IXcomDogfightControl = interface
    ['{3C71D9A4-5E20-4B86-9F13-176000000204}']
    /// <summary>A craft reached a UFO it can engage: the window opens (the time stops and the globe goes to the craft)</summary>
    procedure StartDogfight(ACraft: TXcomCraft; AUfo: TXcomUfo);
    /// <summary>The craft cannot engage yet (AReason: STR_UNABLE_TO_ENGAGE_DEPTH or _AIRBORNE): the window waits minimized</summary>
    procedure DogfightImpossible(ACraft: TXcomCraft; const AReason: string);
    /// <summary>The dogfights that are open or waiting to open</summary>
    function DogfightCount: Integer;
    /// <summary>A UFO is about to be removed from the game: the dogfights with it are dropped</summary>
    procedure UfoRemoving(AUfo: TXcomUfo);
  end;

  /// <summary>
  ///   Receives the geoscape when it is created: the simulation that is given to a geoscape can implement this to
  ///   open popups on it
  /// </summary>
  IXcomGeoscapeAware = interface
    ['{3C71D9A4-5E20-4B86-9F13-176000000202}']
    procedure AttachGeoscape(const AControl: IXcomGeoscapeControl);
  end;

implementation

end.
