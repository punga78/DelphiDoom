{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the fake contrast of a wall                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Apply.FakeContrast;

interface

uses
  DelphiDoom.Udmf.Apply.Intf;

type
  /// <summary>Horizontal walls are a step darker, vertical ones a step lighter</summary>
  TUdmfFakeContrast = class(TInterfacedObject, IUdmfFakeContrast)
  public
    function Calculate(ANoFakeContrast: Boolean; AX1, AY1, AX2, AY2: Integer): Integer;
  end;

implementation

{ TUdmfFakeContrast }

function TUdmfFakeContrast.Calculate(ANoFakeContrast: Boolean; AX1, AY1, AX2, AY2: Integer): Integer;
begin
  if ANoFakeContrast then
    Result := 0
  else if AY1 = AY2 then
    Result := -1
  else if AX1 = AX2 then
    Result := 1
  else
    Result := 0;
end;

end.
