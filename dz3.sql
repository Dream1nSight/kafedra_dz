-- Выдать все города по регионам
declare
    v_data     KOTLYAROV_DM.TOWNS%rowtype;
    cursor towns_by_region (p_id_region number := null)
        return KOTLYAROV_DM.TOWNS%rowtype
        is
        SELECT *
        FROM KOTLYAROV_DM.TOWNS
        where (p_id_region is not null and p_id_region = id)
           or (p_id_region is null)
    ;
begin
    open towns_by_region(1);
--     open towns_by_region;

    loop
        fetch towns_by_region into v_data;
        exit when towns_by_region%notfound;

        DBMS_OUTPUT.PUT_LINE('Town name ' || v_data.name || ', region ID ' || v_data.ID_REGION);
    end loop;
    close towns_by_region;
end;

-- Выдать все специальности (неудаленные),
-- в которых есть хотя бы один доктор (неудаленный),
-- которые работают в больницах (неудаленных)
declare
    v_data     KOTLYAROV_DM.specialities%rowtype;
    cursor doctors_by_specialty(p_age_group number := null)
        return KOTLYAROV_DM.specialities%rowtype
        is
        SELECT s.*
        FROM KOTLYAROV_DM.specialities s
                 INNER JOIN doctor_specialty ds on s.ID = ds.id_speciality
                 INNER JOIN doctors d on ds.id_doctor = d.id
                 INNER JOIN hospitals h on d.id_hospital = h.id
        WHERE s.deleted_at is not null
          AND d.deleted_at IS NULL
          AND h.deleted_at IS NULL
          AND ((p_age_group is not null and p_age_group = s.ID_AGE_GROUP) or (p_age_group is null))
    ;

begin
    open doctors_by_specialty(1);
--     open doctors_by_specialty;

    loop
        fetch doctors_by_specialty into v_data;
        exit when doctors_by_specialty%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', AGE_GROUP ' || v_data.ID_AGE_GROUP);
    end loop;
    close doctors_by_specialty;
end;

-- *Выдать все больницы (неудаленные) конкретной специальности (1) с пометками о доступности, кол-ве врачей;
-- отсортировать по типу: частные выше,
-- по кол-ву докторов: где больше выше,
-- по времени работы: которые еще работают выше
--
-- status 0 = недоступно
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

    v_data hospital_info;
    cursor hospitals_by_speciality(p_id_specialty number := null, p_hospital_status number := null)
        return hospital_info
        is
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
        ORDER BY case when h.id_type = 1 then 1 else 0 end, doc_count DESC, hwt.END_TIME DESC
    ;

begin
    open hospitals_by_speciality;

    loop
        fetch hospitals_by_speciality into v_data;
        exit when hospitals_by_speciality%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', name ' || v_data.name);
    end loop;
    close hospitals_by_speciality;
end;

-- Выдать всех врачей (неудаленных) конкретной больницы,
-- отсортировать по квалификации: у кого есть выше,
-- по участку: если участок совпадает с участком пациента, то такие выше
declare
    v_data     KOTLYAROV_DM.DOCTORS%rowtype;
    cursor doctors_by_hospital(p_id_hospital number := null, p_area varchar2 := null)
        return KOTLYAROV_DM.DOCTORS%ROWTYPE
        is
        SELECT d.*
        FROM KOTLYAROV_DM.DOCTORS d
                 INNER JOIN hospitals h on d.id_hospital = h.id
        WHERE d.deleted_at IS NULL
          and ((p_id_hospital is not null and p_id_hospital = h.id) or (p_id_hospital is null))
        ORDER BY d.degree desc,
                 CASE WHEN ((p_area is not null and p_area = d.AREA) or (p_area is null )) THEN 1 ELSE 0 END
    ;

begin
    open doctors_by_hospital(1, 'area 2');
