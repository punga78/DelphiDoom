{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - a block of a patch                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Section;

interface

uses
  System.Generics.Collections, DelphiDoom.Dehacked.Types;

type
  /// <summary>
  ///   A block of a patch: Thing, Frame, Weapon ... with its fields. It is data: what the
  ///   fields do to the tables of the engine is for the engine
  /// </summary>
  TDehackedSection = class
  private
    FKind: TDehackedSectionKind;
    FLine: Integer;
    FKeyword: string;
    FTitle: string;
    FReference: TDehackedReference;
    FEntries: TList<TDehackedEntry>;
    FExtraFlags: Integer;
    FOldText: string;
    FNewText: string;
    FOldLength: Integer;
    FNewLength: Integer;
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TDehackedEntry;
  public
    constructor Create(AKind: TDehackedSectionKind; ALine: Integer; const AKeyword, ATitle: string);
    destructor Destroy; override;
    procedure AddEntry(const AEntry: TDehackedEntry);
    property Kind: TDehackedSectionKind read FKind;
    /// <summary>The line of the header, counting from 1</summary>
    property Line: Integer read FLine;
    /// <summary>The word that opened the block (THING, [STRINGS] ...)</summary>
    property Keyword: string read FKeyword;
    /// <summary>What follows the word on the line of the header, in upper case</summary>
    property Title: string read FTitle;
    /// <summary>The element that the header names</summary>
    property Reference: TDehackedReference read FReference write FReference;
    property Count: Integer read GetCount;
    property Entries[AIndex: Integer]: TDehackedEntry read GetEntry; default;
    /// <summary>
    ///   Things: the flags of the high bits that the fields BITS said (see IDehackedFlagSet): bit
    ///   0 is the 31st flag (translucent), bit 1 the 30th (friend), bit 2 the 29th (bouncy), bit 3
    ///   the 28th (touchy)
    /// </summary>
    property ExtraFlags: Integer read FExtraFlags write FExtraFlags;
    /// <summary>Text: the string to replace and the new one, and their lengths as the block gave them</summary>
    property OldText: string read FOldText write FOldText;
    property NewText: string read FNewText write FNewText;
    property OldLength: Integer read FOldLength write FOldLength;
    property NewLength: Integer read FNewLength write FNewLength;
  end;

implementation

{ TDehackedSection }

constructor TDehackedSection.Create(AKind: TDehackedSectionKind; ALine: Integer;
  const AKeyword, ATitle: string);
begin
  inherited Create;
  FKind := AKind;
  FLine := ALine;
  FKeyword := AKeyword;
  FTitle := ATitle;
  FReference.Number := -1;
  FEntries := TList<TDehackedEntry>.Create;
end;

destructor TDehackedSection.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

procedure TDehackedSection.AddEntry(const AEntry: TDehackedEntry);
begin
  FEntries.Add(AEntry);
end;

function TDehackedSection.GetCount: Integer;
begin
  Result := FEntries.Count;
end;

function TDehackedSection.GetEntry(AIndex: Integer): TDehackedEntry;
begin
  Result := FEntries[AIndex];
end;

end.
