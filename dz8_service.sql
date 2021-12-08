create or replace function KOTLYAROV_DM.get_integration_hospitals
    return KOTLYAROV_DM.A_HOSPITAL
as
    v_integration_hospitals KOTLYAROV_DM.T_INTEGRATION_HOSPITAL := KOTLYAROV_DM.T_INTEGRATION_HOSPITAL();
    v_result                KOTLYAROV_DM.A_HOSPITAL             := KOTLYAROV_DM.A_HOSPITAL();
begin
    v_integration_hospitals := KOTLYAROV_DM.PKG_INTEGRATION_REPOSITORY.GET_HOSPITALS();

    if (v_integration_hospitals.COUNT > 0) then
        for i in v_integration_hospitals.first..v_integration_hospitals.last
            loop
                declare
                    v_item KOTLYAROV_DM.T_INTEGRATION_HOSPITAL := v_integration_hospitals(i);
                begin
                    v_result.extend();
                    v_result(i) := KOTLYAROV_DM.T_HOSPITAL(
                            deleted_at => null,
                            name => v_item.NAME,
                            status => 1,
                            id_type => KOTLYAROV_DM.enum_hospital_utils.c_private,
                            id_integration_hospital => v_item.ID_HOSPITAL
                        );
                end;
            end loop;

        return v_result;
    end if;

    return null;
end;