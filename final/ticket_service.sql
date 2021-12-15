create or replace function check_ticket_can_be_requested(
    id_ticket number,
    id_patient number
) return boolean
as
    a_journals KOTLYAROV_DM.pkg_journal_utils.t_journal_array;
begin
    a_journals := KOTLYAROV_DM.pkg_journal_utils.search_in_journal(
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
        return KOTLYAROV_DM.t_exec_status(
                error => 1,
                message => 'Ticket already in journal'
            );
    end if;

    if (not KOTLYAROV_DM.pkg_business_logic_utils.is_patient_suit_for_ticket(
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
        return KOTLYAROV_DM.t_exec_status(
                error => 2,
                message => 'Patient is not suitable for ticket'
            );
    end if;
end;