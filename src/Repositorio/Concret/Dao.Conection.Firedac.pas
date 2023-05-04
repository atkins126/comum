unit Dao.Conection.Firedac;

interface

uses

  Dao.IConection,
  System.Rtti,
  System.Classes,
  System.SysUtils,
  Data.DB,
  Dao.Conection.Parametros,
  Exceptions, Database.SGDB,
  System.Variants,
  Firedac.Stan.Def,
  Firedac.Stan.Async,
  Firedac.Phys.SQLite,
  Firedac.Phys.SQLiteDef,
  Firedac.Stan.Intf,
  Firedac.Stan.Option,
  Firedac.DApt,
  Firedac.Comp.Client,

{$IFDEF   MSWINDOWS}
{$IF DECLARED(FireMonkeyVersion)}
  Firedac.FMXUI.Wait,
{$ELSE}
  Firedac.VCLUI.Wait,
{$ENDIF}
  Firedac.Phys.Oracle,
  Firedac.Phys.MSSQLDef,
  Firedac.Phys.MSSQL,
  Firedac.Phys.OracleDef,
  Firedac.UI.Intf,
  Firedac.Comp.UI,
  Firedac.Comp.Script,
  Firedac.Phys.FBDef,
  Firedac.Phys,
{$ENDIF}
  System.Generics.Collections, Model.CampoValor;

type

  TFiredacConection = class(TInterfacedObject, IConection)
  private
    FConnection: TFDConnection;
    FParametros: TConectionParametros;
    function Conexao(nova: Boolean = false): TFDConnection;
    function Query(): TFDQuery;
    procedure SetQueryParamns(qry: TFDQuery; aNamedParamns: TListaModelCampoValor);
    function VariantIsEmptyOrNull(const Value: Variant): Boolean;
  public

    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
    function ExecSQL(const ASQL: String): LongInt; overload;
    function ExecSQL(const ASQL: String; const AParams: array of Variant): LongInt; overload;
    function ExecSQL(const ASQL: String; aNamedParamns: TListaModelCampoValor): LongInt; overload;
    function Open(const ASQL: String): TDataSet; overload;
    function Open(const ASQL: String; const AParams: array of Variant): TDataSet; overload;
    function Open(const ASQL: String; const AParams: array of Variant; const ATypes: array of TFieldType): TDataSet; overload;
    function Open(const ASQL: String; aNamedParamns: TListaModelCampoValor): TDataSet; overload;

    procedure Close();
    function GetSGBDType: TSGBD;
    procedure TesteConection;

    constructor Create(aParametros: TConectionParametros);
    class function New(aParametros: TConectionParametros): IConection;
    destructor destroy; override;
  end;

implementation

/// <summary>
/// Fecha a conexão com o banco de dados
/// </summary>
procedure TFiredacConection.Close;
begin
  if (FConnection <> nil) then
    Self.FConnection.Close;
end;

/// <summary>
/// Commita as alterações para o banco de dados
/// </summary>
procedure TFiredacConection.Commit;
begin
  Self.FConnection.Commit;
end;

/// <summary>
/// Cria e configura uma Conexao com o banco de dados
/// </summary>
/// <param name="nova">Indica se será criada uma nova instancia</param>
/// <returns>TFDConnection</returns>
function TFiredacConection.Conexao(nova: Boolean = false): TFDConnection;
begin
  if (FConnection = nil) or nova then
  begin
    if (not Assigned(FParametros)) then
      raise TConectionException.Create('Parametros Não Informado para a classe de conexão!');

    FConnection := TFDConnection.Create(nil);

    case FParametros.SGBD of
      tpSQLite:
        begin
          FConnection.DriverName := 'SQLite';
          FConnection.Params.UserName := '';
          FConnection.Params.Password := '';
          FConnection.Params.Database := FParametros.Database;
        end;

{$IFDEF  MSWINDOWS}
      tpSqlServer:
        begin
          FConnection.DriverName := 'MSSQL';
          with FConnection.Params as TFDPhysMSSQLConnectionDefParams do
          begin
            Server := FParametros.Server;
            Database := FParametros.Database;
            UserName := FParametros.UserName;
            Password := FParametros.Password;
            ApplicationName := FParametros.ApplicationName;
          end;
          FConnection.Params.Add('ODBCAdvanced=TrustServerCertificate=yes');
        end;
      tpOracle:
        begin

          FConnection.DriverName := 'Ora';

          with FConnection.Params as TFDPhysOracleConnectionDefParams do
          begin
            Database := FParametros.Database;
            UserName := FParametros.UserName;
            Password := FParametros.Password;

            ApplicationName := ExtractFileName(ApplicationName);
          end;
        end;
{$ENDIF}
    end;

    FConnection.FetchOptions.Mode := fmAll;
    FConnection.ResourceOptions.AutoConnect := True;
    FConnection.Open();
  end;
  result := FConnection;
end;

constructor TFiredacConection.Create(aParametros: TConectionParametros);
begin
  Self.FParametros := aParametros;
