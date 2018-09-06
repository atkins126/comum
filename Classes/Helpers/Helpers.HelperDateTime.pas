unit Helpers.HelperDateTime;

interface

uses
  System.SysUtils;

type

  THelperDateTime = record helper for TDateTime

    procedure Encode(Dia, mes, ano: Word);
    procedure EncodeStr(Dia, mes, ano: string);
    procedure ReplaceTimer;
    procedure SetDateNow;
  end;

implementation


procedure THelperDateTime.Encode(Dia, mes, ano: Word);
begin
  Self := EncodeDate(ano, mes, Dia);
end;

procedure THelperDateTime.EncodeStr(Dia, mes, ano: string);
begin
   try
   Self := EncodeDate( StrToInt(ano), StrToInt( mes),StrToInt(dia));
   except
       raise Exception.Create('TCSTDate: encode inv�lido!');
   end;
end;

procedure THelperDateTime.ReplaceTimer;
var
  newTime: TDateTime;
begin
  newTime := EncodeTime(0, 0, 0, 0);
  ReplaceTime(Self, newTime);
end;

procedure THelperDateTime.SetDateNow;
begin
  Self := Now;
end;
end.
