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


create or replace package KOTLYAROV_DM.pkg_integration_repository
as
    function get_hospitals return KOTLYAROV_DM.a_integration_hospital;
    function get_specialties return KOTLYAROV_DM.a_integration_specialty;
    function get_doctors return KOTLYAROV_DM.a_integration_doctor;
end;

create or replace package body KOTLYAROV_DM.pkg_integration_repository
as
    function get_hospitals return KOTLYAROV_DM.a_integration_hospital
    as
        v_data     clob;
        v_response KOTLYAROV_DM.a_integration_hospital := KOTLYAROV_DM.a_integration_hospital();
    begin
        v_data :=
                KOTLYAROV_DM.PKG_INTEGRATION_CLIENT.GET_HOSPITALS('https://virtserver.swaggerhub.com/AntonovAD/DoctorDB/1.0.0');

        if (v_data is null) then
            return null;
        end if;

        select KOTLYAROV_DM.T_INTEGRATION_HOSPITAL(
                       id_hospital => r.id_hospital,
                       name => r.name,
                       address => r.address,
                       id_town => r.id_town
                   ) bulk collect
        into v_response
        from json_table(v_data, '$' columns (
            nested path '$[*]' columns (
                id_hospital number path '$.id_hospital',
                name varchar2(255) path '$.name',
                address varchar2(255) path '$.address',
                id_town number path '$.id_town'
                ))) r;

        return v_response;
    end;

    function get_specialties return KOTLYAROV_DM.a_integration_specialty
    as
        v_data     clob;
        v_response KOTLYAROV_DM.a_integration_specialty := KOTLYAROV_DM.a_integration_specialty();
    begin
        v_data :=
                KOTLYAROV_DM.PKG_INTEGRATION_CLIENT.GET_SPECIALTIES('https://virtserver.swaggerhub.com/AntonovAD/DoctorDB/1.0.0');

        if (v_data is null) then
            return null;
        end if;

        select KOTLYAROV_DM.T_INTEGRATION_SPECIALTY(
                       id_specialty => r.id_specialty,
                       name => r.name,
                       id_hospital => r.id_hospital
                   ) bulk collect
        into v_response
        from json_table(v_data, '$' columns (
            nested path '$[*]' columns (
                id_specialty number path '$.id_specialty',
                name varchar2(255) path '$.name',
                id_hospital number path '$.id_hospital'
                ))) r;

        return v_response;
    end;

    function get_doctors return KOTLYAROV_DM.a_integration_doctor
    as
        v_data     clob;
        v_response KOTLYAROV_DM.a_integration_doctor := KOTLYAROV_DM.a_integration_doctor();
    begin
        v_data :=
                KOTLYAROV_DM.PKG_INTEGRATION_CLIENT.GET_DOCTORS('https://virtserver.swaggerhub.com/AntonovAD/DoctorDB/1.0.0');

        if (v_data is null) then
            return null;
        end if;

        select KOTLYAROV_DM.T_INTEGRATION_DOCTOR(
                       id_doctor => r.id_doctor,
                       id_hospital => r.id_hospital,
                       id_specialty => r.id_specialty,
                       lname => r.lname,
                       fname => r.fname,
                       mname => r.mname
                   ) bulk collect
        into v_response
        from json_table(v_data, '$' columns (
            nested path '$[*]' columns (
                --следите за тем чтобы типы и их размерность
                --совпадали с типами в ваших обьектах
                id_doctor number path '$.id_doctor',
                id_hospital number path '$.id_hospital',
                id_specialty number path '$.id_specialty',
                lname varchar2(255) path '$.lname',
                fname varchar2(255) path '$.fname',
                mname varchar2(255) path '$.mname'
                ))) r;

        return v_response;
    end;
end;
