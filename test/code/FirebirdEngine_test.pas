{
  Copyright (c) 2020, Vencejo Software
  Distributed under the terms of the Modified BSD License
  The full license is distributed with this software
}
unit FirebirdEngine_test;

interface

uses
  Classes, SysUtils,
  DB,
  FailedExecution, SuccededExecution, ExecutionResult, DatasetExecution,
  DatabaseEngine, FirebirdEngine,
  ConnectionParam,
  DatabaseLogin,
{$IFDEF FPC}
  fpcunit, testregistry
{$ELSE}
  TestFramework
{$ENDIF};

type
  TFirebirdEngineTest = class sealed(TTestCase)
  strict private
    _DatabaseEngine: IDatabaseEngine;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure OpendatasetReturnDataset;
    procedure IsConnectedIsTrue;
    procedure IsConnectedIsFalse;
    procedure ExecuteReturnFailedExecution;
    procedure ExecuteReturningReturnGeneratedID;
    procedure UseGlobalTransactionAndRollbackNotReturnRecords;
    procedure PrivateTransactionAutoCommitReturnRecord;
  end;

implementation

procedure TFirebirdEngineTest.OpendatasetReturnDataset;
var
  ExecutionResult: IExecutionResult;
  Dataset: TDataSet;
  SQL: String;
begin
  SQL := 'select rdb$relation_name from rdb$relations where rdb$view_blr is null and (rdb$system_flag is null or rdb$system_flag = 0)';
  ExecutionResult := _DatabaseEngine.OpenDataset(SQL);
  CheckFalse(ExecutionResult.Failed);
  if Supports(ExecutionResult, IDatasetExecution) then
  begin
    Dataset := (ExecutionResult as IDatasetExecution).Dataset;
    CheckTrue(Assigned(Dataset));
    while not Dataset.Eof do
    begin
      CheckTrue(Dataset.Fields[0].AsString <> '');
      Dataset.Next
    end;
  end;
end;

procedure TFirebirdEngineTest.ExecuteReturnFailedExecution;
var
  ExecutionResult: IExecutionResult;
begin
  ExecutionResult := _DatabaseEngine.Execute('INSERT INTO UNKNOWN(ID) VALUES (1)');
  CheckTrue(ExecutionResult.Failed);
  CheckTrue(Supports(ExecutionResult, IFailedExecution));
  CheckEquals
    ('SQL Error: Dynamic SQL ErrorSQL error code = -204Table unknownUNKNOWNAt line 1, column 13. Error Code: -204. Undefined name The SQL: INSERT INTO UNKNOWN(ID) VALUES (1); ',
    (ExecutionResult as IFailedExecution).Message);
end;

procedure TFirebirdEngineTest.IsConnectedIsFalse;
begin
  CheckTrue(_DatabaseEngine.Disconnect);
  CheckFalse(_DatabaseEngine.IsConnected);
end;

procedure TFirebirdEngineTest.IsConnectedIsTrue;
begin
  CheckTrue(_DatabaseEngine.IsConnected)
end;

procedure TFirebirdEngineTest.ExecuteReturningReturnGeneratedID;
var
  ExecutionResult: IExecutionResult;
  Dataset: TDataSet;
begin
  ExecutionResult := _DatabaseEngine.ExecuteReturning('INSERT INTO TEMP_TEST(name) VALUES (''test'') RETURNING ID');
  CheckFalse(ExecutionResult.Failed);
  CheckTrue(Supports(ExecutionResult, IDatasetExecution));
  Dataset := (ExecutionResult as IDatasetExecution).Dataset;
  CheckTrue(Assigned(Dataset));
  CheckFalse(Dataset.IsEmpty);
  CheckEquals(100, Dataset.FieldByName('id').AsInteger);
end;

procedure TFirebirdEngineTest.UseGlobalTransactionAndRollbackNotReturnRecords;
var
  ExecutionResult: IExecutionResult;
