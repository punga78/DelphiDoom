{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotItemConfigLoader, LoadItemConfig                   }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): LoadItemConfig of   }
{  code\botlib\be_ai_goal.c. Based on the Quake III Arena GPL Source Code (id  }
{  Software). Copyright (C) 1999-2005 Id Software, Inc.                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Goal.ItemConfigLoader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.LibVars.Intf, DelphiDoom.BotAi.Chat.Source,
  DelphiDoom.BotAi.Goal.ItemConfig, DelphiDoom.BotAi.Goal.ItemDefinitions;

type
  /// <summary>Reads the item file (<c>iteminfo "item_armor_body" { name "Heavy Armor" ... }</c>)</summary>
  TBotItemConfigLoader = class
  strict private
    FImport: IBotImport;
    FFiles: IBotFileSource;
    FLibVars: IBotLibVarStore;
    FDefinitions: TBotItemDefinitions;
    function ReadItems(const ASource: TBotChatSource; const AConfig: TBotItemConfig; const AMaxItems: Integer): Boolean;
  public
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource; const ALibVars: IBotLibVarStore;
      const ADefinitions: TBotItemDefinitions);
    /// <summary>
    ///   LoadItemConfig: <c>max_iteminfo</c> (256 if missing or negative; the negative value is reset) is the limit
    ///   of the definitions. nil, with the reason printed, if the file or a definition is wrong.
    /// </summary>
    function Load(const AFileName: AnsiString): TBotItemConfig;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Types,
  DelphiDoom.BotAi.Struct.Reader,
  DelphiDoom.BotAi.Text.CFormat, DelphiDoom.BotAi.Goal.Types;

{ TBotItemConfigLoader }

constructor TBotItemConfigLoader.Create(const AImport: IBotImport; const AFiles: IBotFileSource;
  const ALibVars: IBotLibVarStore; const ADefinitions: TBotItemDefinitions);
begin
  inherited Create;
  FImport := AImport;
  FFiles := AFiles;
  FLibVars := ALibVars;
  FDefinitions := ADefinitions;
end;

function TBotItemConfigLoader.ReadItems(const ASource: TBotChatSource; const AConfig: TBotItemConfig;
  const AMaxItems: Integer): Boolean;
var
  LToken: TIdToken;
  LInfo: TBotItemInfo;
  LBytes: TBytes;
  LIndex: Integer;
  LName: AnsiString;
begin
  Result := False;
  // parse the item config file
  while ASource.ReadToken(LToken) do
  begin
    if TBotChatSource.CText(LToken) = 'iteminfo' then
    begin
      if AConfig.Count >= AMaxItems then
      begin
        ASource.Fail('more than ' + IntToStr(AMaxItems) + ' item info defined'#10);
        Exit;
      end;
      LInfo := Default(TBotItemInfo);
      ASource.ExpectTokenType(TT_STRING, 0, LToken);
      LName := LToken.Text;
      // strncpy(ii->classname, token.string, sizeof(ii->classname) - 1)
      for LIndex := 0 to Length(LName) - 1 do
      begin
        if LIndex >= ITEM_CLASSNAME_SIZE - 1 then
          Break;
        LInfo.ClassName[LIndex] := LName[LIndex + 1];
      end;
      SetLength(LBytes, 0);
      SetLength(LBytes, SizeOf(TBotItemInfo));
      Move(LInfo, LBytes[0], SizeOf(TBotItemInfo));
      if not TBotStructReader.ReadStructure(ASource, FDefinitions.Item, LBytes) then
        Exit;
      Move(LBytes[0], LInfo, SizeOf(TBotItemInfo));
      AConfig.Add(LInfo);
    end
    else
    begin
      ASource.Fail('unknown definition ' + string(TBotChatSource.CText(LToken)) + #10);
      Exit;
    end;
  end;
  Result := True;
end;

function TBotItemConfigLoader.Load(const AFileName: AnsiString): TBotItemConfig;
var
  LMaxItems: Integer;
  LSource: TBotChatSource;
  LRead: Boolean;
begin
  LMaxItems := Trunc(FLibVars.GetValueOrCreate('max_iteminfo', '256'));
  if LMaxItems < 0 then
  begin
    FImport.Print(PRT_ERROR, 'max_iteminfo = ' + TBotCFormat.Int(LMaxItems) + #10);
    LMaxItems := 256;
    FLibVars.SetText('max_iteminfo', '256');
  end;
  LSource := TBotChatSource.Open(FImport, FFiles, AFileName);
  if not Assigned(LSource) then
  begin
    FImport.Print(PRT_ERROR, 'counldn''t load ' + AFileName + #10);
    Exit(nil);
  end;
  // initialize item config
  Result := TBotItemConfig.Create;
  try
    try
      LRead := ReadItems(LSource, Result, LMaxItems);
    except
      // the source printed the error (SourceError); the original returns NULL
      on EBotChatParseException do
        LRead := False;
    end;
  finally
    LSource.Free;
  end;
  if not LRead then
  begin
    FreeAndNil(Result);
    Exit;
  end;
  if Result.Count = 0 then
    FImport.Print(PRT_WARNING, 'no item info loaded'#10);
  FImport.Print(PRT_MESSAGE, 'loaded ' + AFileName + #10);
end;

end.
