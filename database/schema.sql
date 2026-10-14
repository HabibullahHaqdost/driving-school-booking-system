-- Driving School Online Booking System: database schema (MySQL 8 / MariaDB)
-- Revised from the original course report (Phase 3). Changes are marked "-- revised:".

CREATE TABLE students (
    student_id     INT AUTO_INCREMENT PRIMARY KEY,
    first_name     VARCHAR(50)  NOT NULL,
    last_name      VARCHAR(50)  NOT NULL,
    phone          VARCHAR(20)  NOT NULL UNIQUE,
    email          VARCHAR(100) UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE instructors (
    instructor_id    INT AUTO_INCREMENT PRIMARY KEY,
    first_name       VARCHAR(50)  NOT NULL,
    last_name        VARCHAR(50)  NOT NULL,
    phone            VARCHAR(20)  NOT NULL UNIQUE,
    email            VARCHAR(100) UNIQUE,          -- revised: the class diagram has an email attribute
    license_number   VARCHAR(50)  NOT NULL UNIQUE,
    experience_years INT DEFAULT 0,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE classes (
    class_id      INT AUTO_INCREMENT PRIMARY KEY,
    instructor_id INT NOT NULL,
    class_date    DATE NOT NULL,
    start_time    TIME NOT NULL,
    end_time      TIME NOT NULL,
    capacity      INT NOT NULL DEFAULT 1,
    price         DECIMAL(10,2) NOT NULL,
    CHECK (end_time > start_time),                 -- revised
    CHECK (capacity > 0),                          -- revised
    FOREIGN KEY (instructor_id)
        REFERENCES instructors(instructor_id)
        ON DELETE RESTRICT                         -- revised: keep lessons if an instructor is removed by mistake
) ENGINE=InnoDB;

CREATE TABLE bookings (
    booking_id   INT AUTO_INCREMENT PRIMARY KEY,
    student_id   INT NOT NULL,
    class_id     INT NOT NULL,
    booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status       ENUM('pending','confirmed','cancelled') NOT NULL DEFAULT 'pending',
    UNIQUE (student_id, class_id),                 -- revised: a student cannot book the same lesson twice
    FOREIGN KEY (student_id)
        REFERENCES students(student_id)
        ON DELETE CASCADE,
    FOREIGN KEY (class_id)
        REFERENCES classes(class_id)
        ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE payments (
    payment_id     INT AUTO_INCREMENT PRIMARY KEY,
    booking_id     INT NOT NULL UNIQUE,
    amount         DECIMAL(10,2) NOT NULL,
    currency       CHAR(3) NOT NULL DEFAULT 'CAD', -- revised: Phase 5 localization targets CAD
    payment_method ENUM('card','cash','online') NOT NULL,
    payment_status ENUM('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending', -- revised: 'refunded' for cancellations
    payment_date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id)
        ON DELETE RESTRICT                         -- revised: financial records must not be deleted with a booking
) ENGINE=InnoDB;

-- Lookup used for "view available slots": lessons that still have free capacity.
CREATE VIEW available_classes AS
SELECT c.class_id, c.class_date, c.start_time, c.end_time, c.price,
       i.first_name AS instructor_first_name, i.last_name AS instructor_last_name,
       c.capacity - COUNT(b.booking_id) AS seats_left
FROM classes c
JOIN instructors i ON i.instructor_id = c.instructor_id
LEFT JOIN bookings b ON b.class_id = c.class_id AND b.status <> 'cancelled'
GROUP BY c.class_id, c.class_date, c.start_time, c.end_time, c.price,
         i.first_name, i.last_name, c.capacity
HAVING seats_left > 0;
