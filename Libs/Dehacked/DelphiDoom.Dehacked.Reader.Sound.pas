{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the block Sound                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Reader.Sound;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Section, DelphiDoom.Dehacked.Intf,
  DelphiDoom.Dehacked.FieldReader, DelphiDoom.Dehacked.Reader.Base;

type
  /// <summary>
  ///   Sound n or Sound name, and its fields. The reference is Name (the word as it was written)
  ///   and Number (what it says if it starts with a digit, -1 if the digits are followed by
  ///   anything else); a word that starts with a digit is a number, any other is the name of a sound.
  ///   Whether the sound exists is for the engine
  /// </summary>
  TDehackedSoundReader = class(TDehackedReaderBase)
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

{ TDehackedSoundReader }

constructor TDehackedSoundReader.Create(const AKeywords: TArray<string>; const ALog: ILog;
  AFields: TDehackedFieldReader);
begin
  inherited Create(AKeywords, ALog);
  FFields := AFields;
end;

destructor TDehackedSoundReader.Destroy;
begin
  FFields.Free;
  inherited Destroy;
end;

function TDehackedSoundReader.Read(const AKeyword, ARest: string;
  const ASource: IDehackedLineSource): TDehackedSection;
var
  LWord: string;
  LReference: TDehackedReference;
begin
  Result := nil;
  LWord := TDehackedStrings.FirstWordChar(ARest);
  if LWord = '' then
    Exit;

  LReference := Default(TDehackedReference);
  LReference.Name := LWord;
  if CharInSet(LWord[1], ['0'..'9']) then
    LReference.Number := TDehackedStrings.ToInteger(LWord, -1)
  else
    LReference.Number := -1;
  Result := CreateSection(dskSound, AKeyword, ARest, ASource);
  Result.Reference := LReference;
  FFields.Read(ASource, Result, LReference.Number);
end;

end.
