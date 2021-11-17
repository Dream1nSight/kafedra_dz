-- Константы типов больниц
create or replace package KOTLYAROV_DM.pkg_hospital_type
as
    function c_government return number deterministic;
    function c_private return number deterministic;
end;

create or replace package body KOTLYAROV_DM.pkg_hospital_type
as
    function c_government return number deterministic as
    begin
        return 2;
    end;
    function c_private return number deterministic as
    begin
        return 2;
    end;
end;

-- Константы статусов записей в журнале
create or replace package KOTLYAROV_DM.pkg_journal_status_type
as
    function c_opened return number deterministic;
    function c_cancelled return number deterministic;
end;

-- Константы статусов записей в журнале
create or replace package body KOTLYAROV_DM.pkg_journal_status_type
as
    function c_opened return number deterministic as
    begin
        return 0;
    end;
    function c_cancelled return number deterministic as
    begin
        return 1;
    end;
end;

-- *Выдать все больницы (неудаленные) конкретной специальности (1) с пометками о доступности, кол-ве врачей;
-- отсортировать по типу: частные выше,
-- по кол-ву докторов: где больше выше,
-- по времени работы: которые еще работают выше
--
-- status 0 = недоступно
create or replace function KOTLYAROV_DM.get_hospitals_by_speciality(
    p_id_specialty number := null,
    p_hospital_status number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        SELECT h.ID,
               h.id_type,
               h.NAME,
               h.id_organization,
               h.STATUS,
               COUNT(d.id) AS doc_count
        FROM KOTLYAROV_DM.HOSPITALS h
                 INNER JOIN KOTLYAROV_DM.doctors d on d.id_hospital = h.id
                 INNER JOIN KOTLYAROV_DM.doctor_specialty ds on d.id = ds.id_doctor
                 INNER JOIN KOTLYAROV_DM.specialities s on ds.id_speciality = s.id
                 INNER JOIN KOTLYAROV_DM.HOSPITAL_WORK_TIMES hwt on h.ID = hwt.id_hospital
        WHERE h.deleted_at IS NULL
          AND hwt.END_TIME > to_char(systimestamp, 'hh24:mi')
          AND ((p_hospital_status is not null and p_hospital_status = h.status) or (p_hospital_status is null))
          AND ((p_id_specialty is not null and p_id_specialty = s.ID) or (p_id_specialty is null))
        GROUP BY hwt.END_TIME, h.id_type, h.id, h.NAME, h.id_organization, h.STATUS
        ORDER BY case when h.id_type = KOTLYAROV_DM.pkg_hospital_type.c_private then 1 else 0 end, doc_count DESC,
                 hwt.END_TIME DESC;

    return v_result;
end;

create or replace package KOTLYAROV_DM.hospital_utils
as
    function get_hospital_by_id(id number) return KOTLYAROV_DM.HOSPITALS%rowtype;
end;

create or replace package body KOTLYAROV_DM.hospital_utils
as
    function get_hospital_by_id(hospital_id number) return KOTLYAROV_DM.HOSPITALS%rowtype
    as
        v_result KOTLYAROV_DM.HOSPITALS%rowtype;
    begin
        select *
        into v_result
        from KOTLYAROV_DM.HOSPITALS
        where id = hospital_id;

        return v_result;
    end;
end;

create or replace package KOTLYAROV_DM.journal_utils
as
    type t_journal_array is table of KOTLYAROV_DM.hospitals%rowtype;

    procedure insert_row(p_id_ticket number, p_id_patient number, p_status smallint);
    procedure update_status(p_id_ticket number, p_id_patient number, p_status smallint);
    function search_in_journal(p_id_ticket number := null, p_id_patient number := null,
                               p_status smallint := null) return t_journal_array;
end;

create or replace package body KOTLYAROV_DM.journal_utils
as
    procedure insert_row(p_id_ticket number, p_id_patient number, p_status smallint)
    as
    begin
        insert into KOTLYAROV_DM.PATIENT_JOURNALS (ID_PATIENT, ID_TICKET, STATUS)
        values (p_id_patient, p_id_ticket, p_status);

        -- Предпологаю что процедуру можно будет использовать в цикле и завершать транзакцию в конце
        -- commit;
    end;

    procedure update_status(p_id_ticket number, p_id_patient number, p_status smallint)
    as
    begin
        update KOTLYAROV_DM.PATIENT_JOURNALS
        set status = p_status
        where id_patient = p_id_patient
          and id_ticket = p_id_ticket;

        -- Предпологаю что процедуру можно будет использовать в цикле и завершать транзакцию в конце
        -- commit;
    end;

    function search_in_journal(p_id_ticket number := null, p_id_patient number := null, p_status smallint := null)
        return t_journal_array
    as
        a_result t_journal_array;
    begin
        select * bulk collect
        into a_result
        from KOTLYAROV_DM.PATIENT_JOURNALS pj
        where ((p_id_ticket is not null and p_id_ticket = pj.ID_TICKET) or (p_id_ticket is null))
          and ((p_id_patient is not null and p_id_patient = pj.ID_PATIENT) or (p_id_patient is null))
          and ((p_status is not null and p_status = pj.STATUS) or (p_status is null));

        return a_result;
    end;

end;

-- Создать метод записи с проверками пациента
--    на соответствие всем пунктам для записи
create or replace function KOTLYAROV_DM.request(
    p_id_patient number,
    p_id_ticket number
)
    return boolean
as
    v_count    number;
    a_journals KOTLYAROV_DM.journal_utils.t_journal_array;
begin
    a_journals := KOTLYAROV_DM.journal_utils.search_in_journal(
            p_id_patient => p_id_patient,
            p_id_ticket => p_id_ticket,
            p_status => KOTLYAROV_DM.PKG_JOURNAL_STATUS_TYPE.c_opened
        );

    if (a_journals.COUNT != 0) then
        return false;
    end if;

    select count(t.ID)
    into v_count
    from KOTLYAROV_DM.TICKETS t
             INNER JOIN KOTLYAROV_DM.PATIENTS p on p.ID = p_id_patient
             INNER JOIN KOTLYAROV_DM.DOCTOR_SPECIALTY ds on ds.ID = t.ID_DOCTOR_SPECIALITY
             INNER JOIN KOTLYAROV_DM.SPECIALITIES s on s.ID = ds.ID_SPECIALITY
             INNER JOIN KOTLYAROV_DM.DOCTORS d on d.ID = ds.ID_DOCTOR
             INNER JOIN KOTLYAROV_DM.HOSPITALS h on h.ID = d.ID_HOSPITAL
             INNER JOIN KOTLYAROV_DM.AGE_GROUPS ag on ag.ID = s.ID_AGE_GROUP
             INNER JOIN KOTLYAROV_DM.SPECIALITY_GENDER sg on sg.ID_SPECIALITY = s.ID
             INNER JOIN KOTLYAROV_DM.PATIENT_DOCUMENTS pd on pd.ID_PATIENT = p_id_patient
    WHERE t.id = p_id_ticket
      and t.CLOSED = 0
      AND p.ID_GENDER = sg.ID_GENDER
      and t.TIME_BEGIN > sysdate
      and d.DELETED_AT is null
      and s.DELETED_AT is null
      and h.DELETED_AT is null
      and pd.ID_DOCUMENT_TYPE = 4 -- ОМС
      AND add_months(p.BIRTHDATE, ag.AGE_BEGIN * 12) <= sysdate
      AND add_months(p.BIRTHDATE, ag.AGE_END * 12) > sysdate;

    if (v_count = 1) then
        if (KOTLYAROV_DM.journal_utils.search_in_journal(
                    p_id_ticket => p_id_ticket,
                    p_id_patient => p_id_patient
                ).COUNT = 1) then
            KOTLYAROV_DM.journal_utils.update_status(
                    p_id_ticket => p_id_ticket,
                    p_id_patient => p_id_patient,
                    p_status => KOTLYAROV_DM.PKG_JOURNAL_STATUS_TYPE.c_opened
                );
        else
            KOTLYAROV_DM.journal_utils.insert_row(
                    p_id_ticket => p_id_ticket,
                    p_id_patient => p_id_patient,
                    p_status => KOTLYAROV_DM.PKG_JOURNAL_STATUS_TYPE.c_opened
                );
        end if;

        commit;
        return true;
    end if;

    return false;
end;

declare
    v_result boolean;
begin
    v_result := KOTLYAROV_DM.REQUEST(
            p_id_patient => 4,
            p_id_ticket => 2480
        );

    if (v_result) then
        DBMS_OUTPUT.PUT_LINE('All ok');
    else
        DBMS_OUTPUT.PUT_LINE('Patient not suitable for this ticket');
    end if;
end;


-- Пишем функцию отмены записи
create or replace function KOTLYAROV_DM.cancel(
    p_id_patient number,
    p_id_ticket number
)
    return boolean
as
    v_count number;
    a_journals KOTLYAROV_DM.journal_utils.t_journal_array;
begin
    a_journals := KOTLYAROV_DM.journal_utils.search_in_journal(
            p_id_patient => p_id_patient,
            p_id_ticket => p_id_ticket,
            p_status => KOTLYAROV_DM.PKG_JOURNAL_STATUS_TYPE.c_opened
        );

    if (a_journals.COUNT != 1) then
        return false;
    end if;

    select count(*)
    into v_count
    from KOTLYAROV_DM.TICKETS t
             INNER JOIN KOTLYAROV_DM.DOCTOR_SPECIALTY ds on ds.ID = t.ID_DOCTOR_SPECIALITY
             INNER JOIN KOTLYAROV_DM.SPECIALITIES s on s.ID = ds.ID_SPECIALITY
             INNER JOIN KOTLYAROV_DM.DOCTORS d on d.ID = ds.ID_DOCTOR
             INNER JOIN KOTLYAROV_DM.HOSPITAL_WORK_TIMES wt on wt.ID_HOSPITAL = d.ID_HOSPITAL
    where t.TIME_BEGIN > sysdate
      and t.id = p_id_ticket
      and wt.ID_WEEK_DAY = to_number(to_char(sysdate, 'D'))
      and wt.END_TIME > to_char(sysdate + ((1 / 24) * 2), 'hh24:mi');

    if (v_count != 1) then
        return false;
    end if;

    KOTLYAROV_DM.journal_utils.update_status(
        p_id_ticket => p_id_ticket,
        p_id_patient => p_id_patient,
        p_status => KOTLYAROV_DM.PKG_JOURNAL_STATUS_TYPE.c_cancelled
    );

    update KOTLYAROV_DM.TICKETS
    set CLOSED = 0
    where id = p_id_ticket;

    commit;

    return true;
end;

declare
    v_result boolean;
begin
    v_result := KOTLYAROV_DM.CANCEL(
            p_id_patient => 4,
            p_id_ticket => 2480
        );

    if (v_result) then
        DBMS_OUTPUT.PUT_LINE('All ok');
    else
        DBMS_OUTPUT.PUT_LINE('Error cancelling');
    end if;
end;


-- создать два пакета (можно не связанные с проектом)
-- вызывающие друг друга.
-- понять как такое компилировать в одном файле скрипта
create or replace package pkg_test1
as
    procedure p(p_message varchar2);
    procedure test;
end;

create or replace package body pkg_test1
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

create or replace package pkg_test2
as
    procedure p(p_message varchar2);
    procedure test;
end;

create or replace package body pkg_test2
as
    procedure p(p_message varchar2) as
    begin
        DBMS_OUTPUT.PUT_LINE(p_message);
    end;

    procedure test as
    begin
        KOTLYAROV_DM.PKG_TEST2.P('call from pkg_test2');
    end test;
end;