
-- Выдать все города по регионам
SELECT * FROM towns WHERE region_id = 1;

-- Выдать все специальности (неудаленные),
-- в которых есть хотя бы один доктор (неудаленный),
-- которые работают в больницах (неудаленных)
SELECT specialities.*
    FROM KOTLYAROV_DM.specialities
    INNER JOIN doctor_specialty ds on SPECIALITIES.ID = ds.SPECIALITY_ID
    INNER JOIN doctors d on ds.doctor_id = d.id AND d.deleted_at IS NULL
    INNER JOIN hospitals h on d.hospital_id = h.id AND h.deleted_at IS NULL
    WHERE specialities.deleted_at IS NULL
;

-- *Выдать все больницы (неудаленные) конкретной специальности (1) с пометками о доступности, кол-ве врачей;
-- отсортировать по типу: частные выше,
-- по кол-ву докторов: где больше выше,
-- по времени работы: которые еще работают выше
--
-- status 0 = недоступно
SELECT HOSPITALS.ID, HOSPITALS.TYPE_ID, HOSPITALS.NAME, HOSPITALS.ORGANIZATION_ID, HOSPITALS.STATUS, COUNT(d.id) AS doc_count
    FROM HOSPITALS
    INNER JOIN doctors d on d.hospital_id = hospitals.id
    INNER JOIN doctor_specialty ds on d.id = ds.doctor_id
    INNER JOIN specialities s on ds.speciality_id = s.id
    join HOSPITAL_WORK_TIMES hwt on HOSPITALS.ID = hwt.HOSPITAL_ID
    WHERE s.id = 1 AND hospitals.deleted_at IS NULL AND hospitals.status <> 0
    GROUP BY hwt.END_TIME, hospitals.TYPE_ID, hospitals.id, HOSPITALS.NAME, HOSPITALS.ORGANIZATION_ID, HOSPITALS.STATUS
    ORDER BY hospitals.TYPE_ID DESC, doc_count DESC, hwt.END_TIME DESC
;

-- Выдать всех врачей (неудаленных) конкретной больницы,
-- отсортировать по квалификации: у кого есть выше,
-- по участку: если участок совпадает с участком пациента, то такие выше
SELECT DOCTORS.ID, DOCTORS.DELETED_AT, DOCTORS.AREA, DOCTORS.DEGREE, DOCTORS.HOSPITAL_ID FROM doctors
    INNER JOIN hospitals h on DOCTORS.HOSPITAL_ID = h.id
    WHERE DOCTORS.deleted_at IS NULL
    ORDER BY DOCTORS.degree, CASE WHEN DOCTORS.area = 'area2' THEN 1 ELSE 0 END
;

select sysdate from dual;

-- Выдать все талоны конкретного врача (1), не показывать талоны которые начались раньше текущего времени
SELECT * FROM TICKETS
    WHERE TICKETS.DOCTOR_ID = 1 AND TICKETS.TIME_BEGIN > current_date
;