{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the lines "field = value" of a block         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.FieldReader;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Types,
  DelphiDoom.Dehacked.Intf, DelphiDoom.Dehacked.Section, DelphiDoom.Dehacked.FieldTable;

type
  /// <summary>The warnings of a block, as format strings for Format (they end with a line break)</summary>
  TDehackedFieldMessages = record
    /// <summary>A field that the game does not have: %s the field, %d the number of the element</summary>
    UnknownField: string;
    /// <summary>NEWFRAME or ORIGINALFRAME without a number: %s the keyword, %s the text, %d the number of the element</summary>
    InvalidKeywordNumber: string;
    /// <summary>A field that must not be negative: %s the field, %s the text, %d the number of the element</summary>
    PositiveExpected: string;
    /// <summary>A field that the game does not have but knows by name: %s the field</summary>
    Unsupported: string;
    /// <summary>A level that is not 1 or 2: %s the field, %s the text, %d the number of the element</summary>
    InvalidLevel: string;
  end;

  /// <summary>
  ///   Reads the lines "field = value" that follow the header of a block, up to the first line that is
  ///   not one, or that names a field the game does not have: that line is given back to the parser
  /// </summary>
  TDehackedFieldReader = class
  private
    FTable: TDehackedFieldTable;
    FFlagSets: IDehackedFlagSets;
    FLog: ILog;
    FStripQuotes: Boolean;
    FMessages: TDehackedFieldMessages;
    procedure Warn(const AFormat: string; const AArguments: array of const);
    function ReadState(const AText: string; var AEntry: TDehackedEntry; AReference: Integer): Boolean;
    function ReadNextState(const AText: string; var AEntry: TDehackedEntry): Boolean;
    procedure ReadAction(const AText: string; var AEntry: TDehackedEntry);
    procedure ReadFlags(const ADef: TDehackedFieldDef; var AEntry: TDehackedEntry;
      ASection: TDehackedSection);
  public
    /// <param name="ATable">The fields; the reader owns it</param>
    /// <param name="AFlagSets">The sets of flags by name</param>
    /// <param name="ALog">May be nil</param>
    /// <param name="AStripQuotes">The values lose the quotes around them (the things)</param>
    constructor Create(ATable: TDehackedFieldTable; const AFlagSets: IDehackedFlagSets;
      const ALog: ILog; AStripQuotes: Boolean; const AMessages: TDehackedFieldMessages);
    destructor Destroy; override;
    /// <param name="AReference">The number of the element, for the warnings</param>
    procedure Read(const ASource: IDehackedLineSource; ASection: TDehackedSection;
      AReference: Integer);
    property Table: TDehackedFieldTable read FTable;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Dehacked.Strings;

{ TDehackedFieldReader }

constructor TDehackedFieldReader.Create(ATable: TDehackedFieldTable;
  const AFlagSets: IDehackedFlagSets; const ALog: ILog; AStripQuotes: Boolean;
  const AMessages: TDehackedFieldMessages);
begin
  inherited Create;
  FTable := ATable;
  FFlagSets := AFlagSets;
  FLog := ALog;
  FStripQuotes := AStripQuotes;
  FMessages := AMessages;
end;

destructor TDehackedFieldReader.Destroy;
begin
  FTable.Free;
  inherited Destroy;
end;

procedure TDehackedFieldReader.Warn(const AFormat: string; const AArguments: array of const);
begin
  if Assigned(FLog) then
    FLog.Warning(Format(AFormat, AArguments));
end;

function TDehackedFieldReader.ReadState(const AText: string; var AEntry: TDehackedEntry;
  AReference: Integer): Boolean;
var
  LKeyword, LNumberText: string;
  LNumber: Integer;
begin
  Result := True;
  AEntry.StateRef.Kind := srPlain;
  AEntry.StateRef.Number := AEntry.Number;
  LKeyword := TDehackedStrings.FirstWordChar(AText);
  if (LKeyword = 'NEWFRAME') or (LKeyword = 'NEWSTATE') or (LKeyword = 'ORIGINALFRAME') or
    (LKeyword = 'ORIGINALSTATE') then
  begin
    LNumberText := TDehackedStrings.SecondWord(AText);
    LNumber := TDehackedStrings.ToInteger(LNumberText, -1);
    if LNumber < 0 then
    begin
      Warn(FMessages.InvalidKeywordNumber, [LKeyword, LNumberText, AReference]);
      Exit(False);
    end;
    if (LKeyword = 'NEWFRAME') or (LKeyword = 'NEWSTATE') then
      AEntry.StateRef.Kind := srNew
    else
      AEntry.StateRef.Kind := srOriginal;
    AEntry.StateRef.Number := LNumber;
  end;
end;

function TDehackedFieldReader.ReadNextState(const AText: string;
  var AEntry: TDehackedEntry): Boolean;
var
  LKeyword: string;
begin
  Result := True;
  AEntry.StateRef.Kind := srPlain;
  AEntry.StateRef.Number := AEntry.Number;
  LKeyword := TDehackedStrings.FirstWordChar(AText);
  if (LKeyword = 'ORIGINALSTATE') or (LKeyword = 'ORIGINALFRAME') or (LKeyword = 'ORIGINAL') then
  begin
    AEntry.StateRef.Kind := srOriginal;
    AEntry.StateRef.Number := TDehackedStrings.ToInteger(TDehackedStrings.SecondWord(AText), 0);
  end
  else if (LKeyword = 'NEWSTATE') or (LKeyword = 'NEWFRAME') or (LKeyword = 'NEW') then
  begin
    AEntry.StateRef.Kind := srNew;
    AEntry.StateRef.Number := TDehackedStrings.ToInteger(TDehackedStrings.SecondWord(AText), 0);
  end;
end;

procedure TDehackedFieldReader.ReadAction(const AText: string; var AEntry: TDehackedEntry);
begin
  TDehackedStrings.SplitSet(AText, AEntry.ActionName, AEntry.ActionArguments, [' ', '(']);
end;

procedure TDehackedFieldReader.ReadFlags(const ADef: TDehackedFieldDef; var AEntry: TDehackedEntry;
  ASection: TDehackedSection);
var
  LSet: IDehackedFlagSet;
  LMask, LExtra: Integer;
begin
  LSet := FFlagSets.Find(ADef.FlagSet);
  if Assigned(LSet) then
  begin
    AEntry.HasFlags := LSet.Resolve(AEntry.Text, AEntry.Number, AEntry.IsNumber, LMask, LExtra);
    AEntry.Flags := LMask;
    ASection.ExtraFlags := ASection.ExtraFlags or LExtra;
  end;
end;

procedure TDehackedFieldReader.Read(const ASource: IDehackedLineSource; ASection: TDehackedSection;
  AReference: Integer);
var
  LLine, LKey, LValue: string;
  LIndex: Integer;
  LDef: TDehackedFieldDef;
  LEntry: TDehackedEntry;
begin
  while True do
  begin
    if not ASource.Next(LLine) then
      Break;
    if TDehackedStrings.IndexOfChar('=', LLine) = 0 then
    begin
      ASource.PushBack;
      Break;
    end;

    TDehackedStrings.SplitChar(LLine, LKey, LValue, '=');
    if FStripQuotes then
      LValue := TDehackedStrings.RemoveQuotes(LValue);
    LIndex := FTable.IndexOf(LKey);
    if LIndex < 0 then
    begin
      Warn(FMessages.UnknownField, [LKey, AReference]);
      ASource.PushBack;
      Break;
    end;
    LDef := FTable.Field(LIndex);

    if LDef.Kind = dfkUnsupported then
    begin
      Warn(FMessages.Unsupported, [FTable.Field(LDef.Canonical).Name]);
      Continue;
    end;

    LEntry := Default(TDehackedEntry);
    LEntry.Line := ASource.LineNumber;
    LEntry.Key := LKey;
    LEntry.Field := LDef.Canonical;
    LEntry.FieldName := FTable.Field(LDef.Canonical).Name;
    LEntry.Text := LValue;
    LEntry.Number := TDehackedStrings.ToInteger(LValue, LDef.Default);
    LEntry.IsNumber := IntToStr(LEntry.Number) = LValue;
    LEntry.Mbf21 := LDef.SetsMbf21;
    LEntry.StateRef.Number := LEntry.Number;

    case LDef.Kind of
      dfkPositive:
        if LEntry.Number < 0 then
        begin
          Warn(FMessages.PositiveExpected, [LKey, LValue, AReference]);
          Continue;
        end;
      dfkLevel:
        if (LEntry.Number < 1) or (LEntry.Number > LDef.Tolerance) then
        begin
          Warn(FMessages.InvalidLevel, [LEntry.FieldName, LValue, AReference]);
          Continue;
        end;
      dfkState:
        if not ReadState(LValue, LEntry, AReference) then
          Continue;
      dfkNextState:
        ReadNextState(LValue, LEntry);
      dfkFixed:
        LEntry.Fixed := TDehackedStrings.FixedOrFloat(LValue, LDef.Tolerance);
      dfkFlags:
        ReadFlags(LDef, LEntry, ASection);
      dfkAction:
        ReadAction(LValue, LEntry);
      dfkFrameNumber:
        if TDehackedStrings.FirstWordChar(LValue) = 'BRIGHT' then
        begin
          LEntry.Bright := True;
          LEntry.Number := TDehackedStrings.ToInteger(TDehackedStrings.SecondWord(LValue), 0);
        end;
    end;
    ASection.AddEntry(LEntry);
  end;
end;

end.
