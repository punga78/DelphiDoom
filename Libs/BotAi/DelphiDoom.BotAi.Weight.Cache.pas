{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWeightCache, the cache of weight files           }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): weightFileList and  }
{  the cache part of ReadWeightConfig, FreeWeightConfig, FreeWeightConfig2 and }
{  BotShutdownWeights of code\botlib\be_ai_weight.c. Based on the Quake III    }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc.                                                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weight.Cache;

interface

uses
  System.Generics.Collections, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Weight.Config,
  DelphiDoom.BotAi.Weight.Intf;

type
  /// <summary>
  ///   weightFileList as an object: the global list of 128 retained configurations is a field. The
  ///   configurations read while <c>bot_reloadcharacters</c> is set are not retained: they live until
  ///   FreeWeightConfig or Shutdown.
  /// </summary>
  TBotWeightCache = class(TInterfacedObject, IBotWeightCache)
  strict private
    FImport: IBotImport;
    FFiles: IBotFileSource;
    FLibVars: IBotLibVars;
    FOwned: TObjectList<TBotWeightConfig>;
    FRetained: array of TBotWeightConfig;
    procedure Forget(const AConfig: TBotWeightConfig);
  public
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource; const ALibVars: IBotLibVars);
    destructor Destroy; override;
    function ReadWeightConfig(const AFileName: AnsiString): TBotWeightConfig;
    procedure FreeWeightConfig(const AConfig: TBotWeightConfig);
    procedure Shutdown;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Weight.Types, DelphiDoom.BotAi.Weight.Reader;

{ TBotWeightCache }

constructor TBotWeightCache.Create(const AImport: IBotImport; const AFiles: IBotFileSource;
  const ALibVars: IBotLibVars);
begin
  inherited Create;
  FImport := AImport;
  FFiles := AFiles;
  FLibVars := ALibVars;
  FOwned := TObjectList<TBotWeightConfig>.Create(True);
  SetLength(FRetained, MAX_WEIGHT_FILES);
end;

destructor TBotWeightCache.Destroy;
begin
  FOwned.Free;
  inherited Destroy;
end;

procedure TBotWeightCache.Forget(const AConfig: TBotWeightConfig);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FRetained) do
  begin
    if FRetained[LIndex] = AConfig then
      FRetained[LIndex] := nil;
  end;
end;

function TBotWeightCache.ReadWeightConfig(const AFileName: AnsiString): TBotWeightConfig;
var
  LReader: TBotWeightReader;
  LAvailable: Integer;
  LIndex: Integer;
  LReload: Boolean;
begin
  LReload := FLibVars.GetValue('bot_reloadcharacters') <> 0;
  LAvailable := -1;
  if not LReload then
  begin
    for LIndex := 0 to MAX_WEIGHT_FILES - 1 do
    begin
      if not Assigned(FRetained[LIndex]) then
      begin
        if LAvailable = -1 then
          LAvailable := LIndex;
        Continue;
      end;
      if AFileName = FRetained[LIndex].FileName then
        Exit(FRetained[LIndex]);
    end;
    if LAvailable = -1 then
    begin
      FImport.Print(PRT_ERROR, 'weightFileList was full trying to load ' + AFileName + #10);
      Exit(nil);
    end;
  end;
  LReader := TBotWeightReader.Create(FImport, FFiles);
  try
    Result := LReader.Read(AFileName);
  finally
    LReader.Free;
  end;
  if not Assigned(Result) then
    Exit;
  FOwned.Add(Result);
  // the variable is read again after the file, as the original does
  if FLibVars.GetValue('bot_reloadcharacters') = 0 then
    FRetained[LAvailable] := Result;
end;

procedure TBotWeightCache.FreeWeightConfig(const AConfig: TBotWeightConfig);
begin
  if not Assigned(AConfig) then
    Exit;
  if FLibVars.GetValue('bot_reloadcharacters') = 0 then
    Exit;
  Forget(AConfig);
  // FreeWeightConfig2
  FOwned.Remove(AConfig);
end;

procedure TBotWeightCache.Shutdown;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FRetained) do
    FRetained[LIndex] := nil;
  FOwned.Clear;
end;

end.
