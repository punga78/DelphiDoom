{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the rows of the settings the program adds  }
{  to the ones of OpenXcom that are not a yes/no (issue 184)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.ExtraChoiceOptions.Intf;

interface

type
  /// <summary>How a row of IXcomExtraOptions answers a click</summary>
  TXcomExtraKind = (
    /// <summary>A yes/no: the click toggles it and the value is the YES/NO column (what IXcomExtraOptions alone does)</summary>
    ekToggle,
    /// <summary>One of a list or a number: the click goes to the next one, the right click to the previous one; the value is part of the title</summary>
    ekChoice,
    /// <summary>A line of text: the click does nothing</summary>
    ekInfo);

  /// <summary>
  ///   The second interface of an IXcomExtraOptions that has rows that are not a yes/no. A host that does not give
  ///   it (a plain IXcomExtraOptions) has only toggles. The title of a choice is read again after every step
  /// </summary>
  IXcomExtraChoiceOptions = interface
    ['{7F3B1C90-5A2E-4D67-8B14-183000000020}']
    function Kind(AIndex: Integer): TXcomExtraKind;
    /// <param name="ADirection">+1 for the left button, -1 for the right one</param>
    procedure Step(AIndex, ADirection: Integer);
    /// <summary>The options were cancelled: what was changed and not confirmed is forgotten</summary>
    procedure Discard;
  end;

implementation

end.
