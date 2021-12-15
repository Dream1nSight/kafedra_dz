
create or replace package KOTLYAROV_DM.pkg_ticket_repository
as
    function get_ticket_by_id(p_id_ticket number) return KOTLYAROV_DM.T_TICKET;
end;

create or replace package body KOTLYAROV_DM.pkg_ticket_repository
as
    function get_ticket_by_id(p_id_ticket number)
    return KOTLYAROV_DM.T_TICKET
    as
        result KOTLYAROV_DM.T_TICKET;
    begin
        select *
        into result
        from KOTLYAROV_DM.TICKETS
        where ID = p_id_ticket;

        return result;
    end;
end;