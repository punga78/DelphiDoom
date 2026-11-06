{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the parser                                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Parser;

interface

uses
  DelphiDoom.Dehacked.Intf;

type
  /// <summary>
  ///   Reads the text of a patch into its blocks. The first word of a line says which reader
  ///   takes the block; a line that no reader knows is left out (the "Doom version" and
  ///   "Patch format" lines are noted down). What the blocks do to the engine is not decided here
  /// </summary>
  TDehackedParser = class(TInterfacedObject, IDehackedParser)
  private
    FProfile: IDehackedProfile;
  public
    constructor Create(const AProfile: IDehackedProfile);
    function Parse(const AText: string): IDehackedPatch;
    function ParseLines(const ALines: TArray<string>): IDehackedPatch;
  end;

implementation

uses
  DelphiDoom.Dehacked.Section, DelphiDoom.Dehacked.Patch, DelphiDoom.Dehacked.LineSource,
  DelphiDoom.Dehacked.Strings, DelphiDoom.Dehacked.Text;

const
  SIGNATURE = 'PATCH FILE FOR DEHACKED';

{ TDehackedParser }

constructor TDehackedParser.Create(const AProfile: IDehackedProfile);
begin
  inherited Create;
  FProfile := AProfile;
end;

function TDehackedParser.Parse(const AText: string): IDehackedPatch;
begin
  Result := ParseLines(TDehackedText.SplitLines(AText));
end;

function TDehackedParser.ParseLines(const ALines: TArray<string>): IDehackedPatch;
var
  LPatch: TDehackedPatch;
  LSource: IDehackedLineSource;
  LLine, LKeyword, LRest, LKey, LValue: string;
  LReader: IDehackedSectionReader;
  LSection: TDehackedSection;
  LMustReadLine, LFirst, LSignature: Boolean;
  LDoomVersion, LPatchFormat: Integer;
begin
  LPatch := TDehackedPatch.Create;
  Result := LPatch;
  LSource := TDehackedLineSource.Create(ALines);
  LMustReadLine := True;
  LFirst := True;
  LSignature := False;
  LDoomVersion := -1;
  LPatchFormat := -1;
  // as the old loop: a line that a block gave back is read again only if the text goes on
  while LSource.HasMoreLines do
  begin
    if LMustReadLine then
    begin
      if not LSource.Next(LLine) then
        Break;
    end
    else
      LLine := LSource.LastLine;
    LMustReadLine := True;
    if LFirst then
    begin
      LSignature := TDehackedStrings.StartsWith(SIGNATURE, LLine);
      LFirst := False;
    end;

    TDehackedStrings.SplitChar(LLine, LKeyword, LRest);
    LReader := FProfile.FindReader(LKeyword);
    if Assigned(LReader) then
    begin
      LSection := LReader.Read(LKeyword, LRest, LSource);
      if Assigned(LSection) then
        LPatch.Add(LSection);
      if LSource.TakePushBack then
        LMustReadLine := False;
    end
    else
    begin
      TDehackedStrings.SplitChar(LLine, LKey, LValue, '=');
      if LKey = 'DOOM VERSION' then
        LDoomVersion := TDehackedStrings.ToInteger(LValue, -1)
      else if LKey = 'PATCH FORMAT' then
        LPatchFormat := TDehackedStrings.ToInteger(LValue, -1);
    end;
  end;
  LPatch.SetHeader(LDoomVersion, LPatchFormat, LSignature);
end;

end.
