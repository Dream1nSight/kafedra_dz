
-- создать два пакета (можно не связанные с проектом)
-- вызывающие друг друга.
-- понять как такое компилировать в одном файле скрипта
create or replace package KOTLYAROV_DM.pkg_test1
as
    procedure p(p_message varchar2);
    procedure test;
end;

create or replace package KOTLYAROV_DM.pkg_test2
as
    procedure p(p_message varchar2);
    procedure test;
end;

create or replace package body KOTLYAROV_DM.pkg_test1
as
    procedure p(p_message varchar2) as
    begin
        DBMS_OUTPUT.PUT_LINE(p_message);
    end;

    procedure test as
    begin
        KOTLYAROV_DM.PKG_TEST2.P('call from pkg_test1');
    end test;
end;

create or replace package body KOTLYAROV_DM.pkg_test2
as
    procedure p(p_message varchar2) as
    begin
        DBMS_OUTPUT.PUT_LINE(p_message);
    end;

    procedure test as
    begin
        KOTLYAROV_DM.PKG_TEST1.P('call from pkg_test2');
    end test;
end;