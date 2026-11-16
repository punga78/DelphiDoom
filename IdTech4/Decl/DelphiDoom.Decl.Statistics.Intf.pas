{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - IDeclStatistics, what listDecls shows     }
{                                                                              }
{  Written from what idDeclManagerLocal::ListDecls_f reads of the manager;     }
{  licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Statistics.Intf;

interface

type
  /// <summary>
  ///   The numbers behind the <c>listDecls</c> command. The manager implements it next to <c>IDeclManager</c>
  ///   (<c>Supports(Manager, IDeclStatistics, Statistics)</c>), so the interface of the manager itself stays small.
  /// </summary>
  IDeclStatistics = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0020}']
    /// <summary><c>declTypes.Num()</c>: the number of slots of the type list, registered or not</summary>
    function GetTypeSlotCount: Integer;
    /// <summary>A type is registered in the slot (the list of the original has holes: <c>declTypes[i] == NULL</c>)</summary>
    function IsTypeRegistered(const AType: Integer): Boolean;
    /// <summary>
    ///   The bytes the decls of a type take: for each <c>Size()</c> of the entry plus <c>Size()</c> of its
    ///   object if there is one
    /// </summary>
    function GetTypeSize(const AType: Integer): NativeInt;
    /// <summary>The number of files the manager has loaded (<c>loadedFiles.Num()</c>; the implicit file is not one)</summary>
    function GetLoadedFileCount: Integer;
    /// <summary>The sum of the sizes of the loaded files (<c>totalText</c>)</summary>
    function GetLoadedFilesSize: Int64;
  end;

implementation

end.
