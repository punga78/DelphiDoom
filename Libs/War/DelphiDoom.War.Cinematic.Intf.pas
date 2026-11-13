{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the animations of the game: contracts             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Cinematic.Intf;

interface

uses
  DelphiDoom.Cinematic.Flic.Scene.Intf, DelphiDoom.War.Level.Types, DelphiDoom.War.Cinematic.Types;

type
  /// <summary>The animations of the game: names, loops and sounds (cinematics.txt of the remake)</summary>
  IWarCinematicCatalog = interface
    ['{8A2D5F61-C3E7-4B09-9D14-6F0B7E3A5C82}']
    function Count: Integer;
    function Item(AIndex: Integer): TWarCinematicEntry;
    /// <summary>The animation called AName (not case sensitive); False if the game has none</summary>
    function TryFind(const AName: string; out AEntry: TWarCinematicEntry): Boolean;
  end;

  /// <summary>Opens the animations of the game as scenes that a viewer can skip, with their sound</summary>
  IWarCinematicDirector = interface
    ['{D4B71E92-0A58-4C36-8F2B-3E95C1A7D640}']
    /// <summary>
    ///   The scene of the animation AName for a player of APlayerRace; nil if the game has no such animation or
    ///   its file is not there (HMAP01-12, OMAP01-12, LOSE1 and WIN1 are not on the disk of the DOS game we have):
    ///   the caller goes on to the next scene
    /// </summary>
    function TryOpen(const AName: string; APlayerRace: TWarRace): IFlicScene;
  end;

implementation

end.
