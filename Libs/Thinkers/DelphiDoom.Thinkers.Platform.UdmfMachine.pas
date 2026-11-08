{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the scripted platforms                       }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Platform.UdmfMachine;

// The heights are fixed point: the old code let the products wrap and so does this one
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Thinkers.Platform.Types,
  DelphiDoom.Thinkers.Platform.Intf;

type
  /// <summary>
  ///   The platforms of the scripted specials (TH_PlatRaise and the type switch of EVH_DoPlat of
  ///   udmf_plats): the same for Hexen and for the UDMF maps of the other games. As the classic
  ///   machine it works on a copy of the fields of the thinker, which stays a record of the engine
  /// </summary>
  TUdmfPlatMachine = class(TInterfacedObject, IUdmfPlatMachine)
  strict private
    FHost: IPlatHost;
    FSurroundings: IPlatSurroundings;
    FRandom: IGameRandom;
    procedure LowerTo(ASector: Pointer; ALow, AWait: Integer; var AState: TPlatState);
    procedure RaiseTo(ASector: Pointer; AHigh, AWait: Integer; var AState: TPlatState);
    procedure Perpetual(ASector: Pointer; ALowOffset, AWait: Integer; var AState: TPlatState);
  public
    /// <exception cref="EArgumentNilException">A service is nil</exception>
    constructor Create(const AHost: IPlatHost; const ASurroundings: IPlatSurroundings;
      const ARandom: IGameRandom);
    procedure Configure(ASector: Pointer; AKind: TUdmfPlatKind; ATag, ASpeedArgument,
      AWaitArgument, AAmountArgument: Integer; var AState: TPlatState);
    procedure Tick(APlat, ASector: Pointer; AKind: TUdmfPlatKind; var AState: TPlatState);
    procedure AnnounceStart(ASector: Pointer);
  end;

implementation

uses
  System.SysUtils;

const
  /// <summary>The lip of the kinds that do not have one as an argument: 8 units</summary>
  DEFAULT_LIP = 8 * PLAT_FRACUNIT;

{ TUdmfPlatMachine }

constructor TUdmfPlatMachine.Create(const AHost: IPlatHost; const ASurroundings: IPlatSurroundings;
  const ARandom: IGameRandom);
begin
  inherited Create;
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  if not Assigned(ASurroundings) then
    raise EArgumentNilException.Create('ASurroundings');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  FHost := AHost;
  FSurroundings := ASurroundings;
  FRandom := ARandom;
end;

procedure TUdmfPlatMachine.AnnounceStart(ASector: Pointer);
begin
  FHost.PlaySound(ASector, TPlatSound.Start);
end;

procedure TUdmfPlatMachine.Tick(APlat, ASector: Pointer; AKind: TUdmfPlatKind;
  var AState: TPlatState);
var
  LResult: TPlatMoveResult;
begin
  case AState.Status of
    TPlatStatus.Up:
      begin
        LResult := FHost.MovePlane(ASector, AState.Speed, AState.High, AState.Crush,
          PLAT_DIRECTION_UP);
        if (LResult = TPlatMoveResult.Crushed) and not AState.Crush then
        begin
          AState.Count := AState.Wait;
          AState.Status := TPlatStatus.Down;
          FHost.PlaySound(ASector, TPlatSound.Start);
        end
        else if LResult = TPlatMoveResult.PastDestination then
        begin
          AState.Count := AState.Wait;
          AState.Status := TPlatStatus.Waiting;
          FHost.PlaySound(ASector, TPlatSound.Stop);
          if AKind in [TUdmfPlatKind.DownWaitUpStay, TUdmfPlatKind.DownByValueWaitUpStay,
            TUdmfPlatKind.DownWaitUpStayLip] then
            FHost.RemovePlat(APlat);
        end;
      end;

    TPlatStatus.Down:
      begin
        LResult := FHost.MovePlane(ASector, AState.Speed, AState.Low, False, PLAT_DIRECTION_DOWN);
        if LResult = TPlatMoveResult.PastDestination then
        begin
          AState.Count := AState.Wait;
          AState.Status := TPlatStatus.Waiting;
          // the removal comes before the sound: the sector is still there for it
          if AKind in [TUdmfPlatKind.UpWaitDownStay, TUdmfPlatKind.UpByValueWaitDownStay,
            TUdmfPlatKind.UpNearestWaitDownStay] then
            FHost.RemovePlat(APlat);
          FHost.PlaySound(ASector, TPlatSound.Stop);
        end;
      end;

    TPlatStatus.Waiting:
      begin
        AState.Count := AState.Count - 1;
        if AState.Count <= 0 then
        begin
          if FHost.GetFloorHeight(ASector) = AState.Low then
            AState.Status := TPlatStatus.Up
          else
            AState.Status := TPlatStatus.Down;
          FHost.PlaySound(ASector, TPlatSound.Start);
        end;
      end;
  end;
