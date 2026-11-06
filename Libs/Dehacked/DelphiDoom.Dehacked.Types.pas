{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - shared types                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Types;

interface

const
  /// <summary>The value of one in the fixed point numbers of the engine (16.16)</summary>
  DEHACKED_FRACUNIT = 1 shl 16;

type
  /// <summary>The blocks of a patch</summary>
  TDehackedSectionKind = (
    dskThing, dskFrame, dskText, dskPointer, dskSound, dskAmmo, dskWeapon, dskSprites,
    dskCheat, dskMisc, dskPars, dskStrings, dskCodePointers, dskMusic, dskSounds,
    dskSubmitNewStates);

  /// <summary>How the value of a field is read</summary>
  TDehackedFieldKind = (
    /// <summary>A number: Number holds it (the default of the field if the text is not one)</summary>
    dfkInteger,
    /// <summary>A number that has to be zero or more, or the field is dropped with a warning</summary>
    dfkPositive,
    /// <summary>The number of a state, or one of the keywords NEWFRAME/NEWSTATE, ORIGINALFRAME/ORIGINALSTATE</summary>
    dfkState,
    /// <summary>The next state of a frame: also NEW/ORIGINAL, and the name of a state is for the engine</summary>
    dfkNextState,
    /// <summary>Text or a number that the engine resolves by name: a sound, a mobj, a sprite ...</summary>
    dfkName,
    /// <summary>A number in fixed point, or a floating point one that is converted</summary>
    dfkFixed,
    /// <summary>A set of flags: a number or a list of names of the set of the field</summary>
    dfkFlags,
    /// <summary>The name of an action with its arguments, or the number of an action</summary>
    dfkAction,
    /// <summary>The number of a sprite frame, or BRIGHT and the number</summary>
    dfkFrameNumber,
    /// <summary>The level of a weapon (1..Tolerance); anything else is dropped with a warning</summary>
    dfkLevel,
    /// <summary>A field that the game does not have: warned about and dropped</summary>
    dfkUnsupported);

  /// <summary>How a reference to a state is written</summary>
  TDehackedStateRefKind = (
    /// <summary>A number, as it is: Number</summary>
    srPlain,
    /// <summary>NEWFRAME n: the state is counted from the end of the states that the game had</summary>
    srNew,
    /// <summary>ORIGINALFRAME n: a state that the game had</summary>
    srOriginal);

  /// <summary>A reference to a state as the field says it</summary>
  TDehackedStateRef = record
    Kind: TDehackedStateRefKind;
    Number: Integer;
  end;

  /// <summary>
  ///   How a section is introduced: by a number (Number >= 0) or by a name that only the
  ///   engine can resolve (Name)
  /// </summary>
  TDehackedReference = record
    Number: Integer;
    Name: string;
    /// <summary>The block creates a new element (NEWTHING, a new frame ...)</summary>
    IsNew: Boolean;
    /// <summary>The second word of a header (the class of a weapon of Hexen); empty if there is none</summary>
    Qualifier: string;
    QualifierNumber: Integer;
  end;

  /// <summary>A field of a section as the profile of a game declares it</summary>
  TDehackedFieldDef = record
    /// <summary>The name as it is written in the patch, in upper case</summary>
    Name: string;
    /// <summary>The index of the field that this one is an alias of; its own index if it is not one</summary>
    Canonical: Integer;
    Kind: TDehackedFieldKind;
    /// <summary>The name of the set of flags in the profile, for dfkFlags</summary>
    FlagSet: string;
    /// <summary>The numbers above it are not fixed point but already the value, for dfkFixed</summary>
    Tolerance: Integer;
    /// <summary>The value of Number if the text is not a number</summary>
    Default: Integer;
    /// <summary>The patch is MBF21 as soon as the field is there</summary>
    SetsMbf21: Boolean;
  end;

  /// <summary>One line "key = value" of a section, or one line of a list (PAR, FRAME ...)</summary>
  TDehackedEntry = record
    /// <summary>The line of the patch, counting from 1</summary>
    Line: Integer;
    /// <summary>The key as it was written, in upper case</summary>
    Key: string;
    /// <summary>The index of the field in the table of the section (aliases give the canonical one); -1 if there is none</summary>
    Field: Integer;
    /// <summary>The name of the canonical field; empty if there is none</summary>
    FieldName: string;
    /// <summary>The value, in upper case, without the quotes for the fields of the things</summary>
    Text: string;
    /// <summary>The value as a number, or the default of the field</summary>
    Number: Integer;
    /// <summary>The text is the number written in decimal, as is</summary>
    IsNumber: Boolean;
    /// <summary>dfkFixed: the value in fixed point</summary>
    Fixed: Integer;
    /// <summary>dfkFlags: the value sets the flags to Flags</summary>
    HasFlags: Boolean;
    Flags: Integer;
    /// <summary>dfkState and dfkNextState</summary>
    StateRef: TDehackedStateRef;
    /// <summary>dfkAction: the name of the action and what follows it (the arguments)</summary>
    ActionName: string;
    ActionArguments: string;
    /// <summary>dfkFrameNumber: written as BRIGHT n, Number is n</summary>
    Bright: Boolean;
    /// <summary>The field is one of MBF21 (see SetsMbf21 of the field)</summary>
    Mbf21: Boolean;
    /// <summary>[MUSIC] of Hexen: the value was written between parentheses (the music has no name)</summary>
    Cleared: Boolean;
    /// <summary>The numbers of a line of a list: PAR and FRAME in the code pointers</summary>
    Numbers: TArray<Integer>;
  end;

implementation

end.
