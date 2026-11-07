{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the automap library - the scenarios of parity          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.Scenarios;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Automap.Types, DelphiDoom.Tests.Automap.Fingerprint;

type
  /// <summary>
  ///   What a scenario needs from an automap: the temporary harness implements it on the old code
  ///   of am_map (globals), the tests on the library. The scenarios are the same on both sides, so
  ///   the inputs are identical and only the answers are compared.
  /// </summary>
  IAutomapDriver = interface
    ['{A3C5E7F9-1B2D-4E6F-8A0C-2D4F6A8C0E1B}']
    procedure SetFrame(const AX, AY, AWidth, AHeight: Integer);
    procedure FitVertices(const AVertices: TArray<TAutomapPoint>);
    procedure InitializeScale;
    procedure StartWindow(const AHasPlayer: Boolean; const APlayerX, APlayerY: Integer);
    procedure SetPan(const AX, AY: Integer);
    procedure SetZoom(const AMapToFrame, AFrameToMap: Integer);
    procedure SetFollow(const AValue: Boolean);
    procedure ForgetPlayerLocation;
    procedure Tick(const APlayerX, APlayerY: Integer);
    procedure CenterOnPlayer(const APlayerX, APlayerY: Integer);
    procedure SaveScaleAndLocation;
    procedure RestoreScaleAndLocation(const APlayerX, APlayerY: Integer);
    procedure MinOut;
    procedure MaxOut;
    function FrameToMap(const AValue: Integer): Integer;
    function MapToFrame(const AValue: Integer): Integer;
    function MapToFrameX(const AValue: Integer): Integer;
    function MapToFrameY(const AValue: Integer): Integer;
    function Clip(const AMapLine: TAutomapLine; var AFrameLine: TAutomapFrameLine): Boolean;
    procedure Rotate(var AX, AY: Integer; const AAngle: Cardinal; const ACenterX, ACenterY: Integer);
    procedure RotateExact(var AX, AY: Integer; const AAngle: Cardinal; const ACenterX, ACenterY: Integer);
    procedure AddMarkAtCenter;
    procedure ClearMarks;
    /// <summary>The next index and then x and y of each of the marks</summary>
    function MarkValues: TArray<Integer>;
    /// <summary>
    ///   FrameX, FrameY, FrameWidth, FrameHeight, MapX, MapY, MapX2, MapY2, MapWidth, MapHeight,
    ///   ScaleMapToFrame, ScaleFrameToMap, PanX, PanY, ZoomMapToFrame, ZoomFrameToMap, MinScale,
    ///   MaxScale, Follow (0 or 1)
    /// </summary>
    function Snapshot: TArray<Integer>;
    function ZoomIn: Integer;
    function ZoomOut: Integer;
  end;

  /// <summary>The scenarios: each gives the fingerprint of every answer of a driver</summary>
  TAutomapScenarios = class
  strict private
    FDriver: IAutomapDriver;
    FSeed: Cardinal;
    function NextRandom: Cardinal;
    function RandomBetween(const AMinimum, AMaximum: Integer): Integer;
    function RandomLevel(const ARange: Integer): TArray<TAutomapPoint>;
    procedure Prepare(const AFrameChoice: Integer; const ARange: Integer);
    procedure AddSnapshot(const AFingerprint: TFingerprint);
  public
    constructor Create(const ADriver: IAutomapDriver);
    /// <summary>The names of the scenarios</summary>
    class function Names: TArray<string>; static;
    /// <summary>The fingerprint (hex/count) of a scenario</summary>
    function Run(const AName: string): string;
  end;

implementation

uses
  System.SysUtils;

const
  FRAMES: array[0..4, 0..1] of Integer = (
    (320, 168), (640, 336), (1024, 600), (800, 480), (1920, 1020)
  );
  RANGES: array[0..2] of Integer = (2048, 4096, 8192);

{ TAutomapScenarios }

constructor TAutomapScenarios.Create(const ADriver: IAutomapDriver);
begin
  inherited Create;
  FDriver := ADriver;
  FSeed := $2545F491;
end;

class function TAutomapScenarios.Names: TArray<string>;
begin
  Result := TArray<string>.Create('constants', 'transform', 'bounds', 'navigation', 'marks',
    'clip', 'clipedges', 'rotate', 'rotateexact');
end;

function TAutomapScenarios.NextRandom: Cardinal;
begin
  // xorshift32 with a fixed seed
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := FSeed;
end;

function TAutomapScenarios.RandomBetween(const AMinimum, AMaximum: Integer): Integer;
begin
  Result := AMinimum + Integer(NextRandom mod Cardinal(AMaximum - AMinimum + 1));
end;

// The first vertex is in the middle, the second is the top right corner and the third the bottom
// left one: the old search of the limits lost a first vertex that was the biggest (see the
// regression test of the library), so the levels of the parity never depend on it
function TAutomapScenarios.RandomLevel(const ARange: Integer): TArray<TAutomapPoint>;
var
  LCount: Integer;
  LIndex: Integer;
  LRange: Integer;
begin
  LRange := ARange * 65536;
  LCount := RandomBetween(3, 400);
  SetLength(Result, LCount);
  Result[0].X := RandomBetween(-LRange div 8, LRange div 8);
  Result[0].Y := RandomBetween(-LRange div 8, LRange div 8);
  Result[1].X := RandomBetween(LRange div 2, LRange);
  Result[1].Y := RandomBetween(LRange div 2, LRange);
  Result[2].X := RandomBetween(-LRange, -LRange div 2);
  Result[2].Y := RandomBetween(-LRange, -LRange div 2);
  for LIndex := 3 to LCount - 1 do
  begin
    Result[LIndex].X := RandomBetween(Result[2].X, Result[1].X);
    Result[LIndex].Y := RandomBetween(Result[2].Y, Result[1].Y);
  end;
end;

procedure TAutomapScenarios.Prepare(const AFrameChoice: Integer; const ARange: Integer);
var
  LLevel: TArray<TAutomapPoint>;
begin
  FDriver.SetFrame(0, 0, FRAMES[AFrameChoice, 0], FRAMES[AFrameChoice, 1]);
  LLevel := RandomLevel(ARange);
  FDriver.FitVertices(LLevel);
  FDriver.InitializeScale;
  FDriver.StartWindow(True, LLevel[0].X, LLevel[0].Y);
end;

procedure TAutomapScenarios.AddSnapshot(const AFingerprint: TFingerprint);
var
  LValues: TArray<Integer>;
  LValue: Integer;
begin
  LValues := FDriver.Snapshot;
  for LValue in LValues do
    AFingerprint.AddInteger(LValue);
end;

function TAutomapScenarios.Run(const AName: string): string;
var
  LPrint: TFingerprint;
  LRound: Integer;
  LStep: Integer;
  LValue: Integer;
  LValues: TArray<Integer>;
  LSnapshot: TArray<Integer>;
  LLine: TAutomapLine;
  LFrame: TAutomapFrameLine;
  LX, LY: Integer;
  LPlayerX, LPlayerY: Integer;
  LAngle: Cardinal;
  LCenterX, LCenterY: Integer;
  LPan: Integer;
  LLevel: TArray<TAutomapPoint>;
  LEdges: TArray<Integer>;
  LEdgeA, LEdgeB, LEdgeC, LEdgeD: Integer;
  LEdgesY: TArray<Integer>;
begin
  FSeed := $2545F491;
  LPrint := TFingerprint.Create;
  try
    if AName = 'constants' then
    begin
      LPrint.AddInteger(FDriver.ZoomIn);
      LPrint.AddInteger(FDriver.ZoomOut);
    end
    else if AName = 'transform' then
    begin
      for LRound := 1 to 60 do
      begin
        Prepare(LRound mod 5, RANGES[LRound mod 3]);
        AddSnapshot(LPrint);
        for LStep := 1 to 400 do
        begin
          LValue := RandomBetween(-300000000, 300000000);
          if LStep mod 3 = 0 then
            LValue := RandomBetween(-50000, 50000);
          LPrint.AddInteger(FDriver.MapToFrame(LValue));
          LPrint.AddInteger(FDriver.MapToFrameX(LValue));
          LPrint.AddInteger(FDriver.MapToFrameY(LValue));
          LValue := RandomBetween(-4000, 4000);
          LPrint.AddInteger(FDriver.FrameToMap(LValue));
        end;
      end;
    end
    else if AName = 'bounds' then
    begin
      for LRound := 1 to 300 do
      begin
        Prepare(LRound mod 5, RANGES[LRound mod 3]);
        AddSnapshot(LPrint);
      end;
    end
    else if AName = 'navigation' then
    begin
      for LRound := 1 to 40 do
      begin
        LLevel := RandomLevel(RANGES[LRound mod 3]);
        FDriver.SetFrame(0, 0, FRAMES[LRound mod 5, 0], FRAMES[LRound mod 5, 1]);
        FDriver.FitVertices(LLevel);
        FDriver.InitializeScale;
        LPlayerX := LLevel[0].X;
        LPlayerY := LLevel[0].Y;
        FDriver.StartWindow(True, LPlayerX, LPlayerY);
        AddSnapshot(LPrint);
        for LStep := 1 to 1500 do
        begin
          LPlayerX := LPlayerX + RandomBetween(-300000, 300000);
          LPlayerY := LPlayerY + RandomBetween(-300000, 300000);
          LPan := FDriver.FrameToMap(4);
          case NextRandom mod 17 of
            0: FDriver.SetZoom(FDriver.ZoomIn, FDriver.ZoomOut);
            1: FDriver.SetZoom(FDriver.ZoomOut, FDriver.ZoomIn);
            2: FDriver.SetZoom(65536, 65536);
            3: FDriver.SetPan(LPan, 0);
            4: FDriver.SetPan(-LPan, LPan);
            5: FDriver.SetPan(0, 0);
            6:
              begin
                FDriver.SetFollow(NextRandom mod 2 = 0);
                FDriver.ForgetPlayerLocation;
              end;
            7, 8, 9: FDriver.Tick(LPlayerX, LPlayerY);
            10: FDriver.CenterOnPlayer(LPlayerX, LPlayerY);
            11: FDriver.SaveScaleAndLocation;
            12: FDriver.RestoreScaleAndLocation(LPlayerX, LPlayerY);
            13: FDriver.MinOut;
            14: FDriver.MaxOut;
            15: FDriver.StartWindow(NextRandom mod 4 <> 0, LPlayerX, LPlayerY);
            16: FDriver.Tick(LPlayerX, LPlayerY);
          end;
          AddSnapshot(LPrint);
        end;
      end;
    end
    else if AName = 'marks' then
    begin
      Prepare(1, 4096);
      for LStep := 1 to 3000 do
      begin
        case NextRandom mod 9 of
          0: FDriver.ClearMarks;
          1: FDriver.SetPan(FDriver.FrameToMap(4), 0);
          2:
            begin
              FDriver.SetPan(0, 0);
              FDriver.Tick(RandomBetween(-100000000, 100000000), RandomBetween(-100000000, 100000000));
            end;
        else
          FDriver.AddMarkAtCenter;
          FDriver.SetPan(RandomBetween(-300, 300) * 4096, RandomBetween(-300, 300) * 4096);
          FDriver.SetFollow(False);
          FDriver.Tick(0, 0);
        end;
        LValues := FDriver.MarkValues;
        for LValue in LValues do
          LPrint.AddInteger(LValue);
      end;
    end
    else if (AName = 'clip') or (AName = 'clipedges') then
    begin
      for LRound := 1 to 30 do
      begin
        Prepare(LRound mod 5, RANGES[LRound mod 3]);
        if LRound mod 2 = 0 then
          FDriver.MinOut;
        LSnapshot := FDriver.Snapshot;
        // the corners of the window on the map, and its size
        if AName = 'clip' then
        begin
          for LStep := 1 to 1500 do
          begin
            LLine.A.X := RandomBetween(LSnapshot[4] - LSnapshot[8], LSnapshot[6] + LSnapshot[8]);
            LLine.A.Y := RandomBetween(LSnapshot[5] - LSnapshot[9], LSnapshot[7] + LSnapshot[9]);
            LLine.B.X := RandomBetween(LSnapshot[4] - LSnapshot[8], LSnapshot[6] + LSnapshot[8]);
            LLine.B.Y := RandomBetween(LSnapshot[5] - LSnapshot[9], LSnapshot[7] + LSnapshot[9]);
            if LStep mod 5 = 0 then
            begin
              // short lines near the window
              LLine.B.X := LLine.A.X + RandomBetween(-2000, 2000);
              LLine.B.Y := LLine.A.Y + RandomBetween(-2000, 2000);
            end;
            LFrame.A.X := 0; LFrame.A.Y := 0; LFrame.B.X := 0; LFrame.B.Y := 0;
            try
              if FDriver.Clip(LLine, LFrame) then
              begin
                LPrint.AddBoolean(True);
                LPrint.AddInteger(LFrame.A.X);
                LPrint.AddInteger(LFrame.A.Y);
                LPrint.AddInteger(LFrame.B.X);
                LPrint.AddInteger(LFrame.B.Y);
              end
              else
                LPrint.AddBoolean(False);
            except
              LPrint.AddException;
            end;
          end;
        end
        else
        begin
          // every combination of the limits of the window (and one over, one under) as ends
          LEdges := TArray<Integer>.Create(LSnapshot[4] - 1, LSnapshot[4], LSnapshot[4] + 1,
            LSnapshot[6] - 1, LSnapshot[6], LSnapshot[6] + 1);
          LEdgesY := TArray<Integer>.Create(LSnapshot[5] - 1, LSnapshot[5], LSnapshot[7],
            LSnapshot[7] + 1, (LSnapshot[5] + LSnapshot[7]) div 2);
          for LEdgeA in LEdges do
            for LEdgeB in LEdges do
              for LEdgeC in LEdgesY do
                for LEdgeD in LEdgesY do
                begin
                  LLine.A.X := LEdgeA;
                  LLine.A.Y := LEdgeC;
                  LLine.B.X := LEdgeB;
                  LLine.B.Y := LEdgeD;
                  LFrame.A.X := 0; LFrame.A.Y := 0; LFrame.B.X := 0; LFrame.B.Y := 0;
                  try
                    if FDriver.Clip(LLine, LFrame) then
                    begin
                      LPrint.AddBoolean(True);
                      LPrint.AddInteger(LFrame.A.X);
                      LPrint.AddInteger(LFrame.A.Y);
                      LPrint.AddInteger(LFrame.B.X);
                      LPrint.AddInteger(LFrame.B.Y);
                    end
                    else
                      LPrint.AddBoolean(False);
                  except
                    LPrint.AddException;
                  end;
                end;
        end;
      end;
    end
    else if (AName = 'rotate') or (AName = 'rotateexact') then
    begin
      for LStep := 1 to 40000 do
      begin
        LX := RandomBetween(-60000000, 60000000);
        LY := RandomBetween(-60000000, 60000000);
        LCenterX := RandomBetween(-60000000, 60000000);
        LCenterY := RandomBetween(-60000000, 60000000);
        if LStep mod 4 = 0 then
        begin
          LX := RandomBetween(-300000, 300000);
          LY := RandomBetween(-300000, 300000);
          LCenterX := 0;
          LCenterY := 0;
        end;
        case LStep mod 10 of
          0: LAngle := 0;
          1: LAngle := $40000000;
          2: LAngle := $80000000;
          3: LAngle := $C0000000;
          4: LAngle := $FFFFFFFF;
        else
          LAngle := NextRandom;
        end;
        if AName = 'rotate' then
          FDriver.Rotate(LX, LY, LAngle, LCenterX, LCenterY)
        else
          FDriver.RotateExact(LX, LY, LAngle, LCenterX, LCenterY);
        LPrint.AddInteger(LX);
        LPrint.AddInteger(LY);
      end;
    end
    else
      raise Exception.CreateFmt('unknown scenario %s', [AName]);
    Result := LPrint.ToHex;
  finally
    LPrint.Free;
  end;
end;

end.
