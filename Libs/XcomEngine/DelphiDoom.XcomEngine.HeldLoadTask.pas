{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - a loading that does not end (for the       }
{  screenshots of the start screen while it is loading, and for tests)          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.HeldLoadTask;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.GameLoader.Intf, DelphiDoom.XcomEngine.GameLoadTask;

type
  /// <summary>
  ///   Runs nothing: the status stays "running" until Finish or Fail say otherwise. It lets a test or a screenshot
  ///   freeze the start screen in the loading phase, with no thread and no waiting
  /// </summary>
  TXcomHeldLoadTask = class(TXcomGameLoadTask)
  strict private
    FStatus: TXcomLoadStatus;
  public
    procedure Start; override;
    function Status: TXcomLoadStatus; override;
    /// <summary>The loading ends well; the loader runs now</summary>
    procedure Finish;
    /// <summary>The loading ends with this error</summary>
    procedure Fail(const AMessage: string);
  end;

implementation

procedure TXcomHeldLoadTask.Start;
begin
  FStatus := lsRunning;
end;

function TXcomHeldLoadTask.Status: TXcomLoadStatus;
begin
  Result := FStatus;
end;

procedure TXcomHeldLoadTask.Finish;
begin
  if RunLoader then
    FStatus := lsSuccessful
  else
    FStatus := lsFailed;
end;

procedure TXcomHeldLoadTask.Fail(const AMessage: string);
begin
  FError := AMessage;
  FStatus := lsFailed;
end;

end.
