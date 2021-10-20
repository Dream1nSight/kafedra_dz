-- Выдать все города по регионам
SELECT *
FROM KOTLYAROV_DM.towns
WHERE id_region = 1;

-- Выдать все специальности (неудаленные),
-- в которых есть хотя бы один доктор (неудаленный),
-- которые работают в больницах (неудаленных)
SELECT s.*
FROM KOTLYAROV_DM.specialities s
         INNER JOIN doctor_specialty ds on s.ID = ds.id_speciality
         INNER JOIN doctors d on ds.id_doctor = d.id AND d.deleted_at IS NULL
         INNER JOIN hospitals h on d.id_hospital = h.id AND h.deleted_at IS NULL
WHERE s.deleted_at IS NULL
;

-- *Выдать все больницы (неудаленные) конкретной специальности (1) с пометками о доступности, кол-ве врачей;
-- отсортировать по типу: частные выше,
-- по кол-ву докторов: где больше выше,
-- по времени работы: которые еще работают выше
--
-- status 0 = недоступно
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
WHERE s.id = 1
  AND h.deleted_at IS NULL
  AND h.status <> 0
GROUP BY hwt.END_TIME, h.id_type, h.id, h.NAME, h.id_organization, h.STATUS
ORDER BY h.id_type DESC, doc_count DESC, hwt.END_TIME DESC
;

-- Выдать всех врачей (неудаленных) конкретной больницы,
-- отсортировать по квалификации: у кого есть выше,
-- по участку: если участок совпадает с участком пациента, то такие выше
SELECT d.ID, d.DELETED_AT, d.AREA, d.DEGREE, d.id_hospital
FROM KOTLYAROV_DM.DOCTORS d
         INNER JOIN hospitals h on d.id_hospital = h.id
WHERE d.deleted_at IS NULL
ORDER BY d.degree, CASE WHEN d.area = 'area2' THEN 1 ELSE 0 END
;

-- Выдать все талоны конкретного врача (1), не показывать талоны которые начались раньше текущего времени
SELECT *
FROM KOTLYAROV_DM.TICKETS t
WHERE t.id_doctor = 1
  AND t.TIME_BEGIN > current_date
;