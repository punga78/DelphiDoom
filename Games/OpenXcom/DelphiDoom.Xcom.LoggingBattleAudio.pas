{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom program - the sounds of the battle written down as they     }
{  are asked (to check them without a loudspeaker)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.LoggingBattleAudio;

interface

uses
  System.SysUtils, DelphiDoom.XcomBattleStates.Screens.Intf;

type
  /// <summary>Takes a line of the log of the sounds</summary>
  TXcomSoundLogLine = reference to procedure(const ALine: string);

  /// <summary>
  ///   IXcomBattleAudio that writes a line for every request ("play depth sound angle", "loop depth sound",
  ///   "stop") and passes it on to the audio it decorates (nil: only the log)
  /// </summary>
  TXcomLoggingBattleAudio = class(TInterfacedObject, IXcomBattleAudio)
  strict private
    FInner: IXcomBattleAudio;
    FLog: TXcomSoundLogLine;
  public
    constructor Create(const AInner: IXcomBattleAudio; const ALog: TXcomSoundLogLine);
    procedure PlaySound(ADepth, ASound, AAngle: Integer);
    procedure LoopAmbience(ADepth, ASound: Integer);
    procedure StopAmbience;
  end;

implementation

constructor TXcomLoggingBattleAudio.Create(const AInner: IXcomBattleAudio; const ALog: TXcomSoundLogLine);
begin
  inherited Create;
  FInner := AInner;
  FLog := ALog;
end;

procedure TXcomLoggingBattleAudio.PlaySound(ADepth, ASound, AAngle: Integer);
begin
  if Assigned(FLog) then
    FLog(Format('play %d %d %d', [ADepth, ASound, AAngle]));
  if Assigned(FInner) then
    FInner.PlaySound(ADepth, ASound, AAngle);
end;

procedure TXcomLoggingBattleAudio.LoopAmbience(ADepth, ASound: Integer);
begin
  if Assigned(FLog) then
    FLog(Format('loop %d %d', [ADepth, ASound]));
  if Assigned(FInner) then
    FInner.LoopAmbience(ADepth, ASound);
end;

procedure TXcomLoggingBattleAudio.StopAmbience;
begin
  if Assigned(FLog) then
    FLog('stop');
  if Assigned(FInner) then
    FInner.StopAmbience;
end;

end.