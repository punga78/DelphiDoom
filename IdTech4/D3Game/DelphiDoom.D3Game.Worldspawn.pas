{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idWorldspawn (reduced)                    }
{                                                                              }
{  Reduced port of Doom 3 (id Software): game\Misc.cpp / WorldSpawn.cpp        }
{  (idWorldspawn, the entity 0 of a map file, in the world entity number). It  }
{  is an entity and nothing else: it does not start the main script of the     }
{  map, set the gravity or the sky (the caller starts <c>main</c>).            }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.Worldspawn;

interface

uses
  DelphiDoom.D3Game.Entity;

type
  /// <summary>idWorldspawn without its spawn function (see the unit)</summary>
  TD3Worldspawn = class(TD3Entity)
  end;

implementation

end.
