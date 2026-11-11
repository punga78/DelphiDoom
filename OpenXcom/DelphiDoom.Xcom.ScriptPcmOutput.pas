{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom program - a sound output without a device, that asks the    }
{  mixer for samples as the time of a script passes                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.ScriptPcmOutput;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>
  ///   IXcomPcmOutput for the script mode of the program (no window, a manual clock): nothing is heard, but the
  ///   mixer renders the samples of every millisecond that the script lets pass (Pull), so the sounds start, last
  ///   and end as with a device and the statistics of the mixer can be read. The source is not owned
  /// </summary>
  TXcomScriptPcmOutput = class(TInterfacedObject, IXcomPcmOutput)
  strict private
    FSource: IXcomPcmSource;
    FRate: Integer;
    FRemainder: Integer;
    FBuffer: TBytes;
    FPulledBytes: Int64;
  public
    const
      /// <summary>16 bit stereo</summary>
      FRAME_BYTES = 4;
    function Open(ARate: Integer; const ASource: IXcomPcmSource): Boolean;
    procedure Close;
    function IsOpen: Boolean;
    /// <summary>The samples of AMilliseconds of sound are asked to the source and thrown away</summary>
    procedure Pull(AMilliseconds: Integer);
    /// <summary>The bytes asked so far</summary>
    property PulledBytes: Int64 read FPulledBytes;
  end;

implementation

function TXcomScriptPcmOutput.Open(ARate: Integer; const ASource: IXcomPcmSource): Boolean;
begin
  FRate := ARate;
  FSource := ASource;
  FRemainder := 0;
  Result := (ARate > 0) and Assigned(ASource);
end;

procedure TXcomScriptPcmOutput.Close;
begin
  FSource := nil;
end;

function TXcomScriptPcmOutput.IsOpen: Boolean;
begin
  Result := Assigned(FSource);
end;

procedure TXcomScriptPcmOutput.Pull(AMilliseconds: Integer);
var
  LFrames: Integer;
  LTotal: Integer;
begin
  if (not Assigned(FSource)) or (AMilliseconds <= 0) then
    Exit;
  // the frames of the time passed, keeping what does not make a whole frame for the next call
  LTotal := FRate * AMilliseconds + FRemainder;
  LFrames := LTotal div 1000;
  FRemainder := LTotal mod 1000;
  if LFrames = 0 then
    Exit;
  if Length(FBuffer) < LFrames * FRAME_BYTES then
    SetLength(FBuffer, LFrames * FRAME_BYTES);
  FSource.Render(@FBuffer[0], LFrames * FRAME_BYTES);
  Inc(FPulledBytes, LFrames * FRAME_BYTES);
end;

end.