end;

destructor TFiredacConection.destroy;
begin
  if Assigned(FConnection) then
  begin
    FConnection.Close;
    FreeAndNil(FConnection);
  end;
  FreeAndNil(FParametros);
  inherited;
end;

function TFiredacConection.VariantIsEmptyOrNull(const Value: Variant): Boolean;
begin
  result := VarIsClear(Value) or VarIsEmpty(Value) or VarIsNull(Value) or (VarCompareValue(Value, Unassigned) = vrEqual);
  if (not result) and VarIsStr(Value) then
    result := Value = '';
end;

/// <summary>
/// Peccorrer os parametros e seta o seu valor na TFDQuery de acordo com o seu nome e tipo
/// </summary>
/// <param name="qry">TFDQuery a ser parametrizada</param>
/// <param name="aNamedParamns">Lista de Parametros</param>
procedure TFiredacConection.SetQueryParamns(qry: TFDQuery; aNamedParamns: TListaModelCampoValor);
var
  key: string;
  LCampoValor: TModelCampoValor;
  basicType: Integer;
  paramIsNull: Boolean;
begin

  // pecorrrer os parametros
  for key in aNamedParamns.Keys do
  begin
    // ver se o parametro existe na query
    if qry.Params.FindParam(key) = nil then
      Continue;

    // pegar o valor do parametro
    LCampoValor := aNamedParamns.Items[key];

    paramIsNull := LCampoValor.Value = Null;

    // com o valor do parametro, verificar o seu tipo primitido
    basicType := LCampoValor.vType and VarTypeMask;
    case basicType of
      varEmpty:
        begin
          qry.ParamByName(key).Clear;
        end;
      varNull:
        begin
          qry.ParamByName(key).Clear;
        end;
      varSmallInt:
        begin
          if paramIsNull then
          begin
            qry.ParamByName(key).DataType := TFieldType.ftSmallint;
            qry.ParamByName(key).Clear();
          end
          else
            qry.ParamByName(key).AsSmallInt := LCampoValor.Value;
        end;
      varInteger:
        begin
          if paramIsNull then
          begin
            qry.ParamByName(key).DataType := TFieldType.ftInteger;
            qry.ParamByName(key).Clear();
          end
          else
            qry.ParamByName(key).AsInteger := LCampoValor.Value;
        end;
      varSingle:
        begin
          if paramIsNull then
          begin
            qry.ParamByName(key).DataType := TFieldType.ftSingle;
            qry.ParamByName(key).Clear();
          end
          else
            qry.ParamByName(key).AsSingle := LCampoValor.Value;
        end;
      varDouble:
        begin
          if paramIsNull then
          begin
            qry.ParamByName(key).DataType := TFieldType.ftFloat;
            qry.ParamByName(key).Clear();
          end
          else
            qry.ParamByName(key).AsFloat := LCampoValor.Value;
        end;
      varCurrency:
        begin
          if paramIsNull then
          begin
            qry.ParamByName(key).DataType := TFieldType.ftCurrency;
            qry.ParamByName(key).Clear();
          end
          else
            qry.ParamByName(key).AsCurrency := LCampoValor.Value;
        end;
      varDate:
        begin
          if paramIsNull then
          begin
            qry.ParamByName(key).DataType := TFieldType.ftDate;
            qry.ParamByName(key).Clear();
          end
          else
            qry.ParamByName(key).AsDateTime := LCampoValor.Value;
        end;
      varBoolean:
        begin
          if paramIsNull then
          begin
            qry.ParamByName(key).DataType := TFieldType.ftBoolean;
            qry.ParamByName(key).Clear();
          end
          else
            qry.ParamByName(key).AsBoolean := LCampoValor.Value;
        end;
      varVariant:
        begin
          qry.ParamByName(key).Value := LCampoValor.Value;
        end;
      varUnknown:
        begin
          raise Exception.Create('Tipo Desconhecido por Dao.Conection');
        end;
      varByte:
        begin
          qry.ParamByName(key).AsVarByteStr := LCampoValor.Value;
        end;
      varUString:
        begin
          if paramIsNull then
          begin
            qry.ParamByName(key).DataType := TFieldType.ftString;
            qry.ParamByName(key).Clear();
          end
          else
          begin
            qry.ParamByName(key).AsString := LCampoValor.Value;
            // campos grandes, mudar o tipo para ftMemo
            if qry.ParamByName(key).AsString.Length > 2000 then
            begin
              qry.ParamByName(key).DataType := ftMemo;
              qry.ParamByName(key).AsMemo := LCampoValor.Value;

            end;
          end;

        end;
      varString:
        begin
          // qry.ParamByName(key).Size := 100000;
          if paramIsNull then
          begin
            qry.ParamByName(key).DataType := TFieldType.ftString;
            qry.ParamByName(key).Clear();
          end
          else
            qry.ParamByName(key).AsString := LCampoValor.Value;
        end;
      VarTypeMask, varArray, varByRef, varOleStr, varDispatch, varError:
        begin
          raise Exception.Create('Tipo não suportado por Dao.Conection');
        end;
    else
      begin
        qry.ParamByName(key).value := LCampoValor.Value;
      end;
    end;
  end;
