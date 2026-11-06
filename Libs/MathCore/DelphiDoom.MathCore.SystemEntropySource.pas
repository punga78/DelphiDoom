{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the entropy from the runtime generator      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.SystemEntropySource;

interface

uses
  DelphiDoom.MathCore.Intf;

type
  /// <summary>The generator of the runtime (Random), as the old I_Random used</summary>
  TSystemEntropySource = class(TInterfacedObject, IEntropySource)
  public
    /// <summary>ARandomize starts the generator from the clock (the old unit did it at start)</summary>
    constructor Create(const ARandomize: Boolean);
    function Next(ARange: Integer): Integer;
  end;

implementation

{ TSystemEntropySource }

constructor TSystemEntropySource.Create(const ARandomize: Boolean);
begin
  inherited Create;
  if ARandomize then
    Randomize;
end;

function TSystemEntropySource.Next(ARange: Integer): Integer;
begin
  Result := Random(ARange);
end;

end.
