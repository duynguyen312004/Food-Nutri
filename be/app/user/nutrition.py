from datetime import date, timedelta
from decimal import Decimal
from sqlalchemy import func
from extensions import db
from user.models import User, UserProfile, UserSettings, WeightLog, Goal
from exercise.models import ExerciseLog, ExerciseType
from meal.models import Meal, MealEntry
from food.models import FoodItem

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
    
def calculate_tdee(bmr: float, sessions_per_week: int) -> int:
    """Calculate Total Daily Energy Expenditure (TDEE)."""
    return round(bmr * activity_factor_from_sessions(sessions_per_week))

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


def fetch_exercise_sessions(user_id: int, for_date: date) -> int:
    """Đếm buổi tập của user trong 7 ngày tính từ for_date."""
    week_ago = for_date - timedelta(days=6)
    count = (
        db.session.query(func.count(ExerciseLog.exercise_id))
        .filter(ExerciseLog.user_id == user_id)
        .filter(ExerciseLog.logged_at >= week_ago)
        .filter(func.date(ExerciseLog.logged_at) <= for_date)
        .scalar()
    )
    return int(count or 0)

def estimate_calories_burned(met: float, weight_kg: float, duration_min: int) -> float:
    return round(float(met) * float(weight_kg) * (duration_min / 60), 2)

def fetch_exercise_burned(user_id: int, for_date: date, weight_kg: float) -> tuple[float, int]:
    logs = (db.session.query(ExerciseLog, ExerciseType)
            .join(ExerciseType, ExerciseLog.exercise_type_id == ExerciseType.exercise_type_id)
            .filter(ExerciseLog.user_id == user_id)
            .filter(func.date(ExerciseLog.logged_at) == for_date)
            .all())

    total_calories = 0
    count = 0

    for log, ex_type in logs:
        met = ex_type.mets or 1.0
        calories = estimate_calories_burned(met, weight_kg, log.duration_min)
        total_calories += calories
        count += 1

    return total_calories, count

def fetch_calories_consumed(user_id: int, for_date: date) -> float:
    entries = (
        db.session.query(MealEntry, FoodItem)
        .join(Meal, Meal.meal_id == MealEntry.meal_id)
        .join(FoodItem, FoodItem.food_item_id == MealEntry.food_item_id)
        .filter(Meal.user_id == user_id)
        .filter(Meal.meal_date == for_date)
        .all()
    )

    total = 0.0
    for entry, food in entries:
        ratio = float(entry.quantity) / float(food.serving_size) if food.serving_size else 1
        total += ratio * float(food.calories)

    return round(total, 2)
def fetch_macros_consumed(user_id: int, for_date: date) -> dict:
    """
    Sum protein, carbs, fat đã ăn trong ngày, dựa trên MealEntry × FoodItem.
    Trả về dict với keys: protein_g, carbs_g, fat_g (float, grams).
    """
    entries = (
        db.session.query(MealEntry, FoodItem)
        .join(Meal, Meal.meal_id == MealEntry.meal_id)
        .join(FoodItem, FoodItem.food_item_id == MealEntry.food_item_id)
        .filter(Meal.user_id == user_id)
        .filter(Meal.meal_date == for_date)
        .all()
    )

    total_p, total_c, total_f = 0.0, 0.0, 0.0
    for entry, food in entries:
        ratio = float(entry.quantity) / float(food.serving_size) if food.serving_size else 1
        total_p += ratio * float(food.protein_g)
        total_c += ratio * float(food.carbs_g)
        total_f += ratio * float(food.fat_g)

    return {
        'protein_g': round(total_p, 1),
        'carbs_g':   round(total_c, 1),
        'fat_g':     round(total_f, 1),
    }
