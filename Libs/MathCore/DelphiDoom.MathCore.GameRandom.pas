{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the random numbers of the game              }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.GameRandom;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.MathCore.Intf,
  DelphiDoom.MathCore.IntegerStack;

type
  /// <summary>
  ///   The tables and the indexes of the old m_rnd, with the state in the object. Needs a source
  ///   of unpredictable numbers only for NextUnpredictable.
  /// </summary>
  TGameRandom = class(TInterfacedObject, IGameRandom)
  private
    FEntropy: IEntropySource;
    FSavedPlayIndexes: TIntegerStack;
    FMenuIndex: Integer;
    FPlayIndex: Integer;
    FNonCompatibleIndex: Integer;
    FSystemIndex: Integer;
    FSystemSeed: Integer;
  public
    constructor Create(const AEntropy: IEntropySource);
    destructor Destroy; override;
    function NextMenu: Integer;
    function NextPlay: Integer;
    function NextNonCompatible: Integer;
    function NextUnpredictable: Integer;
    function NextSystem: Integer;
    function NextWithIndex(var AIndex: Integer): Integer;
    function FromSeed(const ASeed: Integer): Integer;
    procedure Clear;
    procedure SavePlayIndex;
    function RestorePlayIndex: Boolean;
    function HitscanAngle(const ASpread: TFixed): Integer;
    function HitscanSlope(const ASpread: TFixed): Integer;
    function GetMenuIndex: Integer;
    procedure SetMenuIndex(const AValue: Integer);
    function GetPlayIndex: Integer;
    procedure SetPlayIndex(const AValue: Integer);
    function GetNonCompatibleIndex: Integer;
    procedure SetNonCompatibleIndex(const AValue: Integer);
    function GetSystemIndex: Integer;
    procedure SetSystemIndex(const AValue: Integer);
    function GetSystemSeed: Integer;
    procedure SetSystemSeed(const AValue: Integer);
  end;

implementation

uses
  DelphiDoom.MathCore.Trigonometry, DelphiDoom.MathCore.TableRandom,
  DelphiDoom.MathCore.TableSysRandom;

const
  SYS_RANDOM_SIZE = 10007;

resourcestring
  SSystemIndexOutOfRange = 'The index of the system random is out of the table';

{ TGameRandom }

constructor TGameRandom.Create(const AEntropy: IEntropySource);
begin
  inherited Create;
  FEntropy := AEntropy;
  FSavedPlayIndexes := TIntegerStack.Create;
end;

destructor TGameRandom.Destroy;
begin
  FSavedPlayIndexes.Free;
  inherited Destroy;
end;

function TGameRandom.NextMenu: Integer;
begin
  FMenuIndex := (FMenuIndex + 1) and $FF;
  Result := RANDOM_TABLE[FMenuIndex];
end;

function TGameRandom.NextPlay: Integer;
begin
  FPlayIndex := (FPlayIndex + 1) and $FF;
  Result := RANDOM_TABLE[FPlayIndex];
end;

function TGameRandom.NextNonCompatible: Integer;
begin
  FNonCompatibleIndex := (FNonCompatibleIndex + 1) and $FF;
  Result := RANDOM_TABLE[FNonCompatibleIndex];
end;

function TGameRandom.NextUnpredictable: Integer;
begin
  Result := FEntropy.Next(256);
end;

function TGameRandom.NextSystem: Integer;
begin
  FSystemIndex := FSystemIndex + FSystemSeed + 1;
  if FSystemIndex >= SYS_RANDOM_SIZE then
    FSystemIndex := FSystemIndex - SYS_RANDOM_SIZE;
  // the old code read outside the table here
  if (FSystemIndex < 0) or (FSystemIndex >= SYS_RANDOM_SIZE) then
    raise EMathCoreException.Create(SSystemIndexOutOfRange);
  Result := SYS_RANDOM_TABLE[FSystemIndex];
end;

function TGameRandom.NextWithIndex(var AIndex: Integer): Integer;
begin
  AIndex := (AIndex + 1) and $FF;
  Result := RANDOM_TABLE[AIndex];
end;

function TGameRandom.FromSeed(const ASeed: Integer): Integer;
begin
  Result := RANDOM_TABLE[ASeed and $FF];
end;

procedure TGameRandom.Clear;
begin
  FMenuIndex := 0;
  FPlayIndex := 0;
  FNonCompatibleIndex := 0;
  FSystemIndex := 0;
  FSavedPlayIndexes.Clear;
end;

procedure TGameRandom.SavePlayIndex;
begin
  FSavedPlayIndexes.Push(FPlayIndex);
end;

function TGameRandom.RestorePlayIndex: Boolean;
begin
  Result := FSavedPlayIndexes.Pop(FPlayIndex);
end;

function TGameRandom.HitscanAngle(const ASpread: TFixed): Integer;
var
  LFirst: Integer;
  LSpreadBam: Double;
begin
  // FixedToAngle does not work for negative numbers: take the absolute value
  if ASpread < 0 then
    LSpreadBam := TTrigonometry.FixedToAngle(-ASpread)
  else
    LSpreadBam := TTrigonometry.FixedToAngle(ASpread);
  LFirst := NextNonCompatible;
  Result := Round((LSpreadBam * (LFirst - NextNonCompatible)) / 255);
end;

function TGameRandom.HitscanSlope(const ASpread: TFixed): Integer;
begin
  Result := TTrigonometry.AngleToSlope(HitscanAngle(ASpread));
end;

function TGameRandom.GetMenuIndex: Integer;
begin
  Result := FMenuIndex;
end;

procedure TGameRandom.SetMenuIndex(const AValue: Integer);
begin
  FMenuIndex := AValue;
end;

function TGameRandom.GetPlayIndex: Integer;
begin
  Result := FPlayIndex;
end;

procedure TGameRandom.SetPlayIndex(const AValue: Integer);
begin
  FPlayIndex := AValue;
end;

function TGameRandom.GetNonCompatibleIndex: Integer;
begin
  Result := FNonCompatibleIndex;
end;

procedure TGameRandom.SetNonCompatibleIndex(const AValue: Integer);
begin
  FNonCompatibleIndex := AValue;
end;

function TGameRandom.GetSystemIndex: Integer;
begin
  Result := FSystemIndex;
end;

procedure TGameRandom.SetSystemIndex(const AValue: Integer);
begin
  FSystemIndex := AValue;
end;

function TGameRandom.GetSystemSeed: Integer;
begin
  Result := FSystemSeed;
end;

procedure TGameRandom.SetSystemSeed(const AValue: Integer);
begin
  FSystemSeed := AValue;
end;

end.