end;

/// <summary>
/// Execulta uma instrução sql no banco de dados
/// </summary>
/// <param name="AQL">sql a ser execultada</param>
/// <param name="aNamedParamns">Parametros da sql - nome e o valor </param>
/// <returns>Numero de linhas afetadas</returns>
function TFiredacConection.ExecSQL(const ASQL: String; aNamedParamns: TListaModelCampoValor): LongInt;
var
  qry: TFDQuery;
begin
  qry := Query();
  try

    qry.SQL.Text := ASQL;
    SetQueryParamns(qry, aNamedParamns);

    qry.ExecSQL();
    result := qry.RowsAffected;
  finally
    qry.Free;
  end;

end;

function TFiredacConection.GetSGBDType: TSGBD;
begin
  result := FParametros.SGBD;
end;

class function TFiredacConection.New(aParametros: TConectionParametros): IConection;
begin
  result := TFiredacConection.Create(aParametros);
end;

/// <summary>
/// Execulta uma instrução sql no banco de dados
/// </summary>
/// <returns>Numero de linhas afetadas</returns>
function TFiredacConection.ExecSQL(const ASQL: String): LongInt;
var
  qry: TFDQuery;
begin
  try
    qry := Query();
    qry.ExecSQL(ASQL);
    result := qry.RowsAffected;
  finally
    qry.Free;
  end;
end;

/// <summary>
/// Execulta uma instrução sql no banco de dados
/// </summary>
/// <param name="AQL">sql a ser execultada</param>
/// <param name="aParams">parametros da query</param>
/// <returns>Numero de linhas afetadas</returns>
function TFiredacConection.ExecSQL(const ASQL: String; const AParams: array of Variant): LongInt;
var
  qry: TFDQuery;
begin
  try
    qry := Query();
    qry.ExecSQL(ASQL, AParams);
    result := qry.RowsAffected;
  finally
    qry.Free;
  end;
end;

/// <summary>
/// Execulta uma consulta sql no banco de dados e Retorna Um Dataset
/// </summary>
/// <param name="AQL">sql a ser execultada</param>
/// <returns>Dataset da consulta</returns>
function TFiredacConection.Open(const ASQL: String): TDataSet;
var
  qry: TFDQuery;
begin
  qry := Query();
  qry.Open(ASQL);
  result := qry;
end;

/// <summary>
/// Execulta uma consulta sql no banco de dados e Retorna Um Dataset
/// </summary>
/// <param name="AQL">sql a ser execultada</param>
/// <param name="aParams">parametros da query</param>
/// <returns>Dataset da consulta</returns>
function TFiredacConection.Open(const ASQL: String; const AParams: array of Variant): TDataSet;
var
  qry: TFDQuery;
begin
  qry := Query();
  qry.Open(ASQL, AParams);
  result := qry;

end;

/// <summary>
/// Execulta uma consulta sql no banco de dados e Retorna Um Dataset
/// </summary>
/// <param name="AQL">sql a ser execultada</param>
/// <param name="aParams">parametros da query</param>
/// <param name="aTypes">Tipos dos parametros passados</param>
/// <returns>Dataset da consulta</returns>
function TFiredacConection.Open(const ASQL: String; const AParams: array of Variant; const ATypes: array of TFieldType): TDataSet;
var
  qry: TFDQuery;
begin
  qry := Query();
  qry.Open(ASQL, AParams, ATypes);
  result := qry;

end;

/// <summary>
/// Criar, configura e retorna uma query
/// </summary>
function TFiredacConection.Query: TFDQuery;
begin
  result := TFDQuery.Create(nil);
  result.Connection := Conexao;
end;

/// <summary>
/// Desfaz uma transação
/// </summary>
procedure TFiredacConection.Rollback;
begin
  Conexao.Rollback;
end;

/// <summary>
/// Inicia uma transação
/// </summary>
procedure TFiredacConection.StartTransaction;
begin
  Conexao.StartTransaction;
end;

procedure TFiredacConection.TesteConection;
begin
  Self
    .Conexao()
    .Open();
end;

/// <summary>
/// Execulta uma consulta sql no banco de dados e Retorna Um Dataset
/// </summary>
/// <param name="AQL">sql a ser execultada</param>
/// <param name="aNamedParamns">Parametros da sql - nome e o valor </param>
/// <returns>Dataset da consulta</returns>

function TFiredacConection.Open(const ASQL: String; aNamedParamns: TListaModelCampoValor): TDataSet;
var
  qry: TFDQuery;
begin
  qry := Query();
  qry.SQL.Text := ASQL;
  SetQueryParamns(qry, aNamedParamns);

  qry.Open();
  result := qry;
end;

end.
