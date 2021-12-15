
create or replace package KOTLYAROV_DM.pkg_specialty_repository
as
    function get_specialty_by_id(p_id_ticket number) return KOTLYAROV_DM.T_SPECIALTY;
    function get_specialties_by_age_group(p_id_age_group number) return KOTLYAROV_DM.A_SPECIALTY;
end;

create or replace package body KOTLYAROV_DM.pkg_specialty_repository
as
    function get_specialty_by_id(p_id_specialty number)
    return KOTLYAROV_DM.T_SPECIALTY
    as
        result KOTLYAROV_DM.T_SPECIALTY;
    begin
        select *
        into result
        from KOTLYAROV_DM.SPECIALITIES
        where ID = p_id_specialty;

        return result;
    end;

    function get_specialties_by_age_group(p_id_specialty number)
    return KOTLYAROV_DM.A_SPECIALTY
    as
        result KOTLYAROV_DM.A_SPECIALTY;
    begin
        select *
        bulk collect into result
        from KOTLYAROV_DM.SPECIALITIES
        where ID = p_id_specialty;

        return result;
    end;
end;