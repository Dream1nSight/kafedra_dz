-- Специальность
create or replace type KOTLYAROV_DM.t_specialty as object
(
    id           number,
    deleted_at   date,
    id_age_group number,

    constructor function t_specialty(
        id number,
        deleted_at date,
        id_age_group number
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_specialty as table of KOTLYAROV_DM.t_specialty;

create or replace type body KOTLYAROV_DM.t_specialty as
    constructor function t_specialty(
        id number,
        deleted_at date,
        id_age_group number
    ) return self as result as
    begin
        self.id := id;
        self.deleted_at := deleted_at;
        self.id_age_group := id_age_group;

        return;
    end;
end;

-- Пациент
create or replace type KOTLYAROV_DM.t_patient as object
(
    id         number,
    id_user    number,
    first_name varchar2(255),
    last_name  varchar2(255),
    patronymic varchar2(255),
    birthdate  date,
    id_gender  number,
    phone      number,
    area       varchar2(255),

    constructor function t_patient(
        id number,
        id_user number,
        first_name varchar2,
        last_name varchar2,
        patronymic varchar2,
        birthdate date,
        id_gender number,
        phone number,
        area varchar2
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_patient as table of KOTLYAROV_DM.t_patient;

create or replace type body KOTLYAROV_DM.t_patient as
    constructor function t_patient(
        id number,
        id_user number,
        first_name varchar2,
        last_name varchar2,
        patronymic varchar2,
        birthdate date,
        id_gender number,
        phone number,
        area varchar2
    ) return self as result as
    begin
        self.id := id;
        self.id_user := id_user;
        self.first_name := first_name;
        self.last_name := last_name;
        self.patronymic := patronymic;
        self.birthdate := birthdate;
        self.id_gender := id_gender;
        self.phone := phone;
        self.area := area;

        return;
    end;
end;

-- Документ
create or replace type KOTLYAROV_DM.t_document as object
(
    id               number,
    name             varchar2(255),
    id_patient       number,
    file_name        varchar2(255),
    content          blob,
    id_document_type number,

    constructor function t_document(
        id number,
        name varchar2,
        id_patient number,
        file_name varchar2,
        content blob,
        id_document_type number
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_document as table of KOTLYAROV_DM.t_document;

create or replace type body KOTLYAROV_DM.t_document as
    constructor function t_document(
        id number,
        name varchar2,
        id_patient number,
        file_name varchar2,
        content blob,
        id_document_type number
    ) return self as result as
    begin
        self.id := id;
        self.name := name;
        self.id_patient := id_patient;
        self.file_name := file_name;
        self.content := content;
        self.id_document_type := id_document_type;

        return;
    end;
end;

-- Специальность
create or replace type KOTLYAROV_DM.t_ex_patient as object
(
    patient   KOTLYAROV_DM.t_patient,
    documents KOTLYAROV_DM.a_document,

    constructor function t_ex_patient(
        patient KOTLYAROV_DM.t_patient,
        documents KOTLYAROV_DM.a_document
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_ex_patient as table of KOTLYAROV_DM.t_ex_patient;

create or replace type body KOTLYAROV_DM.t_ex_patient as
    constructor function t_ex_patient(
        patient KOTLYAROV_DM.t_patient,
        documents KOTLYAROV_DM.a_document
    ) return self as result as
    begin
        self.patient := patient;
        self.documents := documents;

        return;
    end;
end;

-- Доктор
create or replace type KOTLYAROV_DM.t_doctor as object
(
    id            number,
    deleted_at    date,
    area          varchar2(255),
    degree        numeric,
    qualification varchar2(255),
    salary        number,
    id_hospital   number,
    constructor function t_doctor(
        id number,
        deleted_at date,
        area varchar2,
        degree numeric,
        qualification varchar2,
        salary number,
        id_hospital number
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
        id_hospital number
    ) return self as result as
    begin
        self.id := id;
        self.deleted_at := deleted_at;
        self.area := area;
        self.degree := degree;
        self.qualification := qualification;
        self.salary := salary;
        self.id_hospital := id_hospital;

        return;
    end;
end;

-- Отзыв о докторе
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

-- Больница
create or replace type KOTLYAROV_DM.t_hospital as object
(
    id              number,
    deleted_at      date,
    name            varchar2(255),
    id_organization number,
    status          smallint,
    id_type         number,

    constructor function t_hospital(
        id number,
        deleted_at date,
        name varchar2,
        id_organization number,
        status smallint,
        id_type number
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
        id_type number
    ) return self as result as
    begin
        self.id := id;
        self.deleted_at := deleted_at;
        self.name := name;
        self.id_organization := id_organization;

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

-- Талон
create or replace type KOTLYAROV_DM.t_ticket as object
(
    id                   number,
    id_doctor_speciality number,
    closed               number(1, 0),
    time_begin           date,
    time_end             date,

    constructor function t_ticket(
        id number,
        id_doctor_speciality number,
        closed number := 0,
        time_begin date,
        time_end date
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_ticket as table of KOTLYAROV_DM.t_ticket;

create or replace type body KOTLYAROV_DM.t_ticket as
    constructor function t_ticket(
        id number,
        id_doctor_speciality number,
        closed number,
        time_begin date,
        time_end date
    ) return self as result as
    begin
        self.id := id;
        self.id_doctor_speciality := id_doctor_speciality;
        self.closed := closed;
        self.time_begin := time_begin;
        self.time_end := time_end;

        return;
    end;
end;

-- Журнальный талон
create or replace type KOTLYAROV_DM.t_patient_journal as object
(
    id_patient number,
    id_ticket  number,
    status     smallint,

    constructor function t_patient_journal(
        id_patient number,
        id_ticket number,
        status smallint
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_patient_journal as table of KOTLYAROV_DM.t_patient_journal;

create or replace type body KOTLYAROV_DM.t_patient_journal as
    constructor function t_patient_journal(
        id_patient number,
        id_ticket number,
        status smallint
    ) return self as result as
    begin
        self.id_patient := id_patient;
        self.id_ticket := id_ticket;
        self.status := status;

        return;
    end;
end;

-- Статус выполнения
create or replace type KOTLYAROV_DM.t_exec_status as object
(
    error number,
    message varchar2(4000),

    constructor function t_exec_status(
        error number,
        message varchar2
    ) return self as result
);

create or replace type KOTLYAROV_DM.a_exec_status as table of KOTLYAROV_DM.t_exec_status;

create or replace type body KOTLYAROV_DM.t_exec_status as
    constructor function t_exec_status(
        error number,
        message varchar2
    ) return self as result as
    begin
        self.error := error;
        self.message := message;

        return;
    end;
end;

declare
    hospital KOTLYAROV_DM.T_HOSPITAL;
begin
    hospital := KOTLYAROV_DM.pkg_hospital_utils.GET_HOSPITAL_BY_ID(1);

    DBMS_OUTPUT.PUT_LINE(
                'id: ' || hospital.ID || chr(13) ||
                'deleted_at: ' || hospital.deleted_at || chr(13) ||
                'name: ' || hospital.name || chr(13) ||
                'id_organization: ' || hospital.id_organization || chr(13) ||
                'status: ' || hospital.status || chr(13) ||
                'id_type: ' || hospital.id_type || chr(13)
        );
end;