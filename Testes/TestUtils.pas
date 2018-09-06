unit TestUtils;
{

  Delphi DUnit Test Case
  ----------------------
  This unit contains a skeleton test case class generated by the Test Case Wizard.
  Modify the generated code to correctly setup and call the methods from the unit
  being tested.

}

interface

uses
  TestFramework, Utils.Crypt, System.SysUtils;

type
  // Test methods for class TCrypt

  TestTCrypt = class(TTestCase)
  strict private
    FCrypt: TCrypt;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published

    procedure TestPOdeCriptografarEDescriptografar;

  end;

implementation

procedure TestTCrypt.SetUp;
begin
  FCrypt := TCrypt.Create;
end;

procedure TestTCrypt.TearDown;
begin
  FCrypt.Free;
  FCrypt := nil;
end;



procedure TestTCrypt.TestPOdeCriptografarEDescriptografar;
var
  Criptografado: string;
  Descriptografado: string;
  Key: string;
  S: string;
begin
  S := '123456789TSeererererernha';
  Key := 'mestre@consult';

  // TODO: Setup method call parameters

  Criptografado := FCrypt.CriptografaString(Key, S);

  Descriptografado := FCrypt.DecriptografaString(Key, Criptografado);
  // TODO: Validate method results

  CheckTrue(Descriptografado = S);

end;


initialization

// Register any test cases with the test runner
RegisterTest(TestTCrypt.Suite);

end.