end;

procedure TUdmfPlatMachine.LowerTo(ASector: Pointer; ALow, AWait: Integer;
  var AState: TPlatState);
var
  LFloor: Integer;
begin
  LFloor := FSurroundings.GetFloorHeight(ASector);
  AState.Low := ALow;
  if AState.Low > LFloor then
    AState.Low := LFloor;
  AState.High := LFloor;
  AState.Wait := AWait;
  AState.Status := TPlatStatus.Down;
end;

procedure TUdmfPlatMachine.RaiseTo(ASector: Pointer; AHigh, AWait: Integer; var AState: TPlatState);
var
  LFloor: Integer;
begin
  LFloor := FSurroundings.GetFloorHeight(ASector);
  AState.High := AHigh;
  if AState.High < LFloor then
    AState.High := LFloor;
  AState.Low := LFloor;
  AState.Wait := AWait;
  AState.Status := TPlatStatus.Up;
end;

procedure TUdmfPlatMachine.Perpetual(ASector: Pointer; ALowOffset, AWait: Integer;
  var AState: TPlatState);
var
  LFloor: Integer;
begin
  LFloor := FSurroundings.GetFloorHeight(ASector);
  AState.Low := FSurroundings.LowestFloorSurrounding(ASector) + ALowOffset;
  if AState.Low > LFloor then
    AState.Low := LFloor;
  AState.High := FSurroundings.HighestFloorSurrounding(ASector);
  if AState.High < LFloor then
    AState.High := LFloor;
  AState.Wait := AWait;
  if (FRandom.NextPlay and 1) = 0 then
    AState.Status := TPlatStatus.Up
  else
    AState.Status := TPlatStatus.Down;
end;

procedure TUdmfPlatMachine.Configure(ASector: Pointer; AKind: TUdmfPlatKind; ATag, ASpeedArgument,
  AWaitArgument, AAmountArgument: Integer; var AState: TPlatState);
var
  LFloor: Integer;
begin
  LFloor := FSurroundings.GetFloorHeight(ASector);
  AState.Crush := False;
  AState.Tag := ATag;
  AState.Speed := ASpeedArgument * (PLAT_FRACUNIT div 8);

  case AKind of
    TUdmfPlatKind.DownWaitUpStay:
      LowerTo(ASector, FSurroundings.LowestFloorSurrounding(ASector) + DEFAULT_LIP,
        AWaitArgument, AState);
    TUdmfPlatKind.DownWaitUpStayLip:
      LowerTo(ASector, FSurroundings.LowestFloorSurrounding(ASector)
        + AAmountArgument * PLAT_FRACUNIT, AWaitArgument, AState);
    TUdmfPlatKind.DownByValueWaitUpStay:
      LowerTo(ASector, LFloor - AAmountArgument * 8 * PLAT_FRACUNIT, AWaitArgument, AState);
    TUdmfPlatKind.UpWaitDownStay:
      RaiseTo(ASector, FSurroundings.HighestFloorSurrounding(ASector), AWaitArgument, AState);
    TUdmfPlatKind.UpNearestWaitDownStay:
      RaiseTo(ASector, FSurroundings.NextHighestFloor(ASector, LFloor), AWaitArgument, AState);
    TUdmfPlatKind.UpByValueWaitDownStay:
      RaiseTo(ASector, LFloor + AAmountArgument * 8 * PLAT_FRACUNIT, AWaitArgument, AState);
    TUdmfPlatKind.PerpetualRaise:
      Perpetual(ASector, DEFAULT_LIP, AWaitArgument, AState);
    TUdmfPlatKind.PerpetualRaiseLip:
      Perpetual(ASector, AAmountArgument * PLAT_FRACUNIT, AWaitArgument, AState);
  end;
end;

end.
