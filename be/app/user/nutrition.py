from datetime import date
from decimal import Decimal
from sqlalchemy import func
from extensions import db
from user.models import User, UserProfile, UserSettings, WeightLog, Goal, ExerciseLog, ExerciseType

def calculate_bmi(weight_kg: float, height_cm: float) -> float:
    h = height_cm / 100  # Convert cm to meters
    return round(weight_kg / (h * h), 1) if h > 0 else 0.0

def calculate_bmr(weight_kg: float, height_cm: float, age: int, gender: str) -> int:
    """Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation."""
    gender = gender.lower() if gender else 'Male'
    if gender == 'male':
        bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age + 5
    else:
        bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age - 161
    return round(bmr)


def activity_factor_from_sessions(sessions_per_week: int) -> float:
    """Convert sessions per week to activity factor."""
    if sessions_per_week <= 0:
        return 1.2  # Sedentary
    elif sessions_per_week <= 3:
        return 1.375  # Lightly active
    elif sessions_per_week <= 5:
        return 1.55  # Moderately active
    elif sessions_per_week <= 7:
        return 1.725  # Very active
    else:
        return 1.9  # Super active
    
def calculate_tdee(bmr: float, sessions_per_week: int, exercise_extra: float = 0) -> int:
    """Calculate Total Daily Energy Expenditure (TDEE)."""
    return round(bmr * activity_factor_from_sessions(sessions_per_week) + exercise_extra)

def calculate_macros(calories: int, goal_direction: str) -> dict:
    """
    Return macro targets (in grams) based on percentage split,
    điều chỉnh theo mục tiêu: 'lose', 'maintain', 'gain'.
    """
    # Tỷ lệ mặc định cho duy trì cân nặng
    protein_pct = 0.20
    fat_pct     = 0.30
    carb_pct    = 0.50

    # Điều chỉnh split khi giảm hoặc tăng cân
    if goal_direction == 'giảm cân':
        protein_pct = 0.25   # ưu tiên protein để giữ cơ bắp
        fat_pct     = 0.25
        carb_pct    = 0.50
    elif goal_direction == 'tăng cân':
        protein_pct = 0.20
        fat_pct     = 0.25
        carb_pct    = 0.55

    # Tính kcal cho từng macro
    protein_kcal = calories * protein_pct
    fat_kcal     = calories * fat_pct
    carb_kcal    = calories * carb_pct

    # Chuyển về gram (protein & carb = 4 kcal/g; fat = 9 kcal/g)
    return {
        'protein_g': round(protein_kcal / 4, 1),
        'fat_g':     round(fat_kcal / 9, 1),
        'carbs_g':   round(carb_kcal / 4, 1),
    }


def fetch_exercise_data(user_id: int, for_date: date) -> tuple[float, int]:
    """Fetch exercise data for a user within a date range."""
    result = (db.session.query(
        func.coalesce(func.sum(ExerciseLog.calories_burned), 0),
        func.coalesce(func.count(ExerciseLog.exercise_id), 0)
    ).filter(ExerciseLog.user_id == user_id).filter(func.date(ExerciseLog.logged_at) == for_date).first()
    )
    return float(result[0]), int(result[1])