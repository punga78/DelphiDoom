{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the saved games                                  }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): SaveGame and LoadGame of    }
{  utils.pas, SaveDirectory and ShowSaveDir of menu.pas                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SaveGames;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Save.Intf;

type
  /// <summary>
  ///   The saved game is the player record written as it is in a file called SAVEGAME.N (SAVE1.N, SAVE2.N, SAVE3.N in
  ///   the games of the family); the names of the menu are the ten short strings of SAVEGAME.DIR. What goes in the
  ///   record (the sprites of monsters, doors and elevators) is the job of the world
  /// </summary>
  TGreedSaveGames = class(TInterfacedObject, IGreedSaveGames)
  strict private
    FFiles: IGreedSaveFiles;
    FVariant: TGreedGameVariant;
    function Prefix: string;
  public
    constructor Create(const AFiles: IGreedSaveFiles; AVariant: TGreedGameVariant);
    function GameFileName(ANumber: Integer): string;
    function DirectoryFileName: string;
    procedure SaveGame(ANumber: Integer; const APlayer: TGreedPlayerRecord);
    function LoadGame(ANumber: Integer; out APlayer: TGreedPlayerRecord): Boolean;
    function ReadDirectory: TGreedSaveDirectory;
    procedure WriteDirectory(const ADirectory: TGreedSaveDirectory);
    /// <summary>
    ///   The scroll range of a saved game made at the other resolution (the end of LoadGame): the low resolution
    ///   has 200 lines, the other 400. A range that already has the size of the current resolution is kept
    /// </summary>
    class procedure AdjustScroll(var APlayer: TGreedPlayerRecord; ALowResolution: Boolean); static;
  end;

implementation

{ TGreedSaveGames }

constructor TGreedSaveGames.Create(const AFiles: IGreedSaveFiles; AVariant: TGreedGameVariant);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FFiles := AFiles;
  FVariant := AVariant;
end;

function TGreedSaveGames.Prefix: string;
begin
  case FVariant of
    ggvGame1: Result := 'SAVE1';
    ggvGame2: Result := 'SAVE2';
    ggvGame3: Result := 'SAVE3';
  else
    Result := 'SAVEGAME';
  end;
end;

function TGreedSaveGames.GameFileName(ANumber: Integer): string;
begin
  Result := Format('%s.%d', [Prefix, ANumber]);
end;

function TGreedSaveGames.DirectoryFileName: string;
begin
  Result := Prefix + '.DIR';
end;

procedure TGreedSaveGames.SaveGame(ANumber: Integer; const APlayer: TGreedPlayerRecord);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, SizeOf(APlayer));
  Move(APlayer, LBytes[0], SizeOf(APlayer));
  FFiles.WriteAll(GameFileName(ANumber), LBytes);
end;

function TGreedSaveGames.LoadGame(ANumber: Integer; out APlayer: TGreedPlayerRecord): Boolean;
var
  LName: string;
  LBytes: TBytes;
begin
  LName := GameFileName(ANumber);
  Result := FFiles.Exists(LName);
  if not Result then
    Exit;
  LBytes := FFiles.ReadAll(LName);
  if Length(LBytes) < SizeOf(APlayer) then
    raise EGreedDataException.CreateFmt(SGreedSaveTooShort, [LName, Length(LBytes), SizeOf(APlayer)]);
  Move(LBytes[0], APlayer, SizeOf(APlayer));
end;

function TGreedSaveGames.ReadDirectory: TGreedSaveDirectory;
var
  LName: string;
  LBytes: TBytes;
  LIndex: Integer;
begin
  LName := DirectoryFileName;
  if not FFiles.Exists(LName) then
  begin
    for LIndex := 0 to GREED_MAX_SAVE_GAMES - 1 do
      Result[LIndex] := '';
    WriteDirectory(Result);
    Exit;
  end;
  LBytes := FFiles.ReadAll(LName);
  if Length(LBytes) < SizeOf(Result) then
    raise EGreedDataException.CreateFmt(SGreedSaveTooShort, [LName, Length(LBytes), SizeOf(Result)]);
  Move(LBytes[0], Result, SizeOf(Result));
end;

procedure TGreedSaveGames.WriteDirectory(const ADirectory: TGreedSaveDirectory);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, SizeOf(ADirectory));
  Move(ADirectory, LBytes[0], SizeOf(ADirectory));
  FFiles.WriteAll(DirectoryFileName, LBytes);
end;

class procedure TGreedSaveGames.AdjustScroll(var APlayer: TGreedPlayerRecord; ALowResolution: Boolean);
var
  LScroll: Integer;
begin
  LScroll := APlayer.ScrollMax - APlayer.ScrollMin;
  if ALowResolution then
  begin
    if LScroll > 200 then
    begin
      APlayer.ScrollMin := APlayer.ScrollMin div 2;
      APlayer.ScrollMax := APlayer.ScrollMin + 200;
    end;
  end
  else if LScroll <= 200 then
  begin
    APlayer.ScrollMin := APlayer.ScrollMin * 2;
    APlayer.ScrollMax := APlayer.ScrollMin + 400;
  end;
end;

end.
