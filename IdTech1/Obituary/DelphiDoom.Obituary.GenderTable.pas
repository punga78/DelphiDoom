{******************************************************************************}
{                                                                              }
{  DelphiDoom: obituary library - the table of the genders                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Obituary.GenderTable;

interface

uses
  DelphiDoom.Obituary.Types, DelphiDoom.Obituary.Intf;

type
  /// <summary>
  ///   IObituaryGenders over the compiled table of TObituaryGenders, for the code that
  ///   receives the genders as a dependency (the formatter, the tests)
  /// </summary>
  TObituaryGenderTable = class(TInterfacedObject, IObituaryGenders)
  public
    /// <summary>The name of a gender</summary>
    function NameOf(const AGender: TObituaryGender): string;
    /// <summary>The pronouns of a gender</summary>
    function PronounsOf(const AGender: TObituaryGender): TObituaryPronouns;
    /// <summary>The gender that a text names, ogDefault if none</summary>
    function FindByName(const AName: string): TObituaryGender;
  end;

implementation

uses
  DelphiDoom.Obituary.Genders;

{ TObituaryGenderTable }

function TObituaryGenderTable.NameOf(const AGender: TObituaryGender): string;
begin
  Result := TObituaryGenders.NameOf(AGender);
end;

function TObituaryGenderTable.PronounsOf(const AGender: TObituaryGender): TObituaryPronouns;
begin
  Result := TObituaryGenders.PronounsOf(AGender);
end;

function TObituaryGenderTable.FindByName(const AName: string): TObituaryGender;
begin
  Result := TObituaryGenders.FindByName(AName);
end;

end.
