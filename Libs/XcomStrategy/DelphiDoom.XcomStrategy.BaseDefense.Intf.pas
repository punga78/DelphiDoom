{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the attack of a UFO on a base as the     }
{  screen handles it (BaseDefenseState and GeoscapeState::handleBaseDefense)    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.BaseDefense.Intf;

interface

uses
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Ufo;

type
  /// <summary>
  ///   A second interface of the listener of the simulation: a listener that has a screen takes over the attack of a
  ///   UFO on a base (the defenses that fire, the battle in the base, the base that is destroyed). A listener without
  ///   it gets IXcomGeoscapeEvents.BaseAttacked and the UFO is destroyed at once
  /// </summary>
  IXcomBaseDefenseEvents = interface
    ['{6F2B4C1D-9A3E-4B75-8D10-176000000103}']
    /// <summary>
    ///   A UFO on its assault run reached the base (its destination is already cleared). True: the defenses of the
    ///   base fire first (BaseDefenseState is shown) and the time goes on with the other UFOs; False: the attack was
    ///   handled at once (handleBaseDefense: the UFO is destroyed, the battle or the loss of the base follows) and the
    ///   step of the time ends, as the return of the C++
    /// </summary>
    function BaseDefense(const ABase: TXcomBase; const AUfo: TXcomUfo): Boolean;
  end;

implementation

end.
