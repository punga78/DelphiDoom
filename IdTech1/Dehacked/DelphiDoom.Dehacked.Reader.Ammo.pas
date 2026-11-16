{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the block Ammo                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Reader.Ammo;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Section, DelphiDoom.Dehacked.Intf,
  DelphiDoom.Dehacked.FieldReader, DelphiDoom.Dehacked.Reader.Base;

type
  /// <summary>Ammo n and its fields; n has to be one of the kinds of ammunition of the game</summary>
  TDehackedAmmoReader = class(TDehackedReaderBase)
  private
    FFields: TDehackedFieldReader;
    FAmmoCount: Integer;
  public
    /// <param name="AFields">The reader owns it</param>
    constructor Create(const AKeywords: TArray<string>; const ALog: ILog;
      AFields: TDehackedFieldReader; AAmmoCount: Integer);
    destructor Destroy; override;
    function Read(const AKeyword, ARest: string;
      const ASource: IDehackedLineSource): TDehackedSection; override;
  end;

implementation

uses
  DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Strings;

{ TDehackedAmmoReader }

constructor TDehackedAmmoReader.Create(const AKeywords: TArray<string>; const ALog: ILog;
  AFields: TDehackedFieldReader; AAmmoCount: Integer);
begin
  inherited Create(AKeywords, ALog);
  FFields := AFields;
  FAmmoCount := AAmmoCount;
end;

destructor TDehackedAmmoReader.Destroy;
begin
  FFields.Free;
  inherited Destroy;
end;

function TDehackedAmmoReader.Read(const AKeyword, ARest: string;
  const ASource: IDehackedLineSource): TDehackedSection;
var
  LWord: string;
  LReference: TDehackedReference;
  LNumber: Integer;
begin
  Result := nil;
  LWord := TDehackedStrings.FirstWordChar(ARest);
  if LWord = '' then
    Exit;

  LNumber := TDehackedStrings.ToInteger(LWord, -1);
  if (LNumber < 0) or (LNumber >= FAmmoCount) then
  begin
    Warn('DEH_Parse(): Wrong ammo number = %s'#13#10, [LWord]);
    Exit;
  end;

  LReference := Default(TDehackedReference);
  LReference.Number := LNumber;
  Result := CreateSection(dskAmmo, AKeyword, ARest, ASource);
  Result.Reference := LReference;
  FFields.Read(ASource, Result, LNumber);
end;

end.
