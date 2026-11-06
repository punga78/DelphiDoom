{******************************************************************************}
{                                                                              }
{  DelphiDoom: the palettes that #CREATEPALETTE asks for                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Scanner.PaletteGenerator;

interface

uses
  DelphiDoom.Scanner.Preprocessor.Intf;

type
  TEnginePaletteGenerator = class(TInterfacedObject, IPaletteGenerator)
  public
    procedure Generate(const AArgument: string);
  end;

implementation

uses
  v_palettes;

{ TEnginePaletteGenerator }

procedure TEnginePaletteGenerator.Generate(const AArgument: string);
begin
  V_AutoGeneratePalettes(AArgument);
end;

end.
