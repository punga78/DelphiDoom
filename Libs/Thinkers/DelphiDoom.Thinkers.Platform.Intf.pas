{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the contracts of the platforms               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Platform.Intf;

interface

uses
  DelphiDoom.Thinkers.Platform.Types;

type
  /// <summary>
  ///   What a platform asks to the game while it runs and when it is made. The sector is an opaque
  ///   handle (a pointer of the engine): the library never looks at it
  /// </summary>
  IPlatHost = interface
    ['{2D8E5A71-C406-4B93-A7F0-5E1B93C8D246}']
    /// <summary>Moves the floor of the sector (T_MovePlane with the floor); ADirection is 1 up and -1 down</summary>
    function MovePlane(ASector: Pointer; ASpeed, ADestination: Integer; ACrush: Boolean;
      ADirection: Integer): TPlatMoveResult;
    /// <summary>The height of the floor of the sector</summary>
    function GetFloorHeight(ASector: Pointer): Integer;
    /// <summary>Plays a sound of the platform at the sector</summary>
    procedure PlaySound(ASector: Pointer; ASound: TPlatSound);
    /// <summary>The tics since the level started</summary>
    function GetLevelTime: Integer;
    /// <summary>True in the engine versions after 1.15 (the old compatibility switch of the removal)</summary>
    function IsModernEngine: Boolean;
    /// <summary>Takes the platform away from the active ones and from the thinkers (the handle is the one given to Tick)</summary>
    procedure RemovePlat(APlat: Pointer);
  end;

  /// <summary>What is around a sector, which a platform needs to decide where it goes</summary>
  IPlatSurroundings = interface
    ['{91C6B3E2-0F5D-4A18-86D7-3AE4B1052C9F}']
    function LowestFloorSurrounding(ASector: Pointer): Integer;
    function HighestFloorSurrounding(ASector: Pointer): Integer;
    function NextHighestFloor(ASector: Pointer; AHeight: Integer): Integer;
    function GetFloorHeight(ASector: Pointer): Integer;
    function GetCeilingHeight(ASector: Pointer): Integer;
    procedure SetFloorPicture(ASector: Pointer; APicture: Integer);
    /// <summary>The sector stops having a type (it did damage, for instance)</summary>
    procedure ClearSpecial(ASector: Pointer);
  end;

  /// <summary>The classic platforms (p_plats of Doom, Heretic and Strife)</summary>
  IPlatMachine = interface
    ['{6B0F94D8-35A1-47E3-9C2B-D8E61A7F5304}']
    /// <summary>
    ///   Sets the state of a new platform of a kind: speed, positions, wait, first direction (the
    ///   fields that the kind does not use keep what they had). AAmount is the height of a
    ///   raise-and-change in units, APictureOfLine the floor picture that the platform takes. The
    ///   game has already put the tag and the crush flag in AState (they are not changed)
    /// </summary>
    procedure Configure(ASector: Pointer; AKind: TPlatKind; APictureOfLine, AAmount: Integer;
      var AState: TPlatState);
    /// <summary>One tic of a platform (T_PlatRaise); APlat is what the host needs to remove it</summary>
    procedure Tick(APlat, ASector: Pointer; AKind: TPlatKind; var AState: TPlatState);
    /// <summary>The status that a platform in stasis takes when it is woken up (P_ActivateInStasis)</summary>
    function WakeUpStatus(AKind: TPlatKind; AOldStatus: TPlatStatus): TPlatStatus;
    /// <summary>Puts a platform in stasis, keeping what it was doing (EV_StopPlat)</summary>
    procedure Pause(var AState: TPlatState);
    /// <summary>True if a kind is the toggle that stops at both ends</summary>
    function IsToggle(AKind: TPlatKind): Boolean;
  end;

  /// <summary>The scripted platforms (udmf_plats, used by Hexen and by the UDMF maps of the other games)</summary>
  IUdmfPlatMachine = interface
    ['{E4A7D250-81B3-4F6C-B59E-0C37F2D8A961}']
    /// <summary>
    ///   Sets the state of a new scripted platform from the arguments of the special: ATag is
    ///   argument 0, ASpeedArgument (1) is in eighths of a unit per tic, AWaitArgument (2) in tics
    ///   and AAmountArgument (3) a distance (units of 8 or a lip, as the kind says). It uses one
    ///   random number for the perpetual kinds
    /// </summary>
    procedure Configure(ASector: Pointer; AKind: TUdmfPlatKind; ATag, ASpeedArgument,
      AWaitArgument, AAmountArgument: Integer; var AState: TPlatState);
    /// <summary>One tic of a scripted platform (TH_PlatRaise)</summary>
    procedure Tick(APlat, ASector: Pointer; AKind: TUdmfPlatKind; var AState: TPlatState);
    /// <summary>Plays the sound with which a scripted platform starts (after it was added to the active ones)</summary>
    procedure AnnounceStart(ASector: Pointer);
  end;

implementation

end.
