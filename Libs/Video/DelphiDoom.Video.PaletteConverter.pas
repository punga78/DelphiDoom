{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the palette converter                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.PaletteConverter;

interface

uses
  DelphiDoom.Video.Intf;

type
  TPaletteConverter = class(TInterfacedObject, IPaletteConverter)
  public
    const
      COLOR_COUNT = 256;
    procedure Convert(ASource: PByte; AGamma: PByte; ADest: PCardinal);
  end;

implementation

{ TPaletteConverter }

procedure TPaletteConverter.Convert(ASource: PByte; AGamma: PByte; ADest: PCardinal);
var
  LIndex: Integer;
  LRed: Byte;
  LGreen: Byte;
  LBlue: Byte;
begin
  for LIndex := 0 to COLOR_COUNT - 1 do
  begin
    LRed := (AGamma + ASource^)^;
    Inc(ASource);
    LGreen := (AGamma + ASource^)^;
    Inc(ASource);
    LBlue := (AGamma + ASource^)^;
    Inc(ASource);
    ADest^ := (Cardinal(LRed) shl 16) or (Cardinal(LGreen) shl 8) or Cardinal(LBlue);
    Inc(ADest);
  end;
end;

end.
