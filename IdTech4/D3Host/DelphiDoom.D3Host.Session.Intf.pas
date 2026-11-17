{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - contracts of the minimal session          }
{                                                                              }
{  Written for this repository (no code of Session.cpp is used): what the      }
{  minimal session asks of the game that loads a map and runs its frames.      }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.Session.Intf;

interface

type
  /// <summary>Loads what a map needs (the .map, the declarations, the scripts) and starts its main script</summary>
  ID3MapLoader = interface
    ['{3F8A21C6-D0B4-4E97-9A15-B7C60E4D8329}']
    procedure LoadMap(const AMapName: AnsiString);
    procedure UnloadMap;
  end;

  /// <summary>One frame of the game: called once for every frame of the session while a map is running</summary>
  ID3GameRunner = interface
    ['{A94D6B07-1E52-4C38-8F0D-2C73B5E9A614}']
    procedure RunFrame(const ATicNumber: Integer);
  end;

implementation

end.
