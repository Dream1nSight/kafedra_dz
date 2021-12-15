
-- Типы
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
