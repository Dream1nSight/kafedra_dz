-- Выдать все города по регионам
create or replace function KOTLYAROV_DM.get_towns_by_region(
    p_id_region number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        SELECT *
        FROM KOTLYAROV_DM.TOWNS
        where (p_id_region is not null and p_id_region = id_region)
           or (p_id_region is null);

    return v_result;
end;

declare
    v_data         KOTLYAROV_DM.TOWNS%rowtype;
    v_towns_cursor sys_refcursor;
begin
    v_towns_cursor := KOTLYAROV_DM.get_towns_by_region(1);

    loop
        fetch v_towns_cursor into v_data;
        exit when v_towns_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('Town name ' || v_data.name || ', region ID ' || v_data.ID_REGION);
    end loop;
    close v_towns_cursor;
end;

-- Выдать все специальности (неудаленные),
-- в которых есть хотя бы один доктор (неудаленный),
-- которые работают в больницах (неудаленных)
create or replace function KOTLYAROV_DM.get_doctors_by_specialty(
    p_age_group number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        SELECT s.*
        FROM KOTLYAROV_DM.specialities s
                 INNER JOIN doctor_specialty ds on s.ID = ds.id_speciality
                 INNER JOIN doctors d on ds.id_doctor = d.id
                 INNER JOIN hospitals h on d.id_hospital = h.id
        WHERE s.deleted_at is not null
          AND d.deleted_at IS NULL
          AND h.deleted_at IS NULL
          AND ((p_age_group is not null and p_age_group = s.ID_AGE_GROUP) or (p_age_group is null));

    return v_result;
end;

declare
    v_data           KOTLYAROV_DM.specialities%rowtype;
    v_doctors_cursor sys_refcursor;
begin
    v_doctors_cursor := KOTLYAROV_DM.get_doctors_by_specialty(1);

    loop
        fetch v_doctors_cursor into v_data;
        exit when v_doctors_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', AGE_GROUP ' || v_data.ID_AGE_GROUP);
    end loop;
    close v_doctors_cursor;
end;

-- *Выдать все больницы (неудаленные) конкретной специальности (1) с пометками о доступности, кол-ве врачей;
-- отсортировать по типу: частные выше,
-- по кол-ву докторов: где больше выше,
-- по времени работы: которые еще работают выше
--
-- status 0 = недоступно
create or replace function KOTLYAROV_DM.get_hospitals_by_speciality(
    p_id_specialty number := null,
    p_hospital_status number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        SELECT h.ID,
               h.id_type,
               h.NAME,
               h.id_organization,
               h.STATUS,
               COUNT(d.id) AS doc_count
        FROM KOTLYAROV_DM.HOSPITALS h
                 INNER JOIN KOTLYAROV_DM.doctors d on d.id_hospital = h.id
                 INNER JOIN KOTLYAROV_DM.doctor_specialty ds on d.id = ds.id_doctor
                 INNER JOIN KOTLYAROV_DM.specialities s on ds.id_speciality = s.id
                 INNER JOIN KOTLYAROV_DM.HOSPITAL_WORK_TIMES hwt on h.ID = hwt.id_hospital
        WHERE h.deleted_at IS NULL
          AND hwt.END_TIME > to_char(systimestamp, 'hh24:mi')
          AND ((p_hospital_status is not null and p_hospital_status = h.status) or (p_hospital_status is null))
          AND ((p_id_specialty is not null and p_id_specialty = s.ID) or (p_id_specialty is null))
        GROUP BY hwt.END_TIME, h.id_type, h.id, h.NAME, h.id_organization, h.STATUS
        ORDER BY case when h.id_type = 1 then 1 else 0 end, doc_count DESC, hwt.END_TIME DESC;

    return v_result;
end;

declare
    type hospital_info is record
                          (
                              id              number,
                              id_type         number,
                              name            varchar2(100),
                              id_organization number,
                              status          number,
                              doc_count       number
                          );

    v_data                 hospital_info;
    v_hospital_info_cursor sys_refcursor;
begin
    v_hospital_info_cursor := KOTLYAROV_DM.get_hospitals_by_speciality();

    loop
        fetch v_hospital_info_cursor into v_data;
        exit when v_hospital_info_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', name ' || v_data.name);
    end loop;
    close v_hospital_info_cursor;
end;

-- Выдать всех врачей (неудаленных) конкретной больницы,
-- отсортировать по квалификации: у кого есть выше,
-- по участку: если участок совпадает с участком пациента, то такие выше
create or replace function KOTLYAROV_DM.get_doctors_by_hospital(
    p_id_hospital number := null,
    p_area varchar2 := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        SELECT d.*
        FROM KOTLYAROV_DM.DOCTORS d
                 INNER JOIN hospitals h on d.id_hospital = h.id
        WHERE d.deleted_at IS NULL
          and ((p_id_hospital is not null and p_id_hospital = h.id) or (p_id_hospital is null))
        ORDER BY d.degree desc,
                 CASE WHEN ((p_area is not null and p_area = d.AREA) or (p_area is null)) THEN 1 ELSE 0 END;

    return v_result;
end;

declare
    v_data           KOTLYAROV_DM.DOCTORS%rowtype;
    v_doctors_cursor sys_refcursor;
begin
    v_doctors_cursor := KOTLYAROV_DM.get_doctors_by_hospital(
            p_id_hospital => 1,
            p_area => 'area 2'
        );

    loop
        fetch v_doctors_cursor into v_data;
        exit when v_doctors_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', AREA ' || v_data.AREA);
    end loop;
    close v_doctors_cursor;
end;

-- Выдать все талоны конкретного врача (1), не показывать талоны которые начались раньше текущего времени
create or replace function KOTLYAROV_DM.get_tickets_by_doctor(
    filter_id_doctor number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        SELECT t.*
        FROM KOTLYAROV_DM.TICKETS t
                 INNER JOIN DOCTOR_SPECIALTY ds on t.ID_DOCTOR_SPECIALITY = ds.id
        WHERE t.TIME_BEGIN > current_date
          and ((filter_id_doctor IS NOT NULL and ds.ID_DOCTOR = filter_id_doctor) or (filter_id_doctor is null));

    return v_result;
end;

declare
    v_data           KOTLYAROV_DM.TICKETS%rowtype;
    v_tickets_cursor sys_refcursor;
begin
    v_tickets_cursor := KOTLYAROV_DM.get_tickets_by_doctor(1);

    loop
        fetch v_tickets_cursor into v_data;
        exit when v_tickets_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', AREA ' || v_data.TIME_END);
    end loop;
    close v_tickets_cursor;
end;


-- выдать документы
create or replace function KOTLYAROV_DM.get_documents_by_patient(
    p_id_patient number,
    p_id_document_type number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        select *
        from KOTLYAROV_DM.PATIENT_DOCUMENTS
        where id = p_id_patient
          and ((p_id_document_type is not null and ID_DOCUMENT_TYPE = p_id_document_type) or
               (p_id_document_type is null));

    return v_result;
end;

declare
    v_document         KOTLYAROV_DM.patient_documents%rowtype;
    v_documents_cursor sys_refcursor;
begin
    v_documents_cursor := KOTLYAROV_DM.get_documents_by_patient(
            p_id_patient => 4,
            p_id_document_type => 2
        );

    loop
        fetch v_documents_cursor into v_document;
        exit when v_documents_cursor%notfound;

        dbms_output.put_line('Document patient ID ' || v_document.id || ', document type ' ||
                             v_document.ID_DOCUMENT_TYPE ||
                             ', document name ' || v_document.NAME);
    end loop;

    close v_documents_cursor;
end;


-- выдать расписание больниц
create or replace function KOTLYAROV_DM.get_hospitals_work_time(
    p_id_hospital number := null,
    p_id_week_day number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        select *
        from KOTLYAROV_DM.HOSPITAL_WORK_TIMES
        where ((p_id_hospital is not null and p_id_hospital = ID_HOSPITAL) or (p_id_hospital is null))
          and ((p_id_week_day is not null and p_id_week_day = ID_WEEK_DAY) or
               (p_id_week_day is null));
    return v_result;
end;

declare
    type t_hospital_work_times is table of KOTLYAROV_DM.HOSPITAL_WORK_TIMES%rowtype;
    v_hospital_work_times_cursor sys_refcursor;
begin
    v_hospital_work_times_cursor := KOTLYAROV_DM.get_hospitals_work_time(
            p_id_hospital => 1
        );
    loop
        declare
            v_work_time KOTLYAROV_DM.HOSPITAL_WORK_TIMES%rowtype;
        begin
            fetch v_hospital_work_times_cursor into v_work_time;
            exit when v_hospital_work_times_cursor%notfound;

            dbms_output.put_line('Hospital ID ' || v_work_time.ID_HOSPITAL || ', week day ' ||
                                 v_work_time.ID_WEEK_DAY ||
                                 ', begin time ' || v_work_time.BEGIN_TIME || ', end time ' ||
                                 v_work_time.END_TIME);
        end;
    end loop;
end;


-- выдать журнал пациента
create or replace function KOTLYAROV_DM.get_patient_journald_by_patient_id(
    p_id_patient number := null
)
    return sys_refcursor
as
    v_result sys_refcursor;
begin
    open v_result for
        select *
        from KOTLYAROV_DM.PATIENT_JOURNALS
        where ((p_id_patient is not null and p_id_patient = ID_PATIENT) or (p_id_patient is null));
    return v_result;
end;

declare
    v_patient_journals        KOTLYAROV_DM.PATIENT_JOURNALS%rowtype;
    v_patient_journald_cursor sys_refcursor;
begin
    v_patient_journald_cursor := KOTLYAROV_DM.get_patient_journald_by_patient_id(4);

    loop
        fetch v_patient_journald_cursor into v_patient_journals;
        exit when v_patient_journald_cursor%notfound;

        dbms_output.put_line('Patient ID ' || v_patient_journals.ID_PATIENT || ', ticket ID ' ||
                             v_patient_journals.ID_TICKET ||
                             ', ticket status ' || v_patient_journals.STATUS);
    end loop;

    close v_patient_journald_cursor;
end;

