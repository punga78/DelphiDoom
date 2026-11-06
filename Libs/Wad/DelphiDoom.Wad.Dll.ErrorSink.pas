{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - how the DLL turns exceptions into codes           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Dll.ErrorSink;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   No exception crosses the DLL boundary: the objects of the DLL give the exception that
  ///   stopped them to a sink, which keeps the message and gives back the code
  /// </summary>
  IWadDllErrorSink = interface
    ['{E0B4D7A9-3F26-4C58-91A0-5D8C2E6B7F13}']
    function Failed(AException: Exception): Integer;
  end;

implementation

end.
