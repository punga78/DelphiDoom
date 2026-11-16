{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the specials of the lines                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Apply.LineSpecialTranslator;

interface

uses
  DelphiDoom.Udmf.Apply.Intf;

type
  /// <summary>
  ///   Swaps the two ranges of specials: the normal ones (1..NormalAdd) move up to SpecialStart,
  ///   the ones of the UDMF range (NormalAdd..SpecialStart + NormalAdd) move down by NormalAdd.
  ///   The bits above the 1023 of the number are kept.
  /// </summary>
  TUdmfLineSpecialTranslator = class(TInterfacedObject, IUdmfLineSpecialTranslator)
  strict private
    FSpecialStart: Integer;
    FNormalAdd: Integer;
    class function InRange(ATest, ALimit1, ALimit2: Integer): Boolean; static;
  public
    constructor Create(ASpecialStart, ANormalAdd: Integer);
    function Translate(ASpecial: Integer): Integer;
  end;

implementation

const
  SPECIAL_NUMBER_MASK = 1023;

{ TUdmfLineSpecialTranslator }

constructor TUdmfLineSpecialTranslator.Create(ASpecialStart, ANormalAdd: Integer);
begin
  inherited Create;
  FSpecialStart := ASpecialStart;
  FNormalAdd := ANormalAdd;
end;

class function TUdmfLineSpecialTranslator.InRange(ATest, ALimit1, ALimit2: Integer): Boolean;
begin
  if ALimit1 < ALimit2 then
    Result := (ATest >= ALimit1) and (ATest <= ALimit2)
  else
    Result := (ATest >= ALimit2) and (ATest <= ALimit1);
end;

function TUdmfLineSpecialTranslator.Translate(ASpecial: Integer): Integer;
var
  LNumber, LKept: Integer;
begin
  LNumber := ASpecial and SPECIAL_NUMBER_MASK;
  LKept := ASpecial and not SPECIAL_NUMBER_MASK;
  if InRange(LNumber, 1, FNormalAdd) then
    Result := (LNumber + FSpecialStart) or LKept
  else if InRange(LNumber, FNormalAdd, FSpecialStart + FNormalAdd) then
    Result := (LNumber - FNormalAdd) or LKept
  else
    Result := ASpecial;
end;

end.
