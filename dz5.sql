-- Константы типов больниц
create or replace package KOTLYAROV_DM.enum_hospital_utils
as
    function c_government return number deterministic;
    function c_private return number deterministic;
end;

create or replace package body KOTLYAROV_DM.enum_hospital_utils
as
    function c_government return number deterministic as
    begin
        return 2;
    end;
    function c_private return number deterministic as
    begin
        return 1;
    end;
end;

-- Константы статусов записей в журнале
create or replace package KOTLYAROV_DM.enum_journal_status_type
as
    function c_opened return number deterministic;
    function c_cancelled return number deterministic;
end;

-- Константы статусов записей в журнале
create or replace package body KOTLYAROV_DM.enum_journal_status_type
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
        ORDER BY case when h.id_type = KOTLYAROV_DM.enum_hospital_utils.c_private then 1 else 0 end, doc_count DESC,
                 hwt.END_TIME DESC;

    return v_result;
end;

create or replace package KOTLYAROV_DM.pkg_hospital_utils
as
    function get_hospital_by_id(hospital_id number) return KOTLYAROV_DM.HOSPITALS%rowtype;
end;

create or replace package body KOTLYAROV_DM.pkg_hospital_utils
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
    type t_journal_array is table of KOTLYAROV_DM.PATIENT_JOURNALS%rowtype;
    record_not_found exception;

    procedure insert_row(p_id_ticket number, p_id_patient number, p_status smallint, p_commit boolean := true);
    procedure update_status(p_id_ticket number, p_id_patient number, p_status smallint, p_commit boolean := true);
    procedure exc_update_status(p_id_ticket number, p_id_patient number, p_status smallint, p_commit boolean := true);
    function search_in_journal(p_id_ticket number := null, p_id_patient number := null,
                               p_status smallint := null) return t_journal_array;
end;

create or replace package body KOTLYAROV_DM.journal_utils
as
    procedure insert_row(p_id_ticket number, p_id_patient number, p_status smallint, p_commit boolean := true)
    as
    begin
        insert into KOTLYAROV_DM.PATIENT_JOURNALS (ID_PATIENT, ID_TICKET, STATUS)
        values (p_id_patient, p_id_ticket, p_status);

        if (p_commit) then
            commit;
        end if;

    exception
        when others then
            KOTLYAROV_DM.ADD_SYSTEM_LOG(
                        $$plsql_unit_owner || '.' || $$plsql_unit || '.' || utl_call_stack.subprogram(1)(2),
                        '{"error":"' || sqlerrm
                            || '","p_id_ticket":"' || p_id_ticket
                            || '","p_id_patient":"' || p_id_patient
                            || '","p_status":"' || p_status
                            || '","backtrace":"' || dbms_utility.format_error_backtrace()
                            || '"}',
                        'error'
                );
    end;

    procedure update_status(p_id_ticket number, p_id_patient number, p_status smallint, p_commit boolean := true)
    as
    begin
        update KOTLYAROV_DM.PATIENT_JOURNALS
        set status = p_status
        where id_patient = p_id_patient
          and id_ticket = p_id_ticket;

        if (p_commit) then
            commit;
        end if;
    end;

    -- внедрить например в одну из check функций при записи
    procedure exc_update_status(p_id_ticket number, p_id_patient number, p_status smallint, p_commit boolean := true)
    as
    begin
        update KOTLYAROV_DM.PATIENT_JOURNALS
        set status = p_status
        where id_patient = p_id_patient
          and id_ticket = p_id_ticket;

        if (p_commit) then
            commit;
        end if;

        if (sql%rowcount = 0) then
            raise KOTLYAROV_DM.JOURNAL_UTILS.record_not_found;
        end if;
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

create or replace package KOTLYAROV_DM.ticket_utils
as
    procedure update_ticket_closed_status(p_id_ticket number, p_closed boolean, p_commit boolean := true);
end;

create or replace package body KOTLYAROV_DM.ticket_utils
as
    procedure update_ticket_closed_status(p_id_ticket number, p_closed boolean, p_commit boolean := true)
    as
        v_closed number;
    begin
        v_closed := case when p_closed then 1 else 0 end;

        update KOTLYAROV_DM.tickets
        set CLOSED = v_closed
        where ID = p_id_ticket;

        if (p_commit) then
            commit;
        end if;
    end;
end;

create or replace package KOTLYAROV_DM.business_logic_utils
as
    function is_patient_suit_for_ticket(p_id_patient number, p_id_ticket number) return boolean;
    function can_cancel_requested_ticket(p_id_ticket number) return boolean;
end;

