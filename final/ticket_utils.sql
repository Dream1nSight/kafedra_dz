
-- Типы
create or replace type KOTLYAROV_DM.t_ticket as object
(
    id                   number,
    id_doctor_speciality number,
    closed               number(1, 0),
    time_begin           date,
    time_end             date,

    constructor function t_ticket(
        id number,
        id_doctor_speciality number,
        closed number := 0,
        time_begin date,
        time_end date
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_ticket as table of KOTLYAROV_DM.t_ticket;

create or replace type body KOTLYAROV_DM.t_ticket as
    constructor function t_ticket(
        id number,
        id_doctor_speciality number,
        closed number,
        time_begin date,
        time_end date
    ) return self as result as
    begin
        self.id := id;
        self.id_doctor_speciality := id_doctor_speciality;
        self.closed := closed;
        self.time_begin := time_begin;
        self.time_end := time_end;

        return;
    end;
end;

-- Утилиты
create or replace package KOTLYAROV_DM.pkg_ticket_utils
as
    procedure update_ticket_closed_status(p_id_ticket number, p_closed boolean, p_commit boolean := true);
end;

create or replace package body KOTLYAROV_DM.pkg_ticket_utils
as
    procedure update_ticket_closed_status(p_id_ticket number, p_closed boolean, p_commit boolean := true)
    as
        v_closed number;

        pragma autonomous_transaction;
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


create or replace package KOTLYAROV_DM.pkg_ticket_utils
as
    procedure update_ticket_closed_status(p_id_ticket number, p_closed boolean);
end;

create or replace package body KOTLYAROV_DM.pkg_ticket_utils
as
    procedure update_ticket_closed_status(p_id_ticket number, p_closed boolean)
    as
        v_closed number;

    begin
        v_closed := case when p_closed then 1 else 0 end;

        update KOTLYAROV_DM.tickets
        set CLOSED = v_closed
        where ID = p_id_ticket;
    end;
end;
