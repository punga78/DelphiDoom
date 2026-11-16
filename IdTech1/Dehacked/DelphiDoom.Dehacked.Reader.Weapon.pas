{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the block Weapon                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Reader.Weapon;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Section, DelphiDoom.Dehacked.Intf,
  DelphiDoom.Dehacked.FieldReader, DelphiDoom.Dehacked.Reader.Base;

type
  /// <summary>
  ///   Weapon n or Weapon name, and the fields. In Hexen the header has a second word, the
  ///   class of the player that the weapon belongs to (Weapon 2 Mage)
  /// </summary>
  TDehackedWeaponReader = class(TDehackedReaderBase)
  private
    FFields: TDehackedFieldReader;
    FWeaponCount: Integer;
    FHasClass: Boolean;
  public
    /// <param name="AFields">The reader owns it</param>
    /// <param name="AWeaponCount">The weapons of the game: a number from this on is wrong</param>
    /// <param name="AHasClass">The header says the class of the player too (Hexen)</param>
    constructor Create(const AKeywords: TArray<string>; const ALog: ILog;
      AFields: TDehackedFieldReader; AWeaponCount: Integer; AHasClass: Boolean);
    destructor Destroy; override;
    function Read(const AKeyword, ARest: string;
      const ASource: IDehackedLineSource): TDehackedSection; override;
  end;

implementation

uses
  DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Strings;

{ TDehackedWeaponReader }

constructor TDehackedWeaponReader.Create(const AKeywords: TArray<string>; const ALog: ILog;
  AFields: TDehackedFieldReader; AWeaponCount: Integer; AHasClass: Boolean);
begin
  inherited Create(AKeywords, ALog);
  FFields := AFields;
  FWeaponCount := AWeaponCount;
  FHasClass := AHasClass;
end;

destructor TDehackedWeaponReader.Destroy;
begin
  FFields.Free;
  inherited Destroy;
end;

function TDehackedWeaponReader.Read(const AKeyword, ARest: string;
  const ASource: IDehackedLineSource): TDehackedSection;
var
  LWord, LClass: string;
  LReference: TDehackedReference;
  LNumber: Integer;
begin
  Result := nil;
  LWord := TDehackedStrings.FirstWordChar(ARest);
  if LWord = '' then
    Exit;

  LReference := Default(TDehackedReference);
  LNumber := TDehackedStrings.ToInteger(LWord, -1);
  if LNumber < 0 then
    // the engine knows the names of its weapons
    LReference.Name := LWord
  else if LNumber >= FWeaponCount then
  begin
    Warn('DEH_Parse(): Wrong weapon number = %s'#13#10, [LWord]);
    Exit;
  end;
  LReference.Number := LNumber;

  if FHasClass then
  begin
    LClass := TDehackedStrings.SecondWord(ARest);
    if LClass = '' then
      Exit;
    LReference.Qualifier := LClass;
    LReference.QualifierNumber := TDehackedStrings.ToInteger(LClass, -1);
  end;

  Result := CreateSection(dskWeapon, AKeyword, ARest, ASource);
  Result.Reference := LReference;
  FFields.Read(ASource, Result, LNumber);
end;

end.
