{******************************************************************************}
{                                                                              }
{  DelphiDoom: test support of the bot AI library - the scenario of the        }
{  parity test (the commands of Tools\Verifica\124\chatgen.c)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.ScenarioRunner;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.BotAi.Chat.Intf, DelphiDoom.BotAi.Random.MsvcRand,
  DelphiDoom.BotAi.LibVars.Table, DelphiDoom.Tests.BotAi.Support;

type
  /// <summary>
  ///   Runs the lines of Tests\Data\BotAi\scenario.txt on the Delphi classes and writes what the C tool writes
  ///   (the line of the command, then its results; what the library prints, logs and sends in the order it does)
  /// </summary>
  TBotScenarioRunner = class
  strict private
    FOutput: TStringList;
    FImport: TFakeBotImport;
    FImportRef: IInterface;
    FLibVars: TBotLibVarTable;
    FLibVarsRef: IInterface;
    FRandom: TBotMsvcRandom;
    FRandomRef: IInterface;
    FChat: IBotChatSystem;
    FArgs: TArray<AnsiString>;
    FNulls: TArray<Boolean>;
    FQuiet: Boolean;
    procedure Flush;
    procedure Emit(const ALine: string);
    function Arg(const AIndex: Integer): AnsiString;
    function Num(const AIndex: Integer): Int64;
    procedure ShowMessage(const AHandle: Integer);
    procedure Execute(const ALine: AnsiString);
  public
    /// <summary>The escapes \t \n \r \\ \xNN of the scenario files</summary>
    class function Unescape(const AText: AnsiString): AnsiString; static;
    constructor Create(const AFiles: IInterface);
    destructor Destroy; override;
    /// <summary>Runs every line of the scenario; the output is in <c>Output</c></summary>
    procedure Run(const AScenario: TStrings);
    property Output: TStringList read FOutput;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.Factory,
  DelphiDoom.BotAi.Chat.Text, DelphiDoom.Scanner.IdCNumbers;

{ TBotScenarioRunner }

constructor TBotScenarioRunner.Create(const AFiles: IInterface);
begin
  inherited Create;
  FOutput := TStringList.Create;
  FImport := TFakeBotImport.Create;
  FImportRef := FImport;
  FLibVars := TBotLibVarTable.Create;
  FLibVarsRef := FLibVars;
  FRandom := TBotMsvcRandom.Create(1);
  FRandomRef := FRandom;
  FChat := TBotChatFactory.CreateChatSystem(FImport, AFiles as IBotFileSource, FLibVars, FRandom);
end;

destructor TBotScenarioRunner.Destroy;
begin
  FChat := nil;
  FRandomRef := nil;
  FLibVarsRef := nil;
  FImportRef := nil;
  FOutput.Free;
  inherited Destroy;
end;

procedure TBotScenarioRunner.Flush;
begin
  FOutput.AddStrings(FImport.Lines);
  FImport.Lines.Clear;
end;

procedure TBotScenarioRunner.Emit(const ALine: string);
begin
  // what the library printed before comes first
  Flush;
  FOutput.Add(ALine);
end;

class function TBotScenarioRunner.Unescape(const AText: AnsiString): AnsiString;
var
  LIndex: Integer;
  LChar: AnsiChar;
begin
  Result := '';
  LIndex := 1;
  while LIndex <= Length(AText) do
  begin
    LChar := AText[LIndex];
    if (LChar = '\') and (LIndex < Length(AText)) then
    begin
      Inc(LIndex);
      case AText[LIndex] of
        't': Result := Result + #9;
        'n': Result := Result + #10;
        'r': Result := Result + #13;
        '\': Result := Result + '\';
        'x':
          if LIndex + 2 <= Length(AText) then
          begin
            Result := Result + AnsiChar(StrToInt('$' + string(Copy(AText, LIndex + 1, 2))));
            Inc(LIndex, 2);
          end
          else
            Result := Result + 'x';
      else
        Result := Result + AText[LIndex];
      end;
      Inc(LIndex);
    end
    else
    begin
      Result := Result + LChar;
      Inc(LIndex);
    end;
  end;
end;

function TBotScenarioRunner.Arg(const AIndex: Integer): AnsiString;
begin
  if AIndex < Length(FArgs) then
    Result := FArgs[AIndex]
  else
    Result := '';
end;

function TBotScenarioRunner.Num(const AIndex: Integer): Int64;
var
  LText: string;
begin
  LText := Trim(string(Arg(AIndex)));
  if LText = '' then
    Exit(0);
  if (Copy(LText, 1, 2) = '0x') or (Copy(LText, 1, 2) = '0X') then
    Result := StrToInt64('$' + Copy(LText, 3, MaxInt))
  else
    Result := StrToInt64(LText);
end;

procedure TBotScenarioRunner.ShowMessage(const AHandle: Integer);
begin
  Emit('chatlen=' + IntToStr(FChat.ChatLength(AHandle)));
  Emit('chatmsg=' + EscapeBotText(FChat.GetChatMessage(AHandle, MAX_MESSAGE_SIZE)));
end;

procedure TBotScenarioRunner.Execute(const ALine: AnsiString);
var
  LParts: TArray<string>;
  LCommand: string;
  LIndex: Integer;
  LVars: TBotChatVariables;
  LMatch: TBotMatch;
  LText: AnsiString;
  LMessage: TBotConsoleMessage;
  LResult: Integer;

  function LHandle: Integer;
  begin
    Result := Integer(Num(0));
  end;

  function Vars(const AFirst: Integer): TBotChatVariables;
  var
    LVar: Integer;
  begin
    Result := TBotChatVariables.None;
    for LVar := 0 to MAX_MATCHVARIABLES - 1 do
    begin
      if (AFirst + LVar < Length(FArgs)) and not FNulls[AFirst + LVar] then
      begin
        Result.Items[LVar].IsSet := True;
        Result.Items[LVar].Text := FArgs[AFirst + LVar];
      end;
    end;
  end;

  procedure ShowMatchVariables;
  var
    LVar: Integer;
  begin
    Emit(Format('match type=%d subtype=%d', [LMatch.MatchType, LMatch.SubType]));
    for LVar := 0 to MAX_MATCHVARIABLES - 1 do
    begin
      Emit(Format('var%d offset=%d length=%d text=%s', [LVar, LMatch.Variables[LVar].Offset,
        LMatch.Variables[LVar].Length, EscapeBotText(FChat.MatchVariable(LMatch, LVar, MAX_MESSAGE_SIZE))]));
    end;
  end;

begin
  LParts := string(ALine).Split(['|']);
  SetLength(FArgs, Length(LParts) - 1);
  SetLength(FNulls, Length(LParts) - 1);
  LCommand := Trim(string(Unescape(AnsiString(LParts[0]))));
  for LIndex := 1 to High(LParts) do
  begin
    FNulls[LIndex - 1] := LParts[LIndex] = '<nil>';
    FArgs[LIndex - 1] := Unescape(AnsiString(LParts[LIndex]));
  end;
  if LCommand = 'libvar' then
    FLibVars.SetText(Arg(0), Arg(1))
  else if LCommand = 'seed' then
    FRandom.SetSeed(Cardinal(Num(0)))
  else if LCommand = 'time' then
    FImport.CurrentTime := TIdCNumbers.Atof(Arg(0))
  else if LCommand = 'setup' then
    Emit('setup=' + IntToStr(FChat.Setup))
  else if LCommand = 'shutdown' then
    FChat.Shutdown
  else if LCommand = 'resetchat' then
    FChat.ResetChatAI
  else if LCommand = 'alloc' then
    Emit('alloc=' + IntToStr(FChat.AllocChatState))
  else if LCommand = 'free' then
    FChat.FreeChatState(LHandle)
  else if LCommand = 'loadchat' then
    Emit('loadchat=' + IntToStr(FChat.LoadChatFile(LHandle, Arg(1), Arg(2))))
  else if LCommand = 'gender' then
    FChat.SetChatGender(LHandle, Integer(Num(1)))
  else if LCommand = 'name' then
    FChat.SetChatName(LHandle, Arg(1), Integer(Num(2)))
  else if LCommand = 'numinitial' then
    Emit('numinitial=' + IntToStr(FChat.NumInitialChats(LHandle, Arg(1))))
  else if LCommand = 'initial' then
  begin
    FChat.InitialChat(LHandle, Arg(1), Integer(Num(2)), Vars(3));
    if not FQuiet then
      ShowMessage(LHandle);
  end
  else if LCommand = 'quiet' then
    FQuiet := Num(0) <> 0
  else if LCommand = 'show' then
    ShowMessage(LHandle)
  else if LCommand = 'reply' then
  begin
    LResult := Ord(FChat.ReplyChat(LHandle, Arg(1), Integer(Num(2)), Integer(Num(3)), Vars(4)));
    Emit('reply=' + IntToStr(LResult));
    if not FQuiet then
      ShowMessage(LHandle);
  end
  else if LCommand = 'construct' then
  begin
    LVars := Vars(5);
    LMatch := Default(TBotMatch);
    for LIndex := 0 to MAX_MATCHVARIABLES - 1 do
    begin
      if not LVars.Items[LIndex].IsSet then
        Continue;
      LMatch.Variables[LIndex].Offset := ShortInt(Length(LMatch.Text));
      LMatch.Variables[LIndex].Length := Length(LVars.Items[LIndex].Text);
      LMatch.Text := LMatch.Text + LVars.Items[LIndex].Text;
    end;
    FChat.ConstructChatMessage(LHandle, Arg(1), Cardinal(Num(2)), Cardinal(Num(3)), LMatch, Num(4) <> 0);
    ShowMessage(LHandle);
  end
  else if LCommand = 'enter' then
    FChat.EnterChat(LHandle, Integer(Num(1)), Integer(Num(2)))
  else if LCommand = 'find' then
  begin
    LMatch := Default(TBotMatch);
    LResult := Ord(FChat.FindMatch(Arg(0), LMatch, Cardinal(Num(1))));
    Emit('find=' + IntToStr(LResult));
    if LResult <> 0 then
      ShowMatchVariables;
  end
  else if LCommand = 'matchvar' then
  begin
    LMatch := Default(TBotMatch);
    FChat.FindMatch(Arg(0), LMatch, Cardinal(Num(1)));
    Emit('matchvar=' + EscapeBotText(FChat.MatchVariable(LMatch, Integer(Num(2)), Integer(Num(3)))));
  end
  else if LCommand = 'unify' then
    Emit('unify=' + EscapeBotText(TBotChatText.UnifyWhiteSpaces(Arg(0))))
  else if LCommand = 'replsyn' then
    Emit('replsyn=' + EscapeBotText(FChat.ReplaceSynonyms(Arg(0), Cardinal(Num(1)))))
  else if LCommand = 'replrsyn' then
    Emit('replrsyn=' + EscapeBotText(FChat.ReplaceReplySynonyms(Arg(0), Cardinal(Num(1)))))
  else if LCommand = 'weighted' then
    Emit('weighted=' + EscapeBotText(FChat.ReplaceWeightedSynonyms(Arg(0), Cardinal(Num(1)))))
  else if LCommand = 'contains' then
    Emit('contains=' + IntToStr(TBotChatText.StringContains(Arg(0), Arg(1), Num(2) <> 0)))
  else if LCommand = 'containsword' then
    Emit('containsword=' + IntToStr(TBotChatText.StringContainsWord(Arg(0), Arg(1), Num(2) <> 0)))
  else if LCommand = 'replacewords' then
    Emit('replacewords=' + EscapeBotText(TBotChatText.ReplaceWords(Arg(0), Arg(1), Arg(2))))
  else if LCommand = 'tildes' then
    Emit('tildes=' + EscapeBotText(TBotChatText.RemoveTildes(Arg(0))))
  else if LCommand = 'queue' then
    FChat.QueueConsoleMessage(LHandle, Integer(Num(1)), Arg(2))
  else if LCommand = 'nextmsg' then
  begin
    LResult := FChat.NextConsoleMessage(LHandle, LMessage);
    LText := AnsiString('nextmsg=' + IntToStr(LResult));
    if LResult <> 0 then
      LText := LText + AnsiString(Format(' type=%d time=%s text=%s', [LMessage.MessageType,
        FormatFloat('0.00', LMessage.Time, TFormatSettings.Invariant), EscapeBotText(LMessage.Text)]));
    Emit(string(LText));
  end
  else if LCommand = 'removemsg' then
    FChat.RemoveConsoleMessage(LHandle, Integer(Num(1)))
  else if LCommand = 'numconsole' then
    Emit('numconsole=' + IntToStr(FChat.NumConsoleMessages(LHandle)))
  else
    Emit('UNKNOWN COMMAND ' + LCommand);
end;

procedure TBotScenarioRunner.Run(const AScenario: TStrings);
var
  LLine: string;
  LRaw: string;
begin
  for LRaw in AScenario do
  begin
    LLine := LRaw.TrimRight([#13, #10]);
    if (LLine = '') or (LLine[1] = ';') then
      Continue;
    Emit('> ' + EscapeBotText(AnsiString(LLine)));
    Execute(AnsiString(LLine));
  end;
  Flush;
end;

end.
