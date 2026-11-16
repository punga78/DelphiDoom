{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: the pure server         }
{                                                                              }
{  Port of UpdatePureServerChecksums, GetPackForChecksum,                      }
{  ClearPureChecksums, SetPureServerChecksums and GetPureServerChecksums of    }
{  framework\FileSystem.cpp (id Software, GPL v3). Copyright (C) 1999-2011 id  }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Framework\IdLib\README.md); the repository }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.PureServer;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf,
  DelphiDoom.Wad.Fs.PureServer.Intf;

type
  /// <summary>
  ///   The pure server lock over the paks of a file system (seen through <c>IGameFileSystemInspector</c>).
  ///   The status of a pak is worked out once, by <c>TGamePackStatus</c>.
  /// </summary>
  TGamePureServer = class(TInterfacedObject, IGamePureServer)
  strict private
    const
      MAX_PURE_PAKS = 128;
    var
      FState: IGameFileSystemInspector;
      FServerPacks: TList<IGamePack>;
      FStatus: TDictionary<IGamePack, TGamePureStatus>;
      FGamePakChecksum: Cardinal;
      FGamePakForOS: TArray<Cardinal>;
      FRestartChecksums: TList<Cardinal>;
      FRestartAddonChecksums: TList<Cardinal>;
      FRestartGamePakChecksum: Cardinal;
    function IsAddonNotSearched(const APack: IGamePack): Boolean;
    function MatchChecksums(const AChecksums: TArray<Cardinal>; out AMissing: TArray<Cardinal>;
      out ACleared: Boolean): Boolean;
  public
    /// <summary>EArgumentNilException when the file system is nil</summary>
    constructor Create(const AState: IGameFileSystemInspector);
    destructor Destroy; override;
    function ServerPacks: TArray<IGamePack>;
    procedure UpdatePureServerChecksums;
    procedure ClearPureChecksums;
    function GetPureServerChecksums: TArray<Cardinal>;
    function SetPureServerChecksums(const AChecksums: TArray<Cardinal>; out AMissing: TArray<Cardinal>;
      ALoadedFileFromDir: Boolean = False): TGamePureReply;
    function GetPackForChecksum(AChecksum: Cardinal; ASearchAddons: Boolean = False): IGamePack;
    function GetPackStatus(const APack: IGamePack): TGamePureStatus;
    function GetGamePakChecksum: Cardinal;
    procedure SetGamePakChecksum(AChecksum: Cardinal);
    procedure SetGamePakForOS(const AChecksums: TArray<Cardinal>);
    function SetPureServerChecksumsWithGamePak(const AChecksums: TArray<Cardinal>; AGamePakChecksum: Cardinal;
      const ADllName: string; out AMissing: TArray<Cardinal>; out AMissingGamePak: Cardinal;
      ALoadedFileFromDir: Boolean = False): TGamePureReply;
    function GetPureServerChecksumsForOS(AOS: Integer; out AGamePakChecksum: Cardinal): TArray<Cardinal>;
    procedure SetRestartChecksums(const AChecksums: TArray<Cardinal>; AGamePakChecksum: Cardinal);
    function RestartChecksums: TArray<Cardinal>;
    function RestartAddonChecksums: TArray<Cardinal>;
    function RestartGamePakChecksum: Cardinal;
  end;

implementation

uses
  DelphiDoom.Wad.Fs.PackStatus;

const
  SNilState = 'TGamePureServer.Create: the file system is nil';
  SMaxPureExceeded = 'MAX_PURE_PAKS ( 128 ) exceeded';
  SNoPakForChecksum = 'SetRestartChecksums failed: no pak for checksum 0x%x';

{ TGamePureServer }

constructor TGamePureServer.Create(const AState: IGameFileSystemInspector);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create(SNilState);
  FState := AState;
  FServerPacks := TList<IGamePack>.Create;
  FStatus := TDictionary<IGamePack, TGamePureStatus>.Create;
  FRestartChecksums := TList<Cardinal>.Create;
  FRestartAddonChecksums := TList<Cardinal>.Create;
end;

destructor TGamePureServer.Destroy;
begin
  FRestartAddonChecksums.Free;
  FRestartChecksums.Free;
  FStatus.Free;
  FServerPacks.Free;
  inherited Destroy;
end;

function TGamePureServer.ServerPacks: TArray<IGamePack>;
begin
  Result := FServerPacks.ToArray;
end;

function TGamePureServer.GetPackStatus(const APack: IGamePack): TGamePureStatus;
begin
  if not FStatus.TryGetValue(APack, Result) then
  begin
    Result := TGamePackStatus.Classify(APack);
    FStatus.Add(APack, Result);
  end;
