{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - reduces a flat to 64x64                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.FlatShrinker;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   R_ShrinkFlatTo64x64 (r_flatinfo.pas): the 64x64 flat is the one that begins the lump, the
  ///   bigger ones give one pixel every Side / 64 in each direction
  /// </summary>
  /// <remarks>
  ///   Difference from the old code, which is a defect that was fixed: for the sizes from
  ///   128x128 up it wrote the result with a stride of 128 bytes (the variable was declared
  ///   as a 128x128 array), past the end of the 4096 bytes that its only caller gives it, and
  ///   the caller then read it with a stride of 64. Here the result has a stride of 64
  /// </remarks>
  TImagingFlatShrinker = class(TInterfacedObject, IImagingFlatShrinker)
  public
    function Shrink(const AFlat: TBytes; out AResult: TBytes): Boolean;
  end;

implementation

{ TImagingFlatShrinker }

function TImagingFlatShrinker.Shrink(const AFlat: TBytes; out AResult: TBytes): Boolean;
var
  LSide: Integer;
  LStep: Integer;
  LRow: Integer;
  LColumn: Integer;
begin
  Result := False;
  AResult := nil;

  if (Length(AFlat) = IMAGING_FLAT_PIXELS) or (Length(AFlat) = IMAGING_FLAT_SIDE * 128) then
  begin
    SetLength(AResult, IMAGING_FLAT_PIXELS);
    Move(AFlat[0], AResult[0], IMAGING_FLAT_PIXELS);
    Exit(True);
  end;

  LSide := 128;
  while LSide <= 4096 do
  begin
    if Length(AFlat) = LSide * LSide then
    begin
      LStep := LSide div IMAGING_FLAT_SIDE;
      SetLength(AResult, IMAGING_FLAT_PIXELS);
      for LRow := 0 to IMAGING_FLAT_SIDE - 1 do
        for LColumn := 0 to IMAGING_FLAT_SIDE - 1 do
          AResult[LRow * IMAGING_FLAT_SIDE + LColumn] := AFlat[LRow * LStep * LSide + LColumn * LStep];
      Exit(True);
    end;
    LSide := LSide * 2;
  end;
end;

end.
