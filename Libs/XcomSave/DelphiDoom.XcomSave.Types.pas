{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - exceptions shared by the objects      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   A saved game object met a situation that the C++ leaves undefined (a null pointer, an infinite loop, a
  ///   value out of range): here it is an error
  /// </summary>
  EXcomSaveException = class(Exception);

implementation

end.
