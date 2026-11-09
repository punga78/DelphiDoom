{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the loading at once, in the calling thread }
{  (what StartState does when it cannot create the thread)                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.ImmediateLoadTask;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.GameLoadTask;

type
  /// <summary>Loads inside Start: the status is final as soon as Start returns. Used by tests and by the screenshots</summary>
  TXcomImmediateLoadTask = class(TXcomGameLoadTask)
  strict private
    FStatus: TXcomLoadStatus;
  public
    procedure Start; override;
    function Status: TXcomLoadStatus; override;
  end;

implementation

procedure TXcomImmediateLoadTask.Start;
begin
  if RunLoader then
    FStatus := lsSuccessful
  else
    FStatus := lsFailed;
end;

function TXcomImmediateLoadTask.Status: TXcomLoadStatus;
begin
  Result := FStatus;
end;

end.
