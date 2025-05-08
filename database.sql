-- 1. Bảng users (social login)
CREATE TABLE users (
  user_id      BIGSERIAL PRIMARY KEY,
  provider     VARCHAR(20)  NOT NULL,           -- 'google' / 'facebook' / 'apple'
  provider_id  VARCHAR(100) NOT NULL,           -- ID bên OAuth trả về
  email        VARCHAR(255) UNIQUE NOT NULL,
  display_name VARCHAR(255),
  avatar_url   TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Bảng user_profile
CREATE TABLE user_profile (
  user_id      BIGINT      PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
  first_name   VARCHAR(100),
  last_name    VARCHAR(100),
  date_of_birth DATE,
  gender       VARCHAR(10),
  height_cm    NUMERIC(5,2),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Bảng user_settings
CREATE TABLE user_settings (
  user_id                 BIGINT      PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
  locale                  VARCHAR(5)  NOT NULL DEFAULT 'vi',
  timezone                VARCHAR(50) NOT NULL DEFAULT 'Asia/Bangkok',
  weight_unit             VARCHAR(10)  NOT NULL DEFAULT 'kg',
  energy_unit             VARCHAR(10)  NOT NULL DEFAULT 'kcal',
  default_target_calories INTEGER,
  drink_water_reminder    BOOLEAN     NOT NULL DEFAULT TRUE,
  meal_reminder           BOOLEAN     NOT NULL DEFAULT TRUE
);

-- 4. Bảng food_items
CREATE TABLE food_items (
  food_item_id  BIGSERIAL PRIMARY KEY,
  name          VARCHAR(255) NOT NULL,
  brand         VARCHAR(255),
  serving_size  NUMERIC(8,2) NOT NULL,
  serving_unit  VARCHAR(50)  NOT NULL,
  calories      NUMERIC(8,2) NOT NULL,
  protein_g     NUMERIC(8,2) NOT NULL,
  carbs_g       NUMERIC(8,2) NOT NULL,
  fat_g         NUMERIC(8,2) NOT NULL,
  barcode       VARCHAR(50)  UNIQUE,
  is_custom     BOOLEAN      NOT NULL DEFAULT FALSE,
  created_by    BIGINT       REFERENCES users(user_id),
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- 5. Bảng barcode_scans
CREATE TABLE barcode_scans (
  scan_id       BIGSERIAL PRIMARY KEY,
  user_id       BIGINT    NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  barcode       VARCHAR(50) NOT NULL,
  food_item_id  BIGINT    REFERENCES food_items(food_item_id),
  scanned_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Bảng meal
CREATE TABLE meal (
  meal_id     BIGSERIAL PRIMARY KEY,
  user_id     BIGINT    NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  name        VARCHAR(100) NOT NULL,      -- Breakfast / Lunch / …
  meal_date   DATE      NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 7. Bảng meal_entries
CREATE TABLE meal_entries (
  entry_id      BIGSERIAL PRIMARY KEY,
  meal_id       BIGINT    NOT NULL REFERENCES meal(meal_id) ON DELETE CASCADE,
  food_item_id  BIGINT    NOT NULL REFERENCES food_items(food_item_id),
  quantity      NUMERIC(8,2) NOT NULL,
  unit          VARCHAR(50),
  calories      NUMERIC(8,2) NOT NULL,
  protein_g     NUMERIC(8,2) NOT NULL,
  carbs_g       NUMERIC(8,2) NOT NULL,
  fat_g         NUMERIC(8,2) NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 8. Bảng water_log
CREATE TABLE water_log (
  water_id   BIGSERIAL PRIMARY KEY,
  user_id    BIGINT    NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  intake_ml  INTEGER   NOT NULL,
  logged_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 9. Bảng weight_log
CREATE TABLE weight_log (
  weight_id  BIGSERIAL PRIMARY KEY,
  user_id    BIGINT    NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  weight_kg  NUMERIC(6,2) NOT NULL,
  logged_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 10. Bảng exercise_type
CREATE TABLE exercise_type (
  exercise_type_id BIGSERIAL PRIMARY KEY,
  name             VARCHAR(100) NOT NULL,
  mets             NUMERIC(5,2),
  category         VARCHAR(50)
);

-- 11. Bảng exercise_log
CREATE TABLE exercise_log (
  exercise_id     BIGSERIAL PRIMARY KEY,
  user_id         BIGINT    NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  exercise_type_id BIGINT   NOT NULL REFERENCES exercise_type(exercise_type_id),
  duration_min    INTEGER   NOT NULL,
  calories_burned NUMERIC(8,2),
  logged_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- 12. Bảng goals
CREATE TABLE goals (
  goal_id      BIGSERIAL PRIMARY KEY,
  user_id      BIGINT    NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  goal_type    VARCHAR(20) NOT NULL,      -- 'weight' / 'calories' / 'macros'.
  goal_direction VARCHAR(10) NOT NULL, -- 'gain' / 'lose' / 'maintain'
  target_value NUMERIC(10,2) NOT NULL,
  start_date   DATE      NOT NULL,
  duration_weeks INTEGER NOT NULL,
  weekly_rate NUMERIC(5,2) NOT NULL DEFAULT 0,75,  -- kg / week or kcal / week
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 13. Bảng notification_settings
CREATE TABLE notification_settings (
  notif_id      BIGSERIAL PRIMARY KEY,
  user_id       BIGINT    NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  type          VARCHAR(30) NOT NULL,     -- 'meal_reminder' / 'drink_water' / …
  time_of_day   TIME      NOT NULL,
  days_of_week  SMALLINT[] NOT NULL,       -- array of 0=Sun…6=Sat
  enabled       BOOLEAN   NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- (Tuỳ chọn) Tạo index để tăng tốc trên các cột thường query:
CREATE INDEX idx_meal_user_date ON meal(user_id, meal_date);
CREATE INDEX idx_entries_meal ON meal_entries(meal_id);
CREATE INDEX idx_barcode_scans_user ON barcode_scans(user_id);
CREATE INDEX idx_water_log_user ON water_log(user_id);
CREATE INDEX idx_weight_log_user ON weight_log(user_id);
CREATE INDEX idx_exercise_log_user ON exercise_log(user_id);