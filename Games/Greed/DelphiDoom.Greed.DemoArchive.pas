{******************************************************************************}
{                                                                              }
{  Greed32: the archive of a demo, for the game of the full version            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.DemoArchive;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   The GREED.BLO of a demo does not have every lump that the game of the full version names (monsters,
  ///   weapons, items: the demo was another program, with shorter tables). The original, made for the full game,
  ///   stops at the first name that it does not find. Behind this archive a name that is not there is the lump
  ///   after the last one, which is empty: the game goes on, and what should have had that picture is not drawn
  ///   (a monster of the full game that the demo does not have is in the level, and is not seen)
  /// </summary>
  TGreedDemoArchive = class(TInterfacedObject, IGreedArchive)
  strict private
    FArchive: IGreedArchive;
    function Inside(AIndex: Integer): Boolean;
  public
    /// <summary>EArgumentNilException if AArchive is nil</summary>
    constructor Create(const AArchive: IGreedArchive);
    function GetLumpCount: Integer;
    function GetLumpInfo(AIndex: Integer): TGreedLumpInfo;
    function GetLumpName(AIndex: Integer): string;
    function GetLumpSize(AIndex: Integer): Integer;
    function IndexOf(const AName: string): Integer;
    function RequireIndexOf(const AName: string): Integer;
    function ReadLump(AIndex: Integer): TBytes;
    function ReadLumpRaw(AIndex: Integer): TBytes;
  end;

implementation

{ TGreedDemoArchive }

constructor TGreedDemoArchive.Create(const AArchive: IGreedArchive);
begin
  inherited Create;
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  FArchive := AArchive;
end;

function TGreedDemoArchive.Inside(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < FArchive.LumpCount);
end;

function TGreedDemoArchive.GetLumpCount: Integer;
begin
  Result := FArchive.LumpCount;
end;

function TGreedDemoArchive.GetLumpInfo(AIndex: Integer): TGreedLumpInfo;
begin
  if Inside(AIndex) then
    Result := FArchive.GetLumpInfo(AIndex)
  else
    Result := Default(TGreedLumpInfo);
end;

function TGreedDemoArchive.GetLumpName(AIndex: Integer): string;
begin
  if Inside(AIndex) then
    Result := FArchive.GetLumpName(AIndex)
  else
    Result := '';
end;

function TGreedDemoArchive.GetLumpSize(AIndex: Integer): Integer;
begin
  if Inside(AIndex) then
    Result := FArchive.GetLumpSize(AIndex)
  else
    Result := 0;
end;

function TGreedDemoArchive.IndexOf(const AName: string): Integer;
begin
  Result := FArchive.IndexOf(AName);
end;

function TGreedDemoArchive.RequireIndexOf(const AName: string): Integer;
begin
  Result := FArchive.IndexOf(AName);
  if Result < 0 then
    Result := FArchive.LumpCount;
end;

function TGreedDemoArchive.ReadLump(AIndex: Integer): TBytes;
begin
  if Inside(AIndex) then
    Result := FArchive.ReadLump(AIndex)
  else
    Result := nil;
end;

function TGreedDemoArchive.ReadLumpRaw(AIndex: Integer): TBytes;
begin
  if Inside(AIndex) then
    Result := FArchive.ReadLumpRaw(AIndex)
  else
    Result := nil;
end;

end.
