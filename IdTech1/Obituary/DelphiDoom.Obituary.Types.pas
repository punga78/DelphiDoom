{******************************************************************************}
{                                                                              }
{  DelphiDoom: obituary library - genders, pronouns and the exception          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Obituary.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The gender of an actor, as the obituaries see it. The order is the one of the
  ///   gender_t of the engine (the ordinal is what DEHACKED and ACTORDEF store)
  /// </summary>
  TObituaryGender = (
    ogDefault,
    ogMale,
    ogFemale,
    ogPlural,
    ogTeam,
    ogNeutral
  );

  /// <summary>The words that the placeholders %g, %h, %p, %s and %r stand for</summary>
  TObituaryPronouns = record
    /// <summary>%g: he, she, it, they</summary>
    Subject: string;
    /// <summary>%h: him, her, it, them</summary>
    ObjectForm: string;
    /// <summary>%p: his, her, its, their</summary>
    Possessive: string;
    /// <summary>%s: his, hers, its, theirs</summary>
    Independent: string;
    /// <summary>%r: he's, she's, it's, they're</summary>
    Contraction: string;
  end;

  /// <summary>Raised when a gender is not one of the known ones</summary>
  EObituaryException = class(Exception);

const
  /// <summary>How many genders there are</summary>
  OBITUARY_GENDER_COUNT = Ord(High(TObituaryGender)) + 1;

  /// <summary>Message of the exception of an unknown gender (the argument is its ordinal)</summary>
  SObituaryUnknownGender = 'Obituary: unknown gender %d';

implementation

end.
