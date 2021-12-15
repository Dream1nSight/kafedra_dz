
-- Константы типов больниц
create or replace package KOTLYAROV_DM.enum_hospital_types
as
    function c_government return number deterministic;
    function c_private return number deterministic;
end;

create or replace package body KOTLYAROV_DM.enum_hospital_types
as
    function c_government return number deterministic as
    begin
        return 2;
    end;
    function c_private return number deterministic as
    begin
        return 1;
    end;
end;

create or replace package KOTLYAROV_DM.enum_hospital_statuses
as
    function c_not_working return number deterministic;
    function c_working return number deterministic;
end;

create or replace package body KOTLYAROV_DM.enum_hospital_statuses
as
    function c_not_working return number deterministic as
    begin
        return 0;
    end;
    function c_working return number deterministic as
    begin
        return 1;
    end;
end;

-- Типы
create or replace type KOTLYAROV_DM.t_hospital as object
(
    id              number,
    deleted_at      date,
    name            varchar2(255),
    id_organization number,
    status          smallint,
    id_type         number,
    id_integration_hospital number,

    constructor function t_hospital(
        id number,
        deleted_at date,
        name varchar2,
        id_organization number,
        status smallint,
        id_type number,
        id_integration_hospital number
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_hospital as table of KOTLYAROV_DM.t_hospital;

create or replace type body KOTLYAROV_DM.t_hospital as
    constructor function t_hospital(
        id number,
        deleted_at date,
        name varchar2,
        id_organization number,
        status smallint,
        id_type number,
        id_integration_hospital number
    ) return self as result as
    begin
        self.id := id;
        self.deleted_at := deleted_at;
        self.name := name;
        self.id_organization := id_organization;
        self.id_integration_hospital := id_integration_hospital;

        return;
    end;
end;

-- Расписание больницы
create or replace type KOTLYAROV_DM.t_hospital_work_time as object
(
    id          number,
    id_week_day number(1),
    id_hospital number,
    begin_time  varchar2(5),
    end_time    varchar2(5),
    constructor function t_hospital_work_time(
        id number,
        id_week_day number,
        id_hospital number,
        begin_time varchar2,
        end_time varchar2
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_hospital_work_time as table of KOTLYAROV_DM.t_hospital_work_time;

create or replace type body KOTLYAROV_DM.t_hospital_work_time as
    constructor function t_hospital_work_time(
        id number,
        id_week_day number,
        id_hospital number,
        begin_time varchar2,
        end_time varchar2
    ) return self as result as
    begin
        self.id := id;
        self.id_week_day := id_week_day;
        self.id_hospital := id_hospital;
        self.begin_time := begin_time;
        self.end_time := end_time;

        return;
    end;
end;

-- Расширенная больница (с ее расписанием)
create or replace type KOTLYAROV_DM.t_ex_hospital as object
(
    hospital    KOTLYAROV_DM.T_HOSPITAL,
    description varchar2(4000),

    constructor function t_ex_hospital(
        hospital KOTLYAROV_DM.T_HOSPITAL,
        description varchar2
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_ex_hospital as table of KOTLYAROV_DM.t_ex_hospital;

create or replace type body KOTLYAROV_DM.t_ex_hospital as
    constructor function t_ex_hospital(
        hospital KOTLYAROV_DM.T_HOSPITAL,
        description varchar2
    ) return self as result as
    begin
        self.hospital := hospital;
        self.description := description;

        return;
    end;
end;

create or replace package KOTLYAROV_DM.pkg_hospital_repository
as
    function get_hospital_by_id(p_hospital_id number) return KOTLYAROV_DM.T_HOSPITAL;
    function get_hospital_by_organization_id(p_id_organization number) return KOTLYAROV_DM.A_HOSPITAL;
    function get_integrated_hospitals return KOTLYAROV_DM.A_HOSPITAL;
end;

create or replace package body KOTLYAROV_DM.pkg_hospital_repository

as
    function get_hospital_by_id(p_hospital_id number) return KOTLYAROV_DM.T_HOSPITAL
    as
        v_result KOTLYAROV_DM.T_HOSPITAL;
    begin
        select KOTLYAROV_DM.T_HOSPITAL(
                       id => h.id,
                       deleted_at => h.deleted_at,
                       name => h.name,
                       id_organization => h.id_organization,
                       status => h.status,
                       id_type => h.id_type,
                       id_integration_hospital => h.ID_INTEGRATION_HOSPITAL
                   )
        into v_result
        from KOTLYAROV_DM.HOSPITALS H
        where id = p_hospital_id
          and DELETED_AT is null;

        return v_result;
    end;

    function get_hospital_by_organization_id(hospital_id number) return KOTLYAROV_DM.A_HOSPITAL
    as
        v_result KOTLYAROV_DM.A_HOSPITAL := KOTLYAROV_DM.A_HOSPITAL();
    begin
        select KOTLYAROV_DM.T_HOSPITAL(
                       id => h.id,
                       deleted_at => h.deleted_at,
                       name => h.name,
                       id_organization => h.id_organization,
                       status => h.status,
                       id_type => h.id_type,
                       id_integration_hospital => h.ID_INTEGRATION_HOSPITAL
                   )
        bulk collect
        into v_result
        from KOTLYAROV_DM.HOSPITALS H
        where id = hospital_id
          and DELETED_AT is null;

        return v_result;
    end;

    function get_integrated_hospitals return KOTLYAROV_DM.A_HOSPITAL
    as
        v_result KOTLYAROV_DM.A_HOSPITAL := KOTLYAROV_DM.A_HOSPITAL();
    begin
        select KOTLYAROV_DM.T_HOSPITAL(
                       id => h.id,
                       deleted_at => h.deleted_at,
                       name => h.name,
                       id_organization => h.id_organization,
                       status => h.status,
                       id_type => h.id_type,
                       id_integration_hospital => h.ID_INTEGRATION_HOSPITAL
                   )
        bulk collect
        into v_result
        from KOTLYAROV_DM.HOSPITALS H
        where id_integration_hospital is not null
          and DELETED_AT is null;

        return v_result;
    end;
end;