begin
  CheckFalse(_DatabaseEngine.InTransaction);
  _DatabaseEngine.BeginTransaction;
  CheckTrue(_DatabaseEngine.InTransaction);
  try
    ExecutionResult := _DatabaseEngine.Execute('INSERT INTO TEMP_TEST(name) VALUES (''a'')', True);
    CheckEquals(1, (ExecutionResult as ISuccededExecution).AffectedRows);
    ExecutionResult := _DatabaseEngine.Execute('INSERT INTO TEMP_TEST(name) VALUES (''b'')', True);
    CheckEquals(1, (ExecutionResult as ISuccededExecution).AffectedRows);
    ExecutionResult := _DatabaseEngine.Execute('INSERT INTO TEMP_TEST(name) VALUES (''c'')', True);
    CheckEquals(1, (ExecutionResult as ISuccededExecution).AffectedRows);
  finally
    _DatabaseEngine.RollbackTransaction;
  end;
  ExecutionResult := _DatabaseEngine.OpenDataset('SELECT * FROM TEMP_TEST');
  if Supports(ExecutionResult, IDatasetExecution) then
    CheckTrue((ExecutionResult as IDatasetExecution).Dataset.IsEmpty);
end;

procedure TFirebirdEngineTest.PrivateTransactionAutoCommitReturnRecord;
var
  ExecutionResult: IExecutionResult;
begin
  CheckFalse(_DatabaseEngine.InTransaction);
  ExecutionResult := _DatabaseEngine.Execute('INSERT INTO TEMP_TEST(name) VALUES (''a'')', False);
  CheckFalse(_DatabaseEngine.InTransaction);
  CheckEquals(1, (ExecutionResult as ISuccededExecution).AffectedRows);
  ExecutionResult := _DatabaseEngine.OpenDataset('SELECT * FROM TEMP_TEST');
  if Supports(ExecutionResult, IDatasetExecution) then
    CheckFalse((ExecutionResult as IDatasetExecution).Dataset.IsEmpty);
end;

procedure TFirebirdEngineTest.SetUp;
const
  DEPENDS_PATH = '..\..\..\..\dependencies\';
var
  Login: IDatabaseLogin;
begin
  inherited;
  Login := TDatabaseLogin.New('sysdba', 'masterkey');
{$IFDEF WIN64}
  Login.Parameters.Add(TConnectionParam.New('LIB_PATH', DEPENDS_PATH + 'Firebird25x64\fbembed.dll'));
{$ELSE}
  Login.Parameters.Add(TConnectionParam.New('LIB_PATH', DEPENDS_PATH + 'Firebird25x32\fbembed.dll'));
{$ENDIF}
  Login.Parameters.Add(TConnectionParam.New('ENGINE', 'Firebird'));
  Login.Parameters.Add(TConnectionParam.New('DB_PATH', DEPENDS_PATH + 'TEST.FDB'));
  Login.Parameters.Add(TConnectionParam.New('DIALECT', '3'));
  Login.Parameters.Add(TConnectionParam.New('CHARSET', 'ISO8859_1'));
  _DatabaseEngine := TFirebirdEngine.New;
  CheckTrue(_DatabaseEngine.Connect(Login));
  _DatabaseEngine.ExecuteScript([ //
    'create table TEMP_TEST (ID int not null primary key, name varchar(50))', //
    'CREATE GENERATOR SQ_TEMP_TEST', 'SET GENERATOR SQ_TEMP_TEST TO 99', //
    'SET TERM ^ ;', //
    'CREATE TRIGGER TG_TEMP_TEST for TEMP_TEST' + sLineBreak + //
    'active before insert position 0 as' + sLineBreak + //
    'begin' + sLineBreak + //
    ' if (new.id is null) then' + sLineBreak + //
    ' begin' + sLineBreak + //
    '  new.id = gen_id(SQ_TEMP_TEST, 1);' + sLineBreak + //
    ' end' + sLineBreak + //
    'end ^', //
    'SET TERM ; ^']);
end;

procedure TFirebirdEngineTest.TearDown;
begin
  inherited;
  _DatabaseEngine.ExecuteScript(['drop trigger TG_TEMP_TEST', 'drop table TEMP_TEST', 'DROP GENERATOR SQ_TEMP_TEST']);
  CheckTrue(_DatabaseEngine.Disconnect);
end;

initialization

RegisterTests('DatabaseEngine test', [TFirebirdEngineTest {$IFNDEF FPC}.Suite {$ENDIF}]);

end.
