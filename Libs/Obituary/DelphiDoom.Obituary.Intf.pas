{******************************************************************************}
{                                                                              }
{  DelphiDoom: obituary library - the contract                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Obituary.Intf;

interface

uses
  DelphiDoom.Obituary.Types;

type
  /// <summary>The table of the genders: their names and their pronouns</summary>
  IObituaryGenders = interface
    ['{6B1D3C52-9E0A-4F7B-A4D8-2C5E71B90A13}']
    /// <summary>The name of a gender ("Male"); raises EObituaryException if it is unknown</summary>
    function NameOf(const AGender: TObituaryGender): string;
    /// <summary>The pronouns of a gender; raises EObituaryException if it is unknown</summary>
    function PronounsOf(const AGender: TObituaryGender): TObituaryPronouns;
    /// <summary>
    ///   The gender written as a number (0..5, also $2, 0x2, #2), as its name (any case) or
    ///   as GENDER_ and its name; ogDefault for anything else
    /// </summary>
    function FindByName(const AName: string): TObituaryGender;
  end;

  /// <summary>Writes the message of a death from its model</summary>
  IObituaryFormatter = interface
    ['{0F8A4E67-3D12-4B95-8C70-E6A1D4529B38}']
    /// <summary>
    ///   Replaces %o (victim), %k (killer) and the pronouns %g (of the victim), %h, %p, %s
    ///   and %r (of the killer), in any case, in one pass: a name that contains a placeholder
    ///   is written as it is. What is not a placeholder (a lone %, %x) stays in the text
    /// </summary>
    function Compose(const AModel, AVictimName, AKillerName: string;
      const AVictimGender, AKillerGender: TObituaryGender): string;
  end;

implementation

end.
