-- Выдать все города по регионам
declare
    v_data     KOTLYAROV_DM.REGIONS%rowtype;
    cursor v_cursor (p_id_region number := null)
        return KOTLYAROV_DM.REGIONS%rowtype
        is
        SELECT *
        FROM KOTLYAROV_DM.REGIONS
        where ID = case when p_id_region is null then ID else p_id_region end;
begin
    --     open v_cursor_1(1);
    open v_cursor;

    loop
        fetch v_cursor into v_data;
        exit when v_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('Region name ' || v_data.name || ', code ' || v_data.CODE);
    end loop;
    close v_cursor;
end;

-- Выдать все специальности (неудаленные),
-- в которых есть хотя бы один доктор (неудаленный),
-- которые работают в больницах (неудаленных)
declare
    v_data     KOTLYAROV_DM.specialities%rowtype;
    cursor v_cursor(age_group number := null)
        return KOTLYAROV_DM.specialities%rowtype
        is
        SELECT s.*
        FROM KOTLYAROV_DM.specialities s
                 INNER JOIN doctor_specialty ds on s.ID = ds.id_speciality
                 INNER JOIN doctors d on ds.id_doctor = d.id AND d.deleted_at IS NULL
                 INNER JOIN hospitals h on d.id_hospital = h.id AND h.deleted_at IS NULL
        WHERE s.deleted_at is not null
          AND s.ID_AGE_GROUP = case when age_group is not null then age_group else s.ID_AGE_GROUP end;

begin
    open v_cursor(1);
--     open v_cursor;

    loop
        fetch v_cursor into v_data;
        exit when v_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', AGE_GROUP ' || v_data.ID_AGE_GROUP);
    end loop;
    close v_cursor;
end;

-- *Выдать все больницы (неудаленные) конкретной специальности (1) с пометками о доступности, кол-ве врачей;
-- отсортировать по типу: частные выше,
-- по кол-ву докторов: где больше выше,
-- по времени работы: которые еще работают выше
--
-- status 0 = недоступно
declare
    type record_1 is record
                     (
                         id              number,
                         id_type         number,
                         name            varchar2(100),
                         id_organization number,
                         status          number,
                         doc_count       number
                     );

    v_data record_1;
    cursor v_cursor(hospital_status number := null)
        return record_1
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
                 INNER JOIN KOTLYAROV_DM.specialities s on ds.id_speciality = s.id AND s.ID = 1
                 INNER JOIN KOTLYAROV_DM.HOSPITAL_WORK_TIMES hwt on h.ID = hwt.id_hospital
        WHERE h.deleted_at IS NULL
          AND h.status = case when hospital_status IS NOT NULL then hospital_status else h.STATUS end
          AND hwt.END_TIME > to_char(systimestamp, 'hh24:mi')
        GROUP BY hwt.END_TIME, h.id_type, h.id, h.NAME, h.id_organization, h.STATUS
        ORDER BY case when h.id_type = 1 then 1 else 0 end, doc_count DESC, hwt.END_TIME DESC
    ;

begin
    open v_cursor;

    loop
        fetch v_cursor into v_data;
        exit when v_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', name ' || v_data.name);
    end loop;
    close v_cursor;
end;

-- Выдать всех врачей (неудаленных) конкретной больницы,
-- отсортировать по квалификации: у кого есть выше,
-- по участку: если участок совпадает с участком пациента, то такие выше
declare
    v_data     KOTLYAROV_DM.DOCTORS%rowtype;
    cursor v_cursor(area varchar2 := null)
        return KOTLYAROV_DM.DOCTORS%ROWTYPE
        is
        SELECT d.*
        FROM KOTLYAROV_DM.DOCTORS d
                 INNER JOIN hospitals h on d.id_hospital = h.id
        WHERE d.deleted_at IS NULL
        ORDER BY d.degree desc,
                 CASE WHEN d.area = COALESCE(area, d.area) THEN 1 ELSE 0 END
    ;

begin
    open v_cursor('area 2');
--     open v_cursor;

    loop
        fetch v_cursor into v_data;
        exit when v_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', AREA ' || v_data.AREA);
    end loop;
    close v_cursor;
end;

-- Выдать все талоны конкретного врача (1), не показывать талоны которые начались раньше текущего времени
declare
    v_data     KOTLYAROV_DM.TICKETS%rowtype;
    cursor v_cursor(filter_id_doctor number := null)
        return KOTLYAROV_DM.TICKETS%ROWTYPE
        is
        SELECT t.*
        FROM KOTLYAROV_DM.TICKETS t
                 INNER JOIN DOCTOR_SPECIALTY ds on t.ID_DOCTOR_SPECIALITY = ds.id and ds.ID_DOCTOR = case when filter_id_doctor IS NOT NULL then filter_id_doctor else ds.ID_DOCTOR end
        WHERE t.TIME_BEGIN > current_date
    ;

begin
    open v_cursor(1);
--     open v_cursor;

    loop
        fetch v_cursor into v_data;
        exit when v_cursor%notfound;

        DBMS_OUTPUT.PUT_LINE('ID ' || v_data.ID || ', AREA ' || v_data.TIME_END);
    end loop;
    close v_cursor;
end;
