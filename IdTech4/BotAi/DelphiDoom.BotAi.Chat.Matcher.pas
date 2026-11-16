{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotChatMatcher, StringsMatch, BotFindMatch and        }
{  BotMatchVariable                                                            }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): code\botlib\        }
{  be_ai_chat.c. Based on the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.Matcher;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.Tables;

type
  /// <summary>Recognises a message with the match templates and gives the variables it found</summary>
  TBotChatMatcher = class
  strict private
    FTables: TBotChatTables;
    FImport: IBotImport;
  public
    constructor Create(const ATables: TBotChatTables; const AImport: IBotImport);
    /// <summary>
    ///   StringsMatch: tries the pieces on the text of the match and sets the offset and the length of
    ///   the variables. The offsets are signed chars: one of 128 or more wraps, as in the original.
    /// </summary>
    function StringsMatch(const APieces: TBotMatchPieces; var AMatch: TBotMatch): Boolean;
    /// <summary>BotFindMatch: the first template of the context that matches; the text is cut to the size of a message</summary>
    function FindMatch(const AText: AnsiString; const AContext: Cardinal; var AMatch: TBotMatch): Boolean;
    /// <summary>BotMatchVariable: the text of a variable, at most size - 1 characters; empty if not set</summary>
    function MatchVariable(const AMatch: TBotMatch; const AVariable, ASize: Integer): AnsiString;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Text;

{ TBotChatMatcher }

constructor TBotChatMatcher.Create(const ATables: TBotChatTables; const AImport: IBotImport);
begin
  inherited Create;
  FTables := ATables;
  FImport := AImport;
end;

function TBotChatMatcher.StringsMatch(const APieces: TBotMatchPieces; var AMatch: TBotMatch): Boolean;
var
  LLastVariable: Integer;
  LPointer: Integer;
  LNewPointer: Integer;
  LPieceIndex: Integer;
  LStringIndex: Integer;
  LIndex: Integer;
  LText: AnsiString;
  LFoundString: AnsiString;
begin
  LLastVariable := -1;
  LPointer := 0;
  LText := AMatch.Text;
  for LPieceIndex := 0 to High(APieces) do
  begin
    if APieces[LPieceIndex].PieceType = MT_STRING then
    begin
      LNewPointer := -1;
      LFoundString := '';
      for LStringIndex := 0 to High(APieces[LPieceIndex].Strings) do
      begin
        LFoundString := APieces[LPieceIndex].Strings[LStringIndex];
        if LFoundString = '' then
        begin
          LNewPointer := LPointer;
          Break;
        end;
        LIndex := TBotChatText.StringContains(Copy(LText, LPointer + 1, MaxInt), LFoundString, False);
        if LIndex >= 0 then
        begin
          LNewPointer := LPointer + LIndex;
          if LLastVariable >= 0 then
          begin
            AMatch.Variables[LLastVariable].Length := LNewPointer - AMatch.Variables[LLastVariable].Offset;
            LLastVariable := -1;
            Break;
          end
          else if LIndex = 0 then
            Break;
          LNewPointer := -1;
        end;
      end;
      if LNewPointer < 0 then
        Exit(False);
      LPointer := LNewPointer + Length(LFoundString);
    end
    else if APieces[LPieceIndex].PieceType = MT_VARIABLE then
    begin
      AMatch.Variables[APieces[LPieceIndex].Variable].Offset := ShortInt(LPointer);
      LLastVariable := APieces[LPieceIndex].Variable;
    end;
  end;
  // a match was found if the last piece was a variable or the whole text was used
  if (LLastVariable >= 0) or (Copy(LText, LPointer + 1, MaxInt) = '') then
  begin
    if LLastVariable >= 0 then
    begin
      // an offset that wrapped to a negative number reads before the text in the original: no characters here
      if AMatch.Variables[LLastVariable].Offset >= 0 then
        AMatch.Variables[LLastVariable].Length := Length(Copy(LText, AMatch.Variables[LLastVariable].Offset + 1, MaxInt))
      else
        AMatch.Variables[LLastVariable].Length := 0;
    end;
    Result := True;
  end
  else
    Result := False;
end;

function TBotChatMatcher.FindMatch(const AText: AnsiString; const AContext: Cardinal; var AMatch: TBotMatch): Boolean;
var
  LTemplate: TBotMatchTemplate;
  LIndex: Integer;
begin
  AMatch.Text := Copy(AText, 1, MAX_MESSAGE_SIZE - 1);
  // remove any trailing enters
  while (AMatch.Text <> '') and (AMatch.Text[Length(AMatch.Text)] = #10) do
    SetLength(AMatch.Text, Length(AMatch.Text) - 1);
  for LTemplate in FTables.Templates do
  begin
    if (LTemplate.Context and AContext) = 0 then
      Continue;
    // reset the match variable offsets
    for LIndex := 0 to MAX_MATCHVARIABLES - 1 do
      AMatch.Variables[LIndex].Offset := -1;
    if StringsMatch(LTemplate.Pieces, AMatch) then
    begin
      AMatch.MatchType := LTemplate.MatchType;
      AMatch.SubType := LTemplate.SubType;
      Exit(True);
    end;
  end;
  Result := False;
end;

function TBotChatMatcher.MatchVariable(const AMatch: TBotMatch; const AVariable, ASize: Integer): AnsiString;
var
  LSize: Integer;
begin
  Result := '';
  if (AVariable < 0) or (AVariable >= MAX_MATCHVARIABLES) then
  begin
    FImport.Print(PRT_FATAL, 'BotMatchVariable: variable out of range'#10);
    Exit;
  end;
  if AMatch.Variables[AVariable].Offset >= 0 then
  begin
    LSize := ASize;
    if AMatch.Variables[AVariable].Length < LSize then
      LSize := AMatch.Variables[AVariable].Length + 1;
    if LSize > 1 then
      Result := Copy(AMatch.Text, AMatch.Variables[AVariable].Offset + 1, LSize - 1);
  end;
end;

end.
