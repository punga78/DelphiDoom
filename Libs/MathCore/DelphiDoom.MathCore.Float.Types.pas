{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - shared types of the vector and      }
{  matrix classes                                                              }
{                                                                              }
{  Types for the port of idVecX, idMatX, idLCP and friends (idlib\math) of     }
{  the Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a      }
{  ZeniMax Media company. Based on the Doom 3 GPL Source Code (id Software).   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Types;

interface

type
  /// <summary>A block of floats indexed like a C pointer (<c>p[i]</c>); never declared as a variable</summary>
  TIdSingleArray = array[0..(MaxInt div SizeOf(Single)) - 1] of Single;
  PIdSingleArray = ^TIdSingleArray;
  /// <summary>A block of integers indexed like a C pointer (row permutations, limits)</summary>
  TIdIntegerArray = array[0..(MaxInt div SizeOf(Integer)) - 1] of Integer;
  PIdIntegerArray = ^TIdIntegerArray;
  /// <summary>A block of booleans indexed like a C pointer</summary>
  TIdBooleanArray = array[0..(MaxInt div SizeOf(Boolean)) - 1] of Boolean;
  PIdBooleanArray = ^TIdBooleanArray;

implementation

end.
