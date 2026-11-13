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
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
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
    function IsAddonNotSearched(const APack: IGamePack): Boolean;
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
  end;

implementation

uses
  DelphiDoom.Wad.Fs.PackStatus;

const
  SNilState = 'TGamePureServer.Create: the file system is nil';
  SMaxPureExceeded = 'MAX_PURE_PAKS ( 128 ) exceeded';

{ TGamePureServer }

constructor TGamePureServer.Create(const AState: IGameFileSystemInspector);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create(SNilState);
  FState := AState;
  FServerPacks := TList<IGamePack>.Create;
  FStatus := TDictionary<IGamePack, TGamePureStatus>.Create;
end;

destructor TGamePureServer.Destroy;
begin
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

function TGamePureServer.SetPureServerChecksums(const AChecksums: TArray<Cardinal>; out AMissing: TArray<Cardinal>;
  ALoadedFileFromDir: Boolean): TGamePureReply;
var
  LCount, LServerIndex, LLocalIndex: Integer;
  LPack: IGamePack;
  LSuccess, LCanPrepend: Boolean;
begin
  AMissing := nil;
  // the list ends at the first zero checksum, as the array of the original does
  LCount := 0;
  while (LCount < Length(AChecksums)) and (AChecksums[LCount] <> 0) do
    Inc(LCount);
  if LCount = 0 then
  begin
    ClearPureChecksums;
    Exit(TGamePureReply.Ok);
  end;
  if FServerPacks.Count = 0 then
    // there was no pure lockdown yet - lock to what we already have
    UpdatePureServerChecksums;
  LSuccess := True;
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
      LSuccess := False;
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
        LSuccess := False;
        // advance the server checksums only
        Inc(LServerIndex);
      end;
    end
    else
    begin
      // didn't find a matching checksum
      LSuccess := False;
      SetLength(AMissing, Length(AMissing) + 1);
      AMissing[High(AMissing)] := AChecksums[LServerIndex];
      Inc(LServerIndex);
    end;
  end;
  // some extra pak files are referenced at the end of our local list
  if LLocalIndex < FServerPacks.Count then
    LSuccess := False;
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

end.
