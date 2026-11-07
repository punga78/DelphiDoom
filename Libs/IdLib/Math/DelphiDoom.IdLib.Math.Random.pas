{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib math - TIdRandom and TIdRandom2, the generators of idLib  }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\math\Random.h.           }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Math.Random;

{$Q-}
{$R-}

interface

const
  /// <summary>idRandom::MAX_RAND</summary>
  ID_MAX_RAND = $7FFF;

type
  /// <summary>
  ///   idRandom: a linear congruential generator (seed := 69069 * seed + 1) with the state in the
  ///   record, so every owner has its own sequence. Not the generator of the Doom tables
  ///   (that is TGameRandom of Libs\MathCore).
  /// </summary>
  TIdRandom = record
  private
    FSeed: Integer;
  public
    class function Create(const ASeed: Integer = 0): TIdRandom; static;
    procedure SetSeed(const ASeed: Integer);
    function GetSeed: Integer;
    /// <summary>A random integer in [0, MAX_RAND]</summary>
    function RandomInt: Integer; overload;
    /// <summary>A random integer in [0, max[ (0 if max is 0)</summary>
    function RandomInt(const AMax: Integer): Integer; overload;
    /// <summary>A random number in [0, 1]</summary>
    function RandomFloat: Single;
    /// <summary>A random number in [-1, 1]</summary>
    function CRandomFloat: Single;
  end;

  /// <summary>
  ///   idRandom2: the generator of the Numerical Recipes (seed := 1664525 * seed + 1013904223); the
  ///   seed is the 32-bit "unsigned long" of Win32, so the sequence is the same on every platform
  /// </summary>
  TIdRandom2 = record
  private
    FSeed: Cardinal;
  public
    class function Create(const ASeed: Cardinal = 0): TIdRandom2; static;
    procedure SetSeed(const ASeed: Cardinal);
    function GetSeed: Cardinal;
    function RandomInt: Integer; overload;
    /// <summary>A random integer in [0, max]</summary>
    function RandomInt(const AMax: Integer): Integer; overload;
    function RandomFloat: Single;
    function CRandomFloat: Single;
  end;

implementation

uses
  System.Math, DelphiDoom.IdLib.Math.Math;

const
  IEEE_ONE = $3F800000;
  IEEE_MASK = $007FFFFF;

{ TIdRandom }

class function TIdRandom.Create(const ASeed: Integer): TIdRandom;
begin
  Result.FSeed := ASeed;
end;

procedure TIdRandom.SetSeed(const ASeed: Integer);
begin
  FSeed := ASeed;
end;

function TIdRandom.GetSeed: Integer;
begin
  Result := FSeed;
end;

function TIdRandom.RandomInt: Integer;
begin
  FSeed := 69069 * FSeed + 1;
  Result := FSeed and ID_MAX_RAND;
end;

function TIdRandom.RandomInt(const AMax: Integer): Integer;
begin
  if AMax = 0 then
    Exit(0);
  Result := RandomInt mod AMax;
end;

function TIdRandom.RandomFloat: Single;
begin
  Result := RandomInt / Single(ID_MAX_RAND + 1);
end;

function TIdRandom.CRandomFloat: Single;
begin
  Result := 2.0 * (RandomFloat - 0.5);
end;

{ TIdRandom2 }

class function TIdRandom2.Create(const ASeed: Cardinal): TIdRandom2;
begin
  Result.FSeed := ASeed;
end;

procedure TIdRandom2.SetSeed(const ASeed: Cardinal);
begin
  FSeed := ASeed;
end;

function TIdRandom2.GetSeed: Cardinal;
begin
  Result := FSeed;
end;

function TIdRandom2.RandomInt: Integer;
begin
  FSeed := 1664525 * FSeed + 1013904223;
  Result := Integer(FSeed) and ID_MAX_RAND;
end;

function TIdRandom2.RandomInt(const AMax: Integer): Integer;
begin
  if AMax = 0 then
    Exit(0);
  Result := TIdMath.Sar(RandomInt, 16 - TIdMath.BitsForInteger(AMax)) mod AMax;
end;

function TIdRandom2.RandomFloat: Single;
var
  LBits: Cardinal;
begin
  FSeed := 1664525 * FSeed + 1013904223;
  LBits := IEEE_ONE or (FSeed and IEEE_MASK);
  Result := PSingle(@LBits)^ - 1.0;
end;

function TIdRandom2.CRandomFloat: Single;
var
  LBits: Cardinal;
begin
  FSeed := 1664525 * FSeed + 1013904223;
  LBits := IEEE_ONE or (FSeed and IEEE_MASK);
  Result := 2.0 * PSingle(@LBits)^ - 3.0;
end;

end.
