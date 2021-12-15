
-- Создать метод записи с проверками пациента
--    на соответствие всем пунктам для записи
create or replace function KOTLYAROV_DM.request(
    p_id_patient number,
    p_id_ticket number
)
    return KOTLYAROV_DM.t_exec_status
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

    if (KOTLYAROV_DM.pkg_journal_utils.search_in_journal(
                p_id_ticket => p_id_ticket,
                p_id_patient => p_id_patient
            ).COUNT = 1) then
        KOTLYAROV_DM.pkg_journal_utils.update_status(
                p_id_ticket => p_id_ticket,
                p_id_patient => p_id_patient,
                p_status => KOTLYAROV_DM.enum_journal_status_type.c_opened,
                p_commit => false
            );
    else
        KOTLYAROV_DM.pkg_journal_utils.insert_row(
                p_id_ticket => p_id_ticket,
                p_id_patient => p_id_patient,
                p_status => KOTLYAROV_DM.enum_journal_status_type.c_opened,
                p_commit => false
            );
    end if;

    KOTLYAROV_DM.pkg_ticket_utils.update_ticket_closed_status(
            p_id_ticket => p_id_ticket,
            p_closed => true,
            p_commit => false
        );

    commit;
    return KOTLYAROV_DM.t_exec_status(
            error => 0,
            message => ''
        );
end;

-- Пишем функцию отмены записи
create or replace function KOTLYAROV_DM.cancel(
    p_id_patient number,
    p_id_ticket number
)
    return KOTLYAROV_DM.t_exec_status
as
    a_journals KOTLYAROV_DM.pkg_journal_utils.t_journal_array;
begin
    a_journals := KOTLYAROV_DM.pkg_journal_utils.search_in_journal(
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
        return KOTLYAROV_DM.t_exec_status(
                error => 1,
                message => 'Journal record not found'
            );
    end if;

    if (not KOTLYAROV_DM.pkg_business_logic_utils.can_cancel_requested_ticket(p_id_ticket)) then
        KOTLYAROV_DM.ADD_SYSTEM_LOG(
                    $$plsql_unit_owner || '.' || $$plsql_unit,
                    '{"error":"' || 'Ticket request can not be cancelled'
                        || '","p_id_ticket":"' || p_id_ticket
                        || '","p_id_patient":"' || p_id_patient
                        || '","backtrace":"' || dbms_utility.format_error_backtrace()
                        || '"}',
                    'debug'
            );
        return KOTLYAROV_DM.t_exec_status(
                error => 1,
                message => 'Ticket request can not be cancelled'
            );
    end if;

    KOTLYAROV_DM.pkg_journal_utils.update_status(
            p_id_ticket => p_id_ticket,
            p_id_patient => p_id_patient,
            p_status => KOTLYAROV_DM.enum_journal_status_type.c_cancelled,
            p_commit => false
        );

    KOTLYAROV_DM.pkg_ticket_utils.update_ticket_closed_status(
            p_id_ticket => p_id_ticket,
            p_closed => false,
            p_commit => false
        );

    commit;
    return KOTLYAROV_DM.t_exec_status(
            error => 0,
            message => ''
        );
end;