end;

procedure TGamePureServer.UpdatePureServerChecksums;
var
  LPack: IGamePack;
  LStatus: TGamePureStatus;
begin
  FServerPacks.Clear;
  for LPack in FState.Packs do
  begin
    LStatus := GetPackStatus(LPack);
    if LStatus = TGamePureStatus.Never then
      Continue;
    if (LStatus = TGamePureStatus.Neutral) and not LPack.Referenced then
      Continue;
    FServerPacks.Add(LPack);
    if FServerPacks.Count >= MAX_PURE_PAKS then
      raise EGameFsException.Create(SMaxPureExceeded);
  end;
end;

procedure TGamePureServer.ClearPureChecksums;
begin
  FServerPacks.Clear;
end;

function TGamePureServer.GetPureServerChecksums: TArray<Cardinal>;
var
  LIndex: Integer;
begin
  SetLength(Result, FServerPacks.Count);
  for LIndex := 0 to FServerPacks.Count - 1 do
    Result[LIndex] := FServerPacks[LIndex].Checksum;
end;

function TGamePureServer.GetPackForChecksum(AChecksum: Cardinal; ASearchAddons: Boolean): IGamePack;
var
  LPack: IGamePack;
begin
  for LPack in FState.Packs do
    if LPack.Checksum = AChecksum then
      Exit(LPack);
  if ASearchAddons then
    for LPack in FState.AddonPacks do
      if LPack.Checksum = AChecksum then
        Exit(LPack);
  Result := nil;
end;

function TGamePureServer.IsAddonNotSearched(const APack: IGamePack): Boolean;
var
  LPack: IGamePack;
begin
  Result := False;
  for LPack in FState.AddonPacks do
    if LPack = APack then
      Exit(True);
end;

function TGamePureServer.MatchChecksums(const AChecksums: TArray<Cardinal>; out AMissing: TArray<Cardinal>;
  out ACleared: Boolean): Boolean;
var
  LCount, LServerIndex, LLocalIndex: Integer;
  LPack: IGamePack;
  LCanPrepend: Boolean;
begin
  AMissing := nil;
  ACleared := False;
  // the list ends at the first zero checksum, as the array of the original does
  LCount := 0;
  while (LCount < Length(AChecksums)) and (AChecksums[LCount] <> 0) do
    Inc(LCount);
  if LCount = 0 then
  begin
    ClearPureChecksums;
    ACleared := True;
    Exit(True);
  end;
  if FServerPacks.Count = 0 then
    // there was no pure lockdown yet - lock to what we already have
    UpdatePureServerChecksums;
  Result := True;
  LCanPrepend := True;
  LServerIndex := 0;
  LLocalIndex := 0;
  while LServerIndex < LCount do
  begin
    if (LLocalIndex < FServerPacks.Count) and (FServerPacks[LLocalIndex].Checksum = AChecksums[LServerIndex]) then
    begin
      // once you start matching into the list there is no prepending anymore
      LCanPrepend := False;
      Inc(LServerIndex);
      Inc(LLocalIndex);
      Continue;
    end;
    LPack := GetPackForChecksum(AChecksums[LServerIndex], True);
    // an addon pak that is not on the search list: a restart including it is required
    if Assigned(LPack) and LPack.IsAddon and IsAddonNotSearched(LPack) then
      Result := False;
    if Assigned(LPack) then
    begin
      if LCanPrepend then
      begin
        // we still have a chance
        FServerPacks.Insert(LLocalIndex, LPack);
        Inc(LServerIndex);
        Inc(LLocalIndex);
      end
      else
      begin
        Result := False;
        // advance the server checksums only
        Inc(LServerIndex);
      end;
    end
    else
    begin
      // didn't find a matching checksum
      Result := False;
      SetLength(AMissing, Length(AMissing) + 1);
      AMissing[High(AMissing)] := AChecksums[LServerIndex];
      Inc(LServerIndex);
    end;
  end;
  // some extra pak files are referenced at the end of our local list
  if LLocalIndex < FServerPacks.Count then
    Result := False;
end;

function TGamePureServer.SetPureServerChecksums(const AChecksums: TArray<Cardinal>; out AMissing: TArray<Cardinal>;
  ALoadedFileFromDir: Boolean): TGamePureReply;
var
  LSuccess, LCleared: Boolean;
