{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the list of the keys of actors                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  It is TActorKeyList of psi_game.pas without the scans of the thinkers: the  }
{  engine walks the actors and adds their keys (IScriptActorSource.Collect).   }
{  The order of the keys is the one that scripts have always seen: looking     }
{  for a key (Exists, and so Add without duplicates) moves it to the front     }
{  unless it is the first.                                                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Actors.KeyList;

interface

type
  /// <summary>A list of keys of actors, without duplicates unless AllowDuplicates is set</summary>
  TScriptActorKeyList = class(TObject)
  strict private
    FKeys: TArray<Cardinal>;
    FCount: Integer;
    FAllowDuplicates: Boolean;
    function GetCount: Integer;
    function GetKey(const AIndex: Integer): Cardinal;
    procedure SetKey(const AIndex: Integer; const AValue: Cardinal);
    procedure SetAllowDuplicates(const AValue: Boolean);
  public
    constructor Create;
    /// <summary>Adds a key; with no duplicates a key that is already there is not added twice</summary>
    procedure Add(const AKey: Cardinal);
    /// <summary>Removes a key (all its copies if there are duplicates); false if it was not there</summary>
    function Delete(const AKey: Cardinal): Boolean;
    /// <summary>True if the key is in the list; the key found goes to the front (a swap with the first key)</summary>
    function Exists(const AKey: Cardinal): Boolean;
    procedure Clear;
    /// <summary>The keys, in the order of the list</summary>
    function ToArray: TArray<Cardinal>;
    property Count: Integer read GetCount;
    /// <summary>The key at the index, SCRIPT_INVALID_ID outside of the list (setting it outside does nothing)</summary>
    property Keys[const AIndex: Integer]: Cardinal read GetKey write SetKey; default;
    /// <summary>
    ///   False (the default): a key is in the list once. Turning it on keeps the keys; turning it off
    ///   removes the copies, keeping the first of each key
    /// </summary>
    property AllowDuplicates: Boolean read FAllowDuplicates write SetAllowDuplicates;
  end;

implementation

uses
  DelphiDoom.ScriptHost.World.Intf;

{ TScriptActorKeyList }

constructor TScriptActorKeyList.Create;
begin
  inherited Create;
  FCount := 0;
  FAllowDuplicates := False;
end;

function TScriptActorKeyList.GetCount: Integer;
begin
  Result := FCount;
end;

function TScriptActorKeyList.GetKey(const AIndex: Integer): Cardinal;
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    Result := SCRIPT_INVALID_ID
  else
    Result := FKeys[AIndex];
end;

procedure TScriptActorKeyList.SetKey(const AIndex: Integer; const AValue: Cardinal);
begin
  if (AIndex >= 0) and (AIndex < FCount) then
    FKeys[AIndex] := AValue;
end;

procedure TScriptActorKeyList.Add(const AKey: Cardinal);
var
  LCapacity: Integer;
begin
  if not FAllowDuplicates then
    if Exists(AKey) then
      Exit;
  if FCount >= Length(FKeys) then
  begin
    // the growth of the old list: small steps first (the order of the keys does not depend on it)
    LCapacity := Length(FKeys);
    if LCapacity < 16 then
      Inc(LCapacity, 4)
    else if LCapacity < 128 then
      Inc(LCapacity, 16)
    else
      Inc(LCapacity, 128);
    SetLength(FKeys, LCapacity);
  end;
  FKeys[FCount] := AKey;
  Inc(FCount);
end;

function TScriptActorKeyList.Delete(const AKey: Cardinal): Boolean;
var
  LIndex: Integer;
  LKept: Integer;
begin
  if FCount = 0 then
  begin
    Result := False;
    Exit;
  end;
  if not FAllowDuplicates then
  begin
    Result := False;
    // the last key takes the place of the one that goes away
    for LIndex := 0 to FCount - 1 do
      if FKeys[LIndex] = AKey then
      begin
        FKeys[LIndex] := FKeys[FCount - 1];
        Dec(FCount);
        Result := True;
        Exit;
      end;
    Exit;
  end;
  // looking for the key moves it to the front, as it always did
  Result := Exists(AKey);
  if not Result then
    Exit;
  LKept := 0;
  for LIndex := 0 to FCount - 1 do
    if FKeys[LIndex] <> AKey then
    begin
      FKeys[LKept] := FKeys[LIndex];
      Inc(LKept);
    end;
  FCount := LKept;
end;

function TScriptActorKeyList.Exists(const AKey: Cardinal): Boolean;
var
  LIndex: Integer;
  LFirst: Cardinal;
begin
  for LIndex := 0 to FCount - 1 do
    if FKeys[LIndex] = AKey then
    begin
      if LIndex > 0 then
      begin
        LFirst := FKeys[0];
        FKeys[0] := FKeys[LIndex];
        FKeys[LIndex] := LFirst;
      end;
      Result := True;
      Exit;
    end;
  Result := False;
end;

procedure TScriptActorKeyList.Clear;
begin
  FKeys := nil;
  FCount := 0;
end;

procedure TScriptActorKeyList.SetAllowDuplicates(const AValue: Boolean);
var
  LCopy: TArray<Cardinal>;
  LCopied: Integer;
  LIndex: Integer;
begin
  if FAllowDuplicates = AValue then
    Exit;
  FAllowDuplicates := AValue;
  if AValue or (FCount < 2) then
    Exit;
  // the old code emptied the list here (its loop ran over the count after it was zeroed); the
  // property was never given to scripts, so nothing could see it
  LCopy := Copy(FKeys, 0, FCount);
  LCopied := FCount;
  FCount := 0;
  for LIndex := 0 to LCopied - 1 do
    Add(LCopy[LIndex]);
end;

function TScriptActorKeyList.ToArray: TArray<Cardinal>;
begin
  Result := Copy(FKeys, 0, FCount);
end;

end.
