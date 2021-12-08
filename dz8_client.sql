
create or replace package KOTLYAROV_DM.pkg_integration_client
as
    function get_hospitals(p_url varchar2) return clob;
    function get_specialties(p_url varchar2) return clob;
    function get_doctors(p_url varchar2) return clob;
end;

create or replace package body KOTLYAROV_DM.pkg_integration_client
as
    function get_hospitals(p_url varchar2) return clob
    as
        v_data     clob;
        v_success  boolean;
        v_out_code number;
    begin
        v_data := KOTLYAROV_DM.HTTP_FETCH(
                p_url => p_url || '/hospitals',
                out_success => v_success,
                p_debug => true,
                out_code => v_out_code
            );

        if (v_success) then
            return v_data;
        else
            return null;
        end if;
    end;

    function get_specialties(p_url varchar2) return clob
    as
        v_data     clob;
        v_success  boolean;
        v_out_code number;
    begin
        v_data := KOTLYAROV_DM.HTTP_FETCH(
                p_url => p_url || '/specialties',
                out_success => v_success,
                p_debug => true,
                out_code => v_out_code
            );

        if (v_success) then
            return v_data;
        else
            return null;
        end if;
    end;

    function get_doctors(p_url varchar2) return clob
    as
        v_data     clob;
        v_success  boolean;
        v_out_code number;
    begin
        v_data := KOTLYAROV_DM.HTTP_FETCH(
                p_url => p_url || '/doctors',
                out_success => v_success,
                p_debug => true,
                out_code => v_out_code
            );

        if (v_success) then
            return v_data;
        else
            return null;
        end if;
    end;
end;