create or replace package body KOTLYAROV_DM.business_logic_utils
as
    function is_patient_suit_for_ticket(p_id_patient number, p_id_ticket number) return boolean
    as
        v_count number;
    begin
        select count(*)
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

        return v_count = 1;
    end;

    function can_cancel_requested_ticket(p_id_ticket number) return boolean
    as
        v_count number;
    begin
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

        return v_count = 1;
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
    a_journals KOTLYAROV_DM.journal_utils.t_journal_array;
begin
    a_journals := KOTLYAROV_DM.journal_utils.search_in_journal(
            p_id_patient => p_id_patient,
            p_id_ticket => p_id_ticket,
            p_status => KOTLYAROV_DM.enum_journal_status_type.c_opened
        );

    if (a_journals.COUNT != 0) then
        KOTLYAROV_DM.ADD_SYSTEM_LOG(
                    $$plsql_unit_owner || '.' || $$plsql_unit,
                    '{"error":"' || 'Ticket already in journal'
                        || '","p_id_ticket":"' || p_id_ticket
                        || '","p_id_patient":"' || p_id_patient
                        || '","backtrace":"' || dbms_utility.format_error_backtrace()
                        || '"}',
                    'warning'
            );
        return false;
    end if;

    if (not KOTLYAROV_DM.business_logic_utils.is_patient_suit_for_ticket(
            p_id_patient => p_id_patient,
            p_id_ticket => p_id_ticket
        )) then
        KOTLYAROV_DM.ADD_SYSTEM_LOG(
                    $$plsql_unit_owner || '.' || $$plsql_unit,
                    '{"error":"' || 'Patient is not suitable for ticket'
                        || '","p_id_ticket":"' || p_id_ticket
                        || '","p_id_patient":"' || p_id_patient
                        || '","backtrace":"' || dbms_utility.format_error_backtrace()
                        || '"}',
                    'debug'
            );
        return false;
    end if;

    if (KOTLYAROV_DM.journal_utils.search_in_journal(
                p_id_ticket => p_id_ticket,
                p_id_patient => p_id_patient
            ).COUNT = 1) then
        KOTLYAROV_DM.journal_utils.update_status(
                p_id_ticket => p_id_ticket,
                p_id_patient => p_id_patient,
                p_status => KOTLYAROV_DM.enum_journal_status_type.c_opened,
                p_commit => false
            );
    else
        KOTLYAROV_DM.journal_utils.insert_row(
                p_id_ticket => p_id_ticket,
                p_id_patient => p_id_patient,
                p_status => KOTLYAROV_DM.enum_journal_status_type.c_opened,
                p_commit => false
            );
    end if;

    KOTLYAROV_DM.ticket_utils.update_ticket_closed_status(
            p_id_ticket => p_id_ticket,
            p_closed => true,
            p_commit => false
        );

    commit;
    return true;
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
    a_journals KOTLYAROV_DM.journal_utils.t_journal_array;
begin
    a_journals := KOTLYAROV_DM.journal_utils.search_in_journal(
            p_id_patient => p_id_patient,
            p_id_ticket => p_id_ticket,
            p_status => KOTLYAROV_DM.enum_journal_status_type.c_opened
        );

    if (a_journals.COUNT != 1) then
        KOTLYAROV_DM.ADD_SYSTEM_LOG(
                    $$plsql_unit_owner || '.' || $$plsql_unit,
                    '{"error":"' || 'Journal record not found'
                        || '","p_id_ticket":"' || p_id_ticket
                        || '","p_id_patient":"' || p_id_patient
                        || '","backtrace":"' || dbms_utility.format_error_backtrace()
                        || '"}',
                    'warning'
            );
        return false;
    end if;

    if (not KOTLYAROV_DM.business_logic_utils.can_cancel_requested_ticket(p_id_ticket)) then
        KOTLYAROV_DM.ADD_SYSTEM_LOG(
                    $$plsql_unit_owner || '.' || $$plsql_unit,
                    '{"error":"' || 'Ticket request can not be cancelled'
                        || '","p_id_ticket":"' || p_id_ticket
                        || '","p_id_patient":"' || p_id_patient
                        || '","backtrace":"' || dbms_utility.format_error_backtrace()
                        || '"}',
                    'debug'
            );
        return false;
    end if;

    KOTLYAROV_DM.journal_utils.update_status(
            p_id_ticket => p_id_ticket,
            p_id_patient => p_id_patient,
            p_status => KOTLYAROV_DM.enum_journal_status_type.c_cancelled,
            p_commit => false
        );

    KOTLYAROV_DM.ticket_utils.update_ticket_closed_status(
            p_id_ticket => p_id_ticket,
            p_closed => false,
            p_commit => false
        );

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
