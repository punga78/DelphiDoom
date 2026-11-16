{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, a cvar (cvar_t)            }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): q_shared.h.     }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.CVar;

interface

type
  /// <summary>
  ///   cvar_t: the data of a console variable. The cvar system owns and changes it; the properties are
  ///   writable only because the system is another unit
  /// </summary>
  TQ3CVar = class
  strict private
    FName: AnsiString;
    FStringValue: AnsiString;
    FResetString: AnsiString;
    FLatchedString: AnsiString;
    FHasLatched: Boolean;
    FFlags: Integer;
    FModified: Boolean;
    FModificationCount: Integer;
    FValue: Single;
    FIntegerValue: Integer;
    FRemoved: Boolean;
  public
    property Name: AnsiString read FName write FName;
    /// <summary>cvar_t.string</summary>
    property StringValue: AnsiString read FStringValue write FStringValue;
    property ResetString: AnsiString read FResetString write FResetString;
    /// <summary>latchedString; valid only when <c>HasLatched</c> (the original has a nil pointer)</summary>
    property LatchedString: AnsiString read FLatchedString write FLatchedString;
    property HasLatched: Boolean read FHasLatched write FHasLatched;
    property Flags: Integer read FFlags write FFlags;
    property Modified: Boolean read FModified write FModified;
    property ModificationCount: Integer read FModificationCount write FModificationCount;
    /// <summary>atof of the string</summary>
    property Value: Single read FValue write FValue;
    /// <summary>atoi of the string</summary>
    property IntegerValue: Integer read FIntegerValue write FIntegerValue;
    /// <summary>The slot was emptied by cvar_restart (a user created variable thrown out)</summary>
    property Removed: Boolean read FRemoved write FRemoved;
  end;

implementation

end.
