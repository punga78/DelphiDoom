{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the options of the search of the IWADs                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Iwad.Options;

interface

uses
  DelphiDoom.Iwad.Intf;

type
  /// <summary>
  ///   The only class that reads the options searchdoomwaddir, searchdoomwadpath,
  ///   searchsteampaths and additionalwadpaths of the configuration file. It reads them every
  ///   time: the file is loaded after the composition root has run
  /// </summary>
  TEngineIwadOptions = class(TInterfacedObject, IIwadOptions)
  public
    function GetSearchWadDirectory: Boolean;
    function GetSearchWadPath: Boolean;
    function GetSearchSteamPaths: Boolean;
    function GetAdditionalPaths: string;
  end;

implementation

uses
  d_main;

{ TEngineIwadOptions }

function TEngineIwadOptions.GetSearchWadDirectory: Boolean;
begin
  Result := searchdoomwaddir;
end;

function TEngineIwadOptions.GetSearchWadPath: Boolean;
begin
  Result := searchdoomwadpath;
end;

function TEngineIwadOptions.GetSearchSteamPaths: Boolean;
begin
  Result := searchsteampaths;
end;

function TEngineIwadOptions.GetAdditionalPaths: string;
begin
  Result := additionalwadpaths;
end;

end.
