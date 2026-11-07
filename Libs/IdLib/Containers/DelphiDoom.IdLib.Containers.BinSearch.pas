{******************************************************************************}
{                                                                              }
{  DelphiDoom: idLib containers - the binary search templates                  }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idlib\containers\BinSearch.h.  }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.IdLib.Containers.BinSearch;

interface

uses
  System.Generics.Defaults;

type
  /// <summary>
  ///   idBinSearch_Less, _LessEqual, _Greater and _GreaterEqual: binary searches on an array
  ///   ordered in increasing order. The original compares with the operators of the element type;
  ///   a generic cannot, so the order comes from an <c>IComparer&lt;T&gt;</c> (the default one if
  ///   none is given). <c>ASize</c> is the number of elements to search in (at most the length of
  ///   the array); like the original, an empty range gives 0 (the element 0 is not read).
  /// </summary>
  TIdBinSearch<T> = class
  private
    class function Resolve(const AComparer: IComparer<T>): IComparer<T>; static;
  public
    /// <summary>The index of the last element which is smaller than the value (0 if there is none)</summary>
    class function Less(const AArray: array of T; const ASize: Integer; const AValue: T;
      const AComparer: IComparer<T> = nil): Integer; static;
    /// <summary>The index of the last element which is smaller than or equal to the value</summary>
    class function LessEqual(const AArray: array of T; const ASize: Integer; const AValue: T;
      const AComparer: IComparer<T> = nil): Integer; static;
    /// <summary>The index of the first element which is greater than the value (ASize if there is none)</summary>
    class function Greater(const AArray: array of T; const ASize: Integer; const AValue: T;
      const AComparer: IComparer<T> = nil): Integer; static;
    /// <summary>The index of the first element which is greater than or equal to the value</summary>
    class function GreaterEqual(const AArray: array of T; const ASize: Integer; const AValue: T;
      const AComparer: IComparer<T> = nil): Integer; static;
  end;

implementation

{ TIdBinSearch<T> }

class function TIdBinSearch<T>.Resolve(const AComparer: IComparer<T>): IComparer<T>;
begin
  if Assigned(AComparer) then
    Result := AComparer
  else
    Result := TComparer<T>.Default;
end;

class function TIdBinSearch<T>.Less(const AArray: array of T; const ASize: Integer; const AValue: T;
  const AComparer: IComparer<T>): Integer;
var
  LComparer: IComparer<T>;
  LLength, LMid, LOffset: Integer;
begin
  LComparer := Resolve(AComparer);
  LLength := ASize;
  LMid := LLength;
  LOffset := 0;
  while LMid > 0 do
  begin
    LMid := LLength shr 1;
    if LComparer.Compare(AArray[LOffset + LMid], AValue) < 0 then
      Inc(LOffset, LMid);
    Dec(LLength, LMid);
  end;
  Result := LOffset;
end;

class function TIdBinSearch<T>.LessEqual(const AArray: array of T; const ASize: Integer; const AValue: T;
  const AComparer: IComparer<T>): Integer;
var
  LComparer: IComparer<T>;
  LLength, LMid, LOffset: Integer;
begin
  LComparer := Resolve(AComparer);
  LLength := ASize;
  LMid := LLength;
  LOffset := 0;
  while LMid > 0 do
  begin
    LMid := LLength shr 1;
    if LComparer.Compare(AArray[LOffset + LMid], AValue) <= 0 then
      Inc(LOffset, LMid);
    Dec(LLength, LMid);
  end;
  Result := LOffset;
end;

class function TIdBinSearch<T>.Greater(const AArray: array of T; const ASize: Integer; const AValue: T;
  const AComparer: IComparer<T>): Integer;
var
  LComparer: IComparer<T>;
  LLength, LMid, LOffset, LResult: Integer;
begin
  LComparer := Resolve(AComparer);
  LLength := ASize;
  LMid := LLength;
  LOffset := 0;
  LResult := 0;
  while LMid > 0 do
  begin
    LMid := LLength shr 1;
    if LComparer.Compare(AArray[LOffset + LMid], AValue) > 0 then
      LResult := 0
    else
    begin
      Inc(LOffset, LMid);
      LResult := 1;
    end;
    Dec(LLength, LMid);
  end;
  Result := LOffset + LResult;
end;

class function TIdBinSearch<T>.GreaterEqual(const AArray: array of T; const ASize: Integer; const AValue: T;
  const AComparer: IComparer<T>): Integer;
var
  LComparer: IComparer<T>;
  LLength, LMid, LOffset, LResult: Integer;
begin
  LComparer := Resolve(AComparer);
  LLength := ASize;
  LMid := LLength;
  LOffset := 0;
  LResult := 0;
  while LMid > 0 do
  begin
    LMid := LLength shr 1;
    if LComparer.Compare(AArray[LOffset + LMid], AValue) >= 0 then
      LResult := 0
    else
    begin
      Inc(LOffset, LMid);
      LResult := 1;
    end;
    Dec(LLength, LMid);
  end;
  Result := LOffset + LResult;
end;

end.
