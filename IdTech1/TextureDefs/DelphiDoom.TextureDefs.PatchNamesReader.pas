{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture definitions library - the lump PNAMES                   }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TextureDefs.PatchNamesReader;

interface

uses
  System.SysUtils, DelphiDoom.TextureDefs.Intf;

type
  /// <summary>
  ///   PNAMES is a 32 bit count and then that many names of 8 bytes. A name ends at the first
  ///   byte that is 0; it is made upper case and the spaces around it are cut, as the lookup of
  ///   the engine wants it. A count that does not fit the lump is an error (the old code read
  ///   what came after the lump)
  /// </summary>
  TTextureDefsPatchNamesReader = class(TInterfacedObject, ITextureDefsPatchNamesReader)
  public
    function Read(const ABytes: TBytes): TArray<string>;
  end;

implementation

uses
  DelphiDoom.TextureDefs.Names, DelphiDoom.TextureDefs.Types;

const
  SPatchNamesTooShort = 'PNAMES: the lump is too short for the count of names';
  SPatchNamesBadCount = 'PNAMES: the count of names does not fit the lump';

{ TTextureDefsPatchNamesReader }

function TTextureDefsPatchNamesReader.Read(const ABytes: TBytes): TArray<string>;
var
  LCount: Integer;
  LIndex: Integer;
begin
  if Length(ABytes) < SizeOf(Integer) then
    raise ETextureDefsException.Create(TTextureDefsError.TruncatedLump, SPatchNamesTooShort);
  Move(ABytes[0], LCount, SizeOf(Integer));
  if (LCount < 0) or (Int64(LCount) * TEXTUREDEFS_NAME_LENGTH > Length(ABytes) - SizeOf(Integer)) then
    raise ETextureDefsException.Create(TTextureDefsError.BadDirectory, SPatchNamesBadCount);
  SetLength(Result, LCount);
  for LIndex := 0 to LCount - 1 do
    Result[LIndex] := TTextureDefsNames.Trim(
      TTextureDefsNames.Decode(ABytes, SizeOf(Integer) + LIndex * TEXTUREDEFS_NAME_LENGTH));
end;

end.
