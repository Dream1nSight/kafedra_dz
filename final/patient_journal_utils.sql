
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

-- Типы
create or replace type KOTLYAROV_DM.t_patient_journal as object
(
    id_patient number,
    id_ticket  number,
    status     smallint,

    constructor function t_patient_journal(
        id_patient number,
        id_ticket number,
        status smallint
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_patient_journal as table of KOTLYAROV_DM.t_patient_journal;

create or replace type body KOTLYAROV_DM.t_patient_journal as
    constructor function t_patient_journal(
        id_patient number,
        id_ticket number,
        status smallint
    ) return self as result as
    begin
        self.id_patient := id_patient;
        self.id_ticket := id_ticket;
        self.status := status;

        return;
    end;
end;

create or replace package KOTLYAROV_DM.pkg_journal_utils
as
    type t_journal_array is table of KOTLYAROV_DM.T_PATIENT_JOURNAL;
    record_not_found exception;

    procedure insert_row(p_id_ticket number, p_id_patient number, p_status smallint);
    procedure update_status(p_id_ticket number, p_id_patient number, p_status smallint);
    procedure exc_update_status(p_id_ticket number, p_id_patient number, p_status smallint);
    function search_in_journal(p_id_ticket number := null, p_id_patient number := null,
                               p_status smallint := null) return t_journal_array;
end;

create or replace package body KOTLYAROV_DM.pkg_journal_utils
as
    procedure insert_row(p_id_ticket number, p_id_patient number, p_status smallint)
    as
    begin
        insert into KOTLYAROV_DM.PATIENT_JOURNALS (ID_PATIENT, ID_TICKET, STATUS)
        values (p_id_patient, p_id_ticket, p_status);

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

    procedure update_status(p_id_ticket number, p_id_patient number, p_status smallint)
    as
    begin
        update KOTLYAROV_DM.PATIENT_JOURNALS
        set status = p_status
        where id_patient = p_id_patient
          and id_ticket = p_id_ticket;

    end;

    -- внедрить например в одну из check функций при записи
    procedure exc_update_status(p_id_ticket number, p_id_patient number, p_status smallint)
    as
    begin
        update KOTLYAROV_DM.PATIENT_JOURNALS
        set status = p_status
        where id_patient = p_id_patient
          and id_ticket = p_id_ticket;

        if (sql%rowcount = 0) then
            raise KOTLYAROV_DM.pkg_journal_utils.record_not_found;
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