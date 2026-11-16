{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the block Misc                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Reader.Misc;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Section, DelphiDoom.Dehacked.Intf,
  DelphiDoom.Dehacked.FieldTable, DelphiDoom.Dehacked.Reader.Base;

type
  /// <summary>
  ///   Misc: the health and armor of the bonuses. A value that is not zero or more ends the block
  ///   (and the line is read again as a header), as does a field the game does not have
  /// </summary>
  TDehackedMiscReader = class(TDehackedReaderBase)
  private
    FTable: TDehackedFieldTable;
  public
    /// <param name="ATable">The reader owns it</param>
    constructor Create(const AKeywords: TArray<string>; const ALog: ILog; ATable: TDehackedFieldTable);
    destructor Destroy; override;
    function Read(const AKeyword, ARest: string;
      const ASource: IDehackedLineSource): TDehackedSection; override;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Strings;

{ TDehackedMiscReader }

constructor TDehackedMiscReader.Create(const AKeywords: TArray<string>; const ALog: ILog;
  ATable: TDehackedFieldTable);
begin
  inherited Create(AKeywords, ALog);
  FTable := ATable;
end;

destructor TDehackedMiscReader.Destroy;
begin
  FTable.Free;
  inherited Destroy;
end;

function TDehackedMiscReader.Read(const AKeyword, ARest: string;
  const ASource: IDehackedLineSource): TDehackedSection;
var
  LLine, LKey, LValue: string;
  LIndex: Integer;
  LEntry: TDehackedEntry;
begin
  Result := CreateSection(dskMisc, AKeyword, ARest, ASource);
  while ASource.Next(LLine) do
  begin
    if TDehackedStrings.IndexOfChar('=', LLine) = 0 then
    begin
      ASource.PushBack;
      Break;
    end;

    TDehackedStrings.SplitChar(LLine, LKey, LValue, '=');
    LIndex := FTable.IndexOf(LKey);
    if LIndex < 0 then
    begin
      Warn('DEH_Parse(): Wrong misc field = %s'#13#10, [LKey]);
      ASource.PushBack;
      Break;
    end;

    LEntry := Default(TDehackedEntry);
    LEntry.Line := ASource.LineNumber;
    LEntry.Key := LKey;
    LEntry.Field := FTable.Field(LIndex).Canonical;
    LEntry.FieldName := FTable.Field(LEntry.Field).Name;
    LEntry.Text := LValue;
    LEntry.Number := TDehackedStrings.ToInteger(LValue, -1);
    LEntry.IsNumber := IntToStr(LEntry.Number) = LValue;
    if LEntry.Number < 0 then // zero is allowed
    begin
      Warn('DEH_Parse(): Wrong misc value %s, field = %s'#13#10, [LValue, LKey]);
      ASource.PushBack;
      Break;
    end;
    Result.AddEntry(LEntry);
  end;
end;

end.
