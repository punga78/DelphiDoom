{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - writing a file in one step (issue 186)    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.AtomicFileWriter;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.AtomicFiles.Intf;

type
  /// <summary>
  ///   The file is written next to the real one under the name path.tmp and takes its place when it is complete, so
  ///   the real file is never seen half written (a program that dies or a disk that fills in the middle of the write
  ///   leaves the old file). A file system that is not an IXcomAtomicFiles is written in place, as it always was
  /// </summary>
  TXcomAtomicFileWriter = class
  public
    /// <param name="ABeforeReplace">Called when the new file is complete and the old one is still in place (to keep a copy); nil for nothing</param>
    class procedure Write(const AFiles: IXcomFileSystem; const APath: string; const ABytes: TBytes;
      const ABeforeReplace: TProc = nil); static;
  end;

implementation

class procedure TXcomAtomicFileWriter.Write(const AFiles: IXcomFileSystem; const APath: string; const ABytes: TBytes;
  const ABeforeReplace: TProc);
var
  LAtomic: IXcomAtomicFiles;
  LTemporary: string;
begin
  if not Supports(AFiles, IXcomAtomicFiles, LAtomic) then
  begin
    if Assigned(ABeforeReplace) then
      ABeforeReplace();
    AFiles.WriteAll(APath, ABytes);
    Exit;
  end;
  LTemporary := APath + '.tmp';
  try
    AFiles.WriteAll(LTemporary, ABytes);
  except
    // the half written file goes, the real one was not touched, and the error of the disk goes on
    LAtomic.DeleteFile(LTemporary);
    raise;
  end;
  if Assigned(ABeforeReplace) then
    ABeforeReplace();
  LAtomic.ReplaceFile(LTemporary, APath);
end;

end.
