{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture definitions library - the sizes of the flats            }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TextureDefs.FlatSizes;

interface

type
  /// <summary>The flats are squares of 64 to 4096 pixels; the size is kept as a code</summary>
  TTextureDefsFlatSizes = class
  public
    /// <summary>The code of a side in pixels; what is not 128 .. 4096 is a 64x64 flat (the old R_FlatSizeFromSize)</summary>
    class function CodeFromSize(ASize: Integer): Integer; static;
    /// <summary>The side in pixels of a code; a code that does not exist gives 64</summary>
    class function SizeFromCode(ACode: Integer): Integer; static;
  end;

implementation

uses
  DelphiDoom.TextureDefs.Types;

{ TTextureDefsFlatSizes }

class function TTextureDefsFlatSizes.CodeFromSize(ASize: Integer): Integer;
begin
  case ASize of
    128: Result := FLAT_SIZE_128;
    256: Result := FLAT_SIZE_256;
    512: Result := FLAT_SIZE_512;
    1024: Result := FLAT_SIZE_1024;
    2048: Result := FLAT_SIZE_2048;
    4096: Result := FLAT_SIZE_4096;
  else
    Result := FLAT_SIZE_64;
  end;
end;

class function TTextureDefsFlatSizes.SizeFromCode(ACode: Integer): Integer;
begin
  case ACode of
    FLAT_SIZE_128: Result := 128;
    FLAT_SIZE_256: Result := 256;
    FLAT_SIZE_512: Result := 512;
    FLAT_SIZE_1024: Result := 1024;
    FLAT_SIZE_2048: Result := 2048;
    FLAT_SIZE_4096: Result := 4096;
  else
    Result := 64;
  end;
end;

end.
