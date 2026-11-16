{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - the place that knows the classes        }
{                                                                              }
{  Written for this library (idAAS::Alloc of AAS.cpp), Doom 3 GPL Source Code. }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Framework\IdLib); the repository as a whole is }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Factory;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Aas.AasFile, DelphiDoom.MapFile.Aas.Intf, DelphiDoom.Aas.D3.Types,
  DelphiDoom.Aas.D3.Intf;

type
  /// <summary>The only place of the Doom 3 navigation that names the concrete classes</summary>
  TAasNavigationFactory = class sealed
  public
    /// <summary>A navigator without a file: <c>Init</c> loads the map through the reader (idAAS::Alloc)</summary>
    class function CreateNavigator(const AReader: IAasFileReader; const ALog: IIdLibLog = nil;
      const AMaxCacheMemory: Integer = AAS_MAX_ROUTING_CACHE_MEMORY): IAasMapNavigator; static;
    /// <summary>
    ///   A navigator on a file that is already loaded. <c>AOwnsFile</c> says if the navigator frees it.
    ///   An EAasRoutingException says that the file is not fit for routing
    /// </summary>
    class function CreateNavigatorForFile(const AFile: TAasFile; const AOwnsFile: Boolean;
      const ALog: IIdLibLog = nil; const AMaxCacheMemory: Integer = AAS_MAX_ROUTING_CACHE_MEMORY): IAasMapNavigator; static;
  end;

implementation

uses
  DelphiDoom.Aas.D3.Navigator;

{ TAasNavigationFactory }

class function TAasNavigationFactory.CreateNavigator(const AReader: IAasFileReader; const ALog: IIdLibLog;
  const AMaxCacheMemory: Integer): IAasMapNavigator;
begin
  Result := TAasNavigator.Create(AReader, ALog, AMaxCacheMemory);
end;

class function TAasNavigationFactory.CreateNavigatorForFile(const AFile: TAasFile; const AOwnsFile: Boolean;
  const ALog: IIdLibLog; const AMaxCacheMemory: Integer): IAasMapNavigator;
var
  LNavigator: TAasNavigator;
begin
  LNavigator := TAasNavigator.Create(nil, ALog, AMaxCacheMemory);
  Result := LNavigator;
  LNavigator.Attach(AFile, AOwnsFile);
end;

end.
