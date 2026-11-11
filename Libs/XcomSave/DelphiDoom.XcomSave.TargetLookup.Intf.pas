{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - how a craft finds the target it is     }
{  going to when the saved game is loaded                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.TargetLookup.Intf;

interface

uses
  DelphiDoom.XcomSave.Target;

type
  /// <summary>
  ///   What Craft::load asks of the SavedGame: the UFO, waypoint, mission site or alien base with an id. The
  ///   result is nil if there is none; it is not owned by the caller
  /// </summary>
  IXcomTargetLookup = interface
    ['{3C0B7F1A-5D52-4E0C-9A31-176000000011}']
    function FindUfo(AId: Integer): TXcomTarget;
    function FindWaypoint(AId: Integer): TXcomTarget;
    /// <summary>A mission site with the id whose deployment marker name is AMarkerName</summary>
    function FindMissionSite(AId: Integer; const AMarkerName: string): TXcomTarget;
    /// <summary>An alien base with the id whose deployment marker name is AMarkerName</summary>
    function FindAlienBase(AId: Integer; const AMarkerName: string): TXcomTarget;
  end;

implementation

end.
