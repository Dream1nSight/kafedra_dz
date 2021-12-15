
-- Типы
create or replace type KOTLYAROV_DM.t_doctor as object
(
    id            number,
    deleted_at    date,
    area          varchar2(255),
    degree        numeric,
    qualification varchar2(255),
    salary        number,
    id_hospital   number,
    id_integration_doctor number,

    constructor function t_doctor(
        id number,
        deleted_at date,
        area varchar2,
        degree numeric,
        qualification varchar2,
        salary number,
        id_hospital number,
        id_integration_specialty number,
        id_integration_doctor number
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_doctor as table of KOTLYAROV_DM.t_doctor;

create or replace type body KOTLYAROV_DM.t_doctor as
    constructor function t_doctor(
        id number,
        deleted_at date,
        area varchar2,
        degree numeric,
        qualification varchar2,
        salary number,
        id_hospital number,
        id_integration_doctor number
    ) return self as result as
    begin
        self.id := id;
        self.deleted_at := deleted_at;
        self.area := area;
        self.degree := degree;
        self.qualification := qualification;
        self.salary := salary;
        self.id_hospital := id_hospital;
        self.id_integration_doctor := id_integration_doctor;

        return;
    end;
end;

create or replace type KOTLYAROV_DM.t_doctor_review as object
(
    id        number,
    id_doctor number,
    review    varchar2(4000),
    rate      number(1),

    constructor function t_doctor_review(
        id number,
        id_doctor number,
        review varchar2,
        rate number
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_doctor_review as table of KOTLYAROV_DM.t_doctor_review;

create or replace type body KOTLYAROV_DM.t_doctor_review as
    constructor function t_doctor_review(
        id number,
        id_doctor number,
        review varchar2,
        rate number
    ) return self as result as
    begin
        self.id := id;
        self.id_doctor := id_doctor;
        self.review := review;
        self.rate := rate;

        return;
    end;
end;
