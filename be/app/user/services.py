from datetime import date
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


# --- Nutrition & Metrics Calculation ---

def compute_user_metrics(user_id, data, prof, for_date):
    """
    Compute BMI, BMR, TDEE and macro targets for the user on a specific date.
    Returns a dict with keys: bmi, bmr, tdee, macros.
    """
    # --- Thông tin cơ bản ---
    weight = float(data.get('current_weight_kg', 0))
    height = float(prof.height_cm)

    # Tính tuổi tính theo for_date, không phải always today
    age = (for_date - prof.date_of_birth).days // 365
    gender = prof.gender or data.get('gender', 'male')

    bmi = calculate_bmi(weight, height)
    bmr = calculate_bmr(weight, height, age, gender)

    # --- Dữ liệu tập luyện cho đúng ngày đó ---
    sessions = fetch_exercise_sessions(user_id, for_date)

    #calories đã tiêu thụ
    calories_consumed = fetch_calories_consumed(user_id, for_date)

    #calories đã đốt cháy
    calories_burned, count = fetch_exercise_burned(user_id, for_date, weight)

    # TDEE cũng dựa trên bmr và sessions
    tdee = calculate_tdee(bmr, sessions)
    # Lấy mức giảm của user (kg/tuần), default=0.25
    weekly_rate = data.get('weekly_rate', 0.25)

    # Tính target_calories
    # 7700 kcal ≈ 1 kg mỡ (hoặc mô cơ)
    daily_adjustment = round((weekly_rate * 7700) / 7)

    if data['goal_direction'] == 'giảm cân':
        target_calories = tdee - daily_adjustment
    elif data['goal_direction'] == 'tăng cân':
        target_calories = tdee + daily_adjustment
    else:  # giữ nguyên
        target_calories = tdee

    # sau khi tính target_calories
    target_calories = max(target_calories, bmr * 1.1)
    
    #tính calories còn 
    remaining_calories = target_calories - calories_consumed + calories_burned

    #macro_consumed
    macros_consumed = fetch_macros_consumed(user_id, for_date)

    # Macro target vẫn dựa trên target_calories và mục tiêu
    macros = calculate_macros(target_calories, data.get('goal_direction'))

    #Tính nước
    water_intake_ml = fetch_water_intake(user_id, for_date)
    
    target_calories    = int(round(target_calories))
    remaining_calories = int(round(remaining_calories))
    calories_burned    = int(round(calories_burned))
    calories_consumed  = int(round(calories_consumed))
    
    return {
        'bmi': bmi,
        'bmr': bmr,
        'tdee': tdee,                     # TDEE cơ bản (chưa ± deficit/surplus)
        'target_calories': target_calories,  # Lượng calories user cần ăn (TDEE ± daily_adjustment)
        'macros': macros,
        'macros_consumed': macros_consumed,
        'remaining_calories': remaining_calories,
        'calories_burned': calories_burned,
        'calories_consumed': calories_consumed,
        'water_intake_ml' : water_intake_ml
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
