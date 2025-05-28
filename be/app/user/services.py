from datetime import date, datetime
from extensions import db
from user.models import User, UserProfile, UserSettings, WeightLog, Goal
from user.nutrition import (
    calculate_bmi,
    calculate_bmr,
    fetch_calories_consumed,
    fetch_exercise_burned,
    calculate_tdee,
    calculate_macros,
    fetch_exercise_sessions,
    fetch_macros_consumed,
    fetch_water_intake
)

# --- Upsert Helpers ---

def upsert_user_from_firebase(decoded_token):
    uid = decoded_token.get('uid')
    provider = decoded_token.get('firebase', {}).get('sign_in_provider')
    email = decoded_token.get('email')
    display = decoded_token.get('name')
    avatar = decoded_token.get('picture')

    user = User.query.filter_by(provider_id=uid, provider=provider).first()
    if not user:
        user = User(
            provider=provider,
            provider_id=uid,
            email=email,
            display_name=display,
            avatar_url=avatar
        )
        db.session.add(user)
    else:
        user.email = email
        user.display_name = display
        user.avatar_url = avatar
    db.session.commit()
    return user


def upsert_profile(user_id, data):
    prof = UserProfile.query.get(user_id) or UserProfile(user_id=user_id)
    for field in ('first_name', 'last_name', 'date_of_birth', 'gender', 'height_cm'):
        if field in data:
            setattr(prof, field, data[field])
    db.session.add(prof)
    db.session.commit()
    return prof


def upsert_settings(user_id, data):
    sett = UserSettings.query.get(user_id) or UserSettings(user_id=user_id)
    for field in (
        'locale', 'timezone', 'weight_unit', 'energy_unit',
        'default_target_calories', 'drink_water_reminder', 'meal_reminder'
    ):
        if field in data:
            setattr(sett, field, data[field])
    db.session.add(sett)
    db.session.commit()
    return sett

# --- Weight Log ---
def get_weight_logs(user_id, start_date=None, end_date=None):
    """
    Fetch weight logs for a user within an optional date range.
    Returns a list of WeightLog objects.
    """
    query = WeightLog.query.filter_by(user_id=user_id)
    if start_date:
        query = query.filter(WeightLog.logged_at >= start_date)
    if end_date:
        query = query.filter(WeightLog.logged_at <= end_date)
    return query.order_by(WeightLog.logged_at.desc()).all()

def log_weight(user_id, weight_kg, logged_at=None):
    """
    Ghi lại log cân nặng cho user. Nếu cùng ngày thì ghi đè.
    logged_at: string (YYYY-MM-DD) hoặc None
    """
    # Convert logged_at sang date nếu là string
    if logged_at is None:
        logged_at = date.today()
    elif isinstance(logged_at, str):
        logged_at = datetime.strptime(logged_at, "%Y-%m-%d").date()
    elif isinstance(logged_at, datetime):
        logged_at = logged_at.date()

    # Kiểm tra trùng ngày
    log = WeightLog.query.filter_by(user_id=user_id, logged_at=logged_at).first()
    if log:
        log.weight_kg = weight_kg
    else:
        log = WeightLog(
            user_id=user_id,
            weight_kg=weight_kg,
            logged_at=logged_at
        )
        db.session.add(log)
    db.session.commit()
    return log


def delete_weight_log(weight_id):
    """
    Delete a weight log entry by ID.
    """
    log = WeightLog.query.get(weight_id)
    if not log:
        raise ValueError(f"Weight log ID {weight_id} không tồn tại.")

    db.session.delete(log)
    db.session.commit()

# --- Nutrition & Metrics Calculation ---

def compute_user_metrics(user_id, data, prof, for_date):
    """
    Compute BMI, BMR, TDEE and macro targets for the user on a specific date.
    Returns a dict with keys: bmi, bmr, tdee, macros, and more.
    """
    # --- Kiểm tra dữ liệu đầu vào ---
    if not prof.height_cm or not prof.date_of_birth:
        raise ValueError("Thiếu chiều cao hoặc ngày sinh để tính chỉ số.")

    weight = float(data.get('current_weight_kg', 0))
    if weight <= 0:
        raise ValueError("Cân nặng không hợp lệ.")

    height = float(prof.height_cm)
    age = (for_date - prof.date_of_birth).days // 365
    gender = prof.gender or data.get('gender', 'male')

    bmi = calculate_bmi(weight, height)
    bmr = calculate_bmr(weight, height, age, gender)

    # --- Tính dữ liệu luyện tập ---
    sessions = fetch_exercise_sessions(user_id, for_date)
    calories_consumed = fetch_calories_consumed(user_id, for_date)
    calories_burned, count = fetch_exercise_burned(user_id, for_date, weight)

    tdee = calculate_tdee(bmr, sessions)

    # --- Tính mức điều chỉnh calo ---
    weekly_rate = float(data.get('weekly_rate', 0.25))
    daily_adjustment = round((weekly_rate * 7700) / 7)

    # Giới hạn daily_adjustment nếu quá lớn
    if daily_adjustment > 1200:
        daily_adjustment = 1200  # tránh mục tiêu nguy hiểm

    goal_direction = data.get('goal_direction', 'giữ nguyên')
    if goal_direction == 'giảm cân':
        target_calories = tdee - daily_adjustment
    elif goal_direction == 'tăng cân':
        target_calories = tdee + daily_adjustment
    else:
        target_calories = tdee

    # Giới hạn target_calories tối thiểu
    min_cal = max(1200, bmr * 1.1)
    target_calories = max(target_calories, min_cal)

    # Tính remaining
    remaining_calories = target_calories - calories_consumed + calories_burned

    # --- Macro style ---
    macro_style = data.get('macro_style', 'default')  # optional field
    macros = calculate_macros(target_calories, goal_direction, macro_style)
    macros_consumed = fetch_macros_consumed(user_id, for_date)

    # --- Nước uống ---
    water_intake_ml = fetch_water_intake(user_id, for_date)

    # Làm tròn các chỉ số cần hiển thị
    target_calories    = int(round(target_calories))
    remaining_calories = int(round(remaining_calories))
    calories_burned    = int(round(calories_burned))
    calories_consumed  = int(round(calories_consumed))

    # --- lưu lại target_calories vào settings ---
    user_settings = UserSettings.query.get(user_id)
    if user_settings:
        user_settings.default_target_calories = target_calories
        db.session.add(user_settings)
        db.session.commit()

    return {
        'bmi': bmi,
        'bmr': bmr,
        'tdee': tdee,
        'target_calories': target_calories,
        'macros': macros,
        'macros_consumed': macros_consumed,
        'remaining_calories': remaining_calories,
        'calories_burned': calories_burned,
        'calories_consumed': calories_consumed,
        'water_intake_ml': water_intake_ml
    }

