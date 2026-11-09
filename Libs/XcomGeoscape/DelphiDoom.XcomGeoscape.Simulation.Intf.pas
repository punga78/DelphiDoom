{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - what the clock of the geoscape drives    }
{  (the time5Seconds ... time1Month of GeoscapeState)                           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.Simulation.Intf;

interface

type
  /// <summary>
  ///   The strategic game that runs while the time of the geoscape goes on: UFOs and crafts that move, the
  ///   detection, the alien missions, the work of the bases and the end of the month. It is separate from the screen
  ///   (GeoscapeState) so that it can be tested without one. The screen calls these in the order of the C++: when a
  ///   day ends it calls the five of the day, the hour, the 30 minutes, the 10 minutes and the 5 seconds
  /// </summary>
  IXcomGeoscapeSimulation = interface
    ['{91F3A0C6-2B58-4E7D-83A4-C5D06E1B7F29}']
    procedure Time5Seconds;
    procedure Time10Minutes;
    procedure Time30Minutes;
    procedure Time1Hour;
    procedure Time1Day;
    procedure Time1Month;
    /// <summary>
    ///   What GeoscapeState::init does when the first base gets its name, after the month is added to the saved
    ///   game: determineAlienMissions and the maintenance that the first month costs
    /// </summary>
    procedure StartFirstMonth;
  end;

implementation

end.
