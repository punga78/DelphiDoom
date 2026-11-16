{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the block Thing                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Reader.Thing;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Section, DelphiDoom.Dehacked.Intf,
  DelphiDoom.Dehacked.FieldReader, DelphiDoom.Dehacked.Reader.Base;

type
  /// <summary>
  ///   Thing n, Thing name or NEWTHING name, and the fields of the thing. A number that does not
  ///   write itself the same (0x10, 007) or is not one is the name of a new thing
  /// </summary>
  TDehackedThingReader = class(TDehackedReaderBase)
  private
    FFields: TDehackedFieldReader;
  public
    /// <param name="AFields">The reader owns it</param>
    constructor Create(const AKeywords: TArray<string>; const ALog: ILog; AFields: TDehackedFieldReader);
    destructor Destroy; override;
    function Read(const AKeyword, ARest: string;
      const ASource: IDehackedLineSource): TDehackedSection; override;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Strings;

{ TDehackedThingReader }

constructor TDehackedThingReader.Create(const AKeywords: TArray<string>; const ALog: ILog;
  AFields: TDehackedFieldReader);
begin
  inherited Create(AKeywords, ALog);
  FFields := AFields;
end;

destructor TDehackedThingReader.Destroy;
begin
  FFields.Free;
  inherited Destroy;
end;

function TDehackedThingReader.Read(const AKeyword, ARest: string;
  const ASource: IDehackedLineSource): TDehackedSection;
var
  LWord: string;
  LReference: TDehackedReference;
  LNumber: Integer;
begin
  LWord := TDehackedStrings.ParseFirstWord(ARest);
  Result := CreateSection(dskThing, AKeyword, ARest, ASource);
  LReference := Default(TDehackedReference);
  LReference.Number := -1;
  if (AKeyword = 'NEWTHING') or (LWord = '') or
    (IntToStr(TDehackedStrings.ToInteger(LWord, 0)) <> LWord) then
  begin
    LReference.IsNew := True;
    LReference.Name := LWord;
    LNumber := -1;
  end
  else
  begin
    // the numbers of the patches start at 1; whether the thing exists is for the engine
    LReference.Number := TDehackedStrings.ToInteger(LWord, -1);
    LNumber := LReference.Number - 1;
  end;
  Result.Reference := LReference;
  FFields.Read(ASource, Result, LNumber);
end;

end.
