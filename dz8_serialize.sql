create or replace function KOTLYAROV_DM.controller
    return clob
as
    v_result      integer;
    v_response    KOTLYAROV_DM.A_HOSPITAL := KOTLYAROV_DM.A_HOSPITAL();
    v_return_clob clob;
begin
    v_response := KOTLYAROV_DM.get_integration_hospitals();

    apex_json.free_output;
    apex_json.initialize_clob_output();
    apex_json.open_object();
    apex_json.write('code', case when v_result is null then -1 else 0 end);
    apex_json.open_array('response');

    if v_response.count > 0 then
        for i in v_response.first..v_response.last
            loop
                declare
                    v_item KOTLYAROV_DM.A_HOSPITAL := v_response(i);
                begin
                    apex_json.open_object();
                    apex_json.write('id', v_item.id);
                    apex_json.write('deleted_at', v_item.deleted_at);
                    apex_json.write('name', v_item.name);
                    apex_json.write('id_organization', v_item.id_organization);
                    apex_json.write('status', v_item.status);
                    apex_json.write('id_type', v_item.id_type);
                    apex_json.write('id_integration_hospital', v_item.id_integration_hospital);
                    apex_json.close_object();
                end;
            end loop;
    end if;
    apex_json.close_array();
    apex_json.close_object();
    v_return_clob := apex_json.get_clob_output;
    apex_json.free_output;

    return v_return_clob;
end;