{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the random bytes of the melt for the Imaging library   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Imaging.Random;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Intf, DelphiDoom.MathCore.Intf;

type
  /// <summary>
  ///   Answers the Imaging library with the "unpredictable" numbers of the generator of the
  ///   game (the I_Random of m_rnd.pas, the one that f_wipe.pas asked): they do not move the
  ///   indexes that demos and net games depend on
  /// </summary>
  TEngineImagingRandom = class sealed(TInterfacedObject, IImagingRandom)
  strict private
    FRandom: IGameRandom;
  public
    constructor Create(const ARandom: IGameRandom);
    function NextByte: Byte;
  end;

implementation

{ TEngineImagingRandom }

constructor TEngineImagingRandom.Create(const ARandom: IGameRandom);
begin
  inherited Create;
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  FRandom := ARandom;
end;

function TEngineImagingRandom.NextByte: Byte;
begin
  Result := Byte(FRandom.NextUnpredictable and $FF);
end;

end.
