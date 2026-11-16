{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the blocks that are a list of "key = value"  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Reader.Lines;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Section,
  DelphiDoom.Dehacked.Intf, DelphiDoom.Dehacked.Reader.Base;

type
  /// <summary>What a block of this kind does with each line "key = value"</summary>
  TDehackedLineKind = (
    /// <summary>[SPRITES]: a sprite and the name of its new one (4 characters)</summary>
    dlkSprites,
    /// <summary>[STRINGS]: the name of a string and its text; a backslash at the end of a line goes on in the next</summary>
    dlkStrings,
    /// <summary>[MUSIC]: a music (number, name or map) and the name of the lump</summary>
    dlkMusic,
    /// <summary>[SOUNDS]: a sound (number or name) and the name of the lump</summary>
    dlkSounds,
    /// <summary>[CODEPTR]: FRAME n and the action of the frame</summary>
    dlkCodePointers);

  /// <summary>
  ///   The BEX blocks that are a list of lines "key = value". They end at the first line without
  ///   an equal sign; that line is read again as a header
  /// </summary>
  TDehackedLinesReader = class(TDehackedReaderBase)
  private
    FKind: TDehackedLineKind;
    FKindOfSection: TDehackedSectionKind;
    FParenthesesClear: Boolean;
    procedure ReadSprite(const ALine: string; const ASource: IDehackedLineSource;
      ASection: TDehackedSection);
    procedure ReadString(const ALine: string; const ASource: IDehackedLineSource;
      ASection: TDehackedSection);
    procedure ReadMusic(const ALine: string; const ASource: IDehackedLineSource;
      ASection: TDehackedSection);
    procedure ReadSound(const ALine: string; const ASource: IDehackedLineSource;
      ASection: TDehackedSection);
    procedure ReadCodePointer(const ALine: string; const ASource: IDehackedLineSource;
      ASection: TDehackedSection);
  public
    /// <param name="AParenthesesClear">
    ///   [MUSIC] of Hexen: a value between parentheses clears a name instead of setting one (Cleared of the entry)
    /// </param>
    constructor Create(const AKeywords: TArray<string>; const ALog: ILog; AKind: TDehackedLineKind;
      AParenthesesClear: Boolean = False);
    function Read(const AKeyword, ARest: string;
      const ASource: IDehackedLineSource): TDehackedSection; override;
  end;

implementation

uses
  DelphiDoom.Dehacked.Strings;

const
  SECTION_KINDS: array[TDehackedLineKind] of TDehackedSectionKind = (
    dskSprites, dskStrings, dskMusic, dskSounds, dskCodePointers);

{ TDehackedLinesReader }

constructor TDehackedLinesReader.Create(const AKeywords: TArray<string>; const ALog: ILog;
  AKind: TDehackedLineKind; AParenthesesClear: Boolean);
begin
  inherited Create(AKeywords, ALog);
  FKind := AKind;
  FKindOfSection := SECTION_KINDS[AKind];
  FParenthesesClear := AParenthesesClear;
end;

function TDehackedLinesReader.Read(const AKeyword, ARest: string;
  const ASource: IDehackedLineSource): TDehackedSection;
var
  LLine: string;
begin
  Result := CreateSection(FKindOfSection, AKeyword, ARest, ASource);
  while ASource.Next(LLine) do
  begin
    if TDehackedStrings.IndexOfChar('=', LLine) = 0 then
    begin
      ASource.PushBack;
      Break;
    end;
    case FKind of
      dlkSprites: ReadSprite(LLine, ASource, Result);
      dlkStrings: ReadString(LLine, ASource, Result);
      dlkMusic: ReadMusic(LLine, ASource, Result);
      dlkSounds: ReadSound(LLine, ASource, Result);
      dlkCodePointers: ReadCodePointer(LLine, ASource, Result);
    end;
  end;
end;

procedure TDehackedLinesReader.ReadSprite(const ALine: string; const ASource: IDehackedLineSource;
  ASection: TDehackedSection);
var
  LEntry: TDehackedEntry;
begin
  LEntry := Default(TDehackedEntry);
  LEntry.Line := ASource.LineNumber;
  TDehackedStrings.SplitChar(ALine, LEntry.Key, LEntry.Text, '=');
  LEntry.Number := TDehackedStrings.ToInteger(LEntry.Key, -1);
  // the name of the sprite that is looked for is not checked here: for a number the engine
  // takes the name from its table
  if Length(LEntry.Text) <> 4 then
  begin
    Warn('DEH_Parse(): Sprite name with %d characters = %s'#13#10, [Length(LEntry.Text), LEntry.Text]);
    Exit;
  end;
  ASection.AddEntry(LEntry);
end;

procedure TDehackedLinesReader.ReadString(const ALine: string; const ASource: IDehackedLineSource;
  ASection: TDehackedSection);
var
  LText, LNext: string;
  LEntry: TDehackedEntry;
begin
  LEntry := Default(TDehackedEntry);
  LEntry.Line := ASource.LineNumber;
  LText := ALine;
  while LText[Length(LText)] = '\' do
  begin
    // the line goes on: the backslash becomes a line break
    LText[Length(LText)] := #10;
    if not ASource.Next(LNext) then
      Break;
    LText := LText + LNext;
  end;
  TDehackedStrings.SplitChar(LText, LEntry.Key, LEntry.Text, '=');
  ASection.AddEntry(LEntry);
end;

procedure TDehackedLinesReader.ReadMusic(const ALine: string; const ASource: IDehackedLineSource;
  ASection: TDehackedSection);
var
  LEntry: TDehackedEntry;
  LValue: string;
begin
  LEntry := Default(TDehackedEntry);
  LEntry.Line := ASource.LineNumber;
  TDehackedStrings.SplitChar(ALine, LEntry.Key, LValue, '=');
  LEntry.Number := TDehackedStrings.ToInteger(LEntry.Key, -1);
  if FParenthesesClear and (Length(LValue) > 0) and (LValue[1] = '(') and
    (LValue[Length(LValue)] = ')') then
  begin
    LEntry.Cleared := True;
    LEntry.Text := '';
  end
  else
    LEntry.Text := TDehackedStrings.FirstWordChar(LValue);
  ASection.AddEntry(LEntry);
end;

procedure TDehackedLinesReader.ReadSound(const ALine: string; const ASource: IDehackedLineSource;
  ASection: TDehackedSection);
var
  LEntry: TDehackedEntry;
begin
  LEntry := Default(TDehackedEntry);
  LEntry.Line := ASource.LineNumber;
  TDehackedStrings.SplitChar(ALine, LEntry.Key, LEntry.Text, '=');
  LEntry.Number := TDehackedStrings.ToInteger(LEntry.Key, -1);
  ASection.AddEntry(LEntry);
end;

procedure TDehackedLinesReader.ReadCodePointer(const ALine: string;
  const ASource: IDehackedLineSource; ASection: TDehackedSection);
var
  LLeft, LWord, LFrame: string;
  LEntry: TDehackedEntry;
  LFrameNumber: Integer;
begin
  LEntry := Default(TDehackedEntry);
  LEntry.Line := ASource.LineNumber;
  TDehackedStrings.SplitChar(ALine, LLeft, LEntry.Text, '=');
  TDehackedStrings.SplitChar(LLeft, LWord, LFrame);
  if LWord <> 'FRAME' then
    Exit;
  LFrameNumber := TDehackedStrings.ToInteger(LFrame, -1);
  if LFrameNumber < 0 then
    Exit;
  LEntry.Key := LWord;
  LEntry.Numbers := [LFrameNumber];
  LEntry.Number := TDehackedStrings.ToInteger(LEntry.Text, -1);
  TDehackedStrings.SplitSet(LEntry.Text, LEntry.ActionName, LEntry.ActionArguments, [' ', '(']);
  ASection.AddEntry(LEntry);
end;

end.
