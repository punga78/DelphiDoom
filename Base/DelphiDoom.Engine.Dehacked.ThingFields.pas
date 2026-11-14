{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the place of the fields of the things of one game      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Dehacked.ThingFields;

interface

uses
  DelphiDoom.Dehacked.Types,
  DelphiDoom.Dehacked.Intf;

type
  /// <summary>
  ///   The place where a game that runs on the profile of another one (Radix on Doom) puts the reader
  ///   of the fields that only its things have. The parser of DEHACKED is composed before the game
  ///   is: it receives the place, and the part of the composition of the game fills it later
  /// </summary>
  IEngineDehackedThingFields = interface(IDehackedExtraThingFields)
    ['{2B7E9A14-6C05-4D83-9F3A-E1D8470B5C26}']
    /// <summary>From now on the fields that the table of the game does not have are asked to AFields</summary>
    /// <remarks>Raises EArgumentNilException if AFields is nil</remarks>
    procedure Attach(const AFields: IDehackedExtraThingFields);
  end;

  /// <summary>Empty until a game attaches its reader: no field is known, as for the four games</summary>
  TEngineDehackedThingFields = class sealed(TInterfacedObject, IDehackedExtraThingFields,
    IEngineDehackedThingFields)
  strict private
    FFields: IDehackedExtraThingFields;
  public
    procedure Attach(const AFields: IDehackedExtraThingFields);
    function TryRead(const AThing: TDehackedReference; const AKey, AValue: string): Boolean;
  end;

implementation

uses
  System.SysUtils;

const
  SFieldsIsNil = 'TEngineDehackedThingFields: the reader of the fields is nil';

{ TEngineDehackedThingFields }

procedure TEngineDehackedThingFields.Attach(const AFields: IDehackedExtraThingFields);
begin
  if not Assigned(AFields) then
    raise EArgumentNilException.Create(SFieldsIsNil);
  FFields := AFields;
end;

function TEngineDehackedThingFields.TryRead(const AThing: TDehackedReference; const AKey,
  AValue: string): Boolean;
begin
  Result := Assigned(FFields) and FFields.TryRead(AThing, AKey, AValue);
end;

end.
