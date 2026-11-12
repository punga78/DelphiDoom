{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the settings the program adds to the ones  }
{  of OpenXcom (issue 183): the advanced options list them after its own        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.ExtraOptions.Intf;

interface

type
  /// <summary>
  ///   Yes/no settings that OpenXcom does not have. The host gives them (nil or none: the screens of the options
  ///   are the ones of OpenXcom, pixel for pixel); the list of the advanced options shows them in a section of
  ///   their own after the last one. The texts are given as they are shown: the language files of OpenXcom do not
  ///   know these settings. A setting takes effect as the others do, when the options are confirmed
  /// </summary>
  IXcomExtraOptions = interface
    ['{7F3B1C90-5A2E-4D67-8B14-183000000010}']
    /// <summary>The title of the section</summary>
    function Heading: string;
    function Count: Integer;
    /// <summary>The text of the row</summary>
    function Title(AIndex: Integer): string;
    /// <summary>The text of the tooltip</summary>
    function Description(AIndex: Integer): string;
    function IsOn(AIndex: Integer): Boolean;
    procedure SetOn(AIndex: Integer; AValue: Boolean);
  end;

implementation

end.
