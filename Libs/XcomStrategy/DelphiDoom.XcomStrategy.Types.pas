{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - types shared by the strategic logic     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The strategic logic met a situation that the C++ leaves undefined (a missing rule, a zone that does not
  ///   exist): here it is an error with the message of the C++ when there is one
  /// </summary>
  EXcomStrategyException = class(Exception);

  /// <summary>productionProgress_e: what a step of a production ended with</summary>
  TXcomProductionProgress = (ppNotComplete, ppComplete, ppNotEnoughMoney, ppNotEnoughMaterials);

implementation

end.
