{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - what a scrolling control asks a list    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.ScrollableList;

interface

type
  /// <summary>
  ///   The part of TextList that ArrowButton and ScrollBar use (the C++ gives them a TextList *): a small contract
  ///   that breaks the dependency cycle between the list and its controls. The reference is not counted: the list
  ///   owns its controls, so the controls never outlive it
  /// </summary>
  IXcomScrollableList = interface
    ['{5E3A9C21-7B04-4D68-A1F2-3C9D80E46B57}']
    function GetRows: Integer;
    function GetVisibleRows: Integer;
    function GetScroll: Integer;
    procedure ScrollTo(AScroll: Integer);
    procedure ScrollUp(AToMax: Boolean; AByWheel: Boolean = False);
    procedure ScrollDown(AToMax: Boolean; AByWheel: Boolean = False);
    /// <summary>The list belongs to a combo box (the track of the scroll bar and the selector change shade)</summary>
    function HasComboBox: Boolean;
  end;

implementation

end.
