unit Helpers.HelperDate;

interface

uses
  System.SysUtils;

type

  THelperDate = record helper for TDate

    procedure Encode(Dia, mes, ano: Word);
    procedure SetDateNow;
    procedure EncodeStr(Dia, mes, ano: string);
    procedure ReplaceTimer; overload;
    procedure ReplaceTimer(aHora, aMin, aSec, aMil: Word); overload;
    function ToString: string;
  end;

implementation

procedure THelperDate.Encode(Dia, mes, ano: Word);
begin
  Self := EncodeDate(ano, mes, Dia);
end;

procedure THelperDate.EncodeStr(Dia, mes, ano: string);
begin
  try
    Self := EncodeDate(StrToInt(ano), StrToInt(mes), StrToInt(Dia));
  except
    raise Exception.Create('TCSTDate: encode inv�lido!');
  end;
end;

procedure THelperDate.ReplaceTimer(aHora, aMin, aSec, aMil: Word);
var
  newTime: TDateTime;
  data: TDateTime;
begin
  newTime := EncodeTime(aHora, aMin, aSec, aMil);
  data := Self;
  ReplaceTime(data, newTime);
  Self := data;

end;

procedure THelperDate.ReplaceTimer;
var
  newTime: TDateTime;
  data: TDateTime;
begin
  newTime := EncodeTime(0, 0, 0, 0);
  data := Self;
  ReplaceTime(data, newTime);
  Self := data;

end;

procedure THelperDate.SetDateNow;
begin
  Self := Now;
end;

function THelperDate.ToString: string;
begin
  result := DateToStr(Self);
end;

end.
