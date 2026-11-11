{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - how a UFO finds its mission when the   }
{  saved game is loaded                                                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.MissionLookup.Intf;

interface

uses
  DelphiDoom.XcomSave.AlienMission;

type
  /// <summary>What Ufo::load asks of the SavedGame: the months passed and the mission with an id</summary>
  IXcomMissionLookup = interface
    ['{3C0B7F1A-5D52-4E0C-9A31-176000000012}']
    /// <summary>getMonthsPassed: -1 in a saved game that is only a battle</summary>
    function MonthsPassed: Integer;
    /// <summary>The mission with the id; nil if there is none (not owned by the caller)</summary>
    function FindMission(AId: Integer): TXcomAlienMission;
  end;

implementation

end.
