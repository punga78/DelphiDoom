{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - a data container that is turned into a WAD             }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Wad.Converter.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   A game whose data are not a WAD (Radix: RADIX.DAT) gives the engine a converter: the file
  ///   that it recognizes becomes the bytes of a WAD in memory, which w_wad.pas adds in its place
  /// </summary>
  IEngineWadConverter = interface
    ['{3B5E7A10-9C42-4D68-A1F3-6E08D2B94C57}']
    /// <summary>False when the file is not a container of this game (nothing is changed)</summary>
    function TryConvert(const AFileName: string; out AWad: TBytes): Boolean;
  end;

implementation

end.
