-- создать метод логирования с автономной транзакцией
create or replace procedure KOTLYAROV_DM.add_system_log(
    p_object_name varchar2,
    p_params varchar2,
    p_log_type varchar2 default 'common'
)
as
    pragma autonomous_transaction;
begin
    insert into KOTLYAROV_DM.system_logs(object_name, log_type, params)
    values (p_object_name, p_log_type, p_params);

    commit;
end;

drop table KOTLYAROV_DM.SYSTEM_LOGS purge;

-- создать таблицу логов
create table KOTLYAROV_DM.system_logs
(
    id          number generated by default as identity (nocycle cache 20) primary key,

    sh_user     varchar2(50) default user,
    created_at  date         default sysdate,
    object_name varchar2(200),
    log_type    varchar2(1000),
    params      varchar2(4000)
)
    -- настроить в ней секционирование
    -- по дате создания на ближайшие три месяца
    partition by range (created_at)
(
    partition part_1 values less than (to_date('01.12.2021 00:00', 'dd.mm.yyyy hh24:mi')),
    partition part_2 values less than (to_date('01.01.2022 00:00', 'dd.mm.yyyy hh24:mi')),
    partition part_3 values less than (to_date('01.02.2022 00:00', 'dd.mm.yyyy hh24:mi'))
);

-- Льём данные
begin
    KOTLYAROV_DM.add_system_log(
            p_object_name => 'object name',
            p_params => 'test params'
        );
    KOTLYAROV_DM.add_system_log(
            p_object_name => 'object name',
            p_params => 'test params'
        );
end;

-- Проверяем
select *
from KOTLYAROV_DM.system_logs;

-- Очистка
alter table KOTLYAROV_DM.system_logs
    truncate partition part_1;

-- Пересобираем индекс
alter index KOTLYAROV_DM.SYS_C0028977 rebuild;

-- Проверяем
select *
from KOTLYAROV_DM.system_logs;

-- добавить еще секции на следующие три месяца
alter table KOTLYAROV_DM.system_logs
    add partition part_5 values less than (to_date('01.03.2022 00:00', 'dd.mm.yyyy hh24:mi'));

alter table KOTLYAROV_DM.system_logs
    add partition part_6 values less than (to_date('01.04.2022 00:00', 'dd.mm.yyyy hh24:mi'));

alter table KOTLYAROV_DM.system_logs
    add partition part_4 values less than (to_date('01.05.2022 00:00', 'dd.mm.yyyy hh24:mi'));

-- Льём данные
begin
    KOTLYAROV_DM.add_system_log(
            p_object_name => 'object name',
            p_params => 'test params'
        );
    KOTLYAROV_DM.add_system_log(
            p_object_name => 'object name',
            p_params => 'test params'
        );
end;

-- Проверяем
select *
from KOTLYAROV_DM.system_logs;

-- Логирование эксепшена в процедуре
begin
    KOTLYAROV_DM.JOURNAL_UTILS.insert_row(3, 3, 0);
    KOTLYAROV_DM.JOURNAL_UTILS.insert_row(2, 13, 0);
    KOTLYAROV_DM.JOURNAL_UTILS.insert_row(5, 77, 0);
end;

-- написать один select на вывод ошибок из логов
-- в нём должно быть:
-- условие за конкретный промежуток времени
-- условие на конкретный метод
-- условие на конкретные входные данные в логе (json_table)
select *
from KOTLYAROV_DM.system_logs
where CREATED_AT > sysdate - 1
  and trunc(CREATED_AT) <= trunc(sysdate)
  and upper(OBJECT_NAME) = 'KOTLYAROV_DM.JOURNAL_UTILS.INSERT_ROW'
  and (select id_ticket
       from json_table(params, '$' columns (
           id_ticket number path '$.p_id_ticket'
           ))) = 3
;

-- показать как обрабатывается такая ошибка в вызывающей программе
begin
    KOTLYAROV_DM.JOURNAL_UTILS.EXC_UPDATE_STATUS(123, 123, KOTLYAROV_DM.enum_journal_status_type.C_OPENED);

    exception when KOTLYAROV_DM.JOURNAL_UTILS.RECORD_NOT_FOUND then
        DBMS_OUTPUT.PUT_LINE('Record not found!');
end;