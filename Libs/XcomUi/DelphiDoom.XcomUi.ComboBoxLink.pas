{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - what a list asks of its combo box       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.ComboBoxLink;

interface

type
  /// <summary>
  ///   The part of ComboBox that its TextList uses (the C++ gives the list a ComboBox *): choosing a row selects the
  ///   item and closes the list. The reference is not counted: the combo box owns the list
  /// </summary>
  IXcomComboBoxLink = interface
    ['{A41D7E92-30C6-4B85-9F17-D2E8C06B35A1}']
    procedure SetSelected(ASelected: Integer);
    procedure ToggleList;
  end;

implementation

end.
