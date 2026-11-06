{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - cache of the lumps already read                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.LumpCache;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Wad.Intf;

type
  /// <summary>
  ///   Keeps the lumps already read. Static lumps stay until they are
  ///   released, Cache lumps until Purge (the engine calls it when it needs
  ///   memory). The reader is given by the constructor
  /// </summary>
  TLumpCache = class(TInterfacedObject, ILumpCache)
  private
    FReader: ILumpReader;
    FStatic: TDictionary<Integer, TBytes>;
    FCache: TDictionary<Integer, TBytes>;
  public
    constructor Create(const AReader: ILumpReader);
    destructor Destroy; override;
    function GetCachedCount: Integer;
    function Lump(ALump: Integer; ALevel: TLumpCacheLevel): TBytes;
    procedure Release(ALump: Integer);
    procedure Purge;
    procedure Clear;
  end;

implementation

{ TLumpCache }

constructor TLumpCache.Create(const AReader: ILumpReader);
begin
  inherited Create;
  if AReader = nil then
    raise EArgumentNilException.Create('AReader');
  FReader := AReader;
  FStatic := TDictionary<Integer, TBytes>.Create;
  FCache := TDictionary<Integer, TBytes>.Create;
end;

destructor TLumpCache.Destroy;
begin
  FCache.Free;
  FStatic.Free;
  inherited Destroy;
end;

function TLumpCache.GetCachedCount: Integer;
begin
  Result := FStatic.Count + FCache.Count;
end;

function TLumpCache.Lump(ALump: Integer; ALevel: TLumpCacheLevel): TBytes;
begin
  if FStatic.TryGetValue(ALump, Result) then
    Exit;
  if FCache.TryGetValue(ALump, Result) then
  begin
    // asked as Static now: it must not be purged
    if ALevel = TLumpCacheLevel.Static then
    begin
      FCache.Remove(ALump);
      FStatic.Add(ALump, Result);
    end;
    Exit;
  end;
  Result := FReader.ReadLump(ALump);
  if ALevel = TLumpCacheLevel.Static then
    FStatic.Add(ALump, Result)
  else
    FCache.Add(ALump, Result);
end;

procedure TLumpCache.Release(ALump: Integer);
begin
  FStatic.Remove(ALump);
  FCache.Remove(ALump);
end;

procedure TLumpCache.Purge;
begin
  FCache.Clear;
end;

procedure TLumpCache.Clear;
begin
  FStatic.Clear;
  FCache.Clear;
end;

end.
