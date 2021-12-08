create or replace type KOTLYAROV_DM.t_integration_hospital as object
(
    id_hospital number,
    name        varchar2(255),
    address     varchar2(255),
    id_town     number,

    constructor function t_integration_hospital(
        id_hospital number,
        name varchar2,
        address varchar2,
        id_town number
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_integration_hospital as table of KOTLYAROV_DM.t_integration_hospital;

create or replace type body KOTLYAROV_DM.t_integration_hospital as
    constructor function t_integration_hospital(
        id_hospital number,
        name varchar2,
        address varchar2,
        id_town number
    ) return self as result as
    begin
        self.id_hospital := id_hospital;
        self.name := name;
        self.address := address;
        self.id_town := id_town;

        return;
    end;
end;

create or replace type KOTLYAROV_DM.t_integration_specialty as object
(
    id_specialty number,
    name         varchar2(255),
    id_hospital  number,

    constructor function t_integration_specialty(
        id_specialty number,
        name varchar2,
        id_hospital number
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_integration_specialty as table of KOTLYAROV_DM.t_integration_specialty;

create or replace type body KOTLYAROV_DM.t_integration_specialty as
    constructor function t_integration_specialty(
        id_specialty number,
        name varchar2,
        id_hospital number
    ) return self as result as
    begin
        self.id_specialty := id_specialty;
        self.name := name;
        self.id_hospital := id_hospital;

        return;
    end;
end;

create or replace type KOTLYAROV_DM.t_integration_doctor as object
(
    id_doctor    number,
    id_hospital  number,
    id_specialty number,
    lname        varchar2(255),
    fname        varchar2(255),
    mname        varchar2(255),

    constructor function t_integration_doctor(
        id_doctor number,
        id_hospital number,
        id_specialty number,
        lname varchar2,
        fname varchar2,
        mname varchar2
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_integration_doctor as table of KOTLYAROV_DM.t_integration_doctor;

create or replace type body KOTLYAROV_DM.t_integration_doctor as
    constructor function t_integration_doctor(
        id_doctor number,
        id_hospital number,
        id_specialty number,
        lname varchar2,
        fname varchar2,
        mname varchar2
    ) return self as result as
    begin
        self.id_doctor := id_doctor;
        self.id_hospital := id_hospital;
        self.id_specialty := id_specialty;
        self.lname := lname;
        self.fname := fname;
        self.mname := mname;

        return;
    end;
end;

create or replace package KOTLYAROV_DM.pkg_integration_client
as
    function get_hospitals(p_url varchar2) return KOTLYAROV_DM.a_integration_hospital;
    function get_specialties(p_url varchar2) return KOTLYAROV_DM.a_integration_specialty;
    function get_doctors(p_url varchar2) return KOTLYAROV_DM.a_integration_doctor;
end;

create or replace package body KOTLYAROV_DM.pkg_integration_client
as
    function get_hospitals(p_url varchar2) return KOTLYAROV_DM.a_integration_hospital
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

    function get_specialties(p_url varchar2) return KOTLYAROV_DM.a_integration_specialty
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

    function get_doctors(p_url varchar2) return KOTLYAROV_DM.a_integration_doctor
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

begin
    sys.dbms_scheduler.create_job(
            job_name => 'kotlyarov.dl.job_cache_hospitals',
            start_date => current_timestamp,
            repeat_interval => 'FREQ=HOURLY;INTERVAL=1;',
            end_date => null,
            job_class => 'STORED_PROCEDURE',
            job_action => 'begin student.job_test_action; end;'
        );

    sys.dbms_scheduler.create_job(
            job_name => 'kotlyarov.dl.job_cache_specialties',
            start_date => current_timestamp,
            repeat_interval => 'FREQ=HOURLY;INTERVAL=1;',
            end_date => null,
            job_class => 'STORED_PROCEDURE',
            job_action => 'begin student.job_test_action; end;'
        );

    sys.dbms_scheduler.create_job(
            job_name => 'kotlyarov.dl.job_cache_doctors',
            start_date => current_timestamp,
            repeat_interval => 'FREQ=HOURLY;INTERVAL=1;',
            end_date => null,
            job_class => 'STORED_PROCEDURE',
            job_action => 'begin student.job_test_action; end;'
        );
end;