--     open doctors_by_hospital(null, 'area 2');

    loop
        fetch doctors_by_hospital into v_data;
        exit when doctors_by_hospital%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', AREA ' || v_data.AREA);
    end loop;
    close doctors_by_hospital;
end;

-- Выдать все талоны конкретного врача (1), не показывать талоны которые начались раньше текущего времени
declare
    v_data     KOTLYAROV_DM.TICKETS%rowtype;
    cursor tickets_by_doctor(filter_id_doctor number := null)
        return KOTLYAROV_DM.TICKETS%ROWTYPE
        is
        SELECT t.*
        FROM KOTLYAROV_DM.TICKETS t
                 INNER JOIN DOCTOR_SPECIALTY ds on t.ID_DOCTOR_SPECIALITY = ds.id
        WHERE t.TIME_BEGIN > current_date
          and ((filter_id_doctor IS NOT NULL and ds.ID_DOCTOR = filter_id_doctor) or (filter_id_doctor is null))
    ;

begin
    open tickets_by_doctor(1);
--     open tickets_by_doctor;

    loop
        fetch tickets_by_doctor into v_data;
        exit when tickets_by_doctor%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', AREA ' || v_data.TIME_END);
    end loop;
    close tickets_by_doctor;
end;


-- выдать документы
declare
    type t_documents is table of KOTLYAROV_DM.patient_documents%rowtype;

    cursor documents_by_patient(p_id_patient number, p_id_document_type number := null)
        return  KOTLYAROV_DM.patient_documents%rowtype
        is
        select *
        from KOTLYAROV_DM.PATIENT_DOCUMENTS
        where id = p_id_patient
          and ((p_id_document_type is not null and ID_DOCUMENT_TYPE = p_id_document_type) or
               (p_id_document_type is null))
    ;
begin
    for i in documents_by_patient(4, 2)
        loop
            dbms_output.put_line('Document patient ID ' || i.id || ', document type ' || i.ID_DOCUMENT_TYPE ||
                                 ', document name ' || i.NAME);
        end loop;
end;


-- выдать расписание больниц
declare
    type t_hospital_work_times is table of KOTLYAROV_DM.HOSPITAL_WORK_TIMES%rowtype;

    cursor hospitals_work_time(p_id_hospital number := null, p_id_week_day number := null)
        is
        select *
        from KOTLYAROV_DM.HOSPITAL_WORK_TIMES
        where ((p_id_hospital is not null and p_id_hospital = ID_HOSPITAL) or (p_id_hospital is null))
          and ((p_id_week_day is not null and p_id_week_day = ID_WEEK_DAY) or
               (p_id_week_day is null))
    ;
begin
    for i in hospitals_work_time(1)
        loop
            declare
                v_work_time KOTLYAROV_DM.HOSPITAL_WORK_TIMES%rowtype;
            begin
                v_work_time := i;
                dbms_output.put_line('Hospital ID ' || v_work_time.ID_HOSPITAL || ', week day ' ||
                                     v_work_time.ID_WEEK_DAY ||
                                     ', begin time ' || v_work_time.BEGIN_TIME || ', end time ' ||
                                     v_work_time.END_TIME);
            end;
        end loop;
end;


-- выдать журнал пациента
declare
    v_patient_journals               KOTLYAROV_DM.PATIENT_JOURNALS%rowtype;
    v_patient_journald_by_id_patient sys_refcursor;
begin
    open v_patient_journald_by_id_patient for
        select *
        from KOTLYAROV_DM.PATIENT_JOURNALS
        where ID_PATIENT = 4;

    loop
        fetch v_patient_journald_by_id_patient into v_patient_journals;
        exit when v_patient_journald_by_id_patient%notfound;

        dbms_output.put_line('Patient ID ' || v_patient_journals.ID_PATIENT || ', ticket ID ' || v_patient_journals.ID_TICKET ||
                             ', ticket status ' || v_patient_journals.STATUS);
    end loop;

    close v_patient_journald_by_id_patient;
end;