begin
  LSuccess := MatchChecksums(AChecksums, AMissing, LCleared);
  if LCleared then
    Exit(TGamePureReply.Ok);
  // we reply to missing before the last check
  if Length(AMissing) > 0 then
    Exit(TGamePureReply.Missing);
  if ALoadedFileFromDir then
    LSuccess := False;
  if LSuccess then
    Result := TGamePureReply.Ok
  else
    Result := TGamePureReply.Restart;
end;

function TGamePureServer.GetGamePakChecksum: Cardinal;
begin
  Result := FGamePakChecksum;
end;

procedure TGamePureServer.SetGamePakChecksum(AChecksum: Cardinal);
begin
  FGamePakChecksum := AChecksum;
end;

procedure TGamePureServer.SetGamePakForOS(const AChecksums: TArray<Cardinal>);
begin
  FGamePakForOS := Copy(AChecksums);
end;

function TGamePureServer.SetPureServerChecksumsWithGamePak(const AChecksums: TArray<Cardinal>;
  AGamePakChecksum: Cardinal; const ADllName: string; out AMissing: TArray<Cardinal>;
  out AMissingGamePak: Cardinal; ALoadedFileFromDir: Boolean): TGamePureReply;
var
  LSuccess, LCleared: Boolean;
  LPack: IGamePack;
begin
  AMissingGamePak := 0;
  LSuccess := MatchChecksums(AChecksums, AMissing, LCleared);
  if LCleared then
    Exit(TGamePureReply.Ok);
  // DLL checksuming: the server has no knowledge of code we can use (an operating system issue)
  if AGamePakChecksum = 0 then
    Exit(TGamePureReply.NoDll);
  if AGamePakChecksum <> FGamePakChecksum then
  begin
    // the current code is wrong: search all the paks, the pure list is not relevant here
    LPack := GetPackForChecksum(AGamePakChecksum);
    if not Assigned(LPack) then
    begin
      AMissingGamePak := AGamePakChecksum;
      Exit(TGamePureReply.Missing);
    end;
    // if assets paks are missing, do not try the restart or the NODLL answer
    if Length(AMissing) > 0 then
      Exit(TGamePureReply.Missing);
    // make sure there is a valid DLL for us
    if LPack.FindEntry(ADllName) >= 0 then
    begin
      // this will be used to extract the DLL in pure mode
      FGamePakChecksum := AGamePakChecksum;
      Exit(TGamePureReply.Restart);
    end;
    Exit(TGamePureReply.NoDll);
  end;
  // we reply to missing after the DLL check so it can be part of the list
  if Length(AMissing) > 0 then
    Exit(TGamePureReply.Missing);
  if ALoadedFileFromDir then
    LSuccess := False;
  if LSuccess then
    Result := TGamePureReply.Ok
  else
    Result := TGamePureReply.Restart;
end;

function TGamePureServer.GetPureServerChecksumsForOS(AOS: Integer; out AGamePakChecksum: Cardinal): TArray<Cardinal>;
begin
  Result := GetPureServerChecksums;
  if AOS < 0 then
    AGamePakChecksum := FGamePakChecksum
  else if AOS < Length(FGamePakForOS) then
    AGamePakChecksum := FGamePakForOS[AOS]
  else
    AGamePakChecksum := 0;
end;

procedure TGamePureServer.SetRestartChecksums(const AChecksums: TArray<Cardinal>; AGamePakChecksum: Cardinal);
var
  LIndex: Integer;
  LPack: IGamePack;
begin
  FRestartChecksums.Clear;
  for LIndex := 0 to High(AChecksums) do
  begin
    if AChecksums[LIndex] = 0 then
      Break;
    LPack := GetPackForChecksum(AChecksums[LIndex], True);
    if not Assigned(LPack) then
      raise EGameFsException.CreateFmt(SNoPakForChecksum, [AChecksums[LIndex]]);
    // can't mark it pure if we're not even gonna search it
    if LPack.IsAddon and not FRestartAddonChecksums.Contains(LPack.Checksum) then
      FRestartAddonChecksums.Add(LPack.Checksum);
    FRestartChecksums.Add(AChecksums[LIndex]);
  end;
  FRestartGamePakChecksum := AGamePakChecksum;
end;

function TGamePureServer.RestartChecksums: TArray<Cardinal>;
begin
  Result := FRestartChecksums.ToArray;
end;

function TGamePureServer.RestartAddonChecksums: TArray<Cardinal>;
begin
  Result := FRestartAddonChecksums.ToArray;
end;

function TGamePureServer.RestartGamePakChecksum: Cardinal;
begin
  Result := FRestartGamePakChecksum;
end;
end.
