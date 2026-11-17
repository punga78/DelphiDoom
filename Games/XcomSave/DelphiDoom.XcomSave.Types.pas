{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - exceptions shared by the objects      }
{  Derived from OpenXcom (the OpenXcom Developers), available under the GNU    }
{  General Public License, version 3 or (at your option) any later version;    }
{  see Games\XcomFormats\README.md for the license of this unit                }
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