# --- Main Setup Flow ---

def complete_initial_setup(user_id, data):
    """
    Perform initial setup after registration:
      - Upsert user profile & settings
      - Log initial weight
      - Create a weight goal
      - Compute nutrition metrics

    Returns: (profile, weight_log, goal, settings, metrics_dict)
    """
    # 1) Profile & Settings
    prof = upsert_profile(user_id, data)
    sett = upsert_settings(user_id, data)

    # 2) Initial Weight Log
    wl = None
    if data.get('current_weight_kg') is not None:
        wl = WeightLog(user_id=user_id, weight_kg=data['current_weight_kg'])
        db.session.add(wl)

    # 3) Create Goal
    goal = Goal(
        user_id=user_id,
        goal_type='weight',
        target_value=data['target_weight_kg'],
        goal_direction=data.get('goal_direction', 'giữ nguyên'),
        start_date=date.today(),
        duration_weeks=data['duration_weeks'],
        weekly_rate=data.get('weekly_rate', 0.75)
    )
    db.session.add(goal)

    # Commit so we have IDs and can compute metrics
    db.session.commit()

    return prof, wl, goal, sett


# --- Delete User Account---
def delete_user_account(user_id):
    user = User.query.get(user_id)
    if not user:
        raise ValueError(f"User ID {user_id} không tồn tại.")

    db.session.delete(user)
    db.session.commit()


def validate_and_create_goal(uid, data):
    # Validate và tính toán logic ở đây
    target_value = float(data.get('target_weight'))
    goal_direction = data.get('goal_direction', '')
    weekly_rate = float(data.get('weekly_rate', 0.75))
    duration_weeks = int(data.get('duration_weeks', 12))

    # Lấy profile
    prof = UserProfile.query.get(uid)
    if not prof or not prof.height_cm or not prof.date_of_birth:
        raise ValueError('Thông tin hồ sơ chưa đầy đủ!')

    # Lấy cân nặng hiện tại
    latest_log = (
        WeightLog.query.filter_by(user_id=uid)
        .order_by(WeightLog.logged_at.desc())
        .first()
    )
    if not latest_log:
        raise ValueError('Bạn chưa có log cân nặng nào')
    current_weight = float(latest_log.weight_kg)
    age = (date.today() - prof.date_of_birth).days // 365
    gender = prof.gender or 'male'
    height = float(prof.height_cm)

    # Kiểm tra logic giảm/tăng cân
    if goal_direction == 'giảm cân' and target_value >= current_weight:
        raise ValueError('Cân nặng mục tiêu phải nhỏ hơn cân nặng hiện tại khi giảm cân!')
    if goal_direction == 'tăng cân' and target_value <= current_weight:
        raise ValueError('Cân nặng mục tiêu phải lớn hơn cân nặng hiện tại khi tăng cân!')

    # --- Dùng các hàm có sẵn ---
    from user.nutrition import calculate_bmr, fetch_exercise_sessions, calculate_tdee
    bmr = calculate_bmr(current_weight, height, age, gender)
    sessions = fetch_exercise_sessions(uid, date.today())
    tdee = calculate_tdee(bmr, sessions)
    daily_adjustment = round((weekly_rate * 7700) / 7)
    min_cal = max(1200, bmr * 1.1)
    if daily_adjustment > 1200:
        raise ValueError('Tốc độ mục tiêu quá nhanh, vượt ngưỡng an toàn!')

    if goal_direction == 'giảm cân':
        target_calories = tdee - daily_adjustment
    elif goal_direction == 'tăng cân':
        target_calories = tdee + daily_adjustment
    else:
        target_calories = tdee
    if target_calories < min_cal:
        raise ValueError(f'Mục tiêu này sẽ làm calories hàng ngày xuống quá thấp ({target_calories} kcal, tối thiểu nên là {int(min_cal)} kcal). Hãy chọn tốc độ vừa phải hơn.')

    # Nếu qua mọi check: lưu DB
    new_goal = Goal(
        user_id=uid,
        goal_type='weight',
        target_value=target_value,
        goal_direction=goal_direction,
        start_date=date.today(),
        duration_weeks=duration_weeks,
        weekly_rate=weekly_rate
    )
    db.session.add(new_goal)
    db.session.commit()

    return {
        'message': 'Cập nhật mục tiêu thành công!',
        'goal': {
            'target_value': float(new_goal.target_value),
            'goal_direction': new_goal.goal_direction,
            'weekly_rate': float(new_goal.weekly_rate),
            'duration_weeks': new_goal.duration_weeks,
            'start_date': new_goal.start_date.isoformat()
        },
        'bmr': bmr,
        'tdee': tdee,
        'target_calories': int(round(target_calories))
    }

